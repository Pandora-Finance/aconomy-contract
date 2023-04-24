// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "./poolAddress.sol";

contract CollateralController {

    struct Collateral {
        uint256 _amount;
        address _collateralAddress;
    }

    mapping(uint256 => Collateral) internal loanCollateral;

    function getCollateral(uint256 _loanId) external view returns(Collateral[]){
        return loanCollateral[_loanId];
    }

}