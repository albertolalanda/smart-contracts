const {
  BN, // Big Number support
} = require("@openzeppelin/test-helpers");
const { ethers } = require("hardhat");
const { expect } = require("chai");
const NumToken = require("../../numbers-token/artifacts/contracts/Num.sol/Num.json");

let owner, otherAccount;
let numbersToken;
let numbersNft;

before(async () => {
  [owner, otherAccount] = await ethers.getSigners();

  numbersToken = await (
    await ethers.getContractFactory(NumToken.abi, NumToken.bytecode, owner)
  ).deploy();

  numbersNft = await (
    await ethers.getContractFactory("NumbersNFT", owner)
  ).deploy(5, numbersToken.address, owner.address);
});

describe("NumbersNFT", function () {
  describe("Deployment", function () {
    it("Name should be 'NumbersNFT'", async () => {
      nome = await numbersNft.connect(owner).name();
      expect(nome).to.be.a.string;
      expect(nome).to.equal("NumbersNFT");
    });

    it("Symbol should be 'nNUM'", async () => {
      symbol = await numbersNft.connect(owner).symbol();
      expect(symbol).to.be.a.string;
      expect(symbol).to.equal("nNUM");
    });

    it("Total supply should be 0", async () => {
      supply = await numbersNft.connect(owner).count();

      expect(supply.toString()).to.be.bignumber.equal("0");
    });

    it("Supply cap should be 20", async () => {
      cap = await numbersNft.connect(owner).totalSupplyCap();
      expect(cap.toString()).to.be.bignumber.equal("5");
    });
  });

  describe("NumbersNFT mint", () => {
    it("SafeMint 1 NumbersNFT with owner and fail to safeMint with other account", async () => {
      balance = await numbersNft.connect(owner).balanceOf(owner.address);

      expect(balance.toString()).to.be.bignumber.equal("0");

      // Create 1 nNUM on owner account
      await numbersNft.connect(owner).safeMint(owner.address);
      balance = await numbersNft.connect(owner).balanceOf(owner.address);
      expect(balance.toString()).to.be.bignumber.equal("1");

      supply = await numbersNft.connect(owner).count();
      expect(supply.toString()).to.be.bignumber.equal("1");

      expect(await numbersNft.connect(owner).isContentOwned("0")).to.be.equal(
        true
      );
      expect(await numbersNft.connect(owner).ownerOf("0")).to.be.equal(
        owner.address
      );

      await expect(
        numbersNft.connect(otherAccount).safeMint(otherAccount.address)
      ).to.be.revertedWith("Ownable: caller is not the owner");
    });

    it("payToMint 1 NumbersNFT with enough approved NUM tokens", async () => {
      await numbersToken
        .connect(owner)
        .transfer(otherAccount.address, "100000000000000000000");

      await expect(
        numbersNft.connect(otherAccount).payToMint(otherAccount.address)
      ).to.be.revertedWith("ERC20: insufficient allowance");

      await numbersToken
        .connect(otherAccount)
        .approve(numbersNft.address, "100000000000000000000");

      await numbersNft.connect(otherAccount).payToMint(otherAccount.address);

      supply = await numbersNft.connect(otherAccount).count();
      expect(supply.toString()).to.be.bignumber.equal("2");

      expect(
        await numbersNft.connect(otherAccount).isContentOwned("1")
      ).to.be.equal(true);
      expect(await numbersNft.connect(otherAccount).ownerOf("1")).to.be.equal(
        otherAccount.address
      );

      allowance = await numbersToken
        .connect(otherAccount)
        .allowance(otherAccount.address, numbersNft.address);

      balance = await numbersToken
        .connect(otherAccount)
        .balanceOf(otherAccount.address);
      expect(balance.toString()).to.be.bignumber.equal("90000000000000000000");

      await numbersNft.connect(owner).updatePrice("20");
      await numbersNft.connect(otherAccount).payToMint(otherAccount.address);
      balance = await numbersToken
        .connect(otherAccount)
        .balanceOf(otherAccount.address);
      expect(balance.toString()).to.be.bignumber.equal("70000000000000000000");
    });

    it("mint all tokens and increase supply", async () => {
      await numbersNft.connect(otherAccount).payToMint(otherAccount.address);
      await numbersNft.connect(otherAccount).payToMint(otherAccount.address);

      supply = await numbersNft.connect(otherAccount).count();
      expect(supply.toString()).to.be.bignumber.equal("5");

      await expect(
        numbersNft.connect(otherAccount).payToMint(otherAccount.address)
      ).to.be.revertedWithCustomError(numbersNft, "MintLimit");

      await numbersNft.connect(owner).increaseAvailableTotalSupply(5);
      cap = await numbersNft.connect(owner).totalSupplyCap();
      expect(cap.toString()).to.be.bignumber.equal("10");

      await numbersNft.connect(otherAccount).payToMint(otherAccount.address);
      supply = await numbersNft.connect(otherAccount).count();
      expect(supply.toString()).to.be.bignumber.equal("6");
    });
  });

  describe("NumbersNFT transfer", () => {
    it("transfer NFT", async () => {
      expect(await numbersNft.connect(owner).ownerOf("1")).to.be.equal(
        otherAccount.address
      );
      await numbersNft.connect(otherAccount).approve(owner.address, "1");
      await numbersNft
        .connect(otherAccount)
        ["safeTransferFrom(address,address,uint256)"](
          otherAccount.address,
          owner.address,
          "1"
        );

      expect(await numbersNft.connect(owner).ownerOf("1")).to.be.equal(
        owner.address
      );
    });
  });

  describe("Others", () => {
    it("withdraw NUM tokens from mints", async () => {
      balance = await numbersToken.connect(owner).balanceOf(owner.address);
      expect(balance.toString()).to.be.bignumber.equal("0");
      await numbersNft.connect(owner).withdrawNUM();
      balance = await numbersToken.connect(owner).balanceOf(owner.address);
      expect(balance.toString()).to.be.bignumber.equal("90000000000000000000");
    });
    it("RoyaltyInfo", async () => {
      let royalty = await numbersNft
        .connect(owner)
        .royaltyInfo(2, "10000000000000000000");

      expect(royalty[0]).to.be.equal(owner.address);
      expect(royalty[1].toString()).to.be.bignumber.equal("500000000000000000");
    });
  });
});
