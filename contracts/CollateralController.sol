// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./poolStorage.sol";

contract CollateralController {

    address _Address;
    struct Collateral {
        uint256 amount;
        address collateralAddress;
    }

    // loanId => Collateral
    mapping(uint256 => Collateral) internal loanCollateral;

    constructor(address _address) {
        _Address = _address;
    }

    function getCollateral(uint256 _loanId) external view returns(Collateral memory){
        return loanCollateral[_loanId];
    }

    function depositCollateral(uint256 _loanId, address _contract, uint256 _amount) external {
        (address borrower,,,,,,poolStorage.LoanState state) = poolStorage(_Address).loans(_loanId);
        require(msg.sender == borrower);
        require(state == poolStorage.LoanState.PENDING);
        require(_contract != address(0));
        require(_amount > 0);

        Collateral memory collateral = Collateral(
            _amount,
            _contract
        );

        loanCollateral[_loanId] = collateral;
        IERC20(_contract).transferFrom(msg.sender, address(this), _amount);
    }

    function withdrawCollateral(uint256 _loanId) external {
        (address borrower,,,,,,poolStorage.LoanState state) = poolStorage(_Address).loans(_loanId);
        require(msg.sender == borrower);
        require(state == poolStorage.LoanState.PENDING ||
        state == poolStorage.LoanState.PAID);

        delete loanCollateral[_loanId];

        IERC20(loanCollateral[_loanId].collateralAddress).transfer(msg.sender, loanCollateral[_loanId].amount);
    }

}