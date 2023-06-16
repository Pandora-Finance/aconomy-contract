// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

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

    /**
     * @notice Deatils for a listed NFT.
     * @param NFTtokenId The Id of the token.
     * @param tokenIdOwner The owner of the nft.
     * @param contractAddress The contract address.
     * @param duration The expected duration.
     * @param expectedAmount The expected amount.
     * @param percent The expected interest percent in bps.
     * @param listed Boolean indicating if the nft is listed.
     * @param bidAccepted Boolean indicating if a bid has been accepted.
     * @param repaid Boolean indicating if amount has been repaid.
     */
    struct NFTdetail {
        uint256 NFTtokenId;
        address tokenIdOwner;
        address contractAddress;
        uint32 duration;
        uint256 expectedAmount;
        uint16 percent;
        bool listed;
        bool bidAccepted;
        bool repaid;
    }

    /**
     * @notice Deatils for a bid.
     * @param bidId The Id of the bid.
     * @param percent The interest percentage.
     * @param duration The duration of the bid.
     * @param expiration The duration within which bid has to be accepted.
     * @param bidderAddress The address of the bidder.
     * @param ERC20Address The address of the erc20 funds.
     * @param Amount The amount of funds.
     * @param protocolFee The protocol fee when creating a bid.
     * @param withdrawn Boolean indicating if a bid has been withdrawn.
     * @param bidAccepted Boolean indicating if the bid has been accepted.
     */
    struct BidDetail {
        uint256 bidId;
        uint16 percent;
        uint32 duration;
        uint256 expiration;
        address bidderAddress;
        address ERC20Address;
        uint256 Amount;
        uint16 protocolFee;
        bool withdrawn;
        bool bidAccepted;
    }

    // NFTid => NFTdetail
    mapping(uint256 => NFTdetail) public NFTdetails;

    // NFTid => Bid[]
    mapping(uint256 => BidDetail[]) public Bids;

    // Events
    event AppliedBid(uint256 BidId, uint256 NFTid);
    event PercentSet(uint256 NFTid, uint16 Percent);
    event DurationSet(uint256 NFTid, uint32 Duration);
    event ExpectedAmountSet(uint256 NFTid, uint256 expectedAmount);
    event NFTlisted(uint256 NFTid, uint256 TokenId, address ContractAddress);
    event repaid(uint256 NFTid, uint256 BidId, uint256 Amount);
    event Withdrawn(uint256 NFTid, uint256 BidId, uint256 Amount);
    event NFTRemoved(uint256 NFTId);
    event BidRejected(
        uint256 NFTid,
        uint256 BidId,
        address recieverAddress,
        uint256 Amount
    );
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

    /**
     * @notice Lists the nft for borrowing.
     * @param _tokenId The Id of the token.
     * @param _contractAddress The address of the token contract.
     * @param _percent The interest percentage expected.
     * @param _duration The duration of the loan.
     * @param _expectedAmount The loan amount expected.
     */
    function listNFTforBorrowing(
        uint256 _tokenId,
        address _contractAddress,
        uint16 _percent,
        uint32 _duration,
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
            _expectedAmount,
            _percent,
            true,
            false,
            false
        );

        NFTdetails[_NFTid] = details;

        emit NFTlisted(_NFTid, _tokenId, _contractAddress);
    }

    /**
     * @notice Sets the expected percentage.
     * @param _NFTid The Id of the NFTDetail
     * @param _percent The interest percentage expected.
     */
    function setPercent(
        uint256 _NFTid,
        uint16 _percent
    ) public NFTOwner(_NFTid) {
        if (_percent != NFTdetails[_NFTid].percent) {
            NFTdetails[_NFTid].percent = _percent;

            emit PercentSet(_NFTid, _percent);
        }
    }

    /**
     * @notice Sets the expected duration.
     * @param _NFTid The Id of the NFTDetail
     * @param _duration The duration expected.
     */
    function setDurationTime(
        uint256 _NFTid,
        uint32 _duration
    ) public NFTOwner(_NFTid) {
        if (_duration != NFTdetails[_NFTid].duration) {
            NFTdetails[_NFTid].duration = _duration;

            emit DurationSet(_NFTid, _duration);
        }
    }

    /**
     * @notice Sets the expected loan amount.
     * @param _NFTid The Id of the NFTDetail
     * @param _expectedAmount The expected amount.
     */
    function setExpectedAmount(
        uint256 _NFTid,
        uint256 _expectedAmount
    ) public NFTOwner(_NFTid) {
        if (_expectedAmount != NFTdetails[_NFTid].expectedAmount) {
            NFTdetails[_NFTid].expectedAmount = _expectedAmount;

            emit ExpectedAmountSet(_NFTid, _expectedAmount);
        }
    }

    /**
     * @notice Allows a user to bid a loan for an nft.
     * @param _NFTid The Id of the NFTDetail.
     * @param _bidAmount The amount being bidded.
     * @param _ERC20Address The address of the tokens being bidded.
     * @param _percent The interest percentage for the loan bid.
     * @param _duration The duration of the loan bid.
     * @param _expiration The timestamp after which the bid can be withdrawn.
     */
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
        require(!NFTdetails[_NFTid].bidAccepted, "Bid Already Accepted");
        require(NFTdetails[_NFTid].listed, "You can't Bid on this NFT");

        uint16 fee = AconomyFee(AconomyFeeAddress).AconomyNFTLendBorrowFee();

        BidDetail memory bidDetail = BidDetail(
            Bids[_NFTid].length,
            _percent,
            _duration,
            _expiration + block.timestamp,
            msg.sender,
            _ERC20Address,
            _bidAmount,
            fee,
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
        emit AppliedBid(Bids[_NFTid].length - 1, _NFTid);
    }

    /**
     * @notice Accepts the specified bid.
     * @param _NFTid The Id of the NFTDetail
     * @param _bidId The Id of the bid.
     */
    function AcceptBid(uint256 _NFTid, uint256 _bidId) external nonReentrant {
        require(!Bids[_NFTid][_bidId].withdrawn, "Already withdrawn");
        require(NFTdetails[_NFTid].listed, "It's not listed for Borrowing");
        require(!NFTdetails[_NFTid].bidAccepted, "bid already accepted");
        require(!Bids[_NFTid][_bidId].bidAccepted, "Bid Already Accepted");
        require(
            NFTdetails[_NFTid].tokenIdOwner == msg.sender,
            "You can't Accept This Bid"
        );

        NFTdetails[_NFTid].bidAccepted = true;
        Bids[_NFTid][_bidId].bidAccepted = true;

        address AconomyOwner = AconomyFee(AconomyFeeAddress)
            .getAconomyOwnerAddress();

        //Calculating Aconomy Fee
        uint256 amountToAconomy = LibCalculations.percent(
            Bids[_NFTid][_bidId].Amount,
            Bids[_NFTid][_bidId].protocolFee
        );

        // transfering Amount to NFT Owner
        require(
            IERC20(Bids[_NFTid][_bidId].ERC20Address).transfer(
                msg.sender,
                Bids[_NFTid][_bidId].Amount - amountToAconomy
            ),
            "unable to transfer to receiver"
        );

        // transfering Amount to Protocol Owner
        if (amountToAconomy != 0) {
            require(
                IERC20(Bids[_NFTid][_bidId].ERC20Address).transfer(
                    AconomyOwner,
                    amountToAconomy
                ),
                "Unable to transfer to AconomyOwner"
            );
        }

        //needs approval on frontend
        // transferring NFT to this address
        ERC721(NFTdetails[_NFTid].contractAddress).safeTransferFrom(
            msg.sender,
            address(this),
            NFTdetails[_NFTid].NFTtokenId
        );

        emit AcceptedBid(
            _NFTid,
            _bidId,
            Bids[_NFTid][_bidId].Amount - amountToAconomy,
            amountToAconomy
        );
    }

    /**
     * @notice Rejects the specified bid.
     * @param _NFTid The Id of the NFTDetail
     * @param _bidId The Id of the bid.
     */
    function rejectBid(uint256 _NFTid, uint256 _bidId) external nonReentrant {
        require(!Bids[_NFTid][_bidId].withdrawn, "Already withdrawn");
        require(!Bids[_NFTid][_bidId].bidAccepted, "Bid Already Accepted");
        require(
            NFTdetails[_NFTid].tokenIdOwner == msg.sender,
            "You can't Accept This Bid"
        );
        Bids[_NFTid][_bidId].withdrawn = true;
        require(
            IERC20(Bids[_NFTid][_bidId].ERC20Address).transfer(
                Bids[_NFTid][_bidId].bidderAddress,
                Bids[_NFTid][_bidId].Amount
            ),
            "unable to transfer to bidder Address"
        );
        emit BidRejected(
            _NFTid,
            _bidId,
            Bids[_NFTid][_bidId].bidderAddress,
            Bids[_NFTid][_bidId].Amount
        );
    }

    /**
     * @notice Repays the loan amount.
     * @param _NFTid The Id of the NFTDetail
     * @param _bidId The Id of the bid.
     */
    function Repay(uint256 _NFTid, uint256 _bidId) external nonReentrant {
        require(NFTdetails[_NFTid].bidAccepted, "Bid Not Accepted yet");
        require(NFTdetails[_NFTid].listed, "It's not listed for Borrowing");
        require(Bids[_NFTid][_bidId].bidAccepted, "Bid not Accepted");
        require(!NFTdetails[_NFTid].repaid, "Already Repaid");

        // Calculate percentage Amount
        uint256 percentageAmount = LibCalculations.percent(
            Bids[_NFTid][_bidId].Amount,
            Bids[_NFTid][_bidId].percent
        );

        // transfering Amount to Bidder
        require(
            IERC20(Bids[_NFTid][_bidId].ERC20Address).transferFrom(
                msg.sender,
                Bids[_NFTid][_bidId].bidderAddress,
                Bids[_NFTid][_bidId].Amount + percentageAmount
            ),
            "unable to transfer to bidder Address"
        );

        NFTdetails[_NFTid].repaid = true;
        NFTdetails[_NFTid].listed = false;

        // transferring NFT to this address
        ERC721(NFTdetails[_NFTid].contractAddress).safeTransferFrom(
            address(this),
            msg.sender,
            NFTdetails[_NFTid].NFTtokenId
        );
        emit repaid(
            _NFTid,
            _bidId,
            Bids[_NFTid][_bidId].Amount + percentageAmount
        );
    }

    /**
     * @notice Withdraws the bid amount after expiration.
     * @param _NFTid The Id of the NFTDetail
     * @param _bidId The Id of the bid.
     */
    function withdraw(uint256 _NFTid, uint256 _bidId) external nonReentrant {
        require(
            Bids[_NFTid][_bidId].bidderAddress == msg.sender,
            "You can't withdraw this Bid"
        );
        require(!Bids[_NFTid][_bidId].withdrawn, "Already withdrawn");
        require(
            !Bids[_NFTid][_bidId].bidAccepted,
            "Your Bid has been Accepted"
        );
        require(
            block.timestamp > Bids[_NFTid][_bidId].expiration,
            "Can't withdraw Bid before expiration"
        );
        require(
            IERC20(Bids[_NFTid][_bidId].ERC20Address).transfer(
                msg.sender,
                Bids[_NFTid][_bidId].Amount
            ),
            "unable to transfer to Bidder Address"
        );
        Bids[_NFTid][_bidId].withdrawn = true;
        emit Withdrawn(_NFTid, _bidId, Bids[_NFTid][_bidId].Amount);
    }

    /**
     * @notice Removes the nft from listing.
     * @param _NFTid The Id of the NFTDetail
     */
    function removeNFTfromList(uint256 _NFTid) external {
        require(
            msg.sender ==
                ERC721(NFTdetails[_NFTid].contractAddress).ownerOf(
                    NFTdetails[_NFTid].NFTtokenId
                ),
            "Only token owner can execute"
        );
        require(
            NFTdetails[_NFTid].bidAccepted == false,
            "bid has been accepted"
        );
        if (!NFTdetails[_NFTid].listed) {
            revert("It's aiready removed");
        }

        NFTdetails[_NFTid].listed = false;

        emit NFTRemoved(_NFTid);
    }
}
