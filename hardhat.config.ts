import { HardhatUserConfig } from "hardhat/config"
import "@nomicfoundation/hardhat-toolbox"
import secrets from "./.secret.json";

const config: HardhatUserConfig = {
  solidity: "0.8.19",
  networks: {
    matic: {
      url: "https://polygon-mainnet.g.alchemy.com/v2/fMGEdQxGbq46TrKb0nTwdmAIh1ezg4BR",
      accounts: [secrets.prod]
    },
    mumbai: {
      url: "https://polygon-mumbai.g.alchemy.com/v2/33v8xR1ESeHGOhkJWroSInNuXC-kZLRJ",
      accounts: [secrets.test]
    }
  }
};

export default config;
