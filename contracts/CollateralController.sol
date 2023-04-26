// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./poolStorage.sol";
import "./poolAddress.sol";

contract CollateralController is ReentrancyGuard{

    address _Address;
    struct Collateral {
        uint256 amount;
        address collateralAddress;
        bool withdrawn;
    }

    // loanId => Collateral
    mapping(uint256 => Collateral) internal loanCollateral;
    mapping(uint256 => bool) public isLoanCollateralized;

    event CollateralDeposited(uint256 loanId, address erc20contract, uint256 amount, address depositor);
    event CollateralWithdrawn(uint256 loanId, address erc20Contract, uint256 amount, address withdrawer);
    event CollateralLiquidated(uint256 loanId, address erc20Contract, uint256 amount, address liquidator);

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
            _contract,
            false
        );

        loanCollateral[_loanId] = collateral;
        isLoanCollateralized[_loanId] = true;
        IERC20(_contract).transferFrom(msg.sender, address(this), _amount);

        emit CollateralDeposited(_loanId, _contract, _amount, msg.sender);
    }

    function withdrawCollateral(uint256 _loanId) external nonReentrant{
        (address borrower,,,,,,poolStorage.LoanState state) = poolStorage(_Address).loans(_loanId);
        require(isLoanCollateralized[_loanId]);
        require(!loanCollateral[_loanId].withdrawn);
        require(msg.sender == borrower);
        require(state == poolStorage.LoanState.PENDING ||
        state == poolStorage.LoanState.PAID);
        isLoanCollateralized[_loanId] = false;
        loanCollateral[_loanId].withdrawn = true;

        IERC20(loanCollateral[_loanId].collateralAddress).transfer(msg.sender, loanCollateral[_loanId].amount);

        emit CollateralWithdrawn(
            _loanId, 
            loanCollateral[_loanId].collateralAddress, 
            loanCollateral[_loanId].amount, 
            msg.sender
        );
    }

    function liquidateCollateral(uint256 _loanId, address _liquidator) external {
        require(msg.sender == _Address);
        require(isLoanCollateralized[_loanId]);
        loanCollateral[_loanId].withdrawn = true;
        
        IERC20(loanCollateral[_loanId].collateralAddress).transfer(_liquidator, loanCollateral[_loanId].amount);

        emit CollateralLiquidated(
            _loanId, 
            loanCollateral[_loanId].collateralAddress, 
            loanCollateral[_loanId].amount, 
            _liquidator
        );
    }

}