// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.0;

abstract contract IHZLRegistry {
 
    /// @notice Given an contract id returns the registered address
    /// @dev Id is keccak256 of the contract name
    /// @param _id Id of contract
    function getAddr(bytes32 _id) public view virtual returns (address);

    /// @notice Helper function to easily query if id is registered
    /// @param _id Id of contract
    function isRegistered(bytes32 _id) public view virtual returns (bool);

    /////////////////////////// OWNER ONLY FUNCTIONS ///////////////////////////

    /// @notice Adds a new contract to the registry
    /// @param _id Id of contract
    /// @param _contractAddr Address of the contract
    function addNewContract(
        bytes32 _id,
        address _contractAddr
    ) public virtual;

    /// @notice Reverts to the previous address immediately
    /// @dev In case the new version has a fault, a quick way to fallback to the old contract
    /// @param _id Id of contract
    function revertToPreviousAddress(bytes32 _id) public virtual;

    /// @notice Starts an address change for an existing entry
    /// @dev Can override a change that is currently in progress
    /// @param _id Id of contract
    /// @param _newContractAddr Address of the new contract
    function startContractChange(bytes32 _id, address _newContractAddr) public virtual;

    /// @notice stop an address change for an existing entry
    /// @dev Can override a change that is currently in progress
    /// @param _id Id of contract
    function stopContract(bytes32 _id) public virtual;

    /// @notice start an address change for an existing entry
    /// @dev Can override a change that is currently in progress
    /// @param _id Id of contract
    function startContract(bytes32 _id) public virtual;

}