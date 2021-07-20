// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.0;

abstract contract IHZLConfig {

    /// @notice Given an contract id returns the config address
    /// @dev Id is keccak256 of the contract name
    /// @param _name Id of contract
    function getAddr(bytes32 _name) public view virtual returns (address);

    /// @notice Given the pledge hzl token for staking
    function getPledgeUnit() public view virtual returns (uint256);

    /// @notice Given the fee for mining
    function getFeeUnit() public view virtual returns (uint256);

    /// @notice Given the reward by per block
    function getMinnerReward() public view virtual returns (uint256);

    /// @notice the block mining time of base chain block number
    function getMiningRange() public view virtual returns (uint32);

    function getPrecision(address _addr) public view virtual returns (uint32);

    /////////////////////////// OWNER ONLY FUNCTIONS ///////////////////////////

    /// @notice Adds a new contract to the config
    /// @param _name Id of contract
    /// @param _contractAddr Address of the contract
    function addNewContract(
        bytes32 _name,
        address _contractAddr
    ) public virtual;

    function addPrecisions(
        address _addr,
        uint32 _precision
    ) public virtual;

    /// @notice init config
    function initConfig() public virtual;

    /// @notice update config
    /// @param _pledgeUnitId the pledge hzl token for staking
    /// @param _feeUnit the fee for mining
    /// @param _minnerReward the reward by per block
    /// @param _miningRange the block mining time of base chain block number
    function updateConfig(
        uint256 _pledgeUnitId,
        uint256 _feeUnit,
        uint256 _minnerReward,
        uint32 _miningRange
    ) public virtual;
}