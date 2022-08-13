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

  const NumNFT = await ethers.getContractFactory("NumbersNFT");
  const numNFT = await NumNFT.deploy(
    20,
    "0x9775f51536f87DCB7F7faaa9E0a1d2BC55D4FC16",
    "0xc3193A290B43261B7d39FC9D769436246E100a05"
  );

  console.log("NumNFT address:", numNFT.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
