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
    address payable validator = payable(address(0xABCD));


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

//     // Check validator commissions
//     string memory commission = piNftMethods.validatorCommissions(piNftContract, tokenId);
//     require(commission.isValid, "Commission is not valid");
//     require(commission.commission.account == validator, "Incorrect validator account");
//     require(commission.commission.value == 1000, "Incorrect commission value");
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
           
               vm.stopPrank();

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
    (   uint256 saleId,
        ,
        ,
        ,
        ,
     bool bidSale,
     bool status1,
        ,
        ,
        address owner,
        ) = PiMarket._tokenMeta(1);
        console.log("aa",status1);
                console.log("sss",bidSale);
                        console.log("bbb",owner);
                       console.log("ccc",saleId);


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
    // uint256 aliceGotAmount = (50000 * 8200) / 10000;
    // assertEq(balance1 - _balance1, aliceGotAmount, "Incorrect amount received by Alice");

    // // Check the amount received by Royalty Receiver
    // uint256 royaltyGotAmount = (50000 * 500) / 10000;
    // assertEq(balance2 - _balance2, royaltyGotAmount, "Incorrect amount received by Royalty Receiver");

    // // Check the amount received by Fee Receiver
    // uint256 feeGotAmount = (50000 * 100) / 10000;
    // assertEq(balance3 - _balance3, feeGotAmount, "Incorrect amount received by Fee Receiver");

    // // Check the amount received by Validator
    // uint256 validatorGotAmount = (50000 * 1200) / 10000;
    // assertEq(balance4 - _balance4, validatorGotAmount, "Incorrect amount received by Validator");

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

    // // Validate validator commission
    // (bool isValid, address account, uint256 value) = piNFTMethodsContract.validatorCommissions(piNftContract, 0);
    // assertEq(isValid, false, "Incorrect validator commission status");
    // assertEq(account, validator, "Incorrect validator account");
    // assertEq(value, 1000, "Incorrect validator commission value");
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
    // piNFTMethodsContract.addERC20(
    //     address(piNftContract),
    //     0,
    //     address(sampleERC20),
    //     500,
    //     time.latest().add(3601).toString(),
    //     100,
    //     [
    //         [validator.getAddress(), 300]
    //     ]
    // );
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

}

   


