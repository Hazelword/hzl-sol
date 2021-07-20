// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.0;

contract HzlBase {

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


    bytes32 USDT_TOKEN = keccak256('usdt');

    bytes32 HZL_TOKEN = keccak256('hzl');

    bytes32 HZL_REGISTRY = keccak256('HZLRegistry');

    bytes32 HZL_CONFIG = keccak256('HZLConfig');

    //price sheet, token address => quote
    //mapping(address => PriceSheet[]) _priceSheets;

    //price chain, block number => price market
    mapping(uint256 => PriceMarket) _priceChain;

    //price chain, block number => price market
    mapping(uint256 => HzlBlock) _hzlChain;

    // the precision of price,(e.g 1000, means four decimal places)
    mapping(address => uint32) _precisions;

    PriceMarket currentPriceMarket;

    BlockInfo blockInfo;

    function getBlockInfo() public view returns(uint256, uint256, uint256) {
        return (blockInfo.HZL_CURRENT_BLOCK, blockInfo.HZL_GENESIS_BLOCK, blockInfo.LAST_CHAIN_BLOCK);
    }

}