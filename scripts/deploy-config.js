// We require the Hardhat Runtime Environment explicitly here. This is optional 
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
require('dotenv').config()
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
  const HzlConfig = await hre.ethers.getContractFactory("HZLConfig");
  const HZLRegistry = await hre.ethers.getContractFactory("HZLRegistry");


  const config = await HzlConfig.deploy();
  const registry = await HZLRegistry.deploy();


  await config.deployed();
  await registry.deployed();

  console.log('config deployed:', config.address);
  console.log('registry deployed:', registry.address);

  const btc = ethers.utils.keccak256(ethers.utils.toUtf8Bytes('btc'));
  const eth = ethers.utils.keccak256(ethers.utils.toUtf8Bytes('eth'));
  console.log('btc', btc);
  console.log('eth', eth);
  
  //register
  await registry.addNewContract(btc, process.env.BTC_ADDR);
  await registry.addNewContract(eth, process.env.ETH_ADDR);

  //config
  await config.initConfig();

}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });
