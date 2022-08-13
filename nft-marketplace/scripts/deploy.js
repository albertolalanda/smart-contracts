// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// You can also run a script with `npx hardhat run <script>`. If you do that, Hardhat
// will compile your contracts, add the Hardhat Runtime Environment's members to the
// global scope, and execute the script.
const hre = require("hardhat");

async function main() {
  const [deployer] = await ethers.getSigners();

  console.log("Deploying contracts with the account:", deployer.address);

  console.log("Account balance:", (await deployer.getBalance()).toString());

  const Market = await ethers.getContractFactory("Market");
  const market = await Market.deploy(
    "0xd75c45487BC6Bf1C9cf875857B69010e0827F69e",
    5,
    "0x9775f51536f87DCB7F7faaa9E0a1d2BC55D4FC16"
  );

  console.log("NFT Marketplace address:", market.address);
}
// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
