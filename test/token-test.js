const HzlToken = artifacts.require("HzlToken");
const ERC20Token = artifacts.require("ERC20Token");

describe("Token contract", function() {
  let accounts;

  before(async function() {
    accounts = await web3.eth.getAccounts();
  });

  describe("Deployment", function() {
    it("deploy erc20 token", async function() {
      const hzl = await HzlToken.new();
      assert.equal(await hzl.totalSupply(), 0);
      await hzl.mint(100, accounts[0]);
      const total = await hzl.totalSupply();
      const bn_total = web3.utils.toBN(total).toString();
      assert.equal(bn_total, 100);

      
    });
  });
});