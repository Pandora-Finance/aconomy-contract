const {
  time,
  loadFixture,
} = require("@nomicfoundation/hardhat-toolbox/network-helpers");
const { anyValue } = require("@nomicfoundation/hardhat-chai-matchers/withArgs");
const { expect } = require("chai");
const { ethers } = require("hardhat");
const moment = require("moment");
const { BN } = require("@openzeppelin/test-helpers");

describe("piNFT", function () {
  let piNFTInstance;
  let erc2771Context;
  async function deploypiNFT() {
    [alice, validator, bob, royaltyReciever] = await ethers.getSigners();

    const LibShare = await hre.ethers.deployContract("LibShare", []);
    await LibShare.waitForDeployment();

    const piNFTMethods = await hre.ethers.getContractFactory("piNFTMethods", {
      libraries: {
        LibShare: await LibShare.getAddress(),
      },
    });

    piNftMethods = await upgrades.deployProxy(
      piNFTMethods,
      ["0xBf175FCC7086b4f9bd59d5EAE8eA67b8f940DE0d"],
      {
        initializer: "initialize",
        kind: "uups",
        unsafeAllow: ["external-library-linking"],
      }
    );

    const piNfT = await hre.ethers.getContractFactory("piNFT");

    piNFT = await upgrades.deployProxy(
      piNfT,
      [
        "Aconomy",
        "ACO",
        await piNftMethods.getAddress(),
        "0xBf175FCC7086b4f9bd59d5EAE8eA67b8f940DE0d",
      ],
      {
        initializer: "initialize",
        kind: "uups",
        unsafeAllow: ["external-library-linking"],
      }
    );

    const mintToken = await hre.ethers.deployContract("mintToken", [
      "100000000000",
    ]);
    sampleERC20 = await mintToken.waitForDeployment();

    const validateNFT = await hre.ethers.getContractFactory("validatedNFT")

    validatedNFT = await upgrades.deployProxy(
      validateNFT,
      [await piNftMethods.getAddress()],
      {
        initializer: "initialize",
        kind: "uups",
      }
    );

    const aconomyfee = await hre.ethers.deployContract("AconomyFee", []);
    aconomyFee = await aconomyfee.waitForDeployment();

    await aconomyFee.setAconomyPoolFee(50);
    await aconomyFee.setAconomyPiMarketFee(50);
    await aconomyFee.setAconomyNFTLendBorrowFee(50);


    const LibCollection = await hre.ethers.deployContract("LibCollection", []);
    await LibCollection.waitForDeployment();

    const CollectionFactory = await hre.ethers.getContractFactory(
      "CollectionFactory",
      {
        libraries: {
          LibCollection: await LibCollection.getAddress(),
        },
      }
    );

    const CollectionMethods = await hre.ethers.deployContract(
      "CollectionMethods",
      []
    );
    let CollectionMethod = await CollectionMethods.waitForDeployment();

    const collectionFactory = await upgrades.deployProxy(
      CollectionFactory,
      [await CollectionMethod.getAddress(), await piNftMethods.getAddress()],
      {
        initializer: "initialize",
        kind: "uups",
        unsafeAllow: ["external-library-linking"],
      }
    );

    await CollectionMethods.initialize(
      alice.getAddress(),
      await collectionFactory.getAddress(),
      "xyz",
      "xyz"
    );

    const LibMarket = await hre.ethers.deployContract("LibMarket", []);
    await LibMarket.waitForDeployment();

    const pimarket = await hre.ethers.getContractFactory("piMarket", {
      libraries: {
        LibMarket: await LibMarket.getAddress(),
      },
    });
    piMarket = await upgrades.deployProxy(
      pimarket,
      [
        await aconomyFee.getAddress(),
        await collectionFactory.getAddress(),
        await piNftMethods.getAddress(),
      ],
      {
        initializer: "initialize",
        kind: "uups",
        unsafeAllow: ["external-library-linking"],
      }
    );

    await piNftMethods.setPiMarket(piMarket.getAddress());

    // console.log("add",await validatedNFT.getAddress())

    // await sampleERC20.mint("0xf69F75EB0c72171AfF58D79973819B6A3038f39f", 1000);

    // let exp = new BN(await time.latest()).add(new BN(3600));

    // const tx = await validatedNFT.mintValidatedNFT("0xf69F75EB0c72171AfF58D79973819B6A3038f39f", "URI1", sampleERC20.getAddress(), 500, exp.toString(), 500, [["0xf69F75EB0c72171AfF58D79973819B6A3038f39f", 500]]);
    // const tx = await validatedNFT.mintValidatedNFT("0xf69F75EB0c72171AfF58D79973819B6A3038f39f", "URI1");
    // const owner = await validatedNFT.ownerOf(0);
    // console.log("ss",owner.toString());
    //   const bal = await validatedNFT.balanceOf("0xf69F75EB0c72171AfF58D79973819B6A3038f39f");
    //   expect(bal).to.equal(1);

    //   expect(
    //   await piNftMethods.approvedValidator(validatedNFT.getAddress(), 0)
    // ).to.equal("0xf69F75EB0c72171AfF58D79973819B6A3038f39f");

    return {
      piNFT,
      sampleERC20,
      piNftMethods,
      alice,
      validator,
      bob,
      royaltyReciever,
      validatedNFT,
    };
  }

  describe("Deployment", function () {
    it("should deploy the contracts", async () => {
      let {
        piNFT,
        sampleERC20,
        piNftMethods,
        alice,
        validator,
        bob,
        royaltyReciever,
        validatedNFT,
      } = await deploypiNFT();
    });

    it("should deploy the contracts", async () => {
      await expect(
        piNFT.connect(royaltyReciever).pause()
      ).to.be.revertedWith("Ownable: caller is not the owner");

      await piNFT.pause();

      // const tx = await piNFTcontract.mintNFT(alice, "URI1", [[royaltyReciever, 500]]);

      await expect(
        piNFT.mintNFT(alice, "URI1", [[royaltyReciever, 500]])
      ).to.be.revertedWith("Pausable: paused");

      await expect(
        piNFT.connect(royaltyReciever).unpause()
      ).to.be.revertedWith("Ownable: caller is not the owner");

      await piNFT.unpause();
      erc2771Context = await hre.ethers.getContractAt("AconomyERC2771Context", await piNFT.getAddress())
    });

    it("should not allow non owner to pause piNFTMethods", async () => {
      await expect(
        piNftMethods.connect(royaltyReciever).pause()
      ).to.be.revertedWith("Ownable: caller is not the owner");

      await piNftMethods.pause();

      await expect(
        piNftMethods.connect(royaltyReciever).unpause()
      ).to.be.revertedWith("Ownable: caller is not the owner");

      await piNftMethods.unpause();
    })

    it("should check is trusted forwarder", async () => {
      expect(
          await erc2771Context.isTrustedForwarder("0xBf175FCC7086b4f9bd59d5EAE8eA67b8f940DE0d")
          ).to.equal(true)

      expect(
          await erc2771Context.isTrustedForwarder(await bob.getAddress())
          ).to.equal(false)
    })

    it("should not let non owner add a trusted forwarder", async () => {
        await expect(erc2771Context.connect(royaltyReciever).addTrustedForwarder(await bob.getAddress())
        ).to.be.revertedWith("Ownable: caller is not the owner")
    })

    it("should not let non owner remove a trusted forwarder", async () => {
        await expect(erc2771Context.connect(royaltyReciever).removeTrustedForwarder(await alice.getAddress())
        ).to.be.revertedWith("Ownable: caller is not the owner")
    })

    it("should let owner add a trusted forwarder", async () => {
        await erc2771Context.addTrustedForwarder(await bob.getAddress())
        expect(
            await erc2771Context.isTrustedForwarder(await bob.getAddress())
            ).to.equal(true)
    })

    it("should let owner remove a trusted forwarder", async () => {
        await erc2771Context.removeTrustedForwarder(await bob.getAddress())
        expect(
            await erc2771Context.isTrustedForwarder(await bob.getAddress())
            ).to.equal(false)
    })

    it("should read the name and symbol of piNFT contract", async () => {
      expect(await piNFT.name()).to.equal("Aconomy");
      expect(await piNFT.symbol()).to.equal("ACO");
    });

    it("should fail to mint if the to address is address 0", async () => {
      await expect(
        piNFT.mintNFT("0x0000000000000000000000000000000000000000", "xyz", [
          [royaltyReciever, 500],
        ])
      ).to.be.revertedWithoutReason();
    });

    it("should mint an ERC721 token to alice", async () => {
      const tx = await piNFT.mintNFT(alice, "URI1", [[royaltyReciever, 500]]);
      await expect(
        piNFT.mintNFT(alice, "URI1", [[royaltyReciever, 4901]])
      ).to.be.revertedWith("overflow");

      const owner = await piNFT.ownerOf(0);
      const bal = await piNFT.balanceOf(alice);
      expect(owner).to.equal(await alice.getAddress());
      expect(bal).to.equal(1);
    });

    it("should not allow redeem if It's not funded", async () => {
      await piNFT.approve(piNftMethods.getAddress(), 0);

      await expect(
        piNftMethods.redeemOrBurnPiNFT(
          piNFT.getAddress(),
          0,
          alice.getAddress(),
          "0x0000000000000000000000000000000000000000",
          sampleERC20.getAddress(),
          false
        )
      ).to.be.revertedWithoutReason();
    });

    it("should not allow Burn if It's not funded", async () => {
      await piNFT.approve(piNftMethods.getAddress(), 0);

      await expect(
        piNftMethods.redeemOrBurnPiNFT(
          piNFT.getAddress(),
          0,
          alice.getAddress(),
          "0x0000000000000000000000000000000000000000",
          sampleERC20.getAddress(),
          true
        )
      ).to.be.revertedWithoutReason();
    });

    it("should not let owner withdraw validator funds before adding funds", async () => {
      await piNFT.approve(piNftMethods.getAddress(), 0);
      await expect(
        piNftMethods.withdraw(
          await piNFT.getAddress(),
          0,
          await sampleERC20.getAddress(),
          300
        )
      ).to.be.revertedWithoutReason();
    });


    it("should not let non owner setPiMarket Address", async () => {
      await expect(
        piNftMethods.connect(bob).setPiMarket(
          await piNFT.getAddress()
        )
      ).to.be.revertedWith("Ownable: caller is not the owner");
    });

    it("should check that Royality must be less 4900", async () => {
      await expect(
        piNFT.mintNFT(alice, "URI1", [[royaltyReciever, 4901]])
      ).to.be.revertedWith("overflow");
    });

    it("should check that Royality receiver isn't 0 address", async () => {
      await expect(
        piNFT.mintNFT(alice, "URI1", [
          ["0x0000000000000000000000000000000000000000", 4900],
        ])
      ).to.be.revertedWithoutReason();
    });

    it("should check that Royality value isn't 0", async () => {
      await expect(
        piNFT.mintNFT(alice, "URI1", [[royaltyReciever, 0]])
      ).to.be.revertedWithoutReason();
    });

    it("should check that Royality length is less than 10", async () => {
      await expect(
        piNFT.mintNFT(alice, "URI1", [
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
      ).to.be.revertedWithoutReason();
    });

    it("should mint an ERC721 token to alice", async () => {
      const tx = await piNFT.mintNFT(alice, "URI1", [[royaltyReciever, 500]]);
      const owner = await piNFT.ownerOf(0);
      // console.log("dhvdh",alice.getAddress())
      const bal = await piNFT.balanceOf(alice);
      expect(owner).to.equal(await alice.getAddress());
      expect(bal).to.equal(2);
    });

    // expect(
    //   await piNftMethods.approvedValidator(piNFT.getAddress(), 0)
    // ).to.equal(await validator.getAddress());

    // it("should mint an ERC721 token to alice", async () => {
    //   let exp = new BN(await time.latest()).add(new BN(3600));
    //   const tx = await piNFT.mintValidatedNFT("0xf69F75EB0c72171AfF58D79973819B6A3038f39f", "URI1", sampleERC20.getAddress(), 500, exp.toString(), 500, [[royaltyReciever, 500]]);
    //   // const owner = await piNFT.ownerOf(0);
    //   // console.log("dhvdh",alice.getAddress())
    //   const bal = await piNFT.balanceOf("0xf69F75EB0c72171AfF58D79973819B6A3038f39f");
    //   // expect(owner).to.equal(await alice.getAddress());
    //   expect(bal).to.equal(1);
    // });

    it("should not Delete an ERC721 token if the caller isn't the owner", async () => {
      await expect(
        piNFT.connect(bob).deleteNFT(1)
      ).to.be.revertedWithoutReason();
    });

    it("should not allow delete if contract is paused", async () => {
      await piNFT.pause();

      await expect(
        piNFT.deleteNFT(1)
      ).to.be.revertedWith("Pausable: paused");

      await piNFT.unpause();
    });

    it("should Delete an ERC721 token to alice", async () => {
      await piNFT.deleteNFT(1);
      const bal = await piNFT.balanceOf(alice);
      expect(bal).to.equal(1);
    });

    it("should fetch the tokenURI and royalties", async () => {
      const uri = await piNFT.tokenURI(0);
      expect(uri).to.equal("URI1");
      const royalties = await piNFT.getRoyalties(0);
      expect(royalties[0][0]).to.equal(await royaltyReciever.getAddress());
      expect(royalties[0][1]).to.equal(500);
    });

    it("should mint ERC20 tokens to validator", async () => {
      await sampleERC20.mint(validator, 1000);
      const balance = await sampleERC20.balanceOf(validator);
      expect(balance).to.equal(1000);
    });

    it("should not allow non owner to add a validator", async () => {
      // expectRevert.unspecified(piNftMethods.addValidator(piNFT.address, 0, validator, {from: bob}))

      await expect(
        piNftMethods
          .connect(bob)
          .addValidator(piNFT.getAddress(), 0, validator.getAddress())
      ).to.be.revertedWithoutReason();
    });

    it("should pause and unpause piNFTMethods", async () => {
      await piNftMethods.pause();

      // const tx = await piNFTcontract.mintNFT(alice, "URI1", [[royaltyReciever, 500]]);

      await expect(
        piNftMethods.addValidator(
          piNFT.getAddress(),
          0,
          validator.getAddress()
        )
      ).to.be.revertedWith("Pausable: paused");

      await piNftMethods.unpause();
    });

    it("should not let non validator add funds without adding validator address", async () => {
      await sampleERC20.connect(alice).approve(piNftMethods.getAddress(), 500);
      let exp = new BN(await time.latest()).add(new BN(3600));
      await expect(
        piNftMethods
          .connect(validator)
          .addERC20(
            await piNFT.getAddress(),
            0,
            sampleERC20.getAddress(),
            500,
            500,
            500,
            [[await validator.getAddress(), 200]]
          )
      ).to.be.revertedWithoutReason();
    });

    

        it("should not allow redeem if validator is 0 address", async () => {
          await piNFT.approve(piNftMethods.getAddress(), 0);
    
          await expect(
            piNftMethods.redeemOrBurnPiNFT(
              piNFT.getAddress(),
              0,
              alice.getAddress(),
              "0x0000000000000000000000000000000000000000",
              sampleERC20.getAddress(),
              false
            )
          ).to.be.revertedWithoutReason();
    
        });



    it("should allow alice to add a validator to the nft", async () => {
      await piNftMethods.addValidator(
        piNFT.getAddress(),
        0,
        validator.getAddress()
      );

      expect(
        await piNftMethods.approvedValidator(piNFT.getAddress(), 0)
      ).to.equal(await validator.getAddress());
    });

    it("should not let non validator add funds", async () => {
      await sampleERC20.connect(alice).approve(piNftMethods.getAddress(), 50000);
      let exp = new BN(await time.latest()).add(new BN(3600));
      await expect(
        piNftMethods
          .connect(alice)
          .addERC20(
            await piNFT.getAddress(),
            0,
            sampleERC20.getAddress(),
            500,
            500,
            500,
            [[await validator.getAddress(), 200]]
          )
      ).to.be.revertedWithoutReason();
    });

    it("should not let validator add funds with 0 royalty address ", async () => {
      await sampleERC20.connect(alice).approve(piNftMethods.getAddress(), 500);
      let exp = new BN(await time.latest()).add(new BN(3600));
      await expect(
        piNftMethods
          .connect(validator)
          .addERC20(
            await piNFT.getAddress(),
            0,
            sampleERC20.getAddress(),
            500,
            500,
            500,
            [
              [alice, 100],
              ["0x0000000000000000000000000000000000000000", 100],
              [alice, 100],
              [alice, 100],
              [alice, 100],
              [alice, 100],
              [alice, 100],
              [alice, 100],
              [alice, 100],
              [alice, 100],
            ]
          )
      ).to.be.revertedWithoutReason();
    });

    

    it("should not let validator add funds with more than 10 royalty", async () => {
      await sampleERC20.connect(alice).approve(piNftMethods.getAddress(), 500);
      let exp = new BN(await time.latest()).add(new BN(3600));
      await expect(
        piNftMethods
          .connect(validator)
          .addERC20(
            await piNFT.getAddress(),
            0,
            sampleERC20.getAddress(),
            500,
            500,
            500,
            [
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
            ]
          )
      ).to.be.revertedWithoutReason();
    });

    it("should not let validator add funds with 0 royalty value", async () => {
      await sampleERC20.connect(alice).approve(piNftMethods.getAddress(), 500);
      let exp = new BN(await time.latest()).add(new BN(3600));
      await expect(
        piNftMethods
          .connect(validator)
          .addERC20(
            await piNFT.getAddress(),
            0,
            sampleERC20.getAddress(),
            500,
            500,
            500,
            [
              [alice, 100],
              [alice, 100],
              [alice, 0],
              [alice, 100],
              [alice, 100],
              [alice, 100],
              [alice, 100],
              [alice, 100],
              [alice, 100],
              [alice, 100],
            ]
          )
      ).to.be.revertedWithoutReason();
    });

    it("should fail if paidcommition is calling by Non piMarketAddress ", async () => {
      await expect(
        piNftMethods
          .connect(validator)
          .paidCommission(
            await piNFT.getAddress(),
            1
          )
      ).to.be.revertedWithoutReason();
    });


    

    it("should not let erc20 contract be address 0", async () => {
      await sampleERC20
        .connect(validator)
        .approve(piNftMethods.getAddress(), 500);
        let exp = new BN(await time.latest()).add(new BN(3600));
      await expect(
        piNftMethods
          .connect(validator)
          .addERC20(
            await piNFT.getAddress(),
            0,
            "0x0000000000000000000000000000000000000000",
            500,
            // exp.toString(),
            500,
            500,
            [[await validator.getAddress(), 200]]
          )
      ).to.be.revertedWithoutReason();
    });

    
    it("should not let validator fund on non existing tokenId", async () => {
      await sampleERC20
        .connect(validator)
        .approve(piNftMethods.getAddress(), 500);
        let exp = new BN(await time.latest()).add(new BN(3600));
      await expect(
        piNftMethods
          .connect(validator)
          .addERC20(
            await piNFT.getAddress(),
            5,
            sampleERC20.getAddress(),
            500,
            500,
            500,
            [[await validator.getAddress(), 200]]
          )
      ).to.be.revertedWithoutReason();
    });

    it("should not let validator fund value be 0", async () => {
      await sampleERC20
        .connect(validator)
        .approve(piNftMethods.getAddress(), 500);
        let exp = new BN(await time.latest()).add(new BN(3600));
      await expect(
        piNftMethods
          .connect(validator)
          .addERC20(
            await piNFT.getAddress(),
            0,
            sampleERC20.getAddress(),
            0,
            500,
            500,
            [[await validator.getAddress(), 200]]
          )
      ).to.be.revertedWithoutReason();
    });

    it("should not let validator commission value be 4901", async () => {
      await sampleERC20
        .connect(validator)
        .approve(piNftMethods.getAddress(), 500);
        let exp = new BN(await time.latest()).add(new BN(3600));
      await expect(
        piNftMethods
          .connect(validator)
          .addERC20(
            await piNFT.getAddress(),
            0,
            sampleERC20.getAddress(),
            500,
            4901,
            500,
            [[await validator.getAddress(), 200]]
          )
      ).to.be.revertedWithoutReason();
    });

    it("should pause and unpause piNFTMethods", async () => {
      await piNftMethods.pause();

      await sampleERC20
        .connect(validator)
        .approve(piNftMethods.getAddress(), 500);
        let exp = new BN(await time.latest()).add(new BN(3600));

      await expect(
        piNftMethods
        .connect(validator)
        .addERC20(
          await piNFT.getAddress(),
          0,
          sampleERC20.getAddress(),
          500,
          500,
          500,
          [[await validator.getAddress(), 200]]
        )
      ).to.be.revertedWith("Pausable: paused");

      await piNftMethods.unpause();
    });

    it("should let validator add ERC20 tokens to alice's NFT", async () => {
      await sampleERC20
        .connect(validator)
        .approve(piNftMethods.getAddress(), 500);
        let exp = new BN(await time.latest()).add(new BN(3600));
      await piNftMethods
        .connect(validator)
        .addERC20(
          await piNFT.getAddress(),
          0,
          sampleERC20.getAddress(),
          500,
          500,
          500,
          [[await validator.getAddress(), 200]]
        );
      const tokenBal = await piNftMethods.viewBalance(
        piNFT.getAddress(),
        0,
        sampleERC20.getAddress()
      );
      expect(tokenBal).to.equal(500);
      const validatorBal = await sampleERC20.balanceOf(
        await validator.getAddress()
      );
      expect(validatorBal).to.equal(500);
      let commission = await piNftMethods.validatorCommissions(
        piNFT.getAddress(),
        0
      );
      expect(commission.isValid).to.equal(true);
      expect(commission.commission.account).to.equal(
        await validator.getAddress()
      );
      expect(commission.commission.value).to.equal(500);
    });

    it("should not allow validator changing after funding", async () => {
      await expect(
        piNftMethods.addValidator(piNFT.getAddress(), 0, validator.getAddress())
      ).to.be.revertedWithoutReason();
    });

    it("should not Delete an ERC721 token after validator funding", async () => {
      await expect(piNFT.deleteNFT(0)).to.be.revertedWithoutReason();
    });

    it("should let the validator add more erc20 tokens of the same contract and change commission value", async () => {
      await sampleERC20
        .connect(validator)
        .approve(piNftMethods.getAddress(), 200);
        // console.log("ghsavacv",await time.latest());
        await time.increase(3601);
        let val = await piNftMethods.validatorCommissions(piNFT.getAddress(),0);
        // console.log("dd",val.validationExpiration)
        let exp = new BN(await time.latest()).add(new BN(7500));
        // console.log("2acv",exp.toString());
        // console.log("gh222acv",await time.latest());
      await piNftMethods
        .connect(validator)
        .addERC20(piNFT.getAddress(), 0, sampleERC20.getAddress(), 200, 300, 500, [
          [validator, 200],
        ]);
      const tokenBal = await piNftMethods.viewBalance(
        piNFT.getAddress(),
        0,
        sampleERC20.getAddress()
      );

      const validatorBal = await sampleERC20.balanceOf(validator);
      expect(tokenBal).to.equal(700);
      expect(validatorBal).to.equal(300);
      let commission = await piNftMethods.validatorCommissions(
        piNFT.getAddress(),
        0
      );
      expect(commission.isValid).to.equal(true);
      expect(commission.commission.account).to.equal(
        await validator.getAddress()
      );
      expect(commission.commission.value).to.equal(300);
    });

    it("should not let validator add funds of a different erc20", async () => {
      let exp = new BN(await time.latest()).add(new BN(10000));
      await time.increase(7501);
      await sampleERC20
        .connect(validator)
        .approve(piNftMethods.getAddress(), 500);
      await expect(
        piNftMethods
          .connect(validator)
          .addERC20(await piNFT.getAddress(), 0, alice.getAddress(), 500, 400, 500, [
            [await validator.getAddress(), 200],
          ])
      ).to.be.revertedWith("invalid");
    });

    it("should let alice transfer NFT to bob", async () => {
      await piNFT
        .connect(alice)
        .safeTransferFrom(alice.getAddress(), bob.getAddress(), 0);
      expect(await piNFT.ownerOf(0)).to.equal(await bob.getAddress());
    });

    it("should let bob transfer NFT to alice", async () => {
      await piNFT
        .connect(bob)
        .safeTransferFrom(bob.getAddress(), alice.getAddress(), 0);
      expect(await piNFT.ownerOf(0)).to.equal(await alice.getAddress());
    });

    it("should not let non owner withdraw validator funds", async () => {
      await expect(
        piNftMethods.connect(bob).withdraw(
          piNFT.getAddress(),
          0,
          sampleERC20.getAddress(),
          300
        )
      ).to.be.revertedWithoutReason();
    });

    it("should not let non owner withdraw validator funds", async () => {
      await expect(
        piNftMethods.withdraw(
          piNFT.getAddress(),
          0,
          sampleERC20.getAddress(),
          300
        )
      ).to.be.revertedWith("ERC721: caller is not token owner or approved");
    });

    it("should not let owner withdraw validator funds more than added fund", async () => {
      await piNFT.approve(piNftMethods.getAddress(), 0);
      await expect(
        piNftMethods.withdraw(
          piNFT.getAddress(),
          0,
          sampleERC20.getAddress(),
          100000
        )
      ).to.be.revertedWithoutReason();
    });
    
    it("let alice setPercent while it's paused", async () => {
      await piNftMethods.pause();
      await expect(
        piNftMethods.withdraw(
          await piNFT.getAddress(),
          0,
          sampleERC20.getAddress(),
          300
        )
        ).to.be.revertedWith("Pausable: paused"
      );
      await piNftMethods.unpause();
    });

    it("should not let owner withdraw validator funds more than added fund", async () => {
      await piNFT.approve(piNftMethods.getAddress(), 0);
      await expect(
        piNftMethods.withdraw(
          piNFT.getAddress(),
          0,
          sampleERC20.getAddress(),
          100000
        )
      ).to.be.revertedWithoutReason();
    });

    

    it("should let alice withdraw erc20", async () => {
      let _bal = await sampleERC20.balanceOf(alice.getAddress());
      await piNFT.approve(piNftMethods.getAddress(), 0);
      await piNftMethods.withdraw(
        await piNFT.getAddress(),
        0,
        sampleERC20.getAddress(),
        300
      );

      await expect(
        piNftMethods.connect(bob).withdraw(
          piNFT.getAddress(),
          0,
          sampleERC20.getAddress(),
          100000
        )
      ).to.be.revertedWithoutReason();

      
      let withdrawn = await piNftMethods.viewWithdrawnAmount(await piNFT.getAddress(), 0);
      expect(withdrawn).to.equal(300)

      expect(await piNFT.ownerOf(0)).to.equal(await piNftMethods.getAddress());
      let bal = await sampleERC20.balanceOf(alice);
      expect(bal - _bal).to.equal(300);
      await piNftMethods.withdraw(
        piNFT.getAddress(),
        0,
        sampleERC20.getAddress(),
        200
      );

      withdrawn = await piNftMethods.viewWithdrawnAmount(await piNFT.getAddress(), 0);
      expect(withdrawn).to.equal(500)

      expect(await piNFT.ownerOf(0)).to.equal(await piNftMethods.getAddress());
      bal = await sampleERC20.balanceOf(alice);
      expect(bal - _bal).to.equal(500);
      expect(await sampleERC20.balanceOf(piNftMethods.getAddress())).to.equal(
        200
      );

      await expect(
        piNftMethods.withdraw(
          piNFT.getAddress(),
          0,
          sampleERC20.getAddress(),
          201
        )
      ).to.be.revertedWithoutReason();
    });

    it("should not let external account(bob) to repay the bid", async () => {
      await sampleERC20.connect(bob).approve(piNftMethods.getAddress(), 300);
      await expect(
        piNftMethods
          .connect(bob)
          .Repay(piNFT.getAddress(), 0, sampleERC20.getAddress(), 300)
      ).to.be.revertedWith("not owner");
    });

    it("should not let alice repay more than what's borrowed", async () => {
      await sampleERC20.approve(piNftMethods.getAddress(), 800);
      await expect(
        piNftMethods.Repay(piNFT.getAddress(), 0, sampleERC20.getAddress(), 800)
      ).to.be.revertedWithoutReason();
    });

    it("let alice setPercent while it's paused", async () => {
      await piNftMethods.pause();
      await expect(
        piNftMethods.Repay(
          piNFT.getAddress(),
          0,
          sampleERC20.getAddress(),
          300
        )
        ).to.be.revertedWith("Pausable: paused"
      );
      await piNftMethods.unpause();
    });

    it("should let alice repay erc20", async () => {
      let _bal = await sampleERC20.balanceOf(alice.getAddress());
      await sampleERC20.approve(piNftMethods.getAddress(), 300);
      await piNftMethods.Repay(
        piNFT.getAddress(),
        0,
        sampleERC20.getAddress(),
        300
      );
      expect(await piNFT.ownerOf(0)).to.equal(await piNftMethods.getAddress());
      let bal = await sampleERC20.balanceOf(alice.getAddress());
      expect(_bal - bal).to.equal(300);
      await sampleERC20.approve(piNftMethods.getAddress(), 200);
      await piNftMethods.Repay(
        piNFT.getAddress(),
        0,
        sampleERC20.getAddress(),
        200
      );
      expect(await piNFT.ownerOf(0)).to.equal(await alice.getAddress());
      bal = await sampleERC20.balanceOf(await alice.getAddress());
      expect(_bal - bal).to.equal(500);
    });

    it("should not let alice repay again", async () => {
      await sampleERC20.approve(piNftMethods.getAddress(), 800);
      await expect(
        piNftMethods.Repay(
          piNFT.getAddress(),
          0,
          sampleERC20.getAddress(),
          200
        )
      ).to.be.revertedWithoutReason();
    });

    it("should not allow redeem if contract is paused", async () => {
      await piNFT.approve(piNftMethods.getAddress(), 0);
      await piNftMethods.pause();

      await expect(
        piNftMethods.redeemOrBurnPiNFT(
          piNFT.getAddress(),
          0,
          alice.getAddress(),
          "0x0000000000000000000000000000000000000000",
          sampleERC20.getAddress(),
          false
        )
      ).to.be.revertedWith("Pausable: paused");

      await piNftMethods.unpause();
    });

    it("should not allow redeem if erc20 contract is 0 address", async () => {
      await piNFT.approve(piNftMethods.getAddress(), 0);

      await expect(
        piNftMethods.redeemOrBurnPiNFT(
          piNFT.getAddress(),
          0,
          alice.getAddress(),
          "0x0000000000000000000000000000000000000000",
          "0x0000000000000000000000000000000000000000",
          false
        )
      ).to.be.revertedWithoutReason();

    });

    it("should not allow redeem if NFT receiver is 0 address", async () => {
      await piNFT.approve(piNftMethods.getAddress(), 0);

      await expect(
        piNftMethods.redeemOrBurnPiNFT(
          piNFT.getAddress(),
          0,
          "0x0000000000000000000000000000000000000000",
          "0x0000000000000000000000000000000000000000",
          sampleERC20.getAddress(),
          false
        )
      ).to.be.revertedWithoutReason();

    });

    it("should not allow redeem if ERC20 receiver is not 0 address", async () => {
      await piNFT.approve(piNftMethods.getAddress(), 0);

      await expect(
        piNftMethods.redeemOrBurnPiNFT(
          piNFT.getAddress(),
          0,
          alice.getAddress(),
          alice.getAddress(),
          sampleERC20.getAddress(),
          false
        )
      ).to.be.revertedWithoutReason();

    });

    it("should redeem piNft", async () => {
      await piNFT.approve(piNftMethods.getAddress(), 0);
      await piNftMethods.redeemOrBurnPiNFT(
        piNFT.getAddress(),
        0,
        alice.getAddress(),
        "0x0000000000000000000000000000000000000000",
        sampleERC20.getAddress(),
        false
      );
      const balance = await sampleERC20.balanceOf(validator.getAddress());
      expect(balance).to.equal(1000);
      expect(await piNFT.ownerOf(0)).to.equal(await alice.getAddress());
      expect(await piNftMethods.NFTowner(piNFT.getAddress(), 0)).to.equal(
        "0x0000000000000000000000000000000000000000"
      );
      expect(
        await piNftMethods.approvedValidator(piNFT.getAddress(), 0)
      ).to.equal("0x0000000000000000000000000000000000000000");
      let commission = await piNftMethods.validatorCommissions(
        piNFT.getAddress(),
        0
      );
      expect(commission.isValid).to.equal(false);
      expect(commission.commission.account).to.equal(
        "0x0000000000000000000000000000000000000000"
      );
      expect(commission.commission.value).to.equal(0);
    });

    it("should not allow redeem if ERC20 balance is 0", async () => {
      await piNFT.approve(piNftMethods.getAddress(), 0);

      await expect(
        piNftMethods.redeemOrBurnPiNFT(
          piNFT.getAddress(),
          0,
          alice.getAddress(),
          "0x0000000000000000000000000000000000000000",
          sampleERC20.getAddress(),
          false
        )
      ).to.be.revertedWithoutReason();

    });

    it("should transfer NFT to bob", async () => {
      await piNFT.safeTransferFrom(alice.getAddress(), bob.getAddress(), 0);
      expect(await piNFT.ownerOf(0)).to.equal(await bob.getAddress());
    });

    // it("should let validator add ERC20 tokens to bob's NFT", async () => {
    //   await sampleERC20
    //     .connect(validator)
    //     .approve(piNftMethods.getAddress(), 500);
    //   await piNftMethods
    //     .connect(bob)
    //     .addValidator(piNFT.getAddress(), 0, validator.getAddress());
    //   await expect(
    //     piNftMethods
    //       .connect(validator)
    //       .addERC20(piNFT.getAddress(), 0, sampleERC20.getAddress(), 500, 400, [
    //         [validator.getAddress(), 2900],
    //         [bob.getAddress(), 2001],
    //       ])
    //   ).to.be.revertedWith("overflow");
      
    //     // await piNFT.approve(piNftMethods.getAddress(), 0);
  
    //     await expect(
    //       piNftMethods.connect(bob).redeemOrBurnPiNFT(
    //         piNFT.getAddress(),
    //         0,
    //         "0x0000000000000000000000000000000000000000",
    //         bob,
    //         sampleERC20.getAddress(),
    //         true
    //       )
    //     ).to.be.revertedWithoutReason();

    //   await piNftMethods
    //     .connect(validator)
    //     .addERC20(piNFT.getAddress(), 0, sampleERC20.getAddress(), 500, moment.now()+3600, 400, [
    //       [validator, 200],
    //     ]);
    //   const tokenBal = await piNftMethods.viewBalance(
    //     piNFT.getAddress(),
    //     0,
    //     sampleERC20.getAddress()
    //   );
    //   const validatorBal = await sampleERC20.balanceOf(validator.getAddress());
    //   expect(tokenBal).to.equal(500);
    //   expect(validatorBal).to.equal(500);
    //   let commission = await piNftMethods.validatorCommissions(
    //     piNFT.getAddress(),
    //     0
    //   );
    //   expect(commission.isValid).to.equal(true);
    //   expect(commission.commission.account).to.equal(
    //     await validator.getAddress()
    //   );
    //   expect(commission.commission.value).to.equal(400);
    // });

    it("should let validator add ERC20 tokens to bob's NFT", async () => {
      await sampleERC20
        .connect(validator)
        .approve(piNftMethods.getAddress(), 500);
      await piNftMethods
        .connect(bob)
        .addValidator(piNFT.getAddress(), 0, validator.getAddress());
      await expect(
        piNftMethods
          .connect(validator)
          .addERC20(piNFT.getAddress(), 0, sampleERC20.getAddress(), 500, 400, 500,[
            [validator.getAddress(), 2900],
            [bob.getAddress(), 2001],
          ])
      ).to.be.revertedWith("overflow");
      
        // await piNFT.approve(piNftMethods.getAddress(), 0);
  
        await expect(
          piNftMethods.connect(bob).redeemOrBurnPiNFT(
            piNFT.getAddress(),
            0,
            "0x0000000000000000000000000000000000000000",
            bob,
            sampleERC20.getAddress(),
            true
          )
        ).to.be.revertedWithoutReason();

      await piNftMethods
        .connect(validator)
        .addERC20(piNFT.getAddress(), 0, sampleERC20.getAddress(), 500, 400, 500,[
          [validator, 200],
        ]);
      const tokenBal = await piNftMethods.viewBalance(
        piNFT.getAddress(),
        0,
        sampleERC20.getAddress()
      );
      const validatorBal = await sampleERC20.balanceOf(validator.getAddress());
      expect(tokenBal).to.equal(500);
      expect(validatorBal).to.equal(500);
      let commission = await piNftMethods.validatorCommissions(
        piNFT.getAddress(),
        0
      );
      expect(commission.isValid).to.equal(true);
      expect(commission.commission.account).to.equal(
        await validator.getAddress()
      );
      expect(commission.commission.value).to.equal(400);
    });

    it("should not allow burn if erc20 receiver is 0 address", async () => {
      await piNFT.connect(bob).approve(piNftMethods.getAddress(), 0);

      await expect(
        piNftMethods.redeemOrBurnPiNFT(
          piNFT.getAddress(),
          0,
          "0x0000000000000000000000000000000000000000",
          "0x0000000000000000000000000000000000000000",
          sampleERC20.getAddress(),
          false
        )
      ).to.be.revertedWithoutReason("");
    });

    it("should not allow burn if NFT receiver is not 0 address", async () => {
      await piNFT.connect(bob).approve(piNftMethods.getAddress(), 0);

      await expect(
        piNftMethods.redeemOrBurnPiNFT(
          piNFT.getAddress(),
          0,
          alice.getAddress(),
          alice.getAddress(),
          sampleERC20.getAddress(),
          false
        )
      ).to.be.revertedWithoutReason("");
    });

    it("should not allow burn if NFT receiver is 0 address", async () => {
      await piNFT.connect(bob).approve(piNftMethods.getAddress(), 0);

      await expect(
        piNftMethods.connect(bob).redeemOrBurnPiNFT(
          piNFT.getAddress(),
          0,
          bob.getAddress(),
          bob.getAddress(),
          sampleERC20.getAddress(),
          true
        )
      ).to.be.revertedWithoutReason();
    });

    it("should not allow burn if ERC20 is 0 address", async () => {
      await piNFT.connect(bob).approve(piNftMethods.getAddress(), 0);

      await expect(
        piNftMethods.connect(bob).redeemOrBurnPiNFT(
          piNFT.getAddress(),
          0,
          "0x0000000000000000000000000000000000000000",
          "0x0000000000000000000000000000000000000000",
          sampleERC20.getAddress(),
          true
        )
      ).to.be.revertedWithoutReason();
    });


    

    it("should let bob burn piNFT", async () => {
      expect(await sampleERC20.balanceOf(bob.getAddress())).to.equal(0);
      await piNFT.connect(bob).approve(piNftMethods.getAddress(), 0);
      await piNftMethods
        .connect(bob)
        .redeemOrBurnPiNFT(
          piNFT.getAddress(),
          0,
          "0x0000000000000000000000000000000000000000",
          bob,
          sampleERC20.getAddress(),
          true
        );
      const bobBal = await sampleERC20.balanceOf(bob.getAddress());
      expect(
        await piNftMethods.viewBalance(
          piNFT.getAddress(),
          0,
          sampleERC20.getAddress()
        )
      ).to.equal(0);
      expect(await sampleERC20.balanceOf(bob.getAddress())).to.equal(500);
      expect(await piNFT.ownerOf(0)).to.equal(await validator.getAddress());
      let commission = await piNftMethods.validatorCommissions(
        piNFT.getAddress(),
        0
      );
      expect(commission.isValid).to.equal(false);
      expect(commission.commission.account).to.equal(
        "0x0000000000000000000000000000000000000000"
      );
      expect(commission.commission.value).to.equal(0);
    });

    it("should prevent an external address to call piNFTMethods callable functions", async () => {
      await expect(
        piNFT.setRoyaltiesForValidator(1, 3000, [])
      ).to.be.revertedWith("methods");
      await expect(piNFT.deleteValidatorRoyalties(1)).to.be.revertedWith(
        "methods"
      );
    });
  });

  describe("Deployment", function () {
    it("should mint an ERC721 token to alice", async () => {
      const tx = await piNFT.mintNFT(alice, "URI1", [[royaltyReciever, 500]]);
      await expect(
        await piNFT.mintNFT(alice, "URI1", [[royaltyReciever, 500]])
      )
      .to.emit(piNFT, "TokenMinted")
      .withArgs(3, await alice.getAddress(),"URI1");

      const owner = await piNFT.ownerOf(3);
      const bal = await piNFT.balanceOf(alice);
      expect(owner).to.equal(await alice.getAddress());
      expect(bal).to.equal(2);
    });

    it("should allow alice to add a validator to the nft", async () => {
      await piNftMethods.addValidator(
        piNFT.getAddress(),
        3,
        validator.getAddress()
      );

      expect(
        await piNftMethods.approvedValidator(piNFT.getAddress(), 3)
      ).to.equal(await validator.getAddress());
    });

    it("should not let owner withdraw validator funds before adding funds", async () => {
      await piNFT.approve(piNftMethods.getAddress(), 3);
      await expect(
        piNftMethods.withdraw(
          await piNFT.getAddress(),
          3,
          await sampleERC20.getAddress(),
          300
        )
      ).to.be.revertedWithoutReason();
    });

    it("should let validator add ERC20 tokens to alice's NFT", async () => {
      let exp = new BN(await time.latest()).add(new BN(3600));
        // await time.increase(3601);
      await sampleERC20
        .connect(validator)
        .approve(piNftMethods.getAddress(), 500);

      await piNftMethods
        .connect(validator)
        .addERC20(
          await piNFT.getAddress(),
          3,
          sampleERC20.getAddress(),
          500,
          500,
          500,
          [[await validator.getAddress(), 200]]
        );
      const tokenBal = await piNftMethods.viewBalance(
        piNFT.getAddress(),
        3,
        sampleERC20.getAddress()
      );
      expect(tokenBal).to.equal(500);
      const validatorBal = await sampleERC20.balanceOf(
        await validator.getAddress()
      );
      expect(validatorBal).to.equal(0);
      let commission = await piNftMethods.validatorCommissions(
        piNFT.getAddress(),
        3
      );
      expect(commission.isValid).to.equal(true);
      expect(commission.commission.account).to.equal(
        await validator.getAddress()
      );
      expect(commission.commission.value).to.equal(500);
    });

    it("should not let owner withdraw validator funds more than added fund", async () => {
      await piNFT.approve(piNftMethods.getAddress(), 3);
      await expect(
        piNftMethods.withdraw(
          piNFT.getAddress(),
          3,
          sampleERC20.getAddress(),
          100000
        )
      ).to.be.revertedWithoutReason();
    });


    it("should let alice withdraw erc20", async () => {
      let _bal = await sampleERC20.balanceOf(alice.getAddress());
      await piNFT.approve(piNftMethods.getAddress(), 3);
      await piNftMethods.withdraw(
        await piNFT.getAddress(),
        3,
        sampleERC20.getAddress(),
        300
      );

      await expect(
        piNftMethods.connect(bob).withdraw(
          piNFT.getAddress(),
          0,
          sampleERC20.getAddress(),
          100000
        )
      ).to.be.revertedWithoutReason();

      
      let withdrawn = await piNftMethods.viewWithdrawnAmount(await piNFT.getAddress(), 3);
      expect(withdrawn).to.equal(300)

      expect(await piNFT.ownerOf(3)).to.equal(await piNftMethods.getAddress());
      let bal = await sampleERC20.balanceOf(alice);
      expect(bal - _bal).to.equal(300);
      await piNftMethods.withdraw(
        piNFT.getAddress(),
        3,
        sampleERC20.getAddress(),
        200
      );

      withdrawn = await piNftMethods.viewWithdrawnAmount(await piNFT.getAddress(), 3);
      expect(withdrawn).to.equal(500)

      expect(await piNFT.ownerOf(3)).to.equal(await piNftMethods.getAddress());
      bal = await sampleERC20.balanceOf(alice);
      expect(bal - _bal).to.equal(500);
      expect(await sampleERC20.balanceOf(piNftMethods.getAddress())).to.equal(
        0
      );

      await expect(
        piNftMethods.withdraw(
          piNFT.getAddress(),
          3,
          sampleERC20.getAddress(),
          201
        )
      ).to.be.revertedWithoutReason();
    });

    it("should let validator add more ERC20 tokens to alice's NFT", async () => {
      await sampleERC20.mint(validator, 500);

      await sampleERC20
        .connect(validator)
        .approve(piNftMethods.getAddress(), 500);

        let exp = new BN(await time.latest()).add(new BN(7500));
        await time.increase(3601);

      await piNftMethods
        .connect(validator)
        .addERC20(
          await piNFT.getAddress(),
          3,
          sampleERC20.getAddress(),
          500,
          500,
          500,
          [[await validator.getAddress(), 200]]
        );
      const tokenBal = await piNftMethods.viewBalance(
        piNFT.getAddress(),
        3,
        sampleERC20.getAddress()
      );
      expect(tokenBal).to.equal(1000);
      const validatorBal = await sampleERC20.balanceOf(
        await validator.getAddress()
      );
      expect(validatorBal).to.equal(0);
      let commission = await piNftMethods.validatorCommissions(
        piNFT.getAddress(),
        3
      );
      expect(commission.isValid).to.equal(true);
      expect(commission.commission.account).to.equal(
        await validator.getAddress()
      );
      expect(commission.commission.value).to.equal(500);
    });

    // it("should let alice again withdraw erc20", async () => {
    //   let _bal = await sampleERC20.balanceOf(alice.getAddress());
    //   // await piNFT.approve(piNftMethods.getAddress(), 3);
    //   await piNftMethods.withdraw(
    //     await piNFT.getAddress(),
    //     3,
    //     sampleERC20.getAddress(),
    //     300
    //   );

    //   await expect(
    //     piNftMethods.connect(bob).withdraw(
    //       piNFT.getAddress(),
    //       0,
    //       sampleERC20.getAddress(),
    //       100000
    //     )
    //   ).to.be.revertedWithoutReason();

      
    //   let withdrawn = await piNftMethods.viewWithdrawnAmount(await piNFT.getAddress(), 3);
    //   expect(withdrawn).to.equal(800)

    //   expect(await piNFT.ownerOf(3)).to.equal(await piNftMethods.getAddress());
    //   let bal = await sampleERC20.balanceOf(alice);
    //   expect(bal - _bal).to.equal(300);
    //   await piNftMethods.withdraw(
    //     piNFT.getAddress(),
    //     3,
    //     sampleERC20.getAddress(),
    //     200
    //   );

    //   withdrawn = await piNftMethods.viewWithdrawnAmount(await piNFT.getAddress(), 3);
    //   expect(withdrawn).to.equal(1000)

    //   expect(await piNFT.ownerOf(3)).to.equal(await piNftMethods.getAddress());
    //   bal = await sampleERC20.balanceOf(alice);
    //   expect(bal - _bal).to.equal(500);
    //   expect(await sampleERC20.balanceOf(piNftMethods.getAddress())).to.equal(
    //     0
    //   );

    //   await expect(
    //     piNftMethods.withdraw(
    //       piNFT.getAddress(),
    //       3,
    //       sampleERC20.getAddress(),
    //       201
    //     )
    //   ).to.be.revertedWithoutReason();
    // });

    it("should let alice again withdraw erc20", async () => {
      let _bal = await sampleERC20.balanceOf(alice.getAddress());
      // await piNFT.approve(piNftMethods.getAddress(), 3);
      await piNftMethods.withdraw(
        await piNFT.getAddress(),
        3,
        sampleERC20.getAddress(),
        300
      );

      await expect(
        piNftMethods.connect(bob).withdraw(
          piNFT.getAddress(),
          0,
          sampleERC20.getAddress(),
          100000
        )
      ).to.be.revertedWithoutReason();

      
      let withdrawn = await piNftMethods.viewWithdrawnAmount(await piNFT.getAddress(), 3);
      expect(withdrawn).to.equal(800)

      expect(await piNFT.ownerOf(3)).to.equal(await piNftMethods.getAddress());
      let bal = await sampleERC20.balanceOf(alice);
      expect(bal - _bal).to.equal(300);
      await piNftMethods.withdraw(
        piNFT.getAddress(),
        3,
        sampleERC20.getAddress(),
        200
      );

      withdrawn = await piNftMethods.viewWithdrawnAmount(await piNFT.getAddress(), 3);
      expect(withdrawn).to.equal(1000)

      expect(await piNFT.ownerOf(3)).to.equal(await piNftMethods.getAddress());
      bal = await sampleERC20.balanceOf(alice);
      expect(bal - _bal).to.equal(500);
      expect(await sampleERC20.balanceOf(piNftMethods.getAddress())).to.equal(
        0
      );

      await expect(
        piNftMethods.withdraw(
          piNFT.getAddress(),
          3,
          sampleERC20.getAddress(),
          201
        )
      ).to.be.revertedWithoutReason();
    });

    it("should not let alice repay more than what's borrowed", async () => {
      await sampleERC20.approve(piNftMethods.getAddress(), 2000);
      await expect(
        piNftMethods.Repay(piNFT.getAddress(), 3, sampleERC20.getAddress(), 2000)
      ).to.be.revertedWithoutReason();
    });

    it("should let alice repay erc20", async () => {
      let _bal = await sampleERC20.balanceOf(alice.getAddress());
      await sampleERC20.approve(piNftMethods.getAddress(), 500);
      await piNftMethods.Repay(
        piNFT.getAddress(),
        3,
        sampleERC20.getAddress(),
        500
      );
      expect(await piNFT.ownerOf(3)).to.equal(await piNftMethods.getAddress());
      let bal = await sampleERC20.balanceOf(alice.getAddress());
      expect(_bal - bal).to.equal(500);
      await sampleERC20.approve(piNftMethods.getAddress(), 500);
      await piNftMethods.Repay(
        piNFT.getAddress(),
        3,
        sampleERC20.getAddress(),
        500
      );
      expect(await piNFT.ownerOf(3)).to.equal(await alice.getAddress());
      bal = await sampleERC20.balanceOf(await alice.getAddress());
      expect(_bal - bal).to.equal(1000);
    });

    it("should not let alice repay again", async () => {
      await sampleERC20.approve(piNftMethods.getAddress(), 800);
      await expect(
        piNftMethods.Repay(
          piNFT.getAddress(),
          3,
          sampleERC20.getAddress(),
          200
        )
      ).to.be.revertedWithoutReason();
    });

  })

  describe("ValidatedNFT", function () {
    it("should should mint a validated NFT", async () => {
      const tx = await validatedNFT.mintValidatedNFT(validator, "URI1");
    const owner = await validatedNFT.ownerOf(0);
    // console.log("ss",owner.toString());
      const bal = await validatedNFT.balanceOf(validator);
      expect(bal).to.equal(1);

      expect(
      await piNftMethods.approvedValidator(validatedNFT.getAddress(), 0)
    ).to.equal(await validator.getAddress());
  })

  it("should not pause by non owner", async () => {
    await expect(
      validatedNFT.connect(royaltyReciever).pause()
    ).to.be.revertedWith("Ownable: caller is not the owner");
    await validatedNFT.pause();


    await expect(
      validatedNFT.mintValidatedNFT(alice, "URI1")
    ).to.be.revertedWith("Pausable: paused");

    await expect(
      validatedNFT.connect(royaltyReciever).unpause()
    ).to.be.revertedWith("Ownable: caller is not the owner");

    await validatedNFT.unpause();

    const tx = await validatedNFT.mintValidatedNFT(alice, "URI1");
    const owner = await validatedNFT.ownerOf(1);
    // console.log("ss",owner.toString());
      const bal = await validatedNFT.balanceOf(alice);
      expect(bal).to.equal(1);

      expect(
      await piNftMethods.approvedValidator(validatedNFT.getAddress(), 1)
    ).to.equal(await alice.getAddress());

  });

  it("should let validator add ERC20 tokens to his NFT", async () => {

    await sampleERC20.mint(validator.getAddress(), 1000);
    const validatorBal1 = await sampleERC20.balanceOf(
      await validator.getAddress()
    );
    await sampleERC20
      .connect(validator)
      .approve(piNftMethods.getAddress(), 500);
      let exp = new BN(await time.latest()).add(new BN(3600));
    await piNftMethods
      .connect(validator)
      .addERC20(
        await validatedNFT.getAddress(),
        0,
        sampleERC20.getAddress(),
        500,
        500,
        500,
        [[await validator.getAddress(), 200]]
      );
    const tokenBal = await piNftMethods.viewBalance(
      validatedNFT.getAddress(),
      0,
      sampleERC20.getAddress()
    );
    expect(tokenBal).to.equal(500);
    const validatorBal = await sampleERC20.balanceOf(
      await validator.getAddress()
    );
    expect(validatorBal).to.equal(500);
    let commission = await piNftMethods.validatorCommissions(
      validatedNFT.getAddress(),
      0
    );
    expect(commission.isValid).to.equal(true);
    expect(commission.commission.account).to.equal(
      await validator.getAddress()
    );
    expect(commission.commission.value).to.equal(500);
  });

  it("should let validator transfer NFT to alice", async () => {
    await validatedNFT
      .connect(validator)
      .safeTransferFrom(validator.getAddress(), alice.getAddress(), 0);
    expect(await validatedNFT.ownerOf(0)).to.equal(await alice.getAddress());
  });

  it("should redeem piNft", async () => {
    const validatorBal1 = await sampleERC20.balanceOf(
      await validator.getAddress()
    );

    expect(validatorBal1).to.equal(500);

    const aliceBal1 = await sampleERC20.balanceOf(
      await alice.getAddress()
    );

    expect(aliceBal1).to.equal(100000000000);

    // console.log("Validator", validatorBal1);
    // console.log("aliceBal1", aliceBal1.toString());

    await validatedNFT.approve(piNftMethods.getAddress(), 0);
    await piNftMethods.redeemOrBurnPiNFT(
      validatedNFT.getAddress(),
      0,
      alice.getAddress(),
      "0x0000000000000000000000000000000000000000",
      sampleERC20.getAddress(),
      false
    );
    const balance = await sampleERC20.balanceOf(validator.getAddress());
    // console.log("Validator", balance);

    const aliceBal2 = await sampleERC20.balanceOf(
      await alice.getAddress()
    );

    expect(aliceBal2).to.equal(100000000000);

    // console.log("Validator", validatorBal1);
    // console.log("aliceBal2", aliceBal2.toString());
    expect(balance).to.equal(1000);
    expect(await validatedNFT.ownerOf(0)).to.equal(await alice.getAddress());
    expect(await piNftMethods.NFTowner(validatedNFT.getAddress(), 0)).to.equal(
      "0x0000000000000000000000000000000000000000"
    );
    expect(
      await piNftMethods.approvedValidator(validatedNFT.getAddress(), 0)
    ).to.equal("0x0000000000000000000000000000000000000000");
    let commission = await piNftMethods.validatorCommissions(
      validatedNFT.getAddress(),
      0
    );
    expect(commission.isValid).to.equal(false);
    expect(commission.commission.account).to.equal(
      "0x0000000000000000000000000000000000000000"
    );
    expect(commission.commission.value).to.equal(0);
  });

  it("should should mint a validated NFT again", async () => {
    const tx = await validatedNFT.mintValidatedNFT(validator, "URI1");
  const owner = await validatedNFT.ownerOf(2);
    const bal = await validatedNFT.balanceOf(validator);
    expect(bal).to.equal(1);
    expect(owner).to.equal(await validator.getAddress());

    expect(
    await piNftMethods.approvedValidator(validatedNFT.getAddress(), 2)
  ).to.equal(await validator.getAddress());
})




it("should let validator add ERC20 tokens to his NFT", async () => {

  const validatorBal1 = await sampleERC20.balanceOf(
    await validator.getAddress()
  );
  await sampleERC20
    .connect(validator)
    .approve(piNftMethods.getAddress(), 500);
    let exp = new BN(await time.latest()).add(new BN(3600));
  await piNftMethods
    .connect(validator)
    .addERC20(
      await validatedNFT.getAddress(),
      2,
      sampleERC20.getAddress(),
      500,
      500,
      500,
      [[await validator.getAddress(), 200]]
    );
  const tokenBal = await piNftMethods.viewBalance(
    validatedNFT.getAddress(),
    2,
    sampleERC20.getAddress()
  );
  expect(tokenBal).to.equal(500);
  const validatorBal = await sampleERC20.balanceOf(
    await validator.getAddress()
  );
  expect(validatorBal).to.equal(500);
  let commission = await piNftMethods.validatorCommissions(
    validatedNFT.getAddress(),
    2
  );
  expect(commission.isValid).to.equal(true);
  expect(commission.commission.account).to.equal(
    await validator.getAddress()
  );
  expect(commission.commission.value).to.equal(500);
});

it("should let validator transfer NFT to alice again", async () => {
  await validatedNFT
    .connect(validator)
    .safeTransferFrom(validator.getAddress(), alice.getAddress(), 2);
  expect(await validatedNFT.ownerOf(2)).to.equal(await alice.getAddress());
});

it("should Burn piNft", async () => {
  const validatorBal1 = await sampleERC20.balanceOf(
    await validator.getAddress()
  );

  expect(validatorBal1).to.equal(500);

  const aliceBal1 = await sampleERC20.balanceOf(
    await alice.getAddress()
  );

  expect(aliceBal1).to.equal(100000000000);


  await validatedNFT.connect(alice).approve(piNftMethods.getAddress(), 2);
  await piNftMethods.connect(alice).redeemOrBurnPiNFT(
    validatedNFT.getAddress(),
    2,
    "0x0000000000000000000000000000000000000000",
    alice.getAddress(),
    sampleERC20.getAddress(),
    true
  );

  const balance = await sampleERC20.balanceOf(validator.getAddress());
  // console.log("Validator", balance);

  const aliceBal2 = await sampleERC20.balanceOf(
    await alice.getAddress()
  );

  expect(aliceBal2).to.equal(100000000500);

  expect(balance).to.equal(500);
  expect(await validatedNFT.ownerOf(2)).to.equal(await validator.getAddress());
  expect(await piNftMethods.NFTowner(validatedNFT.getAddress(), 2)).to.equal(
    "0x0000000000000000000000000000000000000000"
  );
  expect(
    await piNftMethods.approvedValidator(validatedNFT.getAddress(), 2)
  ).to.equal("0x0000000000000000000000000000000000000000");
  let commission = await piNftMethods.validatorCommissions(
    validatedNFT.getAddress(),
    2
  );
  expect(commission.isValid).to.equal(false);
  expect(commission.commission.account).to.equal(
    "0x0000000000000000000000000000000000000000"
  );
  expect(commission.commission.value).to.equal(0);
});

it("should let validator add ERC20 tokens to his tokenId one", async () => {

  const tx = await validatedNFT.mintValidatedNFT(validator, "URI1");
    const owner = await validatedNFT.ownerOf(3);
    // console.log("ss",owner.toString());
      // const bal = await validatedNFT.balanceOf(alice);
      // expect(bal).to.equal(1);

      expect(
      await piNftMethods.approvedValidator(validatedNFT.getAddress(), 3)
    ).to.equal(await validator.getAddress());

  await sampleERC20.mint(validator.getAddress(), 500);
  const validatorBal1 = await sampleERC20.balanceOf(
    await validator.getAddress()
  );
  await sampleERC20
    .connect(validator)
    .approve(piNftMethods.getAddress(), 500);
    let exp = new BN(await time.latest()).add(new BN(3600));
  await piNftMethods
    .connect(validator)
    .addERC20(
      await validatedNFT.getAddress(),
      3,
      sampleERC20.getAddress(),
      500,
      1000,
      500,
      [[await validator.getAddress(), 200]]
    );
  const tokenBal = await piNftMethods.viewBalance(
    validatedNFT.getAddress(),
    3,
    sampleERC20.getAddress()
  );
  expect(tokenBal).to.equal(500);
  const validatorBal = await sampleERC20.balanceOf(
    await validator.getAddress()
  );
  expect(validatorBal).to.equal(500);
  let commission = await piNftMethods.validatorCommissions(
    validatedNFT.getAddress(),
    3
  );
  expect(commission.isValid).to.equal(true);
  expect(commission.commission.account).to.equal(
    await validator.getAddress()
  );
  expect(commission.commission.value).to.equal(1000);

  await validatedNFT
    .connect(validator)
    .safeTransferFrom(validator.getAddress(), alice.getAddress(), 3);
  expect(await validatedNFT.ownerOf(3)).to.equal(await alice.getAddress());

});

it("should let validator place piNFT on sale", async () => {
  await validatedNFT.approve(piMarket.getAddress(), 3);
  const result = await piMarket.sellNFT(
    validatedNFT.getAddress(),
    3,
    50000,
    "0x0000000000000000000000000000000000000000"
  );
  expect(await validatedNFT.ownerOf(3)).to.equal(await piMarket.getAddress());
});

it("should edit the price after listing on sale", async () => {
  await piMarket.connect(alice).editSalePrice(1, 60000);
  await expect(
    piMarket.connect(bob).editSalePrice(1, 60000)
  ).to.be.revertedWith("You are not the owner");

  await expect(
    piMarket.connect(alice).editSalePrice(1, 60)
  ).to.be.revertedWithoutReason();
  let meta = await piMarket._tokenMeta(1);
  let price = meta.price;
  expect(price).to.equal(60000);
  await piMarket.connect(alice).editSalePrice(1, 60000);
  await piMarket.connect(alice).editSalePrice(1, 50000);
  let newmeta = await piMarket._tokenMeta(1);
  expect(newmeta.price).to.equal(50000);
});

it("should not let seller buy their own nft", async () => {
  await expect(
    piMarket.connect(alice).BuyNFT(1, false, { value: 50000 })
  ).to.be.revertedWithoutReason();
});

it("should not let bidder place bid on direct sale NFT", async () => {
  await expect(piMarket.connect(bob).Bid(1, 50000, {value: 50000})).to.be.revertedWithoutReason()
})

it("should let bob buy piNFT", async () => {
  let meta = await piMarket._tokenMeta(1);
  expect(meta.status).to.equal(true);

  const _balance1 = await ethers.provider.getBalance(alice.getAddress());

  result2 = await piMarket.connect(bob).BuyNFT(1, false, { value: 50000 });
  expect(await validatedNFT.ownerOf(3)).to.equal(await bob.getAddress());

  let newMeta = await piMarket._tokenMeta(1);
  expect(newMeta.status).to.equal(false);

  let commission = await piNftMethods.validatorCommissions(
    validatedNFT.getAddress(),
    3
  );
  expect(commission.isValid).to.equal(false);
  expect(commission.commission.account).to.equal(
    await validator.getAddress()
  );
  expect(commission.commission.value).to.equal(1000);
});

it("should not Delete an ERC721 token if the caller isn't the owner", async () => {
  await expect(
    validatedNFT.connect(bob).deleteNFT(0)
  ).to.be.revertedWithoutReason();
});

it("should not allow delete if contract is paused", async () => {
  await validatedNFT.pause();

  await expect(
    validatedNFT.deleteNFT(0)
  ).to.be.revertedWith("Pausable: paused");

  await validatedNFT.unpause();
});

it("should Delete an ERC721 token to alice", async () => {
  const bal = await validatedNFT.balanceOf(alice);
  expect(bal).to.equal(2);
  await validatedNFT.deleteNFT(0);
  const bal1 = await validatedNFT.balanceOf(alice);
  expect(bal1).to.equal(1);
});




  })
});
