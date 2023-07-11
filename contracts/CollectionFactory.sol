// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "./utils/LibShare.sol";
import "./Libraries/LibCollection.sol";

contract CollectionFactory is
    OwnableUpgradeable,
    PausableUpgradeable,
    UUPSUpgradeable
{
    using Counters for Counters.Counter;

    //STORAGE START -------------------------------------------------------------------------------------

    /**
     * @notice Deatils for a collection.
     * @param name The name of the collection.
     * @param symbol The symbol of a collection.
     * @param URI The collection uri.
     * @param contractAddress the address of the deployed collection.
     * @param owner The collection owner.
     * @param description The collection description
     */
    struct CollectionMeta {
        string name;
        string symbol;
        string URI;
        address contractAddress;
        address owner;
        string description;
    }

    // collectionId => collwctionMeta
    mapping(uint256 => CollectionMeta) public collections;

    mapping(address => uint256) public addressToCollectionId;

    // collectionId => royalties
    mapping(uint256 => LibShare.Share[]) public royaltiesForCollection;

    uint256 public collectionId;
    address collectionMethodAddress;
    address public piNFTMethodsAddress;

    //STORAGE END ------------------------------------------------------------------------------------------

    event CollectionURISet(uint256 collectionId, string uri);

    event CollectionNameSet(uint256 collectionId, string name);

    event CollectionDescriptionSet(uint256 collectionId, string Description);

    event CollectionSymbolSet(uint256 collectionId, string Symbol);

    event CollectionCreated(uint256 collectionId, address CollectionAddress);

    event CollectionRoyaltiesSet(
        uint256 indexed collectionId,
        LibShare.Share[] royalties
    );

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        address _collectionMethodAddress,
        address _piNFTMethodsAddress
    ) public initializer {
        __Ownable_init();
        __UUPSUpgradeable_init();
        collectionMethodAddress = _collectionMethodAddress;
        piNFTMethodsAddress = _piNFTMethodsAddress;
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    modifier collectionOwner(uint256 _collectionId) {
        require(
            collections[_collectionId].owner == msg.sender,
            "Not the owner"
        );
        _;
    }

    function changeCollectionMethodImplementation(
        address newCollectionMethods
    ) external onlyOwner {
        collectionMethodAddress = newCollectionMethods;
    }

    /**
     * @notice Creates and deploys a collection and returns the collection Id.
     * @dev Returned value is type uint256.
     * @param _name The name of the collection.
     * @param _symbol The symbol of the collection.
     * @param _uri The collection uri.
     * @param _description The collection description.
     * @param royalties The collection royalties.
     * @return collectionId_ .
     */
    function createCollection(
        string memory _name,
        string memory _symbol,
        string calldata _uri,
        string memory _description,
        LibShare.Share[] memory royalties
    ) public whenNotPaused returns (uint256 collectionId_) {
        collectionId_ = ++collectionId;

        //Deploy collection Address
        address collectionAddress = LibCollection.deployCollectionAddress(
            msg.sender,
            address(this),
            _name,
            _symbol,
            collectionMethodAddress
        );

        CollectionMeta memory details = CollectionMeta(
            _name,
            _symbol,
            _uri,
            collectionAddress,
            msg.sender,
            _description
        );

        collections[collectionId_] = details;
        addressToCollectionId[collectionAddress] = collectionId_;
        setRoyaltiesForCollection(collectionId_, royalties);

        emit CollectionCreated(collectionId_, collectionAddress);
    }

    /**
     * @notice Sets the collection royalties.
     * @param _collectionId The id of the collection.
     * @param royalties The royalties to be set for the collection.
     */
    function setRoyaltiesForCollection(
        uint256 _collectionId,
        LibShare.Share[] memory royalties
    ) public whenNotPaused collectionOwner(_collectionId) {
        require(royalties.length <= 10, "Atmost 10 royalties can be added");
        delete royaltiesForCollection[_collectionId];
        uint256 sumRoyalties = 0;
        for (uint256 i = 0; i < royalties.length; i++) {
            require(
                royalties[i].account != address(0x0),
                "Royalty recipient should be present"
            );
            require(royalties[i].value != 0, "Royalty value should be > 0");
            royaltiesForCollection[_collectionId].push(royalties[i]);
            sumRoyalties += royalties[i].value;
        }
        require(sumRoyalties <= 4000, "Sum of Royalties > 40%");

        emit CollectionRoyaltiesSet(_collectionId, royalties);
    }

    /**
     * @notice Sets the collection uri.
     * @param _collectionId The id of the collection.
     * @param _uri The uri to be set.
     */
    function setCollectionURI(
        uint256 _collectionId,
        string calldata _uri
    ) public whenNotPaused collectionOwner(_collectionId) {
        if (
            keccak256(abi.encodePacked(_uri)) !=
            keccak256(abi.encodePacked(collections[_collectionId].URI))
        ) {
            collections[_collectionId].URI = _uri;

            emit CollectionURISet(_collectionId, _uri);
        }
    }

    /**
     * @notice Sets the collection name.
     * @param _collectionId The id of the collection.
     * @param _name The name to be set.
     */
    function setCollectionName(
        uint256 _collectionId,
        string memory _name
    ) public whenNotPaused collectionOwner(_collectionId) {
        if (
            keccak256(abi.encodePacked(_name)) !=
            keccak256(abi.encodePacked(collections[_collectionId].name))
        ) {
            collections[_collectionId].name = _name;

            emit CollectionNameSet(_collectionId, _name);
        }
    }

    /**
     * @notice Sets the collection symbol.
     * @param _collectionId The id of the collection.
     * @param _symbol The collection symbol to be set.
     */
    function setCollectionSymbol(
        uint256 _collectionId,
        string memory _symbol
    ) public whenNotPaused collectionOwner(_collectionId) {
        if (
            keccak256(abi.encodePacked(_symbol)) !=
            keccak256(abi.encodePacked(collections[_collectionId].symbol))
        ) {
            collections[_collectionId].symbol = _symbol;

            emit CollectionSymbolSet(_collectionId, _symbol);
        }
    }

    /**
     * @notice Sets the collection description.
     * @param _collectionId The id of the collection.
     * @param _description The collection description to be set.
     */
    function setCollectionDescription(
        uint256 _collectionId,
        string memory _description
    ) public whenNotPaused collectionOwner(_collectionId) {
        if (
            keccak256(abi.encodePacked(_description)) !=
            keccak256(abi.encodePacked(collections[_collectionId].description))
        ) {
            collections[_collectionId].description = _description;

            emit CollectionDescriptionSet(_collectionId, _description);
        }
    }

    /**
     * @notice Fetches the collection royalties.
     * @dev Returns a LibShare.Share[] array.
     * @param _collectionId The id of the collection.
     * @return A LibShare.Share[] struct array of royalties.
     */
    function getCollectionRoyalties(
        uint256 _collectionId
    ) external view returns (LibShare.Share[] memory) {
        return royaltiesForCollection[_collectionId];
    }

    function _authorizeUpgrade(address) internal override onlyOwner {}
}
