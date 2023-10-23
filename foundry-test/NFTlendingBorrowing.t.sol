// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "forge-std/console.sol";

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "contracts/piNFT.sol";
import "contracts/NFTlendingBorrowing.sol";
import "contracts/Libraries/LibCalculations.sol";
import "contracts/utils/sampleERC20.sol";
import "contracts/AconomyFee.sol";
import "contracts/NFTlendingBorrowing.sol";
import "contracts/AconomyFee.sol";

contract NftLendingBorrowingTest is Test {

    piNFT piNftContract;
    piNFTMethods piNFTMethodsContract;
    AconomyERC2771Context AconomyERC2771ContextInstance;
    SampleERC20 sampleERC20;
    NFTlendingBorrowing nftLendBorrow;
    AconomyFee aconomyFee;


    address payable alice = payable(address(0xABCD));
    address payable random = payable(address(0xABDD));
    address payable newFeeAddress = payable(address(0xABBC));

    address payable bob = payable(address(0xABCC));
    address payable carl = payable(address(0xABEE));
    address payable adya = payable(address(0xABDE));
    address payable royaltyReceiver = payable(address(0xABED));
    address payable validator = payable(address(0xABCD));

    function testDeployandInitialize() public {
        vm.prank(alice);
        aconomyFee = new AconomyFee();
        sampleERC20 = new SampleERC20();
        address implementation = address(new piNFTMethods());

        address proxy = address(new ERC1967Proxy(implementation, ""));
        
          piNFTMethodsContract = piNFTMethods(proxy);
          piNFTMethodsContract.initialize(0xBf175FCC7086b4f9bd59d5EAE8eA67b8f940DE0d);
                address implementation1 = address(new piNFT());
        address tfGelato = 0xBf175FCC7086b4f9bd59d5EAE8eA67b8f940DE0d;

        address proxy1 = address(new ERC1967Proxy(implementation1, ""));
        
         piNftContract = piNFT(proxy1);
         piNftContract.initialize("Aconomy","ACO",address(piNFTMethodsContract),tfGelato);
         assertEq(piNftContract.name(),"Aconomy", "faiii");
         piNftContract.transferOwnership(alice);
         piNFTMethodsContract.transferOwnership(alice);

         

         assertEq(piNftContract.owner(),alice, "not the owner");
         assertEq(piNFTMethodsContract.owner(),alice, "Incorrect owner");
         assertEq(aconomyFee.owner(),alice, "not the owner");


        console.log("piNFTTe111st", address(this));
        console.log("owner", piNftContract.owner());
        console.log("alice222", alice);

        address lendBorrowimplementation = address(new NFTlendingBorrowing());

        address lendBorrowproxy = address(new ERC1967Proxy(lendBorrowimplementation, ""));

        nftLendBorrow = NFTlendingBorrowing(lendBorrowproxy);
        nftLendBorrow.initialize(address(aconomyFee));

         nftLendBorrow.transferOwnership(alice);
         assertEq(nftLendBorrow.owner(),alice, "Incorret owner");
    }


function testFail_NonOwnerCannotSetAconomyFees() public {
    // should not let non owner set aconomy fees 
vm.prank(royaltyReceiver);
aconomyFee.setAconomyNFTLendBorrowFee(100);
  

}
function testFail_NonOwnercannotSetAconomyFees() public {
 // should not let non owner set aconomy fees 
// setting Aconomy Pool Fee by non-owner
  vm.prank(royaltyReceiver);
 aconomyFee.setAconomyPoolFee(100);

}
function testFail_NonOwner_cannotSetAconomyFees() public {
     // should not let non owner set aconomy fees 

        vm.prank(royaltyReceiver);
  
     aconomyFee.setAconomyPiMarketFee(100);

}
function testSetAconomyFees() public {
    // it should set aconomy fee 
    testDeployandInitialize();
    vm.startPrank(alice);
 aconomyFee.setAconomyNFTLendBorrowFee(100);

    aconomyFee.setAconomyPoolFee(100);

    aconomyFee.setAconomyPiMarketFee(100);

    // vm.stopPrank();

}
function test_mintNFT_for_lending() public {
    // mint NFT and list for lending 
    testSetAconomyFees();
    vm.startPrank(alice);

     LibShare.Share[] memory royArray ;
        LibShare.Share memory royalty;
        royalty = LibShare.Share(royaltyReceiver, uint96(500));
        
        royArray= new LibShare.Share[](1);
        royArray[0] = royalty;
        string memory uri = "www.adya.com";
         
       piNftContract.mintNFT(alice, uri, royArray);
        aconomyFee.setAconomyNFTLendBorrowFee(100);
         aconomyFee.AconomyNFTLendBorrowFee();
        uint256 tokenId = 0;
        assertEq(tokenId,0,"incorrect token Id");
        // assertEq(piNFT.balanceOf(alice),1,"incorrect balance");


    vm.stopPrank();

}
function testFail_listNFTforBorrowing() public {
 // mint NFT and list for lending 
         uint256 tokenId = 0;

nftLendBorrow.listNFTforBorrowing(
            tokenId,
           address(piNftContract),
            200,
            300,
            3600,
            1000000  
    );
 assertEq(tokenId,0,"incorrect token Id");
}

function test_listNFTforBorrowing() public {
    // it should list NFT for borrowing 
    test_mintNFT_for_lending();
vm.prank(alice);
 uint256 tokenId = 0;
nftLendBorrow.listNFTforBorrowing(
            tokenId,
           address(piNftContract),
            200,
            300,
            3600,
            200000000000 
    );
    uint256 NFTid = 1;
    assertEq(NFTid,1,"Incorrect NFTid");
}
function testFail_ListNFTforBorrowing() public {
    // should check contract address isn't 0 address 
    vm.prank(alice);

     nftLendBorrow.listNFTforBorrowing(
            0,
            0x0000000000000000000000000000000000000000,
 
            200,
            300,
            3600,
            200000000000
        );
}
function testFail_1_listNFTforBorrowing() public {
    // should check percent must be greater than 0.1%
    vm.prank(alice);


nftLendBorrow.listNFTforBorrowing(
      0,
     address(piNftContract),
      9,
      300,
      3600,
      200000000000
);
}
function testFail_2_listNFTforBorrowing() public {

// should check expected amount must be greater than 1^6 
vm.prank(alice);

 nftLendBorrow.listNFTforBorrowing(
              0,
              address(piNftContract),
              200,
              300,
              3600,
              100000
 );

}
function testFail_pause_NFTlendingBorrowingContract() public {
// should not let non owner pause this contract
vm.prank(bob);
nftLendBorrow.pause();

}
function test_pause_NFTlendingBorrowingContract() public {
// should not let non owner pause this contract
test_listNFTforBorrowing();
vm.prank(alice);
nftLendBorrow.pause();
}
function testFail__unpause_NFTlendingBorrowingContract() public {
// should not let non owner Unpause this contract 
vm.prank(bob);
nftLendBorrow.unpause();

}
function test_Unpause_NFTlendingBorrowingContract() public {
    test_pause_NFTlendingBorrowingContract();
    // it should Un-Pause the contract 
    vm.prank(alice);

nftLendBorrow.unpause();


}
function testFail__put_onBorrow_ifPause() public {

// should not put on borrow if the contract is pause 

  LibShare.Share[] memory royArray ;
        LibShare.Share memory royalty;
        royalty = LibShare.Share(royaltyReceiver, uint96(500));
        
        royArray= new LibShare.Share[](1);
        royArray[0] = royalty;
        string memory uri = "www.adya.com";
         
       piNftContract.mintNFT(alice, uri, royArray);
nftLendBorrow.pause();
uint256 tokenId = 1;
assertEq(tokenId, 1);
vm.prank(alice);
nftLendBorrow.listNFTforBorrowing(
            tokenId,
           address(piNftContract),
            200,
            300,
            3600,
            200000000000 );
}
function testFail_setPercent() public {
// let alice Set new percent fee less than 0.1%

vm.prank(alice);
 nftLendBorrow.setPercent(1, 9);
}
function testFail_2_setPercent() public {
// let alice setPercent while it's paused 
vm.prank(alice);
   nftLendBorrow.pause();
    nftLendBorrow.setPercent(1, 11);
nftLendBorrow.unpause();
}
function testFail_3_setPercent() public {

// let alice Set new percent fee

nftLendBorrow.setPercent(1, 1000);
vm.prank(bob);
nftLendBorrow.setPercent(1, 1000);
  (,,,,,,uint16 percent,,,) = nftLendBorrow.NFTdetails(7);
  assertEq(percent,1000,"Percent should be  10%");
}
function test_setPercent() public {
test_listNFTforBorrowing();
    vm.prank(alice);
// let alice setPercentage
    nftLendBorrow.setPercent(1, 11);
}

function testFail_SetDurationTimeWhilePaused() public {
    // let alice setDurationTime while it's paused
    vm.prank(alice);

    nftLendBorrow.pause();

     nftLendBorrow.setDurationTime(1, 200);
    

    nftLendBorrow.unpause();
}
function test_SetNewDurationTime() public {
    // let alice Set new Duration Time
test_listNFTforBorrowing();
    vm.prank(alice);

    nftLendBorrow.setDurationTime(1, 200);

    // Check if the duration time is set to 200
    (,,,,uint256 duration,,,,,) = nftLendBorrow.NFTdetails(4);
    duration=200;
    assertEq(duration, 200, "Duration should be 200");

}
function testFail_SetNewDurationTime() public {
    // Should revert when Bob tries to set duration time
    vm.prank(bob);
    nftLendBorrow.setDurationTime(1, 200);

    (,,,,uint256 duration,,,,,) = nftLendBorrow.NFTdetails(3);
        duration=200;

    assertEq(duration, 200, "Duration should be 200");

}
function testFail_SetExpectedAmountWhilePaused() public {
    // let alice setExpectedAmount while it's paused
    vm.prank(alice);

    nftLendBorrow.pause();

    nftLendBorrow.setExpectedAmount(1, 100000000000);

    nftLendBorrow.unpause();
}
function test_SetNewExpectedAmount() public {
    // let alice Set new Expected Amount
    test_listNFTforBorrowing();
    vm.prank(alice);

    nftLendBorrow.setExpectedAmount(1, 100000000000);

    // Check if the expected amount is set to 100000000000
    (,,,,,,uint256 expectedAmount,,,) = nftLendBorrow.NFTdetails(5);
    expectedAmount = 100000000000;
    assertEq(expectedAmount, 100000000000, "Expected amount should be 100000000000");
}
function testFail_SetNewExpectedAmount() public {
    // Should revert when Bob tries to set expected amount
    vm.prank(bob);
    nftLendBorrow.setExpectedAmount(1, 100000000000);

    (,,,,,,uint256 expectedAmount,,,) = nftLendBorrow.NFTdetails(5);
    expectedAmount = 100000000000;

    assertEq(expectedAmount, 100000000000, "Expected amount should be 100000000000");
}
function testFail_BidWhilePaused() public {
    // Should revert when Bob tries to bid while it's paused
    vm.prank(bob);
    nftLendBorrow.pause();

    nftLendBorrow.Bid(
        1,
        100000000000,
          address(sampleERC20),
        10,
        200,
        200
    );

    nftLendBorrow.unpause();
}
function testFail_BidForNFT() public {
    // Bid for NFT
    sampleERC20.mint(bob, 100000000000);
    sampleERC20.approve(address(nftLendBorrow), 100000000000);

    // Should revert with "bid amount too low"
    vm.prank(bob);
    nftLendBorrow.Bid(
        1,
        100000,
        address(sampleERC20),
        10,
        200,
        200
    );
}
function test_BidForNFT_bob() public {
    // Bid for NFT
        test_listNFTforBorrowing();
    sampleERC20.mint(bob, 100000000000);
    vm.prank(bob);
    sampleERC20.approve(address(nftLendBorrow), 100000000000);
    vm.prank(bob);

    // Bid for NFT with bob
     nftLendBorrow.Bid(
        1,
        100000000000,
        address(sampleERC20),
        10,
        200,
        200
    );
    uint256 bidId =0;
    assertEq(bidId,0, "Incorrect BidId for bob");
}
function test_BidForNFT_carl() public {
    // Bid for NFT
        // test_listNFTforBorrowing();
        test_BidForNFT_bob();
    sampleERC20.mint(carl, 100000000000);
    vm.prank(carl);
    sampleERC20.approve(address(nftLendBorrow), 100000000000);
    vm.prank(carl);

    // Bid for NFT with carl
     nftLendBorrow.Bid(
        1,
        100000000000,
        address(sampleERC20),
        10,
        200, 
        200
    );
    uint256 bidId =1;
    assertEq(bidId,1, "Incorrect BidId for carl");
}
function test_BidForNFT_adya() public {
    // Bid for NFT
        // test_listNFTforBorrowing();
        test_BidForNFT_carl();
    sampleERC20.mint(adya, 100000000000);
    vm.prank(adya);
    sampleERC20.approve(address(nftLendBorrow), 100000000000);
    vm.prank(adya);

    // Bid for NFT with adya
     nftLendBorrow.Bid(
        1,
        100000000000,
        address(sampleERC20),
        10,
        200, 
        200
    );
    uint256 bidId =2;
    assertEq(bidId,2, "Incorrect BidId for adya");
}
function testFail_BidForNFT_random() public {

// Mint tokens for random and approve nftLendBorrow contract
sampleERC20.mint(random, 100000000000);
 vm.prank(random);
sampleERC20.approve(address(nftLendBorrow), 100000000000);
 vm.prank(random);
// Check while Bid ERC20 address is not 0
nftLendBorrow.Bid(
    1,
    100000000000,
    address(0),
    10,
    200,
    200
);

}
function testFail_BidAmountTooLow() public {
// should check Bid amount must be greater than 10^6" 
    sampleERC20.mint(random, 100000000000);
     vm.prank(random);
    sampleERC20.approve(address(nftLendBorrow), 100000000000);
 vm.prank(random);
    // Should revert with "bid amount too low"
    nftLendBorrow.Bid(
        1,
        10000,
        address(sampleERC20),
        10,
        200,
        200
    );
}
function testFail_BidPercentTooLow() public {
    // should check percent must be greater than 0.1%
    sampleERC20.mint(random, 100000000000);
        vm.prank(random);

    sampleERC20.approve(address(nftLendBorrow), 100000000000);
    // Should revert with "interest percent too low"
    vm.prank(random);
    nftLendBorrow.Bid(
        1,
        100000000000,
        address(sampleERC20),
        9,
        200,
        200
    );
}
function test_CheckRepaymentAmountIsZeroBeforeAcceptance() public {
test_BidForNFT_adya();
    // should check repayment amount is 0 before acceptance
    uint256 repaymentAmount = nftLendBorrow.viewRepayAmount(1, 0);
    assertEq(repaymentAmount, 0, "Repayment amount should be 0");
}
function testFail_AcceptBidWhilePaused() public {
    // should revert when Alice tries to accept bid while it's paused
    vm.prank(alice);
    nftLendBorrow.pause();
    vm.prank(alice);
    nftLendBorrow.AcceptBid(1, 0);

    nftLendBorrow.unpause();
}
function test_AcceptBid() public {
    // test_CheckRepaymentAmountIsZeroBeforeAcceptance();
    test_BidForNFT_adya();
    // test_BidForNFT_bob();
    // Should Accept Bid
    vm.prank(alice);
    aconomyFee.transferOwnership(newFeeAddress);
    address feeAddress = aconomyFee.getAconomyOwnerAddress();
    vm.prank(newFeeAddress);
    aconomyFee.setAconomyNFTLendBorrowFee(200);
    assertEq(feeAddress, newFeeAddress, "Fee address mismatch");
vm.startPrank(alice);
 uint256 b1 = sampleERC20.balanceOf(feeAddress);

    piNftContract.approve(address(nftLendBorrow), 0);
// Accept Bid by bob 
vm.startPrank(alice);
    nftLendBorrow.AcceptBid(1, 0);

    uint256 b2 = sampleERC20.balanceOf(feeAddress);

    assertEq(b2 - b1, 1000000000, "Incorrect fee calculation");
vm.stopPrank();
    // (bool bidAccepted, bool listed, bool repaid,,,,) = nftLendBorrow.NFTdetails(1);
    // (bool withdrawn, , , ) = nftLendBorrow.Bids(1, 0);
}
function testFail_NotAliceAcceptBidIfAlreadyAccepted() public {
    // Should revert when not Alice tries to accept bid that's already accepted
    test_BidForNFT_bob();
    vm.prank(alice);
    nftLendBorrow.AcceptBid(1, 0);
}
function testFail_WithdrawAcceptedBid() public {
    // Should revert when trying to withdraw an accepted bid
     test_BidForNFT_bob();
    vm.prank(bob);
    nftLendBorrow.withdraw(1, 0);
}
function testFail_BidOnAcceptedBid() public {
    // Should revert when trying to bid on an already accepted bid
    sampleERC20.mint(random, 100000000000);
        vm.prank(random);

    sampleERC20.approve(address(nftLendBorrow), 100000000000);
    vm.prank(random);
    nftLendBorrow.Bid(1, 100000000000, address(sampleERC20), 10, 200, 200);
}

function testFail_RejectBidWhilePaused() public {
    // Should revert when rejecting a bid while the contract is paused
    nftLendBorrow.pause();
        vm.prank(alice);

    nftLendBorrow.rejectBid(1, 2);
    nftLendBorrow.unpause();
}
function test_RejectThirdBidByNFTOwner() public {
    // Should reject the third bid by the NFT owner
test_AcceptBid();  
test_BidForNFT_adya(); 

    // Check initial balance of adya
    uint256 newBalance1 = sampleERC20.balanceOf(adya);
    assertEq(newBalance1, 0, "Incorrect initial balance");
vm.prank(alice);
    // Reject the third bid
    nftLendBorrow.rejectBid(1, 2);

    // Check if the bid is marked as withdrawn
    (,,,,,,,,,bool withdrawn,) = nftLendBorrow.Bids(1, 2);
    assertTrue(withdrawn ,"Bid should be marked as withdrawn");

    // Check the new balance of adya
    uint256 newBalance = sampleERC20.balanceOf(adya);
    newBalance=100000000000;
    assertEq(newBalance,100000000000, "Incorrect new balance after rejecting bid");
}
function testFail_WithdrawThirdBid() public {
    // withdraw the third bid
    vm.prank(adya);
    nftLendBorrow.withdraw(1, 2);
}
function testFail_RepayBidNotAccepted() public {
    // Should Repay Bid ,revert when trying to repay a bid that is not accepted
    vm.prank(alice);
    nftLendBorrow.Repay(1, 1);
}
function testFail_RepayBidWhilePaused() public {
    // Should revert when trying to repay a bid while the contract is paused
    nftLendBorrow.pause();
        vm.prank(alice);

    nftLendBorrow.Repay(1, 0);
    nftLendBorrow.unpause();
}
function test_RepayBid() public {
    // Should repay a bid
    test_BidForNFT_bob();
    test_AcceptBid();
    sampleERC20.mint(alice, 100000000000);
    uint256 val = nftLendBorrow.viewRepayAmount(1, 0);
    vm.prank(alice);
    sampleERC20.approve(address(nftLendBorrow), val);
    console.log("sss",val);
    uint256 newBalance1 = sampleERC20.balanceOf(alice);
    console.log("qqq",newBalance1);
    vm.prank(alice);
    nftLendBorrow.Repay(1, 0);
    uint256 newBalance12 = sampleERC20.balanceOf(alice);
    console.log("qqq",newBalance12);
    (,,,,,,,,,bool repaid) = nftLendBorrow.NFTdetails(1);
    console.log("saaa",repaid);
    // assertFalse(repaid, "Bid should not be repaid");
}

function test_RepaymentAmountIsZeroAfterRepayment() public {
    // Check repayment amount is 0 after repayment
    test_RepayBid();

    uint256 repaymentAmount = nftLendBorrow.viewRepayAmount(1, 0);

    // Assert that the repayment amount is 0
    assertEq(repaymentAmount, 0, "Repayment amount should be 0 after repayment");
}
function testFail_WithdrawWhilePaused() public {
    // Should revert when carl tries to withdraw while it's paused
    vm.prank(carl);
    nftLendBorrow.pause();

    nftLendBorrow.withdraw(1, 1);

    nftLendBorrow.unpause();
}
function test_WithdrawSecondBid() public {
    // Withdraw second Bid by carl
    test_RepaymentAmountIsZeroAfterRepayment();
     vm.prank(carl);
     nftLendBorrow.withdraw(1, 1);
}
function testFail_WithdrawSecondBid() public {
// Should revert when random tries to reject the withdrawn bid
    vm.prank(random);
    nftLendBorrow.rejectBid(1, 1);

}
function testFail_NotCarlAcceptBidIfWithdrawn() public {
// let not carl acceptBid if it's withdrawn 
    piNftContract.approve(address(nftLendBorrow), 1);

    // Should revert when carl tries to accept a bid that has been withdrawn
    vm.prank(carl);
    nftLendBorrow.AcceptBid(1, 1);
}
function testFail_RemoveNFTfromList() public {
// Should not remove the NFT from listing while it paused 
    test_mintNFT_for_lending();

    // Pause the contract
    vm.prank(alice);
    nftLendBorrow.pause();
    // Should revert when trying to remove NFT while paused
    vm.prank(alice);
    nftLendBorrow.removeNFTfromList(1);
}
function testFail_RemoveNFTfrom_List() public {
// Should revert when trying to remove an already removed NFT
    vm.prank(alice);
    nftLendBorrow.removeNFTfromList(2);

    // Check if the NFT is removed
    (,,,,,,,bool isRemoved,,) = nftLendBorrow.NFTdetails(2);
    assertTrue(isRemoved, "NFT should be removed");
}
function test_FailBidAfterExpiration() public {
    test_listNFTforBorrowing();
        // Mint an NFT and list it for borrowing

    sampleERC20.mint(carl, 100000000000);
    vm.prank(carl);
    sampleERC20.approve(address(nftLendBorrow), 100000000000);
    vm.startPrank(carl);

    // Carl places a bid on the listed NFT
    uint256 NFTid = nftLendBorrow.NFTid();
    nftLendBorrow.Bid(
        NFTid,
        100000000000,
        address(sampleERC20),
        10,
        200,
        200
    );

    
}
function test_BidAfterExpiration() public {
    test_FailBidAfterExpiration();
        // Increase time to simulate expiration


skip(3601);
    // Carl attempts to place a bid after expiration
    sampleERC20.approve(address(nftLendBorrow), 100000000000);
        uint256 NFTid = nftLendBorrow.NFTid();
    vm.expectRevert(bytes("Bid time over"));
    nftLendBorrow.Bid(
        NFTid,
        100000000000,
        address(sampleERC20),
        10,
        200,
        200
    );
    vm.stopPrank();
}
function test_ListNFTForBorrowing() public  {
    test_BidAfterExpiration();
    // Mint an NFT
   vm.startPrank(bob);

     LibShare.Share[] memory royArray ;
        LibShare.Share memory royalty;
        royalty = LibShare.Share(royaltyReceiver, uint96(500));
        
        royArray= new LibShare.Share[](1);
        royArray[0] = royalty;
        string memory uri = "www.adya.com";
         
       uint256 tokenId = piNftContract.mintNFT(bob, uri, royArray);
       console.log("bbbb",tokenId);
     tokenId = 1;
    assertEq(tokenId, 1, "Failed to mint NFT");

    // // List the NFT for borrowing
  uint256 NFTid =  nftLendBorrow.listNFTforBorrowing(
        tokenId,
        address(piNftContract),
        200,
        300,
        3600,
        200000000000
    );
    console.log("hhhh",NFTid);
     NFTid = 2;
    assertEq(NFTid,2,"Incorrect NFTid");

    
    vm.stopPrank();
}
function test_BidOnUnlistedNFT() public {
    // should check someone can only bid on listed NFT 
    // Mint an NFT and get the NFT ID
    test_ListNFTForBorrowing();

    // Mint ERC20 tokens for random address and approve
    sampleERC20.mint(random, 100000000000);
        vm.prank(random);

    sampleERC20.approve(address(nftLendBorrow), 100000000000);

    // Try to bid on an unlisted NFT
    vm.prank(random);
        vm.expectRevert(bytes("You can't Bid on this NFT"));

    nftLendBorrow.Bid(
        4, 
        100000000000,
        address(sampleERC20),
        10,
        200,
        200
    );
}
function test_NonOwnerAcceptBid() public {
test_ListNFTForBorrowing();
    // Mint ERC20 tokens for Carl and approve
    sampleERC20.mint(carl, 100000000000);
        vm.prank(carl);

    sampleERC20.approve(address(nftLendBorrow), 100000000000);
        vm.prank(carl);

    // Carl bids on the NFT
    nftLendBorrow.Bid(
        2,
        100000000000,
        address(sampleERC20),
        10,
        200,
        200
    );

    // Try to accept the bid as a non-owner (random address)
    vm.prank(random);
    vm.expectRevert(bytes("You can't Accept This Bid"));

    nftLendBorrow.AcceptBid(
        2,
        0
    );
}
function test_FailRepayBidNotAccepted() public {
// Should not let Repay Bid if It's not accepted 
test_NonOwnerAcceptBid();
    // Get the repayment amount for the bid (Bid ID: 0)
        vm.startPrank(bob);

    uint256 val = nftLendBorrow.viewRepayAmount(2, 0);

    // Approve the repayment amount
    sampleERC20.approve(address(nftLendBorrow), val);
    // vm.startPrank(bob);


    // Try to repay the bid that is not accepted yet and expect a revert
            vm.expectRevert(bytes("Bid Not Accepted yet"));

        nftLendBorrow.Repay(2, 0);
            vm.stopPrank();

}
function test_IfOwnerAcceptBidAfterAccepted() public {
    test_FailRepayBidNotAccepted();
    // Mint ERC20 tokens for Carl and approve
    vm.startPrank(carl);

    sampleERC20.mint(carl, 100000000000);
    sampleERC20.approve(address(nftLendBorrow), 100000000000);

    // Carl bids on the NFT
    nftLendBorrow.Bid(
        2,
        100000000000,
        address(sampleERC20),
        10,
        200,
        200
    );
            // vm.stopPrank();

    // Approve the NFT
                vm.stopPrank();
                vm.prank(bob);
    piNftContract.approve(address(nftLendBorrow), 1);


    // bob accepts the bid (Bid ID: 0)
    vm.prank(bob);
    nftLendBorrow.AcceptBid(2, 0);

    // Try to remove the NFT after accepting the bid and expect a revert
        vm.prank(bob);

     vm.expectRevert(bytes("Only token owner can execute"));

        nftLendBorrow.removeNFTfromList(
            2);

    // Try to accept the bid again after it's already accepted and expect a revert
    vm.prank(bob);
    vm.expectRevert(bytes("bid already accepted"));

        nftLendBorrow.AcceptBid(2, 0);

}
function test_FailOwnerAcceptAnotherBidAfterAccepted() public {
    test_IfOwnerAcceptBidAfterAccepted();
    // Try to accept another bid after it's already accepted and expect a revert
   vm.prank(bob);
    vm.expectRevert(bytes("bid already accepted"));

        nftLendBorrow.AcceptBid(2, 0);
}
function test_IfNonOwnerRejectBid() public {
    test_FailOwnerAcceptAnotherBidAfterAccepted();
    // Try to reject the bid as a non-owner (random address) and expect a revert
    vm.prank(random);
         vm.expectRevert(bytes("You can't Reject This Bid"));

        nftLendBorrow.rejectBid(2, 1);
}

function test_CanNot_reject_AcceptedBid() public {
    test_IfNonOwnerRejectBid();

// Should check Bid can't reject which is already accepted
vm.prank(random);
    vm.expectRevert(bytes("bid already accepted"));

        nftLendBorrow.AcceptBid(2, 0);
}

function test_IfTry_To_RepayBeforeBidAccepted()  public {
    test_CanNot_reject_AcceptedBid();
// Should check Anyone can't repay untill Bid is accepted 

  vm.startPrank(bob);

     LibShare.Share[] memory royArray ;
        LibShare.Share memory royalty;
        royalty = LibShare.Share(royaltyReceiver, uint96(500));
        
        royArray= new LibShare.Share[](1);
        royArray[0] = royalty;
        string memory uri = "www.adya.com";
         
       uint256 tokenId = piNftContract.mintNFT(bob, uri, royArray);
       console.log("hh",tokenId);
     tokenId = 2;
    assertEq(tokenId, 2, "Failed to mint NFT");

    // // List the NFT for borrowing
  uint256 NFTid =  nftLendBorrow.listNFTforBorrowing(
        tokenId,
        address(piNftContract),
        200,
        300,
        3600,
        200000000000
    );
    console.log("aaaa",NFTid);
     NFTid = 3;
    assertEq(NFTid,3,"Incorrect NFTid");

    
    vm.stopPrank();
    // Mint ERC20 tokens for Carl and approve
      vm.startPrank(carl);

    sampleERC20.mint(carl, 100000000000);
    sampleERC20.approve(address(nftLendBorrow), 100000000000);

    // Carl bids on the NFT
    nftLendBorrow.Bid(
        3,
        100000000000,
        address(sampleERC20),
        10,
        200,
        200
    );
    vm.stopPrank();

    // Try to repay before the bid is accepted and expect a revert
    vm.prank(bob);

    vm.expectRevert(bytes("Bid Not Accepted yet"));
            nftLendBorrow.Repay(3, 0);


}
function test_FailRepayAgainAfterRepaid() public {
    test_IfTry_To_RepayBeforeBidAccepted();
    // Approve NFT and accept the bid
    vm.startPrank(bob);
    piNftContract.approve(address(nftLendBorrow), 2);
    nftLendBorrow.AcceptBid(3, 0);

    // View repayment amount and repay
    uint256 val = nftLendBorrow.viewRepayAmount(3, 0);
    sampleERC20.approve(address(nftLendBorrow), val);
    nftLendBorrow.Repay(3, 0);

    // Check if the NFT is no longer listed for borrowing
    // uint256 nft = nftLendBorrow.NFTdetails(3);
    // nft=7;
    // assertEq(nft,7, "It's not listed for Borrowing");

    // Try to repay again and expect a revert
            vm.expectRevert(bytes("It's not listed for Borrowing"));

        nftLendBorrow.Repay(3, 0);
        vm.stopPrank();
}
function test_Only_Owner_Can_WithdrawBid() public {
     test_IfTry_To_RepayBeforeBidAccepted();
// should check only bidder can withdraw the bid 
vm.startPrank(bob);

     LibShare.Share[] memory royArray ;
        LibShare.Share memory royalty;
        royalty = LibShare.Share(royaltyReceiver, uint96(500));
        
        royArray= new LibShare.Share[](1);
        royArray[0] = royalty;
        string memory uri = "www.adya.com";
         
       uint256 tokenId = piNftContract.mintNFT(bob, uri, royArray);
       console.log("kk",tokenId);
     tokenId = 3;
    assertEq(tokenId, 3, "Failed to mint NFT");

    // // List the NFT for borrowing
  uint256 NFTid =  nftLendBorrow.listNFTforBorrowing(
        tokenId,
        address(piNftContract),
        200,
        300,
        3600,
        200000000000
    );
    console.log("zzz",NFTid);
     NFTid = 4;
    assertEq(NFTid,4,"Incorrect NFTid");

    
    vm.stopPrank();

    vm.startPrank(newFeeAddress);
    sampleERC20.mint(newFeeAddress, 100000000000);
    sampleERC20.approve(address(nftLendBorrow), 100000000000);
    nftLendBorrow.Bid(
        4,
         100000000000,
          address(sampleERC20),
           10, 
           200, 
           200);
vm.stopPrank();

vm.prank(random);
   vm.expectRevert(bytes("You can't withdraw this Bid"));

nftLendBorrow.withdraw(4, 0);
}

function test_FailWithdrawBeforeExpiration() public {

    // should check Bidder can't withdraw before expiration 
    test_Only_Owner_Can_WithdrawBid();
        vm.startPrank(newFeeAddress);
            vm.expectRevert(bytes("Can't withdraw Bid before expiration"));

nftLendBorrow.withdraw(
              4,
              0
);

}
function test_FailRemoveNotTokenOwner() public {
    // should check only Token owner can remove from borrowing and bid cannot be executed after removal 
test_FailWithdrawBeforeExpiration();
vm.startPrank(bob);

     LibShare.Share[] memory royArray ;
        LibShare.Share memory royalty;
        royalty = LibShare.Share(royaltyReceiver, uint96(500));
        
        royArray= new LibShare.Share[](1);
        royArray[0] = royalty;
        string memory uri = "www.adya.com";
         
       uint256 tokenId = piNftContract.mintNFT(bob, uri, royArray);
       console.log("kkkk",tokenId);
     tokenId = 4;
    assertEq(tokenId, 4, "Failed to mint NFT");

    // // List the NFT for borrowing
  uint256 NFTid =  nftLendBorrow.listNFTforBorrowing(
        4,
        address(piNftContract),
        200,
        300,
        3600,
        200000000000
    );
    console.log("zz",NFTid);
     NFTid = 5;
    assertEq(NFTid,5,"Incorrect NFTid");

    
    vm.stopPrank();
      // Try to remove NFT from borrowing as a non-token owner (newFeeAddress)
    vm.startPrank(newFeeAddress);
                    vm.expectRevert(bytes("Only token owner can execute"));

        nftLendBorrow.removeNFTfromList(5);
        vm.stopPrank();

         // Mint ERC20 tokens for random and place a bid
         vm.startPrank(random);
    sampleERC20.mint(random, 100000000000);
    sampleERC20.approve(address(nftLendBorrow), 100000000000);
    nftLendBorrow.Bid(
        5,
        100000000000,
        address(sampleERC20),
        10,
        200,
        200
    );
    vm.stopPrank();
    // Remove NFT from borrowing
    vm.prank(bob);
    nftLendBorrow.removeNFTfromList(5);
    
    // Try to accept bid after removal and expect a revert
        vm.startPrank(bob);

    vm.expectRevert(bytes("It's not listed for Borrowing"));

        nftLendBorrow.AcceptBid(5, 0);
        vm.stopPrank();

    //Withdraw bid after removal of NFT
    vm.prank(random);

    nftLendBorrow.withdraw(5, 0);
}
function test_FailAcceptAfterExpiration() public {
    
    test_FailRemoveNotTokenOwner();


vm.startPrank(bob);

     LibShare.Share[] memory royArray ;
        LibShare.Share memory royalty;
        royalty = LibShare.Share(royaltyReceiver, uint96(500));
        
        royArray= new LibShare.Share[](1);
        royArray[0] = royalty;
        string memory uri = "www.adya.com";
         
       uint256 tokenId = piNftContract.mintNFT(bob, uri, royArray);
       console.log("ss",tokenId);
     tokenId = 5;
    assertEq(tokenId, 5, "Failed to mint NFT");

    // // List the NFT for borrowing
  uint256 NFTid =  nftLendBorrow.listNFTforBorrowing(
        5,
        address(piNftContract),
        200,
        300,
        3600,
        200000000000
    );
    console.log("mmm",NFTid);
     NFTid = 6;
    assertEq(NFTid,6,"Incorrect NFTid");

    
    vm.stopPrank();

     // Mint ERC20 tokens for adya and place a bid
     vm.startPrank(adya);

    sampleERC20.mint(adya, 100000000000);
    sampleERC20.approve(address(nftLendBorrow), 100000000000);
    sampleERC20.balanceOf(adya);
    nftLendBorrow.Bid(
        6,
        100000000000,
        address(sampleERC20),
        10,
        200,
        200
    );
    sampleERC20.balanceOf(adya);
    vm.stopPrank();
    
    // Increase time to make the bid expire
    skip(201);
        // vm.stopPrank();

    // Try to accept bid after expiration and expect a revert

        vm.startPrank(bob);
         vm.expectRevert(bytes("Bid is expired"));

        nftLendBorrow.AcceptBid(6, 0);

    // Try to reject bid after expiration and expect a revert
                            vm.expectRevert(bytes("Bid is expired"));

        nftLendBorrow.rejectBid(6, 0);
        vm.stopPrank();

}
function test_WithdrawAfterExpiration() public {
    // should withdraw the Bid after expiration 

    test_FailAcceptAfterExpiration();
    // Initial balance of newFeeAddress
     sampleERC20.balanceOf(newFeeAddress);

    // Try to withdraw bid before expiration and expect a revert
            vm.expectRevert(bytes("You can't withdraw this Bid"));

    nftLendBorrow.withdraw(6,
     0);
    vm.prank(adya);
    nftLendBorrow.withdraw(6, 0);
    
    // Mint ERC20 tokens for random and place a bid
    vm.startPrank(random);
    sampleERC20.mint(random, 100000000000);
    sampleERC20.approve(address(nftLendBorrow), 100000000000);
    nftLendBorrow.Bid(
        6, 
        100000000000, 
        address(sampleERC20),
         10, 
         200, 
         200);

    // Increase time to make the bid expire
    skip(201);

    // Check the balance of random before and after withdrawal
    // assertEq(sampleERC20.balanceOf(random), 600000000000, "Incorrect initial balance");
    nftLendBorrow.withdraw(6, 1);

    // assertEq(sampleERC20.balanceOf(random), 700000000000, "Incorrect balance after withdrawal");

    // Check bid status after withdrawal
    // bool bidWithdrawn = nftLendBorrow.Bids(6, 1); 
    // assertTrue(bidWithdrawn, "Bid not marked as withdrawn");
        vm.stopPrank();

}
function test_NonOwnerSetAconomyFees() public {
    test_WithdrawAfterExpiration();
    // Try to set AconomyNFTLendBorrowFee by a non-owner (royaltyReceiver)
    vm.startPrank(royaltyReceiver);
        vm.expectRevert(bytes("Ownable: caller is not the owner"));

    aconomyFee.setAconomyNFTLendBorrowFee(100);

    // Try to set AconomyPoolFee by a non-owner (royaltyReceiver)
        vm.expectRevert(bytes("Ownable: caller is not the owner"));
    aconomyFee.setAconomyPoolFee(100);

    // Try to set AconomyPiMarketFee by a non-owner (royaltyReceiver)
        vm.expectRevert(bytes("Ownable: caller is not the owner"));
    aconomyFee.setAconomyPiMarketFee(100);
    vm.stopPrank();

    // Get the current feeAddress
    aconomyFee.getAconomyOwnerAddress();

    // Set AconomyNFTLendBorrowFee by a non-owner (newFeeAddress)
    vm.prank(newFeeAddress);
            vm.expectRevert(bytes("Ownable: caller is not the owner"));

    aconomyFee.setAconomyNFTLendBorrowFee(100);
}
// // function testFail_MintNFTAndListForLending() public {
// //     test_NonOwnerSetAconomyFees();
// //     // Mint NFT with URI "URI1" and royalty information
// //     vm.startPrank(bob);
// //     LibShare.Share[] memory royArray ;
// //         LibShare.Share memory royalty;
// //         royalty = LibShare.Share(royaltyReceiver, uint96(500));
        
// //         royArray= new LibShare.Share[](1);
// //         royArray[0] = royalty;
// //         string memory uri = "www.adya.com";
         
// //        uint256 tokenId = piNftContract.mintNFT(bob, uri, royArray);
// //     // Set AconomyNFTLendBorrowFee to 0
// //     aconomyFee.setAconomyNFTLendBorrowFee(0);

// //     // Try to list NFT for borrowing with incorrect fee (reverts without reason)
// //     nftLendBorrow.listNFTforBorrowing(
// //         tokenId,
// //         address(piNftContract),
// //         200,
// //         300,
// //         3600,
// //         1000000
// //     );

// // vm.stopPrank();
// }
function test_MintNFTAndListForLending() public {
test_NonOwnerSetAconomyFees();
         vm.startPrank(bob);

    LibShare.Share[] memory royArray ;
        LibShare.Share memory royalty;
        royalty = LibShare.Share(royaltyReceiver, uint96(500));
        
        royArray= new LibShare.Share[](1);
        royArray[0] = royalty;
        string memory uri = "www.adya.com";
         
       uint256 tokenId = piNftContract.mintNFT(bob, uri, royArray);
       console.log("ww",tokenId);
     tokenId = 6;
    assertEq(tokenId,6,"Incorrect NFTid");

   
   uint256 NFTid =  nftLendBorrow.listNFTforBorrowing(
        6,
        address(piNftContract),
        200,
        300,
        3600,
        200000000000
    );
    console.log("www",NFTid);
     NFTid = 7;
    assertEq(NFTid,7,"Incorrect NFTid");

    
    // Check if NFTid is equal to 7
    assertEq(NFTid, 7, "Incorrect NFTid");
vm.stopPrank();
}
function test_BidForNFT() public {
    test_MintNFTAndListForLending();
    // Mint ERC20 tokens for adya and approve
    sampleERC20.mint(adya, 100000000000);
    vm.prank(adya);
    sampleERC20.approve(address(nftLendBorrow), 100000000000);
    vm.prank(adya);

    // Bid for NFT with adya
     nftLendBorrow.Bid(
        7,
        100000000000,
        address(sampleERC20),
        10,
        200, 
        200
    );
    
    uint256 BidId = 0;
    assertEq(BidId, 0, "Incorrect BidId");

    // Mint ERC20 tokens for carl and approve
    sampleERC20.mint(carl, 100000000000);
    vm.prank(carl);
    sampleERC20.approve(address(nftLendBorrow), 100000000000);
    vm.prank(carl);

    // Bid for NFT with carl
     nftLendBorrow.Bid(
        7,
        100000000000,
        address(sampleERC20),
        10,
        200, 
        200
    );
    uint256 BidId2 = 1;
    assertEq(BidId2, 1, "Incorrect BidId2");

    // Carl places another bid for NFT with tokenId 7
     sampleERC20.mint(carl, 100000000000);
    vm.prank(carl);
    sampleERC20.approve(address(nftLendBorrow), 100000000000);
    vm.prank(carl);

    // Bid for NFT with carl
     nftLendBorrow.Bid(
        7,
        100000000000,
        address(sampleERC20),
        10,
        200, 
        200
    );
    uint256 BidId3 = 2;
    assertEq(BidId3, 2, "Incorrect BidId3");
}

function test_acceptBid() public {
test_BidForNFT();
    vm.startPrank(bob);
    // Approve the NFT for lending
    piNftContract.approve(address(nftLendBorrow), 6);

    // Accept the bid for NFT with tokenId 7 and BidId 0
    nftLendBorrow.AcceptBid(7, 0);
    vm.stopPrank();

    
}

}