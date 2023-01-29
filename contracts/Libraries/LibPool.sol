// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "../poolAddress.sol";

library LibPool {
    function deployPoolAddress(
        address _poolOwner,
        address _poolRegistry,
        address _AconomyFeeAddress,
        uint256 _paymentCycleDuration,
        uint256 _paymentDefaultDuration,
        uint256 _feePercent
    ) external returns (address) {
        poolAddress tokenAddress = new poolAddress(
            _poolOwner,
            _poolRegistry,
            _AconomyFeeAddress,
            _paymentCycleDuration,
            _paymentDefaultDuration,
            _feePercent
        );

        return address(tokenAddress);
    }
}
