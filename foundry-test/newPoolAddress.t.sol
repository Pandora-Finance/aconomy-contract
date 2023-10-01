pragma solidity >=0.4.22 <0.9.0;
import "forge-std/Test.sol";
import "forge-std/console.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import {SafeMath} from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "contracts/poolRegistry.sol";
import "contracts/poolAddress.sol";

import "contracts/poolStorage.sol";
import "contracts/AconomyFee.sol";
import "contracts/Libraries/LibCalculations.sol";
import "contracts/interfaces/IaccountStatus.sol";

import "contracts/utils/sampleERC20.sol";

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract poolAddressTest is Test{
   poolAddress pool;
//    poolRegistry PoolRegistry;

//     poolStorage PoolStorage;

    SampleERC20 erc20Contract;

AttestationRegistry attestationRegistry;
    AttestationServices attestationServices;
    AconomyFee aconomyFee;
    poolRegistry PoolRegistry;

    address payable alice = payable(address(0xABCC));
    address payable sam = payable(address(0xABDD));
    address payable bob = payable(address(0xABCD));

    address public owner;
    address public borrower;
    address public lendingToken;
    uint256 public poolId;
    uint256 public principal;
    uint32 public duration;
    uint32 public expirationDuration;
    uint16 public apr;
    address public receiver;
    
    // Initialize the contract and setup variables before each test
    function setUp () public {
        attestationRegistry = new AttestationRegistry();
        aconomyFee = new AconomyFee(); 
        attestationServices = new AttestationServices(attestationRegistry);
       PoolRegistry = new poolRegistry(attestationServices, address(aconomyFee));
       pool = new poolAddress(address(PoolRegistry), address(aconomyFee));
       erc20Contract = new SampleERC20();
        owner = msg.sender;
        borrower = address(0x123); 
        lendingToken = address(0x456);
        principal = 1000000;
        duration = 30 days;
        expirationDuration = 7 days;
        apr = 10000; // 100% APR
        receiver = borrower;
    }
    function divideSafely(uint256 numerator, uint256 denominator) public pure returns (uint256) {
    require(denominator != 0, "Denominator cannot be zero");
    return numerator / denominator;
}
function test_CreatePool() public {
        vm.prank(alice);
        poolId = PoolRegistry.createPool(
            3500, // Payment cycle duration
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

function test_AddLender() external {
test_CreatePool();
    // uint256 poolId = PoolRegistry.createPool(
    //     3600, 
    //         1800, 
    //         86400, 
    //         1000, 
    //         500, 
    //         "https://adya.com",
    //         true,
    //         true
    // );
assertEq(poolId, 1, "something wromg");
vm.prank(alice);
PoolRegistry.addLender(poolId, bob, block.timestamp + 3600);

    (bool isVerified, ) = PoolRegistry.lenderVarification(poolId, bob);
    assertEq(isVerified, true, "Lender not added successfully");
}


function testAddBorrower() external {
    test_CreatePool();
    // uint256 poolId = PoolRegistry.createPool(
    //     3600,
    //         1800, 
    //         86400, 
    //         1000, 
    //         500, 
    //         "https://adya.com",
    //         true,
    //         true
    // );
vm.prank(alice);
    PoolRegistry.addBorrower(poolId, sam, block.timestamp + 3600);

    (bool isVerified, ) = PoolRegistry.borrowerVarification(poolId, sam);
    assertEq(isVerified, true, "Borrower not added successfully");
}

 function testLoanRequest() public {
test_CreatePool();
    vm.prank(alice);
        uint256 poolId = PoolRegistry.createPool(
            3600, // Payment cycle duration
            1800, // Payment default duration
            86400, // Loan expiration time
            1000, // Pool fee percent (e.g., 10%)
            500, // APR (e.g., 5%)
            "https://adya.com",
            false,
            false 
        );

       
        assertEq(PoolRegistry.getPoolOwner(poolId), alice, "Owner should be alice");
        assertEq(poolId, 2, "something wromg");
        assertTrue(poolId > 0, "Pool creation failed");   

        address lendingToken = address(erc20Contract);
        poolId = 1;
        uint256 principal = 1000000;
        uint32 duration = 3600;
        uint16 APR = 500;
        

        vm.prank(sam);
        uint256 loanId = pool.loanRequest(
            lendingToken,
            poolId,
            principal,
            duration,
            APR,
            sam
        );
 }

    // Test that a borrower can request a loan
    // function testLoanRequest() public {
    //     pool.loanRequest(
    //         lendingToken,
    //         poolId,
    //         principal,
    //         duration,
    //         apr,
    //         receiver
    //     );
    //     console.log("Debug Message");

    

    function testIsLoanDefaulted() public {
        bool isDefaulted = pool.isLoanDefaulted(1); // Assuming loan ID 1 for testing
        assertFalse(isDefaulted, "Loan should not be defaulted");
    }

    function testCalculateNextDueDate() public {
        uint32 dueDate = pool.calculateNextDueDate(1); // Assuming loan ID 1 for testing
        
    }


  
    function testIsLoanExpired() public {
        uint256 loanId = 1; // 


        bool loanExpired = pool.isLoanExpired(loanId);

    assertFalse(loanExpired, "Loan should not be expired initially");

    }
    function testViewInstallmentAmount() public {
        // pool.AcceptLoan();
        
        uint256 loanId = 1; 

        // uint256 installmentAmount = pool.viewInstallmentAmount(loanId);

        // console.log("sssss",installmentAmount);

       
        // assertEq(installmentAmount, 0, "Installment amount should be non-negative");
    }
     function testIsPaymentLate() public {
        uint256 loanId = 1;

        bool paymentLate = pool.isPaymentLate(loanId);

        // Assert that the payment is not late initially
        assertFalse(paymentLate, "Payment should not be late initially");

    }

    function test_createNewPool() public {
        test_CreatePool();
        uint256 paymentCycleDuration = 30 days;
        uint256 loanExpirationDuration = 2 days;
        vm.prank(alice);
        // poolId = PoolRegistry.createPool(
        //     paymentCycleDuration,
        //     loanExpirationDuration,
        //     100,
        //     100,
        //     "sk.com",
        //     true,
        //     true
        // );
        // assertEq(PoolRegistry.getPoolOwner(poolId), alice, "Owner should be alice");
        // assertEq(poolId, 3, "something wromg");
        // assertTrue(poolId > 0, "Pool creation failed");   

    }
}