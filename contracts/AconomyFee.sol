pragma solidity 0.8.11;
// SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/access/Ownable.sol";

contract AconomyFee is Ownable {
    uint16 public _AconomyPoolFee;
    uint16 public _AconomyPiMarketFee;
    uint16 public _AconomyNFTLendBorrowFee;

    event SetAconomyFee(uint16 newFee, uint16 oldFee);
    event SetAconomyPiMarketFee(uint16 newFee, uint16 oldFee);
    event SetAconomyNFTLendBorrowFee(uint16 newFee, uint16 oldFee);

    function AconomyPoolFee() public view returns (uint16) {
        return _AconomyPoolFee;
    }

    function AconomyPiMarketFee() public view returns (uint16) {
        return _AconomyPiMarketFee;
    }

    function AconomyNFTLendBorrowFee() public view returns (uint16) {
        return _AconomyNFTLendBorrowFee;
    }

    function getAconomyOwnerAddress() public view returns (address) {
        return owner();
    }

    /**
     * @notice Sets the protocol fee.
     * @param newFee The value of the new fee percentage in bps.
     */
    function setAconomyPoolFee(uint16 newFee) public onlyOwner {
        if (newFee == _AconomyPoolFee) return;

        uint16 oldFee = _AconomyPoolFee;
        _AconomyPoolFee = newFee;
        emit SetAconomyFee(newFee, oldFee);
    }

    function setAconomyPiMarketFee(uint16 newFee) public onlyOwner {
        if (newFee == _AconomyPiMarketFee) return;

        uint16 oldFee = _AconomyPiMarketFee;
        _AconomyPiMarketFee = newFee;
        emit SetAconomyFee(newFee, oldFee);
    }

    function setAconomyNFTLendBorrowFee(
        uint16 newFee
    ) public onlyOwner {
        if (newFee == _AconomyNFTLendBorrowFee) return;

        uint16 oldFee = _AconomyNFTLendBorrowFee;
        _AconomyNFTLendBorrowFee = newFee;
        emit SetAconomyNFTLendBorrowFee(newFee, oldFee);
    }
}
