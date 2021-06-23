require('dotenv').config()
const { expect } = require('chai');
const hre = require('hardhat');
const ethers = hre.ethers;


const HzlToken = artifacts.require("HzlToken");
const ERC20Token = artifacts.require("ERC20Token");

const { balanceOf, send } = require('./utils/common');

describe("HzlMining", function() {

  const OWNER_ACC = process.env.ADDRESS1;
  const signer = ethers.provider.getSigner(OWNER_ACC);

  const HZL_ADDR = process.env.HZL_ADDR;
  const BTC_ADDR = process.env.BTC_ADDR;
  const ETH_ADDR = process.env.ETH_ADDR;
  const USDT_ADDR = process.env.USDT_ADDR;

  let accounts;
  let amount = "10000";

  before(async function() {
    accounts = await web3.eth.getAccounts();
  });

  describe("init", function() {
    it("transfer 10000", async function() {
      console.log("=========1===========")
      for(let account of accounts) {
        await send(signer, HZL_ADDR, account, amount);
        await send(signer, BTC_ADDR, account, amount);
        await send(signer, ETH_ADDR, account, amount);
        await send(signer, USDT_ADDR, account, amount);
      }
      console.log("========2============")
      for(let account of accounts) {
        let hzl_banlance = await balanceOf(HZL_ADDR, account);
        let btc_banlance = await balanceOf(BTC_ADDR, account);
        let eth_banlance = await balanceOf(ETH_ADDR, account);
        let usdt_banlance = await balanceOf(USDT_ADDR, account);
        console.log(account, "hzl_banlance", hzl_banlance);
        console.log(account, "btc_banlance", btc_banlance);
        console.log(account, "eth_banlance", eth_banlance);
        console.log(account, "usdt_banlance", usdt_banlance);
      }
    });
  });
});