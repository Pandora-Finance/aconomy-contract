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
        string memory uri = "www.sk.com";
         
        uint256 tokenId = piNftContract.mintNFT(alice, uri, royArray);
        console.log(tokenId);
        assertEq(tokenId, 0,"Invalid token Id");
        assertEq(piNftContract.balanceOf(alice), 1, "Failed to mint NFT");
        return tokenId;
    }

 
}