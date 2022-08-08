require("@nomicfoundation/hardhat-toolbox");
require("dotenv").config();

const ALC_API_KEY = process.env.ALCHEMY_API_KEY;
const MUMBAI_PK = process.env.MUMBAI_PRIVATE_KEY;

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: "0.8.9",
  networks: {
    mumbai: {
      url: `https://polygon-mumbai.g.alchemy.com/v2/${ALC_API_KEY}`,
      accounts: [MUMBAI_PK],
    },
  },
};
