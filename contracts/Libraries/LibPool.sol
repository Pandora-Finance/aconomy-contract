
// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "../FundingPool.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";

library LibPool {

    /**
     * @notice Returns the address of the deployed pool contract.
     * @dev Returned value is type address.
     * @param _poolOwner The address set to own the pool.
     * @param _poolRegistry The address of the poolRegistry contract.
     * @param _FundingPool the address of the proxy implementation of FundingPool.
     * @return address of the deployed .
     */
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