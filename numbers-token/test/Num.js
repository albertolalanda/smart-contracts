const {
  BN, // Big Number support
} = require("@openzeppelin/test-helpers");
const { ethers } = require("hardhat");
const { expect } = require("chai");

let owner, otherAccount;
let numContract;

before(async () => {
  [owner, otherAccount] = await ethers.getSigners();

  numContract = await (await ethers.getContractFactory("Num", owner)).deploy();
});

describe("NumbersCoin", function () {
  describe("Deployment", function () {
    it("Name should be 'NumbersCoin'", async () => {
      nome = await numContract.connect(owner).name();
      expect(nome).to.be.a.string;
      expect(nome).to.equal("NumbersCoin");
    });

    it("Symbol should be 'NUM'", async () => {
      symbol = await numContract.connect(owner).symbol();
      expect(symbol).to.be.a.string;
      expect(symbol).to.equal("NUM");
    });

    it("Should have 18 decimals", async () => {
      decimals = await numContract.connect(owner).decimals();
      expect(decimals.toString()).to.be.bignumber.equal("18");
    });

    it("Total supply should be 100", async () => {
      supply = await numContract.connect(owner).totalSupply();

      expect(supply.toString()).to.be.bignumber.equal("100000000000000000000");
    });

    it("Supply cap should be 1.000.000", async () => {
      cap = await numContract.connect(owner).cap();
      expect(cap.toString()).to.be.bignumber.equal("1000000000000000000000000");
    });
  });

  describe("Accounts", function () {
    it("Balance of owner account should be 100_000000000000000000", async () => {
      balance = await numContract.connect(owner).balanceOf(owner.address);

      expect(balance.toString()).to.be.bignumber.equal("100000000000000000000");
    });

    it("Balance of other account should be 0", async () => {
      balance = await numContract
        .connect(owner)
        .balanceOf(otherAccount.address);

      expect(balance.toString()).to.be.bignumber.equal("0");
    });
  });
  describe("NumbersCoin mint", () => {
    it("Mint 1 NumbersCoin with owner and fail to mint with other account", async () => {
      balance = await numContract.connect(owner).balanceOf(owner.address);

      expect(balance.toString()).to.be.bignumber.equal("100000000000000000000");

      // Create 1 NUM on owner account
      await numContract
        .connect(owner)
        .mint(owner.address, "1000000000000000000");
      balance = await numContract.connect(owner).balanceOf(owner.address);
      expect(balance.toString()).to.be.bignumber.equal("101000000000000000000");

      supply = await numContract.connect(owner).totalSupply();
      expect(supply.toString()).to.be.bignumber.equal("101000000000000000000");

      await expect(
        numContract
          .connect(otherAccount)
          .mint(otherAccount.address, "1000000000000000000")
      ).to.be.revertedWith("Ownable: caller is not the owner");
    });

    it("Cannot mint more than cap of 1000000_e18", async () => {
      balance = await numContract.connect(owner).balanceOf(owner.address);

      expect(balance.toString()).to.be.bignumber.equal("101000000000000000000");

      supply = await numContract.connect(owner).totalSupply();
      expect(supply.toString()).to.be.bignumber.equal("101000000000000000000");

      await expect(
        numContract
          .connect(owner)
          .mint(owner.address, "999999000000000000000000")
      ).to.be.revertedWith("ERC20Capped: cap exceeded");
    });
  });

  describe("NumbersCoin accounts", () => {
    it("Transfer 1 NUM from owner to other account", async () => {
      balanceOwner = await numContract.connect(owner).balanceOf(owner.address);
      expect(balanceOwner.toString()).to.be.bignumber.equal(
        "101000000000000000000"
      );

      await numContract
        .connect(owner)
        .transfer(otherAccount.address, "1000000000000000000");

      balanceOwner = await numContract.connect(owner).balanceOf(owner.address);
      expect(balanceOwner.toString()).to.be.bignumber.equal(
        "100000000000000000000"
      );
      balanceOtherAccount = await numContract
        .connect(otherAccount)
        .balanceOf(otherAccount.address);
      expect(balanceOtherAccount.toString()).to.be.bignumber.equal(
        "1000000000000000000"
      );
    });

    it("Allow spending of 1 NUM from owner to other account", async () => {
      balanceOwner = await numContract.connect(owner).balanceOf(owner.address);
      expect(balanceOwner.toString()).to.be.bignumber.equal(
        "100000000000000000000"
      );

      await numContract
        .connect(owner)
        .approve(otherAccount.address, "1000000000000000000");

      allowance = await numContract
        .connect(otherAccount)
        .allowance(owner.address, otherAccount.address);
      expect(allowance.toString()).to.be.bignumber.equal("1000000000000000000");

      await numContract
        .connect(otherAccount)
        .transferFrom(
          owner.address,
          otherAccount.address,
          "1000000000000000000"
        );

      allowance = await numContract
        .connect(otherAccount)
        .allowance(owner.address, otherAccount.address);
      expect(allowance.toString()).to.be.bignumber.equal("0");

      balanceOwner = await numContract.connect(owner).balanceOf(owner.address);
      expect(balanceOwner.toString()).to.be.bignumber.equal(
        "99000000000000000000"
      );
      balanceOtherAccount = await numContract
        .connect(otherAccount)
        .balanceOf(otherAccount.address);
      expect(balanceOtherAccount.toString()).to.be.bignumber.equal(
        "2000000000000000000"
      );
    });
  });
});
