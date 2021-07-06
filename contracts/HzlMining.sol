// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.0;

import "./HzlBase.sol";
import "./HzlToken.sol";
import "./interface/IHzlMining.sol";
import "./lib/SafeERC20.sol";
import "./lib/SafeMath.sol";
import "./base/ERC20.sol";
import "./base/Lock.sol";
import "./base/Miners.sol";
import "./auth/AdminAuth.sol";

import "./core/HZLConfig.sol";
import "./core/HZLRegistry.sol";

/// @title the mining logic of hazelword
/// @author ydong
/// @notice You can use this contract only for quote
/// @dev All function calls are currently implemented without side effects
contract HzlMining is HzlBase, AdminAuth, IHzlMining, Lock, Miners{

    using SafeMath for uint256; 
    using SafeERC20 for ERC20;

    bytes4 private constant SELECTOR = bytes4(keccak256(bytes('transfer(address,uint256)')));

    event Quote(address indexed sender, address indexed tokenAddress, uint num, uint usdtNum);

    event NewBlock(address indexed sender, uint chainBlockNumeber, uint hzlBlockNumeber);

    event CloseOrder(address indexed sender, address indexed tokenAddress, uint index);

    event TakeOrder(address indexed sender, address indexed tokenAddress, uint index, uint amount);

    event Freeze(address indexed sender, uint amount);
    event UnFreeze(address indexed sender, uint amount);

    constructor() {
        blockInfo.HZL_GENESIS_BLOCK = block.number;
    }

    address public constant HZL_CONFIG_ADDR = 0x78D714e1b47Bb86FE15788B917C9CC7B77975529;

    address public constant HZL_REGISTRY_ADDR = 0x85b108660f47caDfAB9e0503104C08C1c96e0DA9;


    HZLConfig hzlConfig = HZLConfig(HZL_CONFIG_ADDR);

    HZLRegistry hzlRegisty = HZLRegistry(HZL_REGISTRY_ADDR);

    function initialize() external onlyGovernances {
        //PriceMarket storage market = _priceChain[GENESIS_BLOCK];
        init = true;
    }

    function updateConfig(address config) external onlyGovernances {
        hzlConfig = HZLConfig(config);
    }

    function getConfig() external view returns(address) {
        return address(hzlConfig);
    }

    function updateRegistry(address registry) external onlyGovernances {
        hzlRegisty = HZLRegistry(registry);
    }

    function getRegistry() external view returns(address) {
        return address(hzlRegisty);
    }


    /// @notice Post a price for TOKEN/USDT
    /// @dev TOKEN is ERC20
    /// @param tokenAddress The address of TOKEN contract
    /// @param num The numbers of TOKEN to quote
    /// @param usdtNum The price of TOKEN
    function quote(address tokenAddress, uint num, uint usdtNum) public onlyMiners payable {
        
        require(hzlRegisty.isRegistered(tokenAddress), "not support is token address");
        require(num > 0 && usdtNum >0, "num must greater than 0");

        PriceMarket storage market = _priceChain[blockInfo.HZL_CURRENT_BLOCK];
        PriceSheet[] storage priceSheets = market._priceSheets[tokenAddress];

        uint256 chainBlockNumber = block.number;
        if((chainBlockNumber - blockInfo.LAST_CHAIN_BLOCK) >= hzlConfig.getMiningRange()) {
            //settlement of quotations for T1 period
            _settlement();
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
    function _settlement() private  {
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
    function queryCurrent(address tokenAddress) public view onlyGovernances returns (uint256) {
        require(hzlRegisty.isRegistered(tokenAddress), "not support is token address");

        uint256 blockNumber = blockInfo.HZL_CURRENT_BLOCK;
        HzlBlock storage hzlblock = _hzlChain[blockNumber];
        
        return hzlblock._price[tokenAddress];
    }

    /// @notice close one order
    /// @dev Id is keccak256 of the contract name
    /// @param tokenAddress The address of TOKEN contract
    /// @param index The numbers of TOKEN to quote
    function closeOrder(address tokenAddress, uint index) public override onlyMiners lock {
        PriceMarket storage market = _priceChain[blockInfo.HZL_CURRENT_BLOCK];
        PriceSheet storage priceSheet = market._priceSheets[tokenAddress][index];
        require(priceSheet.minner == msg.sender, "user not the Order miners!");
        //set level=1,this order will not be cal in this block
        priceSheet.level = 1;
        emit CloseOrder(msg.sender, tokenAddress, index);
    }

    /// @notice close all order byself
    /// @dev closed order will not cal
    function closeAllOrder(address tokenAddress) public override onlyMiners lock {
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

    function takeOrderToken(address tokenAddress, uint256 index, uint256 num) public override onlyMiners lock {
        PriceMarket storage market = _priceChain[blockInfo.HZL_CURRENT_BLOCK];
        PriceSheet[] storage priceSheets = market._priceSheets[tokenAddress];
        require(index < priceSheets.length, "HZL: TRADE_FAILED_OUTINDEX");
        PriceSheet storage priceSheet = priceSheets[index];
        require(num <= priceSheet.remainToken, "HZL: TRADE_FAILED_OUTNUMBER");
        ERC20 usdt = ERC20(hzlRegisty.getAddr(USDT_TOKEN));
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

    function takeOrderUstd(address tokenAddress, uint256 index, uint256 num) public override onlyMiners lock {
        PriceMarket storage market = _priceChain[blockInfo.HZL_CURRENT_BLOCK];
        PriceSheet[] storage priceSheets = market._priceSheets[tokenAddress];
        require(index < priceSheets.length, "HZL: TRADE_FAILED_OUTINDEX");
        PriceSheet storage priceSheet = priceSheets[index];
        require(num <= priceSheet.remainUsdt, "HZL: TRADE_FAILED_OUTNUMBER");
        ERC20 usdt = ERC20(hzlRegisty.getAddr(USDT_TOKEN));
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
    function freeze() public override onlyNotMiners {
        ERC20 hzl =  ERC20(hzlRegisty.getAddr(HZL_TOKEN));
        hzl.safeTransferFrom(msg.sender, address(this), hzlConfig.getPledgeUnit());
        minners[msg.sender] = true;
        emit Freeze(msg.sender, hzlConfig.getPledgeUnit());
    }

    /// @notice unfreeze is the opposite of  freeze
    /// @dev take back freeze hzl
    function unfreeze() public override onlyMiners {
        ERC20 hzl =  ERC20(hzlRegisty.getAddr(HZL_TOKEN));
        minners[msg.sender] = false;
        hzl.safeTransfer(address(this), hzlConfig.getPledgeUnit());
        emit UnFreeze(msg.sender, hzlConfig.getPledgeUnit());
    }
}