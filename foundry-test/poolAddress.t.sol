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

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract poolAddressTest is Test{
    //Instances
    AconomyFee aconomyFee;
    poolAddress poolAddr;
   poolRegistry PoolRegistry;

    poolStorage PoolStorage;

    address payable alice = payable(address(0xABCC));

  function setUp() public {
    aconomyFee = new AconomyFee();
    poolAddr = new poolAddress(msg.sender, address(this));
    // PoolStorage = new poolStorage();
   PoolRegistry = new poolRegistry(attestationServices, address( AconomyFee));

  
}
 function testLoanRequest() public {
        address lendingToken = address(0x1);
        uint256 poolId = 1;
        uint256 principal = 1000;
        uint32 duration = 30;
        uint16 APR = 5;
        address receiver = address(0);

        //loan request
        uint256 loanId = poolAddr.loanRequest(
            lendingToken,
            poolId,
            principal,
            duration,
            APR,
            receiver
        );


function testAcceptLoan() public {
        uint256 loanId = poolAddr.loanRequest(
            address(0x1),
            1, 
            1000,
            30,
            5,
            address(0)
        );

        // Accept loan
        (
            uint256 amountToAconomy,
            uint256 amountToPool,
            uint256 amountToBorrower
        ) = poolAddr.AcceptLoan(loanId);

        // Verify that amounts are greater than or equal to zero
        assertEq(amountToAconomy, 0, "Amount to Aconomy should be greater than or equal to zero");
        assertEq(amountToPool, 0, "Amount to Pool should be greater than or equal to zero");
        assertEq(amountToBorrower, 0, "Amount to Borrower should be greater than or equal to zero");
    }
     function testIsLoanExpired() public {
        uint256 loanId = poolAddr.loanRequest(
            address(0x1),
            1,
            1000,
            30,
            5,
            address(0)
        );

        poolAddr.setLoanExpirationTime(loanId, 1);


        bool expired = poolAddr.isLoanExpired(loanId);

        // Verify that the loan is indeed expired
        assertTrue(expired, "Loan should be expired");
    }

    function testIsLoanDefaulted() public {
    
        uint256 loanId = poolAddr.loanRequest(
            address(0x1), 
            1, 
            1000,
            30,
            5,
            address(0)
        );

        poolAddr.setLoanDefaultDuration(loanId, 1); // 1 second default duration

        // Check if the loan is defaulted (should be true)
        bool defaulted = poolAddr.isLoanDefaulted(loanId);

    
        assertTrue(defaulted, "Loan should be defaulted");
    }

    function testIsPaymentLate() public {
    
        uint256 loanId = poolAddr.loanRequest(
            address(0x1),
            1, 
            1000,
            1, // 1-day duration
            5,
            address(0)
        );

        // Advance time by 2 days
        poolAddr.advanceTime(2 days);
        bool latePayment = poolAddr.isPaymentLate(loanId);

    
        assertTrue(latePayment, "Payment should be late");
 
    }
    function testLastRepaidTimestamp() public {
        uint256 loanId = poolAddr.loanRequest(
            address(0x1), 
            1, 
            1000,
            30,
            5,
            address(0)
        );

        // Accept the loan
        poolAddr.AcceptLoan(loanId);

        uint32 lastRepaid = poolAddr.lastRepaidTimestamp(loanId);

        // Verify that the last repaid timestamp is initially zero
        assertEq(
            lastRepaid,
            0,
            "Last repaid timestamp should be zero before any repayment"
        );
    }

 }