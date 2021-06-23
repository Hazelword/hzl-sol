// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.0;

interface IHzlMining {

    /// @notice close one order
    /// @dev Id is keccak256 of the contract name
    /// @param tokenAddress address of token
    /// @param index The numbers of TOKEN to quote
    function closeOrder(address tokenAddress, uint index) external;

    // @notice close all order
    /// @dev Id is keccak256 of the contract name
    /// @param tokenAddress address of token
    function closeAllOrder(address tokenAddress) external;

    /// @notice take order id token
    /// @dev Id is keccak256 of the contract name
    /// @param tokenAddress address of token
    /// @param index index of pricesheet
    /// @param num num of token
    function takeOrderToken(address tokenAddress, uint256 index, uint256 num) external;

    /// @notice take order usdt token
    /// @dev Id is keccak256 of the contract name
    /// @param tokenAddress address of token
    /// @param index index of pricesheet
    /// @param num num of token
    function takeOrderUstd(address tokenAddress, uint256 index, uint256 num) external;
    /**
     * @dev freeze the amount of tokens in existence for mining.
     */
    function freeze() external;

    /**
     * @dev unfreeze tokens back to original address.
     */
    function unfreeze() external;

}