// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "./Libraries/LibPool.sol";

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "./Libraries/LibCalculations.sol";
import "./poolRegistry.sol";
import { BokkyPooBahsDateTimeLibrary as BPBDTL } from "./Libraries/DateTimeLib.sol";

contract FundingPool is Initializable, ReentrancyGuardUpgradeable {
    address public poolOwner;
    address public poolRegistryAddress;

    function initialize(address _poolOwner, address _poolRegistry)
        external
        initializer
    {
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

    struct Installments {
        uint256 monthlyCycleInterest;
        uint32 installments;
        uint32 installmentsPaid;
    }

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

    //Supply to pool by lenders
    function supplyToPool(
        uint256 _poolId,
        address _ERC20Address,
        uint256 _amount,
        uint32 _maxLoanDuration,
        uint256 _expiration
    ) external nonReentrant {
        (bool isVerified, ) = poolRegistry(poolRegistryAddress)
            .lenderVerification(_poolId, msg.sender);

        require(isVerified, "Not verified lender");

        require(
            _ERC20Address != address(0),
            "you can't do this with zero address"
        );

        require(_amount != 0, "You can't supply with zero amount");
        require(_maxLoanDuration % 30 days == 0);
        require(_amount >= 10000, "amount too low");

        address lender = msg.sender;
        require(_expiration > uint32(block.timestamp), "wrong timestamp");
        uint256 _bidId = bidId;
        FundDetail storage fundDetail = lenderPoolFundDetails[lender][_poolId][
            _ERC20Address
        ][_bidId];
        fundDetail.amount = _amount;
        fundDetail.expiration = _expiration;
        fundDetail.maxDuration = _maxLoanDuration;
        fundDetail.interestRate = poolRegistry(poolRegistryAddress).getPoolApr(
            _poolId
        );
        fundDetail.bidTimestamp = uint32(block.timestamp);

        fundDetail.state = BidState.PENDING;
        fundDetail.installment.installments = _maxLoanDuration / 30 days;
        fundDetail.installment.installmentsPaid = 0;

        uint32 paymentCycle = poolRegistry(poolRegistryAddress)
            .getPaymentCycleDuration(_poolId);

        fundDetail.paymentCycleAmount = LibCalculations.payment(
            _amount,
            fundDetail.maxDuration,
            paymentCycle,
            fundDetail.interestRate
        );

        uint256 monthlyPrincipal = _amount / fundDetail.installment.installments;

        fundDetail.installment.monthlyCycleInterest = fundDetail.paymentCycleAmount - monthlyPrincipal;

        address _poolAddress = poolRegistry(poolRegistryAddress).getPoolAddress(
            _poolId
        );

        // Send payment to the Pool
        require(
            IERC20(_ERC20Address).transferFrom(lender, _poolAddress, _amount),
            "Unable to tansfer to poolAddress"
        );
        bidId++;

        emit SuppliedToPool(lender, _poolId, _bidId, _ERC20Address, _amount);
    }

    function AcceptBid(
        uint256 _poolId,
        address _ERC20Address,
        uint256 _bidId,
        address _lender,
        address _receiver
    ) external nonReentrant {
        require(poolOwner == msg.sender, "You are not the Pool Owner");
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
            poolRegistry(poolRegistryAddress).getAconomyFee()
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

    function RejectBid(
        uint256 _poolId,
        address _ERC20Address,
        uint256 _bidId,
        address _lender
    ) external nonReentrant {
        require(poolOwner == msg.sender, "You are not the Pool Owner");
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
        return uint32(block.timestamp) > calculateNextDueDate(_poolId, _ERC20Address, _bidId, _lender) + 7 days;
    }

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
        if (
            dueDate_ >
            fundDetail.acceptBidTimestamp + fundDetail.maxDuration
        ) {
            dueDate_ =
                fundDetail.acceptBidTimestamp +
                fundDetail.maxDuration;
        }
    }

    function viewInstallmentAmount(
        uint256 _poolId,
        address _ERC20Address,
        uint256 _bidId,
        address _lender
    ) external view returns(uint256){
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

        if(monthsSinceStart > lastPaymentCycle) {
            return fundDetail.paymentCycleAmount;
        }
        else {
            return 0;
        }
    }

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
        if (fundDetail.state != BidState.ACCEPTED) {
            revert("Loan must be accepted");
        }
        require(fundDetail.installment.installmentsPaid + 1 <= fundDetail.installment.installments);
        require(block.timestamp > calculateNextDueDate(_poolId, _ERC20Address, _bidId, _lender));

        uint32 paymentCycle = poolRegistry(poolRegistryAddress)
            .getPaymentCycleDuration(_poolId);

        if(fundDetail.installment.installmentsPaid + 1 == fundDetail.installment.installments) {
            _repayFullAmount(_poolId, _ERC20Address, _bidId, _lender);
        } else {
            uint256 monthlyInterest = fundDetail.installment.monthlyCycleInterest;
            uint256 monthlyDue = fundDetail.paymentCycleAmount;
            uint256 due = monthlyDue - monthlyInterest;

        (
            uint256 owedAmount,
            ,
            uint256 interest
        ) = LibCalculations.calculateInstallmentAmount(
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

            fundDetail.installment.installmentsPaid ++;

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

    // function RepayInstallment(
    //     uint256 _poolId,
    //     address _ERC20Address,
    //     uint256 _bidId,
    //     address _lender
    // ) external nonReentrant {
    //     require(poolOwner == msg.sender, "You are not the Pool Owner");
    //     FundDetail storage fundDetail = lenderPoolFundDetails[_lender][_poolId][
    //         _ERC20Address
    //     ][_bidId];
    //     if (fundDetail.state != BidState.ACCEPTED) {
    //         revert("Bid must be pending");
    //     }

    //     uint32 paymentCycle = poolRegistry(poolRegistryAddress)
    //         .getPaymentCycleDuration(_poolId);

    //     (
    //         uint256 owedAmount,
    //         uint256 dueAmount,
    //         uint256 interest
    //     ) = LibCalculations.calculateInstallmentAmount(
    //             fundDetail.amount,
    //             fundDetail.Repaid.amount,
    //             fundDetail.interestRate,
    //             fundDetail.paymentCycleAmount,
    //             paymentCycle,
    //             fundDetail.lastRepaidTimestamp,
    //             block.timestamp,
    //             fundDetail.acceptBidTimestamp,
    //             fundDetail.maxDuration
    //         );
    //     _repayBid(
    //         _poolId,
    //         _ERC20Address,
    //         _bidId,
    //         _lender,
    //         dueAmount,
    //         interest,
    //         owedAmount + interest
    //     );

    //     emit InstallmentRepaid(
    //         _poolId,
    //         _bidId,
    //         owedAmount,
    //         dueAmount,
    //         interest
    //     );
    // }

    // function viewInstallmentAmount(
    //     uint256 _poolId,
    //     address _ERC20Address,
    //     uint256 _bidId,
    //     address _lender
    // ) public view returns (uint256) {
    //     FundDetail storage fundDetail = lenderPoolFundDetails[_lender][_poolId][
    //         _ERC20Address
    //     ][_bidId];
    //     if (fundDetail.state != BidState.ACCEPTED) {
    //         revert("Bid must be accepted");
    //     }
    //     uint32 paymentCycle = poolRegistry(poolRegistryAddress)
    //         .getPaymentCycleDuration(_poolId);

    //     (, uint256 dueAmount, uint256 interest) = LibCalculations
    //         .calculateInstallmentAmount(
    //             fundDetail.amount,
    //             fundDetail.Repaid.amount,
    //             fundDetail.interestRate,
    //             fundDetail.paymentCycleAmount,
    //             paymentCycle,
    //             fundDetail.lastRepaidTimestamp,
    //             block.timestamp,
    //             fundDetail.acceptBidTimestamp,
    //             fundDetail.maxDuration
    //         );
    //     uint256 paymentAmount = dueAmount + interest;
    //     return paymentAmount;
    // }

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
                block.timestamp,
                fundDetail.acceptBidTimestamp,
                fundDetail.maxDuration
            );
        uint256 paymentAmount = owedAmount + interest;
        return paymentAmount;
    }

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
            revert("Bid must be pending");
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
            revert("Bid must be pending");
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
        // Send payment to the lender
        require(
            IERC20(_ERC20Address).transferFrom(
                msg.sender,
                _lender,
                paymentAmount
            ),
            "unable to transfer to lender"
        );

        fundDetail.Repaid.amount += _amount;
        fundDetail.Repaid.interest += _interest;
        fundDetail.lastRepaidTimestamp = uint32(block.timestamp);
    }

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

        // Transfering the amount to the lender
        require(
            IERC20(_ERC20Address).transfer(_lender, fundDetail.amount),
            "Unable to transfer to lender"
        );

        fundDetail.state = BidState.WITHDRAWN;

        emit Withdrawn(_lender, _bidId, _poolId, fundDetail.amount);
    }
}
