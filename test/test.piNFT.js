const PiNFT = artifacts.require("piNFT");
const SampleERC20 = artifacts.require("sampleERC20");

contract("PiNFT", (accounts) => {
  let piNFT, sampleERC20;
  let alice = accounts[0];
  let validator = accounts[1];
  let bob = accounts[2];

  it("should deploy the contracts", async () => {
    piNFT = await PiNFT.deployed();
    sampleERC20 = await SampleERC20.deployed();
    assert(piNFT !== undefined, "PiNFT contract was not deployed");
    assert(sampleERC20 !== undefined, "SampleERC20 contract was not deployed");
  });

  it("should read the name and symbol of piNFT contract", async () => {
    assert.equal(await piNFT.name(), "Aconomy");
    assert.equal(await piNFT.symbol(), "ACO");
  });

  it("should mint an ERC721 token to alice", async () => {
    const tx = await piNFT.mintNFT(alice, "URI1");
    const tokenId = tx.logs[0].args.tokenId.toNumber();
    assert(tokenId === 0, "Failed to mint or wrong token Id");
    assert.equal(await piNFT.balanceOf(alice), 1, "Failed to mint");
  });

  it("should mint ERC20 tokens to validator", async () => {
    const tx = await sampleERC20.mint(validator, 1000);
    const balance = await sampleERC20.balanceOf(validator);
    assert(balance == 1000, "Failed to mint ERC20 tokens");
  });
});
