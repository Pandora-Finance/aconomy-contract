// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;
import "forge-std/Test.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "forge-std/console.sol";
import "contracts/piNFT.sol";
import "contracts/AconomyERC2771Context.sol";
import "contracts/utils/LibShare.sol";
import "contracts/piNFTMethods.sol";
contract piNFTTest is Test {

    piNFT piNftContract;
    piNFTMethods PiNFTMethods;
    AconomyERC2771Context AconomyERC2771ContextInstance;


    address payable alice = payable(address(0xABCD));
    address payable bob = payable(address(0xABCC));
    address payable adya = payable(address(0xABEE));

function testDeployAndInitialize() public {
                address implementation = address(new piNFTMethods());

                 bytes memory data = abi.encodeCall(piNFT.initialize, "0xBf175FCC7086b4f9bd59d5EAE8eA67b8f940DE0d");
        address proxy = address(new ERC1967Proxy(implementation, data));
        
         piNFTMethods PiNFTMethods = piNFTMethods(proxy);
        // assertEq(piNFTMethods.trustedForwarder(),trustedForwarder);
    }

    function testDeployandInitialize() public {
                address implementation = address(new piNFT());
                // string memory name;
        // string memory symbol;
        // address piNFTMethodsAddress;
        address tfGelato = 0xBf175FCC7086b4f9bd59d5EAE8eA67b8f940DE0d;

                 bytes memory data = abi.encodeCall(piNFT.initialize, "Aconomy","ACO",address(PiNFTMethods),tfGelato);
        address proxy = address(new ERC1967Proxy(implementation, data));
        
        piNFT piNftContract = piNFT(proxy);
        // assertEq(piNftContract.name,symbol,piNFTMethodsAddress,name,symbol,piNFTMethodsAddress,tfGelato(), name,symbol,piNFTMethodsAddress,name,symbol,piNFTMethodsAddress,tfGelato);
    }


function setUp() public {
        piNftContract = new piNFT();
        PiNFTMethods = new piNFTMethods();
        AconomyERC2771ContextInstance = new AconomyERC2771Context();
    }

    function testPauseAndUnpause() public {      
        address _owner = piNftContract.owner();
        console.log("owner",_owner);
        // assertTrue(piNftContract.paused(), "Contract should be paused initially");
        vm.prank(alice);
assertEq(alice,_owner,"not the owner");
        piNftContract.pause();
        assertTrue(piNftContract.paused(), "Failed to unpause contract");

        piNftContract.pause();
        assertTrue(piNftContract.paused(), "Failed to pause contract");
    }

function testMintNFT() public {
    piNftContract.mintNFT;
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
    }
    function testtMintNFT_bob() public {
    piNftContract.mintNFT;
       LibShare.Share[] memory royArray ;
        LibShare.Share memory royalty;
        royalty = LibShare.Share(royaltyReceiver, uint96(10));
        
        royArray= new LibShare.Share[](1);
        royArray[0] = royalty;
        string memory uri = "www.adya.com";
         
        uint256 tokenId = piNftContract.mintNFT(bob, uri, royArray);
        console.log(tokenId);
        assertEq(tokenId, 0,"Invalid token Id");
        assertEq(piNftContract.balanceOf(bob), 1, "Failed to mint NFT");
    }
    function testFailMintNFT() public {
        

        // Trying to mint a token to alice with an invalid URI
        LibShare.Share[] memory royArray;
        LibShare.Share memory royalty;
        royalty = LibShare.Share(royaltyReceiver, uint96(10));
        royArray = new LibShare.Share[](1);
        royArray[0] = royalty;
        string memory invalidUri = "invalid_uri";
        uint256 tokenId = piNftContract.mintNFT(alice, invalidUri, royArray);
        assertEq(tokenId, 0, "Unexpected token ID");
        assertEq(piNftContract.balanceOf(alice), 1, "Unexpected balance of NFTs for alice");
    }
    function testLazyMintNFT() public {
        piNftContract.lazyMintNFT;
        string memory uri = "www.adya.com";
        LibShare.Share[] memory royalties;
        LibShare.Share memory royalty = LibShare.Share(royaltyReceiver, uint96(10));
        royalties = new LibShare.Share[](1);
        royalties[0] = royalty;

        uint256 tokenId = piNftContract.lazyMintNFT(alice, uri, royalties);

        assertEq(piNftContract.balanceOf(alice), 1, "Failed to mint NFT");
        assertEq(piNftContract.ownerOf(tokenId), alice, "Invalid owner after lazy mint");
        assertEq(piNftContract.tokenURI(tokenId), uri, "Invalid token URI after lazy mint");

        // Checking royalties
        LibShare.Share[] memory storedRoyalties = piNftContract.getRoyalties(tokenId);
        assertEq(storedRoyalties[0].account, royaltyReceiver, "Invalid royalty receiver");
        assertEq(storedRoyalties[0].value, uint96(10), "Invalid royalty value");
    }
    

    function testSetAndGetRoyalties() public {
        LibShare.Share[] memory royArray;
        LibShare.Share memory royalty = LibShare.Share(royaltyReceiver, uint96(10));

        royArray = new LibShare.Share[](1);
        royArray[0] = royalty;

        piNftContract.mintNFT(alice, "www.adya.com", royArray);

        LibShare.Share[] memory fetchedRoyalties = piNftContract.getRoyalties(0);
        assertEq(fetchedRoyalties.length, 1, "Invalid number of royalties");
        assertEq(fetchedRoyalties[0].account, royaltyReceiver, "Invalid royalty account");
        assertEq(fetchedRoyalties[0].value, uint96(10), "Invalid royalty value");
    }
    function testSetAndGetValidatorRoyalties() public {
        LibShare.Share[] memory royArray;
        LibShare.Share memory royalty = LibShare.Share(validator, uint96(5));

        royArray = new LibShare.Share[](1);
        royArray[0] = royalty;

        piNftContract.setRoyaltiesForValidator(0, 1, royArray);

        LibShare.Share[] memory fetchedRoyalties = piNftContract.getValidatorRoyalties(0);
        assertEq(fetchedRoyalties.length, 1, "Invalid number of validator royalties");
        assertEq(fetchedRoyalties[0].account, validator, "Invalid validator account");
        assertEq(fetchedRoyalties[0].value, uint96(5), "Invalid validator royalty value");
    }
     function testDeleteValidatorRoyalties() public {
        LibShare.Share[] memory royArray;
        LibShare.Share memory royalty = LibShare.Share(validator, uint96(5));

        royArray = new LibShare.Share[](1);
        royArray[0] = royalty;

        piNftContract.setRoyaltiesForValidator(0, 1, royArray);
        piNftContract.deleteValidatorRoyalties(0);

        LibShare.Share[] memory fetchedRoyalties = piNftContract.getValidatorRoyalties(0);
        assertEq(fetchedRoyalties.length, 0, "Failed to delete validator royalties");
    }
      function testGetValidatorRoyalties() public {
        // Mint an NFT
       piNftContract.mintNFT;
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
vm.prank(alice);
        // Get validator royalties
        LibShare.Share[] memory receivedRoyalties = piNftContract.getValidatorRoyalties(1);
        assertEq(receivedRoyalties.length, 1, "Incorrect number of royalties");
        // assertEq(receivedRoyalties[0].recipient, address(this), "Incorrect recipient address");
        assertEq(receivedRoyalties[0].value, 500, "Incorrect royalty value");
    
      }
}