// We require the Hardhat Runtime Environment explicitly here. This is optional 
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
const hre = require("hardhat");
const ethers = hre.ethers;

async function main() {
  // Hardhat always runs the compile task when running scripts with its command
  // line interface.
  //
  // If this script is run directly using `node` you may want to call compile 
  // manually to make sure everything is compiled
  // await hre.run('compile');

  // We get the contract to deploy
  const HzlToken = await hre.ethers.getContractFactory("HzlToken");
  const ERC20Token = await hre.ethers.getContractFactory("ERC20Token");

  const hzl = await HzlToken.deploy();
  const btc = await ERC20Token.deploy("bitcoin", "btc");
  const eth = await ERC20Token.deploy("ethereum", "eth");
  const usdt = await ERC20Token.deploy("usdt erc20", "usdt");

  await hzl.deployed();
  await btc.deployed();
  await eth.deployed();
  await usdt.deployed();

  console.log("hzl deployed to:", hzl.address);
  console.log("btc deployed to:", btc.address);
  console.log("eth deployed to:", eth.address);
  console.log("usdt deployed to:", usdt.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });
