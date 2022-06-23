// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract piNFT is ERC721URIStorage, ERC721Holder{

    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;
    Counters.Counter private _piIdCounter;

    // piId => tokenId
    mapping(uint256 => uint256) internal piIdToTokenId;

    // piId => token owner
    mapping(uint256 => address) internal piIdToTokenOwner;

    // piId => childTokenId
    mapping(uint256 => uint256) internal piIdToChildTokenId; 

    // token owner address => token count
    mapping(address => uint256) internal tokenOwnerToPiTokenCount;

    constructor(string memory _name, string memory _symbol) ERC721(_name, _symbol) {}

    event piNFTMinted(uint256 indexed piId, uint256 indexed tokenId, address indexed to);

    function mintPiNFT(address _to, string memory _uri) public returns (uint256, uint256) {
        _piIdCounter.increment();
        uint256 piId_ = _piIdCounter.current();
        uint256 tokenId_ = _tokenIdCounter.current();
        _safeMint(_to, tokenId_);
        _setTokenURI(tokenId_, _uri);
        _tokenIdCounter.increment();
        piIdToTokenId[piId_] = tokenId_;
        // piIdToTokenOwner[piId_] = _to;
        // tokenOwnerToPiTokenCount[_to]++;
        emit piNFTMinted(piId_, tokenId_, _to);
        return (piId_, tokenId_);
    }

    function mintNFT(address _to, string memory _uri) public returns (uint256) {
        uint256 tokenId_ = _tokenIdCounter.current();
        _safeMint(_to, tokenId_);
        _setTokenURI(tokenId_, _uri);
        _tokenIdCounter.increment();
        return tokenId_;
    }

    function nftIntoPiNFT(uint256 _nftId, uint256 _piId) public {
        require(ownerOf(_nftId) == msg.sender, "Only owner can transfer");
        safeTransferFrom(msg.sender, address(this), _nftId);
        piIdToChildTokenId[_piId] = _nftId;
    }

    function viewChildNFT(uint256 _piId) public view returns (uint256) {
        return piIdToChildTokenId[_piId];
    }
}