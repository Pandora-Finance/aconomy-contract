// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "contracts/piNFT.sol";
import "contracts/NFTlendingBorrowing.sol";
import "contracts/Libraries/LibCalculations.sol";
import "contracts/utils/sampleERC20.sol";
import "contracts/AconomyFee.sol";

contract NFTlendingBoroowing is Test {
    NFTlendingBorrowing NFTlendingBorrowingContract;
    piNFT piNftContract;
    SampleERC20 erc20Contract;
    AconomyFee Charge;

    address payable alice = payable(address(0xABCC));
    address payable royaltyReceiver = payable(address(0xBEEF));
    address payable validator = payable(address(0xABBB));

    function setUp() public {
        Charge = new AconomyFee();
        NFTlendingBorrowingContract = new NFTlendingBorrowing(address(Charge));
        piNftContract = new piNFT("Aconomy", "ACO");
        erc20Contract = new SampleERC20();
    }

    function test_name_and_symbol() public {
        assertEq(piNftContract.name(), "Aconomy", "Incorrect name");
        assertEq(piNftContract.symbol(), "ACO", "Incorrect symbol");
    }

    function test_mint_an_ERC_token_to_alice() public returns (uint256) {
        LibShare.Share[] memory royArray;
        LibShare.Share memory royality;
        royality = LibShare.Share(royaltyReceiver, uint96(10));
        royArray = new LibShare.Share[](1);
        royArray[0] = royality;
        string memory uri = "www.adya.com";
        uint256 tokenId = piNftContract.mintNFT(alice, uri, royArray);
        console.log(tokenId);
        assertEq(tokenId, 0, "invalid token Id");
        assertEq(piNftContract.balanceOf(alice), 1, "failed to mint NFt");
        return tokenId;
    }

    function test_mint_ERC20_tokens_to_validator() public {
        erc20Contract.mint(validator, 1000);
        uint256 bal = erc20Contract.balanceOf(validator);
        assertEq(bal, 1000, "Failed to mint ERC20 tokens");
    }

}
