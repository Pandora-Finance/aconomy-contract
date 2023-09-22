pragma solidity 0.8.11;

// SPDX-License-Identifier: MIT

interface IAttestationServices {
    function register(bytes calldata schema) external returns (bytes32);
}
