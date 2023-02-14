// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "../Collection.sol";

library LibCollection {
    function deployCollectionAddress(address _collectionOwner, address _piNFT)
        external
        returns (address)
    {
        Collection tokenAddress = new Collection(_collectionOwner, _piNFT);

        return address(tokenAddress);
    }
}
