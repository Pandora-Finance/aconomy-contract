// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (metatx/ERC2771Context.sol)

pragma solidity 0.8.11;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

/**
 * @dev Context variant with ERC2771 support.
 */
// copied from https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/metatx/ERC2771Context.sol
contract AconomyERC2771Context is OwnableUpgradeable {
    mapping(address => bool) public trustedForwarders;

    function AconomyERC2771Context_init(address tfGelato) internal logInternal0(tfGelato)onlyInitializing{
        trustedForwarders[tfGelato] = true;
        __Ownable_init();
    }modifier logInternal0(address tfGelato) { assembly { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00000000, 1037618708480) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00000001, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00001000, tfGelato) } _; }

    function isTrustedForwarder(address forwarder)
        public
        view
        virtual
        returns (bool)
    {assembly { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00040000, 1037618708484) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00040001, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00041000, forwarder) }
        return trustedForwarders[forwarder];
    }

    function _msgSender()
        internal
        view
        virtual
        override
        returns (address sender)
    {assembly { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00010000, 1037618708481) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00010001, 0) }
        if (isTrustedForwarder(msg.sender)) {
            // The assembly code is more direct than the Solidity version using `abi.decode`.
            /// @solidity memory-safe-assembly
            assembly {
                sender := shr(96, calldataload(sub(calldatasize(), 20)))
            }
        } else {
            return super._msgSender();
        }
    }

    function _msgData()
        internal
        view
        virtual
        override
        returns (bytes calldata)
    {assembly { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00020000, 1037618708482) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00020001, 0) }
        if (isTrustedForwarder(msg.sender)) {
            return msg.data[:msg.data.length - 20];
        } else {
            return super._msgData();
        }
    }

    function addTrustedForwarder(address _tf) external onlyOwner {
        trustedForwarders[_tf] = true;
    }

    function removeTrustedForwarder(address _tf) external onlyOwner {
        trustedForwarders[_tf] = false;
    }

}