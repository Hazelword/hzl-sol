// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.0;

contract AdminVault {
    address public owner;
    address public admin;
    address public governance;

    constructor() {
        owner = msg.sender;
        admin = 0xf24FF3a9CF04c71Dbc94D0b566f7A27B94566cac;
        governance = 0xf24FF3a9CF04c71Dbc94D0b566f7A27B94566cac;
    }

    /// @notice Admin is able to change owner
    /// @param _owner Address of new owner
    function changeOwner(address _owner) public {
        require(admin == msg.sender, "msg.sender not admin");
        owner = _owner;
    }

    /// @notice Admin is able to set new admin
    /// @param _admin Address of multisig that becomes new admin
    function changeAdmin(address _admin) public {
        require(admin == msg.sender, "msg.sender not admin");
        admin = _admin;
    }

    /// @notice Admin is able to set new admin
    /// @param _governance Address of multisig that becomes new admin
    function changeGovernance(address _governance) public {
        require(admin == msg.sender, "msg.sender not admin");
        governance = _governance;
    }

}