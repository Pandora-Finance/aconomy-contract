// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

library LibShare {
    // Defines the share of royalties for the address

    /**
     * @notice details of a royalty share.
     * @param account The address of the royalty receiver.
     * @param value The percentage of royalties in bps.
     */
    struct Share {
        address payable account;
        uint96 value;
    }

    function setCommission(Share storage _setShare, uint96 _commission) external {
        require(_commission <= 4900);
        _setShare.account = payable(msg.sender);
        _setShare.value = _commission;
    }
}