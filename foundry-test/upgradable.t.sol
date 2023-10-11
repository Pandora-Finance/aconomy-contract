// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "contracts/upgradable.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract UUPSTest is Test {
    function testDeployAndInitialize() internal {
        address implementation = address(new TestUUPS());
        uint256 value = 42;

        bytes memory data = abi.encodeCall(TestUUPS.initialize, value);
        address proxy = address(new ERC1967Proxy(implementation, data));

        TestUUPS testUUPS = TestUUPS(proxy);
        assertEq(testUUPS.value(), value);
    }
}