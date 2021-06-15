// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.0;

import "./base/ERC20.sol";
import "./interface/IHzlToken.sol";

contract HzlToken is IHzlToken, ERC20 {

    address _tokenMiningAddress;

    constructor () ERC20("HazelWord", "HZL") {
        // Mint initialSupply tokens to msg.sender
        _tokenMiningAddress = msg.sender;
    }

    /// @dev Mint 
    /// @param value The amount of HZL to add
    /// @param send The address of to send
    function mint(uint256 value, address send) public payable {

        require(msg.sender == _tokenMiningAddress, "HZLToken:!Auth");
        
        _mint(send, value);
    }

    function checkBidder() external override view returns(address) {
        return address(this);
    }

}