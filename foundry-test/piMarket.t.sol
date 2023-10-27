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

}


   


