require('dotenv').config()
require("@nomiclabs/hardhat-truffle5");
require("@nomiclabs/hardhat-ethers");
// require('@nomiclabs/hardhat-waffle');
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
