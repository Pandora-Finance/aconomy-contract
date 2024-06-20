// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import {SafeMath} from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "./poolRegistry.sol";
import "./poolStorage.sol";
import "./AconomyFee.sol";
import "./Libraries/LibCalculations.sol";
import "./Libraries/LibPoolAddress.sol";
import {BokkyPooBahsDateTimeLibrary as BPBDTL} from "./Libraries/DateTimeLib.sol";

contract poolAddress is
    poolStorage,
    ReentrancyGuardUpgradeable,
    PausableUpgradeable,
    OwnableUpgradeable,
    UUPSUpgradeable
{
    using SafeMath for uint256;
    using EnumerableSet for EnumerableSet.UintSet;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        address _poolRegistry,
        address _AconomyFeeAddress
    ) public initializer {
        __ReentrancyGuard_init();
        __Ownable_init();
        __UUPSUpgradeable_init();
        poolRegistryAddress = _poolRegistry;
        AconomyFeeAddress = _AconomyFeeAddress;
        loanId = 0;
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    event loanAccepted(uint256 poolId, uint256 indexed loanId, address indexed lender);

    event repaidAmounts(
        uint256 poolId,
        uint256 owedPrincipal,
        uint256 duePrincipal,
        uint256 interest
    );
    event AcceptedLoanDetail(
        uint256 poolId,
        uint256 indexed loanId,
        uint256 indexed amountToAconomy,
        uint256 amountToPool,
        uint256 amountToBorrower
    );

    event LoanRepaid(uint256 poolId, uint256 indexed loanId, uint256 Amount);
    event LoanRepayment(uint256 poolId, uint256 indexed loanId, uint256 Amount);

    event SubmittedLoan(
        uint256 poolId,
        uint256 indexed loanId,
        address indexed borrower,
        address receiver,
        uint256 paymentCycleAmount
    );

    /**
     * @notice Lets a borrower request for a loan.
     * @dev Returned value is type uint256.
     * @param _lendingToken The address of the token being requested.
     * @param _poolId The Id of the pool.
     * @param _principal The principal amount being requested.
     * @param _duration The duration of the loan.
     * @param _expirationDuration The time in which the loan has to be accepted before it expires.
     * @param _APR The annual interest percentage in bps.
     * @param _receiver The receiver of the funds.
     * @return loanId_ Id of the loan.
     */
    function loanRequest(
        address _lendingToken,
        uint256 _poolId,
        uint256 _principal,
        uint32 _duration,
        uint32 _expirationDuration,
        uint16 _APR,
        address _receiver
    ) public whenNotPaused returns (uint256 loanId_) {
        require(_lendingToken != address(0));
        require(_receiver != address(0));
        (bool isVerified, ) = poolRegistry(poolRegistryAddress)
            .borrowerVerification(_poolId, msg.sender);
        require(isVerified);
        require(!poolRegistry(poolRegistryAddress).ClosedPool(_poolId));
        require(_duration % 30 days == 0);
        require(_APR >= 100);
        require(_principal >= 1000000, "low");
        require(_expirationDuration > 0);

        loanId_ = loanId;

        poolLoans[_poolId] = loanId_;

        uint16 fee = AconomyFee(AconomyFeeAddress).AconomyPoolFee();

        // Create and store our loan into the mapping
        Loan storage loan = loans[loanId];
        loan.borrower = msg.sender;
        loan.receiver = _receiver != address(0) ? _receiver : loan.borrower;
        loan.poolId = _poolId;
        loan.loanDetails.lendingToken = ERC20(_lendingToken);
        loan.loanDetails.principal = _principal;
        loan.loanDetails.loanDuration = _duration;
        loan.loanDetails.timestamp = uint32(block.timestamp);
        loan.loanDetails.protocolFee = fee;
        loan.terms.installments = _duration / 30 days;
        loan.terms.installmentsPaid = 0;

        loan.terms.paymentCycle = poolRegistry(poolRegistryAddress)
            .getPaymentCycleDuration(_poolId);

        loan.terms.APR = _APR;

        loanDefaultDuration[loanId] = poolRegistry(poolRegistryAddress)
            .getPaymentDefaultDuration(_poolId);

        loanExpirationDuration[loanId] = _expirationDuration;

        loan.terms.paymentCycleAmount = LibCalculations.payment(
            _principal,
            _duration,
            loan.terms.paymentCycle,
            _APR
        );

        uint256 monthlyPrincipal = _principal / loan.terms.installments;

        loan.terms.monthlyCycleInterest =
            loan.terms.paymentCycleAmount -
            monthlyPrincipal;

        loan.state = LoanState.PENDING;

        emit SubmittedLoan(
            _poolId,
            loanId,
            loan.borrower,
            loan.receiver,
            loan.terms.paymentCycleAmount
        );

        // Store loan inside borrower loans mapping
        borrowerLoans[loan.borrower].push(loanId);

        // Increment loan id
        loanId++;
    }

    /**
     * @notice Accepts the loan request.
     * @param _loanId The Id of the loan.
     */
    function AcceptLoan(
        uint256 _loanId
    )
        external
        whenNotPaused
        nonReentrant
        returns (
            uint256 amountToAconomy,
            uint256 amountToPool,
            uint256 amountToBorrower
        )
    {
        Loan storage loan = loans[_loanId];
        require(!isLoanExpired(_loanId));

        (amountToAconomy, amountToPool, amountToBorrower) = LibPoolAddress
            .acceptLoan(loan, poolRegistryAddress, AconomyFeeAddress);

        // Record Amount filled by lenders
        lenderLendAmount[address(loan.loanDetails.lendingToken)][
            loan.lender
        ] += loan.loanDetails.principal;
        totalERC20Amount[address(loan.loanDetails.lendingToken)] += loan
            .loanDetails
            .principal;

        // Store Borrower's active loan
        require(borrowerActiveLoans[loan.borrower].add(_loanId));

        emit loanAccepted(loan.poolId,_loanId, loan.lender);

        emit AcceptedLoanDetail(loan.poolId,_loanId, amountToAconomy, amountToPool, amountToBorrower);
    }

    /**
     * @notice Checks if the loan has expired.
     * @dev Return type is of boolean.
     * @param _loanId The Id of the loan.
     * @return boolean indicating if the loan is expired.
     */
    function isLoanExpired(uint256 _loanId) public view returns (bool) {
        Loan storage loan = loans[_loanId];

        if (loan.state != LoanState.PENDING) return false;
        if (loanExpirationDuration[_loanId] == 0) return false;

        return (uint32(block.timestamp) >
            loan.loanDetails.timestamp + loanExpirationDuration[_loanId]);
    }

    /**
     * @notice Checks if the loan has defaulted.
     * @dev Return type is of boolean.
     * @param _loanId The Id of the loan.
     * @return boolean indicating if the loan is defaulted.
     */
    function isLoanDefaulted(uint256 _loanId) public view returns (bool) {
        Loan storage loan = loans[_loanId];

        // Make sure loan cannot be liquidated if it is not active
        if (loan.state != LoanState.ACCEPTED) return false;

        if (loanDefaultDuration[_loanId] == 0) return false;

        return ((int32(uint32(block.timestamp)) -
            int32(
                loan.loanDetails.acceptedTimestamp +
                    loan.loanDetails.loanDuration
            )) > int32(loanDefaultDuration[_loanId]));
    }

    /**
     * @notice Returns the last repaid timestamp of the loan.
     * @dev Return type is of uint32.
     * @param _loanId The Id of the loan.
     * @return timestamp in uint32.
     */
    function lastRepaidTimestamp(uint256 _loanId) public view returns (uint32) {
        return LibCalculations.lastRepaidTimestamp(loans[_loanId]);
    }

    /**
     * @notice Checks if the loan repayment is late.
     * @dev Return type is of boolean.
     * @param _loanId The Id of the loan.
     * @return boolean indicating if the loan repayment is late.
     */
    function isPaymentLate(uint256 _loanId) public view returns (bool) {
        if (loans[_loanId].state != LoanState.ACCEPTED) return false;
        return uint32(block.timestamp) > calculateNextDueDate(_loanId) + 7 days;
    }

    /**
     * @notice Calculates the next repayment due date.
     * @dev Return type is of uint32.
     * @param _loanId The Id of the loan.
     * @return dueDate_ The timestamp of the next payment due date.
     */
    function calculateNextDueDate(
        uint256 _loanId
    ) public view returns (uint32 dueDate_) {
        Loan storage loan = loans[_loanId];
        if (loans[_loanId].state != LoanState.ACCEPTED) return dueDate_;

        // Start with the original due date being 1 payment cycle since loan was accepted
        dueDate_ = loan.loanDetails.acceptedTimestamp + loan.terms.paymentCycle;

        // Calculate the cycle number the last repayment was made
        uint32 delta = lastRepaidTimestamp(_loanId) -
            loan.loanDetails.acceptedTimestamp;
        if (delta > 0) {
            uint32 repaymentCycle = (delta / loan.terms.paymentCycle);
            dueDate_ += (repaymentCycle * loan.terms.paymentCycle);
        }

        //if we are in the last payment cycle, the next due date is the end of loan duration
        if (
            dueDate_ >
            loan.loanDetails.acceptedTimestamp + loan.loanDetails.loanDuration
        ) {
            dueDate_ =
                loan.loanDetails.acceptedTimestamp +
                loan.loanDetails.loanDuration;
        }
    }

    /**
     * @notice Returns the installment amount to be paid at the called timestamp.
     * @dev Return type is of uint256.
     * @param _loanId The Id of the loan.
     * @return uint256 of the installment amount to be paid.
     */
    function viewInstallmentAmount(
        uint256 _loanId
    ) external view returns (uint256) {
        uint32 LastRepaidTimestamp = lastRepaidTimestamp(_loanId);
        uint256 lastPaymentCycle = BPBDTL.diffMonths(
            loans[_loanId].loanDetails.acceptedTimestamp,
            LastRepaidTimestamp
        );
        uint256 monthsSinceStart = BPBDTL.diffMonths(
            loans[_loanId].loanDetails.acceptedTimestamp,
            block.timestamp
        );

        if (
            loans[_loanId].terms.installmentsPaid + 1 ==
            loans[_loanId].terms.installments
        ) {
            return viewFullRepayAmount(_loanId);
        }

        if (monthsSinceStart > lastPaymentCycle) {
            return loans[_loanId].terms.paymentCycleAmount;
        } else {
            return 0;
        }
    }

    /**
     * @notice Repays the monthly installment.
     * @param _loanId The Id of the loan.
     */
    function repayMonthlyInstallment(
        uint256 _loanId
    ) external whenNotPaused nonReentrant {
        require(loans[_loanId].loanDetails.principal / uint256(loans[_loanId].terms.installments) >= 1000000, "low");
        require(loans[_loanId].state == LoanState.ACCEPTED);
        require(
            loans[_loanId].terms.installmentsPaid + 1 <=
                loans[_loanId].terms.installments
        );
        require(block.timestamp > calculateNextDueDate(_loanId));

        if (
            loans[_loanId].terms.installmentsPaid + 1 ==
            loans[_loanId].terms.installments
        ) {
            _repayFullLoan(_loanId);
        } else {
            uint256 monthlyInterest = loans[_loanId].terms.monthlyCycleInterest;
            uint256 monthlyDue = loans[_loanId].terms.paymentCycleAmount;
            uint256 due = monthlyDue - monthlyInterest;

            (uint256 owedAmount, , uint256 interest) = LibCalculations
                .owedAmount(loans[_loanId], block.timestamp);
            loans[_loanId].terms.installmentsPaid++;

            _repayLoan(
                _loanId,
                Payment({principal: due, interest: monthlyInterest}),
                owedAmount + interest
            );
            loans[_loanId].loanDetails.lastRepaidTimestamp =
                loans[_loanId].loanDetails.acceptedTimestamp +
                (loans[_loanId].terms.installmentsPaid *
                    loans[_loanId].terms.paymentCycle);
        }
    }

    /**
     * @notice Returns the full amount to be paid at the called timestamp.
     * @dev Return type is of uint256.
     * @param _loanId The Id of the loan.
     * @return uint256 of the full amount to be paid.
     */
    function viewFullRepayAmount(
        uint256 _loanId
    ) public view returns (uint256) {
        (uint256 owedAmount, , uint256 interest) = LibCalculations.owedAmount(
            loans[_loanId],
            block.timestamp + 10 minutes
        );

        uint256 paymentAmount = owedAmount + interest;
        if (
            loans[_loanId].state != LoanState.ACCEPTED ||
            loans[_loanId].state == LoanState.PAID
        ) {
            paymentAmount = 0;
        }
        return paymentAmount;
    }

    /**
     * @notice Repays the full amount to be paid at the called timestamp.
     * @param _loanId The Id of the loan.
     */
    function _repayFullLoan(uint256 _loanId) private {
        require(loans[_loanId].state == LoanState.ACCEPTED);
        (uint256 owedPrincipal, , uint256 interest) = LibCalculations
            .owedAmount(loans[_loanId], block.timestamp);
        _repayLoan(
            _loanId,
            Payment({principal: owedPrincipal, interest: interest}),
            owedPrincipal + interest
        );
    }

    /**
     * @notice Repays the full amount to be paid at the called timestamp.
     * @param _loanId The Id of the loan.
     */
    function repayFullLoan(
        uint256 _loanId
    ) external nonReentrant whenNotPaused {
        require(loans[_loanId].state == LoanState.ACCEPTED);
        (uint256 owedPrincipal, , uint256 interest) = LibCalculations
            .owedAmount(loans[_loanId], block.timestamp);
        _repayLoan(
            _loanId,
            Payment({principal: owedPrincipal, interest: interest}),
            owedPrincipal + interest
        );
    }

    /**
     * @notice Repays the specified amount.
     * @param _loanId The Id of the loan.
     * @param _payment The amount being paid split into principal and interest.
     * @param _owedAmount The total amount owed at the called timestamp.
     */
    function _repayLoan(
        uint256 _loanId,
        Payment memory _payment,
        uint256 _owedAmount
    ) internal {
        Loan storage loan = loans[_loanId];
        uint256 paymentAmount = _payment.principal + _payment.interest;

        // Check if we are sending a payment or amount remaining
        if (paymentAmount >= _owedAmount) {
            paymentAmount = _owedAmount;
            loan.state = LoanState.PAID;

            // Remove borrower's active loan
            require(borrowerActiveLoans[loan.borrower].remove(_loanId));

            emit LoanRepaid(loan.poolId, _loanId, paymentAmount);
        } else {
            emit LoanRepayment(loan.poolId, _loanId, paymentAmount);
        }

        loan.loanDetails.totalRepaid.principal += _payment.principal;
        loan.loanDetails.totalRepaid.interest += _payment.interest;
        loan.loanDetails.lastRepaidTimestamp = uint32(block.timestamp);

        // Send payment to the lender
        bool isSuccess = IERC20(loan.loanDetails.lendingToken).transferFrom(
            msg.sender,
            loan.lender,
            paymentAmount
        );

        require(isSuccess);
    }

    function _authorizeUpgrade(address) internal override onlyOwner {}
}
