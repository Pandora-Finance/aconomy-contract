// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

// import "./Libraries/LibPool.sol";

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "./Libraries/LibCalculations.sol";
import "./poolRegistry.sol";
import {BokkyPooBahsDateTimeLibrary as BPBDTL} from "./Libraries/DateTimeLib.sol";

contract FundingPool is Initializable, ReentrancyGuardUpgradeable {
    address public poolOwner;
    address public poolRegistryAddress;

    /**
     * @notice Initializer function.
     * @param _poolOwner The pool owner's address.
     * @param _poolRegistry The address of the poolRegistry contract.
     */
    function initialize(
        address _poolOwner,
        address _poolRegistry
    ) external initializer {
        poolOwner = _poolOwner;
        poolRegistryAddress = _poolRegistry;
    }

    uint256 public bidId = 0;

    event BidRepaid(uint256 indexed bidId, uint256 PaidAmount);
    event BidRepayment(uint256 indexed bidId, uint256 PaidAmount);

    event BidAccepted(
        address lender,
        address reciever,
        uint256 BidId,
        uint256 PoolId,
        uint256 Amount,
        uint256 paymentCycleAmount
    );

    event BidRejected(
        address lender,
        uint256 BidId,
        uint256 PoolId,
        uint256 Amount
    );

    event Withdrawn(
        address reciever,
        uint256 BidId,
        uint256 PoolId,
        uint256 Amount
    );

    event SuppliedToPool(
        address indexed lender,
        uint256 indexed poolId,
        uint256 BidId,
        address indexed ERC20Token,
        uint256 tokenAmount
    );

    event InstallmentRepaid(
        uint256 poolId,
        uint256 bidId,
        uint256 owedAmount,
        uint256 dueAmount,
        uint256 interest
    );

    event FullAmountRepaid(
        uint256 poolId,
        uint256 bidId,
        uint256 Amount,
        uint256 interest
    );

    /**
     * @notice Deatils for the installments.
     * @param monthlyCycleInterest The interest to be paid every cycle.
     * @param installments The total installments to be paid.
     * @param installmentsPaid The total installments paid.
     * @param defaultDuration The duration after which loan is defaulted
     * @param protocolFee The protocol fee when creating the bid.
     */
    struct Installments {
        uint256 monthlyCycleInterest;
        uint32 installments;
        uint32 installmentsPaid;
        uint32 defaultDuration;
        uint16 protocolFee;
    }

    /**
     * @notice Deatils for a fund supply.
     * @param amount The amount being funded.
     * @param expiration The timestamp within which the fund bid should be accepted.
     * @param maxDuration The bid loan duration.
     * @param interestRate The interest rate in bps.
     * @param state The state of the bid.
     * @param bidTimestamp The timestamp the bid was created.
     * @param acceptBidTimestamp The timestamp the bid was accepted.
     * @param paymentCycleAmount The amount to be paid every cycle.
     * @param totalRepaidPrincipal The total principal repaid.
     * @param lastRepaidTimestamp The timestamp of the last repayment.
     * @param installment The installment details.
     * @param repaid The amount repaid.
     */
    struct FundDetail {
        uint256 amount;
        uint256 expiration; //After expiration time, if owner dose not accept bid then lender can withdraw the fund
        uint32 maxDuration; //Bid Duration
        uint16 interestRate;
        BidState state;
        uint32 bidTimestamp;
        uint32 acceptBidTimestamp;
        uint256 paymentCycleAmount;
        uint256 totalRepaidPrincipal;
        uint32 lastRepaidTimestamp;
        Installments installment;
        RePayment Repaid;
    }

    /**
     * @notice Deatils for payment.
     * @param amount The principal amount involved.
     * @param interest The interest amount involved.
     */
    struct RePayment {
        uint256 amount;
        uint256 interest;
    }

    enum BidState {
        PENDING,
        ACCEPTED,
        PAID,
        WITHDRAWN,
        REJECTED
    }

    // Mapping of lender address => poolId => ERC20 token => BidId => FundDetail
    mapping(address => mapping(uint256 => mapping(address => mapping(uint256 => FundDetail))))
        public lenderPoolFundDetails;

    /**
     * @notice Allows a lender to supply funds to the pool owner.
     * @param _poolId The Id of the pool.
     * @param _ERC20Address The address of the funds being supplied.
     * @param _amount The amount of funds being supplied.
     * @param _maxLoanDuration The duration of the loan after being accepted.
     * @param _expiration The time stamp within which the loan has to be accepted.
     * @param _APR The annual interest in bps
     */
    function supplyToPool(
        uint256 _poolId,
        address _ERC20Address,
        uint256 _amount,
        uint32 _maxLoanDuration,
        uint256 _expiration,
        uint16 _APR
    ) external nonReentrant {
        require(
            !poolRegistry(poolRegistryAddress).ClosedPool(_poolId),
            "pool closed"
        );
        (bool isVerified, ) = poolRegistry(poolRegistryAddress)
            .lenderVerification(_poolId, msg.sender);

        require(isVerified, "Not verified lender");

        require(
            _ERC20Address != address(0),
            "you can't do this with zero address"
        );

        require(_maxLoanDuration % 30 days == 0);
        require(_APR >= 100, "apr too low");
        require(_amount >= 1000000, "amount too low");

        uint16 fee = poolRegistry(poolRegistryAddress).getAconomyFee();

        require(_expiration > uint32(block.timestamp), "wrong timestamp");
        uint256 _bidId = bidId;
        FundDetail storage fundDetail = lenderPoolFundDetails[msg.sender][
            _poolId
        ][_ERC20Address][_bidId];
        fundDetail.amount = _amount;
        fundDetail.expiration = _expiration;
        fundDetail.maxDuration = _maxLoanDuration;
        fundDetail.interestRate = _APR;
        fundDetail.bidTimestamp = uint32(block.timestamp);

        fundDetail.state = BidState.PENDING;
        fundDetail.installment.installments = _maxLoanDuration / 30 days;
        fundDetail.installment.installmentsPaid = 0;
        fundDetail.installment.protocolFee = fee;

        uint32 paymentCycle = poolRegistry(poolRegistryAddress)
            .getPaymentCycleDuration(_poolId);

        fundDetail.paymentCycleAmount = LibCalculations.payment(
            _amount,
            fundDetail.maxDuration,
            paymentCycle,
            fundDetail.interestRate
        );

        uint256 monthlyPrincipal = _amount /
            fundDetail.installment.installments;

        fundDetail.installment.monthlyCycleInterest =
            fundDetail.paymentCycleAmount -
            monthlyPrincipal;

        fundDetail.installment.defaultDuration = poolRegistry(
            poolRegistryAddress
        ).getPaymentDefaultDuration(_poolId);

        address _poolAddress = poolRegistry(poolRegistryAddress).getPoolAddress(
            _poolId
        );

        bidId++;

        // Send payment to the Pool
        require(
            IERC20(_ERC20Address).transferFrom(
                msg.sender,
                _poolAddress,
                _amount
            ),
            "Unable to tansfer to poolAddress"
        );

        emit SuppliedToPool(
            msg.sender,
            _poolId,
            _bidId,
            _ERC20Address,
            _amount
        );
    }

    /**
     * @notice Accepts the specified bid to supply to the pool.
     * @param _poolId The Id of the pool.
     * @param _ERC20Address The address of the bid funds being accepted.
     * @param _bidId The Id of the bid.
     * @param _lender The address of the lender.
     * @param _receiver The address of the funds receiver.
     */
    function AcceptBid(
        uint256 _poolId,
        address _ERC20Address,
        uint256 _bidId,
        address _lender,
        address _receiver
    ) external nonReentrant {
        require(poolOwner == msg.sender, "You are not the Pool Owner");
        require(
            !poolRegistry(poolRegistryAddress).ClosedPool(_poolId),
            "pool closed"
        );
        FundDetail storage fundDetail = lenderPoolFundDetails[_lender][_poolId][
            _ERC20Address
        ][_bidId];
        if (fundDetail.state != BidState.PENDING) {
            revert("Bid must be pending");
        }
        require(
            fundDetail.expiration >= uint32(block.timestamp),
            "bid expired"
        );
        fundDetail.acceptBidTimestamp = uint32(block.timestamp);
        fundDetail.lastRepaidTimestamp = uint32(block.timestamp);
        uint256 amount = fundDetail.amount;
        fundDetail.state = BidState.ACCEPTED;

        address AconomyOwner = poolRegistry(poolRegistryAddress)
            .getAconomyOwner();

        //Aconomy Fee
        uint256 amountToAconomy = LibCalculations.percent(
            amount,
            fundDetail.installment.protocolFee
        );

        // transfering Amount to Owner
        require(
            IERC20(_ERC20Address).transfer(_receiver, amount - amountToAconomy),
            "unable to transfer to receiver"
        );

        // transfering Amount to Protocol Owner
        if (amountToAconomy != 0) {
            require(
                IERC20(_ERC20Address).transfer(AconomyOwner, amountToAconomy),
                "Unable to transfer to AconomyOwner"
            );
        }

        emit BidAccepted(
            _lender,
            _receiver,
            _bidId,
            _poolId,
            amount,
            fundDetail.paymentCycleAmount
        );
    }

    /**
     * @notice Rejects the bid to supply to the pool.
     * @param _poolId The Id of the pool.
     * @param _ERC20Address The address of the funds contract.
     * @param _bidId The Id of the bid.
     * @param _lender The address of the lender.
     */
    function RejectBid(
        uint256 _poolId,
        address _ERC20Address,
        uint256 _bidId,
        address _lender
    ) external nonReentrant {
        require(poolOwner == msg.sender, "You are not the Pool Owner");
        require(
            !poolRegistry(poolRegistryAddress).ClosedPool(_poolId),
            "pool closed"
        );
        FundDetail storage fundDetail = lenderPoolFundDetails[_lender][_poolId][
            _ERC20Address
        ][_bidId];
        if (fundDetail.state != BidState.PENDING) {
            revert("Bid must be pending");
        }
        fundDetail.state = BidState.REJECTED;
        // transfering Amount to Lender
        require(
            IERC20(_ERC20Address).transfer(_lender, fundDetail.amount),
            "unable to transfer to receiver"
        );
        emit BidRejected(_lender, _bidId, _poolId, fundDetail.amount);
    }

    /**
     * @notice Checks if bid has expired.
     * @param _poolId The Id of the pool.
     * @param _ERC20Address The address of the funds contract.
     * @param _bidId The Id of the bid.
     * @param _lender The address of the lender.
     */
    function isBidExpired(
        uint256 _poolId,
        address _ERC20Address,
        uint256 _bidId,
        address _lender
    ) public view returns (bool) {
        FundDetail storage fundDetail = lenderPoolFundDetails[_lender][_poolId][
            _ERC20Address
        ][_bidId];

        if (fundDetail.state != BidState.PENDING) return false;
        if (fundDetail.expiration == 0) return false;

        return (uint32(block.timestamp) > fundDetail.expiration);
    }

    /**
     * @notice Checks if loan is defaulted.
     * @param _poolId The Id of the pool.
     * @param _ERC20Address The address of the funds contract.
     * @param _bidId The Id of the bid.
     * @param _lender The address of the lender.
     */
    function isLoanDefaulted(
        uint256 _poolId,
        address _ERC20Address,
        uint256 _bidId,
        address _lender
    ) public view returns (bool) {
        FundDetail storage fundDetail = lenderPoolFundDetails[_lender][_poolId][
            _ERC20Address
        ][_bidId];

        // Make sure loan cannot be liquidated if it is not active
        if (fundDetail.state != BidState.ACCEPTED) return false;

        if (fundDetail.installment.defaultDuration == 0) return false;

        return ((int32(uint32(block.timestamp)) -
            int32(fundDetail.acceptBidTimestamp + fundDetail.maxDuration)) >
            int32(fundDetail.installment.defaultDuration));
    }

    /**
     * @notice Checks if loan repayment is late.
     * @dev Returned value is type boolean.
     * @param _poolId The Id of the pool.
     * @param _ERC20Address The address of the erc20 funds.
     * @param _bidId The Id of the bid.
     * @param _lender The lender address.
     * @return boolean of late payment.
     */
    function isPaymentLate(
        uint256 _poolId,
        address _ERC20Address,
        uint256 _bidId,
        address _lender
    ) public view returns (bool) {
        FundDetail storage fundDetail = lenderPoolFundDetails[_lender][_poolId][
            _ERC20Address
        ][_bidId];
        if (fundDetail.state != BidState.ACCEPTED) return false;
        return
            uint32(block.timestamp) >
            calculateNextDueDate(_poolId, _ERC20Address, _bidId, _lender) +
                7 days;
    }

    /**
     * @notice Calculates and returns the next due date.
     * @dev Returned value is type uint256.
     * @param _poolId The Id of the pool.
     * @param _ERC20Address The address of the erc20 funds.
     * @param _bidId The Id of the bid.
     * @param _lender The lender address.
     * @return dueDate_ unix time of due date in uint256.
     */
    function calculateNextDueDate(
        uint256 _poolId,
        address _ERC20Address,
        uint256 _bidId,
        address _lender
    ) public view returns (uint256 dueDate_) {
        FundDetail storage fundDetail = lenderPoolFundDetails[_lender][_poolId][
            _ERC20Address
        ][_bidId];
        if (fundDetail.state != BidState.ACCEPTED) return dueDate_;

        uint256 paymentCycle = poolRegistry(poolRegistryAddress)
            .getPaymentCycleDuration(_poolId);

        // Start with the original due date being 1 payment cycle since loan was accepted
        dueDate_ = fundDetail.acceptBidTimestamp + paymentCycle;

        // Calculate the cycle number the last repayment was made
        uint32 delta = fundDetail.lastRepaidTimestamp -
            fundDetail.acceptBidTimestamp;
        if (delta > 0) {
            uint256 repaymentCycle = (delta / paymentCycle);
            dueDate_ += (repaymentCycle * paymentCycle);
        }

        //if we are in the last payment cycle, the next due date is the end of loan duration
        if (dueDate_ > fundDetail.acceptBidTimestamp + fundDetail.maxDuration) {
            dueDate_ = fundDetail.acceptBidTimestamp + fundDetail.maxDuration;
        }
    }

    /**
     * @notice Returns the installment amount to be paid at the called timestamp.
     * @dev Returned value is type uint256.
     * @param _poolId The Id of the pool.
     * @param _ERC20Address The address of the erc20 funds.
     * @param _bidId The Id of the bid.
     * @param _lender The lender address.
     * @return installment amount in uint256.
     */
    function viewInstallmentAmount(
        uint256 _poolId,
        address _ERC20Address,
        uint256 _bidId,
        address _lender
    ) external view returns (uint256) {
        FundDetail storage fundDetail = lenderPoolFundDetails[_lender][_poolId][
            _ERC20Address
        ][_bidId];
        uint32 LastRepaidTimestamp = fundDetail.lastRepaidTimestamp;
        uint256 lastPaymentCycle = BPBDTL.diffMonths(
            fundDetail.acceptBidTimestamp,
            LastRepaidTimestamp
        );
        uint256 monthsSinceStart = BPBDTL.diffMonths(
            fundDetail.acceptBidTimestamp,
            block.timestamp
        );

        if (
            fundDetail.installment.installmentsPaid + 1 ==
            fundDetail.installment.installments
        ) {
            return viewFullRepayAmount(_poolId, _ERC20Address, _bidId, _lender);
        }

        if (monthsSinceStart > lastPaymentCycle) {
            return fundDetail.paymentCycleAmount;
        } else {
            return 0;
        }
    }

    /**
     * @notice Repays the monthly installment.
     * @param _poolId The Id of the pool.
     * @param _ERC20Address The address of the erc20 funds.
     * @param _bidId The Id of the bid.
     * @param _lender The lender address.
     */
    function repayMonthlyInstallment(
        uint256 _poolId,
        address _ERC20Address,
        uint256 _bidId,
        address _lender
    ) external nonReentrant {
        require(poolOwner == msg.sender, "You are not the Pool Owner");
        FundDetail storage fundDetail = lenderPoolFundDetails[_lender][_poolId][
            _ERC20Address
        ][_bidId];
        require(fundDetail.amount / fundDetail.installment.installments >= 1000000, "low");
        if (fundDetail.state != BidState.ACCEPTED) {
            revert("Loan must be accepted");
        }
        require(
            fundDetail.installment.installmentsPaid + 1 <=
                fundDetail.installment.installments
        );
        require(
            block.timestamp >
                calculateNextDueDate(_poolId, _ERC20Address, _bidId, _lender)
        );

        uint32 paymentCycle = poolRegistry(poolRegistryAddress)
            .getPaymentCycleDuration(_poolId);

        if (
            fundDetail.installment.installmentsPaid + 1 ==
            fundDetail.installment.installments
        ) {
            _repayFullAmount(_poolId, _ERC20Address, _bidId, _lender);
        } else {
            uint256 monthlyInterest = fundDetail
                .installment
                .monthlyCycleInterest;
            uint256 monthlyDue = fundDetail.paymentCycleAmount;
            uint256 due = monthlyDue - monthlyInterest;

            (uint256 owedAmount, , uint256 interest) = LibCalculations
                .calculateInstallmentAmount(
                    fundDetail.amount,
                    fundDetail.Repaid.amount,
                    fundDetail.interestRate,
                    fundDetail.paymentCycleAmount,
                    paymentCycle,
                    fundDetail.lastRepaidTimestamp,
                    block.timestamp,
                    fundDetail.acceptBidTimestamp,
                    fundDetail.maxDuration
                );

            fundDetail.installment.installmentsPaid++;

            _repayBid(
                _poolId,
                _ERC20Address,
                _bidId,
                _lender,
                due,
                monthlyInterest,
                owedAmount + interest
            );

            fundDetail.lastRepaidTimestamp =
                fundDetail.acceptBidTimestamp +
                (fundDetail.installment.installmentsPaid * paymentCycle);
        }
    }

    /**
     * @notice Returns the full amount to be repaid.
     * @dev Returned value is type uint256.
     * @param _poolId The Id of the pool.
     * @param _ERC20Address The address of the erc20 funds.
     * @param _bidId The Id of the bid.
     * @param _lender The lender address.
     * @return Full amount to be paid in uint256.
     */
    function viewFullRepayAmount(
        uint256 _poolId,
        address _ERC20Address,
        uint256 _bidId,
        address _lender
    ) public view returns (uint256) {
        FundDetail storage fundDetail = lenderPoolFundDetails[_lender][_poolId][
            _ERC20Address
        ][_bidId];
        if (
            fundDetail.state != BidState.ACCEPTED ||
            fundDetail.state == BidState.PAID
        ) {
            return 0;
        }
        uint32 paymentCycle = poolRegistry(poolRegistryAddress)
            .getPaymentCycleDuration(_poolId);

        (uint256 owedAmount, , uint256 interest) = LibCalculations
            .calculateInstallmentAmount(
                fundDetail.amount,
                fundDetail.Repaid.amount,
                fundDetail.interestRate,
                fundDetail.paymentCycleAmount,
                paymentCycle,
                fundDetail.lastRepaidTimestamp,
                block.timestamp + 10 minutes,
                fundDetail.acceptBidTimestamp,
                fundDetail.maxDuration
            );
        uint256 paymentAmount = owedAmount + interest;
        return paymentAmount;
    }

    /**
     * @notice Repays the full amount for the loan.
     * @param _poolId The Id of the pool.
     * @param _ERC20Address The address of the erc20 funds.
     * @param _bidId The Id of the bid.
     * @param _lender The lender address.
     */
    function _repayFullAmount(
        uint256 _poolId,
        address _ERC20Address,
        uint256 _bidId,
        address _lender
    ) private {
        require(poolOwner == msg.sender, "You are not the Pool Owner");
        FundDetail storage fundDetail = lenderPoolFundDetails[_lender][_poolId][
            _ERC20Address
        ][_bidId];
        if (fundDetail.state != BidState.ACCEPTED) {
            revert("Bid must be accepted");
        }

        uint32 paymentCycle = poolRegistry(poolRegistryAddress)
            .getPaymentCycleDuration(_poolId);

        (uint256 owedAmount, , uint256 interest) = LibCalculations
            .calculateInstallmentAmount(
                fundDetail.amount,
                fundDetail.Repaid.amount,
                fundDetail.interestRate,
                fundDetail.paymentCycleAmount,
                paymentCycle,
                fundDetail.lastRepaidTimestamp,
                block.timestamp,
                fundDetail.acceptBidTimestamp,
                fundDetail.maxDuration
            );
        _repayBid(
            _poolId,
            _ERC20Address,
            _bidId,
            _lender,
            owedAmount,
            interest,
            owedAmount + interest
        );

        emit FullAmountRepaid(_poolId, _bidId, owedAmount, interest);
    }

    /**
     * @notice Repays the full amount for the loan.
     * @param _poolId The Id of the pool.
     * @param _ERC20Address The address of the erc20 funds.
     * @param _bidId The Id of the bid.
     * @param _lender The lender address.
     */
    function RepayFullAmount(
        uint256 _poolId,
        address _ERC20Address,
        uint256 _bidId,
        address _lender
    ) external nonReentrant {
        require(poolOwner == msg.sender, "You are not the Pool Owner");
        FundDetail storage fundDetail = lenderPoolFundDetails[_lender][_poolId][
            _ERC20Address
        ][_bidId];
        if (fundDetail.state != BidState.ACCEPTED) {
            revert("Bid must be accepted");
        }

        uint32 paymentCycle = poolRegistry(poolRegistryAddress)
            .getPaymentCycleDuration(_poolId);

        (uint256 owedAmount, , uint256 interest) = LibCalculations
            .calculateInstallmentAmount(
                fundDetail.amount,
                fundDetail.Repaid.amount,
                fundDetail.interestRate,
                fundDetail.paymentCycleAmount,
                paymentCycle,
                fundDetail.lastRepaidTimestamp,
                block.timestamp,
                fundDetail.acceptBidTimestamp,
                fundDetail.maxDuration
            );
        _repayBid(
            _poolId,
            _ERC20Address,
            _bidId,
            _lender,
            owedAmount,
            interest,
            owedAmount + interest
        );

        emit FullAmountRepaid(_poolId, _bidId, owedAmount, interest);
    }

    /**
     * @notice Repays the specified amount for the loan.
     * @param _poolId The Id of the pool.
     * @param _ERC20Address The address of the erc20 funds.
     * @param _bidId The Id of the bid.
     * @param _lender The lender address.
     * @param _amount The amount being repaid.
     * @param _interest The interest being repaid.
     * @param _owedAmount The total owed amount at the called timestamp.
     */
    function _repayBid(
        uint256 _poolId,
        address _ERC20Address,
        uint256 _bidId,
        address _lender,
        uint256 _amount,
        uint256 _interest,
        uint256 _owedAmount
    ) internal {
        FundDetail storage fundDetail = lenderPoolFundDetails[_lender][_poolId][
            _ERC20Address
        ][_bidId];

        uint256 paymentAmount = _amount + _interest;

        // Check if we are sending a payment or amount remaining
        if (paymentAmount >= _owedAmount) {
            paymentAmount = _owedAmount;

            fundDetail.state = BidState.PAID;
            emit BidRepaid(_bidId, paymentAmount);
        } else {
            emit BidRepayment(_bidId, paymentAmount);
        }

        fundDetail.Repaid.amount += _amount;
        fundDetail.Repaid.interest += _interest;
        fundDetail.lastRepaidTimestamp = uint32(block.timestamp);

        // Send payment to the lender
        require(
            IERC20(_ERC20Address).transferFrom(
                msg.sender,
                _lender,
                paymentAmount
            ),
            "unable to transfer to lender"
        );
    }

    /**
     * @notice Allows the lender to withdraw the loan bid if it is still pending.
     * @param _poolId The Id of the pool.
     * @param _ERC20Address The address of the erc20 funds.
     * @param _bidId The Id of the bid.
     * @param _lender The lender address.
     */
    function Withdraw(
        uint256 _poolId,
        address _ERC20Address,
        uint256 _bidId,
        address _lender
    ) external nonReentrant {
        FundDetail storage fundDetail = lenderPoolFundDetails[_lender][_poolId][
            _ERC20Address
        ][_bidId];

        if (fundDetail.state != BidState.PENDING) {
            revert("Bid must be pending");
        }

        // Check is lender the calling the function
        if (_lender != msg.sender) {
            revert("You are not a Lender");
        }

        require(
            fundDetail.expiration < uint32(block.timestamp),
            "You can't Withdraw"
        );

        fundDetail.state = BidState.WITHDRAWN;

        // Transfering the amount to the lender
        require(
            IERC20(_ERC20Address).transfer(_lender, fundDetail.amount),
            "Unable to transfer to lender"
        );

        emit Withdrawn(_lender, _bidId, _poolId, fundDetail.amount);
    }
}
