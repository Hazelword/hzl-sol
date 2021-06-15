// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.0;

contract HzlBase {

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

    struct PriceSheet {
        // index of price sheet
        uint256 index;
        // minner address
        address minner;
        // current chain height
        uint256 height;
        // the number of token
        uint256 token;
        // the number of usdt
        uint256 usdt;
        //cal the price
        uint256 price;
        // the remain number of token
        uint256 remainToken;
        // the remain number of usdt
        uint256 remainUsdt;
        // the last be cal token
        uint256 calNum;
        //  0 expresses initial price sheet,  a value greater than 0 means not to be calculated int the end
        uint32 level;
        // the precision of price,(e.g 1000, means four decimal places)
        uint32 precision;
        // if remainToken or remainUsdt equal 0 ,then this price sheet is not effect
        bool effect;
    }

    struct BlockInfo {
        //HZL Genesis block
        uint256 HZL_GENESIS_BLOCK;

        //HZL current block
        uint256 HZL_CURRENT_BLOCK;

        //chain block
        uint256 LAST_CHAIN_BLOCK;
    }

    struct PriceMarket {
        address[] _quotePairs;
        mapping(address => PriceSheet[]) _priceSheets;
    }

    struct HzlBlock {
        address[] _quotePairs;
        mapping(address => uint256) _price;
    }


    bytes32 USDT_TOKEN = "usdt";

    bytes32 HZL_TOKEN = "hzl";


    //eg. usdt=>address, hzl=>address
    mapping(bytes32 => address) tokenPair;

    //quote trading pair, ture is Hazelword offered
    mapping(address => bool) _quotePair;

    //price sheet, token address => quote
    mapping(address => PriceSheet[]) _priceSheets;

    //price chain, block number => price market
    mapping(uint256 => PriceMarket) _priceChain;

    //price chain, block number => price market
    mapping(uint256 => HzlBlock) _hzlChain;

    //is minner?, user address => bool
    mapping(address => bool) minners;

    // the precision of price,(e.g 1000, means four decimal places)
    mapping(address => uint32) _precisions;

    PriceMarket currentPriceMarket;

    MiningConfig miningConfig;

    BlockInfo blockInfo;

    function getTokenAddress(bytes32 name) public view returns (address){
        return tokenPair[name];
    }

}