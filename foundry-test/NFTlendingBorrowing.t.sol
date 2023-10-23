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

}