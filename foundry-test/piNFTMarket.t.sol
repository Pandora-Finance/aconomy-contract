// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "forge-std/console2.sol";

import "contracts/piNFT.sol";
import "contracts/utils/sampleERC20.sol";
import "contracts/piMarket.sol";
import "contracts/utils/LibShare.sol";


 contract PiMarketTest is Test {
    piNFT piNftContract;
    SampleERC20 erc20Contract;
    piMarket pimarket;
    
    address payable alice = payable(address(0xABCD));
    address payable validator = payable(address(0xAACD));
    address payable bob = payable(address(0xAAAD));
    address payable royaltyReceiver = payable(address(0xAAAA));
    address payable feeReceiver = payable(address(0xABBD));
    address payable bidder1 = payable(address(0xABBB));
    address payable bidder2 = payable(address(0xABCC));
    // address payable feeAddress = payable(address(0xABBC));

    struct TokenMeta {
        uint256 saleId;
        address tokenContractAddress;
        uint256 tokenId;
        uint256 price;
        bool directSale;
        bool bidSale;
        bool status;
        uint256 bidStartTime;
        uint256 bidEndTime;
        address currentOwner;
    }
  struct BidOrder {
        uint256 bidId;
        uint256 saleId;
        address sellerAddress;
        address buyerAddress;
        uint256 price;
        bool withdrawn;
    }
    function setUp() public {
        piNftContract = new piNFT("Aconomy", "ACO");
        erc20Contract = new SampleERC20();
        pimarket = new piMarket(feeReceiver);
    }

    function test_create_a_piNFT_with_500_erc20_tokens_to_alice() public{
        erc20Contract.mint(validator, 1000);

        LibShare.Share[] memory royArray ;
        LibShare.Share memory royalty;
        royalty = LibShare.Share(royaltyReceiver, uint96(500));   
        royArray= new LibShare.Share[](1);
        royArray[0] = royalty;
        string memory uri = "www.adya.com";

        uint256 tokenId = piNftContract.mintNFT(alice, uri, royArray);
        assertEq(tokenId, 0, "Unable to mint NFT");

        vm.prank(validator);
        erc20Contract.approve(address(piNftContract), 500);
        vm.prank(validator);
        piNftContract.addERC20(validator, tokenId, address(erc20Contract), 500);

       uint256 tokenBal =  piNftContract.viewBalance(tokenId, address(erc20Contract));
       assertEq(tokenBal, 500, "Failed to add ERC20 to piNFT");
    }

    function test_alice_place_piNFT_on_sale() public {
        test_create_a_piNFT_with_500_erc20_tokens_to_alice();
        vm.prank(alice);
         piNftContract.approve(address(pimarket), 0);
         vm.prank(alice);
       pimarket.sellNFT(address(piNftContract), 0, 5000);
      assertEq(
        piNftContract.ownerOf(0),
        address(pimarket),
        "Failed to put piNFT on Sale"
      );
    }

    function testFail_bob_place_piNFT_on_sale() public {
        test_create_a_piNFT_with_500_erc20_tokens_to_alice();
        vm.prank(bob);
         piNftContract.approve(address(pimarket), 0);
         vm.prank(bob);
       pimarket.sellNFT(address(piNftContract), 0, 5000);
      assertEq(
        piNftContract.ownerOf(0),
        address(pimarket),
        "Failed to put piNFT on Sale"
      );
    }

    function test_should_let_bob_buy_piNFT() public {
        test_alice_place_piNFT_on_sale();

          (
        uint256 saleId,
        address tokenContractAddress,
        uint256 tokenId,
        uint256 price,
        bool directSale,
        bool bidSale,
        bool status,
        uint256 bidStartTime,
        uint256 bidEndTime,
        address currentOwner
         ) = pimarket._tokenMeta(1);  

         assertEq(status, true, "meta status is false"); 

         alice.call{value:10 ether}(" ");
         royaltyReceiver.call{value:10 ether}(" ");
         feeReceiver.call{value:10 ether}(" ");
     
      uint256 _balance1 = alice.balance;
      uint256 _balance2 = (royaltyReceiver).balance;
      uint256 _balance3 = (feeReceiver).balance;
     

      bob.call{value:10 ether}(" ");
      vm.prank(bob);
      pimarket.BuyNFT{ value: 5000 }(saleId);
      assertEq( piNftContract.ownerOf(0), bob, "Bob is not owner");

       uint256 balance1 = alice.balance;
      uint256 balance2 = (royaltyReceiver).balance;
      uint256 balance3 = (feeReceiver).balance;

      assertEq(balance1-_balance1, (5000 * 9400) / 10000, "Failed to transfer NFT AMount");
      assertEq(balance2-_balance2, (5000 * 500) / 10000, "Failed to transfer Royalty AMount");
      assertEq(balance3-_balance3, (5000 * 100) / 10000, "Failed to transfer fee AMount");

       (,,,,,,bool stat,,,) = pimarket._tokenMeta(1);
      assertEq(stat, false);
    }

    function test_bob_place_piNFT_on_sale_again() public{
      test_should_let_bob_buy_piNFT();
      vm.prank(bob);
      piNftContract.approve(address(pimarket), 0);
      vm.prank(bob);
      pimarket.sellNFT(address(piNftContract), 0, 10000);
      assertEq(
        piNftContract.ownerOf(0),
        address(pimarket),
        "Failed to put piNFT on Sale"
      );
    }


  function test_bob_cancel_sale() public{
    test_bob_place_piNFT_on_sale_again();
    vm.prank(bob);
     pimarket.cancelSale(2);
      (,,,,,,bool stat,,,) = pimarket._tokenMeta(2);
      assertEq(stat, false, "Bob cancel sale failed");
  }

function testFail_bob_burn_piNFT() public{
    test_bob_cancel_sale();
    vm.prank(alice);
     piNftContract.burnPiNFT(0, alice, bob, address(erc20Contract), 500);
      uint256 validatorBal =  erc20Contract.balanceOf(validator);
      assertEq(piNftContract.viewBalance(0, address(erc20Contract)),
        0,
        "Failed to remove ERC20 tokens from NFT"
      );
      assertEq(
        erc20Contract.balanceOf(bob),
        500,
        "Failed to transfer ERC20 tokens to validator"
      );
      assertEq(piNftContract.ownerOf(0), alice, "NFT not transferred to alice");
  }

  function test_bob_burn_piNFT() public{
    test_bob_cancel_sale();
    vm.prank(bob);
     piNftContract.burnPiNFT(0, alice, bob, address(erc20Contract), 500);
      uint256 validatorBal =  erc20Contract.balanceOf(validator);
      assertEq(piNftContract.viewBalance(0, address(erc20Contract)),
        0,
        "Failed to remove ERC20 tokens from NFT"
      );
      assertEq(
        erc20Contract.balanceOf(bob),
        500,
        "Failed to transfer ERC20 tokens to validator"
      );
      assertEq(piNftContract.ownerOf(0), alice, "NFT not transferred to alice");
  }

  function test_create_a_piNFT_with_500_erc20_tokens_to_alice2() public{
    test_bob_burn_piNFT();
     LibShare.Share[] memory royArray ;
      LibShare.Share memory royalty;
      royalty = LibShare.Share(royaltyReceiver, uint96(500));   
      royArray= new LibShare.Share[](1);
      royArray[0] = royalty;
      string memory uri = "www.adya.com";
      erc20Contract.mint(validator, 1000);
      uint256 tokenId = piNftContract.mintNFT(alice, uri, royArray);
      assertEq(tokenId, 1, "Failed to mint or wrong token Id");
      vm.prank(validator);
      erc20Contract.approve(address(piNftContract), 500);
      vm.prank(validator);
      piNftContract.addERC20(
        validator,
        tokenId,
        address(erc20Contract),
        500
      );
  }

  function test_alice_place_piNFT_on_auction() public{
    test_create_a_piNFT_with_500_erc20_tokens_to_alice2();
    vm.prank(alice);
     piNftContract.approve(address(pimarket), 1);
     vm.prank(alice);
     pimarket.SellNFT_byBid(address(piNftContract), 1, 5000, 300);
      assertEq(
         piNftContract.ownerOf(1),
        address(pimarket),
        "Failed to put piNFT on Auction"
      );
      (,,,,,bool bidSale,,,,)= pimarket._tokenMeta(3);
      assertEq(bidSale, true);
  }

  function test_bidders_place_bid_on_piNFT() public{
    test_alice_place_piNFT_on_auction();
    bidder1.call{value:10 ether}(" ");
    bidder2.call{value:10 ether}(" ");
    vm.prank(bidder1);
    pimarket.Bid{value:6000}(3);
    vm.prank(bidder2);
    pimarket.Bid{value:6500}(3);
    vm.prank(bidder1);
    pimarket.Bid{value:7000}(3);

   ( ,,,address buyerAddress,,) = pimarket.Bids(3,2);
   assertEq(buyerAddress, bidder1, "bidding failed bidder1");

  }

  function testFail_bidders_place_bid_on_piNFT_after_auction_duration() public{
    test_alice_place_piNFT_on_auction();
    bidder1.call{value:10 ether}(" ");
    bidder2.call{value:10 ether}(" ");
    skip(301);
    vm.prank(bidder1);
    pimarket.Bid{value:6000}(3);
    vm.prank(bidder2);
    pimarket.Bid{value:6500}(3);
    vm.prank(bidder1);
    pimarket.Bid{value:7000}(3);

   ( ,,,address buyerAddress,,) = pimarket.Bids(3,2);
   assertEq(buyerAddress, bidder1, "bidding failed bidder1");
  }

  // function testFail_highest_bidder_tries_to_withdraw_his_bid() public{
  //   test_bidders_place_bid_on_piNFT();
  //   vm.prank(bidder1);
  //   pimarket.withdrawBidMoney(3, 2);
  //   uint256 result = address(pimarket).balance;
  //   assertEq(result, 12500, "Not able to withdraw bids");
  // }

  function test_alice_execute_highest_bid() public {
    test_bidders_place_bid_on_piNFT();
    uint256 _balance2 = (royaltyReceiver).balance;
    uint256 _balance3 = (feeReceiver).balance;

    vm.prank(alice);
    pimarket.executeBidOrder(3, 2);
    assertEq(piNftContract.ownerOf(1), bidder1);

    uint256 balance2 = (royaltyReceiver).balance;
    uint256 balance3 = (feeReceiver).balance;

    assertEq(
        balance2-_balance2,
        (7000 * 500) / 10000,
        "Failed to transfer royalty amount"
      );
    assertEq(
        balance3-_balance3,
        (7000 * 100) / 10000,
        "Failed to transfer royalty amount"
      );

  }

  function testFail_bob_execute_highest_bid() public {
    test_bidders_place_bid_on_piNFT();
    uint256 _balance2 = (royaltyReceiver).balance;
    uint256 _balance3 = (feeReceiver).balance;

    vm.prank(bob);
    pimarket.executeBidOrder(3, 2);
    assertEq(piNftContract.ownerOf(1), bidder1);

    uint256 balance2 = (royaltyReceiver).balance;
    uint256 balance3 = (feeReceiver).balance;

    assertEq(
        balance2-_balance2,
        (7000 * 500) / 10000,
        "Failed to transfer royalty amount"
      );
    assertEq(
        balance3-_balance3,
        (7000 * 100) / 10000,
        "Failed to transfer royalty amount"
      );

  }

  function test_other_bidders_withdraw_their_bids() public{
    test_alice_execute_highest_bid();
    vm.prank(bidder1);
    pimarket.withdrawBidMoney(3, 0);
    vm.prank(bidder2);
    pimarket.withdrawBidMoney(3, 1);
    uint256 result = address(pimarket).balance;
    assertEq(result, 0, "Not able to withdraw bids");
  }

  function testFail_other_bidders_withdraw_someone_else_bids() public{
    test_alice_execute_highest_bid();
    vm.prank(bidder2);
    pimarket.withdrawBidMoney(3, 0);
    vm.prank(bidder1);
    pimarket.withdrawBidMoney(3, 1);
    uint256 result = address(pimarket).balance;
    assertEq(result, 0, "Not able to withdraw bids");
  }

function test_bidder_redeem_piNFT() public{
  test_other_bidders_withdraw_their_bids();
  vm.prank(bidder1);
  
  piNftContract.redeemPiNFT(1, alice, validator, address(erc20Contract), 500);
      uint256 validatorBal = erc20Contract.balanceOf(validator);
      assertEq(
        piNftContract.viewBalance(1, address(erc20Contract)),
        0,
        "Failed to remove ERC20 tokens from NFT"
      );
      assertEq(
       erc20Contract.balanceOf(validator),
        1500,
        "Failed to transfer ERC20 tokens to validator"
      );
      assertEq(piNftContract.ownerOf(0), alice, "NFT not transferred to alice");
  }

  function test_cancel_sale_withdraw_bid() public{
  test_bidders_place_bid_on_piNFT();
  vm.prank(alice);
  pimarket.cancelSale(3);
  (,,,uint256 price,,,bool stat,,,) = pimarket._tokenMeta(3);
  assertEq(stat, false, "Cancel sale failed");
  vm.prank(bidder1);
  pimarket.withdrawBidMoney(3, 0);
  vm.prank(bidder2);
  pimarket.withdrawBidMoney(3, 1);
  vm.prank(bidder1);
  pimarket.withdrawBidMoney(3, 2);
  uint256 result = address(pimarket).balance;
  assertEq(result, 0, "Not able to withdraw bids");
}
function test_create_a_piNFT_with_2000_erc20_tokens_to_alice() public{
    test_cancel_sale_withdraw_bid();
     LibShare.Share[] memory royArray ;
      LibShare.Share memory royalty;
      royalty = LibShare.Share(royaltyReceiver, uint96(500));
      royArray= new LibShare.Share[](1);
      royArray[0] = royalty;
      string memory uri = "www.Adya.com";
      erc20Contract.mint(validator, 2000);
      uint256 tokenId = piNftContract.mintNFT(alice, uri, royArray);
      assertEq(tokenId, 2, "Failed to mint or wrong token Id");
      vm.prank(validator);
      erc20Contract.approve(address(piNftContract), 2000);
      vm.prank(validator);
      piNftContract.addERC20(
        validator,
        tokenId,
        address(erc20Contract),
        2000
      );
  }
  function test_create_a_piNFT_with_1000_erc20_tokens_to_bob() public{
    test_create_a_piNFT_with_2000_erc20_tokens_to_alice();
     LibShare.Share[] memory royArray ;
      LibShare.Share memory royalty;
      royalty = LibShare.Share(royaltyReceiver, uint96(500));
      royArray= new LibShare.Share[](1);
      royArray[0] = royalty;
      string memory uri = "www.adya.com";
      erc20Contract.mint(validator, 1000);
      uint256 tokenId = piNftContract.mintNFT(bob, uri, royArray);
      assertEq(tokenId, 3, "Failed to mint or wrong token Id");
      vm.prank(validator);
      erc20Contract.approve(address(piNftContract), 1000);
      vm.prank(validator);
      piNftContract.addERC20(
        validator,
        tokenId,
        address(erc20Contract),
        1000
      );
  }

}