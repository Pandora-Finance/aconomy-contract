// pragma solidity >=0.4.22 <0.9.0;
// import "forge-std/Test.sol";
// import "forge-std/console.sol";

// import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
// import "@openzeppelin/contracts/utils/Counters.sol";
// import {SafeMath} from "@openzeppelin/contracts/utils/math/SafeMath.sol";
// import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
// import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
// import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
// import "contracts/poolRegistry.sol";
// import "contracts/poolAddress.sol";

// import "contracts/poolStorage.sol";
// import "contracts/AconomyFee.sol";
// import "contracts/Libraries/LibCalculations.sol";
// import "contracts/interfaces/IaccountStatus.sol";

// import "contracts/utils/sampleERC20.sol";

// import "@openzeppelin/contracts/utils/Address.sol";
// import "@openzeppelin/contracts/utils/math/Math.sol";
// import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

// contract poolAddressTest is Test{
//     //Instances
// //     AconomyFee aconomyFee;
//     poolAddress poolAddr;
// //    poolRegistry PoolRegistry;

// //     poolStorage PoolStorage;

//     SampleERC20 erc20Contract;

// AttestationRegistry attestationRegistry;
//     AttestationServices attestationServices;
//     AconomyFee aconomyFee;
//     poolRegistry PoolRegistry;

//     address payable alice = payable(address(0xABCC));
//     address payable sam = payable(address(0xABDD));
//     address payable alex = payable(address(0xABEE));
//     address payable tom = payable(address(0xABFF));


//     address payable bob = payable(address(0xABbb));
//     address payable royaltyReceiver = payable(address(0xBEEF));
//     address payable validator = payable(address(0xABBB));
//     uint256 poolId;

//   function setUp() public {

//     attestationRegistry = new AttestationRegistry();
//         aconomyFee = new AconomyFee(); 
//         attestationServices = new AttestationServices(attestationRegistry);

//         PoolRegistry = new poolRegistry(attestationServices, address(aconomyFee));

//         poolAddr = new poolAddress(address(PoolRegistry), address(aconomyFee));


//         erc20Contract = new SampleERC20();

  
// }
// function divideSafely(uint256 numerator, uint256 denominator) public pure returns (uint256) {
//     require(denominator != 0, "Denominator cannot be zero");
//     return numerator / denominator;
// }
// function test_CreatePool() public {
//         vm.prank(alice);
//         uint256 poolId = PoolRegistry.createPool(
//             3600, // Payment cycle duration
//             1800, // Payment default duration
//             86400, // Loan expiration time
//             1000, // Pool fee percent (e.g., 10%)
//             500, // APR (e.g., 5%)
//             "https://adya.com",
//             true,
//             false 
//         );

       
//         assertEq(PoolRegistry.getPoolOwner(poolId), alice, "Owner should be alice");
//         assertEq(poolId, 1, "something wromg");
//         assertTrue(poolId > 0, "Pool creation failed");   
//     }

// function testAddLender() external {

//     uint256 poolId = PoolRegistry.createPool(
//         3600, 
//             1800, 
//             86400, 
//             1000, 
//             500, 
//             "https://adya.com",
//             true,
//             true
//     );


// PoolRegistry.addLender(poolId, address(this), block.timestamp + 3600);

//     (bool isVerified, ) = PoolRegistry.lenderVarification(poolId, address(this));
//     assertEq(isVerified, true, "Lender not added successfully");
// }


// function testAddBorrower() external {
    
//     uint256 poolId = PoolRegistry.createPool(
//         3600,
//             1800, 
//             86400, 
//             1000, 
//             500, 
//             "https://adya.com",
//             true,
//             true
//     );

//     PoolRegistry.addBorrower(poolId, address(this), block.timestamp + 3600);

//     (bool isVerified, ) = PoolRegistry.borrowerVarification(poolId, address(this));
//     assertEq(isVerified, true, "Borrower not added successfully");
// }

//  function testLoanRequest() public {

//     vm.prank(alice);
//         uint256 poolId = PoolRegistry.createPool(
//             3600, // Payment cycle duration
//             1800, // Payment default duration
//             86400, // Loan expiration time
//             1000, // Pool fee percent (e.g., 10%)
//             500, // APR (e.g., 5%)
//             "https://adya.com",
//             true,
//             false 
//         );

       
//         assertEq(PoolRegistry.getPoolOwner(poolId), alice, "Owner should be alice");
//         assertEq(poolId, 1, "something wromg");
//         assertTrue(poolId > 0, "Pool creation failed");   

//         address lendingToken = address(erc20Contract);
//         // uint256 poolId = 1;
//         uint256 principal = 1000;
//         uint32 duration = 3600;
//         uint16 APR = 500;
        

//         vm.prank(sam);
//         uint256 loanId = poolAddr.loanRequest(
//             lendingToken,
//             poolId,
//             principal,
//             duration,
//             APR,
//             sam
//         );
//  }


// function testAcceptLoan() public {
//     testLoanRequest();
         
// address lendingToken = address(erc20Contract);
//         // uint256 poolId = 1;
//         uint256 principal = 1000;
//         uint32 duration = 3600;
//         uint16 APR = 500;

//         uint256 loanId = poolAddr.loanRequest(
//             lendingToken,
//             poolId,
//             principal,
//             duration,
//             APR,
//             sam
//         );
//         // Accept loan
//         (
//             uint256 amountToAconomy,
//             uint256 amountToPool,
//             uint256 amountToBorrower
//         ) = poolAddr.AcceptLoan(loanId);

//         // Verify that amounts are greater than or equal to zero
//         assertEq(amountToAconomy, 0, "Amount to Aconomy should be greater than or equal to zero");
//         assertEq(amountToPool, 0, "Amount to Pool should be greater than or equal to zero");
//         assertEq(amountToBorrower, 0, "Amount to Borrower should be greater than or equal to zero");
//     }
//      function testIsLoanExpired() public {
//         uint256 loanId = poolAddr.loanRequest(
//             address(0x1),
//             1,
//             1000,
//             30,
//             5,
//             address(0)
//         );

//         // poolAddr.setLoanExpirationTime(loanId, 1);


//         bool expired = poolAddr.isLoanExpired(loanId);

//         // Verify that the loan is indeed expired
//         assertTrue(expired, "Loan should be expired");
//     }

//     function testIsLoanDefaulted() public {
    
//         uint256 loanId = poolAddr.loanRequest(
//             address(0x1), 
//             1, 
//             1000,
//             30,
//             5,
//             address(0)
//         );

//         // poolAddr.setLoanDefaultDuration(loanId, 1); // 1 second default duration

//         // Check if the loan is defaulted (should be true)
//         bool defaulted = poolAddr.isLoanDefaulted(loanId);

    
//         assertTrue(defaulted, "Loan should be defaulted");
//     }

//     function testIsPaymentLate() public {
    
//         uint256 loanId = poolAddr.loanRequest(
//             address(0x1),
//             1, 
//             1000,
//             1, // 1-day duration
//             5,
//             address(0)
//         );

//         // Advance time by 2 days
//         // poolAddr.advanceTime(2 days);
//         bool latePayment = poolAddr.isPaymentLate(loanId);

    
//         assertTrue(latePayment, "Payment should be late");
 
//     }
//     function testLastRepaidTimestamp() public {
//         uint256 loanId = poolAddr.loanRequest(
//             address(0x1), 
//             1, 
//             1000,
//             30,
//             5,
//             address(0)
//         );

//         // Accept the loan
//         poolAddr.AcceptLoan(loanId);

//         uint32 lastRepaid = poolAddr.lastRepaidTimestamp(loanId);

//         // Verify that the last repaid timestamp is initially zero
//         assertEq(
//             lastRepaid,
//             0,
//             "Last repaid timestamp should be zero before any repayment"
//         );
//     }

//  }