// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "./Libraries/LibCollection.sol";

contract Collection {
    address poolOwner;
    address piNFTAddress;

    constructor(address _poolOwner, address _piNFTAddress) {
        address poolOwner = _poolOwner;
        address piNFTAddress = _piNFTAddress;
    }
}
