// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

 contract validatorStake is
    OwnableUpgradeable,
    PausableUpgradeable,
    ReentrancyGuardUpgradeable,
    UUPSUpgradeable
{
    using Counters for Counters.Counter;
    using SafeERC20 for IERC20;

    struct StakeDetail {
        uint256 stakedAmount;
        uint256 refundedAmount;
        address ERC20Token;
    }

    mapping(address => StakeDetail) public validatorStakes;

    event Staked(address validator, address ERC20Address, uint256 amount, uint256 TotalStakedAmount, bool positionChange);
    event RefundedStake(address validator, address ERC20Address, uint256 refundedAmount, uint256 LeftStakedAmount);




        /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize() public initializer {
        __ReentrancyGuard_init();
        __Ownable_init();
        __UUPSUpgradeable_init();
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

     function _stake(uint256 _amount, address _ERC20Address, address _validator, bool _paid) internal {
        require(_amount > 0, "Low Amount");
        require(_ERC20Address != address(0), "Zero Address");

        if(!_paid && validatorStakes[_validator].stakedAmount > 0) {
            revert("more than one time");
        }
        if(validatorStakes[_validator].stakedAmount > 0) {
            require(_ERC20Address == validatorStakes[_validator].ERC20Token, "Token mismatch");
        }

        validatorStakes[_validator].stakedAmount += _amount;
        validatorStakes[_validator].ERC20Token = _ERC20Address;

        bool isSuccess = IERC20(_ERC20Address).transferFrom(_validator, address(this), _amount);

        require(isSuccess, "Transfer failed");

        emit Staked(_validator, _ERC20Address, _amount, validatorStakes[_validator].stakedAmount, _paid);
    }

    function stake(uint256 _amount, address _ERC20Address) external whenNotPaused nonReentrant {
        _stake(_amount, _ERC20Address, msg.sender, false);
    }

    function addStake(uint256 _amount, address _ERC20Address) external whenNotPaused nonReentrant {
        _stake(_amount, _ERC20Address, msg.sender, true);
    }

    function refundStake(address _validatorAddress, uint256 _refundAmount) external whenNotPaused nonReentrant onlyOwner {
        require(_validatorAddress != address(0), "Zero Address");
        require(_refundAmount > 0, "Low Amount");

        StakeDetail storage stakes = validatorStakes[_validatorAddress];

        stakes.stakedAmount -= _refundAmount;
        stakes.refundedAmount += _refundAmount;

        address _ERC20Address = validatorStakes[_validatorAddress].ERC20Token;

        bool isSuccess = IERC20(_ERC20Address).transfer(_validatorAddress, _refundAmount);

        require(isSuccess, "Transfer failed");

        emit RefundedStake(_validatorAddress, _ERC20Address, _refundAmount, stakes.stakedAmount);
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}
}