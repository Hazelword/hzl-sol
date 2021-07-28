require('dotenv').config()
const { expect } = require('chai');
const hre = require('hardhat');
const ethers = hre.ethers;


const HzlToken = artifacts.require("HzlToken");
const ERC20Token = artifacts.require("ERC20Token");

const { balanceOf, Float2BN, approve,freeze,USDT,HZL,HZLMining,HZLConfig } = require('./utils/common');

describe("HzlMining", function() {

  const OWNER_ACC = process.env.ADDRESS1;
  const signer = ethers.provider.getSigner(OWNER_ACC);

  const HZL_ADDR = process.env.HZL_ADDR;
  const BTC_ADDR = process.env.BTC_ADDR;
  const ETH_ADDR = process.env.ETH_ADDR;
  const USDT_ADDR = process.env.USDT_ADDR;


  let accounts;
  let MINING_CONTRACT;
  let CONFIG_CONTRACT;

  let quoteusdt = ['60000','25000','45000', '5000'];
  let quotetoken = ['2','1','1.5', '0.1'];


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

  const print = async function() {
    const btc_price = await MINING_CONTRACT.queryCurrent(BTC_ADDR);
    console.log("btc_price:", btc_price.toString());
  }

  describe("quote", function() {

    it("quote", async function() {
      
      for(let i=0; i<quoteusdt.length; i++) {
        await approve(accounts[0], process.env.MINING_ADDR, Float2BN(quotetoken[i],18), BTC_ADDR);
        await approve(accounts[0], process.env.MINING_ADDR, Float2BN(quoteusdt[i],18), USDT_ADDR);
        console.log("approve", accounts[0])
        const tx = await MINING_CONTRACT.quote(BTC_ADDR, Float2BN(quotetoken[i],18), Float2BN(quoteusdt[i],18));
      }
    });

    // it("query", async function() {
    //   await print();
    //   await MINING_CONTRACT.settlement();
    //   await print();
    // });


  });
});