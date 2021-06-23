// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.0;

import "../lib/SafeERC20.sol";
import "./AdminVault.sol";

/// @title AdminAuth Handles owner/admin privileges over smart contracts
contract AdminAuth {
    using SafeERC20 for IERC20;

    address public constant ADMIN_VAULT_ADDR = 0x493275370aF3f63d9ccd10a6539435121cF4fbb9;

    AdminVault public constant adminVault = AdminVault(ADMIN_VAULT_ADDR);

    modifier onlyOwner() {
        require(adminVault.owner() == msg.sender, "msg.sender not owner");
        _;
    }

    modifier onlyAdmin() {
        require(adminVault.admin() == msg.sender, "msg.sender not admin");
        _;
    }

    modifier onlyGovernance() {
        require(
            adminVault.governance() == msg.sender,
            "Only governance can call this."
        );
        _;
    }

    modifier onlyGovernances() {
        require(
            adminVault.admin() == msg.sender || adminVault.governance() == msg.sender,
            "Only governance can call this."
        );
        _;
    }

    /// @notice withdraw stuck funds
    function withdrawStuckFunds(address _token, address _receiver, uint256 _amount) public onlyAdmin {
        IERC20(_token).safeTransfer(_receiver, _amount);
    }

}