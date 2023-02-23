// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

import "./AconomyFee.sol";
import "./Libraries/LibCalculations.sol";

contract NFTlendingBorrowing is ERC721Holder, ReentrancyGuard {
    using Counters for Counters.Counter;
    uint256 public NFTid;
    address AconomyFeeAddress;
    struct NFTdetail {
        uint256 NFTtokenId;
        address tokenIdOwner;
        address contractAddress;
        uint32 duration;
        uint256 expiration;
        uint256 expectedAmount;
        uint16 percent;
        bool listed;
        bool bidAccepted;
        bool repaid;
    }

    struct BidDetail {
        uint256 bidId;
        uint16 percent;
        uint32 duration;
        uint256 expiration;
        address bidderAddress;
        address ERC20Address;
        uint256 Amount;
        bool withdrawn;
        bool bidAccepted;
    }

    // NFTid => NFTdetail
    mapping(uint256 => NFTdetail) public NFTdetails;

    // NFTid => Bid[]
    mapping(uint256 => BidDetail[]) public Bids;

    // Events
    event AppliedBid(uint256 BidId, BidDetail data, uint256 NFTid);
    event SetPercent(uint256 NFTid, uint16 Percent);
    event SetDuration(uint256 NFTid, uint32 Duration);
    event SetExpiration(uint256 NFTid, uint256 Expiration);
    event SetExpectedAmount(uint256 NFTid, uint256 expectedAmount);
    event NFTlisted(uint256 NFTid, uint256 TokenId, address ContractAddress);
    event repaid(uint256 NFTid, uint256 BidId, uint256 Amount);
    event withdrawn(uint256 NFTid, uint256 BidId, uint256 Amount);
    event AcceptedBid(
        uint256 NFTid,
        uint256 BidId,
        uint256 Amount,
        uint256 ProtocolAmount
    );

    constructor(address _aconomyFee) {
        AconomyFeeAddress = _aconomyFee;
    }

    modifier onlyOwnerOfToken(address _contractAddress, uint256 _tokenId) {
        require(
            msg.sender == ERC721(_contractAddress).ownerOf(_tokenId),
            "Only token owner can execute"
        );
        _;
    }

    modifier NFTOwner(uint256 _NFTid) {
        require(NFTdetails[_NFTid].tokenIdOwner == msg.sender, "Not the owner");
        _;
    }

    // list Your NFT for Borrowing by NFT owner
    function listNFTforBorrowing(
        uint256 _tokenId,
        address _contractAddress,
        uint16 _percent,
        uint32 _duration,
        uint256 _expiration,
        uint256 _expectedAmount
    )
        external
        onlyOwnerOfToken(_contractAddress, _tokenId)
        nonReentrant
        returns (uint256 _NFTid)
    {
        require(
            _contractAddress != address(0),
            "you can't do this with zero address"
        );

        _NFTid = ++NFTid;

        NFTdetail memory details = NFTdetail(
            _tokenId,
            msg.sender,
            _contractAddress,
            _duration,
            _expiration,
            _expectedAmount,
            _percent,
            true,
            false,
            false
        );

        NFTdetails[_NFTid] = details;

        emit NFTlisted(_NFTid, _tokenId, _contractAddress);
    }

    function setPercent(uint256 _NFTid, uint16 _percent)
        public
        NFTOwner(_NFTid)
    {
        if (_percent != NFTdetails[_NFTid].percent) {
            NFTdetails[_NFTid].percent = _percent;

            emit SetPercent(_NFTid, _percent);
        }
    }

    function setDurationTime(uint256 _NFTid, uint32 _duration)
        public
        NFTOwner(_NFTid)
    {
        if (_duration != NFTdetails[_NFTid].duration) {
            NFTdetails[_NFTid].duration = _duration;

            emit SetDuration(_NFTid, _duration);
        }
    }

    function setExpirationTime(uint256 _NFTid, uint256 _expiration)
        public
        NFTOwner(_NFTid)
    {
        uint256 expirationTime = block.timestamp + _expiration;
        if (expirationTime != NFTdetails[_NFTid].expiration) {
            NFTdetails[_NFTid].expiration = expirationTime;

            emit SetExpiration(_NFTid, expirationTime);
        }
    }

    function setExpectedAmount(uint256 _NFTid, uint256 _expectedAmount)
        public
        NFTOwner(_NFTid)
    {
        if (_expectedAmount != NFTdetails[_NFTid].expectedAmount) {
            NFTdetails[_NFTid].expectedAmount = _expectedAmount;

            emit SetExpectedAmount(_NFTid, _expectedAmount);
        }
    }

    // Bid on a NFT by users
    function Bid(
        uint256 _NFTid,
        uint256 _bidAmount,
        address _ERC20Address,
        uint16 _percent,
        uint32 _duration,
        uint256 _expiration
    ) external nonReentrant {
        require(
            _ERC20Address != address(0),
            "you can't do this with zero address"
        );
        require(_bidAmount != 0, "You can't bid with zero Amount");
        NFTdetail memory NFT = NFTdetails[_NFTid];
        require(!NFT.bidAccepted, "Bid Already Accepted");
        require(NFT.listed, "You can't Bid on this NFT");
        BidDetail memory bidDetail = BidDetail(
            Bids[_NFTid].length,
            _percent,
            _duration,
            _expiration,
            msg.sender,
            _ERC20Address,
            _bidAmount,
            false,
            false
        );
        require(
            IERC20(_ERC20Address).transferFrom(
                msg.sender,
                address(this),
                _bidAmount
            ),
            "Unable to tansfer Your ERC20"
        );
        Bids[_NFTid].push(bidDetail);
        emit AppliedBid(Bids[_NFTid].length - 1, bidDetail, _NFTid);
    }

    // Accept Bid by NFT owner
    function AcceptBid(uint256 _NFTid, uint256 _bidId) external nonReentrant {
        BidDetail memory bids = Bids[_NFTid][_bidId];
        NFTdetail memory NFT = NFTdetails[_NFTid];
        require(!bids.withdrawn, "Already withdrawn");
        require(NFT.listed, "It's not listed for Borrowing");
        require(!bids.bidAccepted, "Bid Already Accepted");
        require(NFT.tokenIdOwner == msg.sender, "You can't Accept This Bid");

        NFTdetails[_NFTid].bidAccepted = true;
        Bids[_NFTid][_bidId].bidAccepted = true;

        address AconomyOwner = AconomyFee(AconomyFeeAddress)
            .getAconomyOwnerAddress();

        //Calculating Aconomy Fee
        uint256 amountToAconomy = LibCalculations.percent(
            bids.Amount,
            AconomyFee(AconomyFeeAddress).protocolFee()
        );

        // transfering Amount to NFT Owner
        require(
            IERC20(bids.ERC20Address).transfer(
                msg.sender,
                bids.Amount - amountToAconomy
            ),
            "unable to transfer to receiver"
        );

        // transfering Amount to Protocol Owner
        if (amountToAconomy != 0) {
            require(
                IERC20(bids.ERC20Address).transfer(
                    AconomyOwner,
                    amountToAconomy
                ),
                "Unable to transfer to AconomyOwner"
            );
        }

        //needs approval on frontend
        // transferring NFT to this address
        ERC721(NFT.contractAddress).safeTransferFrom(
            msg.sender,
            address(this),
            NFT.NFTtokenId
        );

        emit AcceptedBid(
            _NFTid,
            _bidId,
            bids.Amount - amountToAconomy,
            amountToAconomy
        );
    }

    // Repay Amount including percentage to Bidder
    function Repay(uint256 _NFTid, uint256 _bidId) external nonReentrant {
        NFTdetail memory NFT = NFTdetails[_NFTid];
        BidDetail memory bids = Bids[_NFTid][_bidId];
        require(NFT.bidAccepted, "Bid Not Accepted yet");
        require(NFT.listed, "It's not listed for Borrowing");
        require(!NFT.repaid, "Already Repaid");

        // Calculate percentage Amount
        uint256 percentageAmount = LibCalculations.percent(
            bids.Amount,
            bids.percent
        );

        // transfering Amount to Bidder
        require(
            IERC20(bids.ERC20Address).transferFrom(
                msg.sender,
                bids.bidderAddress,
                bids.Amount + percentageAmount
            ),
            "unable to transfer to bidder Address"
        );

        NFTdetails[_NFTid].repaid = true;

        // transferring NFT to this address
        ERC721(NFT.contractAddress).safeTransferFrom(
            address(this),
            msg.sender,
            NFT.NFTtokenId
        );
        emit repaid(_NFTid, _bidId, bids.Amount + percentageAmount);
    }

    function withdraw(uint256 _NFTid, uint256 _bidId) external nonReentrant {
        BidDetail memory bid = Bids[_NFTid][_bidId];
        require(!bid.bidAccepted, "Your Bid has been Accepted");
        require(bid.bidderAddress == msg.sender, "You can't withdraw this Bid");
        require(
            block.timestamp > bid.expiration,
            "You can't withdraw this Bid"
        );
        require(
            IERC20(bid.ERC20Address).transfer(msg.sender, bid.Amount),
            "unable to transfer to Bidder Address"
        );
    }

    function removeNFTfromList(uint256 _NFTid) external {
        NFTdetail memory NFT = NFTdetails[_NFTid];
        require(
            msg.sender == ERC721(NFT.contractAddress).ownerOf(NFT.NFTtokenId),
            "Only token owner can execute"
        );
        if (!NFT.listed) {
            revert("It's aiready removed");
        }

        NFTdetails[_NFTid].listed = false;
    }
}
