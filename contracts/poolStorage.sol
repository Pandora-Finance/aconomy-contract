pragma solidity 0.8.11;
// SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

abstract contract poolStorage {
    using EnumerableSet for EnumerableSet.UintSet;
    // Current number of loans.
    uint256 public loanId = 0;

    // Mapping of loanId to loan information.
    mapping(uint256 => Loan) public loans;

    //poolId => loanId => LoanState
    mapping(uint256 => uint256) public poolLoans;

    enum LoanState {
        PENDING,
        CANCELLED,
        ACCEPTED,
        PAID
    }

    /**
     * @notice Deatils for payment.
     * @param principal The principal amount involved.
     * @param interest The interest amount involved.
     */
    struct Payment {
        uint256 principal;
        uint256 interest;
    }

    /**
     * @notice Deatils for a loan.
     * @param lendingToken The lending token involved.
     * @param principal The principal amount being borrowed.
     * @param totalRepaid The total funds repaid.
     * @param timestamp The timestamp the loan was created.
     * @param acceptedTimestamp The timestamp the loan was accepted.
     * @param lastRepaidTimestamp The timestamp of the last repayment.
     * @param loanDuration The duration of the loan.
     * @param protocolFee The fee when creating a loan.
     */
    struct LoanDetails {
        ERC20 lendingToken;
        uint256 principal;
        Payment totalRepaid;
        uint32 timestamp;
        uint32 acceptedTimestamp;
        uint32 lastRepaidTimestamp;
        uint32 loanDuration;
        uint16 protocolFee;
    }

    /**
     * @notice The payment terms.
     * @param paymentCycleAmount The amount to be paid every cycle.
     * @param monthlyCycleInterest The interest to be paid every cycle.
     * @param paymentCycle The duration of a payment cycle.
     * @param APR The interest rate involved in bps.
     * @param installments The total installments for the loan repayment.
     * @param installmentsPaid The installments paid.
     */
    struct Terms {
        uint256 paymentCycleAmount;
        uint256 monthlyCycleInterest;
        uint32 paymentCycle;
        uint16 APR;
        uint32 installments;
        uint32 installmentsPaid;
    }

     /**
     * @notice The base loan struct.
     * @param borrower The borrower of the loan.
     * @param receiver The receiver of the loan funds.
     * @param lender The lender of the loan funds.
     * @param poolId The Id of the pool in which the loan was created.
     * @param loanDetails The details of the loan.
     * @param terms The terms of the loan.
     * @param state The state of the loan.
     */
    struct Loan {
        address borrower;
        address receiver;
        address lender;
        uint256 poolId;
        LoanDetails loanDetails;
        Terms terms;
        LoanState state;
    }

    // Mapping of borrowers to borrower requests.
    mapping(address => EnumerableSet.UintSet) internal borrowerActiveLoans;

    // Amount filled by all lenders.
    // Asset address => Volume amount
    mapping(address => uint256) public totalERC20Amount;

    // Mapping of borrowers to borrower requests.
    mapping(address => uint256[]) public borrowerLoans;
    mapping(uint256 => uint32) public loanDefaultDuration;
    mapping(uint256 => uint32) public loanExpirationDuration;

    // Mapping of amount filled by lenders.
    // Asset address => Lender address => Lend amount
    mapping(address => mapping(address => uint256)) public lenderLendAmount;
}
