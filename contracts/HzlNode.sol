// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.0;

import "./HzlMining.sol";
import "./lib/SafeMath.sol";

//stake and quory
contract HzlNode {

    using SafeMath for uint256;

    address _hzlMining;

    address _governance;

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

    uint private unlocked = 1;
    modifier lock() {
        require(unlocked == 1, 'HZL: LOCKED');
        unlocked = 0;
        _;
        unlocked = 1;
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

    modifier onlyGovernance() {
        require(
            msg.sender == _governance,
            "Only governance can call this."
        );
        _;
    }

    constructor(address governance) {
        _governance = governance;
    }

    function upgradeTo(address newHzlMining) public {
        _hzlMining = newHzlMining;
    }

    function setActive() public {
        flag = ACTIVE;
    }

    function setNoActive() public {
        flag = NO_ACTIVE;
    }

    function stake(address tokenAddress, uint256 amount)
        external 
        lock 
        onlyOneBlock
        whenActive
    {
        require(amount > 0, "Hzl:stake:!amount");
        HzlMining hzlMining = HzlMining(_hzlMining);
        require(hzlMining.isTokenAddress(tokenAddress), "Hzl:stake:!amount");
        _token_staked_total[tokenAddress] = _token_staked_total[tokenAddress].add(amount);
        _staked_balances[tokenAddress][msg.sender] = _staked_balances[tokenAddress][msg.sender].add(amount);
        _safeTransfer(tokenAddress, address(this), amount);
    }

    function query(address token) 
        public
        view
        whenActive
        returns (uint256)
    {
        HzlMining hzlMining = HzlMining(_hzlMining);
        uint256 price = hzlMining.queryCurrent(token);
        return price;
    }


    function _safeTransfer(address token, address to, uint value) private {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(SELECTOR, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'HZL: TRANSFER_FAILED');
    }
    
    
}