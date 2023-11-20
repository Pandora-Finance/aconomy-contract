// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;
import "forge-std/Test.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "forge-std/console.sol";
import "contracts/piNFT.sol";
// import "contracts/AconomyERC2771Context.sol";
import "contracts/utils/LibShare.sol";
import "contracts/Libraries/LibCollection.sol";
import "contracts/CollectionFactory.sol";
import "contracts/CollectionMethods.sol";
import "contracts/piNFTMethods.sol";
import "contracts/utils/sampleERC20.sol";

contract collectionFactoryTest is Test {


    piNFTMethods piNFTMethodsContract;
    SampleERC20 sampleERC20;
    CollectionFactory factory;
    CollectionMethods collectionMethods;
    CollectionMethods collectionMethodsInstance;





    address payable alice = payable(address(0xABCD));
    address payable carl = payable(address(0xABEE));
    address payable bob = payable(address(0xABCC));
    address payable feeReceiver = payable(address(0xABEE));
    address payable royaltyReceiver = payable(address(0xABED));
    address payable validator = payable(address(0xABBD));

 function testDeployandInitialize() public {
        vm.prank(alice);
        sampleERC20 = new SampleERC20();   

        address implementation = address(new piNFTMethods());

        address proxy = address(new ERC1967Proxy(implementation, ""));
        
          piNFTMethodsContract = piNFTMethods(proxy);
          piNFTMethodsContract.initialize(0xBf175FCC7086b4f9bd59d5EAE8eA67b8f940DE0d);
               
         piNFTMethodsContract.transferOwnership(alice);
           collectionMethods = new CollectionMethods();
        collectionMethods.initialize(address(factory),alice,"Aconomy","ACO");



         address CollectionFactoryimplementation = address(new CollectionFactory());
         address CollectionFactoryproxy = address(new ERC1967Proxy(CollectionFactoryimplementation, ""));
        factory = CollectionFactory(CollectionFactoryproxy);
        factory.initialize(address(collectionMethods),address(piNFTMethodsContract));
        factory.transferOwnership(alice);
         assertEq(factory.owner(),alice, "Incorret owner");
        // console.log("owner", factory.owner());


         

        
       
    }
function test_DeployContracts() public {
    // should deploy the contracts
    testDeployandInitialize();
        vm.startPrank(alice);

     factory.pause();
    
    LibShare.Share[] memory royArray ;
        LibShare.Share memory royalty;
        royalty = LibShare.Share(royaltyReceiver, uint96(500));
        
        royArray= new LibShare.Share[](1);
        royArray[0] = royalty;
        vm.expectRevert(bytes("Pausable: paused")); 
   
   factory.createCollection("PANDORA", "PAN", "xyz", "xyz",royArray);
   vm.stopPrank();
      // Unpause the CollectionFactory
        vm.prank(alice);

    factory.unpause();
}

function test_PauseNFTMethodsNonOwner() public {
    // should not allow non owner to pause Un-pause piNFTMethods
    test_DeployContracts();
            vm.startPrank(royaltyReceiver);

    vm.expectRevert(bytes("Ownable: caller is not the owner"));
    factory.pause();
       vm.stopPrank();


    // Pause the CollectionFactory 
    vm.prank(alice);
    factory.pause();

    // Assert that non-owner cannot unpause
    vm.startPrank(royaltyReceiver);
    vm.expectRevert(bytes("Ownable: caller is not the owner"));
    factory.unpause();
           vm.stopPrank();


    // Unpause the CollectionFactory
    vm.prank(alice);

    factory.unpause();
}
function test_CheckRoyaltyReceiverNotZeroAddress() public {
    // should check Royalty receiver isn't 0 address
    test_PauseNFTMethodsNonOwner();
    vm.expectRevert(bytes("Royalty recipient should be present"));
    LibShare.Share[] memory royArray ;
        LibShare.Share memory royalty;
        royalty = LibShare.Share(payable(0x0000000000000000000000000000000000000000), uint96(4901));
        
        royArray= new LibShare.Share[](1);
        royArray[0] = royalty;
    factory.createCollection("PANDORA", "PAN", "xyz", "xyz", royArray);
}
function test_CheckRoyalty_Value() public {
// should check that Royality must be less 4900 
    test_CheckRoyaltyReceiverNotZeroAddress();
    vm.expectRevert(bytes("Sum of Royalties > 49%"));
    LibShare.Share[] memory royArray ;
        LibShare.Share memory royalty;
        royalty = LibShare.Share(payable(royaltyReceiver), uint96(4901));
        
        royArray= new LibShare.Share[](1);
        royArray[0] = royalty;
    factory.createCollection("PANDORA", "PAN", "xyz", "xyz", royArray);
}
function test_royality_length_should_be_ten() public {
    // "should check that Royality length must be less than 10" 
    test_CheckRoyalty_Value();


LibShare.Share[] memory royArray;
royArray = new LibShare.Share[](11); 
for (uint i = 0; i < 11; i++) {
    royArray[i] = LibShare.Share(payable(alice), uint96(100));
}
    vm.expectRevert(bytes("Atmost 10 royalties can be added"));

factory.createCollection("PANDORA", "PAN", "xyz", "xyz", royArray);

}
function test_Check_Royalty_Value() public {
// should check that Royality value isn't 0 
test_royality_length_should_be_ten();
    vm.expectRevert(bytes("Royalty value should be > 0"));
    LibShare.Share[] memory royArray ;
        LibShare.Share memory royalty;
        royalty = LibShare.Share(royaltyReceiver, uint96(0));
        
        royArray= new LibShare.Share[](1);
        royArray[0] = royalty;
    factory.createCollection("PANDORA", "PAN", "xyz", "xyz", royArray);
}

function testDeployingCollectionsWithCollectionFactory() public {
    test_Check_Royalty_Value();
    vm.startPrank(alice);
    LibShare.Share[] memory royArray ;
        LibShare.Share memory royalty;
        royalty = LibShare.Share(royaltyReceiver, uint96(500));
        
        royArray= new LibShare.Share[](1);
        royArray[0] = royalty;
   uint256 collectionId = factory.createCollection("PANDORA", "PAN", "xyz", "xyz", royArray);
      assertEq(collectionId,1,"incorrect ID");

    // Step 2: Retrieve the address of the newly created collection
 ( ,
       ,
       ,
       address contractAddress,
       ,
        )=factory.collections(1);
// address collectionAddress = meta.contractAddress;
    // Step 3: Deploy the LibShare contract (if not already deployed in setUp)
    // LibShare libShare = new LibShare();
    // collectionMethods collectionMethods = CollectionMethods(collectionAddress);
    vm.stopPrank();

    
}
function test_SetRoyaltiesByNonOwner() public {
    // should not allow royalties to be set by non-owner
    testDeployingCollectionsWithCollectionFactory();
    vm.startPrank(royaltyReceiver);
    vm.expectRevert(bytes("Not the owner"));
     LibShare.Share[] memory royArray ;
        LibShare.Share memory royalty;
        royalty = LibShare.Share(royaltyReceiver, uint96(500));
        
        royArray= new LibShare.Share[](1);
        royArray[0] = royalty;
    factory.setRoyaltiesForCollection(1,royArray);
    vm.stopPrank();
}
function test_SetRoyaltiesWhenPaused() public {
    // should not allow royalties to be set when contract is paused
    test_SetRoyaltiesByNonOwner();
    vm.prank(alice);
    factory.pause();

    vm.expectRevert(bytes("Pausable: paused"));
    LibShare.Share[] memory royArray ;
        LibShare.Share memory royalty;
        royalty = LibShare.Share(royaltyReceiver, uint96(500));
        
        royArray= new LibShare.Share[](1);
        royArray[0] = royalty;
    factory.setRoyaltiesForCollection(1,royArray);
        
        vm.prank(alice);
        factory.unpause();
}
function test_SetURIByNonOwner() public {
    // should not allow URI to be set by non owner
    test_SetRoyaltiesWhenPaused();
        vm.prank(royaltyReceiver);

    vm.expectRevert(bytes("Not the owner"));
    factory.setCollectionURI(1, "XYZ");
}
function test_SetURIWhenPaused() public {
    // should not allow URI to be set when contract is paused
    test_SetURIByNonOwner();
    vm.startPrank(alice);
    factory.pause();

    vm.expectRevert(bytes("Pausable: paused"));
    factory.setCollectionURI(1, "XYZ");

    factory.unpause();
        vm.stopPrank();

}
function test_ChangeURI() public {
    // should change the URI
    test_SetURIWhenPaused();
        vm.startPrank(alice);

    ( ,
       ,
        string memory URI,
       ,
       ,
        )=factory.collections(1);
        URI= "xyz";
        assertEq(URI,"xyz","invalid URI");
    factory.setCollectionURI(1, "SRS");
( ,
       ,
        string memory newURI,
       ,
       ,
        )=factory.collections(1);
            assertEq(newURI, "SRS", "URI not changed successfully");
                    vm.stopPrank();

}
function test_SetSymbolNonOwner() public {
    // should not allow symbol to be set by non-owner
    test_ChangeURI();

            vm.startPrank(royaltyReceiver);
    vm.expectRevert(bytes("Not the owner"));
    factory.setCollectionSymbol(1, "XYZ");

            vm.stopPrank();

}
function test_SetSymbolWhenPaused() public {
    // should not allow symbol to be set when contract is paused
    test_SetSymbolNonOwner();
    vm.startPrank(alice);
    factory.pause();
      vm.expectRevert(bytes("Pausable: paused"));
    factory.setCollectionSymbol(1, "XYZ");
    factory.unpause();
    vm.stopPrank();
}


function test_ChangeCollectionSymbol() public {
    // should change the Collection Symbol

    test_SetSymbolWhenPaused();
        vm.startPrank(alice);

    ( ,
       string memory symbol,
        ,
       ,
       ,
        )=factory.collections(1);
        assertEq(symbol, "PAN", "invalid symbol");

    factory.setCollectionSymbol(1, "PNDR");
    ( ,
       string memory newSymbol,
        ,
       ,
       ,
        )=factory.collections(1);
        assertEq(newSymbol, "PNDR", "incorrect symbol");
            vm.stopPrank();

}
function test_SetName_NonOwner() public {
// should not allow name to be set by non owner 
    test_ChangeCollectionSymbol();
        vm.startPrank(royaltyReceiver);

    vm.expectRevert(bytes("Not the owner"));
    factory.setCollectionName(1, "XYZ");
        vm.stopPrank();

}
function test_SetNameContractPaused() public {
    // should not allow name to be set when contract is paused
    test_SetName_NonOwner();
    vm.startPrank(alice);
    factory.pause();
      vm.expectRevert(bytes("Pausable: paused"));
     factory.setCollectionName(1, "XYZ");
    factory.unpause();
    vm.stopPrank();
}
function test_ChangeCollectionName() public {
    // should change the Collection Name
test_SetNameContractPaused();
    vm.startPrank(alice);
      ( string memory name,
       ,
        ,
       ,
       ,
        )=factory.collections(1);
        assertEq(name, "PANDORA", "invalid name");

    factory.setCollectionName(1, "Pan");
   
    ( string memory NewName,
       ,
        ,
       ,
       ,
        )=factory.collections(1);
        assertEq(NewName, "Pan", "incorrect name");
            vm.stopPrank();

}
function test_SetDescriptionNonOwner() public {
    // should not allow description to be set by non owner
    test_ChangeCollectionName();

    vm.startPrank(royaltyReceiver);
        vm.expectRevert(bytes("Not the owner"));
    factory.setCollectionDescription(1, "XYZ");
    vm.stopPrank();
}

function test_SetDescriptionContractPaused() public {
    // should not allow description to be set when contract is paused
    test_SetDescriptionNonOwner();

    vm.startPrank(alice);
    factory.pause();
    vm.expectRevert(bytes("Pausable: paused"));
    factory.setCollectionDescription(1, "XYZ");
    factory.unpause();
    vm.stopPrank();
}
function test_ChangeCollectionDescription() public {
    // should change the Collection Description
    test_SetDescriptionContractPaused();
        vm.startPrank(alice);


     (,
      ,
      ,
      ,
      ,
    string memory description
 ) = factory.collections(1);

    assertEq(description, "xyz", "invalid description");

    factory.setCollectionDescription(1, "I am Token");

    ( ,
      ,
      ,
      ,
      ,
    string memory newDescription
 ) = factory.collections(1);

    assertEq(newDescription, "I am Token", "incorrect description");
        vm.stopPrank();

}
function testFail_ToMintNonOwner() public {
    // should fail to mint if the caller is not the collection owner
test_ChangeCollectionDescription();
    vm.startPrank(bob);
 // Attempt to mint from a non-owner account
collectionMethods.mintNFT(bob, "xyz");
    vm.stopPrank();

}

function testFail_ToMintToZeroAddress() public {
    // should fail to mint if the to address is address 0
test_ChangeCollectionDescription();

    // Attempt to mint to address 0
   
        collectionMethods.mintNFT(
            0x0000000000000000000000000000000000000000,
            "xyz"
        );
}
function test_MintERC721TokenToAlice() public {
    // should mint an ERC721 token to alice
test_ChangeCollectionDescription();
        vm.startPrank(alice);



    // Mint an ERC721 token to alice with URI "URI1"
   
   


  
        (
        ,
        ,
        ,
        address contractAddress,
        ,
        )=factory.collections(1);



       collectionMethodsInstance = CollectionMethods(contractAddress);




 string memory uri = "www.adya.com";
 uint256 tokenId = collectionMethodsInstance.mintNFT(alice, uri);
    assertEq(tokenId, 0, "Failed to mint NFT");
     // Check balance of alice after minting
        uint256 bal = collectionMethodsInstance.balanceOf(alice);
       assertEq(bal,1,"incorrect balamce after minting");
           vm.stopPrank();


}
function test_Mint_ERC721TokenToAlice() public {
    // should mint an ERC721 token to alice
test_MintERC721TokenToAlice();
        vm.startPrank(alice);



    // Mint an ERC721 token to alice with URI "URI1"
   
   


  
        (
        ,
        ,
        ,
        address contractAddress,
        ,
        )=factory.collections(1);



       collectionMethodsInstance = CollectionMethods(contractAddress);




 string memory uri = "www.adya.com";
 uint256 tokenId = collectionMethodsInstance.mintNFT(alice, uri);
    assertEq(tokenId, 1, "Failed to mint NFT");
     // Check balance of alice after minting
        uint256 bal = collectionMethodsInstance.balanceOf(alice);
       assertEq(bal,2,"incorrect balamce after minting");
    vm.stopPrank();

}
function testFail_DeleteIfCallerNotOwner() public {
    // should not delete an ERC721 token if the caller isn't the owner
    test_Mint_ERC721TokenToAlice();
            vm.startPrank(bob);

    

    // Attempt to delete an ERC721 token by bob, expect revert
    collectionMethodsInstance.deleteNFT(1);
        vm.stopPrank();

}
// function testTokenURIAndRoyalties() public {
//         test_Mint_ERC721TokenToAlice();

//         // Arrange
//         string memory expectedURI = "URI1";
//         uint256 expectedRoyalty = 500;
//         string memory uri = collectionMethodsInstance.tokenURI(0);
//         (address receiver, uint256 royaltyAmount) = factory.getCollectionRoyalties(1);
//         // Assert
//         assertEq(uri, expectedURI);
//         assertEq(receiver, royaltyReceiver);
//         assertEq(royaltyAmount, expectedRoyalty);
//     }
function test_MintERC20TokensToValidator() public {
    // should mint ERC20 tokens to validator
        test_Mint_ERC721TokenToAlice();

    sampleERC20.mint(validator, 1000);
    uint256 balance = sampleERC20.balanceOf(validator);
    assertEq(balance, 1000, "Invalid ERC20 balance for validator");
}
function test_ShouldNotAllowNonOwnerToAddValidator() public {
    // "should not allow non owner to add a validator 
    test_MintERC20TokensToValidator();
    

    vm.startPrank(bob);
    vm.expectRevert(bytes(""));
    piNFTMethodsContract.addValidator(address(collectionMethodsInstance), 0, validator);
    vm.stopPrank();

}
function test_ShouldAllowAliceToAddValidatorToTheNFT() public {
    // should allow alice to add a validator to the nft 
     test_ShouldNotAllowNonOwnerToAddValidator();
        vm.startPrank(alice);

   
    piNFTMethodsContract.addValidator(address(collectionMethodsInstance), 0, validator);

    address approvedValidator = piNFTMethodsContract.approvedValidator(address(collectionMethodsInstance), 0);
    assertEq(approvedValidator, validator);
        vm.stopPrank();

}
function testShouldNotLetNonValidatorAddFunds() public {
    // should not let non validator add funds 
     test_ShouldAllowAliceToAddValidatorToTheNFT();
    // Set an expiration time for the transaction
    // Warp the time ahead by 3600 seconds (1 hour)
      uint256 latestTime = block.timestamp;
        vm.warp(latestTime + 3600);
        // Now block.timestamp will return the warped time
        uint256 newTime = block.timestamp;
        // Check that the new time is indeed 3600 seconds ahead
        assertEq(newTime, latestTime + 3600);
   
    
    // Set an expiration time for the transaction
    // Simulate Alice approving the ERC20 transfer
    vm.startPrank(alice);
    sampleERC20.approve(address(piNFTMethodsContract), 500);
    vm.stopPrank();

    // Try to add ERC20 funds with Alice, expecting it to revert
    vm.startPrank(alice);
    vm.expectRevert(bytes(""));
    LibShare.Share[] memory royArray1 ;
        LibShare.Share memory royalty1;
        royalty1 = LibShare.Share(validator, uint96(200));
        
        royArray1= new LibShare.Share[](1);
        royArray1[0] = royalty1;
    piNFTMethodsContract.addERC20(
address(collectionMethodsInstance),
        0,
        address(sampleERC20),
        500,
        500,
        royArray1
    );
    vm.stopPrank();
}


function test_ShouldNot_ERC20_zero() public {
// should not let erc20 contract be address 0 

testShouldNotLetNonValidatorAddFunds();
    // Set an expiration time for the transaction
    // Warp the time ahead by 3600 seconds (1 hour)
      uint256 latestTime = block.timestamp;
        vm.warp(latestTime + 3600);
        // Now block.timestamp will return the warped time
        uint256 newTime = block.timestamp;
        // Check that the new time is indeed 3600 seconds ahead
        assertEq(newTime, latestTime + 3600);
   
    
    // Set an expiration time for the transaction
    // Simulate Alice approving the ERC20 transfer
    vm.startPrank(validator);
    sampleERC20.approve(address(piNFTMethodsContract), 500);
    vm.stopPrank();

    // Try to add ERC20 funds with Alice, expecting it to revert
    vm.startPrank(validator);
    vm.expectRevert(bytes(""));
    LibShare.Share[] memory royArray1 ;
        LibShare.Share memory royalty1;
        royalty1 = LibShare.Share(validator, uint96(200));
        
        royArray1= new LibShare.Share[](1);
        royArray1[0] = royalty1;
    piNFTMethodsContract.addERC20(
address(collectionMethodsInstance),
        0,
        0x0000000000000000000000000000000000000000,
        500,
        500,
        royArray1
    );
    vm.stopPrank();
}
function test_Validator_Funds_zero() public {
    // should not let non validator add funds 
test_ShouldNot_ERC20_zero();
    // Set an expiration time for the transaction
    // Warp the time ahead by 3600 seconds (1 hour)
      uint256 latestTime = block.timestamp;
        vm.warp(latestTime + 3600);
        // Now block.timestamp will return the warped time
        uint256 newTime = block.timestamp;
        // Check that the new time is indeed 3600 seconds ahead
        assertEq(newTime, latestTime + 3600);
   
    
    // Set an expiration time for the transaction
    // Simulate Alice approving the ERC20 transfer
    vm.startPrank(validator);
    sampleERC20.approve(address(piNFTMethodsContract), 500);
    vm.stopPrank();

    // Try to add ERC20 funds with Alice, expecting it to revert
    vm.startPrank(validator);
    vm.expectRevert(bytes(""));
    LibShare.Share[] memory royArray1 ;
        LibShare.Share memory royalty1;
        royalty1 = LibShare.Share(validator, uint96(200));
        
        royArray1= new LibShare.Share[](1);
        royArray1[0] = royalty1;
    piNFTMethodsContract.addERC20(
address(collectionMethodsInstance),
        0,
        address(sampleERC20),
        0,
        500,
        royArray1
    );
    vm.stopPrank();
}
function test_Validator_commission() public {
// should not let validator commission value be 4901 
test_Validator_Funds_zero();
    // Set an expiration time for the transaction
    // Warp the time ahead by 3600 seconds (1 hour)
      uint256 latestTime = block.timestamp;
        vm.warp(latestTime + 3600);
        // Now block.timestamp will return the warped time
        uint256 newTime = block.timestamp;
        // Check that the new time is indeed 3600 seconds ahead
        assertEq(newTime, latestTime + 3600);
   
    
    vm.startPrank(validator);
    sampleERC20.approve(address(piNFTMethodsContract), 500);
    vm.stopPrank();

    // Try to add ERC20 funds with validator, expecting it to revert
    vm.startPrank(validator);
    vm.expectRevert(bytes(""));
    LibShare.Share[] memory royArray1 ;
        LibShare.Share memory royalty1;
        royalty1 = LibShare.Share(validator, uint96(200));
        
        royArray1= new LibShare.Share[](1);
        royArray1[0] = royalty1;
    piNFTMethodsContract.addERC20(
address(collectionMethodsInstance),
        0,
        address(sampleERC20),
        500,
        4901,
        royArray1
    );
    vm.stopPrank();
}
function test_Check_validator_Royalties_strength() public {

// should not let validator royalties have more than 10 addresses 
test_Validator_commission();
 // Warp the time ahead by 3600 seconds (1 hour)
      uint256 latestTime = block.timestamp;
        vm.warp(latestTime + 3600);
        // Now block.timestamp will return the warped time
        uint256 newTime = block.timestamp;
        // Check that the new time is indeed 3600 seconds ahead
        assertEq(newTime, latestTime + 3600);
   
 
    vm.startPrank(validator);
    sampleERC20.approve(address(piNFTMethodsContract), 500);
    vm.stopPrank();

    vm.startPrank(validator);
        vm.expectRevert(bytes(""));

LibShare.Share[] memory royArray;
royArray = new LibShare.Share[](11); 
for (uint i = 0; i < 11; i++) {
    royArray[i] = LibShare.Share(validator, uint96(100));
}
     piNFTMethodsContract.addERC20(
address(collectionMethodsInstance),
        0,
        address(sampleERC20),
        500,
        500,
        royArray
    );
    vm.stopPrank();

}

function test_ValidatorRoyality_zero() public {
// should not let validator royalties value be 0 
test_Check_validator_Royalties_strength();
    // Set an expiration time for the transaction
    // Warp the time ahead by 3600 seconds (1 hour)
      uint256 latestTime = block.timestamp;
        vm.warp(latestTime + 3600);
        // Now block.timestamp will return the warped time
        uint256 newTime = block.timestamp;
        // Check that the new time is indeed 3600 seconds ahead
        assertEq(newTime, latestTime + 3600);
   
    
    vm.startPrank(validator);
    sampleERC20.approve(address(piNFTMethodsContract), 500);
    vm.stopPrank();

    // Try to add ERC20 funds with validator, expecting it to revert
    vm.startPrank(validator);
    vm.expectRevert(bytes("Royalty 0"));
    LibShare.Share[] memory royArray1 ;
        LibShare.Share memory royalty1;
        royalty1 = LibShare.Share(validator, uint96(0));
        
        royArray1= new LibShare.Share[](1);
        royArray1[0] = royalty1;
    piNFTMethodsContract.addERC20(
address(collectionMethodsInstance),
        0,
        address(sampleERC20),
        500,
        500,
        royArray1
    );
    vm.stopPrank();
}

function test_ValidatorRoyality_address() public {
// should not let validator royalties address be 0 
test_ValidatorRoyality_zero();
    // Set an expiration time for the transaction
    // Warp the time ahead by 3600 seconds (1 hour)
      uint256 latestTime = block.timestamp;
        vm.warp(latestTime + 3600);
        // Now block.timestamp will return the warped time
        uint256 newTime = block.timestamp;
        // Check that the new time is indeed 3600 seconds ahead
        assertEq(newTime, latestTime + 3600);
   
    
    vm.startPrank(validator);
    sampleERC20.approve(address(piNFTMethodsContract), 500);
    vm.stopPrank();

    // Try to add ERC20 funds with validator, expecting it to revert
    vm.startPrank(validator);
    vm.expectRevert(bytes(""));
    LibShare.Share[] memory royArray1 ;
        LibShare.Share memory royalty1;
        royalty1 = LibShare.Share(payable(0x0000000000000000000000000000000000000000), uint96(100));
        
        royArray1= new LibShare.Share[](1);
        royArray1[0] = royalty1;
    piNFTMethodsContract.addERC20(
address(collectionMethodsInstance),
        0,
        address(sampleERC20),
        500,
        500,
        royArray1
    );
    vm.stopPrank();
}
function test_Check_ValidatorRoyality_4901() public {
// should not let validator royalties be greater than 4901 
test_ValidatorRoyality_address();
    // Set an expiration time for the transaction
    // Warp the time ahead by 3600 seconds (1 hour)
      uint256 latestTime = block.timestamp;
        vm.warp(latestTime + 3600);
        // Now block.timestamp will return the warped time
        uint256 newTime = block.timestamp;
        // Check that the new time is indeed 3600 seconds ahead
        assertEq(newTime, latestTime + 3600);
   
    
    vm.startPrank(validator);
    sampleERC20.approve(address(piNFTMethodsContract), 500);
    vm.stopPrank();

    // Try to add ERC20 funds with validator, expecting it to revert
    vm.startPrank(validator);
    vm.expectRevert(bytes("overflow"));
    LibShare.Share[] memory royArray1 ;
        LibShare.Share memory royalty1;
        royalty1 = LibShare.Share(validator, uint96(4901));
        
        royArray1= new LibShare.Share[](1);
        royArray1[0] = royalty1;
    piNFTMethodsContract.addERC20(
address(collectionMethodsInstance),
        0,
        address(sampleERC20),
        500,
        500,
        royArray1
    );
    vm.stopPrank();
}

function test_ValidatorAdd_ERC20_toNFT() public {
// should let validator add ERC20 tokens to alice's NFT 
test_Check_ValidatorRoyality_4901();
    // Set an expiration time for the transaction
    // Warp the time ahead by 3600 seconds (1 hour)
      uint256 latestTime = block.timestamp;
        vm.warp(latestTime + 3600);
        // Now block.timestamp will return the warped time
        uint256 newTime = block.timestamp;
        // Check that the new time is indeed 3600 seconds ahead
        assertEq(newTime, latestTime + 3600);
   
    
    vm.startPrank(validator);
    sampleERC20.approve(address(piNFTMethodsContract), 500);
    vm.stopPrank();

    // Try to add ERC20 funds with validator, expecting it to revert
    vm.startPrank(validator);
    LibShare.Share[] memory royArray1 ;
        LibShare.Share memory royalty1;
        royalty1 = LibShare.Share(validator, uint96(500));
        
        royArray1= new LibShare.Share[](1);
        royArray1[0] = royalty1;
    piNFTMethodsContract.addERC20(
address(collectionMethodsInstance),
        0,
        address(sampleERC20),
        500,
        500,
        royArray1
    );
    vm.stopPrank();
     uint256 tokenBalance = piNFTMethodsContract.viewBalance(address(collectionMethodsInstance),0,address(sampleERC20));
    assertEq(tokenBalance,500, "Incorrect ERC20 balance");
          uint256 validatorBal =  sampleERC20.balanceOf(validator);
              assertEq(validatorBal,500, "Incorrect validator balance");

            
    // Validate the status and commission details
      (LibShare.Share memory commission ,bool isValid) = piNFTMethodsContract.validatorCommissions(address(collectionMethodsInstance), 0);
    assertTrue(isValid, "Incorrect validator commission status");
    assertEq(commission.account, validator, "Incorrect validator account");
    assertEq(commission.value, 500, "Incorrect commission value");



}
}

