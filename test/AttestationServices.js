const {
    time,
    loadFixture,
  } = require("@nomicfoundation/hardhat-toolbox/network-helpers");
  const { anyValue } = require("@nomicfoundation/hardhat-chai-matchers/withArgs");
  const { expect } = require("chai");
  const { ethers } = require("hardhat");
  const moment = require("moment");
  const { BN } = require("@openzeppelin/test-helpers");
  
  describe("Pool Registry", function (){
    let schemaUUID;
    let attestationUUID;

    async function deployContractFactory() {
      [deployer, alice, bob] = await ethers.getSigners();

      registry = await hre.ethers.deployContract("AttestationRegistry", []);
      await registry.waitForDeployment();

      services = await hre.ethers.deployContract("AttestationServices", [registry.getAddress()]);
      await services.waitForDeployment();
  
      return { registry, services, deployer, alice, bob };
    }
  
    describe("Deployment", function () {
        it("should deploy the contracts", async () => {
            let { registry, services, deployer, alice, bob } = await deployContractFactory()
            expect(
                await services.getAddress()).to.not.equal(
                null || undefined
              );
            expect(
                await registry.getAddress()).to.not.equal(
                null || undefined
              );
        })

        it("should register a schema", async () => {
            let tx = await registry.register("0x2875696e7432353620706f6f6c49642c2061646472657373206c656e64657241");
            const trace = await hre.network.provider.send("debug_traceTransaction", [
                tx.hash,
                {
                    disableMemory: true,
                    disableStack: true,
                    disableStorage: true,
                },
            ]);
            //console.log(trace.returnValue)
            schemaUUID = `0x${trace.returnValue}`;
            let res = await registry.getAS(schemaUUID);
            expect(res.schema).to.equal("0x2875696e7432353620706f6f6c49642c2061646472657373206c656e64657241")
        })

        it("should not register an already registered schema", async () => {
            await expect(registry.register("0x2875696e7432353620706f6f6c49642c2061646472657373206c656e64657241")).to.be.revertedWith(
            "AlreadyExists"
            )
        })

        it("should attest an address", async () => {
            let tx = await services.attest(alice, schemaUUID, "0x0000000000000000000000000000000000000000")
            const trace = await hre.network.provider.send("debug_traceTransaction", [
                tx.hash,
                {
                    disableMemory: true,
                    disableStack: true,
                    disableStorage: true,
                },
            ]);
            attestationUUID = `0x${trace.returnValue}`;
            let active = await services.isAddressActive(attestationUUID);
            expect(active).to.equal(true)
            let valid = await services.isAddressValid(attestationUUID);
            expect(valid).to.equal(true)
        })

        it("should return if a faulty uuid is invalid", async () => {
            let valid = await services.isAddressValid(schemaUUID);
            expect(valid).to.equal(false)
        })

        it("should return if a faulty uuid is inactive", async () => {
            let active = await services.isAddressActive(schemaUUID);
            expect(active).to.equal(false)
        })

        it("should not attest an invalid schema", async () => {
            await expect(services.attest(
                alice, 
                "0x2875696e7432353620706f6f6c49642c2061646472657373206c656e64657241", 
                "0x0000000000000000000000000000000000000000")).to.be.revertedWith(
                "InvalidSchema"
                )
        })

        it("should not allow a non attester to revoke", async () => {
            await expect(services.connect(alice).revoke(
                attestationUUID
            )).to.be.revertedWith("Access denied")
        })

        it("should not allow revoking a non existant attestation uuid", async () => {
            await expect(services.revoke(
                schemaUUID)).to.be.revertedWith("Not found")
        })

        it("should revoke an existing attestation", async () => {
            await services.revoke(attestationUUID);
            let active = await services.isAddressActive(attestationUUID)
            expect(active).to.equal(false)
        })

        it("should not allow revoking an already revoked attestation", async () => {
            await expect(services.revoke(
                attestationUUID
            )).to.be.revertedWith("Already Revoked")
        })
      
    })
  })