
// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "../FundingPool.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";

library LibPool {
    function deployPoolAddress(
        address _poolOwner,
        address _poolRegistry,
        address _FundingPool
    ) external returns (address) {
        address tokenAddress = Clones.clone(_FundingPool);
        FundingPool(tokenAddress).initialize(_poolOwner, _poolRegistry);

        return address(tokenAddress);
    }
}