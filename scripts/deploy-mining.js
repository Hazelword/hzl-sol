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
  const HzlMining = await hre.ethers.getContractFactory("HzlMining");


  const mining = await HzlMining.deploy();

  await mining.deployed();

  console.log("HzlMining deployed to:", mining.address);

  console.log("HzlMining updateConfig to:", process.env.CONFIG_ADDR);
  console.log("HzlMining updateRegistry to:", process.env.REGISTRY_ADDR);
  
  await mining.updateConfig(process.env.CONFIG_ADDR);
  await mining.updateRegistry(process.env.REGISTRY_ADDR);

}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });
