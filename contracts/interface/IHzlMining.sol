// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.0;

interface IHzlMining {
    /**
     * @dev freeze the amount of tokens in existence for mining.
     */
    function freeze() external returns (bool);

    /**
     * @dev unfreeze tokens back to original address.
     */
    function unfreeze() external returns (bool);

    /**
     * @dev if had freeze tokens, return true; e;se false
     */
    function isMiners() external view returns (bool);
}