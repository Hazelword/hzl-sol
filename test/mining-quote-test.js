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


  before(async function() {
    
    accounts = await web3.eth.getAccounts();
    MINING_CONTRACT = await HZLMining(accounts[0]);
  });

  describe("quote", function() {

    it("print", async function() {
      const btc_price = await MINING_CONTRACT.queryCurrent(BTC_ADDR);
      console.log("btc_price:", btc_price.toString());
    });

    it("quote", async function() {
      await approve(accounts[0], process.env.MINING_ADDR, Float2BN('1',18), BTC_ADDR);
      await approve(accounts[0], process.env.MINING_ADDR, Float2BN('50000',18), USDT_ADDR);
      console.log("approve", accounts[0])
      const tx = await MINING_CONTRACT.quote(BTC_ADDR, Float2BN('1',18), Float2BN('30000',18));
      // for(let account of accounts) {
      //   let isMiners = await MINING_CONTRACT.isMiners(account);
      //   console.log("minner", account, isMiners)
      //   if(!isMiners) {
      //     await approve(account, process.env.MINING_ADDR, Float2BN('100000',18), HZL_ADDR);
      //     console.log("approve", account)
      //   }
      // }
    });

    it("settlement", async function() {
      const tx = await MINING_CONTRACT.settlement();
      // for(let account of accounts) {
      //   let isMiners = await MINING_CONTRACT.isMiners(account);
      //   console.log("minner", account, isMiners)
      //   if(!isMiners) {
      //     await approve(account, process.env.MINING_ADDR, Float2BN('100000',18), HZL_ADDR);
      //     console.log("approve", account)
      //   }
      // }
    });


  });
});