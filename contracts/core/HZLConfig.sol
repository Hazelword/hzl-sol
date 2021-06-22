// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.0;

import "../auth/AdminAuth.sol";
import "../utils/HZLLogger.sol";
import "../interface/IHZLConfig.sol";

/// @title Stores all the important qu addresses and can be changed (timelock)
contract HZLConfig is AdminAuth, IHZLConfig {

    struct MiningConfig {

        //the pledge hzl token for staking
        uint256 pledgeUnit;

        //the fee for mining
        uint256 feeUnit;

        //the reward by per block
        uint256 minnerReward;

        //the block mining time of base chain block number
        uint32 miningRange;
    }

    MiningConfig _miningConfig;

    mapping(bytes32 => address) _contracts;

    /// @notice Given an contract id returns the config address
    /// @dev Id is keccak256 of the contract name
    /// @param _name Id of contract
    function getAddr(bytes32 _name) public view override returns (address){
        return _contracts[_name];
    }

    /// @notice Given the pledge hzl token for staking
    function getPledgeUnit() public view override returns (uint256){
        return _miningConfig.pledgeUnit;
    }

    /// @notice Given the fee for mining
    function getFeeUnit() public view override returns (uint256){
        return _miningConfig.pledgeUnit;
    }

    /// @notice Given the reward by per block
    function getMinnerReward() public view override returns (uint256){
        return _miningConfig.pledgeUnit;
    }

    /// @notice the block mining time of base chain block number
    function getMiningRange() public view override returns (uint256){
        return _miningConfig.pledgeUnit;
    }

    /////////////////////////// OWNER ONLY FUNCTIONS ///////////////////////////

    /// @notice Adds a new contract to the config
    /// @param _name Id of contract
    /// @param _contractAddr Address of the contract
    function addNewContract(
        bytes32 _name,
        address _contractAddr
    ) public override {
        _contracts[_name] = _contractAddr;
    }

    /// @notice init config
    function initConfig() public override {
        _miningConfig = MiningConfig(20000, 10, 100, 15);
    }

    /// @notice update config
    /// @param _pledgeUnit the pledge hzl token for staking
    /// @param _feeUnit the fee for mining
    /// @param _minnerReward the reward by per block
    /// @param _miningRange the block mining time of base chain block number
    function updateConfig(
        uint256 _pledgeUnit,
        uint256 _feeUnit,
        uint256 _minnerReward,
        uint32 _miningRange
    ) public override {
        _miningConfig = MiningConfig(_pledgeUnit, _feeUnit, _minnerReward, _miningRange);
    }

}