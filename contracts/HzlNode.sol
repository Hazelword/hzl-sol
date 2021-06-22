// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.0;

import "./HzlMining.sol";
import "./lib/SafeMath.sol";
import "./base/Lock.sol";
import "./auth/AdminAuth.sol";

//stake and quory
contract HzlNode is AdminAuth, Lock{

    using SafeMath for uint256;

    address _hzlMining;

    address _governance;

    address public constant HZL_CONFIG_ADDR = 0xCCf3d848e08b94478Ed8f46fFead3008faF581fD;

    address public constant HZL_REGISTRY_ADDR = 0xCCf3d848e08b94478Ed8f46fFead3008faF581fD;


    HZLConfig hzlConfig = HZLConfig(HZL_CONFIG_ADDR);

    HZLRegistry hzlRegisty = HZLRegistry(HZL_REGISTRY_ADDR);

    //50%
    uint256 _feePool;

    //50%
    uint256 __governancePool;

    //token staked all amount
    mapping(address => uint256) _token_staked_total;

    //token staked per address amount
    mapping(address => mapping(address => uint256)) private _staked_balances;

    //token -> fee to back
    mapping(address => uint256) private _fee_pool;

    //revenue
    mapping(address => mapping(address => uint256)) private _staked_balances_income;

    //retrieval
    mapping(address => mapping(address => uint256)) private _staked_balances_retrieval;

    bytes4 private constant SELECTOR = bytes4(keccak256(bytes('transfer(address,uint256)')));
    function _safeTransfer(address token, address to, uint value) private {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(SELECTOR, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'HZL: TRANSFER_FAILED');
    }

    function upgradeTo(address newHzlMining) public onlyAdmin {
        _hzlMining = newHzlMining;
    }

    function setActive() public onlyAdmin {
        flag = ACTIVE;
    }

    function setNoActive() public onlyAdmin {
        flag = NO_ACTIVE;
    }

    function stake(bytes32 _id, uint256 amount)
        external 
        lock 
        onlyOneBlock
        whenActive
    {
        require(amount > 0, "Hzl:stake:!amount");
        address tokenAddress = hzlRegisty.getAddr(_id);
        require(hzlRegisty.isRegistered(_id), "Hzl:stake:!amount");
        _token_staked_total[tokenAddress] = _token_staked_total[tokenAddress].add(amount);
        _staked_balances[tokenAddress][msg.sender] = _staked_balances[tokenAddress][msg.sender].add(amount);
        _safeTransfer(tokenAddress, address(this), amount);
    }

    function query(bytes32 _id) 
        public
        view
        whenActive
        returns (uint256)
    {
        HzlMining hzlMining = HzlMining(_hzlMining);
        uint256 price = hzlMining.queryCurrent(_id);
        return price;
    }
    
}