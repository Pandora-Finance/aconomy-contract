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
}