const AttestationRegistry = artifacts.require("AttestationRegistry");
const AttestationServices = artifacts.require("AttestationServices");
const truffleAssert = require("truffle-assertions");


contract("Attestation Services", (accounts) => {
    describe("services", () => {
        const deployer = accounts[0];
        const alice = accounts[1];
        const bob = accounts[2];
        let registry;
        let services;
        let schemaUUID;
        let attestationUUID;

        it("should deploy the contracts", async () => {
            registry = await AttestationRegistry.deployed();
            services = await AttestationServices.deployed();
        })

        it("should register a schema", async () => {
            let tx = await registry.register("0x2875696e7432353620706f6f6c49642c2061646472657373206c656e64657241");
            console.log(tx.logs[0].args.uuid);
            schemaUUID = tx.logs[0].args.uuid;
            let res = await registry.getAS(schemaUUID);
            assert.equal(res.schema, "0x2875696e7432353620706f6f6c49642c2061646472657373206c656e64657241")
        })

        it("should not register an already registered schema", async () => {
            await truffleAssert.reverts(registry.register("0x2875696e7432353620706f6f6c49642c2061646472657373206c656e64657241"),
            "AlreadyExists"
            )
        })

        it("should attest an address", async () => {
            let tx = await services.attest(alice, schemaUUID, [])
            attestationUUID = tx.logs[0].args.uuid;
            let active = await services.isAddressActive(attestationUUID);
            assert.equal(active, true)
            let valid = await services.isAddressValid(attestationUUID);
            assert.equal(valid, true)
        })

        it("should return if a faulty uuid is invalid", async () => {
            let valid = await services.isAddressValid(schemaUUID);
            assert.equal(valid, false)
        })

        it("should return if a faulty uuid is inactive", async () => {
            let active = await services.isAddressActive(schemaUUID);
            assert.equal(active, false)
        })

        it("should not attest an invalid schema", async () => {
            await truffleAssert.reverts(services.attest(
                alice, 
                "0x2875696e7432353620706f6f6c49642c2061646472657373206c656e64657241", 
                []),
                "InvalidSchema"
                )
        })

        it("should not allow a non attester to revoke", async () => {
            await truffleAssert.reverts(services.revoke(
                attestationUUID,
                {from: alice}
            ), "Access denied")
        })

        it("should not allow revoking a non existant attestation uuid", async () => {
            await truffleAssert.reverts(services.revoke(
                schemaUUID
            ), "Not found")
        })

        it("should revoke an existing attestation", async () => {
            await services.revoke(attestationUUID);
            let active = await services.isAddressActive(attestationUUID)
            assert.equal(active, false)
        })

        it("should not allow revoking an already revoked attestation", async () => {
            await truffleAssert.reverts(services.revoke(
                attestationUUID
            ), "Already Revoked")
        })
    })
})