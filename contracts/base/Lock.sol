// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.0;

contract Lock {
    uint private unlocked = 1;
    modifier lock() {
        require(unlocked == 1, 'HZL: LOCKED');
        unlocked = 0;
        _;
        unlocked = 1;
    }

    bool init = false;
    modifier onlyOnce() {
        require(
            !init,
            "Only once call this."
        );
        _;
    }

    mapping(uint256 => mapping(address => bool)) private _status;
    modifier onlyOneBlock() {
        require(
            !_status[block.number][tx.origin],
            'HZL:Stak:!block'
        );
        require(
            !_status[block.number][msg.sender],
            'HZL:Stak:!block'
        );

        _;

        _status[block.number][tx.origin] = true;
        _status[block.number][msg.sender] = true;
    }

    uint8 public flag;
    uint8 constant ACTIVE          = 1;
    uint8 constant NO_ACTIVE       = 0;
    modifier whenActive() 
    {
        require(flag == ACTIVE, "HZL:Stak:!flag");
        _;
    }
}