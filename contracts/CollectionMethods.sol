// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721URIStorageUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "./Libraries/LibCollection.sol";
import "./utils/LibShare.sol";
import "./CollectionFactory.sol";
import "./piNFTMethods.sol";

contract CollectionMethods is
    Initializable,
    ERC721URIStorageUpgradeable,
    ReentrancyGuardUpgradeable
{
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;
    address public collectionOwner;
    address public collectionFactoryAddress;

    // tokenId => collection royalties
    mapping(uint256 => LibShare.Share[]) public RoyaltiesForValidator;

    event RoyaltiesSet(uint256 indexed tokenId, LibShare.Share[] royalties);

    event TokenMinted(uint256 tokenId, address to);

    /**
     * @notice Modifier enabling only the piNFTMethods contract to call.
     */
    modifier onlyMethods {
        require(
            msg.sender ==
                CollectionFactory(collectionFactoryAddress)
                    .piNFTMethodsAddress()
        ,"methods");
        _;
    }

    /**
     * @notice Contract initializer.
     * @param _collectionOwner The address set to own the collection.
     * @param _collectionFactoryAddress The address of the CollectionFactory contract.
     * @param _name the name of the collection being created.
     * @param _symbol the symbol of the collection being created.
     */
    function initialize(
        address _collectionOwner,
        address _collectionFactoryAddress,
        string memory _name,
        string memory _symbol
    ) external initializer {
        __ERC721_init(_name, _symbol);
        __ERC721URIStorage_init();
        collectionOwner = _collectionOwner;
        collectionFactoryAddress = _collectionFactoryAddress;
    }

    modifier onlyOwnerOfToken(uint256 _tokenId) {
        require(msg.sender == ERC721Upgradeable.ownerOf(_tokenId), "Not Owner");
        _;
    }

    /**
     * @notice Mints an nft to a specified address.
     * @param _to address to mint the piNFT to.
     * @param _uri The uri of the piNFT.
     */
    function mintNFT(address _to, string memory _uri) public returns(uint256 ) {
        require(msg.sender == collectionOwner);
        require(_to != address(0));
        uint256 tokenId_ = _tokenIdCounter.current();
        _safeMint(_to, tokenId_);
        _setTokenURI(tokenId_, _uri);
        _tokenIdCounter.increment();
        emit TokenMinted(tokenId_, _to);
        return tokenId_;
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
        delete RoyaltiesForValidator[_tokenId];
        uint256 sumRoyalties = 0;
        for (uint256 i = 0; i < royalties.length; i++) {
            require(royalties[i].account != address(0x0));
            require(royalties[i].value != 0, "Royalty 0");
            RoyaltiesForValidator[_tokenId].push(royalties[i]);
            sumRoyalties += royalties[i].value;
        }
        require(sumRoyalties <= 4900 - _commission, "overflow");

        emit RoyaltiesSet(_tokenId, royalties);
    }

    function deleteValidatorRoyalties(uint256 _tokenId) external onlyMethods{
        delete RoyaltiesForValidator[_tokenId];
    }

    /**
     * @notice deletes the nft.
     * @param _tokenId The Id of the token.
     */
    function deleteNFT(uint256 _tokenId) external nonReentrant {
        address piNFTMethodsAddress = CollectionFactory(
            collectionFactoryAddress
        ).piNFTMethodsAddress();
        require(
            piNFTMethods(piNFTMethodsAddress).NFTowner(
                address(this),
                _tokenId
            ) == address(0)
        );
        require(ownerOf(_tokenId) == msg.sender);
        _burn(_tokenId);
    }

    function exists(uint256 _tokenId) external view returns(bool){
        return _exists(_tokenId);
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
        return RoyaltiesForValidator[_tokenId];
    }
}
