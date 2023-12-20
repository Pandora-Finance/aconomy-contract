// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721URIStorageUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721ReceiverUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "./AconomyERC2771Context.sol";
import "./piNFTMethods.sol";

contract validatedNFT is
    ERC721URIStorageUpgradeable,
    ReentrancyGuardUpgradeable,
    PausableUpgradeable,
    AconomyERC2771Context,
    UUPSUpgradeable
{

    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    address public piNFTMethodsAddress;

    event TokenMinted(uint256 tokenId, address to);

    function initialize(address trustedForwarder, address _piNFTmethodAddress) public initializer {
        __ReentrancyGuard_init();
        __UUPSUpgradeable_init();
        AconomyERC2771Context_init(trustedForwarder);
        piNFTMethodsAddress = _piNFTmethodAddress;
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function mintValidatedNFT(
        address _to,
        string memory _uri
    ) public whenNotPaused nonReentrant returns (uint256) {
        uint256 tokenId_ = _tokenIdCounter.current();
        _safeMint(address(this), tokenId_);
        _setTokenURI(tokenId_, _uri);
        piNFTMethods(piNFTMethodsAddress).addValidator(address(this), tokenId_, _to);
        IERC721Upgradeable(address(this)).safeTransferFrom(
                address(this),
                _to,
                tokenId_
        );
        // piNFTMethods(piNFTMethodsAddress).addERC20(address(this), tokenId_, _erc20Contract, _value, _expiration, _commission, royalties);
        _tokenIdCounter.increment();
        emit TokenMinted(tokenId_, _to);
        return tokenId_;
    }

     function exists(uint256 _tokenId) external view returns(bool){
        return _exists(_tokenId);
    }


    function _msgSender()
        internal
        view
        virtual
        override(AconomyERC2771Context, ContextUpgradeable)
        returns (address sender)
    {
        return AconomyERC2771Context._msgSender();
    }

    function _msgData()
        internal
        view
        virtual
        override(AconomyERC2771Context, ContextUpgradeable)
        returns (bytes calldata)
    {
        return AconomyERC2771Context._msgData();
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual returns (bytes4) {
        return this.onERC721Received.selector;
    }

    function _authorizeUpgrade(address) internal override onlyOwner {}

}