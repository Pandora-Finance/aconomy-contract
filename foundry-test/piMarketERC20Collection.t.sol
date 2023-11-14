// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;
import "forge-std/Test.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "forge-std/console.sol";
import "contracts/piNFT.sol";
// import "contracts/AconomyERC2771Context.sol";
import "contracts/utils/LibShare.sol";
import "contracts/piNFTMethods.sol";
import "contracts/piMarket.sol";
import "contracts/piNFT.sol";
import "contracts/CollectionFactory.sol";
import "contracts/CollectionMethods.sol";
import "contracts/utils/LibShare.sol";
import "contracts/Libraries/LibMarket.sol";
import "contracts/AconomyFee.sol";
import "contracts/utils/sampleERC20.sol";

contract piMarketTest is Test {


    piMarket PiMarket;
    piNFT piNftContract;
    piNFTMethods piNFTMethodsContract;
    AconomyERC2771Context AconomyERC2771ContextInstance;
    SampleERC20 sampleERC20;
    CollectionFactory factory;
    AconomyFee aconomyFee;
    CollectionMethods collectionMethods;
        CollectionMethods collectionMethodsInstance;





    address payable alice = payable(address(0xABCD));
    address payable carl = payable(address(0xABEE));
    address payable bob = payable(address(0xABCC));
    address payable feeReceiver = payable(address(0xABEE));
    address payable royaltyReceiver = payable(address(0xABED));
    address payable validator = payable(address(0xABBD));
    address payable bidder1 = payable(address(0xAABD));
    address payable bidder2 = payable(address(0xABFE));
    address payable bidder3 = payable(address(0xACFE));





    function testDeployandInitialize() public {
        vm.prank(alice);
        sampleERC20 = new SampleERC20();   
        aconomyFee = new AconomyFee();

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

         

         address implementation1 = address(new piNFT());
        address tfGelato = 0xBf175FCC7086b4f9bd59d5EAE8eA67b8f940DE0d;
         address proxy1 = address(new ERC1967Proxy(implementation1, ""));
         piNftContract = piNFT(proxy1);
         piNftContract.initialize("Aconomy","ACO",address(piNFTMethodsContract),tfGelato);
         assertEq(piNftContract.name(),"Aconomy", "faiii");
         piNftContract.transferOwnership(alice);
        assertEq(piNftContract.owner(),alice, "not the owner");


         
          address piMarketimplementation = address(new piMarket());
          address piMarketproxy = address(new ERC1967Proxy(piMarketimplementation, ""));
        PiMarket = piMarket(piMarketproxy);
        PiMarket.initialize(address(aconomyFee),address(factory),address(piNFTMethodsContract));
        PiMarket.transferOwnership(alice);
         assertEq(PiMarket.owner(),alice, "Incorret owner");
         vm.prank(alice);
             piNFTMethodsContract.setPiMarket(address(PiMarket));


       
    }

    function test_CreatePrivatePiNFT() public {
    // should create a private piNFT with 500 erc20 tokens to carl
    testDeployandInitialize();
    aconomyFee.setAconomyPiMarketFee(100);
    aconomyFee.transferOwnership(feeReceiver);

    sampleERC20.mint(validator, 1000);

 // Mint NFT to carl
 vm.startPrank(alice);
    LibShare.Share[] memory royArray ;
        LibShare.Share memory royalty;
        royalty = LibShare.Share(royaltyReceiver, uint96(500));
        
        royArray= new LibShare.Share[](1);
        royArray[0] = royalty;
         
   uint256 collectionId= factory.createCollection("PANDORA", "PAN", "xyz", "xyz",royArray);
   assertEq(collectionId,1,"incorrect Id");
  




    // let meta = await factory.collections(1);
    // let address = await meta.contractAddress;
    // collectionContract = await hre.ethers.getContractAt(
    //     "CollectionMethods",
    //     address
    // );

        
        (
        ,
        ,
        ,
        address contractAddress,
        ,
        )=factory.collections(1);


        collectionMethodsInstance = CollectionMethods(contractAddress);


    




 string memory uri = "www.adya.com";
 uint256 tokenId = collectionMethodsInstance.mintNFT(carl, uri);
    assertEq(tokenId, 0, "Failed to mint NFT");


    // Validate NFT ownership
    address owner = collectionMethodsInstance.ownerOf(0);
    assertEq(owner,carl, "Ownership mismatch");

//     // Validate NFT balance of carl
    uint256 balance = collectionMethodsInstance.balanceOf(carl);
    assertEq(balance,1, "Incorrect balance");
    vm.stopPrank();

    // Add validator to NFT
        vm.startPrank(carl);

    piNFTMethodsContract.addValidator(
        address(collectionMethodsInstance),
         0,
          validator);
  // Get the current block timestamp
        uint256 currentTime = block.timestamp;
        // Warp the time ahead by 3600 seconds (1 hour)
        vm.warp(currentTime + 3600);
        // Now block.timestamp will return the warped time
        uint256 newTime = block.timestamp;
        // Check that the new time is indeed 3600 seconds ahead
        assertEq(newTime, currentTime + 3600);
   
vm.stopPrank();
 // Approve ERC20 tokens to piNftMethods
         vm.startPrank(validator);


        sampleERC20.approve(address(piNFTMethodsContract), 500);

    // Add ERC20 to NFT
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
        1000, 
        royArray1);
    vm.stopPrank();

    // View ERC20 balance
    uint256 tokenBalance = piNFTMethodsContract.viewBalance(address(collectionMethodsInstance), 0, address(sampleERC20));
    tokenBalance=500;
    assertEq(tokenBalance,500, "Incorrect ERC20 balance");

  (LibShare.Share memory commission ,bool isValid) = piNFTMethodsContract.validatorCommissions(address(collectionMethodsInstance), 0);

    // Validate the status and commission details
    assertTrue(isValid, "Incorrect validator commission status");
    assertEq(commission.account, validator, "Incorrect validator account");
    assertEq(commission.value, 1000, "Incorrect commission value");
}

function test_CarlTransferPiNFTToAlice() public {
    // should let carl transfer piNFT to alice
test_CreatePrivatePiNFT();
    // Transfer the piNFT from Carl to Alice
    vm.startPrank(carl);
    collectionMethodsInstance.safeTransferFrom(carl, alice, 0);

    // Validate the new owner of the piNFT
    assertEq(collectionMethodsInstance.ownerOf(0), alice, "Incorrect owner after transfer");
    vm.stopPrank();
}
function testFail_SellNFTWithLowPrice() public {
    // should not place NFT on sale if price < 10000
test_CarlTransferPiNFTToAlice();
    // Approve the NFT for sale
    vm.startPrank(alice);
    collectionMethodsInstance.approve(address(PiMarket), 0);

    // Attempt to put the NFT on sale with a price less than 10000
//  vm.expectRevert(bytes("PiMarket: price must be at least 10000"));
     PiMarket.sellNFT(
        address(collectionMethodsInstance), 
        0,
        100,
        address(sampleERC20)
     );
        vm.stopPrank();


}
function testFail_SellNFTWithZeroAddress() public {
    // should not place NFT on sale if contract address is 0
test_CarlTransferPiNFTToAlice();
    // Approve the NFT for sale
    vm.startPrank(alice);
    collectionMethodsInstance.approve(address(PiMarket), 0);

    // Attempt to put the NFT on sale with a zero contract address
    PiMarket.sellNFT(
       0x0000000000000000000000000000000000000000,
        0,
        50000,
        address(sampleERC20)
    );


    vm.stopPrank();
}

function test_AlicePlacesNFTOnSale() public {
    // should let Alice place piNFT on sale
test_CarlTransferPiNFTToAlice();
    vm.startPrank(alice);

    
    // Approve the NFT for sale
       

    collectionMethodsInstance.approve(address(PiMarket), 0);

    // Alice places the NFT on sale
    PiMarket.sellNFT(
        address(collectionMethodsInstance),
        0,
        50000,
        address(sampleERC20)
    );

    

        assertEq(collectionMethodsInstance.ownerOf(0), address(PiMarket), "Ownership should be transferred to the market");
           
               vm.stopPrank();
}
function testEditPriceAfterListingOnSale() public {
// "should edit the price after listing on sale 
test_AlicePlacesNFTOnSale();
    vm.prank(alice);
    PiMarket.editSalePrice(1, 60000);
    vm.prank(bob);
    vm.expectRevert(bytes("You are not the owner"));
        PiMarket.editSalePrice(1, 60000);

        


}
function testFail_EditPriceAfterListingOnSale() public {
     testEditPriceAfterListingOnSale();
    vm.prank(alice);
    PiMarket.editSalePrice(1, 60);
}

function testEdit_PriceAfterListingOnSale() public {
    testEditPriceAfterListingOnSale();
     (     ,
        ,
        ,
        uint256 InitialPrice,
        ,
        ,
        ,
        ,
        ,
        ,
        ) = PiMarket._tokenMeta(1);
    assertEq(InitialPrice, 60000, "Incorrect updated price");

    // Edit the sale price by alice
    vm.startPrank(alice);
    PiMarket.editSalePrice(1, 60000);

    // Attempt to edit the sale price by alice again
        PiMarket.editSalePrice(1, 50000);
  (     ,
        ,
        ,
        uint256 updatedPrice,
        ,
        ,
        ,
        ,
        ,
        ,
        ) = PiMarket._tokenMeta(1);

    // Get the updated price 
    assertEq(updatedPrice, 50000, "Incorrect updated price");

    vm.stopPrank();

}

function testFail_SellerCannotBuyOwnNFT() public {
    testEdit_PriceAfterListingOnSale();
// should not let seller buy their own nft
     vm.prank(alice);
        sampleERC20.approve(address(PiMarket), 50000);

        PiMarket.BuyNFT(1, true );
}
function test_BuyPiNFT() public {
    // Let Bob buy piNFT
testEdit_PriceAfterListingOnSale();
    (   ,
        ,
        ,
        ,
        ,
        ,
     bool status1,
        ,
        ,
        ,
        ) = PiMarket._tokenMeta(1);
        


        assertTrue(status1, "Incorrect piNFT status before the purchase");

 vm.startPrank(bob);
 sampleERC20.mint(bob, 50000);
    
    uint256 _balance1 =  sampleERC20.balanceOf(alice);
    uint256 _balance2 =  sampleERC20.balanceOf(royaltyReceiver);
    uint256 _balance3 =  sampleERC20.balanceOf(feeReceiver);
    uint256 _balance4 =  sampleERC20.balanceOf(validator);
                // console.log("dd",_balance4); 







   sampleERC20.approve(address(PiMarket), 50000);


    PiMarket.BuyNFT(1, true);



    // Validate piNFT ownership
    address newOwner = collectionMethodsInstance.ownerOf(0);
    assertEq(newOwner, bob, "Failed to transfer ownership to Bob");
    // vm.stopPrank();

    
    

    // // Validate new balances  
    uint256 balance1 =  sampleERC20.balanceOf(alice);
    uint256 balance2 =  sampleERC20.balanceOf(royaltyReceiver);
    uint256 balance3 =  sampleERC20.balanceOf(feeReceiver);
    uint256 balance4 =  sampleERC20.balanceOf(validator);




    
    // Check the amount received by Alice 
    uint256 aliceGotAmount = (50000 * 8200) / 10000;
    assertEq(balance1 - _balance1, aliceGotAmount, "Incorrect amount received by Alice");

    // Check the amount received by Royalty Receiver
    uint256 royaltyGotAmount = (50000 * 500) / 10000;
    assertEq(balance2 - _balance2, royaltyGotAmount, "Incorrect amount received by Royalty Receiver");

    // Check the amount received by Fee Receiver
    uint256 feeGotAmount = (50000 * 100) / 10000;
    assertEq(balance3 - _balance3, feeGotAmount, "Incorrect amount received by Fee Receiver");

    // Check the amount received by Validator
    uint256 validatorGotAmount = (50000 * 1200) / 10000;
    assertEq(balance4 - _balance4, validatorGotAmount, "Incorrect amount received by Validator");

    // // Validate  status
     (  ,
        ,
        ,
        ,
        ,
        ,
     bool status,
        ,
        ,
        ,
        ) = PiMarket._tokenMeta(1);
        assertFalse(status, "Incorrect piNFT status after the purchase");

   (LibShare.Share memory commission ,bool isValid) = piNFTMethodsContract.validatorCommissions(address(collectionMethodsInstance), 0);

//     // // Validate the status and commission details
    assertFalse(isValid, "Incorrect validator commission status");
    assertEq(commission.account, validator, "Incorrect validator account");
    assertEq(commission.value, 1000, "Incorrect commission value");
    vm.stopPrank();
}
function testWithdrawFundsFromNFT() public {
    // should let bob withdraw funds from the NFT
test_BuyPiNFT() ; 

    // Withdraw funds from the NFT by bob
    vm.startPrank(bob);
    collectionMethodsInstance.approve(address(piNFTMethodsContract), 0);

    piNFTMethodsContract.withdraw(
        address(collectionMethodsInstance),
        0,
        address(sampleERC20),
        200
    );

    // Check the ERC20 balance of bob
    vm.stopPrank();
    uint256 balance = sampleERC20.balanceOf(bob);
    assertEq(balance, 200, "Incorrect ERC20 balance for bob");

    // Check the owner of the NFT
    address owner = collectionMethodsInstance.ownerOf(0);
    assertEq(owner, address(piNFTMethodsContract), "Incorrect owner of the NFT");
    // vm.stopPrank();
}
function testWithdrawMoreFundsFromNFT() public {
    // should let bob withdraw more funds from the NFT
    testWithdrawFundsFromNFT();

    // Withdraw more funds from the NFT by bob
    vm.startPrank(bob);
    piNFTMethodsContract.withdraw(
        address(collectionMethodsInstance),
        0,
        address(sampleERC20),
        100
    );
    vm.stopPrank();

    // Check the ERC20 balance of bob
    uint256 balance = sampleERC20.balanceOf(bob);
    assertEq(balance, 300, "Incorrect ERC20 balance for bob");

    // Check the owner of the NFT
    address owner = collectionMethodsInstance.ownerOf(0);
    assertEq(owner, address(piNFTMethodsContract), "Incorrect owner of the NFT");
}
function testRepayFundsToNFT() public {
    // should let bob repay funds to the NFT
    testWithdrawMoreFundsFromNFT();

    // Repay funds to the NFT by bob
    vm.startPrank(bob);
    sampleERC20.approve(
        address(piNFTMethodsContract),
        300
    );
    piNFTMethodsContract.Repay(
        address(collectionMethodsInstance),
        0,
        address(sampleERC20),
        300
    );
    vm.stopPrank();

    // Check the ERC20 balance of bob
    uint256 balance = sampleERC20.balanceOf(bob);
    assertEq(balance, 0, "Incorrect ERC20 balance for bob");

    // Check the owner of the NFT
    address owner = collectionMethodsInstance.ownerOf(0);
    assertEq(owner, bob, "Incorrect owner of the NFT");
}
function testValidatorAddERC20AndChangeCommission() public {
    // should allow validator to add erc20 and change commission and royalties
testRepayFundsToNFT();       
    vm.startPrank(validator);
   // Approve 500 sampleERC20 tokens to piNftMethods
    sampleERC20.approve(address(piNFTMethodsContract), 500);
     block.timestamp + 7500;
        // Increase time by 3601 seconds
        vm.warp(block.timestamp + 3601);

    // Add 500 sampleERC20 tokens to piNFT with a commission of 1000 and royalties to validator
        LibShare.Share[] memory royArray1 ;
        LibShare.Share memory royalty1;
        royalty1 = LibShare.Share(validator, uint96(300));
        
        royArray1= new LibShare.Share[](1);
        royArray1[0] = royalty1;
    piNFTMethodsContract.addERC20(
        address(collectionMethodsInstance), 
        0, 
        address(sampleERC20),
         500, 
         100,
          royArray1);

(LibShare.Share memory commission ,bool isValid) = piNFTMethodsContract.validatorCommissions(address(collectionMethodsInstance), 0);

    // Validate the status and commission details
    assertFalse(isValid, "Incorrect validator commission status");
    assertEq(commission.account, validator, "Incorrect validator account");
    assertEq(commission.value, 100, "Incorrect commission value");

        
}
function testBobPlaceNFTOnSaleAgain() public {
    // should let bob place piNFT on sale 
    testValidatorAddERC20AndChangeCommission();
    vm.startPrank(bob);

    // Approve NFT for sale by bob
    collectionMethodsInstance.approve(address(PiMarket), 0);

    // Place piNFT on sale again by bob
    PiMarket.sellNFT(
        address(collectionMethodsInstance),
        0,
        50000,
        address(sampleERC20)
    );
    vm.stopPrank();

    // Check the ownership of piNFT after placing it on sale
    address owner = collectionMethodsInstance.ownerOf(0);
    assertEq(owner, address(PiMarket), "Incorrect owner after placing NFT on sale");
}

function testAliceBuyPiNFT() public {
    // should let alice buy piNFT
    testBobPlaceNFTOnSaleAgain();

 (   ,
        ,
        ,
        ,
        ,
     ,
     bool status,
        ,
        ,
        ,
        ) = PiMarket._tokenMeta(2);

        assertTrue(status, "Incorrect piNFT status before the purchase");

        // Get initial balances
    
    uint256 _balance1 =  sampleERC20.balanceOf(bob);
    uint256 _balance2 =  sampleERC20.balanceOf(royaltyReceiver);
    uint256 _balance3 =  sampleERC20.balanceOf(feeReceiver);
    uint256 _balance4 =  sampleERC20.balanceOf(validator);


    vm.startPrank(alice);
         sampleERC20.mint(alice, 50000);

           sampleERC20.approve(address(PiMarket), 50000);

        


    // Alice buys piNFT
     PiMarket.BuyNFT(2, true);



    // Validate piNFT ownership
    address newOwner = collectionMethodsInstance.ownerOf(0);
    assertEq(newOwner, alice, "Failed to transfer ownership to alice");
    // Check the balances after the transaction
    uint256 balance1 =  sampleERC20.balanceOf(bob);
    uint256 balance2 =  sampleERC20.balanceOf(royaltyReceiver);
    uint256 balance3 =  sampleERC20.balanceOf(feeReceiver);
    uint256 balance4 =  sampleERC20.balanceOf(validator);


     // Check the amount received by bob
    uint256 bobGotAmount = (50000 * 9100) / 10000;
    assertEq(balance1 - _balance1, bobGotAmount, "Incorrect amount received by bob");

    // Check the amount received by Royalty Receiver
    uint256 royaltyGotAmount = (50000 * 500) / 10000;
    assertEq(balance2 - _balance2, royaltyGotAmount, "Incorrect amount received by Royalty Receiver");

    // Check the amount received by Fee Receiver
    uint256 feeGotAmount = (50000 * 100) / 10000;
    assertEq(balance3 - _balance3, feeGotAmount, "Incorrect amount received by Fee Receiver");

    // Check the amount received by Validator
    uint256 validatorGotAmount = (50000 * 300) / 10000;
    assertEq(balance4 - _balance4, validatorGotAmount, "Incorrect amount received by Validator");


    (  ,
        ,
        ,
        ,
        ,
        ,
     bool status1,
        ,
        ,
        ,
        ) = PiMarket._tokenMeta(1);
        assertFalse(status1, "Incorrect piNFT status after the purchase");

        (LibShare.Share memory commission ,bool isValid) = piNFTMethodsContract.validatorCommissions(address(collectionMethodsInstance), 0);

    // Validate the status and commission details
    assertFalse(isValid, "Incorrect validator commission status");
    assertEq(commission.account, validator, "Incorrect validator account");
    assertEq(commission.value, 100, "Incorrect commission value");
            vm.stopPrank();

vm.prank(alice);
 collectionMethodsInstance.safeTransferFrom(alice,bob,0);

}
function test_BobPlaceNFT_OnSale_Again() public {
    // should let bob place piNFT on sale again
    testAliceBuyPiNFT();
        vm.startPrank(bob);

    // testValidatorAddERC20AndChangeCommission();
    collectionMethodsInstance.approve(address(PiMarket), 0);
    PiMarket.sellNFT(
        address(collectionMethodsInstance),
        0,
        10000,
        address(sampleERC20)
    );

    // Check the ownership of piNFT after placing it on sale
    address owner = collectionMethodsInstance.ownerOf(0);
    assertEq(owner, address(PiMarket), "Incorrect owner after placing NFT on sale");

     vm.stopPrank();
}
function testFail_CancelSaleNonOwner() public {
    // should not let non owner cancel sale
 test_BobPlaceNFT_OnSale_Again();
     vm.prank(alice);

    // Attempt to cancel the sale by non-owner
    PiMarket.cancelSale(3);
}
function test_BobCancelSale() public {
    // should let bob cancel sale
 test_BobPlaceNFT_OnSale_Again();
    vm.startPrank(bob);

    // Cancel the sale by bob
    PiMarket.cancelSale(3);
    
    // Check the status after canceling the sale
 (  ,
        ,
        ,
        ,
        ,
        ,
     bool status,
        ,
        ,
        ,
        ) = PiMarket._tokenMeta(3); 
      assertFalse(status, "Incorrect sale status after cancellation");
        vm.stopPrank();

}
function testBobRedeemPiNFT() public {
    // should let bob redeem piNFT
    test_BobCancelSale();
    vm.startPrank(bob);

    // Approve piNFT for redemption by bob
    collectionMethodsInstance.approve(address(piNFTMethodsContract), 0);

    // Redeem piNFT by bob
    piNFTMethodsContract.redeemOrBurnPiNFT(
        address(collectionMethodsInstance),
        0,
        address(alice),
        0x0000000000000000000000000000000000000000,
        address(sampleERC20),
        false
    );

    // Validate balances and ownership after redemption
    assertEq(piNFTMethodsContract.viewBalance(
        address(collectionMethodsInstance),
        0,
        address(sampleERC20)
    ), 0, "Incorrect balance after redemption");

    assertEq(sampleERC20.balanceOf(address(validator)), 8500, "Incorrect validator balance after redemption");

    address owner = collectionMethodsInstance.ownerOf(0);
    assertEq(owner, address(alice), "Incorrect owner after redemption");



   (LibShare.Share memory commission ,bool isValid) = piNFTMethodsContract.validatorCommissions(address(collectionMethodsInstance), 0);

    // Validate the status and commission details
    assertFalse(isValid, "Incorrect validator commission status");
    assertEq(commission.account, 0x0000000000000000000000000000000000000000, "Incorrect validator account");
    assertEq(commission.value, 0, "Incorrect commission value");

    vm.stopPrank();
}

//  describe("Auction sale") 
function testCreatePiNFTWithTokensToAlice() public {
// should create a piNFT with 500 erc20 tokens to alice 
    testBobRedeemPiNFT();


    vm.startPrank(alice);
    sampleERC20.mint(validator, 1000);

    // Mint a piNFT to Alice with URI "URI2" 

    uint256 tokenId = collectionMethodsInstance.mintNFT(alice, "URI2");
    address owner = collectionMethodsInstance.ownerOf(tokenId);
    assertEq(owner,alice, "inValid owner");
    uint256 bal = collectionMethodsInstance.balanceOf(alice);
    assertEq(bal, 2, "Incorrect balance after minting");

        
 
    // Add validator to piNFT
    piNFTMethodsContract.addValidator(
        address(collectionMethodsInstance),
     1,
      validator);
      vm.stopPrank();

    // // Approve ERC20 tokens to piNftMethods
     vm.prank(validator);
    sampleERC20.approve(address(piNFTMethodsContract), 500);
      skip(3601);




       vm.startPrank(validator);

            LibShare.Share[] memory royArray1 ;
        LibShare.Share memory royalty1;
        royalty1 = LibShare.Share(validator, uint96(200));
        
        royArray1= new LibShare.Share[](1);
        royArray1[0] = royalty1;


    piNFTMethodsContract.addERC20(
        address(collectionMethodsInstance), 
        1, 
        address(sampleERC20),
         500, 
         1000,
          royArray1);
   

     vm.stopPrank();


   (LibShare.Share memory commission ,bool isValid) = piNFTMethodsContract.validatorCommissions(address(collectionMethodsInstance), 1);

    // Validate the status and commission details
    assertTrue(isValid, "Incorrect validator commission status");
    assertEq(commission.account, validator, "Incorrect validator account");
    assertEq(commission.value, 1000, "Incorrect commission value");
}

function testFail_PlaceNFTOnAuctionWithLowPrice() public {
// should not place nft on auction if price < 10000 
testCreatePiNFTWithTokensToAlice();
    // Approve the NFT for auction
    vm.startPrank(alice);
    collectionMethodsInstance.approve(address(PiMarket), 1);

    // Attempt to place the NFT on auction with a price less than 10000
    PiMarket.SellNFT_byBid(
        address(collectionMethodsInstance), 
        1,
        100,
        300,
        address(sampleERC20)
    );
    vm.stopPrank();
}
function testFail_PlaceNFTOnAuctionWithZeroAddress() public {
    // should not place nft on auction if contract address is 0
testCreatePiNFTWithTokensToAlice();
    // Approve the NFT for auction
    vm.startPrank(alice);
    collectionMethodsInstance.approve(address(PiMarket), 1);

    // Attempt to place the NFT on auction with a contract address of 0

    PiMarket.SellNFT_byBid(
        0x0000000000000000000000000000000000000000,
        1,
        50000,
        300,
        address(sampleERC20)
    );
    vm.stopPrank();
}
function testFail_PlaceNFTOnAuctionWithZeroAuctionTime() public {
    // should not place nft on auction if auction time is 0
testCreatePiNFTWithTokensToAlice();

    // Approve the NFT for auction
    vm.startPrank(alice);
    collectionMethodsInstance.approve(address(PiMarket), 1);

    // Attempt to place the NFT on auction with an auction time of 0
    PiMarket.SellNFT_byBid(
        address(collectionMethodsInstance), 
        1,
        50000,
        0,
        address(sampleERC20)
    );
    vm.stopPrank();
}
function testAllowValidatorToAddERC20AndChangeCommission() public {
    // should allow validator to add erc20 and change commission and royalties
testCreatePiNFTWithTokensToAlice();
       
    vm.startPrank(validator);
   // Approve 500 sampleERC20 tokens to piNftMethods
    sampleERC20.approve(address(piNFTMethodsContract), 500);
     block.timestamp + 7500;
        // Increase time by 3601 seconds
        vm.warp(block.timestamp + 3601);

    // Add 500 sampleERC20 tokens to piNFT with a commission of 1000 and royalties to validator
        LibShare.Share[] memory royArray1 ;
        LibShare.Share memory royalty1;
        royalty1 = LibShare.Share(validator, uint96(300));
        
        royArray1= new LibShare.Share[](1);
        royArray1[0] = royalty1;
    piNFTMethodsContract.addERC20(
        address(collectionMethodsInstance), 
        1, 
        address(sampleERC20),
         500, 
         100,
          royArray1);

(LibShare.Share memory commission ,bool isValid) = piNFTMethodsContract.validatorCommissions(address(collectionMethodsInstance), 1);

    // Validate the status and commission details
    assertTrue(isValid, "Incorrect validator commission status");
    assertEq(commission.account, validator, "Incorrect validator account");
    assertEq(commission.value, 100, "Incorrect commission value");

        
}
}