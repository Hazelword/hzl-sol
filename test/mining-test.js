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

  describe("transfer hzl", function() {
    it("transfer 100", async function() {
      const HZLToken = await hre.ethers.getContractFactory('HzlToken', signer);
      const hzlToken = await HZLToken.attach(process.env.HZL_ADDR);
      hzlToken.connect(signer);
      let totalSupply = await hzlToken.totalSupply();
      console.log("totalSupply:", totalSupply.toNumber());
      assert.equal(totalSupply.toNumber() > 0, true);
      
      await hzlToken.mint(100, accounts[0]);
      const balance = await balanceOf(process.env.HZL_ADDR, accounts[0])
      console.log("balance:", balance.toNumber());
      assert.equal(balance.toNumber()>100, true);
    });
  });
});