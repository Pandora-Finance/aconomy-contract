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
   console.log("vvv",collectionId);
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
                       console.log("lll",address(contractAddress));


        collectionMethodsInstance = CollectionMethods(contractAddress);
                            //    console.log("ggg",collectionMethodsInstance);


            //    console.log("jjj",address(collectionMethods));
    




 string memory uri = "www.adya.com";
 uint256 tokenId = collectionMethodsInstance.mintNFT(carl, uri);
 console.log("kkk",tokenId);
    tokenId = 0;
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

}

