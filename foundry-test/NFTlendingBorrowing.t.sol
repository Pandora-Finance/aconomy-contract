// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "forge-std/console.sol";

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "contracts/piNFT.sol";
import "contracts/NFTlendingBorrowing.sol";
import "contracts/Libraries/LibCalculations.sol";
import "contracts/utils/sampleERC20.sol";
import "contracts/AconomyFee.sol";
import "contracts/NFTlendingBorrowing.sol";
import "contracts/AconomyFee.sol";

contract NftLendingBorrowingTest is Test {

    piNFT piNftContract;
    piNFTMethods piNFTMethodsContract;
    AconomyERC2771Context AconomyERC2771ContextInstance;
    SampleERC20 sampleERC20;
    NFTlendingBorrowing nftLendBorrow;
    AconomyFee aconomyFee;


    address payable alice = payable(address(0xABCD));
    address payable bob = payable(address(0xABCC));
    address payable adya = payable(address(0xABEE));
    address payable royaltyReceiver = payable(address(0xABED));
    address payable validator = payable(address(0xABCD));

    function testDeployandInitialize() public {
        vm.prank(alice);
        aconomyFee = new AconomyFee();
        sampleERC20 = new SampleERC20();
        address implementation = address(new piNFTMethods());

        address proxy = address(new ERC1967Proxy(implementation, ""));
        
          piNFTMethodsContract = piNFTMethods(proxy);
          piNFTMethodsContract.initialize(0xBf175FCC7086b4f9bd59d5EAE8eA67b8f940DE0d);
                address implementation1 = address(new piNFT());
        address tfGelato = 0xBf175FCC7086b4f9bd59d5EAE8eA67b8f940DE0d;

        address proxy1 = address(new ERC1967Proxy(implementation1, ""));
        
         piNftContract = piNFT(proxy1);
         piNftContract.initialize("Aconomy","ACO",address(piNFTMethodsContract),tfGelato);
         assertEq(piNftContract.name(),"Aconomy", "faiii");
         piNftContract.transferOwnership(alice);
         piNFTMethodsContract.transferOwnership(alice);

         

         assertEq(piNftContract.owner(),alice, "not the owner");
         assertEq(piNFTMethodsContract.owner(),alice, "Incorrect owner");
         assertEq(aconomyFee.owner(),alice, "not the owner");


        console.log("piNFTTe111st", address(this));
        console.log("owner", piNftContract.owner());
        console.log("alice222", alice);

        address lendBorrowimplementation = address(new NFTlendingBorrowing());

        address lendBorrowproxy = address(new ERC1967Proxy(lendBorrowimplementation, ""));

        nftLendBorrow = NFTlendingBorrowing(lendBorrowproxy);
        nftLendBorrow.initialize(address(aconomyFee));

         nftLendBorrow.transferOwnership(alice);
         assertEq(nftLendBorrow.owner(),alice, "Incorret owner");
    }


function testFail_NonOwnerCannotSetAconomyFees() public {
    // should not let non owner set aconomy fees 
vm.prank(royaltyReceiver);
aconomyFee.setAconomyNFTLendBorrowFee(100);
  

}
function testFail_NonOwnercannotSetAconomyFees() public {
 // should not let non owner set aconomy fees 
// setting Aconomy Pool Fee by non-owner
  vm.prank(royaltyReceiver);
 aconomyFee.setAconomyPoolFee(100);

}
function testFail_NonOwner_cannotSetAconomyFees() public {
        vm.prank(royaltyReceiver);
  
     aconomyFee.setAconomyPiMarketFee(100);

}
function testSetAconomyFees() public {
    testDeployandInitialize();
    vm.startPrank(alice);
 aconomyFee.setAconomyNFTLendBorrowFee(100);

    aconomyFee.setAconomyPoolFee(100);

    aconomyFee.setAconomyPiMarketFee(100);

    // vm.stopPrank();

}
function test_mintNFT_for_lending() public {
    // mint NFT and list for lending 
    testSetAconomyFees();
    vm.startPrank(alice);

     LibShare.Share[] memory royArray ;
        LibShare.Share memory royalty;
        royalty = LibShare.Share(royaltyReceiver, uint96(500));
        
        royArray= new LibShare.Share[](1);
        royArray[0] = royalty;
        string memory uri = "www.adya.com";
         
       piNftContract.mintNFT(alice, uri, royArray);
        aconomyFee.setAconomyNFTLendBorrowFee(100);
         aconomyFee.AconomyNFTLendBorrowFee();
        uint256 tokenId = 0;
        assertEq(tokenId,0,"incorrect token Id");
        // assertEq(piNFT.balanceOf(alice),1,"incorrect balance");



}
function testFail_listNFTforBorrowing() public {
 // mint NFT and list for lending 
         uint256 tokenId = 0;

nftLendBorrow.listNFTforBorrowing(
            tokenId,
           address(piNftContract),
            200,
            300,
            3600,
            1000000  
    );
 assertEq(tokenId,0,"incorrect token Id");
}

function test_listNFTforBorrowing() public {
    test_mintNFT_for_lending();

 uint256 tokenId = 0;
nftLendBorrow.listNFTforBorrowing(
            tokenId,
           address(piNftContract),
            200,
            300,
            3600,
            200000000000 
    );
    uint256 NFTid = 1;
    assertEq(NFTid,1,"Incorrect NFTid");
}
}