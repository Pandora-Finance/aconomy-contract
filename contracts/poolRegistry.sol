// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "@openzeppelin/contracts/utils/Counters.sol";
import "./AconomyFee.sol";
import "./Libraries/LibPool.sol";
import "./AttestationServices.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

contract poolRegistry is ReentrancyGuardUpgradeable, PausableUpgradeable, OwnableUpgradeable, UUPSUpgradeable {
    using Counters for Counters.Counter;
    using EnumerableSet for EnumerableSet.AddressSet;

    //STORAGE START ------------------------------------------------------------------------------------

    AttestationServices public attestationService;
    bytes32 public lenderAttestationSchemaId;
    bytes32 public borrowerAttestationSchemaId;
    bytes32 private _attestingSchemaId;
    address public AconomyFeeAddress;
    address public FundingPoolAddress;
    //poolId => close or open
    mapping(uint256 => bool) private ClosedPools;

    uint256 public poolCount;

    /**
     * @notice Deatils for a pool.
     * @param poolAddress The address of the pool.
     * @param owner The owner of the pool.
     * @param URI The pool uri.
     * @param APR The desired apr of the pool.
     * @param poolFeePercent The pool fees in bps.
     * @param lenderAttestationRequired Boolean indicating the requirment of lender attestation.
     * @param verifiedLendersForPool The verified lenders of the pool.
     * @param lenderAttestationIds The Id's of the lender attestations.
     * @param paymentCycleDuration The duration of a payment cycle.
     * @param paymentDefaultDuration The duration after which the payment becomes defaulted.
     * @param loanExpirationTime The desired time after which the loan expires.
     * @param borrowerAttestationRequired Boolean indicating the requirment of borrower attestation.
     * @param verifiedBorrowersForPool The verified borrowers of the pool.
     * @param borrowerAttestationIds The Id's of the borrower attestations.
     */
    struct poolDetail {
        address poolAddress;
        address owner;
        string URI;
        uint16 APR;
        uint16 poolFeePercent; // 10000 is 100%
        bool lenderAttestationRequired;
        EnumerableSet.AddressSet verifiedLendersForPool;
        mapping(address => bytes32) lenderAttestationIds;
        uint32 paymentCycleDuration;
        uint32 paymentDefaultDuration;
        uint32 loanExpirationTime;
        bool borrowerAttestationRequired;
        EnumerableSet.AddressSet verifiedBorrowersForPool;
        mapping(address => bytes32) borrowerAttestationIds;
    }
    //poolId => poolDetail
    mapping(uint256 => poolDetail) internal pools;

    //STORAGE END ------------------------------------------------------------------------------------------

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(){
        _disableInitializers();
    }

    function initialize(
        AttestationServices _attestationServices,
        address _AconomyFee,
        address _FundingPoolAddress
    ) public initializer {
        __ReentrancyGuard_init();
        __Ownable_init();
        __Pausable_init();
        __UUPSUpgradeable_init();
        FundingPoolAddress = _FundingPoolAddress;
        attestationService = _attestationServices;
        AconomyFeeAddress = _AconomyFee;

        lenderAttestationSchemaId = _attestationServices
            .getASRegistry()
            .register("(uint256 poolId, address lenderAddress)");
        borrowerAttestationSchemaId = _attestationServices
            .getASRegistry()
            .register("(uint256 poolId, address borrowerAddress)");
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    modifier lenderOrBorrowerSchema(bytes32 schemaId) {
        _attestingSchemaId = schemaId;
        _;
        _attestingSchemaId = bytes32(0);
    }

    modifier ownsPool(uint256 _poolId) {
        require(pools[_poolId].owner == msg.sender, "Not the owner");
        _;
    }

    function changeFundingPoolImplementation(address newFundingPool) external onlyOwner {
        FundingPoolAddress = newFundingPool;
    }

    event poolCreated(
        address indexed owner,
        address poolAddress,
        uint256 poolId
    );
    event SetPaymentCycleDuration(uint256 poolId, uint32 duration);
    event SetPaymentDefaultDuration(uint256 poolId, uint32 duration);
    event SetPoolFee(uint256 poolId, uint16 feePct);
    event SetloanExpirationTime(uint256 poolId, uint32 duration);
    event LenderAttestation(uint256 poolId, address lender);
    event BorrowerAttestation(uint256 poolId, address borrower);
    event LenderRevocation(uint256 poolId, address lender);
    event BorrowerRevocation(uint256 poolId, address borrower);
    event SetPoolURI(uint256 poolId, string uri);
    event SetAPR(uint256 poolId, uint16 APR);
    event poolClosed(uint256 poolId);

    /**
     * @notice Creates a new pool.
     * @param _paymentDefaultDuration Length of time in seconds before a loan is considered in default for non-payment.
     * @param _loanExpirationTime Length of time in seconds before pending loan expire.
     * @param _poolFeePercent The pool fee percentage in bps.
     * @param _apr The desired pool apr.
     * @param _uri The pool uri.
     * @param _requireLenderAttestation Boolean that indicates if lenders require attestation to join pool.
     * @param _requireBorrowerAttestation Boolean that indicates if borrowers require attestation to join pool.
     * @return poolId_ The market ID of the newly created pool.
     */
    function createPool(
        uint32 _paymentDefaultDuration,
        uint32 _loanExpirationTime,
        uint16 _poolFeePercent,
        uint16 _apr,
        string calldata _uri,
        bool _requireLenderAttestation,
        bool _requireBorrowerAttestation
    ) external whenNotPaused returns (uint256 poolId_) {
        require(_apr >= 100, "given apr too low");
        // Increment pool ID counter
        poolId_ = ++poolCount;

        //Deploy Pool Address
        address poolAddress = LibPool.deployPoolAddress(
            msg.sender,
            address(this),
            FundingPoolAddress
        );
        pools[poolId_].poolAddress = poolAddress;
        // Set the pool owner
        pools[poolId_].owner = msg.sender;

        setApr(poolId_, _apr);
        pools[poolId_].paymentCycleDuration = 30 days;
        setPaymentDefaultDuration(poolId_, _paymentDefaultDuration);
        setPoolFeePercent(poolId_, _poolFeePercent);
        setloanExpirationTime(poolId_, _loanExpirationTime);
        setPoolURI(poolId_, _uri);

        // Check if pool requires lender attestation to join
        if (_requireLenderAttestation) {
            pools[poolId_].lenderAttestationRequired = true;
            addLender(poolId_, msg.sender);
        }
        // Check if pool requires borrower attestation to join
        if (_requireBorrowerAttestation) {
            pools[poolId_].borrowerAttestationRequired = true;
            addBorrower(poolId_, msg.sender);
        }

        emit poolCreated(msg.sender, poolAddress, poolId_);
    }

    /**
     * @notice Sets the desired pool apr.
     * @param _poolId The Id of the pool.
     * @param _apr The apr to be set.
     */
    function setApr(uint256 _poolId, uint16 _apr) public ownsPool(_poolId) {
        if (_apr != pools[_poolId].APR) {
            pools[_poolId].APR = _apr;

            emit SetAPR(_poolId, _apr);
        }
    }

    // function setPaymentCycleDuration(uint256 _poolId, uint32 _duration)
    //     public
    //     ownsPool(_poolId)
    // {
    //     if (_duration != pools[_poolId].paymentCycleDuration) {
    //         pools[_poolId].paymentCycleDuration = _duration;

    //         emit SetPaymentCycleDuration(_poolId, _duration);
    //     }
    // }

    /**
     * @notice Sets the pool uri.
     * @param _poolId The Id of the pool.
     * @param _uri The uri to be set.
     */
    function setPoolURI(
        uint256 _poolId,
        string calldata _uri
    ) public ownsPool(_poolId) {
        if (
            keccak256(abi.encodePacked(_uri)) !=
            keccak256(abi.encodePacked(pools[_poolId].URI))
        ) {
            pools[_poolId].URI = _uri;

            emit SetPoolURI(_poolId, _uri);
        }
    }

    /**
     * @notice Sets the pool payment default duration.
     * @param _poolId The Id of the pool.
     * @param _duration The duration to be set.
     */
    function setPaymentDefaultDuration(
        uint256 _poolId,
        uint32 _duration
    ) public ownsPool(_poolId) {
        require(_duration != 0, "default duration cannot be 0");
        if (_duration != pools[_poolId].paymentDefaultDuration) {
            pools[_poolId].paymentDefaultDuration = _duration;

            emit SetPaymentDefaultDuration(_poolId, _duration);
        }
    }

    /**
     * @notice Sets the pool fee percent.
     * @param _poolId The Id of the pool.
     * @param _newPercent The new percent to be set.
     */
    function setPoolFeePercent(
        uint256 _poolId,
        uint16 _newPercent
    ) public ownsPool(_poolId) {
        require(_newPercent <= 1000, "cannot exceed 10%");
        if (_newPercent != pools[_poolId].poolFeePercent) {
            pools[_poolId].poolFeePercent = _newPercent;
            emit SetPoolFee(_poolId, _newPercent);
        }
    }

    /**
     * @notice Sets the desired loan expiration time.
     * @param _poolId The Id of the pool.
     * @param _duration the duration for expiration.
     */
    function setloanExpirationTime(
        uint256 _poolId,
        uint32 _duration
    ) public ownsPool(_poolId) {
        if (_duration != pools[_poolId].loanExpirationTime) {
            pools[_poolId].loanExpirationTime = _duration;

            emit SetloanExpirationTime(_poolId, _duration);
        }
    }

    /**
     * @notice Change the details of existing pool.
     * @param _poolId The Id of the existing pool.
     * @param _paymentDefaultDuration Length of time in seconds before a loan is considered in default for non-payment.
     * @param _loanExpirationTime Length of time in seconds before pending loan expire.
     * @param _poolFeePercent The pool fee percentage in bps.
     * @param _apr The desired pool apr.
     * @param _uri The pool uri.
     */
    function changePoolSetting(
        uint256 _poolId,
        uint32 _paymentDefaultDuration,
        uint32 _loanExpirationTime,
        uint16 _poolFeePercent,
        uint16 _apr,
        string calldata _uri
    ) public ownsPool(_poolId) {
        setApr(_poolId, _apr);
        setPaymentDefaultDuration(_poolId, _paymentDefaultDuration);
        setPoolFeePercent(_poolId, _poolFeePercent);
        setloanExpirationTime(_poolId, _loanExpirationTime);
        setPoolURI(_poolId, _uri);
    }

    /**
     * @notice Adds a lender to the pool.
     * @dev Only called by the pool owner
     * @param _poolId The Id of the pool.
     * @param _lenderAddress The address of the lender.
     */
    function addLender(
        uint256 _poolId,
        address _lenderAddress
    ) public whenNotPaused ownsPool(_poolId) {
        _attestAddress(_poolId, _lenderAddress, true);
    }

    /**
     * @notice Adds a borrower to the pool.
     * @dev Only called by the pool owner
     * @param _poolId The Id of the pool.
     * @param _borrowerAddress The address of the borrower.
     */
    function addBorrower(
        uint256 _poolId,
        address _borrowerAddress
    ) public whenNotPaused ownsPool(_poolId) {
        _attestAddress(_poolId, _borrowerAddress, false);
    }

    /**
     * @notice Removes a lender from the pool.
     * @dev Only called by the pool owner
     * @param _poolId The Id of the pool.
     * @param _lenderAddress The address of the lender.
     */
    function removeLender(
        uint256 _poolId,
        address _lenderAddress
    ) external whenNotPaused ownsPool(_poolId) {
        _revokeAddress(_poolId, _lenderAddress, true);
    }

    /**
     * @notice Removes a borrower from the pool.
     * @dev Only called by the pool owner
     * @param _poolId The Id of the pool.
     * @param _borrowerAddress The address of the borrower.
     */
    function removeBorrower(
        uint256 _poolId,
        address _borrowerAddress
    ) external whenNotPaused ownsPool(_poolId) {
        _revokeAddress(_poolId, _borrowerAddress, false);
    }

    /**
     * @notice Attests an address.
     * @param _poolId The Id of the pool.
     * @param _Address The address being attested.
     * @param _isLender Boolean indicating if the address is a lender
     */
    function _attestAddress(
        uint256 _poolId,
        address _Address,
        bool _isLender
    )
        internal
        nonReentrant
        lenderOrBorrowerSchema(
            _isLender ? lenderAttestationSchemaId : borrowerAttestationSchemaId
        )
    {
        require(msg.sender == pools[_poolId].owner, "Not the pool owner");

        // Submit attestation for borrower to join a pool
        bytes32 uuid = attestationService.attest(
            _Address,
            _attestingSchemaId, // set by the modifier
            abi.encode(_poolId, _Address)
        );

        _attestAddressVerification(_poolId, _Address, uuid, _isLender);
    }

    /**
     * @notice Verifies the address in poolRegistry.
     * @param _poolId The Id of the pool.
     * @param _Address The address being attested.
     * @param _uuid The uuid of the attestation.
     * @param _isLender Boolean indicating if the address is a lender
     */
    function _attestAddressVerification(
        uint256 _poolId,
        address _Address,
        bytes32 _uuid,
        bool _isLender
    ) internal {
        if (_isLender) {
            // Store the lender attestation ID for the pool ID
            pools[_poolId].lenderAttestationIds[_Address] = _uuid;
            // Add lender address to pool set
            //    (bool isSuccess ) =  pools[_poolId].verifiedLendersForPool.add(_Address);
            require(
                pools[_poolId].verifiedLendersForPool.add(_Address),
                "add lender to poolfailed"
            );

            emit LenderAttestation(_poolId, _Address);
        } else {
            // Store the lender attestation ID for the pool ID
            pools[_poolId].borrowerAttestationIds[_Address] = _uuid;
            // Add lender address to pool set
            require(
                pools[_poolId].verifiedBorrowersForPool.add(_Address),
                "add borrower failed, verifiedBorrowersForPool.add failed"
            );

            emit BorrowerAttestation(_poolId, _Address);
        }
    }

    /**
     * @notice Revokes an address.
     * @param _poolId The Id of the pool.
     * @param _address The address being revoked.
     * @param _isLender Boolean indicating if the address is a lender
     */
    function _revokeAddress(
        uint256 _poolId,
        address _address,
        bool _isLender
    ) internal virtual {
        require(msg.sender == pools[_poolId].owner, "Not the pool owner");

        bytes32 uuid = _revokeAddressVerification(_poolId, _address, _isLender);

        attestationService.revoke(uuid);
        // NOTE: Disabling the call to revoke the attestation on EAS contracts
        //        tellerAS.revoke(uuid);
    }

    /**
     * @notice Verifies the address being revoked in poolRegistry.
     * @param _poolId The Id of the pool.
     * @param _Address The address being revoked.
     * @param _isLender Boolean indicating if the address is a lender
     */
    function _revokeAddressVerification(
        uint256 _poolId,
        address _Address,
        bool _isLender
    ) internal virtual returns (bytes32 uuid_) {
        if (_isLender) {
            uuid_ = pools[_poolId].lenderAttestationIds[_Address];
            // Remove lender address from market set
            pools[_poolId].verifiedLendersForPool.remove(_Address);

            emit LenderRevocation(_poolId, _Address);
        } else {
            uuid_ = pools[_poolId].borrowerAttestationIds[_Address];
            // Remove borrower address from market set
            pools[_poolId].verifiedBorrowersForPool.remove(_Address);

            emit BorrowerRevocation(_poolId, _Address);
        }
    }

    function getPoolFee(uint256 _poolId) public view returns (uint16 fee) {
        return pools[_poolId].poolFeePercent;
    }

    /**
     * @notice Checks if the address is a verified borrower.
     * @dev returns a boolean and byte32 uuid.
     * @param _poolId The Id of the pool.
     * @param _borrowerAddress The address being verified.
     * @return isVerified_ boolean and byte32 uuid_.
     */
    function borrowerVerification(
        uint256 _poolId,
        address _borrowerAddress
    ) public view returns (bool isVerified_, bytes32 uuid_) {
        return
            _isAddressVerified(
                _borrowerAddress,
                pools[_poolId].borrowerAttestationRequired,
                pools[_poolId].borrowerAttestationIds,
                pools[_poolId].verifiedBorrowersForPool
            );
    }

    /**
     * @notice Checks if the address is a verified lender.
     * @dev returns a boolean and byte32 uuid.
     * @param _poolId The Id of the pool.
     * @param _lenderAddress The address being verified.
     * @return isVerified_ boolean and byte32 uuid_.
     */
    function lenderVerification(
        uint256 _poolId,
        address _lenderAddress
    ) public view returns (bool isVerified_, bytes32 uuid_) {
        return
            _isAddressVerified(
                _lenderAddress,
                pools[_poolId].lenderAttestationRequired,
                pools[_poolId].lenderAttestationIds,
                pools[_poolId].verifiedLendersForPool
            );
    }

    /**
     * @notice Checks if the address is verified.
     * @dev returns a boolean and byte32 uuid.
     * @param _wltAddress The address being checked.
     * @param _attestationRequired The need for attestation for the pool.
     * @param _stakeholderAttestationIds The uuid's of the verified pool addresses
     * @param _verifiedStakeholderForPool The addresses of the pool
     * @return isVerified_ boolean and byte32 uuid_.
     */
    function _isAddressVerified(
        address _wltAddress,
        bool _attestationRequired,
        mapping(address => bytes32) storage _stakeholderAttestationIds,
        EnumerableSet.AddressSet storage _verifiedStakeholderForPool
    ) internal view returns (bool isVerified_, bytes32 uuid_) {
        if (_attestationRequired) {
            isVerified_ =
                _verifiedStakeholderForPool.contains(_wltAddress) &&
                attestationService.isAddressActive(
                    _stakeholderAttestationIds[_wltAddress]
                );
            uuid_ = _stakeholderAttestationIds[_wltAddress];
        } else {
            isVerified_ = true;
        }
    }

    /**
     * @notice Closes the pool specified.
     * @param _poolId The Id of the pool.
     */
    function closePool(uint256 _poolId) public whenNotPaused ownsPool(_poolId) {
        if (!ClosedPools[_poolId]) {
            ClosedPools[_poolId] = true;

            emit poolClosed(_poolId);
        }
    }

    function ClosedPool(uint256 _poolId) public view returns (bool) {
        return ClosedPools[_poolId];
    }

    function getPaymentCycleDuration(
        uint256 _poolId
    ) public view returns (uint32) {
        return pools[_poolId].paymentCycleDuration;
    }

    function getPaymentDefaultDuration(
        uint256 _poolId
    ) public view returns (uint32) {
        return pools[_poolId].paymentDefaultDuration;
    }

    function getloanExpirationTime(
        uint256 poolId
    ) public view returns (uint32) {
        return pools[poolId].loanExpirationTime;
    }

    function getPoolAddress(uint256 _poolId) public view returns (address) {
        return pools[_poolId].poolAddress;
    }

    function getPoolOwner(uint256 _poolId) public view returns (address) {
        return pools[_poolId].owner;
    }

    function getPoolApr(uint256 _poolId) public view returns (uint16) {
        return pools[_poolId].APR;
    }

    function getAconomyFee() public view returns (uint16) {
        return AconomyFee(AconomyFeeAddress).AconomyPoolFee();
    }

    function getAconomyOwner() public view returns (address) {
        return AconomyFee(AconomyFeeAddress).getAconomyOwnerAddress();
    }

    function _authorizeUpgrade(address) internal override onlyOwner {}
}
