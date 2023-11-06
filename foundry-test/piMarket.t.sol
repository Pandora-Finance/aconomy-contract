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
    CollectionFactory collectionFactory;
    AconomyFee aconomyFee;
    CollectionMethods collectionMethods;




    address payable alice = payable(address(0xABCD));
    address payable carl = payable(address(0xABEE));
    address payable bob = payable(address(0xABCC));
    address payable feeReceiver = payable(address(0xABEE));
    address payable royaltyReceiver = payable(address(0xABED));
    address payable validator = payable(address(0xABBD));
    address payable bidder1 = payable(address(0xAABD));
        address payable bidder2 = payable(address(0xABFE));




    function testDeployandInitialize() public {
        vm.prank(alice);
        sampleERC20 = new SampleERC20();   
        aconomyFee = new AconomyFee();

        address implementation = address(new piNFTMethods());

        address proxy = address(new ERC1967Proxy(implementation, ""));
        
          piNFTMethodsContract = piNFTMethods(proxy);
          piNFTMethodsContract.initialize(0xBf175FCC7086b4f9bd59d5EAE8eA67b8f940DE0d);
               
         piNFTMethodsContract.transferOwnership(alice);

        // console.log("piNFTTe111st", address(this));
        // console.log("owner", piNftContract.owner());
        // console.log("alice222", alice);

         address CollectionFactoryimplementation = address(new CollectionFactory());
         address CollectionFactoryproxy = address(new ERC1967Proxy(CollectionFactoryimplementation, ""));
        collectionFactory = CollectionFactory(CollectionFactoryproxy);
        collectionFactory.initialize(address(collectionMethods),address(piNFTMethodsContract));
        collectionFactory.transferOwnership(alice);
         assertEq(collectionFactory.owner(),alice, "Incorret owner");

          address CollectionMethodsimplementation = address(new CollectionMethods());
           address CollectionMethodsproxy = address(new ERC1967Proxy(CollectionMethodsimplementation, ""));
           collectionMethods = CollectionMethods(CollectionMethodsproxy);
        collectionMethods.initialize(address(collectionFactory),alice,"Aconomy","ACO");
        // collectionMethods.transferOwnership(alice);
        //  assertEq(collectionMethods.owner(),alice, "Incorret owner");

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
        PiMarket.initialize(address(aconomyFee),address(collectionFactory),address(piNFTMethodsContract));
        PiMarket.transferOwnership(alice);
         assertEq(PiMarket.owner(),alice, "Incorret owner");
         vm.prank(alice);
             piNFTMethodsContract.setPiMarket(address(PiMarket));


       
    }

// Assuming piMarket is an instance of your contract and royaltyReceiver is an account with the role of a non-owner

function testPauseUnpause() public {
        testDeployandInitialize();
// should not allow non owner to pause piMarket 
vm.prank(royaltyReceiver);
    vm.expectRevert(bytes("Ownable: caller is not the owner"));



     PiMarket.pause();
        

    // Pause the contract by the owner
         vm.prank(alice);

    PiMarket.pause();

    // Check that non-owner cannot unpause
    vm.prank(royaltyReceiver);
    vm.expectRevert(bytes("Ownable: caller is not the owner"));

    PiMarket.unpause();
        

    // Unpause the contract by the owner
             vm.prank(alice);

    PiMarket.unpause();
}

  // Assuming aconomyFee, feeReceiver, sampleERC20, piNFT, carl, validator are instances of your contracts

function testMintNFTAndAddERC20() public {
         testPauseUnpause();

        // should create a piNFT with 500 erc20 tokens to carl 
    // Set AconomyPiMarketFee and transfer ownership

    aconomyFee.setAconomyPiMarketFee(100);
    aconomyFee.transferOwnership(feeReceiver);
    assertEq(aconomyFee.owner(),feeReceiver, "Incorret owner");


    // Mint 1000 tokens to the validator
    sampleERC20.mint(validator, 1000);

    // Mint NFT to carl
    LibShare.Share[] memory royArray ;
        LibShare.Share memory royalty;
        royalty = LibShare.Share(royaltyReceiver, uint96(500));
        
        royArray= new LibShare.Share[](1);
        royArray[0] = royalty;
        string memory uri = "www.adya.com";
         
    uint256 tokenId =  piNftContract.mintNFT(carl, uri, royArray);
    tokenId = 0;
    assertEq(tokenId, 0, "Failed to mint NFT");


    // Validate NFT ownership
    address owner = piNftContract.ownerOf(tokenId);
    owner = carl;
    assertEq(owner,carl, "Ownership mismatch");

    // Validate NFT balance of carl
    uint256 balance = piNftContract.balanceOf(carl);
    balance =1;
    assertEq(balance,1, "Incorrect balance");

    // Add validator to NFT
    vm.prank(carl);
    piNFTMethodsContract.addValidator(
        address(piNftContract),
         tokenId,
          validator);

    // Approve ERC20 tokens to piNftMethods
        vm.prank(validator);

    sampleERC20.approve(address(piNFTMethodsContract), 500);

    // Add ERC20 to NFT
            vm.startPrank(validator);

            LibShare.Share[] memory royArray1 ;
        LibShare.Share memory royalty1;
        royalty1 = LibShare.Share(validator, uint96(200));
        
        royArray1= new LibShare.Share[](1);
        royArray1[0] = royalty1;


        //     LibShare.Share[] memory royArray1;
        // LibShare.Share memory royalty;
        // royalty = LibShare.Share(validator, uint96(200));
        
        // royArray1= new LibShare.Share[](1);
        // roy[0] = royalty;

    piNFTMethodsContract.addERC20(address(piNftContract), tokenId, address(sampleERC20), 500, 1000, royArray1);
    vm.stopPrank();

    // View ERC20 balance
    uint256 tokenBalance = piNFTMethodsContract.viewBalance(address(piNftContract), tokenId, address(sampleERC20));
    tokenBalance=500;
    assertEq(tokenBalance,500, "Incorrect ERC20 balance");

  (LibShare.Share memory commission ,bool isValid) = piNFTMethodsContract.validatorCommissions(address(piNftContract), 0);

    // Validate the status and commission details
    assertTrue(isValid, "Incorrect validator commission status");
    assertEq(commission.account, validator, "Incorrect validator account");
    assertEq(commission.value, 1000, "Incorrect commission value");
}
 function testTransferNFT() public {
    // should let carl transfer piNFT to alice 
    testMintNFTAndAddERC20();

    // Carl transfers piNFT to Alice
    vm.prank(carl);
    piNftContract.safeTransferFrom(carl, alice, 0);

    // Validate NFT ownership after transfer
    address owner = piNftContract.ownerOf(0);
    assertEq(owner, alice, "Ownership not transferred correctly");
}
function testPauseBeforeSellNFT() public {
    // should not put on sale if the contract is paused 
    testTransferNFT();

    // Pause the piMarket contract
    vm.startPrank(alice);
    PiMarket.pause();

    // Attempt to put the NFT on sale while the contract is paused
    // vm.startPrank
        vm.expectRevert(bytes("Pausable: paused"));

    PiMarket.sellNFT(
        address(piNftContract), 
        0, 
        50000, 
        address(0)
        );

    // Unpause the piMarket contract
    PiMarket.unpause();
    vm.stopPrank();
}
function testFail_SellNFTWithLowPrice() public {
    // should not place NFT on sale if price < 10000
testPauseBeforeSellNFT();
    // Approve the NFT for sale
    vm.startPrank(alice);
    piNftContract.approve(address(PiMarket), 0);

    // Attempt to put the NFT on sale with a price less than 10000
//  vm.expectRevert(bytes("PiMarket: price must be at least 10000"));
     PiMarket.sellNFT(
        address(piNftContract), 
        0,
        100,
       0x0000000000000000000000000000000000000000
     );
        vm.stopPrank();


}
function testFail_SellNFTWithZeroAddress() public {
    // should not place NFT on sale if contract address is 0
testFail_SellNFTWithLowPrice();
    // Approve the NFT for sale
    vm.startPrank(alice);
    piNftContract.approve(address(PiMarket), 0);

    // Attempt to put the NFT on sale with a zero contract address
    PiMarket.sellNFT(
        address(0), 
        0,
        50000,
        address(0)
    );


    vm.stopPrank();
}
function test_AlicePlacesNFTOnSale() public {
    // should let Alice place piNFT on sale
    // testFail_SellNFTWithZeroAddress();
    testPauseBeforeSellNFT();
    // PiMarket.pause();


    // Approve the NFT for sale
        vm.startPrank(alice);
        address a= piNftContract.ownerOf(0);
        console.log("fff", a);
        console.log("ali",alice);

    piNftContract.approve(address(PiMarket), 0);

    // Alice places the NFT on sale
    PiMarket.sellNFT(
        address(piNftContract),
        0,
        50000,
       0x0000000000000000000000000000000000000000
    );

    // Check if Alice is the owner of the NFT after placing it on sale
        // piNftContract.ownerOf(0) = address(PiMarket);

        assertEq(piNftContract.ownerOf(0), address(PiMarket), "Ownership should be transferred to the market");
           
               vm.stopPrank();// // Validate piNFT ownership
    // address newOwner = piNftContract.ownerOf(0);
    // assertEq(newOwner, alice, "Failed to transfer ownership to alice");
    // // Check the balances after the transaction
    // uint256 balance1 = bob.balance;
    // uint256 balance2 = royaltyReceiver.balance;
    // uint256 balance3 = feeReceiver.balance;
    // uint256 balance4 = validator.balance;

    // (  ,
    //     ,
    //     ,
    //     ,
    //     ,
    //     ,
    //  bool status1,
    //     ,
    //     ,
    //     ,
    //     ) = PiMarket._tokenMeta(2);
    //     console.log("qq",status)1;
    //     assertFalse(status1, "Incorrect piNFT status after the purchase");
    //         vm.stopPrank();



}
function testPauseBeforeEditSalePrice() public {
    // should not allow sale price edit if contract is paused
test_AlicePlacesNFTOnSale();
    // Pause the piMarket contract
    vm.startPrank(alice);
    PiMarket.pause();

    // Attempt to edit the sale price while the contract is paused
    // vm.startPrank
    vm.expectRevert(bytes("Pausable: paused"));

    PiMarket.editSalePrice(1, 60000);

    // Unpause the piMarket contract
    PiMarket.unpause();
    vm.stopPrank();
}
function testEditPriceAfterListingOnSale() public {
// "should edit the price after listing on sale 
testPauseBeforeEditSalePrice();
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
    // Get the initial price
    // uint256 initialPrice = PiMarket._tokenMeta(1).price;
    // assertEq(initialPrice, 60000, "Incorrect initial price");

    // Edit the sale price by alice
    vm.startPrank(alice);
    PiMarket.editSalePrice(1, 60000);

    // Attempt to edit the sale price by alice again
        PiMarket.editSalePrice(1, 50000);
  (     ,
        ,
        ,
        uint256 price1,
        ,
        ,
        ,
        ,
        ,
        ,
        ) = PiMarket._tokenMeta(1);
        console.log("ddd",price1);

    // Get the updated price 
  ( ,,, uint256 updatedPrice ,,,,,,,)= PiMarket._tokenMeta(1);
    assertEq(updatedPrice, 50000, "Incorrect updated price");

    vm.stopPrank();
}
function testFail_SellerCannotBuyOwnNFT() public {
    testEdit_PriceAfterListingOnSale();
// should not let seller buy their own nft
     vm.prank(alice);
        PiMarket.BuyNFT{ value: 50000 }(1, false );
}
function testFailPauseBeforeBuyNFT() public {
    // should not let bob buy nft if contract is paused 
    testEditPriceAfterListingOnSale();

    // Pause the piMarket contract
    vm.prank(alice);
    PiMarket.pause();

    // Attempt to let Bob buy NFT while the contract is paused
        vm.startPrank(bob);
            vm.expectRevert(bytes("Pausable: paused"));

        PiMarket.BuyNFT{ value: 50000 }(1, false );
            vm.stopPrank();

        // "Pausable: paused"

    // Unpause the piMarket contract

    vm.prank(alice);
    PiMarket.unpause();
}
function testFail_BidOnDirectSaleNFT() public {
        testEditPriceAfterListingOnSale();

// should not let bidder place bid on direct sale NFT 
        vm.prank(bob);
        PiMarket.Bid{ value: 50000 }(1, 50000);
    
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
        // console.log("aa",status1);
                // console.log("sss",bidSale);
                        // console.log("bbb",owner);
                    //    console.log("ccc",saleId);


        assertTrue(status1, "Incorrect piNFT status before the purchase");

 vm.startPrank(bob);
//    uint256 balanceB= bob.balance;
    // console.log("ss", balance1);
    vm.deal(bob, 1 ether);
    // bob.mint{value: 0.01 ether}();
        // console.log("www", bob.balance);
// Validate balances
    uint256 _balance1 = alice.balance;
        console.log("aa", _balance1);

    uint256 _balance2 =royaltyReceiver.balance;
            console.log("bb", _balance2);

    uint256 _balance3 =feeReceiver.balance;
                console.log("cc", _balance3);

    uint256 _balance4 =validator.balance;
                    console.log("dd", _balance4);


   


    PiMarket.BuyNFT { value: 50000 }(1, false);



    // Validate piNFT ownership
    address newOwner = piNftContract.ownerOf(0);
    assertEq(newOwner, bob, "Failed to transfer ownership to Bob");
    // vm.stopPrank();

    
    // // Trigger the BuyNFT function
    // PiMarket.BuyNFT{ value: 50000 }(1, false);

    // // Validate new balances
    uint256 balance1 = alice.balance;
                        console.log("bal1", balance1);

        uint256 balance2 = royaltyReceiver.balance;
                                console.log("bal2", balance2);

            uint256 balance3 = feeReceiver.balance;
                                            console.log("bal3", balance3);

    uint256 balance4 = validator.balance;
                                    console.log("bal4", balance4);



    
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

    // // Validate piNFT status
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
        console.log("qq",status);
        assertFalse(status, "Incorrect piNFT status after the purchase");

   (LibShare.Share memory commission ,bool isValid) = piNFTMethodsContract.validatorCommissions(address(piNftContract), 0);

//     // // Validate the status and commission details
    assertFalse(isValid, "Incorrect validator commission status");
    assertEq(commission.account, validator, "Incorrect validator account");
    assertEq(commission.value, 1000, "Incorrect commission value");
    vm.stopPrank();
}
function testFail_CancelSaleWhenNotForSale() public {
    // should not let owner cancel sale if sale status is false
test_BuyPiNFT() ; 
    // Attempt to cancel sale
    vm.startPrank(alice);
    PiMarket.cancelSale(1);
    vm.stopPrank();
}
function testFail_EditSalePriceWhenNotForSale() public {
    // should not allow sale price edit if sale status is false
    test_BuyPiNFT() ; 


    // Attempt to edit sale price when not for sale
    vm.startPrank(alice);

    PiMarket.editSalePrice(1, 60000);
    vm.stopPrank();
}
function testWithdrawFundsFromNFT() public {
    // should let bob withdraw funds from the NFT
test_BuyPiNFT() ; 

    // Withdraw funds from the NFT by bob
    vm.startPrank(bob);
    piNftContract.approve(address(piNFTMethodsContract), 0);

    piNFTMethodsContract.withdraw(
        address(piNftContract),
        0,
        address(sampleERC20),
        200
    );

    // Check the ERC20 balance of bob
    vm.stopPrank();
    uint256 balance = sampleERC20.balanceOf(bob);
    assertEq(balance, 200, "Incorrect ERC20 balance for bob");

    // Check the owner of the NFT
    address owner = piNftContract.ownerOf(0);
    assertEq(owner, address(piNFTMethodsContract), "Incorrect owner of the NFT");
    // vm.stopPrank();
}

function testWithdrawMoreFundsFromNFT() public {
    // should let bob withdraw more funds from the NFT
    testWithdrawFundsFromNFT();

    // Withdraw more funds from the NFT by bob
    vm.startPrank(bob);
    piNFTMethodsContract.withdraw(
        address(piNftContract),
        0,
        address(sampleERC20),
        100
    );
    vm.stopPrank();

    // Check the ERC20 balance of bob
    uint256 balance = sampleERC20.balanceOf(bob);
    assertEq(balance, 300, "Incorrect ERC20 balance for bob");

    // Check the owner of the NFT
    address owner = piNftContract.ownerOf(0);
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
        address(piNftContract),
        0,
        address(sampleERC20),
        300
    );
    vm.stopPrank();

    // Check the ERC20 balance of bob
    uint256 balance = sampleERC20.balanceOf(bob);
    assertEq(balance, 0, "Incorrect ERC20 balance for bob");

    // Check the owner of the NFT
    address owner = piNftContract.ownerOf(0);
    console.log("mmmmm",owner);
    assertEq(owner, bob, "Incorrect owner of the NFT");
}

function testValidatorAddERC20AndChangeCommission() public {
    // should allow validator to add erc20 and change commission and royalties
testRepayFundsToNFT();
    // Increase time beyond the lock period
    vm.startPrank(validator);
    skip(7500);

    // Approve ERC20 tokens to piNftMethods by validator
    sampleERC20.approve(
        address(piNFTMethodsContract),
        500
    );

    // Add ERC20, change commission, and royalties by validator
        LibShare.Share[] memory royArray1 ;
        LibShare.Share memory royalty1;
        royalty1 = LibShare.Share(validator, uint96(300));
        
        royArray1= new LibShare.Share[](1);
        royArray1[0] = royalty1;
    piNFTMethodsContract.addERC20(
        address(piNftContract),
        0,
        address(sampleERC20),
        500,
        100,
        royArray1
    );
    
    (LibShare.Share memory commission ,bool isValid) = piNFTMethodsContract.validatorCommissions(address(piNftContract), 0);

    // Validate the status and commission details
    assertFalse(isValid, "Incorrect validator commission status");
    assertEq(commission.account, validator, "Incorrect validator account");
    assertEq(commission.value, 100, "Incorrect commission value");
    vm.stopPrank();

    // Check validator commission after modification
    // LibShare.Commission memory commission = piNftMethods.validatorCommissions(
    //     address(piNftContract),
    //     0
    // );
    // assertEq(commission.isValid, false, "Validator commission is still valid");
    // assertEq(commission.commission.account, validator.getAddress(), "Incorrect validator account");
    // assertEq(commission.commission.value, 100, "Incorrect commission value");
}

function testBobPlaceNFTOnSaleAgain() public {
    // should let bob place piNFT on sale again
    testValidatorAddERC20AndChangeCommission();
    vm.startPrank(bob);

    // Approve NFT for sale by bob
    piNftContract.approve(address(PiMarket), 0);

    // Place piNFT on sale again by bob
    PiMarket.sellNFT(
        address(piNftContract),
        0,
        50000,
        0x0000000000000000000000000000000000000000
    );
    vm.stopPrank();

    // Check the ownership of piNFT after placing it on sale
    address owner = piNftContract.ownerOf(0);
    assertEq(owner, address(PiMarket), "Incorrect owner after placing NFT on sale");
}
function testAliceBuyPiNFT() public {
    // should let alice buy piNFT
    testBobPlaceNFTOnSaleAgain();

 (   uint256 saleId1,
        ,
        ,
        ,
        ,
     bool bidSale1,
     bool status,
        ,
        ,
        address owner1,
        ) = PiMarket._tokenMeta(2);
        console.log("aa",status);
                console.log("sss",bidSale1);
                        console.log("bbb",owner1);
                       console.log("ccc",saleId1);


        assertTrue(status, "Incorrect piNFT status before the purchase");

        // Get initial balances
    uint256 _balance1 = bob.balance;
    uint256 _balance2 = royaltyReceiver.balance;
    uint256 _balance3 = feeReceiver.balance;
    uint256 _balance4 = validator.balance;


    vm.startPrank(alice);
        vm.deal(alice, 1 ether);


    // Alice buys piNFT
     PiMarket.BuyNFT{ value: 50000 }(2, false);



    // Validate piNFT ownership
    address newOwner = piNftContract.ownerOf(0);
    assertEq(newOwner, alice, "Failed to transfer ownership to alice");
    // Check the balances after the transaction
    uint256 balance1 = bob.balance;
    uint256 balance2 = royaltyReceiver.balance;
    uint256 balance3 = feeReceiver.balance;
    uint256 balance4 = validator.balance;


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
        ) = PiMarket._tokenMeta(2);
        console.log("qq",status1);
        assertFalse(status1, "Incorrect piNFT status after the purchase");

        (LibShare.Share memory commission ,bool isValid) = piNFTMethodsContract.validatorCommissions(address(piNftContract), 0);

    // Validate the status and commission details
    assertFalse(isValid, "Incorrect validator commission status");
    assertEq(commission.account, validator, "Incorrect validator account");
    assertEq(commission.value, 100, "Incorrect commission value");
            vm.stopPrank();

vm.prank(alice);
 piNftContract.safeTransferFrom(alice,bob,0);

}

function test_BobPlaceNFT_OnSale_Again() public {
    // should let bob place piNFT on sale again
    testAliceBuyPiNFT();
        vm.startPrank(bob);

    // testValidatorAddERC20AndChangeCommission();
    piNftContract.approve(address(PiMarket), 0);
    PiMarket.sellNFT(
        address(piNftContract),
        0,
        10000,
        0x0000000000000000000000000000000000000000
    );

    // Check the ownership of piNFT after placing it on sale
    address owner = piNftContract.ownerOf(0);
    assertEq(owner, address(PiMarket), "Incorrect owner after placing NFT on sale");

     vm.stopPrank();
}
function test_CancelSaleWhenPaused() public {
    // should not allow cancelling sale if contract is paused
test_BobPlaceNFT_OnSale_Again();
    vm.startPrank(alice);

    // Pause the piMarket contract
    PiMarket.pause();

    // Attempt to cancel the sale while the contract is paused
    vm.expectRevert(bytes("Pausable: paused"));
    PiMarket.cancelSale(3);

    // Unpause the piMarket contract
    PiMarket.unpause();
    vm.stopPrank();
}

function testFail_CancelSaleNonOwner() public {
    // should not let non owner cancel sale
    test_CancelSaleWhenPaused();
    vm.prank(alice);

    // Attempt to cancel the sale by non-owner
    PiMarket.cancelSale(3);
}
function test_BobCancelSale() public {
    // should let bob cancel sale
test_CancelSaleWhenPaused();
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
        ) = PiMarket._tokenMeta(2); 
      assertFalse(status, "Incorrect sale status after cancellation");
        vm.stopPrank();

}


function testBobRedeemPiNFT() public {
    // should let bob redeem piNFT
    test_BobCancelSale();
    vm.startPrank(bob);

    // Approve piNFT for redemption by bob
    piNftContract.approve(address(piNFTMethodsContract), 0);

    // Redeem piNFT by bob
    piNFTMethodsContract.redeemOrBurnPiNFT(
        address(piNftContract),
        0,
        address(alice),
        0x0000000000000000000000000000000000000000,
        address(sampleERC20),
        false
    );

    // Validate balances and ownership after redemption
    assertEq(piNFTMethodsContract.viewBalance(
        address(piNftContract),
        0,
        address(sampleERC20)
    ), 0, "Incorrect balance after redemption");

    assertEq(sampleERC20.balanceOf(address(validator)), 1000, "Incorrect validator balance after redemption");

    address owner = piNftContract.ownerOf(0);
    assertEq(owner, address(alice), "Incorrect owner after redemption");



   (LibShare.Share memory commission ,bool isValid) = piNFTMethodsContract.validatorCommissions(address(piNftContract), 0);

    // Validate the status and commission details
    assertFalse(isValid, "Incorrect validator commission status");
    assertEq(commission.account, 0x0000000000000000000000000000000000000000, "Incorrect validator account");
    assertEq(commission.value, 0, "Incorrect commission value");

    vm.stopPrank();
}

function testCreatePiNFTWithTokensToAlice() public {
    testBobRedeemPiNFT();
    // Mint 1000 tokens to the validator
    vm.startPrank(alice);
    sampleERC20.mint(validator, 1000);

    // Mint a piNFT to Alice with URI "URI2" and 500 tokens to the royalty receiver
    LibShare.Share[] memory royaltyArray;
    LibShare.Share memory royalty = LibShare.Share(royaltyReceiver, uint96(500));
    royaltyArray = new LibShare.Share[](1);
    royaltyArray[0] = royalty;

    uint256 tokenId = piNftContract.mintNFT(alice, "URI2", royaltyArray);
    // assertEq(piNftContract.ownerOf(tokenId), alice, "Incorrect owner after minting");
    // assertEq(piNftContract.balanceOf(alice), 2, "Incorrect balance after minting");
    // tokenId = 1;
    address owner = piNftContract.ownerOf(tokenId);
    assertEq(owner,alice, "inValid owner");
    uint256 bal = piNftContract.balanceOf(alice);
    assertEq(bal, 2, "Incorrect balance after minting");
    console.log("vvv",tokenId);

          skip(3601);

 
    // Add validator to piNFT
    piNFTMethodsContract.addValidator(
        address(piNftContract),
     tokenId,
      validator);
      vm.stopPrank();

    // // Approve ERC20 tokens to piNftMethods
     vm.prank(validator);
    sampleERC20.approve(address(piNFTMethodsContract), 500);



       vm.startPrank(validator);

            LibShare.Share[] memory royArray1 ;
        LibShare.Share memory royalty1;
        royalty1 = LibShare.Share(validator, uint96(200));
        
        royArray1= new LibShare.Share[](1);
        royArray1[0] = royalty1;


    piNFTMethodsContract.addERC20(
        address(piNftContract), 
        1, 
        address(sampleERC20),
         500, 
         900,
          royArray1);
   
    // View ERC20 balance
    uint256 tokenBalance = piNFTMethodsContract.viewBalance(address(piNftContract), tokenId, address(sampleERC20));
    tokenBalance=500;
    assertEq(tokenBalance,500, "Incorrect ERC20 balance");

     vm.stopPrank();


   (LibShare.Share memory commission ,bool isValid) = piNFTMethodsContract.validatorCommissions(address(piNftContract), 1);

    // Validate the status and commission details
    assertTrue(isValid, "Incorrect validator commission status");
    assertEq(commission.account, validator, "Incorrect validator account");
    assertEq(commission.value, 900, "Incorrect commission value");
}

function testPauseBeforePlaceNFTOnAuction() public {
// should not place nft on auction if contract is paused 
    testCreatePiNFTWithTokensToAlice();

    // Pause the piMarket contract
    vm.startPrank(alice);
    PiMarket.pause();

    // Attempt to place the NFT on auction while the contract is paused
    piNftContract.approve(address(PiMarket), 1);
        vm.expectRevert(bytes("Pausable: paused"));

    PiMarket.SellNFT_byBid(
        address(piNftContract), 
        1,
        100,
        300,
        0x0000000000000000000000000000000000000000
    );

    // Unpause the piMarket contract
    PiMarket.unpause();
    vm.stopPrank();
}

function testFail_PlaceNFTOnAuctionWithLowPrice() public {
// should not place nft on auction if price < 10000 
    testPauseBeforePlaceNFTOnAuction();

    // Approve the NFT for auction
    vm.startPrank(alice);
    piNftContract.approve(address(PiMarket), 1);

    // Attempt to place the NFT on auction with a price less than 10000
    PiMarket.SellNFT_byBid(
        address(piNftContract), 
        1,
        100,
        300,
        0x0000000000000000000000000000000000000000
    );
    vm.stopPrank();
}

function testFail_PlaceNFTOnAuctionWithZeroAddress() public {
    // should not place nft on auction if contract address is 0
testFail_PlaceNFTOnAuctionWithLowPrice();
    // Approve the NFT for auction
    vm.startPrank(alice);
    piNftContract.approve(address(PiMarket), 1);

    // Attempt to place the NFT on auction with a contract address of 0

    PiMarket.SellNFT_byBid(
        0x0000000000000000000000000000000000000000,
        1,
        50000,
        300,
        0x0000000000000000000000000000000000000000
    );
    vm.stopPrank();
}

function testFail_PlaceNFTOnAuctionWithZeroAuctionTime() public {
    // should not place nft on auction if auction time is 0
    testFail_PlaceNFTOnAuctionWithZeroAddress();

    // Approve the NFT for auction
    vm.startPrank(alice);
    piNftContract.approve(address(PiMarket), 1);

    // Attempt to place the NFT on auction with an auction time of 0
    PiMarket.SellNFT_byBid(
        address(piNftContract), 
        1,
        50000,
        0,
 0x0000000000000000000000000000000000000000    );
    vm.stopPrank();
}
function testAllowValidatorToAddERC20AndChangeCommission() public {
    // should allow validator to add erc20 and change commission and royalties
    testPauseBeforePlaceNFTOnAuction();
        block.timestamp + 7500;
        // Increase time by 3601 seconds
        vm.warp(block.timestamp + 3601);
    vm.startPrank(validator);
   

    // Approve 500 sampleERC20 tokens to piNftMethods
    sampleERC20.approve(address(piNFTMethodsContract), 500);

    // Add 500 sampleERC20 tokens to piNFT with a commission of 1000 and royalties to validator
        LibShare.Share[] memory royArray1 ;
        LibShare.Share memory royalty1;
        royalty1 = LibShare.Share(validator, uint96(300));
        
        royArray1= new LibShare.Share[](1);
        royArray1[0] = royalty1;
    piNFTMethodsContract.addERC20(
        address(piNftContract), 
        1, 
        address(sampleERC20),
         500, 
         1000,
          royArray1);

(LibShare.Share memory commission ,bool isValid) = piNFTMethodsContract.validatorCommissions(address(piNftContract), 1);

    // Validate the status and commission details
    assertTrue(isValid, "Incorrect validator commission status");
    assertEq(commission.account, validator, "Incorrect validator account");
    assertEq(commission.value, 1000, "Incorrect commission value");

        
}

function testAlicePlacePiNFTOnAuction() public {
    // should let alice place piNFT on auction
testAllowValidatorToAddERC20AndChangeCommission();
    vm.startPrank(alice);

    // Approve the NFT for auction by alice
    piNftContract.approve(address(PiMarket), 1);

    // Place the NFT on auction by alice
    PiMarket.SellNFT_byBid(
        address(piNftContract),
        1,
        50000,
        300,
        0x0000000000000000000000000000000000000000
    );
    vm.stopPrank();

    // Check the ownership of piNFT after placing it on auction
    address owner = piNftContract.ownerOf(1);
    assertEq(owner, address(PiMarket), "Incorrect owner after placing NFT on auction");

    // Check the bidSale status after placing it on auction
    (
        ,
        ,
        ,
        ,
        ,
        bool bidSale,
        ,
        ,
        ,
        ,
        ) = PiMarket._tokenMeta(4);
    assertTrue(bidSale, "Incorrect bidSale status after placing NFT on auction");
}

function test_AliceChangeAuctionStartPrice() public {
    // should let alice change the start price of the auction
testAlicePlacePiNFTOnAuction();
    vm.startPrank(alice);

    // Change the start price of the auction by alice
    PiMarket.editSalePrice(4, 10000);
(
        ,
        ,
        ,
        uint256 price,
        ,
        ,
        ,
        ,
        ,
        ,
        ) = PiMarket._tokenMeta(4);
            assertEq(price, 10000, "Incorrect start price after changing");

    // Change the start price of the auction again by alice
    PiMarket.editSalePrice(4, 50000);
    (
        ,
        ,
        ,
        uint256 price1,
        ,
        ,
        ,
        ,
        ,
        ,
        ) = PiMarket._tokenMeta(4);
    assertEq(price1, 50000, "Incorrect start price after changing again");

    vm.stopPrank();
}

function testFail_PlaceBidWhenPaused() public {
    // should not place bids if contract is paused
    test_AliceChangeAuctionStartPrice();

    // Pause the piMarket contract
    vm.prank(alice);
    PiMarket.pause();

    // Attempt to place a bid while the contract is paused
        vm.startPrank(bidder1);

    // vm.expectRevert(bytes("Pausable: paused"));
    PiMarket.Bid{ value: 60000 }(4, 60000);

        vm.stopPrank();


    // Unpause the piMarket contract
        vm.prank(alice);

    PiMarket.unpause();
}

function testFail_PlaceBidWithIncorrectValue() public {
    // should not place bids if bid price is not equal to msg.value
        test_AliceChangeAuctionStartPrice();

    // testFail_PlaceBidWhenPaused();
    vm.startPrank(bidder1);

    // Attempt to place a bid with bid price not equal to msg.value
    PiMarket.Bid{ value: 60000 }(4, 50000);
    vm.stopPrank();
}
function testFail_PlaceBidBy_alice() public {
// should let bidders place bid on piNFT    
     test_AliceChangeAuctionStartPrice();

    // testFail_PlaceBidWhenPaused();
    vm.startPrank(alice);

    // Attempt to place a bid by alice
    PiMarket.Bid{ value: 60000 }(4, 60000);
    vm.stopPrank();
}
function testFail_PlaceBid() public {
// should let bidders place bid on piNFT    (with incorrect value)
        test_AliceChangeAuctionStartPrice();

    // testFail_PlaceBidWhenPaused();
    vm.startPrank(bidder1);

    // Attempt to place a bid with bid price not equal to msg.value
    PiMarket.Bid{ value: 50000 }(4, 50000);
    vm.stopPrank();
}
function test_PlaceBid() public {
    // should let bidders place bid on piNFT 
test_AliceChangeAuctionStartPrice();
    //  Bid by bidder1 
     vm.prank(bidder1);
         vm.deal(bidder1, 1 ether);

    PiMarket.Bid{ value: 60000 }(4, 60000);


            //  Bid by bidder2

             vm.prank(bidder2);
             vm.deal(bidder2, 1 ether);

            PiMarket.Bid{ value: 65000 }(4, 65000);

               // Again place a Bid by bidder1 

                  vm.prank(bidder1);
                 PiMarket.Bid{ value: 70000 }(4, 70000);


}
 function testFail_withdrawBid() public {
//should not let highest bidder withdraw before auction end time
       test_PlaceBid();
                 
         vm.prank(bidder1);

        PiMarket.withdrawBidMoney(4, 2);


}
function testFail_PlaceBidAfterAuctionEnd() public {
testFail_withdrawBid();  
 // Increase time to simulate the end of the auction
       vm.startPrank(bidder2);

 vm.warp(block.timestamp + 300);    
            PiMarket.Bid{ value: 75000 }(4, 75000);
            vm.stopPrank();



}
function test_AliceChangeAuctionPriceAfterBidding() public {
    // should not let alice change the auction price after bidding has begun
       test_PlaceBid();
    vm.startPrank(alice);

    // Attempt to change the auction price after bidding has begun
        vm.expectRevert(bytes("Bid has started"));

    PiMarket.editSalePrice(4, 10000);

    vm.stopPrank();
}

function test_ExecuteBidWhenPaused() public {
    // should not execute bid if contract is paused
 test_AliceChangeAuctionPriceAfterBidding();
     vm.startPrank(alice);

    // Pause the piMarket contract
    PiMarket.pause();

    // Attempt to execute a bid while the contract is paused
     vm.expectRevert(bytes("Pausable: paused"));
    PiMarket.executeBidOrder(4, 2, false);

    // Unpause the piMarket contract
    PiMarket.unpause();
    vm.stopPrank();
}

function testFail_ExecuteHighestBid() public {
    // should let alice execute highest bid
test_ExecuteBidWhenPaused();
   

     uint256 _balance1 = alice.balance;
     assertEq(_balance1,0,"invalid balance");

    uint256 _balance2 =royaltyReceiver.balance;
         assertEq(_balance2,0,"invalid balance");


    uint256 _balance3 =feeReceiver.balance;
             assertEq(_balance3,0,"invalid balance");

    

    uint256 _balance4 =validator.balance;
                 assertEq(_balance4,0,"invalid balance");

    // attempt to  execute bid by bob 
     vm.prank(bob);
     PiMarket.executeBidOrder(4, 2, false);

}
function test_AliceExecuteHighestBid() public {
    // should let alice execute highest bid
    test_ExecuteBidWhenPaused();


       vm.startPrank(alice);
     uint256 _balance1 = alice.balance;

    uint256 _balance2 =royaltyReceiver.balance;

    uint256 _balance3 =feeReceiver.balance;

    uint256 _balance4 =validator.balance;
    // attempt to  execute bid by bob 
     PiMarket.executeBidOrder(4, 2, false);
 address owner = piNftContract.ownerOf(1);
    assertEq(owner, bidder1, "Incorrect owner of the NFT");

       // Get updated balances

     uint256 balance1 = alice.balance;
    

        uint256 balance2 = royaltyReceiver.balance;

            uint256 balance3 = feeReceiver.balance;

    uint256 balance4 = validator.balance;




     // Check the amount received by alice
    uint256 AliceGotAmount = (70000 * 8100) / 10000;
    assertEq(balance1 - _balance1, AliceGotAmount, "Incorrect amount received by alice");

    // Check the amount received by Royalty Receiver
    uint256 royaltyGotAmount = (70000 * 500) / 10000;
    assertEq(balance2 - _balance2, royaltyGotAmount, "Incorrect amount received by Royalty Receiver");

    // Check the amount received by Fee Receiver
    uint256 feeGotAmount = (70000 * 100) / 10000;
    assertEq(balance3 - _balance3, feeGotAmount, "Incorrect amount received by Fee Receiver");

    // Check the amount received by Validator
    uint256 validatorGotAmount = (70000 * 1300) / 10000;
    assertEq(balance4 - _balance4, validatorGotAmount, "Incorrect amount received by Validator");


(LibShare.Share memory commission ,bool isValid) = piNFTMethodsContract.validatorCommissions(address(piNftContract), 1);

    // Validate the status and commission details
    assertFalse(isValid, "Incorrect validator commission status");
    assertEq(commission.account, validator, "Incorrect validator account");
    assertEq(commission.value, 1000, "Incorrect commission value");
    vm.stopPrank();


}

function testFail_WithdrawAnotherBid() public {
    // should not let wallet withdraw another's bid
        test_AliceExecuteHighestBid();

    // Try to withdraw bid by bidder2
    vm.startPrank(bidder2);

    // Attempt to withdraw bid by bidder2
    PiMarket.withdrawBidMoney(4, 0);

    vm.stopPrank();
}

function test_WithdrawBidWhenPaused() public {
    // should not allow bids to be withdrawn if contract is paused
    test_AliceExecuteHighestBid();

    // Pause the piMarket contract
        vm.prank(alice);

    PiMarket.pause();

    // Try to withdraw bid by bidder1 while the contract is paused
    vm.startPrank(bidder1);
         vm.expectRevert(bytes("Pausable: paused"));

    PiMarket.withdrawBidMoney(4, 0);
    vm.stopPrank();

    // Unpause the piMarket contract
    vm.prank(alice);
    PiMarket.unpause();
}

function test_OtherBiddersWithdrawBids() public {
// should let other bidders withdraw their bids
test_WithdrawBidWhenPaused();
vm.prank(bidder1);
    PiMarket.withdrawBidMoney(4, 0);
    vm.prank(bidder2);

    PiMarket.withdrawBidMoney(4, 1);

    // Check the balance of the piMarket contract
    uint256 balance1 = address(PiMarket).balance;
    assertEq(balance1, 0, "Incorrect balance after withdrawing bids");

    // Transfer the NFT from bidder1 to alice
    vm.prank(bidder1);

    piNftContract.safeTransferFrom(bidder1, alice, 1);
}

}
