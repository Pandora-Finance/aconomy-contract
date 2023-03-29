// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./piNFT.sol";
import "./CollectionFactory.sol";
import "./CollectionMethods.sol";
import "./utils/LibShare.sol";
import "./Libraries/LibMarket.sol";

contract piMarket is ERC721Holder, ReentrancyGuard {
    using Counters for Counters.Counter;
    Counters.Counter internal _saleIdCounter;
    Counters.Counter private _swapIdCounter;

    address internal feeAddress;

    struct TokenMeta {
        uint256 saleId;
        address tokenContractAddress;
        uint256 tokenId;
        uint256 price;
        bool directSale;
        bool bidSale;
        bool status;
        uint256 bidStartTime;
        uint256 bidEndTime;
        address currentOwner;
        address currency;
    }

    struct BidOrder {
        uint256 bidId;
        uint256 saleId;
        address sellerAddress;
        address buyerAddress;
        uint256 price;
        bool withdrawn;
    }

    struct Swap {
        address initiatorNFTAddress;
        address initiator;
        uint256 initiatorNftId;
        address requestedTokenOwner;
        uint256 requestedTokenId;
        address requestedTokenAddress;
        bool status;
    }

    mapping(uint256 => TokenMeta) public _tokenMeta;
    mapping(uint256 => BidOrder[]) public Bids;
    mapping(uint256 => Swap) public _swaps;

    event SaleCreated(uint256 tokenId, address tokenContract, uint256 saleId);
    event NFTBought(uint256 saleId, address buyer);
    event SaleCancelled(uint256 saleId);
    event BidCreated(uint256 saleId, uint256 bidId);
    event BidExecuted(uint256 saleId, uint256 bidId, uint256 price);
    event BidWithdrawn(uint256 saleId, uint256 bidId);
    event SwapCancelled(uint256 swapId);
    event SwapAccepted(uint256 swapId);
    event SwapProposed(
        address indexed from,
        address indexed to,
        uint256 indexed swapId
    );
    event updatedSalePrice(uint256 saleId, uint256 Price);

    constructor(address _feeAddress) {
        require(_feeAddress != address(0), "Fee address cannot be zero");
        feeAddress = _feeAddress;
    }

    modifier onlyOwnerOfToken(address _contractAddress, uint256 _tokenId) {
        require(
            msg.sender == ERC721(_contractAddress).ownerOf(_tokenId),
            "Only token owner can execute"
        );
        _;
    }

    /*
    @params
    * _contractAddress if _fromCollection is true then collection contract Address and if false piNFT contract Address
    */

    function sellNFT(
        address _contractAddress,
        uint256 _tokenId,
        uint256 _price,
        address _currency
    ) external onlyOwnerOfToken(_contractAddress, _tokenId) nonReentrant {
        _saleIdCounter.increment();
        require(
            _contractAddress != address(0),
            "you can't do this with zero address"
        );

        //needs approval on frontend
        ERC721(_contractAddress).safeTransferFrom(
            msg.sender,
            address(this),
            _tokenId
        );

        TokenMeta memory meta = TokenMeta(
            _saleIdCounter.current(),
            _contractAddress,
            _tokenId,
            _price,
            true,
            false,
            true,
            0,
            0,
            msg.sender,
            _currency
        );

        _tokenMeta[_saleIdCounter.current()] = meta;

        emit SaleCreated(_tokenId, _contractAddress, _saleIdCounter.current());
    }

    function editSalePrice(uint256 _saleId, uint256 _price) public {
        require(
            msg.sender == _tokenMeta[_saleId].currentOwner,
            "You are not the owner"
        );
        require(_tokenMeta[_saleId].status, "You can't edit");
        if (_tokenMeta[_saleId].bidSale) {
            require(Bids[_saleId].length == 0, "Bid has started");
        }

        if (_price != _tokenMeta[_saleId].price) {
            _tokenMeta[_saleId].price = _price;

            emit updatedSalePrice(_saleId, _price);
        }
    }

    function retrieveRoyalty(address _contractAddress, uint256 _tokenId)
        public
        view
        returns (LibShare.Share[] memory)
    {
        return piNFT(_contractAddress).getRoyalties(_tokenId);
    }

    // Get Collection Royalty
    function getCollectionRoyalty(
        address _collectionFactoryAddress,
        uint256 _collectionId
    ) public view returns (LibShare.Share[] memory) {
        return
            CollectionFactory(_collectionFactoryAddress).getCollectionRoyalties(
                _collectionId
            );
    }

    // Get Collection validator Royalty by collection TokenId
    function getCollectionValidatorRoyalty(
        address _collectionAddress,
        uint256 _tokenId
    ) public view returns (LibShare.Share[] memory) {
        return
            CollectionMethods(_collectionAddress).getValidatorRoyalties(
                _tokenId
            );
    }

    // Retrieve validator Royality
    function retrieveValidatorRoyalty(
        address _contractAddress,
        uint256 _tokenId
    ) public view returns (LibShare.Share[] memory) {
        return piNFT(_contractAddress).getValidatorRoyalties(_tokenId);
    }

    function BuyNFT(uint256 _saleId, bool _fromCollection)
        external
        payable
        nonReentrant
    {
        TokenMeta memory meta = _tokenMeta[_saleId];

        LibShare.Share[] memory royalties;
        LibShare.Share[] memory validatorRoyalties;
        if (_fromCollection) {
            royalties = getCollectionRoyalty(
                meta.tokenContractAddress,
                meta.tokenId
            );
            validatorRoyalties = getCollectionValidatorRoyalty(
                meta.tokenContractAddress,
                meta.tokenId
            );
        } else {
            royalties = retrieveRoyalty(
                meta.tokenContractAddress,
                meta.tokenId
            );
            validatorRoyalties = retrieveValidatorRoyalty(
                meta.tokenContractAddress,
                meta.tokenId
            );
        }

        LibMarket.checkSale(_tokenMeta[_saleId]);

        LibMarket.executeSale(_tokenMeta[_saleId], feeAddress, royalties, validatorRoyalties);

        //transfer(_tokenMeta[_saleId], msg.sender);

        ERC721(meta.tokenContractAddress).safeTransferFrom(
            address(this),
            msg.sender,
            meta.tokenId
        );
        emit NFTBought(_saleId, msg.sender);
    }

    function cancelSale(uint256 _saleId) external nonReentrant {
        require(
            msg.sender == _tokenMeta[_saleId].currentOwner,
            "Only owner can cancel sale"
        );
        require(_tokenMeta[_saleId].status, "Token not on sale");

        _tokenMeta[_saleId].price = 0;
        _tokenMeta[_saleId].status = false;
        ERC721(_tokenMeta[_saleId].tokenContractAddress).safeTransferFrom(
            address(this),
            _tokenMeta[_saleId].currentOwner,
            _tokenMeta[_saleId].tokenId
        );
        emit SaleCancelled(_saleId);
    }

    function SellNFT_byBid(
        address _contractAddress,
        uint256 _tokenId,
        uint256 _price,
        uint256 _bidTime,
        address _currency
    ) external onlyOwnerOfToken(_contractAddress, _tokenId) nonReentrant {
        require(
            _contractAddress != address(0),
            "you can't do this with zero address"
        );
        require(_price != 0);
        require(_bidTime != 0);
        _saleIdCounter.increment();

        //needs approval on frontend
        ERC721(_contractAddress).safeTransferFrom(
            msg.sender,
            address(this),
            _tokenId
        );

        TokenMeta memory meta = TokenMeta(
            _saleIdCounter.current(),
            _contractAddress,
            _tokenId,
            _price,
            false,
            true,
            true,
            block.timestamp,
            block.timestamp + _bidTime,
            msg.sender,
            _currency
        );

        _tokenMeta[_saleIdCounter.current()] = meta;

        emit SaleCreated(_tokenId, _contractAddress, _saleIdCounter.current());
    }

    function Bid(uint256 _saleId, uint256 _bidPrice) external payable {
        if(_tokenMeta[_saleId].currency == address(0)) {
            require(msg.value == _bidPrice);
        }
        
        LibMarket.checkBid(_tokenMeta[_saleId], _bidPrice);

        require(block.timestamp <= _tokenMeta[_saleId].bidEndTime);
        _tokenMeta[_saleId].price = _bidPrice;
        //  require(_timeOfAuction[_saleId] >= block.timestamp,"Auction Over");

        if(_tokenMeta[_saleId].currency != address(0)) {
            IERC20(_tokenMeta[_saleId].currency).transferFrom(msg.sender, address(this), _bidPrice);
        }

        BidOrder memory bid = BidOrder(
            Bids[_saleId].length,
            _saleId,
            _tokenMeta[_saleId].currentOwner,
            msg.sender,
            _bidPrice,
            false
        );
        Bids[_saleId].push(bid);

        emit BidCreated(_saleId, Bids[_saleId].length - 1);
    }

    function executeBidOrder(
        uint256 _saleId,
        uint256 _bidOrderID,
        bool _fromCollection
    ) external nonReentrant {

        LibShare.Share[] memory royalties;
        LibShare.Share[] memory validatorRoyalties;
        if (_fromCollection) {
            royalties = getCollectionRoyalty(
                _tokenMeta[_saleId].tokenContractAddress,
                _tokenMeta[_saleId].tokenId
            );
            validatorRoyalties = getCollectionValidatorRoyalty(
                _tokenMeta[_saleId].tokenContractAddress,
                _tokenMeta[_saleId].tokenId
            );
        } else {
            royalties = retrieveRoyalty(
                _tokenMeta[_saleId].tokenContractAddress,
                _tokenMeta[_saleId].tokenId
            );
            validatorRoyalties = retrieveValidatorRoyalty(
                _tokenMeta[_saleId].tokenContractAddress,
                _tokenMeta[_saleId].tokenId
            );
        }

        LibMarket.executeBid(_tokenMeta[_saleId], Bids[_saleId][_bidOrderID], royalties, validatorRoyalties, feeAddress);

        ERC721(_tokenMeta[_saleId].tokenContractAddress).safeTransferFrom(
            address(this),
            Bids[_saleId][_bidOrderID].buyerAddress,
            _tokenMeta[_saleId].tokenId
        );

        emit BidExecuted(_saleId, _bidOrderID, Bids[_saleId][_bidOrderID].price);
    }

    function withdrawBidMoney(uint256 _saleId, uint256 _bidId)
        external
        nonReentrant
    {
        LibMarket.withdrawBid(_tokenMeta[_saleId], Bids[_saleId][_bidId]);
        emit BidWithdrawn(_saleId, _bidId);
    }

    // function transfer(TokenMeta storage token, address _to) internal {
    //     token.currentOwner = _to;
    //     token.status = false;
    //     token.directSale = false;
    //     token.bidSale = false;
    // }

    // who will be making request, his tokenId will be token1
    function makeSwapRequest(
        address contractAddress1,
        address contractAddress2,
        uint256 token1,
        uint256 token2
    )
        public
        onlyOwnerOfToken(contractAddress1, token1)
        nonReentrant
        returns (uint256)
    {
        require(
            contractAddress1 != address(0),
            "you can't do this with zero address"
        );

        require(
            contractAddress2 != address(0),
            "you can't do this with zero address"
        );
        address token2Owner = ERC721(contractAddress2).ownerOf(token2);
        require(token2Owner != msg.sender, "Cannot Swap Between Your Tokens");
        uint256 swapsId = _swapIdCounter.current();
        ERC721(contractAddress1).safeTransferFrom(
            msg.sender,
            address(this),
            token1
        );

        Swap memory swap = Swap(
            contractAddress1,
            msg.sender,
            token1,
            token2Owner,
            token2,
            contractAddress2,
            true
        );

        _swaps[swapsId] = swap;

        _swapIdCounter.increment();

        emit SwapProposed(msg.sender, token2Owner, swapsId);

        return swapsId;
    }

    // cancle swap by initiator
    function cancelSwap(uint256 _swapId) public nonReentrant {
        require(
            msg.sender == _swaps[_swapId].initiator,
            "Only owner can cancel sale"
        );
        require(_swaps[_swapId].status, "Token not on swap");
        _swaps[_swapId].status = false;
        ERC721(_swaps[_swapId].initiatorNFTAddress).safeTransferFrom(
            address(this),
            _swaps[_swapId].initiator,
            _swaps[_swapId].initiatorNftId
        );

        emit SwapCancelled(_swapId);
    }

    // NFTcontractAddress will be of tokenId2
    function acceptSwapRequest(uint256 swapId) public nonReentrant {
        Swap storage swap = _swaps[swapId];
        require(swap.status, "token must be on swap");
        require(swap.requestedTokenOwner == msg.sender, "Only owner can accept swap");
        if(ERC721(swap.initiatorNFTAddress).ownerOf(swap.initiatorNftId) == swap.initiator) {
            swap.status = false;
            revert("requesting token owner has changed");
        }
        ERC721(swap.initiatorNFTAddress).safeTransferFrom(
            address(this),
            msg.sender,
            swap.initiatorNftId
        );
        ERC721(swap.requestedTokenAddress).safeTransferFrom(
            msg.sender,
            swap.initiator,
            swap.requestedTokenId
        );
        swap.status = false;
        emit SwapAccepted(swapId);
    }
}
