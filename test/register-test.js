require('dotenv').config()
const { expect } = require('chai');
const hre = require('hardhat');
const ethers = hre.ethers;

const { balanceOf } = require('./utils/common');

describe("IHZLRegistry", function() {

  let OWNER_ACC;
  let signer;

  let accounts;

  before(async function() {
    accounts = await web3.eth.getAccounts();
    OWNER_ACC = accounts[0];
    signer = ethers.provider.getSigner(OWNER_ACC)
  });

  describe("config", function() {


    it("IHZLRegistry", async function() {
      const IHZLRegistry = await hre.ethers.getContractFactory('HZLRegistry', signer);
      const hzlRegistry = await IHZLRegistry.attach(process.env.REGISTRY_ADDR);
      hzlRegistry.connect(signer);

      const btc = ethers.utils.keccak256(ethers.utils.toUtf8Bytes('btc'));
      const eth = ethers.utils.keccak256(ethers.utils.toUtf8Bytes('eth'));
      const hzl = ethers.utils.keccak256(ethers.utils.toUtf8Bytes('hzl'));
      const usdt = ethers.utils.keccak256(ethers.utils.toUtf8Bytes('usdt'));

      //register
      let flag = await hzlRegistry.isRegistered(process.env.HZL_ADDR)
      if(!flag) {
        await hzlRegistry.addNewContract(hzl, process.env.HZL_ADDR);
      }
      flag = await hzlRegistry.isRegistered(process.env.USDT_ADDR)
      if(!flag) {
        await hzlRegistry.addNewContract(usdt, process.env.USDT_ADDR);
      }
      flag = await hzlRegistry.isRegistered(process.env.BTC_ADDR)
      if(!flag) {
        await hzlRegistry.addNewContract(btc, process.env.BTC_ADDR);
      }
      flag = await hzlRegistry.isRegistered(process.env.ETH_ADDR)
      if(!flag) {
        await hzlRegistry.addNewContract(eth, process.env.ETH_ADDR);
      }


      const addr_btc = await hzlRegistry.getAddr(btc);
      const addr_eth = await hzlRegistry.getAddr(eth);
      const addr_hzl = await hzlRegistry.getAddr(hzl);
      const addr_usdt = await hzlRegistry.getAddr(usdt);
      console.log("addr_btc:", btc, addr_btc);
      console.log("addr_eth:", eth, addr_eth);
      console.log("addr_hzl:", hzl, addr_hzl);
      console.log("addr_usdt:", usdt, addr_usdt);
    });

    it("IHZLConfig", async function() {
      const HZLConfig = await hre.ethers.getContractFactory('HZLConfig', signer);
      const hzlConfig = await HZLConfig.attach(process.env.CONFIG_ADDR);
      hzlConfig.connect(signer);

      await hzlConfig.addPrecisions(process.env.BTC_ADDR, 10000);
      await hzlConfig.addPrecisions(process.env.ETH_ADDR, 10000);
      await hzlConfig.addPrecisions(process.env.USDT_ADDR, 10000);
      await hzlConfig.addPrecisions(process.env.HZL_ADDR, 10000);
    });

    it("HzlMining register", async function() {
      const HzlMining = await hre.ethers.getContractFactory('HzlMining', signer);
      const hzl = await HzlMining.attach(process.env.MINING_ADDR);
      hzl.connect(signer);

      await hzl.updateConfig(process.env.CONFIG_ADDR);
      await hzl.updateRegistry(process.env.REGISTRY_ADDR);

    });
  });
});