// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "../CollectionMethods.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";

library LibCollection {
    function deployCollectionAddress(
        address _collectionOwner,
        address _piNFT,
        string memory _name,
        string memory _symbol,
        address _collectionMethods
    ) external returns (address) {
        address tokenAddress = Clones.clone(_collectionMethods);
        CollectionMethods(tokenAddress).initialize(
            _collectionOwner,
            _piNFT,
            _name,
            _symbol
        );
        return address(tokenAddress);
    }
}
