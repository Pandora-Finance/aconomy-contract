// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "../poolStorage.sol";
import "../poolRegistry.sol";
import "../AconomyFee.sol";
import "./LibCalculations.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

library LibPoolAddress {

    function acceptLoan(poolStorage.Loan storage loan, address poolRegistryAddress, address AconomyFeeAddress) 
    external 
    returns (
            uint256 amountToAconomy,
            uint256 amountToPool,
            uint256 amountToBorrower
        )
    {
        (bool isVerified, ) = poolRegistry(poolRegistryAddress)
            .lenderVerification(loan.poolId, msg.sender);

        require(isVerified, "Not verified lender");
        require(loan.state == poolStorage.LoanState.PENDING, "loan not pending");
        require(
            !poolRegistry(poolRegistryAddress).ClosedPool(loan.poolId),
            "pool closed"
        );
        // require(!isLoanExpired(_loanId));

        loan.loanDetails.acceptedTimestamp = uint32(block.timestamp);
        loan.loanDetails.lastRepaidTimestamp = uint32(block.timestamp);

        loan.state = poolStorage.LoanState.ACCEPTED;

        loan.lender = msg.sender;

        //Aconomy Fee
        amountToAconomy = LibCalculations.percent(
            loan.loanDetails.principal,
            loan.loanDetails.protocolFee
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
            require(isSuccess, "aconomy transfer failed");
        }

        //Transfer to Pool Owner
        if (amountToPool != 0) {
            bool isSuccess2 = IERC20(loan.loanDetails.lendingToken)
                .transferFrom(
                    loan.lender,
                    poolRegistry(poolRegistryAddress).getPoolOwner(loan.poolId),
                    amountToPool
                );
            require(isSuccess2, "pool transfer failed");
        }

        //transfer funds to borrower
        bool isSuccess3 = IERC20(loan.loanDetails.lendingToken).transferFrom(
            loan.lender,
            loan.borrower,
            amountToBorrower
        );

        require(isSuccess3, "borrower transfer failed");
    }

}