// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "contracts/piNFT.sol";
import "contracts/NFTlendingBorrowing.sol";
import "contracts/Libraries/LibCalculations.sol";
import "contracts/utils/sampleERC20.sol";
import "contracts/AconomyFee.sol";

contract NFTlendingBoroowing is Test {
    NFTlendingBorrowing NFTlendingBorrowingContract;
    piNFT piNftContract;
    SampleERC20 erc20Contract;
    AconomyFee Charge;

    address payable alice = payable(address(0xABCC));
    address payable sam = payable(address(0xABDD));
    address payable alex = payable(address(0xABEE));
    address payable tom = payable(address(0xABFF));


    address payable bob = payable(address(0xABbb));
    address payable royaltyReceiver = payable(address(0xBEEF));
    address payable validator = payable(address(0xABBB));

    function setUp() public {
        Charge = new AconomyFee();
        NFTlendingBorrowingContract = new NFTlendingBorrowing(address(Charge));
        piNftContract = new piNFT("Aconomy", "ACO");
        erc20Contract = new SampleERC20();
    }

    function test_name_and_symbol() public {
        assertEq(piNftContract.name(), "Aconomy", "Incorrect name");
        assertEq(piNftContract.symbol(), "ACO", "Incorrect symbol");
    }

    function test_mint_an_ERC_token_to_alice() public returns (uint256) {
        LibShare.Share[] memory royArray;
        LibShare.Share memory royality;
        royality = LibShare.Share(royaltyReceiver, uint96(10));
        royArray = new LibShare.Share[](1);
        royArray[0] = royality;
        string memory uri = "www.adya.com";
        uint256 tokenId = piNftContract.mintNFT(alice, uri, royArray);
        console.log(tokenId);
        assertEq(tokenId, 0, "invalid token Id");
        assertEq(piNftContract.balanceOf(alice), 1, "failed to mint NFt");
        return tokenId;
    }

    function test_mint_ERC20_tokens_to_validator() public {
        erc20Contract.mint(validator, 1000);
        uint256 bal = erc20Contract.balanceOf(validator);
        assertEq(bal, 1000, "Failed to mint ERC20 tokens");
    }

    function test_validator_add_ERC20_tokens_to_alice_NFT() public {
        uint256 tokenId = test_mint_an_ERC_token_to_alice();
        test_mint_ERC20_tokens_to_validator();
    }

    

    function test_list_NFT_for_lending() public returns (uint256){
        uint256 tokenId = test_mint_an_ERC_token_to_alice();
        vm.prank(alice);
        uint256 NFTId = NFTlendingBorrowingContract.listNFTforBorrowing(
            tokenId,
            address(piNftContract),
            1000,
            3600,
            1200
        );
        
                return NFTId;
    }

    function test_Bid_by_bob() public {
        vm.prank(bob);
        erc20Contract.mint(bob, 2000);
        uint256 bal = erc20Contract.balanceOf(bob);
        // assertEq(bal, 1000, "Failed to mint ERC20 tokens");
        uint256 NFTId = test_list_NFT_for_lending();
        console.log("NFTId",NFTId);
        vm.prank(bob);
        erc20Contract.approve(address(NFTlendingBorrowingContract), 1001);
        vm.prank(bob);
        NFTlendingBorrowingContract.Bid(
            NFTId,
            1001,
            address(erc20Contract),
            1000,
            3600,
            3600
        );
        uint256 bal1 = erc20Contract.balanceOf(address(NFTlendingBorrowingContract));
        console.log("Bal",bal1);
    }
    function test_Bid_by_sam() public {
        vm.prank(sam);
        erc20Contract.mint(sam, 1500);
        uint256 bal = erc20Contract.balanceOf(sam);
        // assertEq(bal, 1000, "Failed to mint ERC20 tokens");
        uint256 NFTId = test_list_NFT_for_lending();
        console.log("NFTId",NFTId);
                     vm.prank(sam);

        erc20Contract.approve(address(NFTlendingBorrowingContract), 1002);
        vm.prank(sam);
        NFTlendingBorrowingContract.Bid(
            NFTId,
            1002,
            address(erc20Contract),
            1000,
            3600,
            3600
        );
        uint256 bal1 = erc20Contract.balanceOf(address(NFTlendingBorrowingContract));
        console.log("Bal",bal1);
}
function
 test_Bid_by_tom() public {
        vm.prank(tom);
        erc20Contract.mint(tom, 1200);

        uint256 bal = erc20Contract.balanceOf(tom);
        // assertEq(bal, 1000, "Failed to mint ERC20 tokens");
        uint256 NFTId = test_list_NFT_for_lending();
        console.log("NFTId",NFTId);

        vm.prank(tom);
        erc20Contract.approve(address(NFTlendingBorrowingContract), 1100);

        vm.prank(tom);
        NFTlendingBorrowingContract.Bid(
            NFTId,
            1100,
            address(erc20Contract),
            1000,
            3600,
            3600
            
        );
        uint256 bal1 = erc20Contract.balanceOf(address(NFTlendingBorrowingContract));
        console.log("Bal",bal1);
}
function test_Bid_by_alex() public {
        vm.prank(alex);
        erc20Contract.mint(alex, 1800);
                 uint256 bal = erc20Contract.balanceOf(alex);
        // assertEq(bal, 1000, "Failed to mint ERC20 tokens");
        uint256 NFTId = test_list_NFT_for_lending();
        console.log("NFTId",NFTId);
        vm.prank(alex);
                    erc20Contract.approve(address(NFTlendingBorrowingContract), 1700);

        vm.prank(alex);
        NFTlendingBorrowingContract.Bid(
            NFTId,
            1700,
            address(erc20Contract),
            1000,
            3600,
            3600
        );
        uint256 bal1 = erc20Contract.balanceOf(address(NFTlendingBorrowingContract));
        console.log("Bal",bal1);
}
function test_accept_bid() public {
    vm.prank(alice);
    uint256 NFTId=test_list_NFT_for_lending();
            console.log("NFTId",NFTId);

    vm.prank(alice);
    NFTlendingBorrowingContract.AcceptBid(NFTId,1);
    // assertEq(NFTlendingBorrowing.contractaddress(ERC721)).ownerof(1)==address(NFTlendingBorrowing);
//    assertEq(NFTlendingBorrowing.bids.withdrawn, "Already withdrawn");
//     assertEq(NFTlendingBorrowing.NFT.listed, "It's not listed for Lending");
//      assertEq(NFTlendingBorrowing.bids.bidAccepted, "Bid Already Accepted");

}
}