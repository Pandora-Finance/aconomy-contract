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

    uint256 unixTimestamp = 1701174441;

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
}