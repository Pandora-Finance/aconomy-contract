// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

 contract validatorStake is
    OwnableUpgradeable,
    PausableUpgradeable,
    ReentrancyGuardUpgradeable,
    UUPSUpgradeable
{
    using Counters for Counters.Counter;

    struct StakeDetail {
        uint256 stakedAmount;
        uint256 refundedAmount;
    }

    mapping(address => StakeDetail) public validatorStakes;

    event Staked(address validator, uint256 amount);
    event NewStake(address validator, uint256 amount, uint256 TotalStakedAmount);
    event RefundedStake(address validator, uint256 refundedAmount, uint256 LeftStakedAmount);




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


    function Stake(
        uint256 _amount,
        address _ERC20Address
    ) external whenNotPaused nonReentrant {
        require(msg.sender != address(0));
        require(_amount >= 0);

        StakeDetail memory stakeDetail = StakeDetail(
            _amount,
            0
        );

        validatorStakes[msg.sender] = stakeDetail;

        require(
            IERC20(_ERC20Address).transferFrom(
                msg.sender,
                address(this),
                _amount
            ),
            "Unable to tansfer Your ERC20"
        );

        emit Staked(msg.sender, _amount);
    }

    function addStake(
        uint256 _amount,
        address _ERC20Address
    ) external whenNotPaused nonReentrant {
        require(msg.sender != address(0));
        require(_amount >= 0);

        StakeDetail storage stakes = validatorStakes[msg.sender];
        stakes.stakedAmount += _amount;
        require(
            IERC20(_ERC20Address).transferFrom(
                msg.sender,
                address(this),
                _amount
            ),
            "Unable to tansfer Your ERC20"
        );
        emit NewStake(msg.sender, _amount, stakes.stakedAmount);
    }

    function RefundStake(
        address validatorAddress,
        address _ERC20Address,
        uint256 _refundAmount
    ) external whenNotPaused nonReentrant onlyOwner {
        StakeDetail storage stakes = validatorStakes[validatorAddress];

        bool isSuccess = IERC20(_ERC20Address).transfer(
                validatorAddress,
                _refundAmount
            );
        require(isSuccess, "Transfer failed");
        emit RefundedStake(validatorAddress, _refundAmount, stakes.stakedAmount-stakes.refundedAmount);
    }

    function _authorizeUpgrade(address) internal override onlyOwner {}
}