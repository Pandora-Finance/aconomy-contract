// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

contract StakingYield is Ownable, ReentrancyGuard, Pausable {
    IERC20 public immutable Token;

    // Duration of rewards to be paid out (in seconds)
    uint256 public duration;
    // Timestamp of when the rewards finish
    uint256 public finishAt;
    // Minimum of last updated time and reward finish time
    uint256 public updatedAt;
    // Reward to be paid out per second
    uint256 public rewardRate;
    // Sum of (reward rate * Duration Time * 1e18 / total supply)
    uint256 public rewardPerTokenStored;
    // User address => rewardPerTokenStored
    mapping(address => uint256) public userRewardPerTokenPaid;
    // User address => rewards to be claimed
    mapping(address => uint256) public rewards;

    // Total staked
    uint256 public totalSupply;
    // Reward Tokens
    uint256 public RewardTokens;
    // User address => staked amount
    mapping(address => userDetails) public balanceOf;

    struct userDetails {
        uint256 Amount;
        uint256 StakingTime;
        bool Blocked;
    }

    /* ========== EVENTS ========== */

    event RewardAdded(uint256 reward);
    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardPaid(address indexed user, uint256 reward);
    event RewardsDurationUpdated(uint256 newDuration, uint256 RewardTokens);
    event Recovered(address token, uint256 amount);

    constructor(address _stakingToken) {
        Token = IERC20(_stakingToken);
    }

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
    ) external whenNotPaused updateReward(msg.sender) nonReentrant {
        require(_amount > 0, "amount = 0");
        require(_userAddress != address(0), "zero Address");
        Token.transferFrom(msg.sender, address(this), _amount);
        balanceOf[_userAddress].Amount += _amount;
        balanceOf[_userAddress].StakingTime = block.timestamp;
        totalSupply += _amount;
        emit Staked(_userAddress, _amount);
    }

    function withdraw(
        uint256 _amount
    ) external whenNotPaused updateReward(msg.sender) nonReentrant {
        require(_amount > 0, "amount = 0");
        balanceOf[msg.sender].Amount -= _amount;
        totalSupply -= _amount;
        Token.transfer(msg.sender, _amount);
        emit Withdrawn(msg.sender, _amount);
    }

    function earned(address _account) public view returns (uint256) {
        return
            ((balanceOf[_account].Amount *
                (rewardPerToken() - userRewardPerTokenPaid[_account])) / 1e18) +
            rewards[_account];
    }

    function getReward()
        external
        updateReward(msg.sender)
        whenNotPaused
        nonReentrant
    {
        uint256 reward = rewards[msg.sender];
        if (reward > 0) {
            rewards[msg.sender] = 0;
            Token.transfer(msg.sender, reward);
            RewardTokens = RewardTokens - reward;
            emit RewardPaid(msg.sender, reward);
        }
    }

    function setRewardsDurationAndRewardTokens(uint256 _duration, uint256 _RewardTokens) external onlyOwner {
        require(finishAt < block.timestamp, "reward duration not finished");
        duration = _duration;
        RewardTokens += _RewardTokens;
        emit RewardsDurationUpdated(_duration, _RewardTokens);
    }

    function notifyRewardAmount(
        uint256 _amount
    ) external onlyOwner whenNotPaused updateReward(address(0)) nonReentrant {
        if (block.timestamp >= finishAt) {
            rewardRate = _amount / duration;
        } else {
            uint256 remainingRewards = (finishAt - block.timestamp) *
                rewardRate;
            rewardRate = (_amount + remainingRewards) / duration;
        }

        require(rewardRate > 0, "reward rate = 0");
        require(
            rewardRate * duration <= RewardTokens,
            "reward amount > balance"
        );

        finishAt = block.timestamp + duration;
        updatedAt = block.timestamp;
    }

    function recoverERC20(
        address tokenAddress,
        uint256 tokenAmount
    ) external onlyOwner whenNotPaused nonReentrant {
        Token.transfer(owner(), tokenAmount);
        emit Recovered(tokenAddress, tokenAmount);
    }

    function _min(uint256 x, uint256 y) private pure returns (uint256) {
        return x <= y ? x : y;
    }
}
