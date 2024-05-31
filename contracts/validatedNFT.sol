// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
// import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721URIStorageUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721ReceiverUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "./piNFTMethods.sol";
import "./utils/LibShare.sol";

contract validatedNFT is
    ERC721URIStorageUpgradeable,
    ReentrancyGuardUpgradeable,
    PausableUpgradeable,
    UUPSUpgradeable,
    OwnableUpgradeable
{

    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    address public piNFTMethodsAddress;

    event TokenMinted(uint256 tokenId, address to);

    event RoyaltiesSetForValidator(
        uint256 indexed tokenId,
        LibShare.Share[] royalties
    );

    function initialize( address _piNFTmethodAddress) public initializer {
        __ReentrancyGuard_init();
        __UUPSUpgradeable_init();
        __Ownable_init();
        piNFTMethodsAddress = _piNFTmethodAddress;
    }

    mapping(uint256 => LibShare.Share[]) internal royaltiesForValidator;

    /**
     * @notice Modifier enabling only the piNFTMethods contract to call.
     */
    modifier onlyMethods {
        require(msg.sender == piNFTMethodsAddress, "methods");
        _;
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
        _tokenIdCounter.increment();
        emit TokenMinted(tokenId_, _to);
        return tokenId_;
    }

     function exists(uint256 _tokenId) external view returns(bool){
        return _exists(_tokenId);
    }

    /**
     * @notice Checks and sets validator royalties.
     * @param _tokenId The Id of the token.
     * @param royalties The royalties to be set.
     */
    function setRoyaltiesForValidator(
        uint256 _tokenId,
        uint256 _commission,
        LibShare.Share[] memory royalties
    ) external onlyMethods{
        require(royalties.length <= 10);
        delete royaltiesForValidator[_tokenId];
        uint256 sumRoyalties = 0;
        for (uint256 i = 0; i < royalties.length; i++) {
            require(royalties[i].account != address(0x0));
            require(royalties[i].value != 0);
            royaltiesForValidator[_tokenId].push(royalties[i]);
            sumRoyalties += royalties[i].value;
        }
        require(sumRoyalties <= 4900 - _commission, "overflow");

        emit RoyaltiesSetForValidator(_tokenId, royalties);
    }

    function getRoyalties(
        uint256 _tokenId
    ) external pure returns (LibShare.Share[] memory) {
        LibShare.Share[] memory share;
        return share ;
    }

    /**
     * @notice deletes the nft.
     * @param _tokenId The Id of the token.
     */
    function deleteNFT(uint256 _tokenId) external whenNotPaused nonReentrant {
        require(
            piNFTMethods(piNFTMethodsAddress).NFTowner(
                address(this),
                _tokenId
            ) == address(0)
        );
        require(ownerOf(_tokenId) == msg.sender);
        _burn(_tokenId);
    }

    /**
     * @notice Fetches the validator royalties.
     * @dev Returns a LibShare.Share[] array.
     * @param _tokenId The id of the token.
     * @return A LibShare.Share[] struct array of royalties.
     */
    function getValidatorRoyalties(
        uint256 _tokenId
    ) external view returns (LibShare.Share[] memory) {
        return royaltiesForValidator[_tokenId];
    }

    function deleteValidatorRoyalties(uint256 _tokenId) external onlyMethods{
        delete royaltiesForValidator[_tokenId];
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