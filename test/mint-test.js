require('dotenv').config()
const { expect } = require('chai');
const hre = require('hardhat');
const ethers = hre.ethers;


const HzlToken = artifacts.require("HzlToken");
const ERC20Token = artifacts.require("ERC20Token");

const { balanceOf, mint } = require('./utils/common');

describe("mint", function() {

  let OWNER_ACC;
  const signer = ethers.provider.getSigner(OWNER_ACC);

  const HZL_ADDR = process.env.HZL_ADDR;
  const BTC_ADDR = process.env.BTC_ADDR;
  const ETH_ADDR = process.env.ETH_ADDR;
  const USDT_ADDR = process.env.USDT_ADDR;

  const amount = "10000000000000";

  let accounts;
  let hzl_amount;
  let btc_balance;
  let eth_balance;
  let usdt_balance;

  before(async function() {
    accounts = await hre.ethers.getSigners();
    OWNER_ACC = accounts[0].address;
    console.log("OWNER_ACC", OWNER_ACC)
    console.log("HZL_ADDR", HZL_ADDR)
    hzl_amount = await balanceOf(HZL_ADDR, OWNER_ACC);
    btc_balance = await balanceOf(BTC_ADDR, OWNER_ACC);
    eth_balance = await balanceOf(ETH_ADDR, OWNER_ACC);
    usdt_balance = await balanceOf(USDT_ADDR, OWNER_ACC);
  });

  it("mint hzl", async function() {
    await mint(signer, HZL_ADDR, OWNER_ACC, amount);

    const hzl_balance = await balanceOf(HZL_ADDR, OWNER_ACC);
    console.log("hzl_balance", hzl_balance);
  });

  it("mint btc", async function() {
    await mint(signer, BTC_ADDR, OWNER_ACC, amount);

    const btc_balance = await balanceOf(BTC_ADDR, OWNER_ACC);
    console.log("btc_balance", btc_balance);
  });

  it("mint eth", async function() {
    await mint(signer, ETH_ADDR, OWNER_ACC, amount);

    const eth_balance = await balanceOf(ETH_ADDR, OWNER_ACC);
    console.log("eth_balance", eth_balance);
  });

  it("mint usdt", async function() {
    await mint(signer, USDT_ADDR, OWNER_ACC, amount);

    const usdt_balance = await balanceOf(USDT_ADDR, OWNER_ACC);
    console.log("usdt_balance", usdt_balance);
  });

});