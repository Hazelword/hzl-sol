// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.0;

import "./HzlBase.sol";
import "./HzlToken.sol";
import "./interface/IHzlMining.sol";
import "./lib/SafeERC20.sol";
import "./lib/SafeMath.sol";
import "./base/ERC20.sol";

/// @title the mining logic of hazelword
/// @author ydong
/// @notice You can use this contract only for quote
/// @dev All function calls are currently implemented without side effects
contract HzlMining is HzlBase, IHzlMining{

    using SafeMath for uint256; 
    using SafeERC20 for ERC20;

    address _governance;

    bool init = false;

    bytes4 private constant SELECTOR = bytes4(keccak256(bytes('transfer(address,uint256)')));

    event Quote(address indexed sender, address indexed tokenAddress, uint num, uint usdtNum);

    event NewBlock(address indexed sender, uint chainBlockNumeber, uint hzlBlockNumeber);

    event CloseOrder(address indexed sender, address indexed tokenAddress, uint index);

    event TakeOrder(address indexed sender, address indexed tokenAddress, uint index, uint amount);

    event Freeze(address indexed sender, uint amount);
    event UnFreeze(address indexed sender, uint amount);

    uint private unlocked = 1;
    modifier lock() {
        require(unlocked == 1, 'HZL: LOCKED');
        unlocked = 0;
        _;
        unlocked = 1;
    }

    modifier onlyGovernance() {
        require(
            msg.sender == _governance,
            "Only governance can call this."
        );
        _;
    }

    modifier onlyOnce() {
        require(
            !init,
            "Only once call this."
        );
        _;
    }

    constructor(address governance) {
        _governance = governance;
        blockInfo.HZL_GENESIS_BLOCK = block.number;
    }

    function initialize() external onlyOnce {
        
        //PriceMarket storage market = _priceChain[GENESIS_BLOCK];

        init = true;
    }
    
     function testInitialize() external onlyOnce {
        
        MiningConfig memory test = MiningConfig({
            pledgeUnit: 20000,
            feeUnit: 10,
            minnerReward: 100,
            miningRange: 15
        });
        miningConfig = test;
        tokenPair[USDT_TOKEN] = address(0x652c9ACcC53e765e1d96e2455E618dAaB79bA595);
        tokenPair[HZL_TOKEN] = address(0x417Bf7C9dc415FEEb693B6FE313d1186C692600F);
        tokenPair["BTC"] = address(0xa131AD247055FD2e2aA8b156A11bdEc81b9eAD95);
        init = true;
    }

    function stratQuotePair(address tokenAddress) public onlyGovernance {
        _quotePair[tokenAddress] = true;
    }

    function stopQuotePair(address tokenAddress) public onlyGovernance {
        _quotePair[tokenAddress] = false;
    }
    
    function addQuotePair(bytes32 name, address tokenAddress) public onlyGovernance {
        require(!_quotePair[tokenAddress], "HZL: MUST_STOP!");
        tokenPair[name] = tokenAddress;
    }

    function _safeTransfer(address token, address to, uint value) private {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(SELECTOR, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'HZL: TRANSFER_FAILED');
    }
    

    /// @notice Post a price for TOKEN/USDT
    /// @dev TOKEN is ERC20
    /// @param tokenAddress The address of TOKEN contract
    /// @param num The numbers of TOKEN to quote
    /// @param usdtNum The price of TOKEN
    function quote(address tokenAddress, uint num, uint usdtNum) public payable {
        
        require(_quotePair[tokenAddress], "not support is token address");
        require(num > 0 && usdtNum >0, "num must greater than 0");

        require(isMiners(), "user not miners");
        PriceMarket storage market = _priceChain[blockInfo.HZL_CURRENT_BLOCK];
        PriceSheet[] storage priceSheets = market._priceSheets[tokenAddress];

        uint256 chainBlockNumber = block.number;
        if((chainBlockNumber - blockInfo.LAST_CHAIN_BLOCK) >= miningConfig.pledgeUnit) {
            //settlement of quotations for T1 period
            settlement();
        }

        uint256 index = priceSheets.length;
        uint32 precision = _precisions[tokenAddress];

        uint256 price = usdtNum.div(num).mul(precision);
        
        //build PriceSheet
        PriceSheet memory priceSheet = PriceSheet({
            index: index,
            minner: msg.sender,
            height: chainBlockNumber,
            token: num,
            usdt: usdtNum,
            price: price,
            remainToken: num,
            remainUsdt: usdtNum,
            calNum: num,
            level: 0,
            precision: precision,
            effect: true
        });

        //end, quote success
        blockInfo.LAST_CHAIN_BLOCK = chainBlockNumber;

        //generate new block
        blockInfo.HZL_CURRENT_BLOCK = blockInfo.HZL_CURRENT_BLOCK + 1;
        //new a block
        PriceMarket storage newmarket = _priceChain[blockInfo.HZL_CURRENT_BLOCK];
        //continue
        newmarket._quotePairs = market._quotePairs;

        //add priceSheet
        newmarket._priceSheets[tokenAddress].push(priceSheet);

        emit Quote(msg.sender, tokenAddress, num, usdtNum);
    }

    /// @notice settlement for all TOKEN/USDT
    /// @dev TOKEN in qutoPairs
    function settlement() private  {
        uint256 blockNumber = blockInfo.HZL_CURRENT_BLOCK;
        PriceMarket storage market = _priceChain[blockNumber];
        address[] storage qutoPairs = market._quotePairs;
        HzlBlock storage hzlblock = _hzlChain[blockNumber];
        hzlblock._quotePairs = qutoPairs;
        //settlement all token
        for(uint i = 0; i < qutoPairs.length; i++) {
            //the token for quote sheets
            address tokenAddress = qutoPairs[i];
            PriceSheet[] storage priceSheets = market._priceSheets[tokenAddress];
            uint256 len = priceSheets.length;
            uint256 allPrice;
            uint256 allNum;
            uint256 allCount;
            for(uint j = 0; j < len; j++) {
                PriceSheet storage ps = priceSheets[j];
                if(ps.level == uint32(0)){
                    // origin quote will be calculated
                    allNum = allNum + ps.calNum;
                    allCount = allCount + 1;
                }
                
            }
            
            for(uint j = 0; j < len; j++) {
                PriceSheet storage ps = priceSheets[j];
                if(ps.level == uint32(0)){
                    // origin quote will be calculated
                    allPrice = allPrice + ps.price.mul(ps.calNum).div(allNum);
                }
                
            }
            //cal the price for this token
            uint256 price = allPrice.div(allCount);
            hzlblock._price[tokenAddress] = price;

            emit NewBlock(msg.sender, block.number, blockNumber);
        }
        
    }
    
    /// @notice need invoke by onlyGovernance
    /// @dev query currently price
    /// @param tokenAddress The address of TOKEN contract
    function queryCurrent(address tokenAddress) public view onlyGovernance returns (uint256) {
        require(_quotePair[tokenAddress], "not support is token address");
        uint256 blockNumber = blockInfo.HZL_CURRENT_BLOCK;
        HzlBlock storage hzlblock = _hzlChain[blockNumber];
        
        return hzlblock._price[tokenAddress];
    }

    /// @notice close one order byself
    /// @dev closed order will not cal
    /// @param tokenAddress The address of TOKEN contract
    /// @param index The numbers of TOKEN to quote
    function closeOrder(address tokenAddress, uint index) public {
        PriceMarket storage market = _priceChain[blockInfo.HZL_CURRENT_BLOCK];
        PriceSheet storage priceSheet = market._priceSheets[tokenAddress][index];
        require(priceSheet.minner == msg.sender, "user not the Order miners!");
        //set level=1,this order will not be cal in this block
        priceSheet.level = 1;
        emit CloseOrder(msg.sender, tokenAddress, index);
    }

    /// @notice close all order byself
    /// @dev closed order will not cal
    function closeAllOrder(address tokenAddress) public {
        PriceMarket storage market = _priceChain[blockInfo.HZL_CURRENT_BLOCK];
        PriceSheet[] storage priceSheets = market._priceSheets[tokenAddress];
        for(uint j = 0; j < priceSheets.length; j++) {
            PriceSheet storage priceSheet = priceSheets[j];
            if(priceSheet.minner == msg.sender) {
                priceSheet.level = 1;
            }
        }
        emit CloseOrder(msg.sender, tokenAddress, uint(9999));
    }

    function takeOrderToken(address tokenAddress, uint256 index, uint256 num) public lock {
        PriceMarket storage market = _priceChain[blockInfo.HZL_CURRENT_BLOCK];
        PriceSheet[] storage priceSheets = market._priceSheets[tokenAddress];
        require(index < priceSheets.length, "HZL: TRADE_FAILED_OUTINDEX");
        PriceSheet storage priceSheet = priceSheets[index];
        require(num <= priceSheet.remainToken, "HZL: TRADE_FAILED_OUTNUMBER");
        ERC20 usdt = ERC20(getTokenAddress(USDT_TOKEN));
        ERC20 tToken =  ERC20(tokenAddress);
        {//pay
            //need to pay ustd
            uint256 pay = priceSheet.price.mul(num);
            //transfer ustd to priceSheet this
            usdt.transfer(address(this), pay);
            //add remain usdt token
            priceSheet.remainUsdt = priceSheet.remainUsdt.add(pay);
        }
        {//get
            tToken.transfer(msg.sender, num);
            priceSheet.remainToken = priceSheet.remainToken.sub(num);
        }

        emit TakeOrder(msg.sender, tokenAddress, index, num);
    }

    function takeOrderUstd(address tokenAddress, uint256 index, uint256 num) public lock {
        PriceMarket storage market = _priceChain[blockInfo.HZL_CURRENT_BLOCK];
        PriceSheet[] storage priceSheets = market._priceSheets[tokenAddress];
        require(index < priceSheets.length, "HZL: TRADE_FAILED_OUTINDEX");
        PriceSheet storage priceSheet = priceSheets[index];
        require(num <= priceSheet.remainUsdt, "HZL: TRADE_FAILED_OUTNUMBER");
        ERC20 usdt = ERC20(getTokenAddress(USDT_TOKEN));
        ERC20 tToken =  ERC20(tokenAddress);
        {//pay
            //need to pay ustd
            uint256 pay = num.div(priceSheet.price);
            //transfer ustd to priceSheet this
            tToken.transfer(address(this), pay);
            //add remain usdt token
            priceSheet.remainToken = priceSheet.remainToken.add(pay);
        }
        {//get
            usdt.transfer(msg.sender, num);
            priceSheet.remainUsdt = priceSheet.remainUsdt.sub(num);
        }
        emit TakeOrder(msg.sender, tokenAddress, index, num);
    }

    /// @notice freeze hzl will become a minner 
    /// @dev freeze some hzl
    function freeze() public override returns (bool){
        ERC20 hzl =  ERC20(getTokenAddress(HZL_TOKEN));
        require(!isMiners(), "repetitive operation!");
        require(hzl.balanceOf(tx.origin) > miningConfig.pledgeUnit, "pledge not enough!");
        hzl.safeTransferFrom(msg.sender, address(this), miningConfig.pledgeUnit);
        minners[msg.sender] = true;
        emit Freeze(msg.sender, miningConfig.pledgeUnit);
        return true;
    }

    /// @notice unfreeze is the opposite of  freeze
    /// @dev take back freeze hzl
    function unfreeze() public override returns (bool){
        require(isMiners(), "not allow!");
        ERC20 hzl =  ERC20(getTokenAddress(HZL_TOKEN));
        minners[msg.sender] = false;
        hzl.safeTransfer(address(this), miningConfig.pledgeUnit);
        emit UnFreeze(msg.sender, miningConfig.pledgeUnit);
        return true;
    }

    /// @notice miner can quote and takeOrder
    /// @dev whether or not a miner
    function isMiners() public override view returns (bool){

        return minners[msg.sender];
    }

    function isTokenAddress(address tokenAddress) public view returns (bool){
        return _quotePair[tokenAddress];
    }

}