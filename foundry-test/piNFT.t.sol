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

    function test_mint_ERC20_tokens_to_validator() public{
        erc20Contract.mint(validator, 1000);
        uint256 bal = erc20Contract.balanceOf(validator);
        assertEq(bal, 1000, "Failed to mint ERC20 tokens");
    }
 
}