/* eslint-disable no-undef */
const { expect } = require('chai');

describe('Token', function () {
  let dev, owner, Token, token;
  const INITIAL_SUPPLY = ethers.utils.parseEther('1000000');

  beforeEach(async function () {
    [dev, owner] = await ethers.getSigners();
    Token = await ethers.getContractFactory('Token');
    token = await Token.connect(dev).deploy(owner.address);
    await token.deployed();
  });
  describe('Deployment', function () {
    it('Should have name TokenTest', async function () {
      expect(await token.name()).to.equal('TokenTest');
    });
    it('Should have symbol TKT', async function () {
      expect(await token.symbol()).to.equal('TKT');
    });
    it('Should set owner', async function () {
      expect(await token.owner()).to.equal(owner.address);
    });
    it(`Should have total supply ${INITIAL_SUPPLY.toString()}`, async function () {
      expect(await token.totalSupply()).to.equal(INITIAL_SUPPLY);
    });
    it('Should mint total supply to owner', async function () {
      expect(await token.balanceOf(owner.address)).to.equal(INITIAL_SUPPLY);
    });
  });
});
