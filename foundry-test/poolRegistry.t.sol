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
            3600, // Payment cycle duration
            1800, // Payment default duration
            86400, // Loan expiration time
            1000, // Pool fee percent (e.g., 10%)
            500, // APR (e.g., 5%)
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
// testSetloanExpirationTime();
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

    // Add a lender to the pool
    PoolRegistry.addLender(poolId, address(this), block.timestamp + 3600);

    (bool isVerified, ) = PoolRegistry.lenderVarification(poolId, address(this));
    assertEq(isVerified, true, "Lender not added successfully");
}

}