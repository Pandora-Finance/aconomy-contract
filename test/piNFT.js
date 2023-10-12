const {
  time,
  loadFixture,
} = require("@nomicfoundation/hardhat-toolbox/network-helpers");
const { anyValue } = require("@nomicfoundation/hardhat-chai-matchers/withArgs");
const { expect } = require("chai");
const { ethers } = require("hardhat");

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

    return {
      piNFT,
      sampleERC20,
      piNftMethods,
      alice,
      validator,
      bob,
      royaltyReciever,
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

      await expect(
        piNftMethods
          .connect(validator)
          .addERC20(
            await piNFT.getAddress(),
            0,
            sampleERC20.getAddress(),
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
      await sampleERC20.connect(alice).approve(piNftMethods.getAddress(), 500);
      await expect(
        piNftMethods
          .connect(alice)
          .addERC20(
            await piNFT.getAddress(),
            0,
            sampleERC20.getAddress(),
            500,
            500,
            [[await validator.getAddress(), 200]]
          )
      ).to.be.revertedWithoutReason();
    });

    it("should not let validator add funds with 0 royalty address ", async () => {
      await sampleERC20.connect(alice).approve(piNftMethods.getAddress(), 500);
      await expect(
        piNftMethods
          .connect(validator)
          .addERC20(
            await piNFT.getAddress(),
            0,
            sampleERC20.getAddress(),
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
      await expect(
        piNftMethods
          .connect(validator)
          .addERC20(
            await piNFT.getAddress(),
            0,
            sampleERC20.getAddress(),
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
      await expect(
        piNftMethods
          .connect(validator)
          .addERC20(
            await piNFT.getAddress(),
            0,
            sampleERC20.getAddress(),
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
      await expect(
        piNftMethods
          .connect(validator)
          .addERC20(
            await piNFT.getAddress(),
            0,
            "0x0000000000000000000000000000000000000000",
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
      await expect(
        piNftMethods
          .connect(validator)
          .addERC20(
            await piNFT.getAddress(),
            5,
            sampleERC20.getAddress(),
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
      await expect(
        piNftMethods
          .connect(validator)
          .addERC20(
            await piNFT.getAddress(),
            0,
            sampleERC20.getAddress(),
            0,
            500,
            [[await validator.getAddress(), 200]]
          )
      ).to.be.revertedWithoutReason();
    });

    it("should not let validator commission value be 4901", async () => {
      await sampleERC20
        .connect(validator)
        .approve(piNftMethods.getAddress(), 500);
      await expect(
        piNftMethods
          .connect(validator)
          .addERC20(
            await piNFT.getAddress(),
            0,
            sampleERC20.getAddress(),
            500,
            4901,
            [[await validator.getAddress(), 200]]
          )
      ).to.be.revertedWithoutReason();
    });

    it("should pause and unpause piNFTMethods", async () => {
      await piNftMethods.pause();

      await sampleERC20
        .connect(validator)
        .approve(piNftMethods.getAddress(), 500);

      await expect(
        piNftMethods
        .connect(validator)
        .addERC20(
          await piNFT.getAddress(),
          0,
          sampleERC20.getAddress(),
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

      await piNftMethods
        .connect(validator)
        .addERC20(
          await piNFT.getAddress(),
          0,
          sampleERC20.getAddress(),
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
      await piNftMethods
        .connect(validator)
        .addERC20(piNFT.getAddress(), 0, sampleERC20.getAddress(), 200, 300, [
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
      await sampleERC20
        .connect(validator)
        .approve(piNftMethods.getAddress(), 500);
      await expect(
        piNftMethods
          .connect(validator)
          .addERC20(await piNFT.getAddress(), 0, alice.getAddress(), 500, 400, [
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
          .addERC20(piNFT.getAddress(), 0, sampleERC20.getAddress(), 500, 400, [
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
        .addERC20(piNFT.getAddress(), 0, sampleERC20.getAddress(), 500, 400, [
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
      .withArgs(3, await alice.getAddress());

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

      await piNftMethods
        .connect(validator)
        .addERC20(
          await piNFT.getAddress(),
          3,
          sampleERC20.getAddress(),
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
});
