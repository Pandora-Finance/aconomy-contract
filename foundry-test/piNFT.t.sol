// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "forge-std/console.sol";


import "contracts/piNFT.sol";
import "contracts/utils/sampleERC20.sol";
import "contracts/utils/LibShare.sol";

 contract PiNFTTest is Test {
    piNFT piNftContract;
    SampleERC20 erc20Contract;
    
    address payable alice = payable(address(0xABCD));
    address payable bob = payable(address(0xABCC));
    address payable royaltyReceiver = payable(address(0xBEEF));
    address payable validator = payable(address(0xABBB));

    function setUp() public {
        piNftContract = new piNFT("Aconomy", "ACO");
        erc20Contract = new SampleERC20();
       
    }
  
    function test_name_and_symbol() public {

    
        assertEq(piNftContract.name(), "Aconomy", "Incorrect name");
        assertEq(piNftContract.symbol(), "ACO", "Incorrect symbol");
        
    }
    function testFail_name_and_symbol() public {
        assertEq(piNftContract.name(), "Incorrect Name", "Unexpected name");
}


    function test_mint_an_erc721_token_to_alice() public returns(uint256){
     
        LibShare.Share[] memory royArray ;
        LibShare.Share memory royalty;
        royalty = LibShare.Share(royaltyReceiver, uint96(10));
        
        royArray= new LibShare.Share[](1);
        royArray[0] = royalty;
        string memory uri = "www.adya.com";
         
        uint256 tokenId = piNftContract.mintNFT(alice, uri, royArray);
        console.log(tokenId);
        assertEq(tokenId, 0,"Invalid token Id");
        assertEq(piNftContract.balanceOf(alice), 1, "Failed to mint NFT");
        return tokenId;
    }
  function testFail_mint_an_erc721_token_to_alice() public {
        

        // Trying to mint an ERC721 token to alice with an invalid URI
        LibShare.Share[] memory royArray;
        LibShare.Share memory royalty;
        royalty = LibShare.Share(royaltyReceiver, uint96(10));
        royArray = new LibShare.Share[](1);
        royArray[0] = royalty;
        string memory invalidUri = "invalid_uri";
        uint256 tokenId = piNftContract.mintNFT(alice, invalidUri, royArray);
        // assertEq(tokenId, 0, "Unexpected token ID");
        // assertEq(piNftContract.balanceOf(alice), 1, "Unexpected balance of NFTs for alice");
    }
   

function test_fetch_token_uri_and_royalties() public {
        uint256 tokenId = test_mint_an_erc721_token_to_alice();
        console.log(tokenId);
        string memory _uri = piNftContract.tokenURI(tokenId);
        assertEq(_uri, "www.adya.com", "Invalid tokenURI");

        LibShare.Share[] memory temp = piNftContract.getRoyalties(tokenId);
        console.log(temp[0].account);
        assertEq(temp[0].account, royaltyReceiver, "Incorrect Royalities Address");
        assertEq(temp[0].value, 10, "Incorrect Royalities value");
    }
    function testFail_Fetch_token_uri_and_royalties() public {
    uint256 nonExistentTokenId = 999; 
    string memory _uri = piNftContract.tokenURI(nonExistentTokenId);

    assertEq(_uri, "www.adya.com", "Unexpected token URI");

    LibShare.Share[] memory temp = piNftContract.getRoyalties(nonExistentTokenId);
    assertEq(temp[0].account, royaltyReceiver, "Unexpected Royalities Address");
    assertEq(temp[0].value, 10, "Unexpected Royalities value");
}
    
    function test_mint_ERC20_tokens_to_validator() public{
        erc20Contract.mint(validator, 1000);
        uint256 bal = erc20Contract.balanceOf(validator);
        assertEq(bal, 1000, "Failed to mint ERC20 tokens");
    }
    function testFail_mint_ERC20_tokens_to_validator() public {
       erc20Contract.mint(address(0), 1000);
    uint256 bal = erc20Contract.balanceOf(address(0));
    assertEq(bal, 0, "Unexpected ERC20 balance in address(0)");
}


 function test_validator_add_ERC20_tokens_to_alice_NFT() public{
        uint256 tokenId = test_mint_an_erc721_token_to_alice();
        test_mint_ERC20_tokens_to_validator();
    
 }
 function testFail_validator_add_ERC20_tokens_to_alice_NFT() public {
        uint256 tokenId = piNftContract.mintNFT(alice, "", new LibShare.Share[](0));
    erc20Contract.mint(validator, 1000);
    assertEq(erc20Contract.balanceOf(validator), 0, "Unexpected ERC20 balance in validator's account");
    piNftContract.safeTransferFrom(alice, bob, tokenId);
 }
 
function test_transfer_NFT_to_bob() public{
        test_validator_add_ERC20_tokens_to_alice_NFT();
        vm.prank(alice);
        piNftContract.safeTransferFrom(alice, bob, 0);
        assertEq(piNftContract.ownerOf(0), bob, "NFT is not transferred to Bob");

}
function testFail_transfer_NFT_to_bob_without_switching_to_Alice() public{
        test_validator_add_ERC20_tokens_to_alice_NFT();
        piNftContract.safeTransferFrom(alice, bob, 0);
        assertEq(piNftContract.ownerOf(0), bob, "NFT not transfer to bob");
}
  function testFail_alice_redeem_piNFT() public{
        test_transfer_NFT_to_bob();
        vm.prank(alice);
        piNftContract.redeemPiNFT(0, alice, validator, address(erc20Contract), 500);
         assertEq(
                 piNftContract.viewBalance(0, address(erc20Contract)),
                0,
                "Failed to remove ERC20 tokens from NFT"
            );
         assertEq(
            erc20Contract.balanceOf(validator),
            1000,
            "Failed to transfer ERC20 tokens to validator"
        );
        assertEq(piNftContract.ownerOf(0), alice, "NFT not transferred to alice");
    }


    function test_bob_redeem_piNFT()public{
        test_transfer_NFT_to_bob();
        vm.prank(bob);
        // piNftContract.redeemPiNFT(0, bob,validator, 
        // address(erc20Contract), 500);

        //  assertEq(
        //          piNftContract.viewBalance(0, address(erc20Contract)),
        //         0,
        //         "Failed to remove ERC20 tokens from NFT"
        //     );
        //  assertEq(
        //     erc20Contract.balanceOf(validator),
        //     1000,
        //     "Failed to transfer ERC20 tokens to validator");
    }
    function testFail_bob_redeem_piNFT() public {
  
    test_transfer_NFT_to_bob();
    piNftContract.redeemPiNFT(0, bob, validator, address(erc20Contract), 500);
    assertEq(piNftContract.ownerOf(0), bob, "Unexpected owner of NFT");
}
 }