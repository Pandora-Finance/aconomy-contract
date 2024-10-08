// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import {SafeMath} from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./poolRegistry.sol";
import "./poolStorage.sol";
import "./AconomyFee.sol";
import "./Libraries/LibCalculations.sol";
import "./interfaces/IaccountStatus.sol";

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract poolAddress is poolStorage, ReentrancyGuard {
    address poolRegistryAddress;
    address AconomyFeeAddress;

    using SafeMath for uint256;
    using EnumerableSet for EnumerableSet.UintSet;

    constructor(address _poolRegistry, address _AconomyFeeAddress) {
        poolRegistryAddress = _poolRegistry;
        AconomyFeeAddress = _AconomyFeeAddress;
    }

    modifier pendingLoan(uint256 _loanId) {
        if (loans[_loanId].state != LoanState.PENDING) {
            revert("Loan must be pending");
        }
        _;
    }

    modifier onlyPoolOwner(uint256 poolId) {
        require(
            msg.sender == poolRegistry(poolRegistryAddress).getPoolOwner(poolId)
        );
        _;
    }

    event loanAccepted(uint256 indexed loanId, address indexed lender);

    event repaidAmounts(
        uint256 owedPrincipal,
        uint256 duePrincipal,
        uint256 interest
    );
    event AcceptedLoanDetail(
        uint256 indexed loanId,
        string indexed feeType,
        uint256 indexed amount
    );

    event LoanRepaid(uint256 indexed loanId, uint256 Amount);
    event LoanRepayment(uint256 indexed loanId, uint256 Amount);

    event SubmittedLoan(
        uint256 indexed loanId,
        address indexed borrower,
        address receiver,
        uint256 paymentCycleAmount
    );

    function loanRequest(
        address _lendingToken,
        uint256 _poolId,
        uint256 _principal,
        uint32 _duration,
        uint16 _APR,
        address _receiver
    ) public returns (uint256 loanId_) {
        (bool isVerified, ) = poolRegistry(poolRegistryAddress)
            .borrowerVarification(_poolId, msg.sender);
        require(isVerified, "Not verified borrower");
        require(
            !poolRegistry(poolRegistryAddress).ClosedPool(_poolId),
            "Pool is closed"
        );

        loanId_ = loanId;

        poolLoans[_poolId] = loanId_;

        // Create and store our loan into the mapping
        Loan storage loan = loans[loanId];
        loan.borrower = msg.sender;
        loan.receiver = _receiver != address(0) ? _receiver : loan.borrower;
        loan.poolId = _poolId;
        loan.loanDetails.lendingToken = ERC20(_lendingToken);
        loan.loanDetails.principal = _principal;
        loan.loanDetails.loanDuration = _duration;
        loan.loanDetails.timestamp = uint32(block.timestamp);

        loan.terms.paymentCycle = poolRegistry(poolRegistryAddress)
            .getPaymentCycleDuration(_poolId);

        loan.terms.APR = _APR;

        loanDefaultDuration[loanId] = poolRegistry(poolRegistryAddress)
            .getPaymentDefaultDuration(_poolId);

        loanExpirationTime[loanId] = poolRegistry(poolRegistryAddress)
            .getloanExpirationTime(_poolId);

        loan.terms.paymentCycleAmount = LibCalculations.payment(
            _principal,
            _duration,
            loan.terms.paymentCycle,
            _APR
        );

        loan.state = LoanState.PENDING;

        emit SubmittedLoan(
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

    function AcceptLoan(uint256 _loanId)
        external
        pendingLoan(_loanId)
        nonReentrant
        returns (
            uint256 amountToAconomy,
            uint256 amountToPool,
            uint256 amountToBorrower
        )
    {
        Loan storage loan = loans[_loanId];

        (bool isVerified, ) = poolRegistry(poolRegistryAddress)
            .lenderVarification(loan.poolId, msg.sender);

        require(isVerified, "Not verified lender");
        require(
            !poolRegistry(poolRegistryAddress).ClosedPool(loan.poolId),
            "Pool is closed"
        );
        require(!isLoanExpired(_loanId), "Loan has expired");

        loan.loanDetails.acceptedTimestamp = uint32(block.timestamp);
        loan.loanDetails.lastRepaidTimestamp = uint32(block.timestamp);

        loan.state = LoanState.ACCEPTED;

        loan.lender = msg.sender;

        //Aconomy Fee
        amountToAconomy = LibCalculations.percent(
            loan.loanDetails.principal,
            AconomyFee(AconomyFeeAddress).protocolFee()
        );

        //Pool Fee
        amountToPool = LibCalculations.percent(
            loan.loanDetails.principal,
            poolRegistry(poolRegistryAddress).getPoolFee(loan.poolId)
        );

        //Amount to Borrower
        amountToBorrower =
            loan.loanDetails.principal -
            amountToAconomy -
            amountToPool;

        //Transfer Aconomy Fee
        if (amountToAconomy != 0) {
            bool isSuccess = IERC20(loan.loanDetails.lendingToken).transferFrom(
                loan.lender,
                AconomyFee(AconomyFeeAddress).getAconomyOwnerAddress(),
                amountToAconomy
            );
            require(isSuccess, "Not able to tansfer to aconomy fee address");
        }

        //Transfer to Pool Owner
        if (amountToPool != 0) {
            bool isSuccess2 = IERC20(loan.loanDetails.lendingToken)
                .transferFrom(
                    loan.lender,
                    poolRegistry(poolRegistryAddress).getPoolOwner(loan.poolId),
                    amountToPool
                );
            require(isSuccess2, "Not able to tansfer to pool owner");
        }

        //transfer funds to borrower
        bool isSuccess3 = IERC20(loan.loanDetails.lendingToken).transferFrom(
            loan.lender,
            loan.borrower,
            amountToBorrower
        );

        require(isSuccess3, "Not able to tansfer to borrower");

        // Record Amount filled by lenders
        lenderLendAmount[address(loan.loanDetails.lendingToken)][
            loan.lender
        ] += loan.loanDetails.principal;
        totalERC20Amount[address(loan.loanDetails.lendingToken)] += loan
            .loanDetails
            .principal;

        // Store Borrower's active loan
        require(
            borrowerActiveLoans[loan.borrower].add(_loanId),
            "accept loan failed, add to borrweractiveloans"
        );

        emit loanAccepted(_loanId, loan.lender);

        emit AcceptedLoanDetail(_loanId, "protocol", amountToAconomy);
        emit AcceptedLoanDetail(_loanId, "Pool", amountToPool);
        emit AcceptedLoanDetail(_loanId, "Borrower", amountToBorrower);
    }

    function isLoanExpired(uint256 _loanId) public view returns (bool) {
        Loan storage loan = loans[_loanId];

        if (loan.state != LoanState.PENDING) return false;
        if (loanExpirationTime[_loanId] == 0) return false;

        return (uint32(block.timestamp) >
            loan.loanDetails.timestamp + loanExpirationTime[_loanId]);
    }

    function isLoanDefaulted(uint256 _loanId) public view returns (bool) {
        Loan storage loan = loans[_loanId];

        // Make sure loan cannot be liquidated if it is not active
        if (loan.state != LoanState.ACCEPTED) return false;

        if (loanDefaultDuration[_loanId] == 0) return false;

        return (uint32(block.timestamp) - lastRepaidTimestamp(_loanId) >
            loanDefaultDuration[_loanId]);
    }

    function lastRepaidTimestamp(uint256 _loanId) public view returns (uint32) {
        return LibCalculations.lastRepaidTimestamp(loans[_loanId]);
    }

    function isPaymentLate(uint256 _loanId) public view returns (bool) {
        if (loans[_loanId].state != LoanState.ACCEPTED) return false;
        return uint32(block.timestamp) > calculateNextDueDate(_loanId);
    }

    function calculateNextDueDate(uint256 _loanId)
        public
        view
        returns (uint32 dueDate_)
    {
        Loan storage loan = loans[_loanId];
        if (loans[_loanId].state != LoanState.ACCEPTED) return dueDate_;

        // Start with the original due date being 1 payment cycle since loan was accepted
        dueDate_ = loan.loanDetails.acceptedTimestamp + loan.terms.paymentCycle;

        // Calculate the cycle number the last repayment was made
        uint32 delta = lastRepaidTimestamp(_loanId) -
            loan.loanDetails.acceptedTimestamp;
        if (delta > 0) {
            uint32 repaymentCycle = 1 + (delta / loan.terms.paymentCycle);
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

    function repayYourLoan(uint256 _loanId) external nonReentrant {
        if (loans[_loanId].state != LoanState.ACCEPTED) {
            revert("Loan must be accepted");
        }
        (
            uint256 owedAmount,
            uint256 dueAmount,
            uint256 interest
        ) = LibCalculations.owedAmount(loans[_loanId], block.timestamp);
        _repayLoan(
            _loanId,
            Payment({principal: dueAmount, interest: interest}),
            owedAmount + interest
        );
        emit repaidAmounts(owedAmount, dueAmount, interest);
    }

    function viewInstallmentAmount(uint256 _loanId)
        public
        view
        returns (uint256)
    {
        if (loans[_loanId].state != LoanState.ACCEPTED) {
            revert("Loan must be accepted");
        }
        (
            uint256 owedAmount,
            uint256 dueAmount,
            uint256 interest
        ) = LibCalculations.owedAmount(loans[_loanId], block.timestamp);

        uint256 paymentAmount = dueAmount + interest;
        return paymentAmount;
    }

    function viewFullRepayAmount(uint256 _loanId)
        public
        view
        returns (uint256)
    {
        if (loans[_loanId].state != LoanState.ACCEPTED) {
            revert("Loan must be accepted");
        }
        (
            uint256 owedAmount,
            uint256 dueAmount,
            uint256 interest
        ) = LibCalculations.owedAmount(loans[_loanId], block.timestamp);

        uint256 paymentAmount = owedAmount + interest;
        return paymentAmount;
    }

    function repayFullLoan(uint256 _loanId) external nonReentrant {
        if (loans[_loanId].state != LoanState.ACCEPTED) {
            revert("Loan must be accepted");
        }
        (uint256 owedPrincipal, , uint256 interest) = LibCalculations
            .owedAmount(loans[_loanId], block.timestamp);
        _repayLoan(
            _loanId,
            Payment({principal: owedPrincipal, interest: interest}),
            owedPrincipal + interest
        );
    }

    function _repayLoan(
        uint256 _loanId,
        Payment memory _payment,
        uint256 _owedAmount
    ) internal {
        Loan storage loan = loans[_loanId];
        uint256 paymentAmount = _payment.principal + _payment.interest;
        uint256 poolId_ = loan.poolId;
        address poolAddress_ = poolRegistry(poolRegistryAddress).getPoolAddress(
            poolId_
        );

        // Check if we are sending a payment or amount remaining
        if (paymentAmount >= _owedAmount) {
            paymentAmount = _owedAmount;
            loan.state = LoanState.PAID;

            // Remove borrower's active loan
            require(
                borrowerActiveLoans[loan.borrower].remove(_loanId),
                "not able to repay, remove loanId failed"
            );

            emit LoanRepaid(_loanId, paymentAmount);
        } else {
            emit LoanRepayment(_loanId, paymentAmount);
        }
        // Send payment to the lender
        bool isSuccess = IERC20(loan.loanDetails.lendingToken).transferFrom(
            msg.sender,
            loan.lender,
            paymentAmount
        );

        require(isSuccess, "unable to transfer to lender");

        loan.loanDetails.totalRepaid.principal += _payment.principal;
        loan.loanDetails.totalRepaid.interest += _payment.interest;
        loan.loanDetails.lastRepaidTimestamp = uint32(block.timestamp);
    }
}
