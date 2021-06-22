// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

contract Miners {

    //is minner?, user address => bool
    mapping(address => bool) minners;

    modifier onlyMiners() {
        require(
            minners[msg.sender],
            "Only miner call this."
        );
        _;
    }

    modifier onlyNotMiners() {
        require(
            !minners[msg.sender],
            "Only not miner call this."
        );
        _;
    }
}