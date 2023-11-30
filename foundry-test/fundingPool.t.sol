// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;
import "forge-std/Test.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "forge-std/console.sol";
import "forge-std/Vm.sol";
import "contracts/poolRegistry.sol";
import "contracts/AconomyFee.sol";
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
        FundingPool fundingpoolInstance;
        poolRegistry poolRegis;


    uint256 public erc20Amount = 10000000000;
    uint32 public paymentCycleDuration = 30 days;
    uint32 public loanDefaultDuration = 180 days;
    uint32 public loanExpirationDuration = 1 days;

    uint256 unixTimestamp = 1701321683;

     uint256 poolId;
    uint256 expiration;


    address payable poolOwner = payable(address(0xABEE));
    address payable lender = payable(address(0xABCC));
    address payable nonLender = payable(address(0xABDE));
    address payable receiver = payable(address(0xABCE));
    address payable newFeeOwner = payable(address(0xABCC));

address pool1Address;
    function testDeployandInitialize() public {
        vm.startPrank(poolOwner);
        sampleERC20 = new SampleERC20();   
        aconomyFee = new AconomyFee();
        attestRegistry= new AttestationRegistry();
        attestServices= new AttestationServices(attestRegistry);

        fundingpoolInstance = new FundingPool();

        // fundingPool.initialize(address(factory),alice,"Aconomy","ACO");
         address implementation = address(new poolRegistry());

        address proxy = address(new ERC1967Proxy(implementation, ""));
        poolRegis = poolRegistry(proxy);
          poolRegis.initialize(attestServices,address(aconomyFee),address(fundingpoolInstance));
        poolRegis.transferOwnership(poolOwner);


        fundingpoolInstance.initialize(poolOwner,address(poolRegis));


vm.stopPrank();

    }
    function test_owner() public {
        testDeployandInitialize();
        assertEq(poolRegis.owner(),poolOwner,"not the owner");
        assertEq(fundingpoolInstance.poolOwner(),poolOwner,"not  owner");

        
    }
     function test_CreatePool() public {
    // should create Pool
test_owner();
vm.startPrank(poolOwner);
 aconomyFee.setAconomyPoolFee(100);
 aconomyFee.AconomyPoolFee();

    // Create a new pool
  uint256 poolId1 = poolRegis.createPool(
         paymentCycleDuration,
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
        pool1Address = poolRegis.getPoolAddress(1);

    // Verify that lender is not a verified lender
    (bool isVerified, ) = poolRegis.lenderVerification(1, lender);
    assertFalse(isVerified, "Random should not be a verified lender initially");

    // Add lender as a lender
    poolRegis.addLender(1, lender);

    // Verify that lender is now a verified lender
    (bool isVerifiedAfterAdd, ) = poolRegis.lenderVerification(1, lender);
    assertTrue(isVerifiedAfterAdd, "lender should be a verified lender after addition");

    // Remove lender as a lender
    poolRegis.removeLender(1, lender);

    // Verify that lender is not a verified lender after removal
    (bool isVerifiedAfterRemove, ) = poolRegis.lenderVerification(1, lender);
    assertFalse(isVerifiedAfterRemove, "lender should not be a verified lender after removal");

    // Add lender as a lender again
    poolRegis.addLender(1, lender);

    // Verify that lender is a verified lender after the second addition
    (bool isVerifiedAfterSecondAdd, ) = poolRegis.lenderVerification(1, lender);
    assertTrue(isVerifiedAfterSecondAdd, "lender should be a verified lender after the second addition");

    vm.stopPrank();
}
function test_AddRemoveBorrower() public {
    // should add Borrower to the pool
    test_AddRemoveLender();
    vm.startPrank(poolOwner);

    // Verify that nonLender is not a verified borrower initially
    (bool isVerified, ) = poolRegis.borrowerVerification(1, nonLender);
    assertFalse(isVerified, "Borrower should not be a verified borrower initially");

    // Add nonLender as a borrower
    poolRegis.addBorrower(1, nonLender);

    // Verify that borrower is now a verified borrower
    (bool isVerifiedAfterAdd, ) = poolRegis.borrowerVerification(1, nonLender);
    assertTrue(isVerifiedAfterAdd, "Borrower should be a verified borrower after addition");

    // Remove nonLender as a borrower
    poolRegis.removeBorrower(1, nonLender);

    // Verify that borrower is not a verified borrower after removal
    (bool isVerifiedAfterRemove, ) = poolRegis.borrowerVerification(1, nonLender);
    assertFalse(isVerifiedAfterRemove, "Borrower should not be a verified borrower after removal");

    // Add nonLender as a borrower again
    poolRegis.addBorrower(1, nonLender);

    // Verify that nonLender is a verified borrower after the second addition
    (bool isVerifiedAfterSecondAdd, ) = poolRegis.borrowerVerification(1, nonLender);
    assertTrue(isVerifiedAfterSecondAdd, "Borrower should be a verified borrower after the second addition");

    vm.stopPrank();
}

function testLenderCanSupplyFundsToThePool() public {
// should allow lender to supply funds to the pool 
        test_AddRemoveBorrower();
        vm.warp(block.timestamp + 3600);
        // unixTimestamp
        // uint256 currentBlock = block.number;
         unixTimestamp = block.number;

        expiration = block.timestamp + 3600;
        address fundingpooladdress = poolRegis.getPoolAddress(1);
        // console.log(fundingpooladdress);
        fundingpoolInstance = FundingPool(fundingpooladdress);
        vm.prank(poolOwner);
        sampleERC20.mint(poolOwner,10000000000000);
                vm.prank(poolOwner);
        sampleERC20.transfer(lender,erc20Amount);

                vm.startPrank(lender);

       sampleERC20.approve(address(fundingpoolInstance), erc20Amount);
       fundingpoolInstance.supplyToPool(1,
         address(sampleERC20),
          erc20Amount,
           loanDefaultDuration, 
           expiration,
           1000);
           uint256 bidId;
        bidId = 0;

                vm.stopPrank();
        vm.prank(poolOwner);

        sampleERC20.transfer(address(lender), 10000000000);
                        vm.startPrank(lender);

        sampleERC20.approve(address(fundingpoolInstance), 10000000000);
        fundingpoolInstance.supplyToPool(1,
         address(sampleERC20),
          10000000000, 
          loanDefaultDuration,
           expiration, 
           1000);

        uint256 bidId1;
        bidId1 = 1;
        // vm.stopPrank();
        uint256 balance = sampleERC20.balanceOf(lender);
        assertEq(balance, 0);

        (uint256 amount,
        uint256 fundExpiration,
        uint32 maxDuration,
        uint16 interestRate, 
        , 
        ,
        ,
        ,
        ,
        ,
        ,
        ) = fundingpoolInstance.lenderPoolFundDetails(
            lender, 1, address(sampleERC20), bidId);
        assertEq(amount, erc20Amount);
        assertEq(loanDefaultDuration, maxDuration);
        assertEq(interestRate, 1000);
        assertEq(fundExpiration, expiration);
        // assertEq(state, 0); // BidState.PENDING
                vm.stopPrank();

    }
function test_nonLender_supplyToPool() public {
    // should not allow non-lender to supply funds to the pool 
    testLenderCanSupplyFundsToThePool();
     vm.warp(block.timestamp + 3600);
        // Rest of your test logic
         unixTimestamp = block.number;
        expiration = block.timestamp + 3600;

                        vm.startPrank(nonLender);

  sampleERC20.approve(address(fundingpoolInstance), erc20Amount);

  vm.expectRevert(bytes("Not verified lender"));

       fundingpoolInstance.supplyToPool(
        1,
        address(sampleERC20),
        erc20Amount,
        loanDefaultDuration, 
        expiration,
        1000);

    vm.stopPrank();


}
function test_supply_zero_address() public {
// should not allow lender to supply 0 address to the pool 
test_nonLender_supplyToPool();
 vm.warp(block.timestamp + 3600);
        // Rest of your test logic
         unixTimestamp = block.number;
        expiration = block.timestamp + 3600;

                        vm.startPrank(lender);

  sampleERC20.approve(address(fundingpoolInstance), erc20Amount);

  vm.expectRevert(bytes("you can't do this with zero address"));

       fundingpoolInstance.supplyToPool(
        1,
0x0000000000000000000000000000000000000000,
        erc20Amount,
        loanDefaultDuration, 
        expiration,
        1000);

    vm.stopPrank();


}
function test_loanDuration_Days() public {
// should not allow lender to input a duration not divisible by 30 days

test_supply_zero_address();

vm.warp(block.timestamp + 3600);
        // Rest of your test logic
         unixTimestamp = block.number;
        expiration = block.timestamp + 3600;

                        vm.startPrank(lender);

  sampleERC20.approve(address(fundingpoolInstance), erc20Amount);

  vm.expectRevert(bytes(""));

       fundingpoolInstance.supplyToPool(
        1,
        address(sampleERC20),
        erc20Amount,
        loanDefaultDuration + 1, 
        expiration,
        1000);

    vm.stopPrank();


}
function test_supply_with_lowAPR() public {

// should not allow lender to supply an apr less than 100 bps 
 test_loanDuration_Days();

vm.warp(block.timestamp + 3600);
        // Rest of your test logic
         unixTimestamp = block.number;
        expiration = block.timestamp + 3600;

                        vm.startPrank(lender);

  sampleERC20.approve(address(fundingpoolInstance), erc20Amount);

  vm.expectRevert(bytes("apr too low"));

       fundingpoolInstance.supplyToPool(
        1,
        address(sampleERC20),
        erc20Amount,
        loanDefaultDuration , 
        expiration,
        10);

    vm.stopPrank();



}
function test_low_supply_amount() public {
// should not allow lender to supply 100000 amount to the pool 
test_supply_with_lowAPR();
vm.warp(block.timestamp + 3600);
        // Rest of your test logic
         unixTimestamp = block.number;
        expiration = block.timestamp + 3600;

                        vm.startPrank(lender);

  sampleERC20.approve(address(fundingpoolInstance), erc20Amount);

  vm.expectRevert(bytes("amount too low"));

       fundingpoolInstance.supplyToPool(
        1,
        address(sampleERC20),
        100000,
        loanDefaultDuration,
        expiration,
        1000);

    vm.stopPrank();

}
function test_duration_not_Divisible() public {
// should not allow lender to set a duration not divisible by 30 
test_low_supply_amount();

vm.warp(block.timestamp + 3600);
        // Rest of your test logic
         unixTimestamp = block.number;
        expiration = block.timestamp + 3600;

                        vm.startPrank(lender);

  sampleERC20.approve(address(fundingpoolInstance), erc20Amount);

  vm.expectRevert(bytes(""));

       fundingpoolInstance.supplyToPool(
        1,
        address(sampleERC20),
        10000000000,
        31,
        expiration,
        1000);

    vm.stopPrank();


}
function test_faulty_expiration() public {
// should not allow lender to supply a faulty expiration 
test_duration_not_Divisible();
vm.warp(block.timestamp + 3600);
        // Rest of your test logic
         unixTimestamp = block.number;
        expiration = block.timestamp + 3600;

                        vm.startPrank(lender);

  sampleERC20.approve(address(fundingpoolInstance), erc20Amount);

  vm.expectRevert(bytes("wrong timestamp"));

       fundingpoolInstance.supplyToPool(
        1,
        address(sampleERC20),
        erc20Amount,
        loanDefaultDuration,
        10,
        1000);

    vm.stopPrank();

}
function test_cancelBid_by_nonLender() public {
// should not allow non-lender to cancel a bid 
test_faulty_expiration();

vm.startPrank(nonLender);

  vm.expectRevert(bytes("You are not a Lender"));
fundingpoolInstance.Withdraw(
       1,         
       address(sampleERC20),
        0, 
        lender);

        vm.stopPrank();

}
function test_acceptBid_andEmit() public{
// should accept the bid and emit AcceptedBid event  
testLenderCanSupplyFundsToThePool();

vm.prank(poolOwner);
aconomyFee.transferOwnership(newFeeOwner);

        address feeAddress =  aconomyFee.getAconomyOwnerAddress();
        vm.prank(newFeeOwner);

        aconomyFee.setAconomyPoolFee(200);
        assertEq(feeAddress,newFeeOwner,"ownership not transfer");
         aconomyFee.AconomyPoolFee();
        uint256 b1 =  sampleERC20.balanceOf(feeAddress);

  vm.startPrank(receiver);
  vm.expectRevert(bytes("You are not the Pool Owner"));

 fundingpoolInstance.AcceptBid(
          1,         
       address(sampleERC20),
          0,
          lender,
          receiver
        );
        vm.stopPrank();

  vm.startPrank(poolOwner);

         fundingpoolInstance.AcceptBid(
           1,         
           address(sampleERC20),
           0,
           lender,
           receiver
        );
        uint256 b2 =  sampleERC20.balanceOf(feeAddress);

assertEq((b2-b1),100000000,"incorrect balance");

 (,
        ,
        ,
        , 
        ,  
        ,
        uint32 acceptBidTimestamp,
        ,
        ,
        ,
        ,
        ) = fundingpoolInstance.lenderPoolFundDetails(
            lender,
             1, 
             address(sampleERC20),
            0);

// assertEq(acceptBidTimestamp != moment.now);
        vm.stopPrank();

}
function test_pendingBid() public {
//  should revert if bid is not pending
test_acceptBid_andEmit();
        // await fundingpoolInstance.AcceptBid(
        //   poolId,
        //   await erc20.getAddress(),
        //   bidId,
        //   lender,
        //   receiver
        // );
         vm.startPrank(poolOwner);
  vm.expectRevert(bytes("Bid must be pending"));

          fundingpoolInstance.AcceptBid(
           1,         
           address(sampleERC20),
           0,
            lender,
            receiver
          );
              vm.stopPrank();

}
function test_rejecet_revert() public {
//  should revert reject if bid is not pending
test_pendingBid();

         vm.startPrank(poolOwner);

          vm.expectRevert(bytes("Bid must be pending"));

          fundingpoolInstance.RejectBid(
            1,         
           address(sampleERC20),
           0,
            lender
          );
                        vm.stopPrank();

}
function test_reject_Bid()public {
// should reject the bid and emit RejectBid event 
test_rejecet_revert();
          vm.startPrank(poolOwner);

       fundingpoolInstance.RejectBid(
           1,         
           address(sampleERC20),
           1,
            lender
        );
  
         (uint256 amount,
        ,
        ,
        , 
        ,  
        ,
        ,
        ,
        ,
        ,
        ,
        ) = fundingpoolInstance.lenderPoolFundDetails(
            lender,
             1, 
             address(sampleERC20),
            1);

             uint256 balance =  sampleERC20.balanceOf(lender);


assertEq(amount,10000000000,"incorrect Amount");
assertEq(balance,10100000000,"incorrect Amount");
                        vm.stopPrank();


}
function test_cancelling_notPending_Bid() public {
// should not allow cancelling a bid that is not pending 
test_reject_Bid();
vm.startPrank(lender);

vm.expectRevert(bytes("Bid must be pending"));
fundingpoolInstance.Withdraw(
    1,
  
address(sampleERC20),
 0, 
 lender);
vm.stopPrank();
     
}
function test_viewPay_1st_installment() public {
    // should view and pay 1st intallment amount 
test_cancelling_notPending_Bid();
 (      ,
        ,
        ,
        , 
        ,  
        ,
        uint32 acceptBidTimestamp,
        ,
        ,
        ,
        ,
        ) = fundingpoolInstance.lenderPoolFundDetails(
          lender,
          1,
          address(sampleERC20),
          0
        );
        // console.log(loan);
        uint256 _installmentAmount  =  fundingpoolInstance.viewInstallmentAmount(
          1,
          address(sampleERC20),
          0,
          lender
        );
assertEq(_installmentAmount,0);
        // vm.warp( unixTimestamp + paymentCycleDuration + 500000); 
        uint256 currentTime = block.timestamp;
        vm.warp(currentTime + paymentCycleDuration + 500000);
        uint256 newTime = block.timestamp;
        // Checking increased time
        assertEq(newTime, currentTime + paymentCycleDuration+500000);

 uint256 installmentAmount  =  fundingpoolInstance.viewInstallmentAmount(
          1,
          address(sampleERC20),
          0,
          lender
        );
// console.log("kkk",installmentAmount1);
uint256 dueDate = fundingpoolInstance.calculateNextDueDate(
    1,  
    address(sampleERC20),
    0, 
    lender
);

        uint256 acceptedTimeStamp = acceptBidTimestamp;
        uint256 paymentCycle = paymentCycleDuration;

        assertEq(dueDate, acceptedTimeStamp + paymentCycle);

 vm.startPrank(receiver); 
        sampleERC20.approve(address(fundingpoolInstance), installmentAmount);

          vm.expectRevert(bytes("You are not the Pool Owner"));
        fundingpoolInstance.repayMonthlyInstallment(
             1,
          address(sampleERC20),
          0,
          lender
        );
        vm.stopPrank();

 vm.startPrank(poolOwner); 
                // sampleERC20.mint(borrower,100000000);
        sampleERC20.approve(address(fundingpoolInstance), installmentAmount);

        fundingpoolInstance.repayMonthlyInstallment(
             1,
          address(sampleERC20),
          0,
          lender
        );
        vm.stopPrank();

    (   ,
        ,
        ,
        , 
        ,  
        ,
        ,
        uint256 paymentCycleAmount,
        ,
        ,
        ,
        ) = fundingpoolInstance.lenderPoolFundDetails(
          lender,
          1,
          address(sampleERC20),
          0
        );
// console.log("kkk",paymentCycleAmount);
assertEq(paymentCycleAmount,1715613940,"incorrect amount");

 uint256 currentTime1 = block.timestamp;
        vm.warp(currentTime1 + paymentCycleDuration + 100);
        uint256 _newTime = block.timestamp;
        // Checking increased time
        assertEq(_newTime, currentTime1 + paymentCycleDuration+100);


 uint256 installmentAmount1  =  fundingpoolInstance.viewInstallmentAmount(
          1,
          address(sampleERC20),
          0,
          lender
        );
assertEq(installmentAmount1,1715613940,"incorrect amount");

}
function testContinuedPaymentAfterSkippingCycle() public {
// should continue paying installments after skipping a cycle 
test_viewPay_1st_installment();
(       ,
        ,
        ,
        , 
        ,  
        ,
        uint32 acceptBidTimestamp,
         uint256 paymentCycleAmount,
        ,
        ,
        ,
        ) = fundingpoolInstance.lenderPoolFundDetails(
          lender,
          1,
          address(sampleERC20),
          0
        );


bool PaymentLate = fundingpoolInstance.isPaymentLate(
            1,
            address(sampleERC20),
            0,
            lender
          );
assertFalse(PaymentLate,"incorrect status");

uint256 _now =  sampleERC20.getTime();

uint256 currentTime = block.timestamp;
        vm.warp(currentTime + paymentCycleDuration + paymentCycleDuration + 604800);
        uint256 newTime = block.timestamp;
        // Checking increased time
        assertEq(newTime, currentTime + 2*paymentCycleDuration + 604800);
        _now =  sampleERC20.getTime();
        assertEq(_now, 11476501);


        bool IsPaymentLate = fundingpoolInstance.isPaymentLate(
            1,
            address(sampleERC20),
            0,
            lender
          );
assertTrue(IsPaymentLate,"Payment status");

uint256 dueDate = fundingpoolInstance.calculateNextDueDate(
    1,  
    address(sampleERC20),
    0, 
    lender
);

        uint256 acceptedTimeStamp = acceptBidTimestamp;
        uint256 paymentCycle = paymentCycleDuration;

        assertEq(dueDate, acceptedTimeStamp + 2*paymentCycle);

uint256 installmentAmount  =  fundingpoolInstance.viewInstallmentAmount(
          1,
          address(sampleERC20),
          0,
          lender
        );
assertEq(installmentAmount,paymentCycleAmount,"incorrect installmentAmount");

 vm.startPrank(poolOwner); 
                // sampleERC20.mint(borrower,100000000);
        sampleERC20.approve(address(fundingpoolInstance), installmentAmount);

        fundingpoolInstance.repayMonthlyInstallment(
             1,
          address(sampleERC20),
          0,
          lender
        );
        vm.stopPrank();


(       ,
        ,
        ,
        ,
        , 
        ,  
        ,
        ,
        ,
        ,
        FundingPool.Installments memory installment,
        ) = fundingpoolInstance.lenderPoolFundDetails(
          lender,
          1,
          address(sampleERC20),
          0
        );
assertEq(installment.installmentsPaid,2);


bool PaymentLate1 = fundingpoolInstance.isPaymentLate(
            1,
            address(sampleERC20),
            0,
            lender
          );
assertTrue(PaymentLate1,"incorrect status");

uint256 dueDate1 = fundingpoolInstance.calculateNextDueDate(
    1,  
    address(sampleERC20),
    0, 
    lender
);
        assertEq(dueDate1, acceptedTimeStamp + 3*paymentCycle);



uint256 installmentAmount3  =  fundingpoolInstance.viewInstallmentAmount(
          1,
          address(sampleERC20),
          0,
          lender
        );

 vm.startPrank(poolOwner); 
        sampleERC20.approve(address(fundingpoolInstance), installmentAmount3);

        fundingpoolInstance.repayMonthlyInstallment(
             1,
          address(sampleERC20),
          0,
          lender
        );
        vm.stopPrank();


(       ,
        ,
        ,
        ,
        , 
        ,  
        ,
        ,
        ,
        ,
        FundingPool.Installments memory installment1,
        ) = fundingpoolInstance.lenderPoolFundDetails(
          lender,
          1,
          address(sampleERC20),
          0
        );
assertEq(installment1.installmentsPaid,3);

bool PaymentLate2 = fundingpoolInstance.isPaymentLate(
            1,
            address(sampleERC20),
            0,
            lender
          );
assertTrue(PaymentLate2,"incorrect PaymentLate2 status");
uint256 dueDate2 = fundingpoolInstance.calculateNextDueDate(
    1,  
    address(sampleERC20),
    0, 
    lender
);
        assertEq(dueDate2, acceptedTimeStamp + 4*paymentCycle);
// vm.warp(paymentCycleDuration); 
uint256 installmentAmount4  =  fundingpoolInstance.viewInstallmentAmount(
          1,
          address(sampleERC20),
          0,
          lender
        );

 vm.startPrank(poolOwner); 
        sampleERC20.approve(address(fundingpoolInstance), installmentAmount4);

        fundingpoolInstance.repayMonthlyInstallment(
             1,
          address(sampleERC20),
          0,
          lender
        );
        vm.stopPrank();

// attempt to repay installment again should revert 
        vm.startPrank(poolOwner); 
        sampleERC20.approve(address(fundingpoolInstance), installmentAmount4);
        
  vm.expectRevert(bytes(""));

        fundingpoolInstance.repayMonthlyInstallment(
             1,
          address(sampleERC20),
          0,
          lender
        );
        vm.stopPrank();

(       ,
        ,
        ,
        ,
        , 
        ,  
        ,
        ,
        ,
        ,
        FundingPool.Installments memory installment4,
        ) = fundingpoolInstance.lenderPoolFundDetails(
          lender,
          1,
          address(sampleERC20),
          0
        );
assertEq(installment4.installmentsPaid,4);


bool PaymentLate4 = fundingpoolInstance.isPaymentLate(
            1,
            address(sampleERC20),
            0,
            lender
          );
assertFalse(PaymentLate4,"incorrect status");

uint256 dueDate3 = fundingpoolInstance.calculateNextDueDate(
    1,  
    address(sampleERC20),
    0, 
    lender
);
        // assertEq(dueDate3, acceptedTimeStamp + 5 * paymentCycle);
uint256 currentTime3 = block.timestamp;
        vm.warp(currentTime3 + paymentCycleDuration + 100);
        uint256 _newTime1 = block.timestamp;
        // Checking increased time
        assertEq(_newTime1, currentTime3 + paymentCycleDuration+100);
        uint256 installmentAmount5  =  fundingpoolInstance.viewInstallmentAmount(
          1,
          address(sampleERC20),
          0,
          lender
        );
// console.log("lll",installmentAmount5);
 vm.startPrank(poolOwner); 
        sampleERC20.approve(address(fundingpoolInstance), installmentAmount5);

        fundingpoolInstance.repayMonthlyInstallment(
             1,
          address(sampleERC20),
          0,
          lender
        );
        vm.stopPrank();
(       ,
        ,
        ,
        ,
        , 
        ,  
        ,
        ,
        ,
        ,
        FundingPool.Installments memory installment5,
        ) = fundingpoolInstance.lenderPoolFundDetails(
          lender,
          1,
          address(sampleERC20),
          0
        );
assertEq(installment5.installmentsPaid,5);


bool PaymentLate5 = fundingpoolInstance.isPaymentLate(
            1,
            address(sampleERC20),
            0,
            lender
          );
assertFalse(PaymentLate5,"incorrect status");


uint256 currentTime4 = block.timestamp;
        vm.warp(currentTime4 + paymentCycleDuration + 100);
        uint256 _newTime2 = block.timestamp;
        // Checking increased time
        assertEq(_newTime2, currentTime4 + paymentCycleDuration+100);

        uint256 installmentAmount6  =  fundingpoolInstance.viewInstallmentAmount(
          1,
          address(sampleERC20),
          0,
          lender
        );
// console.log("lll",installmentAmount5);
 vm.startPrank(poolOwner); 
        sampleERC20.approve(address(fundingpoolInstance), installmentAmount6);

        fundingpoolInstance.repayMonthlyInstallment(
             1,
          address(sampleERC20),
          0,
          lender
        );
        vm.stopPrank();
(       ,
        ,
        ,
        ,
        , 
        ,  
        ,
        ,
        ,
        ,
        FundingPool.Installments memory installment6,
        ) = fundingpoolInstance.lenderPoolFundDetails(
          lender,
          1,
          address(sampleERC20),
          0
        );
assertEq(installment6.installmentsPaid,5);



}
}