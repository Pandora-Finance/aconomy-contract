// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "../CollectionMethods.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";

library LibCollection {

    /**
     * @notice Returns the address of the deployed collection contract.
     * @dev Returned value is type address.
     * @param _collectionOwner The address set to own the collection.
     * @param _collectionFactoryAddress The address of the CollectionFactory contract.
     * @param _name the name of the collection being created.
     * @param _symbol the symbol of the collection being created.
     * @param _collectionMethods the address of the proxy implementation CollectionMethods contract.
     * @return address of the deployed collection.
     */
    function deployCollectionAddress(
        address _collectionOwner,
        address _collectionFactoryAddress,
        string memory _name,
        string memory _symbol,
        address _collectionMethods
    ) external returns (address) {
        address tokenAddress = Clones.clone(_collectionMethods);
        CollectionMethods(tokenAddress).initialize(
            _collectionOwner,
            _collectionFactoryAddress,
            _name,
            _symbol
        );
        return address(tokenAddress);
    }
}
