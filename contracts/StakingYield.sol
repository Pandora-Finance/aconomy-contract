// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";

contract StakingYield is Ownable, ReentrancyGuard, Pausable {
    IERC20 public immutable Token;
    ERC20Burnable public burnableToken;

    // Duration of rewards to be paid out (in seconds)
    uint256 public duration;
    // Timestamp of when the rewards finish
    uint256 public finishAt;
    // Minimum of last updated time and reward finish time
    uint256 public updatedAt;
    // Reward to be paid out per second
    uint256 public rewardRate;
    // Sum of (reward rate * dt * 1e18 / total supply)
    uint256 public rewardPerTokenStored;
    // User address => rewardPerTokenStored
    mapping(address => uint256) public userRewardPerTokenPaid;
    // User address => rewards to be claimed
    mapping(address => uint256) public rewards;
    // Total staked
    uint256 public totalSupply;
    // GnosisSafe wallet address
    address public GnosisSafe; 
    // yield will generate based on rewardTokens
    uint256 public rewardTokens;
    // User address => staked amount
    mapping(address => uint256) public balanceOf;
    // User address => staked time
    mapping(address => uint256) public stakeTimestamps;
    // User address => bool
    mapping(address => bool) public withdrawable;

    event RewardAdded(uint256 reward);
    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 received, uint256 Burned);
    event RewardPaid(address indexed user, uint256 reward);
    event RewardsDurationUpdated(uint256 newDuration);
    event Recovered(address receiverAddress,address ERC20Address, uint256 amount);
    event RewardTokenDeposited(uint256 Amount);
    event UpdatedRewardToken(uint256 Amount);

    constructor(address _stakingToken, address _safe) {
        Token = IERC20(_stakingToken);
        burnableToken = ERC20Burnable(_stakingToken);
        GnosisSafe = _safe;
    }

    uint256 constant ONE_YEAR = 365 days;
    uint256 constant TWO_YEARS = 2 * 365 days;
    uint256 constant THREE_YEARS = 3 * 365 days;

    modifier updateReward(address _account) {
        rewardPerTokenStored = rewardPerToken();
        updatedAt = lastTimeRewardApplicable();

        if (_account != address(0)) {
            rewards[_account] = earned(_account);
            userRewardPerTokenPaid[_account] = rewardPerTokenStored;
        }
        _;
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function lastTimeRewardApplicable() public view returns (uint256) {
        return _min(finishAt, block.timestamp);
    }

    function rewardPerToken() public view returns (uint256) {
        if (totalSupply == 0) {
            return rewardPerTokenStored;
        }

        return
            rewardPerTokenStored +
            (rewardRate * (lastTimeRewardApplicable() - updatedAt) * 1e18) /
            totalSupply;
    }

    function stake(
        address _userAddress,
        uint256 _amount
    ) external updateReward(_userAddress) whenNotPaused nonReentrant onlyOwner {
        require(_amount > 0, "amount = 0");
        Token.transferFrom(msg.sender, address(this), _amount);
        balanceOf[_userAddress] += _amount;
        stakeTimestamps[_userAddress] = block.timestamp;
        totalSupply += _amount;
        emit Staked(_userAddress, _amount);
    }

    function withdrawPermission(
        address _userAddress,
        bool _isGranted
    ) external whenNotPaused nonReentrant onlyOwner {
        withdrawable[_userAddress] = _isGranted;
    }

    function withdraw()
        external
        updateReward(msg.sender)
        whenNotPaused
        nonReentrant
    {
        require(withdrawable[msg.sender], "Permission Denied");
        uint256 burnAmount = 0;
        uint256 stakedAmount = balanceOf[msg.sender];
        uint256 currentTime = block.timestamp;
        uint256 stakeTime = stakeTimestamps[msg.sender];
        uint256 withdrawableAmount = stakedAmount;

        if (currentTime < stakeTime + ONE_YEAR) {
            revert("Can't withdraw tokens within one Year");
        } else if (currentTime < stakeTime + TWO_YEARS) {
            burnAmount = (stakedAmount * 5000) / 10000;
        } else if (currentTime < stakeTime + THREE_YEARS) {
            burnAmount = (stakedAmount * 2500) / 10000;
        }

        withdrawableAmount -= burnAmount;

        totalSupply -= stakedAmount;
        balanceOf[msg.sender] -= stakedAmount;
        Token.transfer(msg.sender, withdrawableAmount);
        burnableToken.burn(burnAmount);
        emit Withdrawn(msg.sender, withdrawableAmount, burnAmount);
    }

    function earned(address _account) public view returns (uint256) {
        return
            ((balanceOf[_account] *
                (rewardPerToken() - userRewardPerTokenPaid[_account])) / 1e18) +
            rewards[_account];
    }

    function getReward() external updateReward(msg.sender) {
        uint256 reward = rewards[msg.sender];
        if (reward > 0) {
            rewards[msg.sender] = 0;
            rewardTokens -= reward;
            Token.transfer(msg.sender, reward);
            emit RewardPaid(msg.sender, reward);
        }
    }

    function depositRewardToken(
        uint256 _amount
    ) external onlyOwner whenNotPaused nonReentrant {
        Token.transferFrom(msg.sender, address(this), _amount);
        rewardTokens += _amount;
        emit RewardTokenDeposited(_amount);
    }

    function updateRewardToken(
        uint256 _rewardTokens
    ) external onlyOwner whenNotPaused nonReentrant {
        rewardTokens = _rewardTokens;
        emit UpdatedRewardToken(_rewardTokens);
    }

    function setRewardsDuration(uint256 _duration) external onlyOwner {
        require(finishAt < block.timestamp, "reward duration not finished");
        duration = _duration;
        emit RewardsDurationUpdated(_duration);
    }

    function notifyRewardAmount(
        uint256 _amount
    ) external onlyOwner nonReentrant whenNotPaused updateReward(address(0)) {
        if (block.timestamp >= finishAt) {
            rewardRate = _amount / duration;
        } else {
            uint256 remainingRewards = (finishAt - block.timestamp) *
                rewardRate;
            rewardRate = (_amount + remainingRewards) / duration;
        }

        require(rewardRate > 0, "reward rate = 0");
        require(
            rewardRate * duration <= rewardTokens,
            "reward amount > balance"
        );

        finishAt = block.timestamp + duration;
        updatedAt = block.timestamp;
        emit RewardAdded(_amount);
    }

    // Function that can only be called when the contract IS paused
    function recoverERC20(
        address ERC20Address,
        uint256 tokenAmount
    ) external onlyOwner nonReentrant whenPaused {
        bool isSuccess = IERC20(ERC20Address).transfer(GnosisSafe, tokenAmount);
        require(isSuccess, "Transfer failed");
        emit Recovered(GnosisSafe, ERC20Address, tokenAmount);
    }

    function _min(uint256 x, uint256 y) private pure returns (uint256) {
        return x <= y ? x : y;
    }
}