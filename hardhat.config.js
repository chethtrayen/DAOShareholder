require("@nomicfoundation/hardhat-toolbox");
require("hardhat-deploy")

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: "0.8.17",
  namedAccounts: {
    deployer: 
    {
      default: 0,
      1: 0
    },
    other: {
      default: 1,
    }
  }
};
