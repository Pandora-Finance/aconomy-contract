// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;
import "forge-std/Test.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "forge-std/console.sol";
import "contracts/piNFT.sol";
import "contracts/AconomyERC2771Context.sol";
import "contracts/utils/LibShare.sol";
import "contracts/piNFTMethods.sol";
import "contracts/utils/sampleERC20.sol";
contract piNFTTest is Test {

    piNFT piNftContract;
    piNFTMethods piNFTMethodsContract;
    AconomyERC2771Context AconomyERC2771ContextInstance;
    SampleERC20 sampleERC20;


    address payable alice = payable(address(0xABCD));
    address payable bob = payable(address(0xABCC));
    address payable adya = payable(address(0xABEE));
    address payable royaltyReceiver = payable(address(0xABED));
    address payable validator = payable(address(0xABCD));


    function testDeployandInitialize() public {
        vm.prank(alice);
        sampleERC20 = new SampleERC20();
        address implementation = address(new piNFTMethods());

        address proxy = address(new ERC1967Proxy(implementation, ""));
        
          piNFTMethodsContract = piNFTMethods(proxy);
          piNFTMethodsContract.initialize(0xBf175FCC7086b4f9bd59d5EAE8eA67b8f940DE0d);
                address implementation1 = address(new piNFT());
                // string memory name;
        // string memory symbol;
        // address piNFTMethodsAddress;
        address tfGelato = 0xBf175FCC7086b4f9bd59d5EAE8eA67b8f940DE0d;

                //  bytes memory data = abi.encodeCall(piNFT.initialize, "Aconomy","ACO",address(piNFTMethodsContract),tfGelato);
        address proxy1 = address(new ERC1967Proxy(implementation1, ""));
        
         piNftContract = piNFT(proxy1);
         piNftContract.initialize("Aconomy","ACO",address(piNFTMethodsContract),tfGelato);
         assertEq(piNftContract.name(),"Aconomy", "faiii");
         piNftContract.transferOwnership(alice);
         piNFTMethodsContract.transferOwnership(alice);

         assertEq(piNftContract.owner(),alice, "not the owner");
         assertEq(piNFTMethodsContract.owner(),alice, "Incorrect owner");
        console.log("piNFTTe111st", address(this));
        console.log("owner", piNftContract.owner());
        console.log("alice222", alice);

        // assertEq(piNftContract.name,symbol,piNFTMethodsAddress,name,symbol,piNFTMethodsAddress,tfGelato(), name,symbol,piNFTMethodsAddress,name,symbol,piNFTMethodsAddress,tfGelato);
    }

    function test_PauseAndUnpause() public {
        testDeployandInitialize();
        // Assert owner is Alice
        assertEq(piNftContract.owner(), alice, "Invalid contract owner");
                console.log("Check", alice);
        vm.prank(alice);
        piNftContract.pause();
        assertTrue(piNftContract.paused(), "Failed to pause contract");
        vm.prank(alice);
        piNftContract.unpause();
        assertFalse(piNftContract.paused(), "Failed to unpause contract");
    }


function testMintNFT() public {
    test_PauseAndUnpause();
    // piNftContract.mintNFT;
       LibShare.Share[] memory royArray ;
        LibShare.Share memory royalty;
        royalty = LibShare.Share(royaltyReceiver, uint96(10));
        
        royArray= new LibShare.Share[](1);
        royArray[0] = royalty;
        string memory uri = "www.adya.com";
         
        uint256 tokenId = piNftContract.mintNFT(alice, uri, royArray);
        // console.log(tokenId);
        console.log("tokenIdqqqqqqq",tokenId);
        assertEq(tokenId, 0,"Invalid token Id");
        assertEq(piNftContract.balanceOf(alice), 1, "Failed to mint NFT");
    }
    function testtMintNFT_bob() public {
        testMintNFT();
    // piNftContract.mintNFT;
       LibShare.Share[] memory royArray ;
        LibShare.Share memory royalty;
        royalty = LibShare.Share(royaltyReceiver, uint96(10));
        
        royArray= new LibShare.Share[](1);
        royArray[0] = royalty;
        string memory uri = "www.adya.com";
         vm.prank(bob);
        uint256 tokenId = piNftContract.mintNFT(bob, uri, royArray);
        console.log("tokenIdqqq",tokenId);
        assertEq(tokenId, 1,"Invalid token Id");
        assertEq(piNftContract.balanceOf(bob), 1, "Failed to mint NFT");
    }
    function testFail_to_mint_if_the_to_address_is_address_0() public {
        

        // Trying to mint a token to alice with an invalid URI
        LibShare.Share[] memory royArray;
        LibShare.Share memory royalty;
        royalty = LibShare.Share(royaltyReceiver, uint96(10));
        royArray = new LibShare.Share[](1);
        royArray[0] = royalty;
        string memory invalidUri = "invalid_uri";
        piNftContract.mintNFT(0x0000000000000000000000000000000000000000, invalidUri, royArray);
        assertEq(piNftContract.balanceOf(alice), 1, "Unexpected balance of NFTs for alice");
    }

    function testFail_not_allow_redeem_if_It_is_not_funded() public {
        piNftContract.approve(address(piNFTMethodsContract), 0);
        piNFTMethodsContract.redeemOrBurnPiNFT(
          address(piNftContract),
          0,
          alice,
          0x0000000000000000000000000000000000000000,
          address(sampleERC20),
          false
        );
    }

    function testFail_not_allow_burn_if_It_is_not_funded() public {
        piNftContract.approve(address(piNFTMethodsContract), 0);
        piNFTMethodsContract.redeemOrBurnPiNFT(
          address(piNftContract),
          0,
          alice,
          0x0000000000000000000000000000000000000000,
          address(sampleERC20),
          true
        );
    }

    function testFail_not_let_owner_withdraw_validator_funds_before_adding_funds() public {
        piNftContract.approve(address(piNFTMethodsContract), 0);
        piNFTMethodsContract.withdraw(
          address(piNftContract),
          0,
          address(sampleERC20),
          300
        );
    }
    //  function testfail_not_let_non_owner_setPiMarket_Address() public {
    //     vm.prank(alice);
    //   piNFTMethodsContract.setPiMarket(
    //           address(piNftContract)

    //   );
    //  }

function testFail() public {
// should check that Royality must be less 4900
LibShare.Share[] memory royArray ;
        LibShare.Share memory royalty;
        royalty = LibShare.Share(royaltyReceiver, uint96(4950));
        
        royArray= new LibShare.Share[](1);
        royArray[0] = royalty;
        string memory uri = "www.adya.com";
         
        piNftContract.mintNFT(alice, uri, royArray);
}
 function testFail_1() public {
// should check that Royality receiver isn't 0 address

LibShare.Share[] memory royArray ;
        LibShare.Share memory royalty;
        royalty = LibShare.Share(payable(0x0000000000000000000000000000000000000000), uint96(4950));
        
        royArray= new LibShare.Share[](1);
        royArray[0] = royalty;
        string memory uri = "www.adya.com";
         
        piNftContract.mintNFT(alice, uri, royArray);


 }

function testFail_should_check_that_Royality_value_is_not_0() public {

LibShare.Share[] memory royArray ;
        LibShare.Share memory royalty;
        royalty = LibShare.Share(alice, uint96(0));
        
        royArray= new LibShare.Share[](1);
        royArray[0] = royalty;
        string memory uri = "www.adya.com";
         
        piNftContract.mintNFT(alice, uri, royArray);


}



function testFail_should_not_Delete_an_ERC721_token_if_the_caller_is_not_the_owner() public {
vm.prank(bob);
piNftContract.deleteNFT(0);

}
function testFail_DeleteNFT() public {

    // not allow to delete NFT if contract is pause.

piNftContract.pause();

piNftContract.deleteNFT(1);

piNftContract.unpause();


}

function test_deleteNFT() public {
    // should Delete an ERC721 token to alice 
    testtMintNFT_bob();
vm.prank(bob);
    piNftContract.deleteNFT(1);
 uint256 bal =  piNftContract.balanceOf(bob);
  assertEq(bal,0);




}


function test_fetch_URI_and_royalities() public {
testMintNFT();
vm.prank(alice);
string memory uri = piNftContract.tokenURI(0);
assertEq(uri,"www.adya.com","invalid URI");

// LibShare.Share memory royalty;

//   royalty = piNftContract.getRoyalties(0);

}

function test_mint_ERC20_token_to_validator() public {
    test_fetch_URI_and_royalities();
vm.prank(validator);
sampleERC20.mint(validator, 1000);
      uint256 balance = sampleERC20.balanceOf(validator);
      assertEq(balance,1000,"Incorrect Balance");


}
 function testFail_mint_ERC20_token_to_validator() public {
    //   should not allow non owner to add a validator 
         vm.prank(alice);
          piNFTMethodsContract.addValidator(
            address(piNftContract), 1, address(validator));





 }

 function testFail_Pause_Unpause_piNFTMethod() public{

piNFTMethodsContract.pause();

        piNFTMethodsContract.addValidator(
          address(piNftContract),
          0,
          address(validator)
        );
      piNFTMethodsContract.unpause();

 }

function testFail_notLet_nonValidator_AddFunds_without_addingValidator_address() public {

vm.prank(alice);
 sampleERC20.approve(address(piNFTMethodsContract), 500);

 LibShare.Share[] memory royArray ;
        LibShare.Share memory royalty;
        royalty = LibShare.Share(validator, uint96(200));
        
        royArray= new LibShare.Share[](1);
        royArray[0] = royalty;

      vm.prank(validator);
        piNFTMethodsContract.addERC20(
            address(piNftContract),
            0,
            address(sampleERC20),
            500,
            500, 
            royArray
          );

}


function testFail_redeemOrBurnPiNFT() public {

// should not allow redeem if validator is 0 address 
piNftContract.approve(address(piNFTMethodsContract), 0);
    
            piNFTMethodsContract.redeemOrBurnPiNFT(
              address(piNftContract),
              0,
              address(alice),
              0x0000000000000000000000000000000000000000,
              address(sampleERC20),
              false
            );

}
function test_addValidator() public {
// allow alice to add a validator to the nft 
testMintNFT();
vm.prank(alice);
piNFTMethodsContract.addValidator(
        address(piNftContract),
        0,
        address(validator)
      );

      address valid = piNFTMethodsContract.approvedValidator(address(piNftContract), 0);
assertEq(valid,validator,"invalid validator");

}

function testFail_addValidator() public {

// should not let non validator add funds 

 vm.prank(alice);
 sampleERC20.approve(address(piNFTMethodsContract), 500);

 LibShare.Share[] memory royArray ;
        LibShare.Share memory royalty;
        royalty = LibShare.Share(validator, uint96(200));
        
        royArray= new LibShare.Share[](1);
        royArray[0] = royalty;

      vm.prank(validator);
        piNFTMethodsContract.addERC20(
            address(piNftContract),
            0,
            address(sampleERC20),
            500,
            500, 
            royArray
          );

}



    // function testLazyMintNFT() public {
    //     piNftContract.lazyMintNFT;
    //     string memory uri = "www.adya.com";
    //     LibShare.Share[] memory royalties;
    //     LibShare.Share memory royalty = LibShare.Share(royaltyReceiver, uint96(10));
    //     royalties = new LibShare.Share[](1);
    //     royalties[0] = royalty;

    //     uint256 tokenId = piNftContract.lazyMintNFT(alice, uri, royalties);

    //     assertEq(piNftContract.balanceOf(alice), 1, "Failed to mint NFT");
    //     assertEq(piNftContract.ownerOf(tokenId), alice, "Invalid owner after lazy mint");
    //     assertEq(piNftContract.tokenURI(tokenId), uri, "Invalid token URI after lazy mint");

    //     // Checking royalties
    //     LibShare.Share[] memory storedRoyalties = piNftContract.getRoyalties(tokenId);
    //     assertEq(storedRoyalties[0].account, royaltyReceiver, "Invalid royalty receiver");
    //     assertEq(storedRoyalties[0].value, uint96(10), "Invalid royalty value");
    // }
    

    // function testSetAndGetRoyalties() public {
    //     LibShare.Share[] memory royArray;
    //     LibShare.Share memory royalty = LibShare.Share(royaltyReceiver, uint96(10));

    //     royArray = new LibShare.Share[](1);
    //     royArray[0] = royalty;

    //     piNftContract.mintNFT(alice, "www.adya.com", royArray);

    //     LibShare.Share[] memory fetchedRoyalties = piNftContract.getRoyalties(0);
    //     assertEq(fetchedRoyalties.length, 1, "Invalid number of royalties");
    //     assertEq(fetchedRoyalties[0].account, royaltyReceiver, "Invalid royalty account");
    //     assertEq(fetchedRoyalties[0].value, uint96(10), "Invalid royalty value");
    // }
//     function testSetAndGetValidatorRoyalties() public {
//         LibShare.Share[] memory royArray;
//         LibShare.Share memory royalty = LibShare.Share(validator, uint96(5));

//         royArray = new LibShare.Share[](1);
//         royArray[0] = royalty;

//         piNftContract.setRoyaltiesForValidator(0, 1, royArray);

//         LibShare.Share[] memory fetchedRoyalties = piNftContract.getValidatorRoyalties(0);
//         assertEq(fetchedRoyalties.length, 1, "Invalid number of validator royalties");
//         assertEq(fetchedRoyalties[0].account, validator, "Invalid validator account");
//         assertEq(fetchedRoyalties[0].value, uint96(5), "Invalid validator royalty value");
//     }
//      function testDeleteValidatorRoyalties() public {
//         LibShare.Share[] memory royArray;
//         LibShare.Share memory royalty = LibShare.Share(validator, uint96(5));

//         royArray = new LibShare.Share[](1);
//         royArray[0] = royalty;

//         piNftContract.setRoyaltiesForValidator(0, 1, royArray);
//         piNftContract.deleteValidatorRoyalties(0);

//         LibShare.Share[] memory fetchedRoyalties = piNftContract.getValidatorRoyalties(0);
//         assertEq(fetchedRoyalties.length, 0, "Failed to delete validator royalties");
//     }
//       function testGetValidatorRoyalties() public {
//         // Mint an NFT
//        piNftContract.mintNFT;
//        LibShare.Share[] memory royArray ;
//         LibShare.Share memory royalty;
//         royalty = LibShare.Share(royaltyReceiver, uint96(10));
        
//         royArray= new LibShare.Share[](1);
//         royArray[0] = royalty;
//         string memory uri = "www.adya.com";
         
//         uint256 tokenId = piNftContract.mintNFT(alice, uri, royArray);
//         console.log(tokenId);
//         assertEq(tokenId, 0,"Invalid token Id");
//         assertEq(piNftContract.balanceOf(alice), 1, "Failed to mint NFT");
// vm.prank(alice);
//         // Get validator royalties
//         LibShare.Share[] memory receivedRoyalties = piNftContract.getValidatorRoyalties(1);
//         assertEq(receivedRoyalties.length, 1, "Incorrect number of royalties");
//         // assertEq(receivedRoyalties[0].recipient, address(this), "Incorrect recipient address");
//         assertEq(receivedRoyalties[0].value, 500, "Incorrect royalty value");
    
//       }
}