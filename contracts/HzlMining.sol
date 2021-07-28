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

//use test
import "hardhat/console.sol";

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
        blockInfo.HZL_CURRENT_BLOCK = 1;
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
        uint32 precision = hzlConfig.getPrecision(tokenAddress);
        ERC20 usdt_erc20 =  ERC20(hzlRegisty.getAddr(USDT_TOKEN));
        usdt_erc20.safeTransferFrom(msg.sender, address(this), usdtNum);

        ERC20 token_erc20 =  ERC20(tokenAddress);
        token_erc20.safeTransferFrom(msg.sender, address(this), num);

        PriceMarket storage market = _priceChain[blockInfo.HZL_CURRENT_BLOCK];
        PriceSheet[] storage priceSheets = market._priceSheets[tokenAddress];
        market._quotePairs = hzlRegisty.getQuotePairs();

        console.log("hzl_current_block is %s ", blockInfo.HZL_CURRENT_BLOCK);

        uint256 chainBlockNumber = block.number;
        // if((chainBlockNumber - blockInfo.LAST_CHAIN_BLOCK) >= hzlConfig.getMiningRange()) {
        //     //settlement of quotations for T1 period
        //     console.log("block_number is %s, ############ settlement", chainBlockNumber);
        //     _settlement();
        // }

        uint256 index = priceSheets.length;
        
        uint256 price = usdtNum.mul(precision).div(num);

        console.log("index is %s,precision is %s ,price is %s  ", index, precision, price);

        
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
            calNum: usdtNum,
            level: 0,
            precision: precision,
            effect: true
        });


        //continue
        PriceSheet[] storage me = market._priceSheets[tokenAddress];

        console.log("_priceSheets length is %s", me.length);
        //add priceSheet
        me.push(priceSheet);

        console.log("_priceSheets length push is %s", me.length);

        emit Quote(msg.sender, tokenAddress, num, usdtNum);
    }

    /// @notice settlement for all TOKEN/USDT
    /// @dev TOKEN in qutoPairs
    function settlement() public  {
        uint256 chainBlockNumber = block.number;
        if((chainBlockNumber - blockInfo.LAST_CHAIN_BLOCK) < hzlConfig.getMiningRange()) {
            //settlement of quotations for T1 period
            console.log("end, ############ settlement");
            return;
        }
        uint256 blockNumber = blockInfo.HZL_CURRENT_BLOCK;
        PriceMarket storage market = _priceChain[blockNumber];
        address[] storage qutoPairs = market._quotePairs;
        console.log("block_number is %s, qutoPairs is %s", blockNumber, qutoPairs.length);
        HzlBlock storage hzlblock = _hzlChain[blockNumber];
        hzlblock._quotePairs = qutoPairs;
        //settlement all token
        for(uint i = 0; i < qutoPairs.length; i++) {
            //the token for quote sheets
            address tokenAddress = qutoPairs[i];
            console.log("settlement is %s", tokenAddress);
            PriceSheet[] storage priceSheets = market._priceSheets[tokenAddress];
            uint32 precision = hzlConfig.getPrecision(tokenAddress);
            uint256 len = priceSheets.length;
            if(len == uint256(0)){
                hzlblock._price[tokenAddress] = _hzlChain[blockNumber-1]._price[tokenAddress];
                console.log("use last price is %s ", hzlblock._price[tokenAddress]);
                break;
            }
            uint256 allPrice;
            uint256 allNum;
            uint256 allCount;
            for(uint j = 0; j < len; j++) {
                PriceSheet storage ps = priceSheets[j];
                if(ps.level == uint32(0)){
                    // origin quote will be calculated
                    if(ps.remainToken < ps.token) {
                        uint lost = ps.token.sub(ps.remainToken).mul(ps.price).div(uint(precision));
                        ps.calNum = ps.usdt.sub(lost);
                    }
                    allNum = allNum + ps.calNum;
                    allCount = allCount + 1;
                }
                
            }
            
            for(uint j = 0; j < len; j++) {
                PriceSheet storage ps = priceSheets[j];
                if(ps.level == uint32(0)){
                    // origin quote will be calculated
                    uint256 one_price = ps.price.mul(ps.calNum).div(allNum);
                    console.log("one_price is %s, calNum is %s", one_price, ps.calNum);
                    allPrice = allPrice + one_price;
                }
                
            }
            console.log("allPrice is %s, allNum is %s, allCount is %s", allPrice, allNum, allCount);
            //cal the price for this token
            //uint256 price = allPrice.div(allNum);
            hzlblock._price[tokenAddress] = allPrice;
            console.log("allNum is %s,price is %s  ", allNum, allPrice);
        
            emit NewBlock(msg.sender, block.number, blockNumber);
        }

        //end, quote success
        blockInfo.LAST_CHAIN_BLOCK = block.number;
        //generate new block
        blockInfo.HZL_CURRENT_BLOCK = blockInfo.HZL_CURRENT_BLOCK + 1;

        if(blockNumber > 10){
            uint256 withdrawNumber = blockNumber - 10;
            PriceMarket storage withdraw_market = _priceChain[withdrawNumber];
            address[] storage withdraw_qutoPairs = market._quotePairs;
            console.log("withdrawNumber is %s", withdrawNumber);
            //settlement all token
            for(uint i = 0; i < withdraw_qutoPairs.length; i++) {
                //the token for quote sheets
                address tokenAddress = withdraw_qutoPairs[i];
                PriceSheet[] storage priceSheets = withdraw_market._priceSheets[tokenAddress];
                uint256 len = priceSheets.length;
                ERC20 token_erc20 =  ERC20(tokenAddress);

                for(uint j = 0; j < len; j++) {
                    PriceSheet storage ps = priceSheets[j];
                    if(ps.remainUsdt > 0){
                        ERC20 usdt_erc20 =  ERC20(hzlRegisty.getAddr(USDT_TOKEN));
                        usdt_erc20.safeTransfer(ps.minner, ps.remainUsdt);
                    }
                    if(ps.remainToken > 0){
                        token_erc20.safeTransfer(ps.minner, ps.remainToken);
                    }
                }
            }
        }
        
    }
    
    /// @notice need invoke by onlyGovernance
    /// @dev query currently price
    /// @param tokenAddress The address of TOKEN contract
    function queryCurrent(address tokenAddress) public view onlyGovernances returns (uint256) {
        require(hzlRegisty.isRegistered(tokenAddress), "not support is token address");

        uint256 blockNumber = blockInfo.HZL_CURRENT_BLOCK - 1;
        HzlBlock storage hzlblock = _hzlChain[blockNumber];
        uint price = hzlblock._price[tokenAddress];

        console.log("blockNumber is %s, price is %s", blockNumber, price);
        
        return price;
    }

    /// @notice query Current Market token address
    function queryCurrentMarketToken() public view returns (address[] memory) {
        uint256 blockNumber = blockInfo.HZL_CURRENT_BLOCK;
        PriceMarket storage market = _priceChain[blockNumber];
        
        return market._quotePairs;
    }

    /// @notice query Current Market Order
    function queryCurrentMarketOrder(address tokenAddress) public view returns (uint256) {

        require(hzlRegisty.isRegistered(tokenAddress), "address not registered");
        uint256 blockNumber = blockInfo.HZL_CURRENT_BLOCK;
        PriceMarket storage market = _priceChain[blockNumber];
        PriceSheet[] storage priceSheets = market._priceSheets[tokenAddress];

        return priceSheets.length;
    }

    function queryCurrentMarketOrderIndex(address tokenAddress, uint index) 
        public 
        view 
        returns (
            uint256 indexKey,
            uint256 token,
            uint256 usdt,
            uint256 price,
            uint256 remainToken,
            uint256 remainUsdt,
            uint32 level,
            uint32 precision
        ) {

        require(hzlRegisty.isRegistered(tokenAddress), "address not registered");
        uint256 blockNumber = blockInfo.HZL_CURRENT_BLOCK;
        PriceMarket storage market = _priceChain[blockNumber];
        PriceSheet storage priceSheets = market._priceSheets[tokenAddress][index];

        return (index, priceSheets.token, priceSheets.usdt, priceSheets.price, priceSheets.remainToken, priceSheets.remainUsdt, priceSheets.level, priceSheets.precision);
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