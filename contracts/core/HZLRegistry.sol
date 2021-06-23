// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.0;

import "../auth/AdminAuth.sol";
import "../utils/HZLLogger.sol";
import "../interface/IHZLRegistry.sol";

/// @title Stores all the important qu addresses and can be changed (timelock)
contract HZLRegistry is AdminAuth, IHZLRegistry {
    HZLLogger public constant logger = HZLLogger(
        0xEC69d4f48f4f1740976968FAb9828d645Ad1d77f
    );

    string public constant ERR_ENTRY_ALREADY_EXISTS = "Entry id already exists";
    string public constant ERR_ENTRY_NON_EXISTENT = "Entry id doesn't exists";
    string public constant ERR_ENTRY_NOT_IN_CHANGE = "Entry not in change process";
    string public constant ERR_CHANGE_NOT_READY = "Change not ready yet";
    string public constant ERR_EMPTY_PREV_ADDR = "Previous addr is 0";

    struct Entry {
        address contractAddr;
        uint256 changeStartTime;
        bool exists;
    }

    mapping(address => Entry) public entries;
    mapping(bytes32 => address) public currentAddresses;
    mapping(bytes32 => address) public previousAddresses;

    /// @notice Given an contract id returns the registered address
    /// @dev Id is keccak256 of the contract name
    /// @param _id Id of contract
    function getAddr(bytes32 _id) public override view returns (address) {
        return currentAddresses[_id];
    }

    /// @notice Helper function to easily query if id is registered
    /// @param _addr address of contract
    function isRegistered(address _addr) public override view returns (bool) {
        return entries[_addr].exists;
    }

    /////////////////////////// OWNER ONLY FUNCTIONS ///////////////////////////

    /// @notice Adds a new contract to the registry
    /// @param _id Id of contract
    /// @param _contractAddr Address of the contract
    function addNewContract(
        bytes32 _id,
        address _contractAddr
    ) public override onlyGovernances {
        require(!entries[_contractAddr].exists, ERR_ENTRY_ALREADY_EXISTS);

        entries[_contractAddr] = Entry({
            contractAddr: _contractAddr,
            changeStartTime: 0,
            exists: true
        });
        currentAddresses[_id] = _contractAddr;
        // Remember tha address so we can revert back to old addr if needed
        previousAddresses[_id] = _contractAddr;

        logger.Log(
            address(this),
            msg.sender,
            "AddNewContract",
            abi.encode(_id, _contractAddr)
        );
    }

    /// @notice Reverts to the previous address immediately
    /// @dev In case the new version has a fault, a quick way to fallback to the old contract
    /// @param _id Id of contract
    function revertToPreviousAddress(bytes32 _id) public override onlyGovernances {
        address currentAddr = currentAddresses[_id];
        require(entries[currentAddr].exists, ERR_ENTRY_NON_EXISTENT);
        require(previousAddresses[_id] != address(0), ERR_EMPTY_PREV_ADDR);

        address previousAddr = previousAddresses[_id];
        currentAddresses[_id] = previousAddresses[_id];
        entries[previousAddr] = Entry({
            contractAddr: previousAddr,
            changeStartTime: 0,
            exists: true
        });

        delete entries[currentAddr];

        logger.Log(
            address(this),
            msg.sender,
            "RevertToPreviousAddress",
            abi.encode(_id, currentAddr, previousAddresses[_id])
        );
    }

    /// @notice Starts an address change for an existing entry
    /// @dev Can override a change that is currently in progress
    /// @param _id Id of contract
    /// @param _newContractAddr Address of the new contract
    function startContractChange(bytes32 _id, address _newContractAddr) public override onlyGovernances {
        address currentAddr = currentAddresses[_id];
        require(entries[currentAddr].exists, ERR_ENTRY_NON_EXISTENT);

        entries[_newContractAddr] = Entry({
            contractAddr: _newContractAddr,
            changeStartTime: 0,
            exists: true
        }); 

        currentAddresses[_id] = _newContractAddr;
        previousAddresses[_id] = currentAddr;
        
        delete entries[currentAddr];

        logger.Log(
            address(this),
            msg.sender,
            "StartContractChange",
            abi.encode(_id, currentAddr, _newContractAddr)
        );
    }

    /// @notice stop an address change for an existing entry
    /// @dev Can override a change that is currently in progress
    /// @param _id Id of contract
    function stopContract(bytes32 _id) public override onlyGovernances {
        address currentAddr = currentAddresses[_id];
        require(entries[currentAddr].exists, ERR_ENTRY_NON_EXISTENT);
        entries[currentAddr].changeStartTime = block.timestamp;
        entries[currentAddr].exists = false;
    }

    /// @notice start an address change for an existing entry
    /// @dev Can override a change that is currently in progress
    /// @param _id Id of contract
    function startContract(bytes32 _id) public override onlyGovernances {
        address currentAddr = currentAddresses[_id];
        require(entries[currentAddr].exists, ERR_ENTRY_NON_EXISTENT);
        entries[currentAddr].changeStartTime = block.timestamp;
        entries[currentAddr].exists = true;
    }

}