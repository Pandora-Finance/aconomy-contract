// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "contracts/AconomyFee.sol";
import "contracts/Libraries/LibPool.sol";
import "contracts/AttestationServices.sol";
import "contracts/poolRegistry.sol";
import "contracts/AttestationRegistry.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

contract poolRegistryTest is Test {

     //Instances
     AttestationRegistry attestationRegistry;
    AttestationServices attestationServices;
    AconomyFee aconomyFee;
    poolRegistry PoolRegistry;


    address payable alice = payable(address(0xABCC));
    address payable sam = payable(address(0xABDD));
    address payable alex = payable(address(0xABEE));
    address payable tom = payable(address(0xABFF));

    function setUp() public { 
        attestationRegistry = new AttestationRegistry();
        aconomyFee = new AconomyFee(); 
        attestationServices = new AttestationServices(attestationRegistry);

        PoolRegistry = new poolRegistry(attestationServices, address(aconomyFee));
        // poolRegistry.initialize(address(poolDeployer), address(token), msg.sender);

       
    }

   
    function test_CreatePool() public {
        vm.prank(alice);
        uint256 poolId = PoolRegistry.createPool(
            3600, // Payment cycle duration
            1800, // Payment default duration
            86400, // Loan expiration time
            1000, // Pool fee percent (e.g., 10%)
            500, // APR (e.g., 5%)
            "https://adya.com",
            true,
            false 
        );

       
        assertEq(PoolRegistry.getPoolOwner(poolId), alice, "Owner should be alice");
        assertEq(poolId, 1, "something wromg");
        assertTrue(poolId > 0, "Pool creation failed");   
    }
function test_SetApr() public {
    test_CreatePool();
    // uint256 poolId = createPool(); 
    vm.prank(alice);

    PoolRegistry.setApr(1, 600); // APR to 6%

    assertEq(PoolRegistry.getPoolApr(1), 600);
}
function testSetPoolURI() external {
        test_SetApr();
        vm.prank(alice);
        uint256 poolId = PoolRegistry.createPool(
            3600, // Payment cycle duration
            1800, // Payment default duration
            86400, // Loan expiration time
            1000, // Pool fee percent (e.g., 10%)
            500, // APR (e.g., 5%)
            "https://adya.com",
            true,
            true
        );
        assertEq(poolId, 2, "something wromg");
vm.prank(alice);
        PoolRegistry.setPoolURI(poolId, "https://pandora.com");

    }

    function testFail_SetPoolURI() external {
        test_SetApr();
        vm.prank(alice);
        uint256 poolId = PoolRegistry.createPool(
            3600, 
            1800, 
            86400, 
            1000, 
            500, 
            "https://adya.com",
            true,
            true
        );
        assertEq(poolId, 1, "something wromg");
vm.prank(alice);
        PoolRegistry.setPoolURI(poolId, "https://pandora.com");

    }
function testSetPaymentCycleDuration() external {
// testSetPoolURI();
    uint256 poolId = PoolRegistry.createPool(
        3600, // Payment cycle duration
            1800, // Payment default duration
            86400, // Loan expiration time
            1000, // Pool fee percent (e.g., 10%)
            500, // APR (e.g., 5%)
            "https://adya.com",
            true,
            true
    );

    // Set a new payment cycle duration for the pool
    PoolRegistry.setPaymentCycleDuration(poolId, 5400);

    uint32 updatedDuration = PoolRegistry.getPaymentCycleDuration(poolId);
    assertEq(updatedDuration, 5400, "Payment cycle duration not updated correctly");
}

function testSetPaymentDefaultDuration() external {
// testSetPaymentCycleDuration();
    uint256 poolId = PoolRegistry.createPool(
        3600, // Payment cycle duration
            1800, // Payment default duration
            86400, // Loan expiration time
            1000, // Pool fee percent (e.g., 10%)
            500, // APR (e.g., 5%)
            "https://adya.com",
            true,
            true
    );

    // Set a new payment default duration for the pool
    PoolRegistry.setPaymentDefaultDuration(poolId, 3600);

    uint32 updatedDuration = PoolRegistry.getPaymentDefaultDuration(poolId);
    assertEq(updatedDuration, 3600, "Payment default duration not updated correctly");
}
function testSetPoolFeePercent() external {
// testSetPaymentDefaultDuration();
    uint256 poolId = PoolRegistry.createPool(
       3600, // Payment cycle duration
            1800, // Payment default duration
            86400, // Loan expiration time
            1000, // Pool fee percent (e.g., 10%)
            500, // APR (e.g., 5%)
            "https://adya.com",
            true,
            true
    );

    // Set a new pool fee percentage for the pool
    PoolRegistry.setPoolFeePercent(poolId, 1200);

    uint16 updatedFee = PoolRegistry.getPoolFee(poolId);
    assertEq(updatedFee, 1200, "Pool fee percentage not updated correctly");
}

function testSetloanExpirationTime() external {
    // testSetPoolFeePercent();
    uint256 poolId = PoolRegistry.createPool(
        3600, // Payment cycle duration
            1800, // Payment default duration
            86400, // Loan expiration time
            1000, // Pool fee percent (e.g., 10%)
            500, // APR (e.g., 5%)
            "https://adya.com",
            true,
            true
    );

    // Set a new loan expiration time for the pool
    PoolRegistry.setloanExpirationTime(poolId, 43200);

    uint32 updatedExpiration = PoolRegistry.getloanExpirationTime(poolId);
    assertEq(updatedExpiration, 43200, "Loan expiration time not updated correctly");
}

function testAddLender() external {

    uint256 poolId = PoolRegistry.createPool(
        3600, 
            1800, 
            86400, 
            1000, 
            500, 
            "https://adya.com",
            true,
            true
    );


PoolRegistry.addLender(poolId, address(this), block.timestamp + 3600);

    (bool isVerified, ) = PoolRegistry.lenderVarification(poolId, address(this));
    assertEq(isVerified, true, "Lender not added successfully");
}


function testAddBorrower() external {
    
    uint256 poolId = PoolRegistry.createPool(
        3600,
            1800, 
            86400, 
            1000, 
            500, 
            "https://adya.com",
            true,
            true
    );

    PoolRegistry.addBorrower(poolId, address(this), block.timestamp + 3600);

    (bool isVerified, ) = PoolRegistry.borrowerVarification(poolId, address(this));
    assertEq(isVerified, true, "Borrower not added successfully");
}
function testClosePool() external {

    uint256 poolId = PoolRegistry.createPool(
        3600, 
            1800, 
            86400, 
            1000, 
            500, 
            "https://adya.com",
            true,
            true
    );

    PoolRegistry.closePool(poolId);

    bool isClosed = PoolRegistry.ClosedPool(poolId);
    assertEq(isClosed, true, "Pool not closed successfully");
}
 

function testGetPaymentCycleDuration() external {
    // Create a pool with a payment cycle duration of 30 days

         uint256 poolId = PoolRegistry.createPool(
        30, // Payment cycle duration 30 days.
            7, // Payment default duration(7 days)
            365, // Loan expiration time(365 days)
            1000, // Pool fee percent (10% w.r.t 10000)
            500, // Set APR to  5%)
            "https://adya.com",
            true,
            true
    );

    uint32 cycleDuration = PoolRegistry.getPaymentCycleDuration(poolId);
    assertEq(cycleDuration, 30, "Incorrect payment cycle duration");
}

function testGetPaymentDefaultDuration() external {
    // Create a pool with a payment default duration of 1 day
    uint256 poolId = PoolRegistry.createPool(
        3600, // Payment cycle duration
            86400, // Payment default duration
            86400, // Loan expiration time
            1000, // Pool fee percent (e.g., 10%)
            500, // APR (e.g., 5%)
            "https://adya.com",
            true,
            true
    );

    uint32 defaultDuration = PoolRegistry.getPaymentDefaultDuration(poolId);
    assertEq(defaultDuration, 86400, "Incorrect payment default duration");
}

function testGetLoanExpirationTime() external {
    // Create a pool with a loan expiration time of 365 days
     uint256 poolId = PoolRegistry.createPool(
        
            7200,
            1800,
            365, // Loan expiration time(1 year(365 days))
            1000, 
            600, 
            "https://adya.com",
            true,
            true
    );

    uint32 expirationTime = PoolRegistry.getloanExpirationTime(poolId);
    assertEq(expirationTime, 365, "Incorrect loan expiration time");
}

function testGetPoolAddress() external {
    uint256 poolId = PoolRegistry.createPool(
        3600,
            5400, 
            86400, 
            1000, 
            400, 
            "https://adya.com",
            true,
            true
    );
}

function testGetPoolOwner() external {
    uint256 poolId = PoolRegistry.createPool(
         3600, 
            1800, 
            86400, 
            1000, 
            500, 
            "https://adya.com",
            true,
            true);

    // Retrieve pool owner
    address owner = PoolRegistry.getPoolOwner(poolId);

    // Perform assertions on owner as needed
}

// Test getting pool APR
function testGetPoolApr() external {
    uint256 poolId = PoolRegistry.createPool(
     3600, 
            1800, 
            86400, 
            1000, 
            500, 
            "Adya.com",
            true,
            true);

//     Retrieve pool APR
//  uint16Apr = PoolRegistry.getPoolApr(poolId);

}

function testGetAconomyFee() external {
uint256 poolId = PoolRegistry.createPool(
        30,
        7,
        365,
        11,
        5,
        "adyaa.com",
        true,
        true
    );

    // Retrieve the Aconomy fee
    uint16 fee = PoolRegistry.getAconomyFee();

    
//    assertEq(AconomyFee, 50000, "Incoreect Fee");
}
// Test getting the Aconomy owner address
function testGetAconomyOwner() external {
   uint256 poolId = PoolRegistry.createPool(
    // Here i have taken duration in days and percent w.r.t 100.
        30,
        7,
        365,
        10,
        5,
        "adya.com",
        true,
        true
    );

    // Retrieve the Aconomy owner address
    address owner = PoolRegistry.getAconomyOwner();
}
function testAttestLenderAddress() external {
 uint256 poolId = PoolRegistry.createPool(
    //Taken duration in days and percent w.r.t 100.
        30,
        7,
        365,
        10,
        5,
        "adya.com",
        true,
        true
    );
    address lenderAddress = address(0x123); 
    uint256 expirationTime =  30 days; 
    // Attest lender address
    PoolRegistry.addLender(poolId, lenderAddress, expirationTime);

   
    bool isLenderVerified;
    bytes32 lenderAttestationId;
    (isLenderVerified, lenderAttestationId) = PoolRegistry.lenderVarification(poolId, lenderAddress);

    
    assert(isLenderVerified);
    assert(lenderAttestationId != bytes32(0));
}

}