require('dotenv').config()
const { expect } = require('chai');
const hre = require('hardhat');
const ethers = hre.ethers;


const HzlToken = artifacts.require("HzlToken");
const ERC20Token = artifacts.require("ERC20Token");

const { balanceOf } = require('./utils/common');

describe("HzlMining", function() {

  const OWNER_ACC = process.env.ADDRESS1;
  const signer = ethers.provider.getSigner(OWNER_ACC);

  let accounts;

  before(async function() {
    accounts = await web3.eth.getAccounts();
  });

  describe("quote", function() {


    it("freeze", async function() {
      const HzlMining = await hre.ethers.getContractFactory('HzlMining', signer);
      const hzlMining = await HzlMining.attach(process.env.MINING_ADDR);
      const accounts5 = ethers.provider.getSigner(accounts[5]);

      const hzl_balance = await balanceOf(process.env.HZL_ADDR, accounts[5]);
      console.log("hzl_balance: ", hzl_balance);

      const HZLConfig = await hre.ethers.getContractFactory('HZLConfig', signer);
      const config = await HZLConfig.attach(process.env.CONFIG_ADDR);

      config.connect(signer);

      const pledgeUnit = await config.getPledgeUnit();
      console.log("pledgeUnit:", hre.ethers.utils.formatUnits(pledgeUnit.toString(), 18));

      hzlMining.connect(accounts5);
      console.log(1);
      await hzlMining.freeze();
      console.log(2);
    });
  });
});