// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "forge-std/console.sol";


import "contracts/piNFT.sol";
import "contracts/utils/sampleERC20.sol";
import "contracts/utils/LibShare.sol";

 contract ContractTest is Test {
    piNFT piNftContract;
    SampleERC20 erc20Contract;
    
    address payable alice = payable(address(0xABCD));
    address payable royaltyReceiver = payable(address(0xBEEF));

    function setUp() public {
        piNftContract = new piNFT("Aconomy", "ACO");
        erc20Contract = new SampleERC20();
       
    }
  
    function testNameAndSymbol() public {
        // //  emit log_address(address(this));
        //  console.log(address(piNftContract));
        assertEq(piNftContract.name(), "Aconomy");
        assertEq(piNftContract.symbol(), "ACO");
        //  console.log(alice);
        // assertEq(cont.viewBalance(1, address(0xEb5a964C7B3ebB6F6100D433De8BD223c121d804)), 0);
    }

    function testMintAnErc721TokenToAlice() public{
     
        LibShare.Share[] memory royArray ;
        LibShare.Share memory royalty;
        royalty = LibShare.Share(royaltyReceiver, uint96(10));
        
        royArray= new LibShare.Share[](1);
        royArray[0] = royalty;
        string memory uri = "www.sk.com";
         
        uint256 tokenId = piNftContract.mintNFT(alice, uri, royArray);
        console.log(tokenId);
        assertEq(tokenId, 0,"Failed minting Right NFT");
        assertEq(piNftContract.balanceOf(alice), 1, "Failed to mint");
    }

    function testFetchTheTokenURIAndRoyalties() public {
        LibShare.Share[] memory royArray ;
        LibShare.Share memory royalty;
        royalty = LibShare.Share(royaltyReceiver, uint96(10));
        
        royArray= new LibShare.Share[](1);
        royArray[0] = royalty;
        string memory uri = "www.sk.com";
        uint256 tokenId = piNftContract.mintNFT(alice, uri, royArray);
        string memory _uri = piNftContract.tokenURI(tokenId);
        assertEq(_uri, "www.sk.com", "Invalid URI for the token");

        LibShare.Share[] memory temp = piNftContract.getRoyalties(tokenId);
        console.log(temp[0].account);
        assertEq(temp[0].account, royaltyReceiver, "Wrong Royalities");
        assertEq(temp[0].value, 10, "Wrong Royalities");
    }

}