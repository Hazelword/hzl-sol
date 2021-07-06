require('dotenv').config()
const { expect } = require('chai');
const hre = require('hardhat');
const ethers = hre.ethers;


const { balanceOf, BN2Float, Float2BN } = require('./utils/common');

describe("HZLConfig", function() {

  const OWNER_ACC = process.env.ADDRESS1;
  const signer = ethers.provider.getSigner(OWNER_ACC);


  let accounts;

  before(async function() {
    accounts = await web3.eth.getAccounts();
  });

  describe("log", function() {


    // it("set config", async function() {
    //   const HZLConfig = await hre.ethers.getContractFactory('HZLConfig', signer);
    //   const config = await HZLConfig.attach(process.env.CONFIG_ADDR);

    //   config.connect(signer);
    //   const pledgeUnit = Float2BN("10000", 18);
    //   const feeUnit = Float2BN("10", 18);
    //   const minnerReward = Float2BN("100", 18);
    //   const miningRange = Float2BN("15", 18);
    //   await config.updateConfig(10000, 10*10**18, 100*10**18, 15*10**18);
    // });

    it("print pledgeUnit", async function() {
      const HZLConfig = await hre.ethers.getContractFactory('HZLConfig', signer);
      const config = await HZLConfig.attach(process.env.CONFIG_ADDR);

      config.connect(signer);

      const pledgeUnit = await config.getPledgeUnit();
      console.log("pledgeUnit:", BN2Float(pledgeUnit, 18));

      const feeUnit = await config.getFeeUnit();
      console.log("feeUnit:", BN2Float(feeUnit, 18));

      const minnerReward = await config.getMinnerReward();
      console.log("minnerReward:", BN2Float(minnerReward, 18));

      const miningRange = await config.getMiningRange();
      console.log("miningRange:", miningRange.toString());
    });
  });
});