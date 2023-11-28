// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;
import "forge-std/Test.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "forge-std/console.sol";
import "forge-std/Vm.sol";
import "contracts/poolRegistry.sol";
import "contracts/AconomyFee.sol";
import "contracts/poolAddress.sol";
import "contracts/FundingPool.sol";
import "contracts/poolStorage.sol";



import "contracts/AttestationServices.sol";
import "contracts/Libraries/LibPool.sol";
import "contracts/utils/sampleERC20.sol";


contract poolAddressTest is Test {
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
    uint256 unixTimestamp = 1701174441;




    address payable poolOwner = payable(address(0xABEE));
    address payable random = payable(address(0xABCC));
    address payable borrower = payable(address(0xABDE));
    address payable account2 = payable(address(0xABCE));
    address payable receiver = payable(address(0xABCC));


    function testDeployandInitialize() public {
        vm.startPrank(poolOwner);
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
        poolRegis.transferOwnership(poolOwner);


        address implementation1= address(new poolAddress());
        address proxy1= address(new ERC1967Proxy(implementation1, ""));
        poolAddressInstance = poolAddress(proxy1);
        poolAddressInstance.initialize(address(poolRegis),address(aconomyFee));
        poolAddressInstance.transferOwnership(poolOwner);

        fundingPool.initialize(poolOwner,address(poolRegis));


vm.stopPrank();

    }  
    function test_owner() public {
        testDeployandInitialize();
        assertEq(poolRegis.owner(),poolOwner,"not the owner");
        assertEq(poolAddressInstance.owner(),poolOwner,"not  owner");

        assertEq(fundingPool.poolOwner(),poolOwner,"not  owner");

        
    }

    function test_CreatePool() public {
    // should create Pool
test_owner();
vm.startPrank(poolOwner);

    // Create a new pool
  uint256 poolId1 = poolRegis.createPool(
         paymentCycleDuration,
          loanExpirationDuration,
          100,
          100,
          "adya.com",
          true,
          true
    );
assertEq(poolId1,1,"invalid poolId");
    // Get the pool address
    // address pool1Address = poolRegis.getPoolAddress(poolId1);

    // Perform lender verification
   (bool isVerified ,) = poolRegis.lenderVerification(poolId1, poolOwner);
    assertTrue(isVerified, "Lender verification failed");

    // Perform borrower verification
    (bool isVerified_ ,) = poolRegis.borrowerVerification(poolId1, poolOwner);
    assertTrue(isVerified_, "Borrower verification failed");
    vm.stopPrank();
    
}

function test_AddRemoveLender() public {
    // should add Lender to the pool
test_CreatePool();
vm.startPrank(poolOwner);

    // Verify that random is not a verified lender
    (bool isVerified, ) = poolRegis.lenderVerification(1, random);
    assertFalse(isVerified, "Random should not be a verified lender initially");

    // Add random as a lender
    poolRegis.addLender(1, random);

    // Verify that random is now a verified lender
    (bool isVerifiedAfterAdd, ) = poolRegis.lenderVerification(1, random);
    assertTrue(isVerifiedAfterAdd, "Random should be a verified lender after addition");

    // Remove random as a lender
    poolRegis.removeLender(1, random);

    // Verify that random is not a verified lender after removal
    (bool isVerifiedAfterRemove, ) = poolRegis.lenderVerification(1, random);
    assertFalse(isVerifiedAfterRemove, "Random should not be a verified lender after removal");

    // Add random as a lender again
    poolRegis.addLender(1, random);

    // Verify that random is a verified lender after the second addition
    (bool isVerifiedAfterSecondAdd, ) = poolRegis.lenderVerification(1, random);
    assertTrue(isVerifiedAfterSecondAdd, "Random should be a verified lender after the second addition");

    vm.stopPrank();
}
function test_AddRemoveBorrower() public {
    // should add Borrower to the pool
    test_AddRemoveLender();
    vm.startPrank(poolOwner);

    // Verify that borrower is not a verified borrower initially
    (bool isVerified, ) = poolRegis.borrowerVerification(1, borrower);
    assertFalse(isVerified, "Borrower should not be a verified borrower initially");

    // Add borrower as a borrower
    poolRegis.addBorrower(1, borrower);

    // Verify that borrower is now a verified borrower
    (bool isVerifiedAfterAdd, ) = poolRegis.borrowerVerification(1, borrower);
    assertTrue(isVerifiedAfterAdd, "Borrower should be a verified borrower after addition");

    // Remove borrower as a borrower
    poolRegis.removeBorrower(1, borrower);

    // Verify that borrower is not a verified borrower after removal
    (bool isVerifiedAfterRemove, ) = poolRegis.borrowerVerification(1, borrower);
    assertFalse(isVerifiedAfterRemove, "Borrower should not be a verified borrower after removal");

    // Add borrower as a borrower again
    poolRegis.addBorrower(1, borrower);

    // Verify that borrower is a verified borrower after the second addition
    (bool isVerifiedAfterSecondAdd, ) = poolRegis.borrowerVerification(1, borrower);
    assertTrue(isVerifiedAfterSecondAdd, "Borrower should be a verified borrower after the second addition");

    vm.stopPrank();
}

function test_LoanRequest() public {
    // testing loan request function
test_AddRemoveBorrower();
    vm.startPrank(poolOwner);

    // Set Aconomy Pool Fee
    aconomyFee.setAconomyPoolFee(100);

    // Mint ERC20 tokens for the pool owner
    sampleERC20.mint(poolOwner, 10000000000);
    vm.stopPrank();

    // Call loanRequest function
        vm.startPrank(borrower);

    uint256 loanId1 = poolAddressInstance.loanRequest(
        address(sampleERC20),
        1,
        10000000000,
        loanDefaultDuration,
        loanExpirationDuration,
        100,
        borrower
    );
    // loanId1 = 0;

    // Verify loanId is 0
    assertEq(loanId1, 0, "Incorrect loanId");

    // Retrieve loan details
//    ( Loan memory loan) = poolAddressInstance.loans(0);

    // Verify loan state is 0 (Pending)
    // assertEq(loan.state, 0, "Incorrect loan state");

    vm.stopPrank();
}
function test_LoanRequest_InvalidLendingToken() public {
    // should not request if lending token is 0 address
    test_LoanRequest();
    vm.startPrank(borrower);

    // Attempt to request a loan with 0 address as lending token (should revert)
    vm.expectRevert(bytes(""));
    poolAddressInstance.loanRequest(
        0x0000000000000000000000000000000000000000,
        1,
        10000000000,
        loanDefaultDuration,
        loanExpirationDuration,
        100,
        borrower
    );
    vm.stopPrank();
}
function test_LoanRequest_InvalidReceiver() public {
    // should not request if receiver is 0 address
test_LoanRequest_InvalidLendingToken();
    vm.startPrank(borrower);

    // Attempt to request a loan with 0 address as receiver (should revert)
    vm.expectRevert(bytes(""));
    poolAddressInstance.loanRequest(
        address(sampleERC20),
        1,
        10000000000,
        loanDefaultDuration,
        loanExpirationDuration,
        100,
        0x0000000000000000000000000000000000000000
    );
    vm.stopPrank();
}
function test_LoanRequest_UnverifiedLender() public {
    // should not request if lender is unverified
test_LoanRequest_InvalidReceiver();
    vm.startPrank(receiver);

    // Attempt to request a loan with unverified lender (should revert)
    vm.expectRevert(bytes(""));
    poolAddressInstance.loanRequest(
        address(sampleERC20),
        1,
        10000000000,
        loanDefaultDuration,
        loanExpirationDuration,
        100,
        borrower
    );
    vm.stopPrank();
}
function test_LoanRequest_InvalidDuration() public {
    // should not request if duration is not divisible by 30
test_LoanRequest_UnverifiedLender();
    vm.startPrank(borrower);

    // Attempt to request a loan with invalid duration (should revert)
    vm.expectRevert(bytes(""));
    poolAddressInstance.loanRequest(
        address(sampleERC20),
        1,
        10000000000,
        loanDefaultDuration + 1,
        loanExpirationDuration,
        100,
        borrower
    );
    vm.stopPrank();
}
function test_LoanRequest_InvalidAPR() public {
    // should not request if apr < 100
test_LoanRequest_InvalidDuration();
    vm.startPrank(borrower);

    // Attempt to request a loan with invalid APR (should revert)
     vm.expectRevert(bytes(""));
    poolAddressInstance.loanRequest(
        address(sampleERC20),
        1,
        10000000000,
        loanDefaultDuration,
        loanExpirationDuration,
        10,
        borrower
    );
    vm.stopPrank();
}
function test_LoanRequest_InvalidPrincipal() public {
    // should not request if principal < 1000000
test_LoanRequest_InvalidAPR();
    vm.startPrank(borrower);

    // Attempt to request a loan with invalid principal (should revert)
     vm.expectRevert(bytes("low"));
    poolAddressInstance.loanRequest(
        address(sampleERC20),
        1,
        100000,
        loanDefaultDuration,
        loanExpirationDuration,
        100,
        borrower
    );
    vm.stopPrank();
}
function test_LoanRequest_InvalidExpirationDuration() public {
    // should not request if expiration duration is 0
 test_LoanRequest_InvalidPrincipal();
     vm.startPrank(borrower);

    // Attempt to request a loan with invalid expiration duration (should revert)
     vm.expectRevert(bytes(""));
    poolAddressInstance.loanRequest(
        address(sampleERC20),
        1,
        10000000000,
        loanDefaultDuration,
        0,
        100,
        borrower
    );
    vm.stopPrank();
}
function test_LoanRequest_PausedContract() public {
    // should not request if the contract is paused
test_LoanRequest_InvalidExpirationDuration();
    vm.startPrank(poolOwner);

    // Pause the contract
    poolAddressInstance.pause();
        vm.stopPrank();


    // Attempt to request a loan while the contract is paused (should revert)
        vm.startPrank(borrower);

    vm.expectRevert(bytes("Pausable: paused"));
    poolAddressInstance.loanRequest(
        address(sampleERC20),
        1,
        10000000000,
        loanDefaultDuration,
        loanExpirationDuration,
        100,
        borrower
    );
        vm.stopPrank();


    // Unpause the contract
        vm.startPrank(poolOwner);
    poolAddressInstance.unpause();

    vm.stopPrank();
}
function test_RevertAcceptLoan_NonLender() public {
    // should not accept loan if caller is not lender
test_LoanRequest_PausedContract();
    vm.startPrank(account2);
 sampleERC20.approve(address(poolAddressInstance), 10000000000);
    // Try to accept the loan as a non-lender (should revert)
    vm.expectRevert(bytes("Not verified lender"));
    poolAddressInstance.AcceptLoan(0);

    vm.stopPrank();
}
function testFail_RevertAcceptLoan_Paused() public {
    // should not accept loan if contract is paused
test_RevertAcceptLoan_NonLender();
    // Pause the contract
        vm.startPrank(poolOwner);
    poolAddressInstance.pause();
        vm.stopPrank();


    // Try to accept the loan while the contract is paused (should revert)
        vm.startPrank(borrower);

     vm.expectRevert(bytes("Pausable: paused"));
 sampleERC20.approve(address(poolAddressInstance), 10000000000);
    poolAddressInstance.AcceptLoan(0);
        vm.stopPrank();


//     // Unpause the contract
        vm.startPrank(poolOwner);

    poolAddressInstance.unpause();
    vm.stopPrank();
}function test_AcceptLoanWithFee() public {
    // should Accept loan with fee
test_LoanRequest();
    vm.startPrank(poolOwner);

    // Transfer ownership to a random address
    aconomyFee.transferOwnership(random);
    address feeAddress = aconomyFee.getAconomyOwnerAddress();
            vm.stopPrank();

        vm.startPrank(random);

    aconomyFee.setAconomyPoolFee(200);
    assertEq(feeAddress, random, "incorrect");
    uint256 b1 = sampleERC20.balanceOf(feeAddress);
                vm.stopPrank();


    // Approve and accept the loan
        vm.startPrank(poolOwner);


 sampleERC20.approve(address(poolAddressInstance), 10000000000);
    uint256 _balance1 = sampleERC20.balanceOf(poolOwner);

    poolAddressInstance.AcceptLoan(0);
    uint256 b2 = sampleERC20.balanceOf(feeAddress);
        assertEq((b2 - b1),100000000);


     _balance1 = sampleERC20.balanceOf(borrower);
    assertEq(_balance1,9800000000);

// //     // Check the loan state
// (poolAddress.Loan memory loan)= poolAddressInstance.loans(0);
//         assertEq(uint(loan.state), 2);
    //   (  ,,,,,,poolAddress.LoanState memory state) = poolAddressInstance.loans(0);
      //         assertEq(uint(loan.state), 2);



    vm.stopPrank();
}

function test_RevertAcceptLoanIfNotPending() public {
    // should not accept loan if loan is not pending
test_AcceptLoanWithFee();
    vm.startPrank(poolOwner);

    // Try to accept the loan again (should revert)
 sampleERC20.approve(address(poolAddressInstance), 10000000000);
      vm.expectRevert(bytes("loan not pending"));

     poolAddressInstance.AcceptLoan(0);

}
function test_CalculateNextDueDate() public {
    // should calculate the next due date
test_AcceptLoanWithFee();

    // Assuming loanId1 and poolAddressInstance are already set up.
//    poolStorage.Loan memory loan = poolAddressInstance.loans(0);

      (  ,,,,poolAddress.LoanDetails memory loanDetails,poolAddress.Terms memory terms,) = poolAddressInstance.loans(0);

        // Perform the test.
        uint32 dueDate = poolAddressInstance.calculateNextDueDate(0);
        uint32 acceptedTimeStamp = loanDetails.acceptedTimestamp;
        uint32 paymentCycle = terms.paymentCycle;
        assertEq(dueDate, acceptedTimeStamp + paymentCycle, "Next due date calculation is incorrect");
}
function test_WorkAfterLoanExpires() public {
    // should not work after the loan expires
    test_CalculateNextDueDate();

    // Check if the loan is expired
    bool isExpired = poolAddressInstance.isLoanExpired(0);

    // Increase time to simulate loan expiration
   
    assertFalse(isExpired, "Loan should not be expired after");
}
function test_PaymentDoneInTime() public {
    // should check the payment done in time
 test_WorkAfterLoanExpires();
    // Check if the payment is late
    bool isPaymentLate = poolAddressInstance.isPaymentLate(0);

    // Verify that the payment is not late
    assertFalse(isPaymentLate, "Payment should not be late");
}
function testViewAndPayFirstInstallment() public {
    test_PaymentDoneInTime();
    vm.startPrank(poolOwner);


      (  ,,,,poolAddress.LoanDetails memory loanDetails,poolAddress.Terms memory terms,) = poolAddressInstance.loans(0);
        uint256 acceptedTimeStamp = loanDetails.acceptedTimestamp;
        uint256 paymentCycle = terms.paymentCycle;
        // Simulate time passing
        vm.warp( unixTimestamp + paymentCycleDuration + 5000); 
        uint256 dueDate = poolAddressInstance.calculateNextDueDate(0);
        assertEq(dueDate, acceptedTimeStamp + paymentCycle);
        uint256 installmentAmount = poolAddressInstance.viewInstallmentAmount(0);
        vm.stopPrank();

                vm.startPrank(borrower); 
                sampleERC20.mint(borrower,100000000);
        sampleERC20.approve(address(poolAddressInstance), installmentAmount);
        // vm.prank(borrower);
        poolAddressInstance.repayMonthlyInstallment(0);
    //   (   ,,,,poolAddress.LoanDetails memory loanDetails1,poolAddress.Terms memory terms1,) = poolAddressInstance.loans(0);
        // assertEq(loanDetails1.lastRepaidTimestamp, acceptedTimeStamp + paymentCycle);
        // assertEq(loanDetails1.totalRepaid.principal + loanDetails1.totalRepaid.interest);
                vm.stopPrank();

}
function testContinuedPaymentAfterSkippingCycle() public {
        // Simulate time to skip a payment cycle
        testViewAndPayFirstInstallment();
        vm.warp(unixTimestamp + 2 * paymentCycleDuration + 50000);
        assertTrue(poolAddressInstance.isPaymentLate(0));
        // Calculate and verify next due date
        uint256 dueDate = poolAddressInstance.calculateNextDueDate(0);
      (   ,,,,poolAddress.LoanDetails memory loanDetails,poolAddress.Terms memory terms,) = poolAddressInstance.loans(0);
        assertEq(dueDate, loanDetails.acceptedTimestamp + 2 * terms.paymentCycle);
        // Repay the installment after skipping one cycle
        uint256 installmentAmount = poolAddressInstance.viewInstallmentAmount(0);

         vm.startPrank(borrower); 
                sampleERC20.mint(borrower,100000000);
        sampleERC20.approve(address(poolAddressInstance), installmentAmount);
        poolAddressInstance.repayMonthlyInstallment(0);
        // Assertions after repayment
      (   ,,,,poolAddress.LoanDetails memory loanDetails1,poolAddress.Terms memory terms1,) = poolAddressInstance.loans(0);
        assertEq(loanDetails1.lastRepaidTimestamp, loanDetails1.acceptedTimestamp + 2 * terms1.paymentCycle);
        assertEq(terms1.installmentsPaid, 2);
        assertTrue(poolAddressInstance.isPaymentLate(0));
        // Calculate and verify next due date
        dueDate = poolAddressInstance.calculateNextDueDate(0);
                assertTrue(poolAddressInstance.isPaymentLate(0));
        assertEq(dueDate, loanDetails.acceptedTimestamp + 3 * terms.paymentCycle);
        vm.stopPrank();
        // Pause and attempt to repay
        vm.prank(poolOwner);
        poolAddressInstance.pause();

     vm.expectRevert(bytes("Pausable: paused"));
        vm.prank(borrower);
        poolAddressInstance.repayMonthlyInstallment(0);
        // Unpause and repay
                vm.prank(poolOwner);
        poolAddressInstance.unpause();
        vm.startPrank(borrower); 
                uint256 installmentAmount2 = poolAddressInstance.viewInstallmentAmount(0);

                sampleERC20.mint(borrower,1000000000000);
        sampleERC20.approve(address(poolAddressInstance), installmentAmount2);
                        console.log("ddd",installmentAmount);
        poolAddressInstance.repayMonthlyInstallment(0);
        // Assertions after repayment
      (   ,,,,,poolAddress.Terms memory terms2,) = poolAddressInstance.loans(0);
        // assertEq(loanDetails2.lastRepaidTimestamp,loanDetails2.acceptedTimestamp + 6 * terms2.paymentCycle);
        assertEq(terms2.installmentsPaid, 2);
        assertFalse(poolAddressInstance.isPaymentLate(0));

          uint256  FullRepayAmount = poolAddressInstance. viewFullRepayAmount(0);

                sampleERC20.mint(borrower,1000000000000);
        sampleERC20.approve(address(poolAddressInstance), FullRepayAmount);
                        console.log("ddd",FullRepayAmount);
                          uint256  installmentAmount3 = poolAddressInstance. viewInstallmentAmount(0);

                sampleERC20.mint(borrower,1000000000000);
        sampleERC20.approve(address(poolAddressInstance), installmentAmount3);
                        console.log("ddd",installmentAmount3);
        // poolAddressInstance.repayMonthlyInstallment(0);
}
function test_LoanNotDefaultedIfStateNotAccepted() public {
    // should show loan is not defaulted if state is not accepted
    testContinuedPaymentAfterSkippingCycle();

    bool isLoanDefaulted = poolAddressInstance.isLoanDefaulted(0);

    // Verify that the loan is not defaulted
    assertFalse(isLoanDefaulted, "Loan should not be defaulted");
}
function test_PaymentNotLateIfStateNotAccepted() public {
    // should show payment is not late if state is not accepted
    test_LoanNotDefaultedIfStateNotAccepted();
    
    bool isPaymentLate = poolAddressInstance.isPaymentLate(0);

    // Verify that the payment is not late
    assertFalse(isPaymentLate, "Payment should not be late");
}

function test_CheckFullRepaymentAmountIsZero() public {
    // should check that full repayment amount is 0
    test_PaymentNotLateIfStateNotAccepted();

    // Get the full repayment amount
    uint256 fullRepaymentAmount = poolAddressInstance.viewFullRepayAmount(0);

    // Verify that the full repayment amount is 0
    assertEq(fullRepaymentAmount, 0, "Full repayment amount should be 0");
}
function test_RequestAnotherLoan() public {
    // should request another loan
     test_CheckFullRepaymentAmountIsZero();

vm.startPrank(borrower);
  uint256 loanId1 =  poolAddressInstance.loanRequest(
        address(sampleERC20),
        1,
        10000000000,
        loanDefaultDuration,
        loanExpirationDuration,
        100,
        borrower
    );

    // Update loanId1 to the new loan ID

    // Verify that the new loan ID is 1
    assertEq(loanId1, 1, "New loan ID should be 1");
    vm.stopPrank();

}
function test_AcceptLoan() public {
    // should Accept loan
    test_RequestAnotherLoan();

    // Approve lending tokens for the loan
            vm.startPrank(poolOwner);

    sampleERC20.approve(address(poolAddressInstance), 10000000000);

    // Get the initial balance of the borrower
    // uint256 initialBalance = sampleERC20.balanceOf(borrower);
    // console.log("initialBalance",initialBalance);

    // Accept the loan

    poolAddressInstance.AcceptLoan(1);

    // Get the updated balance of the borrower after accepting the loan
    uint256 updatedBalance = sampleERC20.balanceOf(borrower);
        console.log("updatedBalance",updatedBalance);
vm.stopPrank();

}
function test_RepayFullAmount() public {
    // should repay full amount
     test_AcceptLoan();

    // Get loan details
      (   ,,,,poolAddress.LoanDetails memory loanDetails,,) = poolAddressInstance.loans(0);

 uint256 lastRepaidTimestamp1=loanDetails.lastRepaidTimestamp;
 uint256 paymentCycleDuration1;
vm.warp(loanDetails.lastRepaidTimestamp + paymentCycleDuration1 + 20);
    // Advance blocks to simulate the passage of time
        // Simulate the passage of time
        console.log("kkk",lastRepaidTimestamp1);
    // Get the full repayment amount
    uint256 fullRepayAmount = poolAddressInstance.viewFullRepayAmount(1);

    // Get the current balance of the borrower
    // uint256 borrowerBalance = sampleERC20.balanceOf(borrower);

    // Approve lending tokens for the full repayment amount
    vm.prank(borrower);
    sampleERC20.approve(address(poolAddressInstance), fullRepayAmount);

    // Pause the contract temporarily
    vm.prank(poolOwner);
    poolAddressInstance.pause();

    // Attempt to repay the full loan while the contract is paused (expecting a revert)
    vm.startPrank(borrower);
            vm.expectRevert(bytes("Pausable: paused"));
            poolAddressInstance.repayFullLoan(1);
vm.stopPrank();

    // Unpause the contract
        vm.prank(poolOwner);
    poolAddressInstance.unpause();

//     // Repay the full loan
    vm.prank(borrower);
    poolAddressInstance.repayFullLoan(1);

}
function test_NoFurtherPaymentAfterRepayment() public {
    // should not allow further payment after the loan has been repaid
    test_RepayFullAmount();
    

    // Attempt to repay the full loan again (expecting a revert)
    vm.startPrank(borrower);
        vm.expectRevert(bytes(""));
    poolAddressInstance.repayFullLoan(1);
      vm.stopPrank();

}
function test_FullRepaymentAmountIsZero() public {
    // should check that full repayment amount is 0
    test_NoFurtherPaymentAfterRepayment();

      (   ,,,,poolAddress.LoanDetails memory loanDetails,,) = poolAddressInstance.loans(0);

//  uint256 lastRepaidTimestamp1=loanDetails.lastRepaidTimestamp;
 uint256 paymentCycleDuration1;
vm.warp(loanDetails.lastRepaidTimestamp + paymentCycleDuration1 + 20);
    // Get the full repayment amount
    uint256 fullRepayAmount = poolAddressInstance.viewFullRepayAmount(1);

    // Assert that the full repayment amount is 0
    assertEq(fullRepayAmount, 0, "Full repayment amount should be 0");
}
function test_Request_AnotherLoan() public {
    // should request another loan
    test_FullRepaymentAmountIsZero();
vm.startPrank(borrower);

    // Request another loan
  uint256 loanId = poolAddressInstance.loanRequest(
        address(sampleERC20),
        1,
        10000000000,
        loanDefaultDuration,
        loanExpirationDuration,
        100,
        borrower
    );

    // Update the loanId

    // Assert that the loanId is 2
    assertEq(loanId, 2, "Loan ID should be 2");
    vm.stopPrank();
}
function test_ExpireAfterExpiryDeadline() public {
    // should expire after the expiry deadline
    test_Request_AnotherLoan();

    // Increase time beyond loanExpirationDuration
    skip(loanExpirationDuration + 1);

    // Check if the loan is expired
    bool isExpired = poolAddressInstance.isLoanExpired(2);

    // Assert that the loan is expired
    assertTrue(isExpired, "Loan should be expired after the expiry deadline");
}
function test_NotAllowExpiredLoanToBeAccepted() public {
    // should not allow an expired loan to be accepted
    test_ExpireAfterExpiryDeadline();

    // Attempt to accept an expired loan
        vm.expectRevert(bytes(""));

        poolAddressInstance.AcceptLoan(2);
}
function test_RequestAnother_Loan() public {
    // should request another loan
    test_NotAllowExpiredLoanToBeAccepted();
    vm.startPrank(borrower);


    // Request another loan
    uint256 newLoanId = poolAddressInstance.loanRequest(
        address(sampleERC20),
        1,
        10000000000,
        loanDefaultDuration,
        loanExpirationDuration,
        100,
        borrower
    );

    // Check that the new loan ID matches the expected value
assertEq(newLoanId, 3, "Incorrect new loan ID");
    vm.stopPrank();

}


function test_Accept_Loan() public {
    // should Accept loan
test_RequestAnother_Loan();
    // Approve lending tokens for the loan
            vm.startPrank(poolOwner);

    sampleERC20.approve(address(poolAddressInstance), 10000000000);


    // Accept the loan

    poolAddressInstance.AcceptLoan(3);

    // Get the updated balance of the borrower after accepting the loan
    uint256 updatedBalance = sampleERC20.balanceOf(borrower);
        console.log("updatedBalance",updatedBalance);
vm.stopPrank();

}

function test_CheckLoanDefaulted() public {
    // should show loan defaulted
test_Accept_Loan();
    // Increase time to almost the loan default duration
    skip(loanDefaultDuration + paymentCycleDuration - 10);

    // Check that the loan is not defaulted yet
    bool isDefaultedBefore = poolAddressInstance.isLoanDefaulted(3);
    assertFalse(isDefaultedBefore, "Loan should not be defaulted yet");

    // Increase time to exceed the loan default duration
    skip(11);

    // Check that the loan is now defaulted
    bool isDefaultedAfter = poolAddressInstance.isLoanDefaulted(3);
    assertTrue(isDefaultedAfter, "Loan should be defaulted");
}


function test_RequestLoanAgainWithLowAmount() public {
    // should revert if principal < 1000000
    test_CheckLoanDefaulted();

    // First attempt with 100000 should revert
    vm.startPrank(borrower);

        vm.expectRevert(bytes("low"));

   poolAddressInstance.loanRequest(
        address(sampleERC20),
            1,
            100000,
            loanDefaultDuration,
            loanExpirationDuration,
            100,
            borrower
        );

vm.stopPrank();

    // Second attempt with 1000000 should succeed
    vm.startPrank(borrower);


    // Request another loan
    uint256 loanId = poolAddressInstance.loanRequest(
        address(sampleERC20),
        1,
        1000000,
        loanDefaultDuration,
        loanExpirationDuration,
        100,
        borrower
    );

    // Check that the loanId is incremented
    assertEq(loanId, 4, "Unexpected loanId");
    vm.stopPrank();

}
function test_AcceptLoanAfterLowAmountRequest() public {
    // should accept the loan
     test_RequestLoanAgainWithLowAmount();
                 vm.startPrank(poolOwner);

    sampleERC20.approve(address(poolAddressInstance), 1000000);

    poolAddressInstance.AcceptLoan(4);
    vm.stopPrank();
}

function test_RepayMonthlyInstallmentWithLowAmount() public {
    // should not allow monthly installments as amount is too low
    test_AcceptLoanAfterLowAmountRequest();
    uint256 installmentAmount = poolAddressInstance.viewInstallmentAmount(4);
        vm.startPrank(borrower);

    sampleERC20.approve(address(poolAddressInstance), installmentAmount);
    
    // This call should revert with "low" error
            vm.expectRevert(bytes("low"));
    poolAddressInstance.repayMonthlyInstallment(4);
        vm.stopPrank();

}
function test_RepayFullLoan() public {
    // should repay the full amount
     test_RepayMonthlyInstallmentWithLowAmount();
    uint256 fullRepayAmount = poolAddressInstance.viewFullRepayAmount(4);
    assertEq(fullRepayAmount,1000000,"incorrect RepayAmount");
    // Additional time increase if needed
   skip(3600);
            vm.prank(poolOwner);
            sampleERC20.mint(borrower, 100000000);
                        vm.startPrank(borrower);
    sampleERC20.approve(address(poolAddressInstance), fullRepayAmount);
    
    // Repay the full loan
    // poolAddressInstance.repayFullLoan(4);
vm.stopPrank();
}
function test_Request_Another_Loan() public {
    // should request another loan
    test_RepayFullLoan();
    vm.prank(random);
    aconomyFee.setAconomyPoolFee(0);
    
    vm.startPrank(borrower);

// Request another loan
    uint256 loanId = poolAddressInstance.loanRequest(
        address(sampleERC20),
        1,
        10000000000,
        loanDefaultDuration,
        loanExpirationDuration,
        100,
        borrower
    );
    
   
    // check  assertions 
       assertEq(loanId, 5, "Unexpected loanId");
vm.stopPrank();

}
function test_AcceptLoanWithZeroAconomyFee() public {
    // should accept loan with aconomy fee of 0
    test_Request_Another_Loan();
                             vm.startPrank(poolOwner);
                             sampleERC20.mint(poolOwner,100000000000);

        sampleERC20.approve(address(poolAddressInstance), 10000000000);


    
    // Get borrower's balance before accepting the loan
    uint256 balanceBefore = sampleERC20.balanceOf(borrower);
    
    // // Accept the loan
    poolAddressInstance.AcceptLoan(5);
    
    // Get borrower's balance after accepting the loan
    uint256 balanceAfter = sampleERC20.balanceOf(borrower);
    
    // Additional checks or assertions can be added if needed
    assertEq(balanceAfter - balanceBefore, 9900000000, "Incorrect balance after accepting loan");
    vm.stopPrank();
}
function test_RequesttAnother_Loan() public {
    // should request another loan
    test_AcceptLoanWithZeroAconomyFee();
        vm.startPrank(borrower);

    // Request another loan
   uint256 loanId = poolAddressInstance.loanRequest(
        address(sampleERC20),
        1,
        1000000,
        loanDefaultDuration,
        loanExpirationDuration,
        100,
        borrower
    );
    
    
    // Additional checks
    assertEq(loanId, 6, "Incorrect loan ID");
    vm.stopPrank();

}
function test_ClosePool() public {
    // should close the pool
    test_RequesttAnother_Loan();
    // Close the pool
            vm.startPrank(poolOwner);

    poolRegis.closePool(1);
    
    // Check if the pool is closed
    bool closed = poolRegis.ClosedPool(1);
    assertTrue(closed, "Pool not closed");
        vm.stopPrank();

}
function test_RequestLoanInClosedPool() public {
    // should not request loan in a closed pool
test_ClosePool();    
    // Attempt to request a loan in a closed pool
     vm.startPrank(borrower);
    vm.expectRevert(bytes(""));

 poolAddressInstance.loanRequest(
        address(sampleERC20),
            1,
            10000000000,
            loanDefaultDuration,
            loanExpirationDuration,
            100,
            borrower
        );
        
            vm.stopPrank();

    
}
function test_AcceptLoanInClosedPool() public {
    // should not allow accepting the loan in a closed pool
    test_RequestLoanInClosedPool();
    vm.startPrank(poolOwner);
    // Try to accept the loan in a closed pool and expect revert
        vm.expectRevert(bytes("pool closed"));

    poolAddressInstance.AcceptLoan(6);
    vm.stopPrank();
}
function test_Create_Pool() public {
    // should create Pool
    test_AcceptLoanInClosedPool();
    vm.startPrank(poolOwner);

    // Create a new pool
    poolRegis.createPool(
        paymentCycleDuration,
        loanExpirationDuration,
        0,
        100,
        "adya.com",
        false,
        false
    );
        vm.stopPrank();
}
function test_RequestFunction() public {
// testing loan request function 
test_Create_Pool();
    vm.prank(random);
aconomyFee.setAconomyPoolFee(100);
vm.prank(poolOwner);
sampleERC20.mint(poolOwner, 10000000000);

        vm.startPrank(borrower);

    // Request another loan
  uint256 loanId = poolAddressInstance.loanRequest(
        address(sampleERC20),
          2,
          10000000000,
          loanDefaultDuration,
          loanExpirationDuration,
          100,
          borrower
    );
            vm.stopPrank();
console.log("vvvv",loanId);
}  
function test_Accept_the_loan() public {

// should Accept loan 
 test_RequestFunction();
         vm.startPrank(poolOwner);

        sampleERC20.approve(address(poolAddressInstance), 10000000000);


    // Accept the loan
     poolAddressInstance.AcceptLoan(7);


}

}