// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.0;

import "./ERC20.sol";

contract ERC20Token is ERC20 {

    address _tokenMiningAddress;

    constructor (string memory name_, string memory symbol_) ERC20(name_, symbol_) {
        // Mint initialSupply tokens to msg.sender
        _tokenMiningAddress = msg.sender;
    }
    
    /// @dev Mint 
    /// @param value The amount of TOKNE to add
    function mint(uint256 value, address send) public payable {

        require(msg.sender == _tokenMiningAddress, "ERC20Token:!Auth");
        
        _mint(send, value);
    }
}