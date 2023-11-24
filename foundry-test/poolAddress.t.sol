// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;
import "forge-std/Test.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "forge-std/console.sol";
import "contracts/poolRegistry.sol";
import "contracts/AconomyFee.sol";
import "contracts/poolAddress.sol";
import "contracts/FundingPool.sol";


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





    address payable poolOwner = payable(address(0xABEE));
    address payable random = payable(address(0xABCC));
    address payable borrower = payable(address(0xABDE));
    address payable account2 = payable(address(0xABCE));

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

}