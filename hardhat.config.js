require('dotenv').config()
require("@nomiclabs/hardhat-truffle5");
require("@nomiclabs/hardhat-ethers");
require('@nomiclabs/hardhat-waffle');

task("accounts", "Prints the list of accounts", async (taskArgs, hre) => {
  const accounts = await hre.ethers.getSigners();

  for (const account of accounts) {
    console.log(account.address);
  }
});
// require('@nomiclabs/hardhat-etherscan');
/**
 * @type import('hardhat/config').HardhatUserConfig
 */
module.exports = {
  solidity: {
    version: "0.8.0",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200
      }
    }
  },
  networks: {
    hardhat: {
      mining: {
        auto: false,
        interval: 5000
      }
    },
    localhost: {
      url: "http://127.0.0.1:8545"
    },
    dev: {
      url: 'http://8.210.116.104:9933',
      chainId: 1281,
      accounts: [process.env.PRI1, process.env.PRI2, process.env.PRI3, process.env.PRI4, process.env.PRI5, process.env.PRI6]
    }
  },
  paths: {
    sources: "./contracts",
    tests: "./test",
    cache: "./cache",
    artifacts: "./artifacts"
  },
};
