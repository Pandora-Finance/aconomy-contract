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
function testFail_BidderWithdrawAgain() public {
    // should not let bidder withdraw again
    test_OtherBiddersWithdrawBids();

    // Attempt to withdraw bid again by bidder1
    vm.startPrank(bidder1);
    PiMarket.withdrawBidMoney(4, 0);
    vm.stopPrank();
}
function testFail_ExecuteWithdrawnBid() public {
    // should not execute a withdrawn bid

        test_OtherBiddersWithdrawBids();

    // Attempt to execute a withdrawn bid by bidder2
    vm.startPrank(alice);
    PiMarket.executeBidOrder(4, 1, false);
    vm.stopPrank();
}
function test_AlicePlacePiNFTOnAuction() public {
    // should let alice place piNFT on auction
  test_OtherBiddersWithdrawBids();
    
    // Approve the NFT for auction
    vm.startPrank(alice);
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
    
    // Validate NFT ownership
    address newOwner = piNftContract.ownerOf(1);
    assertEq(newOwner, address(PiMarket), "Failed to transfer ownership to PiMarket");

    // Validate auction status
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
        ) = PiMarket._tokenMeta(5);
    assertTrue(bidSale, "Incorrect bid sale status");
}

function test_BiddersPlaceBidOnPiNFT() public {
    // should let bidders place bid on piNFT
    test_AlicePlacePiNFTOnAuction();
    vm.startPrank(bidder1);

    // Place bid by bidder1
    PiMarket.Bid{ value: 70000 }(5, 70000);
    (,,,address buyerAddress,,) = PiMarket.Bids(5, 0);

    // Validate bid details
    assertEq(buyerAddress, bidder1, "Incorrect buyer address in bid");

    vm.stopPrank();
}


function test_aliceExecuteBid() public {
    // should let alice execute highest bid
    test_BiddersPlaceBidOnPiNFT();
      vm.startPrank(alice);

    uint256 _balance1 = alice.balance;
    uint256 _balance2 = royaltyReceiver.balance;
    uint256 _balance3 = feeReceiver.balance;
    uint256 _balance4 = validator.balance;

    // Execute the highest bid by alice
    PiMarket.executeBidOrder(5, 0, false);

    // Validate NFT ownership
    assertEq(piNftContract.ownerOf(1), bidder1, "Incorrect owner of the NFT");

    // Get updated balances
    uint256 balance1 = alice.balance;
    uint256 balance2 = royaltyReceiver.balance;
    uint256 balance3 = feeReceiver.balance;
    uint256 balance4 = validator.balance;

    // Check the amount received by Alice
    uint256 aliceGotAmount = (70000 * 9100) / 10000;
    assertEq(balance1 - _balance1, aliceGotAmount, "Incorrect amount received by Alice");

    // Check the amount received by Royalty Receiver
    uint256 royaltyGotAmount = (70000 * 500) / 10000;
    assertEq(balance2 - _balance2, royaltyGotAmount, "Incorrect amount received by Royalty Receiver");

    // Check the amount received by Fee Receiver
    uint256 feeGotAmount = (70000 * 100) / 10000;
    assertEq(balance3 - _balance3, feeGotAmount, "Incorrect amount received by Fee Receiver");

    // Check the amount received by Validator
    uint256 validatorGotAmount = (70000 * 300) / 10000;
    assertEq(balance4 - _balance4, validatorGotAmount, "Incorrect amount received by Validator");

    (LibShare.Share memory commission, bool isValid) = piNFTMethodsContract.validatorCommissions(address(piNftContract), 1);

    // Validate the status and commission details
    assertFalse(isValid, "Incorrect validator commission status");
    assertEq(commission.account, validator, "Incorrect validator account");
    assertEq(commission.value, 1000, "Incorrect commission value");
}

function test_BidderDisintegrateNFTAndERC20Tokens() public {
    // should let bidder disintegrate NFT and ERC20 tokens
test_aliceExecuteBid();
    // Approve the NFT for disintegration
    vm.startPrank(bidder1);
    piNftContract.approve(address(piNFTMethodsContract), 1);

    // Disintegrate the NFT and ERC20 tokens by bidder1
    piNFTMethodsContract.redeemOrBurnPiNFT(
        address(piNftContract),
        1,
        bob,
        0x0000000000000000000000000000000000000000,
        address(sampleERC20),
        false
    );

    // Validate ERC20 balance and NFT ownership
    // uint256 validatorBal = sampleERC20.balanceOf(address(validator));
    assertEq(piNFTMethodsContract.viewBalance(address(piNftContract), 1, address(sampleERC20)), 0, "Incorrect ERC20 balance after disintegration");
    assertEq(sampleERC20.balanceOf(address(validator)), 2000, "Incorrect ERC20 balance after disintegration");
    assertEq(piNftContract.ownerOf(1), bob, "Incorrect owner of the NFT after disintegration");

    // Validate validator commission details
    (LibShare.Share memory commission, bool isValid) = piNFTMethodsContract.validatorCommissions(address(piNftContract), 1);
    assertFalse(isValid, "Incorrect validator commission status after disintegration");
    assertEq(commission.account, 0x0000000000000000000000000000000000000000, "Incorrect validator account after disintegration");
    assertEq(commission.value, 0, "Incorrect commission value after disintegration");

    vm.stopPrank();
}

function test_CreatePiNFTWithTokensToAlice() public {
    // should create a piNFT with 500 erc20 tokens to alice
test_BidderDisintegrateNFTAndERC20Tokens();
 vm.startPrank(alice);
    // Mint ERC20 tokens for the validator
    sampleERC20.mint(address(validator), 1000);

    // Mint a new piNFT with 500 erc20 tokens to Alice
   LibShare.Share[] memory royaltyArray;
    LibShare.Share memory royalty = LibShare.Share(royaltyReceiver, uint96(500));
    royaltyArray = new LibShare.Share[](1);
    royaltyArray[0] = royalty;

    uint256 tokenId = piNftContract.mintNFT(
        alice, 
        "URI2", 
        royaltyArray);
   
    tokenId = 2;
    assertEq(tokenId,2,"inavlid token ID");
    address owner = piNftContract.ownerOf(tokenId);
    assertEq(owner,alice, "inValid owner");
    uint256 bal = piNftContract.balanceOf(alice);
    assertEq(bal, 2, "Incorrect balance after minting");
     skip(3601);
 // Add a validator to the piNFT
    piNFTMethodsContract.addValidator(
        address(piNftContract),
         tokenId, 
         address(validator));
         vm.stopPrank();

    // // Approve ERC20 tokens to piNftMethods
     vm.prank(validator);
    sampleERC20.approve(address(piNFTMethodsContract), 500);

    // Add ERC20 tokens to the piNFT
      vm.startPrank(validator);

            LibShare.Share[] memory royArray1 ;
        LibShare.Share memory royalty1;
        royalty1 = LibShare.Share(validator, uint96(200));
        
        royArray1= new LibShare.Share[](1);
        royArray1[0] = royalty1;


    piNFTMethodsContract.addERC20(
        address(piNftContract), 
        2, 
        address(sampleERC20),
         500, 
         900,
          royArray1);
   
    // View ERC20 balance
    uint256 tokenBalance = piNFTMethodsContract.viewBalance(address(piNftContract), tokenId, address(sampleERC20));
    tokenBalance=500;
    assertEq(tokenBalance,500, "Incorrect ERC20 balance");

     vm.stopPrank();

     (LibShare.Share memory commission ,bool isValid) = piNFTMethodsContract.validatorCommissions(address(piNftContract), 2);

    // Validate the status and commission details
    assertTrue(isValid, "Incorrect validator commission status");
    assertEq(commission.account, validator, "Incorrect validator account");
    assertEq(commission.value, 900, "Incorrect commission value");
}
function test_Alice_PlacePiNFTOnAuction() public {
    // should let alice place piNFT on auction
test_CreatePiNFTWithTokensToAlice() ;
    vm.startPrank(alice);

    // Approve the NFT for auction by alice
    piNftContract.approve(address(PiMarket), 2);

    // Place the NFT on auction by alice
    PiMarket.SellNFT_byBid(
        address(piNftContract),
        2,
        50000,
        300,
        0x0000000000000000000000000000000000000000
    );
    vm.stopPrank();

    // Check the ownership of piNFT after placing it on auction
    address owner = piNftContract.ownerOf(2);
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
        ) = PiMarket._tokenMeta(6);
    assertTrue(bidSale, "Incorrect bidSale status after placing NFT on auction");
}
function testFail_BidOnPiNFTAsNFTOwner() public {
    // should let bidders place bid on piNFT
test_Alice_PlacePiNFTOnAuction();
    // Attempt to place bid by Alice, who is the owner of the piNFT
    vm.startPrank(alice);
    PiMarket.Bid{ value: 60000 }(6, 60000);
    vm.stopPrank();
}

function testFail_BidOnPiNFT() public {
    // should let bidders place bid on piNFT
test_Alice_PlacePiNFTOnAuction();
    // Attempt to place bid by Alice, who is the owner of the piNFT
    vm.startPrank(bidder1);
    PiMarket.Bid{ value: 50000 }(6, 60000);
    vm.stopPrank();
}

function test_BidOnPiNFT() public {
    // should let bidders place bid on piNFT
test_Alice_PlacePiNFTOnAuction();
    vm.startPrank(bidder2);

    // Place bid by bidder2
    PiMarket.Bid{ value: 60000 }(6, 60000);
vm.stopPrank();
    // Place bid by bidder2

    vm.startPrank(bidder1);

    PiMarket.Bid{ value: 70000 }(6, 70000);



    (,,,address buyerAddress,,) = PiMarket.Bids(6, 1);

    // Validate bid details
    assertEq(buyerAddress, bidder1, "Incorrect buyer address in bid");

    vm.stopPrank();
}

function test_Bidder2WithdrawBid() public {
    // should let bidder2 withdraw the bid
test_BidOnPiNFT();
    // Withdraw bid by bidder2
    vm.startPrank(bidder2);
    PiMarket.withdrawBidMoney(6, 0);
    vm.stopPrank();

    // Check the withdrawal status
    (   ,
        ,
        ,
        ,
        ,
        bool withdrawn
    ) = PiMarket.Bids(6, 0);
    assertTrue(withdrawn, "Bidder2 should have successfully withdrawn the bid");
}

function testFail_OwnerAcceptWithdrawnBid() public {
    // should not allow owner to accept withdrawn bid
test_Bidder2WithdrawBid();
    // Attempt to execute withdrawn bid by owner
    vm.startPrank(alice);
    PiMarket.executeBidOrder(6, 0, false);
    vm.stopPrank();
}
function testFail_Bidder1WithdrawHighestBid() public {
    // should not let bidder1 withdraw the highest bid
test_Bidder2WithdrawBid();

    // Attempt to withdraw the highest bid by bidder1
    vm.startPrank(bidder1);
    PiMarket.withdrawBidMoney(6, 1);
    vm.stopPrank();
}
function test_HighestBidderWithdrawAfterAuctionExpires() public {
    // should let highest bidder withdraw after auction expires
    test_Bidder2WithdrawBid();

     vm.startPrank(bidder1);
            vm.warp(block.timestamp + 400);
            // skip(400);

    PiMarket.withdrawBidMoney(6, 1);
    (
        ,
        ,
        ,
        ,
        ,
        bool withdrawn
    ) = PiMarket.Bids(6, 1);
    assertTrue(withdrawn, "Bidder1 should be able to withdraw after auction expires");
     vm.stopPrank();
}
function test_AliceCancelAuctionAfterExpiration() public {
    // should let alice cancel the auction after expiration
    test_HighestBidderWithdrawAfterAuctionExpires() ;
         vm.startPrank(alice);

    PiMarket.cancelSale(6);
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
        ) = PiMarket._tokenMeta(6); 
    assertFalse(status, "Auction should be canceled");
    assertEq(piNftContract.ownerOf(2), alice, "Incorrect owner after canceling auction");

         vm.stopPrank();

}

function test_Alice_Again_PlacePiNFTOnAuction() public {
    // should let alice place piNFT on auction
    test_AliceCancelAuctionAfterExpiration();

    // Approve the NFT for auction
    vm.startPrank(alice);
    piNftContract.approve(address(PiMarket), 2);

    // Place the NFT on auction by alice
    PiMarket.SellNFT_byBid(
        address(piNftContract), 
        2,
        50000,
        300,
        0x0000000000000000000000000000000000000000
    );

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
        ) = PiMarket._tokenMeta(7);
    assertTrue(bidSale, "Incorrect bidSale status after placing NFT on auction");
    vm.stopPrank();
}

function testFail_Bidders_PlaceBid_OnPiNFT() public {
    // should let bidders place bid on piNFT
test_Alice_Again_PlacePiNFTOnAuction();
    // Attempt to place bids by alice(owner)
    vm.startPrank(alice);
    
        PiMarket.Bid{value: 60000}(7, 60000);
 
    vm.stopPrank();
}
function testFail_Bidders_PlaceBidOnPiNFT() public {
    // should let bidders place bid on piNFT
test_Alice_Again_PlacePiNFTOnAuction();
    // Attempt to place bids by bidder1
vm.startPrank(bidder1);
    
        PiMarket.Bid{ value: 50000 }(7, 50000 );
   
    vm.stopPrank();
}
function test_Bidders_PlaceBidOnPiNFT() public {
    // should let bidders place bid on piNFT
test_Alice_Again_PlacePiNFTOnAuction();
// Place bids by bidder2 
vm.startPrank(bidder2);

        PiMarket.Bid{value: 60000}(7, 60000);
        vm.stopPrank();
        // Place bids by bidder1
        vm.startPrank(bidder1);

        PiMarket.Bid{value: 70000}(7, 70000);  


          (,,,address buyerAddress,,) = PiMarket.Bids(7, 1);

    // Validate bid details
    assertEq(buyerAddress, bidder1, "Incorrect buyer address in bid");

    vm.stopPrank();


}
function testFail_Bidder_WithdrawHighestBid() public {
    // should not let bidder1 withdraw the highest bid
test_Bidders_PlaceBidOnPiNFT();
    // Attempt to withdraw the highest bid by bidder1
    vm.startPrank(bidder1);
    PiMarket.withdrawBidMoney(7, 1);
    vm.stopPrank();

}

function test_Alice_CancelAuctionAfterExpiration() public {
    // should let alice cancel the auction
test_Bidders_PlaceBidOnPiNFT();
         vm.startPrank(alice);

    PiMarket.cancelSale(7);
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
        ) = PiMarket._tokenMeta(7); 
    assertFalse(status, "Auction should be canceled");
    assertEq(piNftContract.ownerOf(2), alice, "Incorrect owner after canceling auction");

         vm.stopPrank();

}

function test_Bidder_WithdrawHighestBid() public {
    // should let bidder1 withdraw the highest bid
test_Alice_CancelAuctionAfterExpiration();
    // Attempt to withdraw the highest bid by bidder1
    vm.startPrank(bidder1);
    PiMarket.withdrawBidMoney(7, 1);
    (   ,
        ,
        ,
        ,
        ,
        bool withdrawn
    ) = PiMarket.Bids(7, 1);
    assertTrue(withdrawn, "Bidder2 should have successfully withdrawn the bid");
    vm.stopPrank();

}

function test_Alice_Place_PiNFTOnAuction() public {
    // should let alice place piNFT on auction
test_Bidder_WithdrawHighestBid();
    // Approve the NFT for auction
    vm.startPrank(alice);
    piNftContract.approve(address(PiMarket), 2);

    // Place the NFT on auction by alice
    PiMarket.SellNFT_byBid(
        address(piNftContract), 
        2,
        50000,
        300,
        0x0000000000000000000000000000000000000000
    );

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
        ) = PiMarket._tokenMeta(8);
    assertTrue(bidSale, "Incorrect bidSale status after placing NFT on auction");
    vm.stopPrank();
}
//   describe("Swap NFTs", () =>

function test_Create_PiNFTWithTokensToAlice() public {
    // should create a piNFT with 500 erc20 tokens to alice
test_Alice_Place_PiNFTOnAuction();
 vm.startPrank(alice);
    // Mint ERC20 tokens for the validator
    sampleERC20.mint(address(validator), 1000);

    // Mint a new piNFT with 500 erc20 tokens to Alice
   LibShare.Share[] memory royaltyArray;
    LibShare.Share memory royalty = LibShare.Share(royaltyReceiver, uint96(500));
    royaltyArray = new LibShare.Share[](1);
    royaltyArray[0] = royalty;

    uint256 tokenId = piNftContract.mintNFT(
        alice, 
        "URI2", 
        royaltyArray);
   
    tokenId = 3;
    assertEq(tokenId,3,"inavlid token ID");
    address owner = piNftContract.ownerOf(tokenId);
    assertEq(owner,alice, "inValid owner");
    uint256 bal = piNftContract.balanceOf(alice);
    assertEq(bal, 2, "Incorrect balance after minting");
    // Get the current block timestamp
        uint256 currentTime = block.timestamp;
        // Warp the time ahead by 3600 seconds (1 hour)
        vm.warp(currentTime + 3600);
        // Now block.timestamp will return the warped time
        uint256 newTime = block.timestamp;
        // Check that the new time is indeed 3600 seconds ahead
        assertEq(newTime, currentTime + 3600);
    //  skip(3601);
 // Add a validator to the piNFT
    piNFTMethodsContract.addValidator(
        address(piNftContract),
         3, 
         address(validator));
         vm.stopPrank();

    // // Approve ERC20 tokens to piNftMethods
     vm.prank(validator);
    sampleERC20.approve(address(piNFTMethodsContract), 500);

    // Add ERC20 tokens to the piNFT
      vm.startPrank(validator);

            LibShare.Share[] memory royArray1 ;
        LibShare.Share memory royalty1;
        royalty1 = LibShare.Share(validator, uint96(200));
        
        royArray1= new LibShare.Share[](1);
        royArray1[0] = royalty1;


    piNFTMethodsContract.addERC20(
        address(piNftContract), 
        3, 
        address(sampleERC20),
         500, 
         900,
          royArray1);
   
    // View ERC20 balance
    uint256 tokenBalance = piNFTMethodsContract.viewBalance(address(piNftContract), tokenId, address(sampleERC20));
    tokenBalance=500;
    assertEq(tokenBalance,500, "Incorrect ERC20 balance");

     vm.stopPrank();

     (LibShare.Share memory commission ,bool isValid) = piNFTMethodsContract.validatorCommissions(address(piNftContract), 3);

    // Validate the status and commission details
    assertTrue(isValid, "Incorrect validator commission status");
    assertEq(commission.account, validator, "Incorrect validator account");
    assertEq(commission.value, 900, "Incorrect commission value");
}

function test_CreatePiNFTWithTokensToBob() public {
    // should create a piNFT with 500 erc20 tokens to bob

    test_Create_PiNFTWithTokensToAlice();
    vm.startPrank(bob);
    // Mint ERC20 tokens for the validator
    sampleERC20.mint(address(validator), 1000);

    // Mint a new piNFT with 500 erc20 tokens to bob
   LibShare.Share[] memory royaltyArray;
    LibShare.Share memory royalty = LibShare.Share(royaltyReceiver, uint96(500));
    royaltyArray = new LibShare.Share[](1);
    royaltyArray[0] = royalty;

    uint256 tokenId = piNftContract.mintNFT(
        bob, 
        "URI2", 
        royaltyArray);
   
    // tokenId = 4;
    assertEq(tokenId,4,"inavlid token ID");
    address owner = piNftContract.ownerOf(tokenId);
    assertEq(owner,bob, "inValid owner");
    uint256 bal = piNftContract.balanceOf(alice);
    assertEq(bal, 2, "Incorrect balance after minting");
    // Get the current block timestamp
        uint256 currentTime = block.timestamp;
        // Warp the time ahead by 3600 seconds (1 hour)
        vm.warp(currentTime + 3600);
        // Now block.timestamp will return the warped time
        uint256 newTime = block.timestamp;
        // Check that the new time is indeed 3600 seconds ahead
        assertEq(newTime, currentTime + 3600);
                 vm.stopPrank();

    //  skip(3601);
 // Add a validator to the piNFT
 vm.prank(bob);

    piNFTMethodsContract.addValidator(
        address(piNftContract),
         4, 
         address(validator));

    // // Approve ERC20 tokens to piNftMethods
     vm.prank(validator);
    sampleERC20.approve(address(piNFTMethodsContract), 500);

    // Add ERC20 tokens to the piNFT
      vm.startPrank(validator);

            LibShare.Share[] memory royArray1 ;
        LibShare.Share memory royalty1;
        royalty1 = LibShare.Share(validator, uint96(200));
        
        royArray1= new LibShare.Share[](1);
        royArray1[0] = royalty1;


    piNFTMethodsContract.addERC20(
        address(piNftContract), 
        4, 
        address(sampleERC20),
         500, 
         900,
          royArray1);
   
    // View ERC20 balance
    uint256 tokenBalance = piNFTMethodsContract.viewBalance(address(piNftContract), tokenId, address(sampleERC20));
    tokenBalance=500;
    assertEq(tokenBalance,500, "Incorrect ERC20 balance");

     vm.stopPrank();

     (LibShare.Share memory commission ,bool isValid) = piNFTMethodsContract.validatorCommissions(address(piNftContract), 4);

    // Validate the status and commission details
    assertTrue(isValid, "Incorrect validator commission status");
    assertEq(commission.account, validator, "Incorrect validator account");
    assertEq(commission.value, 900, "Incorrect commission value");
}
function test_NewPiNFTWithTokensToAlice() public {
// should create a piNFT again with 500 erc20 tokens to alice
test_CreatePiNFTWithTokensToBob();
 vm.startPrank(alice);
    // Mint ERC20 tokens for the validator
    sampleERC20.mint(address(validator), 1000);

    // Mint a new piNFT with 500 erc20 tokens to Alice
   LibShare.Share[] memory royaltyArray;
    LibShare.Share memory royalty = LibShare.Share(royaltyReceiver, uint96(500));
    royaltyArray = new LibShare.Share[](1);
    royaltyArray[0] = royalty;

    uint256 tokenId = piNftContract.mintNFT(
        alice, 
        "URI2", 
        royaltyArray);
   
    // tokenId = 3;
    assertEq(tokenId,5,"inavlid token ID");
    address owner = piNftContract.ownerOf(tokenId);
    assertEq(owner,alice, "inValid owner");
    uint256 bal = piNftContract.balanceOf(alice);
    assertEq(bal, 3, "Incorrect balance after minting");
    // Get the current block timestamp
        uint256 currentTime = block.timestamp;
        // Warp the time ahead by 3600 seconds (1 hour)
        vm.warp(currentTime + 3600);
        // Now block.timestamp will return the warped time
        uint256 newTime = block.timestamp;
        // Check that the new time is indeed 3600 seconds ahead
        assertEq(newTime, currentTime + 3600);
    //  skip(3601);
 // Add a validator to the piNFT
    piNFTMethodsContract.addValidator(
        address(piNftContract),
         5, 
         address(validator));
         vm.stopPrank();

    // // Approve ERC20 tokens to piNftMethods
     vm.prank(validator);
    sampleERC20.approve(address(piNFTMethodsContract), 500);

    // Add ERC20 tokens to the piNFT
      vm.startPrank(validator);

            LibShare.Share[] memory royArray1 ;
        LibShare.Share memory royalty1;
        royalty1 = LibShare.Share(validator, uint96(200));
        
        royArray1= new LibShare.Share[](1);
        royArray1[0] = royalty1;


    piNFTMethodsContract.addERC20(
        address(piNftContract), 
        5, 
        address(sampleERC20),
         500, 
         900,
          royArray1);
   
    // View ERC20 balance
    uint256 tokenBalance = piNFTMethodsContract.viewBalance(address(piNftContract), tokenId, address(sampleERC20));
    tokenBalance=500;
    assertEq(tokenBalance,500, "Incorrect ERC20 balance");

     vm.stopPrank();

     (LibShare.Share memory commission ,bool isValid) = piNFTMethodsContract.validatorCommissions(address(piNftContract), 5);

    // Validate the status and commission details
    assertTrue(isValid, "Incorrect validator commission status");
    assertEq(commission.account, validator, "Incorrect validator account");
    assertEq(commission.value, 900, "Incorrect commission value");
}
function test_InitiateSwapWhenPaused() public {
    // should not allow initiating a swap if contract is paused
    test_NewPiNFTWithTokensToAlice();
    // Pause the contract and attempt to initiate a swap
    vm.prank(alice);
    PiMarket.pause();

            vm.prank(alice);
        vm.expectRevert(bytes("Pausable: paused"));
        PiMarket.makeSwapRequest(
        address(piNftContract), 
        address(piNftContract), 
            3,
            4
        );
  vm.prank(alice);
  PiMarket.unpause();
}

function test_InitiateSwapNotTokenOwner() public {
    // should not allow initiating a swap if caller is not token owner
test_InitiateSwapWhenPaused();
    // Attempt to initiate a swap by bob who is not the token owner
    vm.startPrank(bob);
       vm.expectRevert(bytes("Only token owner can execute"));
        PiMarket.makeSwapRequest(
        address(piNftContract), 
        address(piNftContract), 
            3,
            4
        );
    vm.stopPrank();
}
function testFail_InitiateSwapWithZeroAddress() public {
    // should not allow initiating a swap if either contract address is 0
test_InitiateSwapNotTokenOwner();

    // Attempt to initiate a swap with one of the contract addresses set to 0
    vm.startPrank(bob);
        PiMarket.makeSwapRequest(
            0x0000000000000000000000000000000000000000,
        address(piNftContract), 
            3,
            4
        );
            vm.stopPrank();
}
function test_InitiateSwap_WithZeroAddress() public {
    // should not allow initiating a swap if either contract address is 0
test_InitiateSwapNotTokenOwner();
    vm.startPrank(bob);


               vm.expectRevert(bytes("Only token owner can execute"));

        PiMarket.makeSwapRequest(
        address(piNftContract), 
            0x0000000000000000000000000000000000000000,
            3,
            4
        );
    vm.stopPrank();
}

function testFail_InitiateSwapTokenOwner2() public {
    // should not allow initiating a swap if caller is token2 owner
 test_InitiateSwap_WithZeroAddress();
    // Attempt to initiate a swap with the caller as the owner of token2
    vm.startPrank(bob);
        PiMarket.makeSwapRequest(
        address(piNftContract), 
        address(piNftContract), 
            3,
            5
        );
    vm.stopPrank();
}
function testFail_InitiateSwapBy_alice() public {
// should let alice initiate swap request 
 test_InitiateSwap_WithZeroAddress();
    vm.startPrank(alice);
        piNftContract.approve(address(PiMarket), 3);

        PiMarket.makeSwapRequest(
        address(piNftContract), 
            0x0000000000000000000000000000000000000000,
            5,
            4
        );
    vm.stopPrank();
}
function testFail_Initiate_SwapBy_alice() public {
// should let alice initiate swap request 
 test_InitiateSwap_WithZeroAddress();
    vm.startPrank(alice);
        piNftContract.approve(address(PiMarket), 3);

        PiMarket.makeSwapRequest(
        0x0000000000000000000000000000000000000000,
        address(piNftContract), 
            5,
            4
        );
    vm.stopPrank();
}
function test_initiate_SwapBy_alice() public {
// should let alice initiate swap request 
 test_InitiateSwap_WithZeroAddress();
    vm.startPrank(alice);
    piNftContract.approve(address(PiMarket), 3);
PiMarket.makeSwapRequest(
        address(piNftContract), 
        address(piNftContract), 
        3,
        4
      );
 
 
 
     (  ,
        address initiator,
        ,
        ,
        ,
        ,
        ) = PiMarket._swaps(0);
                //   vm.stopPrank();
        assertEq(initiator,alice,"incorrect address");
        assertEq(piNftContract.ownerOf(3), address(PiMarket), "Ownership should be transferred to the market");
        vm.stopPrank();

}
function test_Again_initiateSwapByAlice() public {
// should let alice initiate swap request again
test_initiate_SwapBy_alice();
  vm.startPrank(alice);
    piNftContract.approve(address(PiMarket), 5);
PiMarket.makeSwapRequest(
        address(piNftContract), 
        address(piNftContract), 
        5,
        4
      );
 
 
 
     (  ,
        address initiator,
        ,
        ,
        ,
        ,
        ) = PiMarket._swaps(0);
                //   vm.stopPrank();
        assertEq(initiator,alice,"incorrect address");
        assertEq(piNftContract.ownerOf(5), address(PiMarket), "Ownership should be transferred to the market");
        vm.stopPrank();


}

function test_CancelSwapIfTokenOwnerChanged() public {
    // should cancel the swap if requested token owner has changed  
     test_Again_initiateSwapByAlice();
    vm.startPrank(bob);
    piNftContract.safeTransferFrom(bob, carl, 4);
    vm.stopPrank();

    // Attempt to accept the swap request after changing the token owner
        vm.startPrank(carl);

    piNftContract.approve(address(PiMarket), 4);
                   vm.expectRevert(bytes("requesting token owner has changed"));

    PiMarket.acceptSwapRequest(0);

    // Transfer the token back to the original owner
    piNftContract.safeTransferFrom(carl, bob, 4);
        vm.stopPrank();

}
function test_swapRequest() public {

// "should not let an address that is not bob accept the swap request 
test_CancelSwapIfTokenOwnerChanged();
   vm.startPrank(carl); 
          vm.expectRevert(bytes("Only requested owner can accept swap"));

    PiMarket.acceptSwapRequest(0);
            vm.stopPrank();


}
function test_AcceptSwapWhenPaused() public {
    // should not allow accepting a swap if contract is paused
    test_swapRequest();
    vm.prank(alice);
    PiMarket.pause();

    // Approve the token for the swap
        vm.startPrank(bob); 
    piNftContract.approve(address(PiMarket), 4);

    // Attempt to accept the swap request while the contract is paused
          vm.expectRevert(bytes("Pausable: paused"));
          PiMarket.acceptSwapRequest(0);
                      vm.stopPrank();


    // Unpause the contract
        vm.prank(alice);
    PiMarket.unpause();
}
function test_BobAcceptSwapRequest() public {
    // should let bob accept the swap request
    test_AcceptSwapWhenPaused();

    // Approve the token for the swap
            vm.startPrank(bob); 

    piNftContract.approve(address(PiMarket), 4);

    // Check the initial status of the swap
    (   ,
        ,
        ,
        ,
        ,
        ,
        bool status
        ) = PiMarket._swaps(0);
    assertTrue(status, "Incorrect initial swap status");

    // Bob accepts the swap request
    PiMarket.acceptSwapRequest(0);

    // Validate the new ownership of tokens
    assertEq(piNftContract.ownerOf(3), bob, "Incorrect owner of token 3 after swap");
    assertEq(piNftContract.ownerOf(4), alice, "Incorrect owner of token 4 after swap");

    // Check the updated status of the swap
    (   ,
        ,
        ,
        ,
        ,
        ,
        bool status1
        ) = PiMarket._swaps(0);
    assertFalse(status1, "Incorrect final swap status");
}
function test_CancelSwapWhenPaused() public {
    // should not allow cancelling a swap if contract is paused
    test_BobAcceptSwapRequest();

    // Pause the contract
    vm.startPrank(alice);
    PiMarket.pause();

    // Attempt to cancel the swap
    vm.expectRevert(bytes("Pausable: paused"));

    PiMarket.cancelSwap(1);

        PiMarket.unpause();

    vm.stopPrank();
}
function testFail_CancelSwapBy_NonInitiator() public {
// should not allow non initiator cancelling a swap 
test_CancelSwapWhenPaused();

    vm.startPrank(bob);


 PiMarket.cancelSwap(1);

        PiMarket.unpause();

    vm.stopPrank();

}
function test_AliceCancelSwapRequest() public {
    // should let alice cancel the swap request
    test_CancelSwapWhenPaused();

        vm.startPrank(alice);

    // Check the initial status of the swap request
     (   ,
        ,
        ,
        ,
        ,
        ,
        bool status
        ) = PiMarket._swaps(1);
    assertTrue(status, "Incorrect final swap status");
    // Cancel the swap request by Alice
    PiMarket.cancelSwap(1);

    // Check the updated status of the swap request and ownership of the NFT
        assertEq(piNftContract.ownerOf(5), alice, "Incorrect owner of token 5 after swap");

     (   ,
        ,
        ,
        ,
        ,
        ,
        bool status1
        ) = PiMarket._swaps(1);
    assertFalse(status1, "Incorrect final swap status");
        vm.stopPrank();

}
function testFail_CancelSwapRequest() public {
// should not allow cancelling an already cancelled swap 
test_AliceCancelSwapRequest();
    PiMarket.cancelSwap(1);

}

function test_AliceInitiateSwapRequest() public {
    // should let alice initiate swap request
    test_AliceCancelSwapRequest();

        vm.startPrank(alice);

    // Approve the NFT for swap
    piNftContract.approve(address(PiMarket), 5);

    // Initiate the swap request by Alice
    PiMarket.makeSwapRequest(
        address(piNftContract), 
        address(piNftContract), 
        5,
        3
    );

    // Check the details of the initiated swap request
   
     (  ,
        address initiator,
        ,
        ,
        ,
        ,
        ) = PiMarket._swaps(2);
        assertEq(initiator,alice,"incorrect address");

        // Check the ownership of the NFT
        assertEq(piNftContract.ownerOf(5), address(PiMarket), "Incorrect owner of the NFT after initiating swap request");
               vm.stopPrank();

}

function test_Alice_CancelSwapRequest() public {
    // should let alice cancel swap request
test_AliceInitiateSwapRequest();
        vm.startPrank(alice);

    // Check the initial status of the swap request
     (   ,
        ,
        ,
        ,
        ,
        ,
        bool status
        ) = PiMarket._swaps(2);
    assertTrue(status, "Incorrect final swap status");
    // Cancel the swap request by Alice
    PiMarket.cancelSwap(2);

    // Check the updated status of the swap request and ownership of the NFT
        assertEq(piNftContract.ownerOf(5), alice, "Incorrect owner of token 5 after swap");

     (   ,
        ,
        ,
        ,
        ,
        ,
        bool status1
        ) = PiMarket._swaps(2);
    assertFalse(status1, "Incorrect final swap status");
        vm.stopPrank();

}
function testFail_AcceptSwapWithFalseStatus() public {
    // should not allow accepting a swap with a false status
    test_Alice_CancelSwapRequest();
             vm.startPrank(alice);

    // Approve the NFT for swap by Bob
    piNftContract.approve(address(PiMarket), 3);

    // Attempt to accept the swap request with a false status
    
        PiMarket.acceptSwapRequest(2);

         vm.stopPrank();
}
//  Describe (Sale Tests); 
function test_PiNFTWithTokensToCarl() public {
// should create a piNFT again with 500 erc20 tokens to carl
    test_Alice_CancelSwapRequest();
vm.prank(feeReceiver);
aconomyFee.setAconomyPiMarketFee(0);

 vm.startPrank(carl);
    // Mint ERC20 tokens for the validator
    sampleERC20.mint(address(validator), 1000);

    // Mint a new piNFT with 500 erc20 tokens to carl
   LibShare.Share[] memory royaltyArray;
    LibShare.Share memory royalty = LibShare.Share(royaltyReceiver, uint96(500));
    royaltyArray = new LibShare.Share[](1);
    royaltyArray[0] = royalty;

    uint256 tokenId = piNftContract.mintNFT(
        carl, 
        "URI2", 
        royaltyArray);
   
    // tokenId = 3;
    assertEq(tokenId,6,"inavlid token ID");
    address owner = piNftContract.ownerOf(tokenId);
    assertEq(owner,carl, "inValid owner");
    uint256 bal = piNftContract.balanceOf(carl);
    assertEq(bal, 1, "Incorrect balance after minting");
    // Get the current block timestamp
        uint256 currentTime = block.timestamp;
        // Warp the time ahead by 3600 seconds (1 hour)
        vm.warp(currentTime + 3600);
        // Now block.timestamp will return the warped time
        uint256 newTime = block.timestamp;
        // Check that the new time is indeed 3600 seconds ahead
        assertEq(newTime, currentTime + 3600);
    //  skip(3601);
 // Add a validator to the piNFT
    piNFTMethodsContract.addValidator(
        address(piNftContract),
         6, 
         address(validator));
         vm.stopPrank();

    // // Approve ERC20 tokens to piNftMethods
     vm.prank(validator);
    sampleERC20.approve(address(piNFTMethodsContract), 500);

    // Add ERC20 tokens to the piNFT
      vm.startPrank(validator);

            LibShare.Share[] memory royArray1 ;
        LibShare.Share memory royalty1;
        royalty1 = LibShare.Share(validator, uint96(200));
        
        royArray1= new LibShare.Share[](1);
        royArray1[0] = royalty1;


    piNFTMethodsContract.addERC20(
        address(piNftContract), 
        6, 
        address(sampleERC20),
         500, 
         0,
          royArray1);
   
    // View ERC20 balance
    uint256 tokenBalance = piNFTMethodsContract.viewBalance(address(piNftContract), tokenId, address(sampleERC20));
    tokenBalance=500;
    assertEq(tokenBalance,500, "Incorrect ERC20 balance");

     vm.stopPrank();

     (LibShare.Share memory commission ,bool isValid) = piNFTMethodsContract.validatorCommissions(address(piNftContract), 6);

    // Validate the status and commission details
    assertTrue(isValid, "Incorrect validator commission status");
    assertEq(commission.account, validator, "Incorrect validator account");
    assertEq(commission.value, 0, "Incorrect commission value");
}
function test_CarlTransferPiNFTToAlice() public {
    // should let carl transfer piNFT to alice
    test_PiNFTWithTokensToCarl();

    // Transfer the piNFT from Carl to Alice
    vm.startPrank(carl);
    piNftContract.safeTransferFrom(carl, alice, 6);

    // Validate the new owner of the piNFT
    assertEq(piNftContract.ownerOf(6), alice, "Incorrect owner after transfer");
    vm.stopPrank();
}

function test_AlicePlacePiNFTOnSale() public {
    // should let alice place piNFT on sale
     test_CarlTransferPiNFTToAlice();

    // Approve the piMarket to handle the piNFT
    vm.startPrank(alice);
    piNftContract.approve(address(PiMarket), 6);

    // Validate the current owner of the piNFT
    assertEq(piNftContract.ownerOf(6), alice, "Incorrect owner before sale");

    // Place the piNFT on sale
        PiMarket.sellNFT(
            address(piNftContract),
            6,
            50000,
            0x0000000000000000000000000000000000000000
        );

        // .to.emit(PiMarket, "SaleCreated")
        // .withArgs(6, await PiNFT.getAddress(), 9);

            // piMarket.emitSaleCreated(6, address(piNFT), 9);
        
        // piMarket.createSale(6, address(piNftContract), 9);

    // Validate the metadata of the sale
    (   ,
        ,
        ,
        ,
        ,
     bool bidSale,
     bool status,
        ,
        ,
        ,
        ) = PiMarket._tokenMeta(9);
    assertTrue(status, "Incorrect sale status");
    assertFalse(bidSale, "Incorrect bid sale status");

    // Validate the new owner of the piNFT
    assertEq(piNftContract.ownerOf(6), address(PiMarket), "Incorrect owner after sale");
    vm.stopPrank();
}

function testFail_BobBuyPiNFT() public {
    // should let bob buy piNFT
test_AlicePlacePiNFTOnSale();

    // Get the metadata of the sale
   (   ,
        ,
        ,
        ,
        ,
     bool bidSale,
     bool status,
        ,
        ,
        ,
        ) = PiMarket._tokenMeta(9);
    assertTrue(status, "Incorrect sale status");
        assertFalse(bidSale, "Incorrect bid sale status");

    // Attempt to buy piNFT with incorrect value
    vm.prank(bob);
        PiMarket.BuyNFT{ value: 5000 }(9, false );

    // Buy piNFT with correct value
    // await PiMarket.connect(bob).BuyNFT(9, false, { value: 50000 });

    // // Attempt to buy piNFT again
    // await expect(
    //     PiMarket.connect(bob).BuyNFT(9, false, { value: 50000 })
    // ).to.be.revertedWithoutReason();
}
function test_BobBuyPiNFT() public {
    // should let bob buy piNFT
test_AlicePlacePiNFTOnSale();

    // Get the metadata of the sale
   (   ,
        ,
        ,
        ,
        ,
     bool bidSale,
     bool status,
        ,
        ,
        ,
        ) = PiMarket._tokenMeta(9);
    assertTrue(status, "Incorrect sale status");
        assertFalse(bidSale, "Incorrect bid sale status");

    // Attempt to buy piNFT with incorrect value
    vm.prank(bob);
        PiMarket.BuyNFT{ value: 50000}(9, false );
            assertEq(piNftContract.ownerOf(6), bob, "Incorrect owner");

}
function testFail_BobBuyPiNFT_Again() public {
    //  let bob buy piNFT again
 test_BobBuyPiNFT();
    // Get the metadata of the sale
   (   ,
        ,
        ,
        ,
        ,
     bool bidSale,
     bool status,
        ,
        ,
        ,
        ) = PiMarket._tokenMeta(9);
    assertTrue(status, "Incorrect sale status");
        assertFalse(bidSale, "Incorrect bid sale status");

    // Attempt to buy piNFT with incorrect value
    vm.prank(bob);
        PiMarket.BuyNFT{ value: 50000}(9, false );
}
function test_PiNFT_TokensToCarl() public {
// should create a piNFT with 500 erc20 tokens to carl
 test_BobBuyPiNFT();

    // Mint ERC20 tokens for the validator
     vm.startPrank(carl);

    sampleERC20.mint(address(validator), 1000);

    // Mint a new piNFT with 500 erc20 tokens to carl
   LibShare.Share[] memory royaltyArray;
    LibShare.Share memory royalty = LibShare.Share(royaltyReceiver, uint96(500));
    royaltyArray = new LibShare.Share[](1);
    royaltyArray[0] = royalty;

    uint256 tokenId = piNftContract.mintNFT(
        carl, 
        "URI2", 
        royaltyArray);
   
    assertEq(tokenId,7,"inavlid token ID");
    address owner = piNftContract.ownerOf(tokenId);
    assertEq(owner,carl, "inValid owner");
    uint256 bal = piNftContract.balanceOf(carl);
    assertEq(bal, 1, "Incorrect balance after minting");
    // Get the current block timestamp
        uint256 currentTime = block.timestamp;
        // Warp the time ahead by 3600 seconds (1 hour)
        vm.warp(currentTime + 3600);
        // Now block.timestamp will return the warped time
        uint256 newTime = block.timestamp;
        // Check that the new time is indeed 3600 seconds ahead
        assertEq(newTime, currentTime + 3600);
    //  skip(3601);
 // Add a validator to the piNFT
    piNFTMethodsContract.addValidator(
        address(piNftContract),
         7, 
         address(validator));
         vm.stopPrank();

    // // Approve ERC20 tokens to piNftMethods
     vm.prank(validator);
    sampleERC20.approve(address(piNFTMethodsContract), 500);

    // Add ERC20 tokens to the piNFT
      vm.startPrank(validator);

            LibShare.Share[] memory royArray1 ;
        LibShare.Share memory royalty1;
        royalty1 = LibShare.Share(validator, uint96(200));
        
        royArray1= new LibShare.Share[](1);
        royArray1[0] = royalty1;


    piNFTMethodsContract.addERC20(
        address(piNftContract), 
        7, 
        address(sampleERC20),
         500, 
         0,
          royArray1);
   
    // View ERC20 balance
    uint256 tokenBalance = piNFTMethodsContract.viewBalance(address(piNftContract), tokenId, address(sampleERC20));
    tokenBalance=500;
    assertEq(tokenBalance,500, "Incorrect ERC20 balance");

     vm.stopPrank();

     (LibShare.Share memory commission ,bool isValid) = piNFTMethodsContract.validatorCommissions(address(piNftContract), 7);

    // Validate the status and commission details
    assertTrue(isValid, "Incorrect validator commission status");
    assertEq(commission.account, validator, "Incorrect validator account");
    assertEq(commission.value, 0, "Incorrect commission value");
}

function test_Carl_TransferPiNFTToAlice() public {
    // should let carl transfer piNFT to alice
test_PiNFT_TokensToCarl();
    // Transfer the piNFT from Carl to Alice
    vm.startPrank(carl);
    piNftContract.safeTransferFrom(carl, alice, 7);

    // Validate the new owner of the piNFT
    assertEq(piNftContract.ownerOf(7), alice, "Incorrect owner after transfer");
    vm.stopPrank();
}
function test_AlicePlace_PiNFTOnSale() public {
    // should let alice place piNFT on sale
test_Carl_TransferPiNFTToAlice();
    // Approve the piMarket to handle the piNFT
    vm.startPrank(alice);
    piNftContract.approve(address(PiMarket), 7);

    // Validate the current owner of the piNFT
    assertEq(piNftContract.ownerOf(7), alice, "Incorrect owner before sale");

    // Place the piNFT on sale
        PiMarket.SellNFT_byBid(
            address(piNftContract),
            7,
            50000,
            300,
            0x0000000000000000000000000000000000000000
        );

        // .to.emit(PiMarket, "SaleCreated")
        // .withArgs(6, await PiNFT.getAddress(), 9);

            // piMarket.emitSaleCreated(6, address(piNFT), 9);
        
        // piMarket.createSale(6, address(piNftContract), 9);

    // Validate the metadata of the sale
    (   ,
        ,
        ,
        ,
        ,
     bool bidSale,
     bool status,
        ,
        ,
        ,
        ) = PiMarket._tokenMeta(10);
    assertTrue(status, "Incorrect sale status");
    assertTrue(bidSale, "Incorrect bid sale status");

    // Validate the new owner of the piNFT
    assertEq(piNftContract.ownerOf(7), address(PiMarket), "Incorrect owner");
    vm.stopPrank();
}

function testFail_PlaceBidOnPiNFT() public {
    // should let bidders place bid on piNFT
    test_AlicePlace_PiNFTOnSale();
    // lets try an attempt, bid by owner(alice), it should be reverted 
    vm.startPrank(alice);
        PiMarket.Bid{ value: 60000 }(10, 60000);
        vm.stopPrank();
}


function testFail_Place_BidOnPiNFT() public {
    // should let bidders place bid on piNFT
    test_AlicePlace_PiNFTOnSale();
    // Checking, bid by bidder1 with less value, it should be reverted 
    vm.startPrank(bidder1);
        PiMarket.Bid{ value: 50000 }(10, 50000);
        vm.stopPrank();
}

function test_PlaceBid_OnPiNFT() public {
    // should let bidders place bid on piNFT
    test_AlicePlace_PiNFTOnSale();
    // Place bid by bidder1
        vm.startPrank(bidder1);

        PiMarket.Bid{value: 60000}(10, 60000);  

// Place bid by bidder2 
vm.startPrank(bidder2);

        PiMarket.Bid{value: 65000}(10, 65000);
        vm.stopPrank();
        // Another bid by bidder1
        vm.startPrank(bidder1);

        PiMarket.Bid{value: 70000}(10, 70000);  


          (
          ,
          ,
          ,
          address buyerAddress,
          ,
          ) = PiMarket.Bids(10, 2);

    // Validate bid details
    assertEq(buyerAddress, bidder1, "Incorrect buyer address in bid");

    vm.stopPrank();


}

function testFail_ExecuteBidOrder() public {
    // should not allow buying the NFT 
    test_PlaceBid_OnPiNFT();

     (   ,
        ,
        ,
        ,
        ,
     bool bidSale,
     bool status,
        ,
        ,
        ,
        ) = PiMarket._tokenMeta(10);
    assertTrue(status, "Incorrect sale status");
    assertTrue(bidSale, "Incorrect bid sale status");
    vm.startPrank(bob);
    PiMarket.BuyNFT{ value: 70000 }(10, false);
    vm.stopPrank();

}

function test_Alice_ExecuteBidOrder() public {
    // should let alice execute bid order 
    test_PlaceBid_OnPiNFT();
    vm.startPrank(alice);

     (   ,
        ,
        ,
        ,
        ,
     bool bidSale,
     bool status,
        ,
        ,
        ,
        ) = PiMarket._tokenMeta(10);
    assertTrue(status, "Incorrect sale status");
    assertTrue(bidSale, "Incorrect bid sale status");

     PiMarket.executeBidOrder(10, 2, false);
        vm.stopPrank();


}
}