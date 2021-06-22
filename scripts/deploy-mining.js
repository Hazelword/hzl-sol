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
  const accounts = await ethers.getSigners();
  const gov = accounts[0];
  const user1 = accounts[1];
  const user2 = accounts[2];
  const user3 = accounts[3];

  // We get the contract to deploy
  const HzlMining = await hre.ethers.getContractFactory("HzlMining");


  const hzl = await HzlMining.deploy(gov.address);

  await hzl.deployed();

  console.log("HzlMining deployed to:", hzl.address);

  //add quote pair
  const govContract = hzl;
  await govContract.addQuotePair("hzl", "0x5FbDB2315678afecb367f032d93F642f64180aa3");
  await govContract.addQuotePair("btc", "0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512");
  await govContract.addQuotePair("eth", "0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0");
  await govContract.addQuotePair("usdt", "0xCf7Ed3AccA5a467e9e704C703E8D87F634fB0Fc9");

  //start token quote
  await govContract.stratQuotePair("0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512");
  await govContract.stratQuotePair("0x5FbDB2315678afecb367f032d93F642f64180aa3");

  //init
  await govContract.initialize();

  const u1 = hzl.conect(user1);

  console.log("HzlMining success!");

}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });
