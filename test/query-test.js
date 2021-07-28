require('dotenv').config()
const { expect } = require('chai');
const hre = require('hardhat');
const ethers = hre.ethers;


const HzlToken = artifacts.require("HzlToken");
const ERC20Token = artifacts.require("ERC20Token");

const { balanceOf, Float2BN,BN2Float, approve,freeze,USDT,HZL,HZLMining,HZLConfig } = require('./utils/common');

describe("HzlMining", function() {

  const OWNER_ACC = process.env.ADDRESS1;
  const signer = ethers.provider.getSigner(OWNER_ACC);

  const HZL_ADDR = process.env.HZL_ADDR;
  const BTC_ADDR = process.env.BTC_ADDR;
  const ETH_ADDR = process.env.ETH_ADDR;
  const USDT_ADDR = process.env.USDT_ADDR;


  let accounts;
  let MINING_CONTRACT;


  before(async function() {
    
    accounts = await web3.eth.getAccounts();
    MINING_CONTRACT = await HZLMining(accounts[0]);
  });

  function sleep(delay) {
    var start = (new Date()).getTime();
    while ((new Date()).getTime() - start < delay) {
        // 使用  continue 实现；
        continue; 
    }
  }

  function toNumber(rs){
    let index = rs[0].toNumber();
    let token = BN2Float(rs[1], 18);
    let usdt = BN2Float(rs[2], 18);
    let price = rs[3].toNumber();
    let remainToken = BN2Float(rs[4], 18);
    let remainUsdt = BN2Float(rs[5], 18);
    let level = rs[6];
    let precision = rs[7];
    console.log("index:{},token:{},usdt:{},price:{},remainToken:{},remainUsdt:{}, level:{}, precision:{}", 
    index,token,usdt,price,remainToken,remainUsdt,level,precision);
  }

  const print = async function(token) {
    const btc_price = await MINING_CONTRACT.queryCurrent(token);
    console.log("btc_price:", btc_price.toString());
  }

  describe("query", function() {

    it("query BTC", async function() {

      const len = await MINING_CONTRACT.queryCurrentMarketOrder(BTC_ADDR);
      let length = len.toNumber();
      console.log(BTC_ADDR, length);
      for(let i=0; i<length; i++){
        let order = await MINING_CONTRACT.queryCurrentMarketOrderIndex(BTC_ADDR, i);
        toNumber(order);
      }
      await print(BTC_ADDR);
    });

    it("query ETH", async function() {

      const len = await MINING_CONTRACT.queryCurrentMarketOrder(ETH_ADDR);
      
      let length = len.toNumber();
      console.log(ETH_ADDR, length);
      for(let i=0; i<length; i++){
        let order = await MINING_CONTRACT.queryCurrentMarketOrderIndex(ETH_ADDR, i);
        toNumber(order);
      }
      await print(ETH_ADDR);
    });


  });
});