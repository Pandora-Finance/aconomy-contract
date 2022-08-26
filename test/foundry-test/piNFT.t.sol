// // SPDX-License-Identifier: UNLICENSED
// pragma solidity ^0.8.0;

// import "forge-std/Test.sol";
// import "forge-std/console.sol";


// import "contracts/piNFT.sol";
// import "contracts/utils/sampleERC20.sol";
// import "contracts/utils/LibShare.sol";

//  contract PiNFTTest is Test {
//     piNFT piNftContract;
//     SampleERC20 erc20Contract;
    
//     address payable alice = payable(address(0xABCD));
//     address payable bob = payable(address(0xABCC));
//     address payable royaltyReceiver = payable(address(0xBEEF));
//     address payable validator = payable(address(0xABBB));

//     function setUp() public {
//         piNftContract = new piNFT("Aconomy", "ACO");
//         erc20Contract = new SampleERC20();
       
//     }
  
//     function test_name_and_symbol() public {
//         //  emit log_address(address(this));
//         //  console.log(address(piNftContract));
//         assertEq(piNftContract.name(), "Aconomy", "Incorrect name");
//         assertEq(piNftContract.symbol(), "ACO", "Incorrect symbol");
//         // console.log(alice);
//         // assertEq(cont.viewBalance(1, address(0xEb5a964C7B3ebB6F6100D433De8BD223c121d804)), 0);
//     }

//     function test_mint_an_erc721_token_to_alice() public returns(uint256){
     
//         LibShare.Share[] memory royArray ;
//         LibShare.Share memory royalty;
//         royalty = LibShare.Share(royaltyReceiver, uint96(10));
        
//         royArray= new LibShare.Share[](1);
//         royArray[0] = royalty;
//         string memory uri = "www.sk.com";
         
//         uint256 tokenId = piNftContract.mintNFT(alice, uri, royArray);
//         console.log(tokenId);
//         assertEq(tokenId, 0,"Invalid token Id");
//         assertEq(piNftContract.balanceOf(alice), 1, "Failed to mint NFT");
//         return tokenId;
//     }

//     function test_fetch_token_uri_and_royalties() public {
//         uint256 tokenId = test_mint_an_erc721_token_to_alice();
//         console.log(tokenId);
//         string memory _uri = piNftContract.tokenURI(tokenId);
//         assertEq(_uri, "www.sk.com", "Invalid tokenURI");

//         LibShare.Share[] memory temp = piNftContract.getRoyalties(tokenId);
//         console.log(temp[0].account);
//         assertEq(temp[0].account, royaltyReceiver, "Incorrect Royalities Address");
//         assertEq(temp[0].value, 10, "Incorrect Royalities value");
//     }

//     function test_mint_ERC20_tokens_to_validator() public{
//         erc20Contract.mint(validator, 1000);
//         uint256 bal = erc20Contract.balanceOf(validator);
//         assertEq(bal, 1000, "Failed to mint ERC20 tokens");
//     }

//     function test_validator_add_ERC20_tokens_to_alice_NFT() public{
//         uint256 tokenId = test_mint_an_erc721_token_to_alice();
//         test_mint_ERC20_tokens_to_validator();

//         vm.prank(validator);
//         erc20Contract.approve(address(piNftContract), 500);
//         vm.prank(validator);
//         piNftContract.addERC20(validator, tokenId, address(erc20Contract), 500);
//         uint256 tokenBal =  piNftContract.viewBalance(tokenId, address(erc20Contract));
//         uint256 validatorBal = erc20Contract.balanceOf(validator);
//         assertEq(tokenBal, 500, "Failed to add ERC20 tokens into NFT");
//         assertEq(validatorBal, 500, "Validator's balance not reduced");
//     }

//     function testFail_transfer_NFT_to_bob_without_switching_to_Alice() public{
//         test_validator_add_ERC20_tokens_to_alice_NFT();
//         piNftContract.safeTransferFrom(alice, bob, 0);
//         assertEq(piNftContract.ownerOf(0), bob, "Unable to transfer NFT to Bob");
//     }

//     function test_transfer_NFT_to_bob() public{
//         test_validator_add_ERC20_tokens_to_alice_NFT();
//         vm.prank(alice);
//         piNftContract.safeTransferFrom(alice, bob, 0);
//         assertEq(piNftContract.ownerOf(0), bob, "Not transferred NFT to Bob");
//     }

//     function testFail_alice_disintegrate_NFT_and_ERC20_tokens() public{
//         test_transfer_NFT_to_bob();
//         vm.prank(alice);
//         piNftContract.transferERC20(0, validator, address(erc20Contract), 500);
//          assertEq(
//                  piNftContract.viewBalance(0, address(erc20Contract)),
//                 0,
//                 "Failed to remove ERC20 tokens from NFT"
//             );
//          assertEq(
//             erc20Contract.balanceOf(validator),
//             1000,
//             "Failed to transfer ERC20 tokens to validator"
//         );
//     }


//     function test_bob_disintegrate_NFT_and_ERC20_tokens() public{
//         test_transfer_NFT_to_bob();
//         vm.prank(bob);
//         piNftContract.transferERC20(0, validator, address(erc20Contract), 500);
//          assertEq(
//                  piNftContract.viewBalance(0, address(erc20Contract)),
//                 0,
//                 "Failed to remove ERC20 tokens from NFT"
//             );
//          assertEq(
//             erc20Contract.balanceOf(validator),
//             1000,
//             "Failed to transfer ERC20 tokens to validator"
//         );
//     }
// }