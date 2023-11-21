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
function test_ValidatorChangingAfterFunding() public {
    // should not allow validator changing after funding
    test_ValidatorAdd_ERC20_toNFT();
        vm.expectRevert(bytes(""));

        piNFTMethodsContract.addValidator(
            address(collectionMethodsInstance),
             0,
            validator
        );
}
function test_DeleteNFTAfterValidatorFunding() public {
    // should not delete an ERC721 token after validator funding
    test_ValidatorChangingAfterFunding();
    vm.expectRevert(bytes(""));

    collectionMethodsInstance.deleteNFT(0);
}
function test_ValidatorAdd_Change_commission() public {
// should let validator add more ERC20 tokens to alice's NFT and change commission 
test_DeleteNFTAfterValidatorFunding();
      uint256 latestTime = block.timestamp;
        vm.warp(latestTime + 7500);
        // Now block.timestamp will return the warped time
        uint256 newTime = block.timestamp;
        // Check that the new time is indeed 3600 seconds ahead
        assertEq(newTime, latestTime + 7500);
        skip(3600);
   
    
    vm.startPrank(validator);
    sampleERC20.approve(address(piNFTMethodsContract), 200);
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
        200,
        0,
        royArray1
    );


    
    vm.stopPrank();
     uint256 tokenBalance = piNFTMethodsContract.viewBalance(address(collectionMethodsInstance),0,address(sampleERC20));
    assertEq(tokenBalance,700, "Incorrect ERC20 balance");
          uint256 validatorBal =  sampleERC20.balanceOf(validator);
              assertEq(validatorBal,300, "Incorrect validator balance");

            
    // Validate the status and commission details
      (LibShare.Share memory commission ,bool isValid) = piNFTMethodsContract.validatorCommissions(address(collectionMethodsInstance), 0);
    assertTrue(isValid, "Incorrect validator commission status");
    assertEq(commission.account, validator, "Incorrect validator account");
    assertEq(commission.value, 0, "Incorrect commission value");



}
function testFail_ValidatorAddFundsDifferentERC20() public {
    // should not let validator add funds of a different ERC20
test_ValidatorAdd_Change_commission();
     uint256 exp = block.timestamp + 10000;
        vm.warp(exp + 7501);

     LibShare.Share[] memory royArray1 ;
        LibShare.Share memory royalty1;
        royalty1 = LibShare.Share(validator, uint96(200));
        
        royArray1= new LibShare.Share[](1);
        royArray1[0] = royalty1;
            vm.expectRevert(bytes("invalid"));

    piNFTMethodsContract.addERC20(
address(collectionMethodsInstance),
        0,
        feeReceiver,
        200,
        500,
        royArray1
    );
}
function test_AliceTransferNFTtoBob() public {
    // should let Alice transfer NFT to Bob
test_ValidatorAdd_Change_commission();
vm.startPrank(alice);
    collectionMethodsInstance.safeTransferFrom(alice, bob, 0);
    assertEq(
        collectionMethodsInstance.ownerOf(0),
        bob,"incorrect owner after transfer"
    );
           vm.stopPrank();

}
function test_TransferNFTFromBobToAlice() public {
    // should let Bob transfer NFT to Alice
test_AliceTransferNFTtoBob();
vm.startPrank(bob);

    collectionMethodsInstance.safeTransferFrom(bob, alice, 0);
    assertEq(
        collectionMethodsInstance.ownerOf(0),
        alice, "Invalid owner after transfer"
    );
       vm.stopPrank();
}
function testFail_NonOwnerWithdrawValidatorFunds() public {
    // should not let non-owner withdraw validator funds
test_TransferNFTFromBobToAlice();
vm.startPrank(carl);
    vm.expectRevert(bytes("ERC721: caller is not token owner or approved"));

        piNFTMethodsContract.withdraw(
            address(collectionMethodsInstance),
            0,
            address(sampleERC20),
            300
                );
         vm.stopPrank();

}
function test_WithdrawERC20AndRepayBid() public {
    // should let Alice withdraw ERC20
    test_TransferNFTFromBobToAlice();
     vm.startPrank(alice);

  
    uint256 initialBalance = sampleERC20.balanceOf(alice);

    collectionMethodsInstance.approve(address(piNFTMethodsContract), 0);

    piNFTMethodsContract.withdraw(
        address(collectionMethodsInstance),
        0,
        address(sampleERC20),
        300
    );

    uint256 withdrawnAmount = piNFTMethodsContract.viewWithdrawnAmount(address(collectionMethodsInstance), 0);
    assertEq(withdrawnAmount, 300, "Invalid withdrawn amount");

    assertEq(collectionMethodsInstance.ownerOf(0), address(piNFTMethodsContract), "Invalid NFT owner after withdrawal");

    uint256 finalBalance = sampleERC20.balanceOf(alice);
    assertEq(finalBalance - initialBalance, 300, "Invalid ERC20 balance after withdrawal");

    piNFTMethodsContract.withdraw(
        address(collectionMethodsInstance),
        0,
        address(sampleERC20),
        200
    );

    withdrawnAmount = piNFTMethodsContract.viewWithdrawnAmount(address(collectionMethodsInstance), 0);
    assertEq(withdrawnAmount, 500, "Invalid withdrawn amount after second withdrawal");

         vm.stopPrank();

}
function test_WithdrawERC20() public {
// should let Alice withdraw ERC20
test_WithdrawERC20AndRepayBid();
     vm.startPrank(alice);
        vm.expectRevert(bytes(""));

piNFTMethodsContract.withdraw(
        address(collectionMethodsInstance),
        0,
        address(sampleERC20),
        201
    );
         vm.stopPrank();
}

function test_external_repay() public {
 // should not let external account (Bob) to repay the bid
 test_WithdrawERC20();
 vm.startPrank(bob);
    sampleERC20.approve(address(piNFTMethodsContract), 300);
    vm.expectRevert(bytes("not owner"));
        piNFTMethodsContract.Repay(
            address(collectionMethodsInstance),
            0,
            address(sampleERC20),
            300
        );
        vm.stopPrank();

        
}
function test_Repay_more() public{
// Should not let Alice repay more than what's borrowed
test_external_repay();

 vm.startPrank(alice);

sampleERC20.approve(address(piNFTMethodsContract), 800);
    vm.expectRevert(bytes(""));

    piNFTMethodsContract.Repay(
            address(collectionMethodsInstance),
            0,
            address(sampleERC20),
            800
        );
                vm.stopPrank();


}


function test_AliceRepayERC20() public {
// should let alice repay erc20 
test_Repay_more();
 vm.startPrank(alice);

    uint256 initialBalance = sampleERC20.balanceOf(alice);

    // Approve ERC20 transfer for repayment
    sampleERC20.approve(address(piNFTMethodsContract),300);

    // Repay 300 ERC20 tokens
      piNFTMethodsContract.Repay(
            address(collectionMethodsInstance),
            0,
            address(sampleERC20),
            300
        );

    // Expect NFT still owned by piNftMethods
  address   nftOwner =  collectionMethodsInstance.ownerOf(0);
    assertEq(nftOwner, address(piNFTMethodsContract), "NFT not owned by piNftMethods");

    // Check Alice's updated ERC20 balance after repayment
    uint256 updatedBalance =  sampleERC20.balanceOf(alice);
    assertEq(initialBalance - updatedBalance, 300, "Incorrect ERC20 balance after repayment");

    // Approve additional ERC20 transfer for further repayment
    sampleERC20.approve(address(piNFTMethodsContract),200);

    // Repay another 200 ERC20 tokens
    piNFTMethodsContract.Repay(
            address(collectionMethodsInstance),
            0,
            address(sampleERC20),
            200
        );

    // Expect NFT now owned by Alice
    nftOwner =  collectionMethodsInstance.ownerOf(0);
    assertEq(nftOwner, alice, "NFT not owned by Alice");

    // Check Alice's final ERC20 balance after additional repayment
    uint256 finalBalance =  sampleERC20.balanceOf(alice);
    assertEq(initialBalance - finalBalance, 500, "Incorrect final ERC20 balance");
}

function test_RedeemCollectionFactory() public {
  // should redeem CollectionFactory
  test_AliceRepayERC20();
  vm.startPrank(alice);

  // Redeem CollectionFactory NFT
  piNFTMethodsContract.redeemOrBurnPiNFT(
    address(collectionMethodsInstance),
    0,
    alice,
    0x0000000000000000000000000000000000000000,
    address(sampleERC20),
    false
  );

  // Check validator's ERC20 balance after redemption
  uint256 balance = sampleERC20.balanceOf(validator);
  assertEq(balance, 1000, "Incorrect ERC20 balance after redemption");

  // Expect NFT to be owned by Alice
  address nftOwner = collectionMethodsInstance.ownerOf(0);
  assertEq(nftOwner, alice, "NFT not owned by Alice");

  // Check NFT owner and approved validator after redemption
  address nftOwnerAfterRedemption = piNFTMethodsContract.NFTowner(
    address(collectionMethodsInstance),
    0
  );
  assertEq(nftOwnerAfterRedemption, 0x0000000000000000000000000000000000000000, "Incorrect NFT owner after redemption");

  address approvedValidatorAfterRedemption = piNFTMethodsContract.approvedValidator(
     address(collectionMethodsInstance),
    0
  );
  assertEq(approvedValidatorAfterRedemption, 0x0000000000000000000000000000000000000000, "Incorrect approved validator after redemption");

  // Check validator commission after redemption
   (LibShare.Share memory commission ,bool isValid) = piNFTMethodsContract.validatorCommissions(address(collectionMethodsInstance), 0);

    // Validate the status and commission details
    assertFalse(isValid, "Incorrect validator commission status");
    assertEq(commission.account, 0x0000000000000000000000000000000000000000, "Incorrect  account");
    assertEq(commission.value, 0, "Incorrect commission value");
  vm.stopPrank();
}

}

