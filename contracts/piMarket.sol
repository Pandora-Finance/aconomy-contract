// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract piMarket is ERC721Holder, ReentrancyGuard {
    using Counters for Counters.Counter;
    Counters.Counter internal _saleIdCounter;

    struct TokenMeta {
        uint256 saleId;
        address tokenContractAddress;
        uint256 tokenId;
        uint256 price;
        // bool directSale;
        // bool bidSale;
        bool status;
        // uint256 bidStartTime;
        // uint256 bidEndTime;
        address currentOwner;
    }

    // // Defines the share of royalties for the address
    // struct Share {
    //     address payable account;
    //     uint96 value;
    // }

    mapping(uint256 => TokenMeta) public _tokenMeta;

    event TokenMetaReturn(TokenMeta data, uint256 id);

    function sellNFT(address _piNFTAddress, uint256 _tokenId, uint256 _price) external  nonReentrant {
        require(msg.sender == ERC721(_piNFTAddress).ownerOf(_tokenId), 'Only token owner can put on sale');

        _saleIdCounter.increment();

        //needs approval on frontend
        ERC721(_piNFTAddress).safeTransferFrom(
        msg.sender,
        address(this),
        _tokenId
        );

        TokenMeta memory meta = TokenMeta(
            _saleIdCounter.current(),
            _piNFTAddress,
            _tokenId,
            _price,
            // true,
            // false,
            true,
            // 0,
            // 0,
            msg.sender
        );

        _tokenMeta[_saleIdCounter.current()] = meta;

        emit TokenMetaReturn(meta, _saleIdCounter.current());
    }

    function BuyNFT(uint256 _saleId) external payable nonReentrant {
        TokenMeta memory meta = _tokenMeta[_saleId];

        // LibShare.Share[] memory royalties = LibRoyalty.retrieveRoyalty(
        // meta.collectionAddress,
        // PNDCAddress,
        // meta.tokenId
        // );

        require(meta.status, 'token must be on sale');
        require(msg.sender != address(0) && msg.sender != meta.currentOwner, 'invalid address');
        // require(!meta.bidSale);
        require(msg.value >= meta.price, 'value less than price');

        transfer(_tokenMeta[_saleId], msg.sender);

        // uint256 sum = msg.value;
        // uint256 val = msg.value;
        // uint256 fee = msg.value / 100;

        // for (uint256 i = 0; i < royalties.length; i++) {
        // uint256 amount = (royalties[i].value * val) / 10000;
        // // address payable receiver = royalties[i].account;
        // (bool royalSuccess, ) = payable(royalties[i].account).call{ value: amount }("");
        // require(royalSuccess, "Transfer failed");
        // sum = sum - amount;
        // }

        (bool isSuccess, ) = payable(meta.currentOwner).call{ value: msg.value }("");
        require(isSuccess, "Transfer failed");
        ERC721(meta.tokenContractAddress).safeTransferFrom(
        address(this),
        msg.sender,
        meta.tokenId
        );
    }

    function cancelSale(uint256 _saleId) external nonReentrant {
    require(msg.sender == _tokenMeta[_saleId].currentOwner, 'Only owner can cancel sale');
    require(_tokenMeta[_saleId].status, 'Token not on sale');

    _tokenMeta[_saleId].status = false;
    ERC721(_tokenMeta[_saleId].tokenContractAddress).safeTransferFrom(
      address(this),
      _tokenMeta[_saleId].currentOwner,
      _tokenMeta[_saleId].tokenId
    );
  }

    function transfer(TokenMeta storage token, address _to ) internal{
        token.currentOwner = _to;
        token.status = false;
        // token.directSale = false ;
        // token.bidSale = false ;

    }
}