var BigNumber = require('big-number');
var moment = require('moment');
const PoolRegistry = artifacts.require("poolRegistry");
const AttestRegistry = artifacts.require("attestationRegistry")
const AttestServices = artifacts.require("attestationServices");

contract("poolRegistry", async (accounts) => {

    const paymentCycleDuration = moment.duration(30, 'days').asSeconds()
const loanDefaultDuration = moment.duration(180, 'days').asSeconds()
const loanExpirationDuration = moment.duration(1, 'days').asSeconds()


let poolRegistry, attestRegistry, attestServices;


    it("should create attestRegistry, attestationService and link it to poolRegistry", async () => {
        attestRegistry = await AttestRegistry.deployed();
        assert.notEqual(attestRegistry.address, null, "address is zero");
    });



})
