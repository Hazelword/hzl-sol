require('dotenv').config()
const { expect } = require('chai');
const hre = require('hardhat');
const ethers = hre.ethers;


const HzlToken = artifacts.require("HzlToken");
const ERC20Token = artifacts.require("ERC20Token");

const { balanceOf, Float2BN, approve,USDT,HZL,HZLMining,HZLConfig } = require('./utils/common');

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
    MINING_CONTRACT = await HZLMining(accounts[3]);
    CONFIG_CONTRACT = await HZLConfig(accounts[2]);
  });

  describe("quote", function() {

    it("print", async function() {

      const config_addr = await MINING_CONTRACT.getConfig();
      const registry_addr = await MINING_CONTRACT.getRegistry();
      console.log("config_addr", config_addr);
      console.log("registry_addr", registry_addr);

      const hzl_balance = await balanceOf(process.env.HZL_ADDR, accounts[2]);
      console.log("hzl_balance: ", hzl_balance);

      const pledgeUnit = await CONFIG_CONTRACT.getPledgeUnit();
      console.log("pledgeUnit:", hre.ethers.utils.formatUnits(pledgeUnit.toString(), 18));

      console.log(await MINING_CONTRACT.isMiners(accounts[3]))
    });


    it("freeze", async function() {


      await approve(accounts[3], process.env.MINING_ADDR, Float2BN('100000',18), HZL_ADDR);

      console.log(1);
      await MINING_CONTRACT.freeze();
      console.log(2);
    });
  });
});