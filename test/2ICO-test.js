/* eslint-disable comma-dangle */
/* eslint-disable no-undef */
const { expect } = require('chai');

describe('ICO', function () {
  let dev, ownerToken, ownerIco, henri, romain, Token, token, ICO, ico, tx;
  const INITIAL_SUPPLY = ethers.utils.parseEther('1000000');
  const gwei = 10 ** 9;

  beforeEach(async function () {
    [dev, ownerToken, ownerIco, henri, romain] = await ethers.getSigners();
    Token = await ethers.getContractFactory('Token');
    token = await Token.connect(dev).deploy(ownerToken.address);
    await token.deployed();
    ICO = await ethers.getContractFactory('ICO');
    ico = await ICO.connect(ownerIco).deploy(token.address);
    await ico.deployed();
    await token.connect(ownerToken).approve(ico.address, INITIAL_SUPPLY);
  });
  describe('Deployment', function () {
    it('Should revert if ownerToken has no token on ERC20', async function () {
      await token.connect(ownerToken).transfer(henri.address, INITIAL_SUPPLY);
      await expect(ICO.connect(ownerIco).deploy(token.address)).to.be.revertedWith(
        'ICO: owner must have token to exchange'
      );
    });
  });

  describe('Buy function', function () {
    it('receive', async function () {
      tx = await henri.sendTransaction({ to: ico.address, value: 2 * gwei });
      expect(await token.balanceOf(henri.address)).to.equal(ethers.utils.parseEther('2'));
      expect(await ico.total()).to.equal(2 * gwei);
      expect(tx).to.changeEtherBalance(henri, -2 * gwei);
    });
    it('buyTokens', async function () {
      tx = await ico.connect(henri).buyTokens({ value: gwei });
      expect(await token.balanceOf(henri.address)).to.equal(ethers.utils.parseEther('1'));
      expect(await ico.total()).to.equal(gwei);
      expect(tx).to.changeEtherBalance(henri, -gwei);
    });
    it('buy token with refund', async function () {
      await token.connect(ownerToken).approve(ico.address, ethers.utils.parseEther('1'));
      tx = await ico.connect(henri).buyTokens({ value: 3 * gwei });
      expect(await ico.total()).to.equal(gwei);
      expect(tx).to.changeEtherBalance(henri, -gwei);
    });
    it('Should emit a Bought event', async function () {
      await expect(ico.connect(henri).buyTokens({ value: gwei }))
        .to.emit(ico, 'Bought')
        .withArgs(henri.address, gwei);
    });
    it('time flies, should revert if 2 weeks have passed', async function () {
      await ethers.provider.send('evm_increaseTime', [60 * 60 * 24 * 14]); // 2 weeks ~= 14 days == 1209600 secondes
      await ethers.provider.send('evm_mine');
      await expect(ico.connect(henri).buyTokens({ value: gwei })).to.be.revertedWith(
        'ICO: 2 weeks have passed, you can no longer buy token'
      );
    });
    it('Should revert if ICO has no allowance', async function () {
      ico = await ICO.connect(ownerIco).deploy(token.address);
      await ico.deployed();
      await expect(ico.connect(henri).buyTokens({ value: gwei })).to.be.revertedWith(
        'ICO: has not been approved yet or all token are already sold'
      );
    });
  });

  describe('Getter', function () {
    it('conversion', async function () {
      const nb = 15; // 1 gwei = 1 token
      expect(await ico.conversion(nb * gwei)).to.equal(ethers.utils.parseEther('1').mul(nb));
    });
    it('Token sold', async function () {
      await ico.connect(henri).buyTokens({ value: 10 * gwei });
      expect(await ico.tokenSold()).to.equal(10);
    });
    it('Gain total', async function () {
      await ico.connect(henri).buyTokens({ value: 10 * gwei });
      expect(await ico.total()).to.equal(10 * gwei);
    });
    // not usable in testnet environment
    it('Should return time left in second', async function () {
      const time = await ico.timeLeft();
      expect(time).to.equal(1209599); // unsure time between deployment and function call -1s | 1209600s = 2 weeks
      console.log('\ttime left: ', time.toString());
    });
    it('Should say that ICO is terminated', async function () {
      await ethers.provider.send('evm_increaseTime', [60 * 60 * 24 * 14]);
      await ethers.provider.send('evm_mine');
      await expect(ico.timeLeft()).to.be.revertedWith('ICO: there is no time left');
    });
  });

  describe('Withdraw', function () {
    beforeEach(async function () {
      await ico.connect(henri).buyTokens({ value: 10 * gwei });
      await ico.connect(romain).buyTokens({ value: 100 * gwei });
    });
    it('Should send contract balance to owner', async function () {
      await ethers.provider.send('evm_increaseTime', [60 * 60 * 24 * 14]);
      await ethers.provider.send('evm_mine');
      expect(await ico.connect(ownerIco).withdraw()).to.changeEtherBalance(ownerIco, 110 * gwei);
      expect(await ico.total()).to.equal(0);
    });
    it('Should emit a Withdrew event', async function () {
      await ethers.provider.send('evm_increaseTime', [60 * 60 * 24 * 14]);
      await ethers.provider.send('evm_mine');
      await expect(ico.connect(ownerIco).withdraw())
        .to.emit(ico, 'Withdrew')
        .withArgs(ownerIco.address, 110 * gwei);
    });
    it('Should revert if not owner', async function () {
      await expect(ico.connect(henri).withdraw()).to.be.revertedWith('Ownable: caller is not the owner');
    });
    it('Should revert if 2 weeks has not pass', async function () {
      await expect(ico.connect(ownerIco).withdraw()).to.be.revertedWith(
        'ICO: you need to wait 2 weeks from the deployment of this contract'
      );
    });
  });
});
