// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract mintToken is ERC20 {
    constructor(uint256 initialSupply) ERC20("Shrish", "srs") {
        _mint(msg.sender, initialSupply);
    }

    function mint(address _recipient, uint256 _amount) external {
        _mint(_recipient, _amount);
    }

    function getTime() external view returns(uint256) {
        return block.timestamp;
    }
}