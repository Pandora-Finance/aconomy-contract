const {
  time,
  loadFixture,
} = require("@nomicfoundation/hardhat-toolbox/network-helpers");
const { anyValue } = require("@nomicfoundation/hardhat-chai-matchers/withArgs");
const { expect } = require("chai");
const { ethers } = require("hardhat");
const { BN } = require("@openzeppelin/test-helpers");

describe("Collection Factory", function (){
  let collectionInstance;
  async function deployContractFactory() {
    [alice, validator, bob, royaltyReciever] = await ethers.getSigners();

    const LibShare = await hre.ethers.deployContract("LibShare", []);
    await LibShare.waitForDeployment();


    const piNFTMethods = await hre.ethers.getContractFactory("piNFTMethods", {
      libraries: {
        LibShare: await LibShare.getAddress(),
      }
    })
    piNftMethods = await upgrades.deployProxy(piNFTMethods, ["0xBf175FCC7086b4f9bd59d5EAE8eA67b8f940DE0d"], {
      initializer: "initialize",
      kind: "uups",
      unsafeAllow: ["external-library-linking"],
    })

    const CollectionMethods = await hre.ethers.deployContract("CollectionMethods", []);
    let CollectionMethod = await CollectionMethods.waitForDeployment();

    const LibCollection = await hre.ethers.deployContract("LibCollection", []);
    await LibCollection.waitForDeployment();

    const collectionFactory = await hre.ethers.getContractFactory("CollectionFactory", {
      libraries: {
        LibCollection: await LibCollection.getAddress()
      }
    })
    CollectionFactory = await upgrades.deployProxy(collectionFactory, [await CollectionMethod.getAddress(), await piNftMethods.getAddress()], {
      initializer: "initialize",
      kind: "uups",
      unsafeAllow: ["external-library-linking"],
    })

    const mintToken = await hre.ethers.deployContract("mintToken", ["100000000000"]);
    sampleERC20 = await mintToken.waitForDeployment();

    return { sampleERC20, piNftMethods, CollectionFactory, alice, validator, bob, royaltyReciever };
  }

  describe("Deployment", function () {
    it("should deploy the contracts", async () => {
      let { sampleERC20, piNftMethods, CollectionFactory, alice, validator, bob, royaltyReciever} = await deployContractFactory()
      expect(await CollectionFactory.piNFTMethodsAddress()).to.equal(await piNftMethods.getAddress())
    });

    it("should deploy the contracts", async () => {
      await CollectionFactory.pause();
      await expect(
        CollectionFactory.createCollection("PANDORA", "PAN", "xyz", "xyz", [
          [royaltyReciever, 500],
        ])
      ).to.be.revertedWith("Pausable: paused");
      await CollectionFactory.unpause();
    });

    it("should not allow non owner to pause piNFTMethods", async () => {
      await expect(
        CollectionFactory.connect(royaltyReciever).pause()
      ).to.be.revertedWith("Ownable: caller is not the owner");

      await CollectionFactory.pause();

      await expect(
        CollectionFactory.connect(royaltyReciever).unpause()
      ).to.be.revertedWith("Ownable: caller is not the owner");

      await CollectionFactory.unpause();
    })

    it("should check Royality receiver isn't 0 address", async () => {
      await expect(
        CollectionFactory.createCollection("PANDORA", "PAN", "xyz", "xyz", [
          ["0x0000000000000000000000000000000000000000", 4901],
        ])
        ).to.be.revertedWith("Royalty recipient should be present");
    });

    it("should check that Royality must be less 4900", async () => {
      await expect(
        CollectionFactory.createCollection("PANDORA", "PAN", "xyz", "xyz", [
          [royaltyReciever, 4901],
        ])
        ).to.be.revertedWith("Sum of Royalties > 49%");
    });

    it("should check that Royality length must be less than 10", async () => {
      await expect(
        CollectionFactory.createCollection("PANDORA", "PAN", "xyz", "xyz", [
          [alice, 100],
          [alice, 100],
          [alice, 100],
          [alice, 100],
          [alice, 100],
          [alice, 100],
          [alice, 100],
          [alice, 100],
          [alice, 100],
          [alice, 100],
          [alice, 100],
        ])
        ).to.be.revertedWith("Atmost 10 royalties can be added");
    });

    it("should check that Royality value isn't 0", async () => {
      await expect(
        CollectionFactory.createCollection("PANDORA", "PAN", "xyz", "xyz", [
          [royaltyReciever, 0],
        ])
        ).to.be.revertedWith("Royalty value should be > 0");
    });

    it("deploying collections with CollectionFactory contract", async () => {
      await CollectionFactory.createCollection("PANDORA", "PAN", "xyz", "xyz", [
        [royaltyReciever, 500],
      ]);
      let meta = await CollectionFactory.collections(1);
      let address = meta.contractAddress;
      const LibShare = await hre.ethers.deployContract("LibShare", []);
      await LibShare.waitForDeployment();
      let CollectionMethods = await hre.ethers.getContractFactory("CollectionMethods")
      collectionInstance = await CollectionMethods.attach(address);
    });

    it("should not allow royalties to be set by non owner", async () => {
      await expect(
        CollectionFactory.connect(royaltyReciever).setRoyaltiesForCollection(1, [[royaltyReciever, 500]])
        ).to.be.revertedWith("Not the owner")
    })

    it("should not allow royalties to be set when contract is paused", async () => {
      await CollectionFactory.pause();
      await expect(
        CollectionFactory.setRoyaltiesForCollection(1, [[royaltyReciever, 500]]))
      .to.be.revertedWith("Pausable: paused");
      await CollectionFactory.unpause();
    })

    it("should not allow uri to be set by non owner", async () => {
      await expect(
        CollectionFactory.connect(royaltyReciever).setCollectionURI(1, "XYZ")
        ).to.be.revertedWith("Not the owner")
    })

    it("should not allow uri to be set when contract is paused", async () => {
      await CollectionFactory.pause();
      await expect(
        CollectionFactory.setCollectionURI(1, "XYZ"))
      .to.be.revertedWith("Pausable: paused");
      await CollectionFactory.unpause();
    })

    it("should change the uri", async () => {
      let meta = await CollectionFactory.collections(1);
      let uri = meta.URI;
      expect(uri).to.equal("xyz")
      await CollectionFactory.setCollectionURI(1, "SRS");
      let newMeta = await CollectionFactory.collections(1);
      let newURI = newMeta.URI;
      expect(newURI).to.equal("SRS");
    });

    it("should not allow symbol to be set by non owner", async () => {
      await expect(
        CollectionFactory.connect(royaltyReciever).setCollectionSymbol(1, "XYZ")
        ).to.be.revertedWith("Not the owner")
    })

    it("should not allow symbol to be set when contract is paused", async () => {
      await CollectionFactory.pause();
      await expect(
        CollectionFactory.setCollectionSymbol(1, "XYZ"))
      .to.be.revertedWith("Pausable: paused");
      await CollectionFactory.unpause();
    })

    it("should change the Collection Symbol", async () => {
      let meta = await CollectionFactory.collections(1);
      let symbol = meta.symbol;
      expect(symbol).to.equal("PAN")
      await CollectionFactory.setCollectionSymbol(1, "PNDR");
      let newMeta = await CollectionFactory.collections(1);
      let newSymbol = newMeta.symbol;
      expect(newSymbol).to.equal("PNDR")
    });

    it("should not allow name to be set by non owner", async () => {
      await expect(
        CollectionFactory.connect(royaltyReciever).setCollectionName(1, "XYZ")
        ).to.be.revertedWith("Not the owner")
    })

    it("should not allow name to be set when contract is paused", async () => {
      await CollectionFactory.pause();
      await expect(
        CollectionFactory.setCollectionName(1, "XYZ"))
      .to.be.revertedWith("Pausable: paused");
      await CollectionFactory.unpause();
    })
  
    it("should change the Collection Name", async () => {
      let meta = await CollectionFactory.collections(1);
      let name = meta.name;
      expect(name).to.equal("PANDORA")
      await CollectionFactory.setCollectionName(1, "Pan");
      let newMeta = await CollectionFactory.collections(1);
      let newName = newMeta.name;
      expect(newName).to.equal("Pan")
    });

    it("should not allow description to be set by non owner", async () => {
      await expect(
        CollectionFactory.connect(royaltyReciever).setCollectionDescription(1, "XYZ")
        ).to.be.revertedWith("Not the owner")
    })

    it("should not allow description to be set when contract is paused", async () => {
      await CollectionFactory.pause();
      await expect(
        CollectionFactory.setCollectionDescription(1, "XYZ"))
      .to.be.revertedWith("Pausable: paused");
      await CollectionFactory.unpause();
    })
  
    it("should change the Collection Description", async () => {
      let meta = await CollectionFactory.collections(1);
      let description = meta.description;
      expect(description).to.equal("xyz")
      await CollectionFactory.setCollectionDescription(1, "I am Token");
      let newMeta = await CollectionFactory.collections(1);
      let newDescription = newMeta.description;
      expect(newDescription).to.equal("I am Token");
    });
  
    it("should fail to mint if the caller is not the collection owner", async () => {
      await expect(
        collectionInstance.connect(bob).mintNFT(bob, "xyz")
      ).to.be.revertedWithoutReason();
    });
  
    it("should fail to mint if the to address is address 0", async () => {
      await expect(
        collectionInstance.mintNFT(
          "0x0000000000000000000000000000000000000000",
          "xyz"
        )
      ).to.be.revertedWithoutReason();
    });
  
    it("should mint an ERC721 token to alice", async () => {
      const tx = await collectionInstance.mintNFT(alice, "URI1");
      // const tokenId = tx.logs[0].args.tokenId.toNumber();
      // expect(tokenId).to.equal(0)
      expect(
        await collectionInstance.balanceOf(alice)).to.equal(1)
    });
  
    it("should mint an ERC721 token to alice", async () => {
      const tx = await collectionInstance.mintNFT(alice, "URI1");
      // const tokenId = tx.logs[0].args.tokenId.toNumber();
      // expect(tokenId).to.equal(1)
      expect(
        await collectionInstance.balanceOf(alice)).to.equal(2)
    });
  
    it("should not Delete an ERC721 token if the caller isn't the owner", async () => {
      await expect(
        collectionInstance.connect(bob).deleteNFT(1)
      ).to.be.revertedWithoutReason();
    });
  
    it("should Delete an ERC721 token", async () => {
      const tx = await collectionInstance.deleteNFT(1);
      expect(
        await collectionInstance.balanceOf(alice)).to.equal(1)
    });
  
    it("should fetch the tokenURI and royalties", async () => {
      const uri = await collectionInstance.tokenURI(0);
      expect(uri).to.equal("URI1")
      const royalties = await CollectionFactory.getCollectionRoyalties(1);
      expect(royalties[0][0]).to.equal(await royaltyReciever.getAddress());
      expect(royalties[0][1]).to.equal(500);
    });
  
    it("should mint ERC20 tokens to validator", async () => {
      await sampleERC20.mint(validator, 1000);
      const balance = await sampleERC20.balanceOf(validator);
      expect(balance).to.equal(1000)
    });
  
    it("should not allow non owner to add a validator", async () => {
      await expect(piNftMethods.connect(bob).addValidator(await collectionInstance.getAddress(), 0, await validator.getAddress())).to.be.revertedWithoutReason()
    })
  
    it("should allow alice to add a validator to the nft", async () => {
      await piNftMethods.addValidator(await collectionInstance.getAddress(), 0, await validator.getAddress());
      expect(
        await piNftMethods.approvedValidator(await collectionInstance.getAddress(), 0)).to.equal(await validator.getAddress())
    });
  
    it("should not let non validator add funds", async () => {
      let exp = new BN(await time.latest()).add(new BN(3600));
      await sampleERC20.connect(alice).approve(await piNftMethods.getAddress(), 500);
      await expect(piNftMethods.connect(alice).addERC20(
        await collectionInstance.getAddress(),
        0,
        await sampleERC20.getAddress(),
        500,
        500,
        "uri",
        [[validator, 200]]
      )).to.be.revertedWithoutReason();
    })
  
    it("should not let erc20 contract be address 0", async () => {
      let exp = new BN(await time.latest()).add(new BN(3600));
      await sampleERC20.connect(validator).approve(await piNftMethods.getAddress(), 500);
      await expect(piNftMethods.connect(validator).addERC20(
        await collectionInstance.getAddress(),
        0,
        "0x0000000000000000000000000000000000000000",
        500,
        500,
        "uri",
        [[validator, 200]]
      )).to.be.revertedWithoutReason();
    })
  
    it("should not let validator fund value be 0", async () => {
      await sampleERC20.connect(validator).approve(await piNftMethods.getAddress(), 500);
      let exp = new BN(await time.latest()).add(new BN(3600));
      await expect(piNftMethods.connect(validator).addERC20(
        await collectionInstance.getAddress(),
        0,
        await sampleERC20.getAddress(),
        0,
        500,
        "uri",
        [[validator, 200]]
      )).to.be.revertedWithoutReason();
    })
  
    it("should not let validator commission value be 4901", async () => {
      let exp = new BN(await time.latest()).add(new BN(3600));
      await sampleERC20.connect(validator).approve(await piNftMethods.getAddress(), 500);
      await expect(piNftMethods.connect(validator).addERC20(
        await collectionInstance.getAddress(),
        0,
        await sampleERC20.getAddress(),
        500,
        4901,
        "uri",
        [[validator, 200]]
      )).to.be.revertedWithoutReason();
    })

    it("should not let validator royalties have more than 10 addresses", async () => {
      let exp = new BN(await time.latest()).add(new BN(3600));
      await sampleERC20.connect(validator).approve(await piNftMethods.getAddress(), 500);
      await expect(piNftMethods.connect(validator).addERC20(
        await collectionInstance.getAddress(),
        0,
        await sampleERC20.getAddress(),
        500,
        500,
        "uri",
        [[validator, 100],
        [validator, 100],
        [validator, 100],
        [validator, 100],
        [validator, 100],
        [validator, 100],
        [validator, 100],
        [validator, 100],
        [validator, 100],
        [validator, 100],
        [validator, 100],]
      )).to.be.revertedWithoutReason();
    })

    it("should not let validator royalties value be 0", async () => {
      let exp = new BN(await time.latest()).add(new BN(3600));
      await sampleERC20.connect(validator).approve(await piNftMethods.getAddress(), 500);
      await expect(piNftMethods.connect(validator).addERC20(
        await collectionInstance.getAddress(),
        0,
        await sampleERC20.getAddress(),
        500,
        500,
        "uri",
        [[validator, 0]]
      )).to.be.revertedWith("Royalty 0");
    })

    it("should not let validator royalties address be 0", async () => {
      let exp = new BN(await time.latest()).add(new BN(3600));
      await sampleERC20.connect(validator).approve(await piNftMethods.getAddress(), 500);
      await expect(piNftMethods.connect(validator).addERC20(
        await collectionInstance.getAddress(),
        0,
        await sampleERC20.getAddress(),
        500,
        500,
        "uri",
        [["0x0000000000000000000000000000000000000000", 100]]
      )).to.be.revertedWithoutReason();
    })

    it("should not let validator royalties be greater than 4901", async () => {
      let exp = new BN(await time.latest()).add(new BN(3600));
      await sampleERC20.connect(validator).approve(await piNftMethods.getAddress(), 500);
      await expect(piNftMethods.connect(validator).addERC20(
        await collectionInstance.getAddress(),
        0,
        await sampleERC20.getAddress(),
        500,
        500,
        "uri",
        [[validator, 4901]]
      )).to.be.revertedWith("overflow");
    })
  
    it("should let validator add ERC20 tokens to alice's NFT", async () => {
      let exp = new BN(await time.latest()).add(new BN(3600));
      await sampleERC20.connect(validator).approve(await piNftMethods.getAddress(), 500);
      const tx = await piNftMethods.connect(validator).addERC20(
        await collectionInstance.getAddress(),
        0,
        await sampleERC20.getAddress(),
        500,
        500,
        "uri",
        [[validator, 200]]
      );
      const tokenBal = await piNftMethods.viewBalance(
        await collectionInstance.getAddress(),
        0,
        await sampleERC20.getAddress()
      );
      const validatorBal = await sampleERC20.balanceOf(validator);
      expect(tokenBal).to.equal(500);
      expect(validatorBal).to.equal(500)
      let commission = await piNftMethods.validatorCommissions(
        await collectionInstance.getAddress(),
        0
      );
      expect(commission.isValid).to.equal(true);
      expect(commission.commission.account).to.equal(await validator.getAddress());
      expect(commission.commission.value).to.equal(500);
    });
  
    it("should not allow validator changing after funding", async () => {
      expect(piNftMethods.addValidator(await collectionInstance.getAddress(), 0, validator)).to.be.revertedWithoutReason()
    })
  
    it("should not Delete an ERC721 token after validator funding", async () => {
      await expect(collectionInstance.deleteNFT(0)).to.be.revertedWithoutReason()
    });
  
    it("should let validator add more ERC20 tokens to alice's NFT and change commission", async () => {
      let exp = new BN(await time.latest()).add(new BN(7500));
      await time.increase(3601);
      await sampleERC20.connect(validator).approve(await piNftMethods.getAddress(), 200);
      const tx = await piNftMethods.connect(validator).addERC20(
        await collectionInstance.getAddress(),
        0,
        await sampleERC20.getAddress(),
        200,
        0,
        "uri",
        [[validator, 200]]
      );
      const tokenBal = await piNftMethods.viewBalance(
        await collectionInstance.getAddress(),
        0,
        await sampleERC20.getAddress()
      );
      const validatorBal = await sampleERC20.balanceOf(validator);
      expect(tokenBal).to.equal(700)
      expect(validatorBal).to.equal(300)
      let commission = await piNftMethods.validatorCommissions(
        await collectionInstance.getAddress(),
        0
      );
      expect(commission.isValid).to.equal(true);
      expect(commission.commission.account).to.equal(await validator.getAddress());
      expect(commission.commission.value).to.equal(0);
    });
  
    it("should not let validator add funds of a different erc20", async () => {
      let exp = new BN(await time.latest()).add(new BN(10000));
      await time.increase(7501);
      await expect(
        piNftMethods.connect(validator).addERC20(
          await collectionInstance.getAddress(),
          0,
          (await ethers.getSigners())[5],
          200,
          500,
          "uri",
          [[validator, 200]]
        )).to.be.revertedWith("invalid");
    });
  
    it("should let alice transfer NFT to bob", async () => {
      await collectionInstance.connect(alice).safeTransferFrom(alice, bob, 0);
      expect(
        await collectionInstance.ownerOf(0)).to.equal(await bob.getAddress())
    });
  
    it("should let bob transfer NFT to alice", async () => {
      await collectionInstance.connect(bob).safeTransferFrom(bob, alice, 0);
      expect(
        await collectionInstance.ownerOf(0)).to.equal(await alice.getAddress())
    });
  
    it("should not let non owner withdraw validator funds", async () => {
      await expect(piNftMethods.withdraw(
        await collectionInstance.getAddress(),
        0,
        await sampleERC20.getAddress(),
        300
      )).to.be.revertedWith('ERC721: caller is not token owner or approved')
    })
  
    it("should let alice withdraw erc20", async () => {
      let _bal = await sampleERC20.balanceOf(alice);
      await collectionInstance.connect(alice).approve(await piNftMethods.getAddress(), 0);
      await piNftMethods.withdraw(
        await collectionInstance.getAddress(),
        0,
        await sampleERC20.getAddress(),
        300
      );

      let withdrawn = await piNftMethods.viewWithdrawnAmount(await collectionInstance.getAddress(), 0);
      expect(withdrawn).to.equal(300)
  
      expect(await collectionInstance.ownerOf(0)).to.equal(await piNftMethods.getAddress());
      let bal = await sampleERC20.balanceOf(alice);
      expect(bal - _bal).to.equal(300);
      await piNftMethods.withdraw(
        await collectionInstance.getAddress(),
        0,
        await sampleERC20.getAddress(),
        200
      );

      withdrawn = await piNftMethods.viewWithdrawnAmount(await collectionInstance.getAddress(), 0);
      expect(withdrawn).to.equal(500)
  
      await expect(piNftMethods.withdraw(
        await collectionInstance.getAddress(),
        0,
        await sampleERC20.getAddress(),
        201
      )).to.be.revertedWithoutReason()
  
      expect(await collectionInstance.ownerOf(0)).to.equal(await piNftMethods.getAddress());
      bal = await sampleERC20.balanceOf(alice);
      expect(bal - _bal).to.equal(500)
      expect(await sampleERC20.balanceOf(await piNftMethods.getAddress())).to.equal(200);
    });
  
    it("should not let external account(bob) to repay the bid", async () => {
      await sampleERC20.connect(bob).approve(await piNftMethods.getAddress(), 300);
      await expect(piNftMethods.connect(bob).Repay(
        await collectionInstance.getAddress(),
        0,
        await sampleERC20.getAddress(),
        300)).to.be.revertedWithoutReason()
    })
  
    it("should not let alice repay more than what's borrowed", async () => {
      await sampleERC20.approve(await piNftMethods.getAddress(), 800);
      await expect(piNftMethods.Repay(
        await collectionInstance.getAddress(),
        0,
        await sampleERC20.getAddress(),
        800
      )).to.be.revertedWithoutReason();
    })
  
    it("should let alice repay erc20", async () => {
      let _bal = await sampleERC20.balanceOf(alice);
      await sampleERC20.approve(await piNftMethods.getAddress(), 300);
      await piNftMethods.Repay(
        await collectionInstance.getAddress(),
        0,
        await sampleERC20.getAddress(),
        300
      );
      expect(await collectionInstance.ownerOf(0)).to.equal(await piNftMethods.getAddress());
      let bal = await sampleERC20.balanceOf(alice);
      expect(_bal - bal).to.equal(300);
      await sampleERC20.approve(await piNftMethods.getAddress(), 200);
      await piNftMethods.Repay(
        await collectionInstance.getAddress(),
        0,
        await sampleERC20.getAddress(),
        200
      );
      expect(await collectionInstance.ownerOf(0)).to.equal(await alice.getAddress());
      bal = await sampleERC20.balanceOf(alice);
      expect(_bal - bal).to.equal(500);
    });
  
    it("should redeem CollectionFactory", async () => {
      await piNftMethods.redeemOrBurnPiNFT(
        await collectionInstance.getAddress(),
        0,
        alice,
        "0x0000000000000000000000000000000000000000",
        await sampleERC20.getAddress(),
        false
      );
      const balance = await sampleERC20.balanceOf(validator);
      expect(balance).to.equal(1000);
      expect(await collectionInstance.ownerOf(0)).to.equal(await alice.getAddress());
      expect(await piNftMethods.NFTowner(await collectionInstance.getAddress(), 0)).to.equal("0x0000000000000000000000000000000000000000")
      expect(await piNftMethods.approvedValidator(await collectionInstance.getAddress(), 0)).to.equal("0x0000000000000000000000000000000000000000")
      let commission = await piNftMethods.validatorCommissions(
        await collectionInstance.getAddress(),
        0
      );
      expect(commission.isValid).to.equal(false);
      expect(
        commission.commission.account).to.equal("0x0000000000000000000000000000000000000000"
      );
      expect(commission.commission.value).to.equal(0);
    });
  
    it("should transfer NFT to bob", async () => {
      await collectionInstance.safeTransferFrom(alice, bob, 0);
      expect(
        await collectionInstance.ownerOf(0)).to.equal(await bob.getAddress())
    });
  
    it("should let validator add ERC20 tokens to bob's NFT", async () => {
      let exp = new BN(await time.latest()).add(new BN(10000));
      await time.increase(7501);
      await sampleERC20.connect(validator).approve(await piNftMethods.getAddress(), 500);
      await piNftMethods.connect(bob).addValidator(await collectionInstance.getAddress(), 0, validator);
      const tx = await piNftMethods.connect(validator).addERC20(
        await collectionInstance.getAddress(),
        0,
        await sampleERC20.getAddress(),
        500,
        600,
        "uri",
        [[validator, 200]]
      );
      const tokenBal = await piNftMethods.viewBalance(
        await collectionInstance.getAddress(),
        0,
        await sampleERC20.getAddress()
      );
      const validatorBal = await sampleERC20.balanceOf(validator);
      expect(tokenBal).to.equal(500);
      expect(validatorBal).to.equal(500);
      let commission = await piNftMethods.validatorCommissions(
        await collectionInstance.getAddress(),
        0
      );
      expect(commission.isValid).to.equal(true);
      expect(commission.commission.account).to.equal(await validator.getAddress());
      expect(commission.commission.value).to.equal(600);
    });
  
    it("should let bob burn CollectionFactory", async () => {
      expect(await sampleERC20.balanceOf(bob)).to.equal(0);
      await collectionInstance.connect(bob).approve(await piNftMethods.getAddress(), 0);
      await piNftMethods.connect(bob).redeemOrBurnPiNFT(
        await collectionInstance.getAddress(),
        0,
        "0x0000000000000000000000000000000000000000",
        bob,
        await sampleERC20.getAddress(),
        true
      );
      const bobBal = await sampleERC20.balanceOf(bob);
      expect(
        await piNftMethods.viewBalance(
          await collectionInstance.getAddress(),
          0,
          await sampleERC20.getAddress()
        )).to.equal(0)
      expect(
        await sampleERC20.balanceOf(bob)).to.equal(500)
      expect(
        await collectionInstance.ownerOf(0)).to.equal(await validator.getAddress())
      let commission = await piNftMethods.validatorCommissions(
        await collectionInstance.getAddress(),
        0
      );
      expect(commission.isValid).to.equal(false);
      expect(
        commission.commission.account).to.equal("0x0000000000000000000000000000000000000000");
      expect(commission.commission.value).to.equal(0);
    });
  
    it("should prevent an external address to call piNFTMethods callable functions", async () => {
      await expect(
        collectionInstance.setRoyaltiesForValidator(1, 3000, [])).to.be.revertedWith("methods");
      await expect(
        collectionInstance.deleteValidatorRoyalties(1)).to.be.revertedWith("methods");
    });

    it("should not let non owner change collection method implementation", async () => {
      await expect(CollectionFactory.connect(royaltyReciever).changeCollectionMethodImplementation(
        "0xBf175FCC7086b4f9bd59d5EAE8eA67b8f940DE0d")).to.be.revertedWith("Ownable: caller is not the owner")

        await CollectionFactory.changeCollectionMethodImplementation(
          "0xBf175FCC7086b4f9bd59d5EAE8eA67b8f940DE0d")
    })
  })
})

