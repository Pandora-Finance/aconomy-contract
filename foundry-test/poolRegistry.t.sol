// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;
import "forge-std/Test.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "forge-std/console.sol";
import "contracts/poolRegistry.sol";
import "contracts/AconomyFee.sol";
import "contracts/poolAddress.sol";

import "contracts/AttestationServices.sol";
import "contracts/Libraries/LibPool.sol";
import "contracts/utils/sampleERC20.sol";


contract poolRegistryTest is Test {
        AconomyFee aconomyFee;
        SampleERC20 sampleERC20;
        AttestationRegistry attestRegistry;
        AttestationServices attestServices;
        FundingPool fundingPool;
        poolRegistry poolRegis;
        poolAddress poolAddressInstance;



    uint32 public paymentCycleDuration = 30 days;
    uint32 public expiration = 2 days;
    uint32 public loanDuration = 150 days;
    uint32 public loanDefaultDuration = 90 days;
    uint32 public loanExpirationDuration = 180 days;
    uint256 public t = block.timestamp;


    // uint256 public poolId1;
    // uint256 public poolId2;
    // uint256 public loanId1;
    // uint256 public newpoolId;




    address payable account1 = payable(address(0xABCD));
    address payable account0 = payable(address(0xABEE));
    address payable random = payable(address(0xABCC));
    address payable account3 = payable(address(0xABDE));
    address payable account2 = payable(address(0xABCE));

    function testDeployandInitialize() public {
        vm.startPrank(account0);
        sampleERC20 = new SampleERC20();   
        aconomyFee = new AconomyFee();
        attestRegistry= new AttestationRegistry();
        attestServices= new AttestationServices(attestRegistry);

        fundingPool = new FundingPool();
        // fundingPool.initialize(address(factory),alice,"Aconomy","ACO");
         address implementation = address(new poolRegistry());

        address proxy = address(new ERC1967Proxy(implementation, ""));
        poolRegis = poolRegistry(proxy);
          poolRegis.initialize(attestServices,address(aconomyFee),address(fundingPool));
        poolRegis.transferOwnership(account0);


        address implementation1= address(new poolAddress());
        address proxy1= address(new ERC1967Proxy(implementation1, ""));
        poolAddressInstance = poolAddress(proxy1);
        poolAddressInstance.initialize(address(poolRegis),address(aconomyFee));
        poolAddressInstance.transferOwnership(account0);

        fundingPool.initialize(account0,address(poolRegis));


vm.stopPrank();

    }  
    function test_owner() public {
        testDeployandInitialize();
        assertEq(poolRegis.owner(),account0,"not the owner");
        assertEq(poolAddressInstance.owner(),account0,"not  owner");

        assertEq(fundingPool.poolOwner(),account0,"not  owner");

        
    }
    function test_SetAconomyFee() public {
        test_owner();
    // should set Aconomyfee

    // Set AconomyPoolFee to 200
    vm.startPrank(account0);
    aconomyFee.setAconomyPoolFee(200);

    uint256 protocolFee = aconomyFee.AconomyPoolFee();
    assertEq(protocolFee, 200, "AconomyPoolFee should be set to 200");

    // Verify the AconomyFee owner address
    address aconomyFeeOwner = aconomyFee.getAconomyOwnerAddress();
    assertEq(aconomyFeeOwner, account0, "AconomyFee owner should be account0");
    vm.stopPrank();
}
function test_PauseUnpauseNonOwner() public {
    // should not let non owner to pause and unpause the contract
    test_SetAconomyFee();

    // Attempt to pause the contract by a non-owner
        vm.startPrank(random);

    vm.expectRevert(bytes("Ownable: caller is not the owner"));
        poolRegis.pause();
        vm.stopPrank();


    // Pause the contract by owner
    vm.prank(account0);
    poolRegis.pause();


    // Attempt to unpause the contract by a non-owner
            vm.startPrank(random);

            vm.expectRevert(bytes("Ownable: caller is not the owner"));
                poolRegis.unpause();
            vm.stopPrank();



    // Unpause the contract by owner
        vm.prank(account0);
        poolRegis.unpause();
}
function test_create_attestRegistry()  public {
// should create attestRegistry 
test_PauseUnpauseNonOwner();
        assert(address(attestServices) != address(0));
}
function test_CreatePool() public {
    // should create Pool
     test_create_attestRegistry();
     vm.startPrank(account0);

    // Create a new pool
  uint256 poolId1 = poolRegis.createPool(
        loanDefaultDuration,
        loanExpirationDuration,
        100,
        1000,
        "adya.com",
        true,
        true
    );
assertEq(poolId1,1,"invalid poolId");
    // Get the pool address
    // address pool1Address = poolRegis.getPoolAddress(poolId1);

    // Perform lender verification
   (bool isVerified ,) = poolRegis.lenderVerification(poolId1, account0);
    assertTrue(isVerified, "Lender verification failed");

    // Perform borrower verification
    (bool isVerified_ ,) = poolRegis.borrowerVerification(poolId1, account0);
    assertTrue(isVerified_, "Borrower verification failed");
    vm.stopPrank();
    
}
function test_Create_new_Pool() public {
// should create a new Pool 
test_CreatePool();
vm.startPrank(account0);

    // Create a new pool
  uint256 poolId2 = poolRegis.createPool(
              211111111,
              2111111222,
              100,
              1000,
              "Adya.com",
              false,
              false
    );
assertEq(poolId2,2,"invalid poolId");
    // Get the pool address
    // address pool1Address = poolRegis.getPoolAddress(poolId1);

    // Perform lender verification
   (bool isVerified ,) = poolRegis.lenderVerification(poolId2, account0);
    assertTrue(isVerified, "Lender verification failed");

    // Perform borrower verification
    (bool isVerified_ ,) = poolRegis.borrowerVerification(poolId2, account0);
    assertTrue(isVerified_, "Borrower verification failed");
    vm.stopPrank();
    
}
function test_Create_another_Pool() public {
// should create another new Pool 
test_Create_new_Pool();
vm.startPrank(account0);

    // Create a new pool
  uint256 poolId3 = poolRegis.createPool(
              211111111,
              2111111222,
              100,
              1000,
              "Adya.com",
              true,
              true
    );
assertEq(poolId3,3,"invalid poolId");
    // Get the pool address
    // address pool1Address = poolRegis.getPoolAddress(poolId1);

    // Perform lender verification
   (bool isVerified ,) = poolRegis.lenderVerification(poolId3, account0);
    assertTrue(isVerified, "Lender verification failed");

    // Perform borrower verification
    (bool isVerified_ ,) = poolRegis.borrowerVerification(poolId3, account0);
    assertTrue(isVerified_, "Borrower verification failed");
    vm.stopPrank();
}

function test_ChangePoolURI() public {
    // should change the URI
 test_Create_another_Pool();
     vm.startPrank(account0);

    // Get the current URI
    string memory uri = poolRegis.getPoolUri(3);
    assertEq(uri, "Adya.com", "Incorrect initial URI");

    // Change the URI to "XYZ"
    poolRegis.setPoolURI(3, "XYZ");

    // Verify the URI change
    uri = poolRegis.getPoolUri(3);
    assertEq(uri, "XYZ", "URI not changed to XYZ");
    vm.stopPrank();

    // Try to change the URI as a non-owner (should revert)
    vm.startPrank(random);
    vm.expectRevert(bytes("Not the owner"));
    poolRegis.setPoolURI(3, "ABC");
        vm.stopPrank();

     vm.startPrank(account0);

        poolRegis.setPoolURI(3, "adya.com");
        string memory uri1 = poolRegis.getPoolUri(3);
        assertEq(uri1,"adya.com", "Incorrect Final URI");


    vm.stopPrank();
}
function test_ChangePoolAPR() public {
    // should change the APR
test_ChangePoolURI();
    vm.startPrank(account0);

    // Get the current APR
    uint256 apr = poolRegis.getPoolApr(3);
    assertEq(apr, 1000, "Incorrect initial APR");

    // Change the APR to 200
    poolRegis.setApr(3, 1000);

    // Verify the APR change
    uint256 newAPR = poolRegis.getPoolApr(3);
    assertEq(newAPR, 1000, "APR not changed to 200");
        vm.stopPrank();


    // Try to change the APR as a non-owner (should revert)
    vm.startPrank(random);
    vm.expectRevert(bytes("Not the owner"));
    poolRegis.setApr(3, 1000);
    vm.stopPrank();

    // Try to set APR lower than the minimum allowed (should revert)
    vm.startPrank(account0);
    vm.expectRevert(bytes("given apr too low"));
    poolRegis.setApr(3, 99);

    poolRegis.setApr(3, 200);
     uint256 changedAPR = poolRegis.getPoolApr(3);
    assertEq(changedAPR, 200, "APR not changed to 200");

    vm.stopPrank();
}
function test_ChangePaymentDefaultDuration() public {
    // should change the payment default duration
    test_ChangePoolAPR();
    vm.startPrank(account0);

    // Get the current payment default duration
    uint256 defaultDuration = poolRegis.getPaymentDefaultDuration(3);
    assertEq(defaultDuration, 211111111, "Incorrect initial default duration");

    // Change the default duration to 211111112
    poolRegis.setPaymentDefaultDuration(3, 211111112);

    // Verify the default duration change
    uint256 newDefaultDuration = poolRegis.getPaymentDefaultDuration(3);
    assertEq(newDefaultDuration, 211111112, "Default duration not changed to 211111112");

    // Try to change the default duration as a non-owner (should revert)
    vm.startPrank(random);
    vm.expectRevert(bytes("Not the owner"));
    poolRegis.setPaymentDefaultDuration(3, 211111113);
    vm.stopPrank();

    // Try to set default duration to 0 (should revert)
    vm.startPrank(account0);
    vm.expectRevert(bytes("default duration cannot be 0"));
    poolRegis.setPaymentDefaultDuration(3, 0);
    vm.stopPrank();

    vm.startPrank(account0);

poolRegis.setPaymentDefaultDuration(3, 211111112);
uint256 UpdatedDefaultDuration = poolRegis.getPaymentDefaultDuration(3);
    assertEq(UpdatedDefaultDuration, 211111112, "Default duration not changed to");
        vm.stopPrank();



}

function test_ChangePoolFeePercent() public {
    // should change the Pool Fee percent
    test_ChangePaymentDefaultDuration();
    vm.startPrank(account0);

    // Get the current Pool Fee percent
    uint256 poolFeePercent = poolRegis.getPoolFeePercent(3);
    assertEq(poolFeePercent, 100, "Incorrect initial Pool Fee percent");

    // Change the Pool Fee percent to 200
    poolRegis.setPoolFeePercent(3, 100);

    // Verify the Pool Fee percent change
    uint256 newPoolFeePercent = poolRegis.getPoolFeePercent(3);
    assertEq(newPoolFeePercent, 100, "Pool Fee percent not changed to 200");

    // Try to change the Pool Fee percent as a non-owner (should revert)
    vm.startPrank(random);
    vm.expectRevert(bytes("Not the owner"));
    poolRegis.setPoolFeePercent(3, 100);
    vm.stopPrank();

    // Try to set Pool Fee percent to 1001 (should revert)
    vm.startPrank(account0);
    vm.expectRevert(bytes("cannot exceed 10%"));
    poolRegis.setPoolFeePercent(3, 1001);
    vm.stopPrank();

    vm.startPrank(account0);
poolRegis.setPoolFeePercent(3, 200);

// Verify the updated Pool Fee percent change
uint256 updatedPoolFeePercent = poolRegis.getPoolFeePercent(3);
assertEq(updatedPoolFeePercent, 200, "Pool Fee percent not changed to 200");
}
function test_ChangeLoanExpirationTime() public {
    // should change the loan Expiration Time
    test_ChangePoolFeePercent();
    vm.startPrank(account0);

    // Get the current loan Expiration Time
    uint256 loanExpirationTime = poolRegis.getloanExpirationTime(3);
    assertEq(loanExpirationTime, 2111111222, "Incorrect initial loan Expiration Time");

    // Try to set loan Expiration Time to 0 (should revert without reason)
    vm.expectRevert(bytes(""));
    poolRegis.setloanExpirationTime(3, 0);
    vm.stopPrank();


    vm.startPrank(account0);

    // Verify that loan Expiration Time is still 2111111222
   uint256 loanExpirationTime1 = poolRegis.getloanExpirationTime(3);
    assertEq(loanExpirationTime1, 2111111222, "loan Expiration Time changed unexpectedly");

    // Change the loan Expiration Time to 2111111222
    poolRegis.setloanExpirationTime(3, 2111111222);

    // Verify the loan Expiration Time change
    uint256 newloanExpirationTime = poolRegis.getloanExpirationTime(3);
    assertEq(newloanExpirationTime, 2111111222, "loan Expiration Time not changed to 2111111222");
        vm.stopPrank();


    // Try to change the loan Expiration Time as a non-owner (should revert)
    vm.startPrank(random);
    vm.expectRevert(bytes("Not the owner"));
    poolRegis.setloanExpirationTime(3, 2111111223);
    vm.stopPrank();

        vm.startPrank(account0);
         // Change the loan Expiration Time to 2111111223
    poolRegis.setloanExpirationTime(3, 2111111223);

    // Verify the loan Expiration Time change
    uint256 updatedLoanExpirationTime = poolRegis.getloanExpirationTime(3);
    assertEq(updatedLoanExpirationTime, 2111111223, "loan Expiration Time not changed to 2111111223");
        vm.stopPrank();


}
function test_AddLenderContractPaused() public {
    // should not allow adding lender if contract is paused
test_ChangeLoanExpirationTime();
    vm.startPrank(account0);

    // Pause the contract
    poolRegis.pause();

    // Try to add a lender (should revert)
    vm.expectRevert(bytes("Pausable: paused"));
    poolRegis.addLender(3, account3);

    // Unpause the contract
    poolRegis.unpause();
        vm.stopPrank();

}
function test_AddBorrowerContractPaused() public {
    // should not allow adding borrower if contract is paused
    test_AddLenderContractPaused();
    vm.startPrank(account0);

    // Pause the contract
    poolRegis.pause();

    // Try to add a borrower (should revert)
    vm.expectRevert(bytes("Pausable: paused"));
    poolRegis.addBorrower(3, account1);

    // Unpause the contract
    poolRegis.unpause();
        vm.stopPrank();

}


function test_OnlyOwnerCanAddLenderBorrower() public {
    // should check only owner can add lender and borrower
    test_AddBorrowerContractPaused();
    vm.startPrank(account2);

    // Try to add a borrower as non-owner (should revert)
    vm.expectRevert(bytes("Not the owner"));
    poolRegis.addBorrower(3, account1);
    vm.stopPrank();

    // Perform lender verification for account3 (should fail)
        vm.startPrank(account0);

     (bool isVerified_ ,) = poolRegis.lenderVerification(1, account3);
    assertFalse(isVerified_, "Lender verification unexpectedly passed");
        vm.stopPrank();


    // Try to add a lender as non-owner (should revert)
    vm.startPrank(account2);
    vm.expectRevert(bytes("Not the owner"));
    poolRegis.addLender(3, account3);
    vm.stopPrank();
}

function test_CheckLenderBorrowerRemoval() public {
    // should check lender and borrower are removed or not
    test_OnlyOwnerCanAddLenderBorrower();
        vm.startPrank(account0);

    // Perform lender verification for account3 (should fail)
    (bool isVerified_ ,) = poolRegis.lenderVerification(3, account3);
    assertFalse(isVerified_, "Lender verification unexpectedly passed");


    // Add account3 as a lender

    poolRegis.addLender(3, account3);

    // Verify lender status for account3
    ( bool isVerified ,) = poolRegis.lenderVerification(3, account3);
    assertTrue(isVerified, "Failed to add account3 as a lender");
        vm.stopPrank();


    // Try to remove lender as non-owner (should revert)
    vm.startPrank(random);
    vm.expectRevert(bytes("Not the owner"));
    poolRegis.removeLender(3, account3);
    vm.stopPrank();

    // Pause the contract 
        vm.startPrank(account0);

     poolRegis.pause();

    // Try to remove lender while contract is paused (should revert)
    vm.expectRevert(bytes("Pausable: paused"));
    poolRegis.removeLender(3, account3);

    // Unpause the contract
    poolRegis.unpause();

    // Remove lender account3
    poolRegis.removeLender(3, account3);

    // Verify that lender account3 is removed
   ( bool isVerified1 ,) = poolRegis.lenderVerification(3, account3);
    assertFalse(isVerified1, "Failed to remove account3 as a lender");

    // Add account1 as a borrower
    poolRegis.addBorrower(3, account1);

    // Verify borrower status for account1
   ( bool isVerified2 ,) = poolRegis.borrowerVerification(3, account1);
    assertTrue(isVerified2, "Failed to add account1 as a borrower");
        vm.stopPrank();


    // Try to remove borrower as non-owner (should revert)
    vm.startPrank(random);
    vm.expectRevert(bytes("Not the owner"));
    poolRegis.removeBorrower(3, account1);
    vm.stopPrank();

    // Pause the contract
    vm.startPrank(account0);

    poolRegis.pause();

    // Try to remove borrower while contract is paused (should revert)
    vm.expectRevert(bytes("Pausable: paused"));
    poolRegis.removeBorrower(3, account1);

    // Unpause the contract
     poolRegis.unpause();

    // Remove borrower account1
    poolRegis.removeBorrower(3, account1);

    // Verify that borrower account1 is removed
   ( bool isVerified3 ,) = poolRegis.borrowerVerification(3, account1);
    assertFalse(isVerified3, "Failed to remove account1 as a borrower");
    vm.stopPrank();
}
function test_VerifyPoolDetails() public {
    // should verify the details of pool2
    test_CheckLenderBorrowerRemoval();
    vm.startPrank(account0);

    // Get Payment Default Duration for poolId2
    uint256 DefaultDuration = poolRegis.getPaymentDefaultDuration(2);
    assertEq(DefaultDuration, 211111111, "Incorrect Payment Default Duration for pool2");

    // Get Loan Expiration Time for poolId2
    uint256 ExpirationTime = poolRegis.getloanExpirationTime(2);
    assertEq(ExpirationTime, 2111111222, "Incorrect Loan Expiration Time for pool2");

    // Verify lender status for account2
    (bool isVerified_ ,) = poolRegis.lenderVerification(2, account2);
    assertTrue(isVerified_, "Failed to verify lender status for account2 in pool2");

    // Verify borrower status for account2
    (bool isVerified ,) = poolRegis.borrowerVerification(2, account2);
    assertTrue(isVerified, "Failed to verify borrower status for account2 in pool2");
        vm.stopPrank();

}
function test_ChangePoolSetting() public {
    // should change the setting of new pool
    test_VerifyPoolDetails();
    vm.startPrank(random);

    // Try to change the pool setting as a non-owner (should revert)
    vm.expectRevert(bytes("Not the owner"));
    poolRegis.changePoolSetting(
        2,
        11111111,
        111111222,
        200,
        2000,
        "adya.com"
    );
    vm.stopPrank();
        vm.startPrank(account0);
         poolRegis.changePoolSetting(
        2,
        11111111,
        111111222,
        200,
        2000,
        "adya.com"
    );


    // Verify the changes in pool settings
    uint16 apr = poolRegis.getPoolApr(2);
    assertEq(apr, 2000, "Failed to change APR for pool2");

    uint256 DefaultDuration = poolRegis.getPaymentDefaultDuration(2);
    assertEq(DefaultDuration, 11111111, "Failed to change Payment Default Duration for pool2");

    uint256 ExpirationTime = poolRegis.getloanExpirationTime(2);
    assertEq(ExpirationTime, 111111222, "Failed to change Loan Expiration Time for pool2");

    // Verify lender status for account2
    (bool isVerified ,) = poolRegis.lenderVerification(2, account2);
    assertTrue(isVerified, "Failed to verify lender status for account2 in pool2");

    // Verify borrower status for account2
    (bool isVerified_ ,) = poolRegis.borrowerVerification(2, account2);
    assertTrue(isVerified_, "Failed to verify borrower status for account2 in pool2");
            vm.stopPrank();

}
function test_PauseBeforeCreatingPool() public {
    // should not create if the contract is paused
test_ChangePoolSetting();
    vm.startPrank(account0);

    // Pause the contract
    poolRegis.pause();

    // Try to create a new pool (should revert)
    vm.expectRevert(bytes("Pausable: paused"));
    poolRegis.createPool(
        loanDefaultDuration,
        loanExpirationDuration,
        100,
        1000,
        "adya.com",
        true,
        true
    );

    // Unpause the contract
    poolRegis.unpause();
        vm.stopPrank();

}
function test_AddLenderToPool() public {
    // should add Lender to the pool
test_PauseBeforeCreatingPool();
    vm.startPrank(account0);

    // Verify lender status for account3 (should be false initially)
    (bool isVerified ,) = poolRegis.lenderVerification(1, account3);
    assertFalse(isVerified, "Lender status for account3 is not false initially");

    // Add account3 as a lender to pool1
    poolRegis.addLender(1, account3);

    // Verify lender status for account3 (should be true now)
    (bool isVerified_ ,) = poolRegis.lenderVerification(1, account3);
    assertTrue(isVerified_, "Failed to add account3 as a lender to pool1");
    vm.stopPrank();
}
function test_AddBorrowerToPool() public {
    // should add Borrower to the pool
test_AddLenderToPool();
    vm.startPrank(account0);

    // Add account1 as a borrower to pool1
    poolRegis.addBorrower(1, account1);

    // Verify borrower status for account1 (should be true now)
    (bool isVerified_ ,) = poolRegis.borrowerVerification(1, account1);
    assertTrue(isVerified_, "Failed to add account1 as a borrower to pool1");
        vm.stopPrank();

}
function test_AttestedBorrowerRequestLoan() public {
    // should allow Attested Borrower to Request Loan in a Pool
    test_AddBorrowerToPool();
    vm.startPrank(account0);

    // Mint ERC20 tokens for account0
    sampleERC20.mint(account0, 10000000000);
            vm.stopPrank();


    // Borrower (account1) requests a loan in pool1
        vm.startPrank(account1);

    uint256 loanId1 = poolAddressInstance.loanRequest(
        address(sampleERC20),
        1,
        10000000000,
        loanDuration,
        expiration,
        1000,
        account1
    );
    // Validate loanId assigned to the request
    assertEq(loanId1, 0, "Incorrect loanId assigned to the request");
    
}
function test_AcceptLoan() public {
    // should Accept loan
    test_AttestedBorrowerRequestLoan();
    vm.startPrank(account0);

    // Approve ERC20 tokens for the pool contract
    sampleERC20.approve(address(poolAddressInstance), 10000000000);

    // Record borrower's ERC20 balance before accepting the loan
    uint256 initialBalance =  sampleERC20.balanceOf(account0);
assertEq(initialBalance,10000000000,"incorrect balance");

    // Borrower (account1) accepts the loan
    (
            uint256 amountToAconomy,
            uint256 amountToPool,
            uint256 amountToBorrower
        )= poolAddressInstance.AcceptLoan(0);

        console.log("hh",amountToAconomy);
        console.log("hh1",amountToPool);
        console.log("hh2",amountToBorrower);

    // Record borrower's ERC20 balance after accepting the loan
    uint256 finalBalance =  sampleERC20.balanceOf(account1);

    assertEq(finalBalance,9700000000,"incorrect finalBalance");
    vm.stopPrank();

}

  
function test_RepayLoan() public {
    // anyone can repay Loan
    test_AcceptLoan();
    vm.startPrank(account1);
    
    // Increase time to cover the first installment
    //  skip(paymentCycleDuration + currentTime + 1);
     vm.warp(17008064978 + paymentCycleDuration + 1);
     console.log("sss112",block.timestamp);
    // Get the installment amount
    uint256 installmentAmount =  poolAddressInstance.viewInstallmentAmount(0);
    console.log("sss",installmentAmount);
    // assertEq(installmentAmount, , "incorrect installmentAmount"); 

    // Approve ERC20 tokens for repaying the monthly installment
     sampleERC20.approve(address(poolAddressInstance), installmentAmount);

    // Repay the first monthly installment
     poolAddressInstance.repayMonthlyInstallment(0);

    // // Try to repay the second installment from a different account (should revert)
    //  skip(1000);
    // // vm.startPrank(account1);
    // uint256 installmentAmount1 =  poolAddressInstance.viewInstallmentAmount(0);
    // console.log("ssk",installmentAmount1);
        // vm.expectRevert(bytes(""));

    //  poolAddressInstance.repayMonthlyInstallment(0);

    // // Get the full repayment amount

    // uint256 fullRepayAmount =  poolAddressInstance.viewFullRepayAmount(0);
    //     console.log("tttt",fullRepayAmount);
    //         // assertEq(fullRepayAmount, , "incorrect fullRepayAmount"); 



    // // Approve ERC20 tokens for repaying the full loan
    //  sampleERC20.approve(address(poolAddressInstance), fullRepayAmount);

    // // Repay the full loan
    // poolAddressInstance.repayFullLoan(0);

    //  skip(paymentCycleDuration + 1);

    // // Try to repay the full loan again (should revert)
    // poolAddressInstance.repayFullLoan(0)).to.be.revertedWithoutReason();
}
function test_ClosePool() public {
    // should not allow closing pool if contract is paused
test_RepayLoan();
    vm.startPrank(account0);

    // Pause the pool registry contract
     poolRegis.pause();

    // Try to close the pool (should revert)
        vm.expectRevert(bytes("Pausable: paused"));
    poolRegis.closePool(3);

    // Unpause the pool registry contract
    poolRegis.unpause();
        vm.stopPrank();

}
function test_ClosePoolNotOwner() public {
    // should not allow closing pool if caller is not pool owner
    test_ClosePool();
    vm.startPrank(random);

    // Try to close the pool (should revert)
            vm.expectRevert(bytes("Not the owner"));

    poolRegis.closePool(3);

    vm.stopPrank();
}
function test_ChangeFundingPoolImplementation() public {
    // should not let non owner change funding pool implementation
    test_ClosePoolNotOwner();
        vm.startPrank(random);

    vm.expectRevert(bytes("Ownable: caller is not the owner"));
    poolRegis.changeFundingPoolImplementation(0xBf175FCC7086b4f9bd59d5EAE8eA67b8f940DE0d);
    vm.stopPrank();
}

}