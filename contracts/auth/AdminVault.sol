// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.0;

contract AdminVault {
    address public owner;
    address public admin;
    address public governance;

    constructor() {
        owner = msg.sender;
        admin = 0x25eFA336886C74eA8E282ac466BdCd0199f85BB9;
        governance = 0x25eFA336886C74eA8E282ac466BdCd0199f85BB9;
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