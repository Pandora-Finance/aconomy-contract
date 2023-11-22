// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;
import "forge-std/console.sol";
import "forge-std/Test.sol";
import "forge-std/console.sol";
import "contracts/interfaces/IAttestationServices.sol";
import "contracts/interfaces/IAttestationRegistry.sol";
import "contracts/AttestationRegistry.sol";
import "contracts/AttestationServices.sol";
contract AttestationServicesTest is Test {
    AttestationRegistry registry;
    AttestationServices services;
    AttestationRegistry zeroAddRegistry;

    address payable alice = payable(address(0xABCD));
    address payable deployer = payable(address(0xABEE));
    address payable bob = payable(address(0xABCC));

    bytes32 schemaUUID1;
    bytes32 attestationUUID;
    bytes32 schemaUUID;

    function setUp() public {
        registry = new AttestationRegistry();
        services = new AttestationServices(registry);
    }
    function testShouldDeployTheContracts() view public {
        // should deploy the contracts 
        assert(address(services) != address(0));
        assert(address(registry) != address(0));
    }
    function testShouldFailToDeployServicesIfRegistryAddressIsZero() public {
        // should fail to deploy services if registry address is 0 
        testShouldDeployTheContracts();
        // registry1 = address(0);
        vm.expectRevert("InvalidRegistry");
        new AttestationServices(zeroAddRegistry);
    }
    function testShouldRegisterASchema() public {
        // should register a schema 
        testShouldFailToDeployServicesIfRegistryAddressIsZero();
        bytes32 x = keccak256(abi.encodePacked("(uint256 poolId, address lenderAddress)"));
        bytes32 x1 = keccak256(abi.encodePacked("(uint256 poolId, address borrowerAddress)"));
        schemaUUID = registry.register("(uint256 poolId, address lenderAddress)");
        bytes32 newSchemaUUID = registry.register("(uint256 poolId, address borrowerAddress)");
        IAttestationRegistry.ASRecord memory lenderUUID = registry.getAS(schemaUUID);
        IAttestationRegistry.ASRecord memory borrowerUUID = registry.getAS(newSchemaUUID);
        assertEq(schemaUUID,lenderUUID.uuid);
        assertEq(newSchemaUUID,borrowerUUID.uuid);
        assertEq("(uint256 poolId, address borrowerAddress)" ,borrowerUUID.schema);
        assertEq("(uint256 poolId, address lenderAddress)" ,lenderUUID.schema);
        assertEq(1,lenderUUID.index);
        assertEq(2,borrowerUUID.index);
        assertEq(x,schemaUUID);
        assertEq(x1,newSchemaUUID);
        
    }
    function testShouldNotRegisterAnAlreadyRegisteredSchema_For_lender() public {
        // should not register an already registered schema 
        testShouldRegisterASchema();
        vm.expectRevert("AlreadyExists");
        registry.register("(uint256 poolId, address lenderAddress)");
    }
    function testShouldNotRegisterAnAlreadyRegisteredSchema_For_Borrower() public {
                // should not register an already registered schema 
        testShouldNotRegisterAnAlreadyRegisteredSchema_For_lender();
        vm.expectRevert("AlreadyExists");
        registry.register("(uint256 poolId, address borrowerAddress)");
    }
    function testShouldAttestAnAddress() public {
        // should attest an address 
        testShouldNotRegisterAnAlreadyRegisteredSchema_For_Borrower();
        schemaUUID1 = registry.register("0x2875696e7432353620706f6f6c49642c2061646472657373206c656e64657241");
        attestationUUID = services.attest(alice, schemaUUID1, "0x0000000000000000000000000000000000000000");
        assertTrue(services.isAddressActive(attestationUUID));
        assertTrue(services.isAddressValid(attestationUUID));
    }
    function test_InvalidUUID() public {
    // should return if a faulty uuid is invalid
    testShouldAttestAnAddress();
    bool isValid = services.isAddressValid(schemaUUID1);
    assertFalse(isValid, "Faulty UUID should be invalid");
    }
    function test_inactive() public {
    // should return if a faulty uuid is inactive 
    test_InvalidUUID();
    bool isActive = services.isAddressActive(schemaUUID1);
    assertFalse(isActive, "Faulty UUID should be inactive");
}

function test_AttestInvalidSchema() public {
    // should not attest an invalid schema
    test_inactive();
        vm.expectRevert("InvalidSchema");
        services.attest(
            alice,
            0x2875696e7432353620706f6f6c49642c2061646472657373206c656e64657241,
            "address(0)"
        );
       
}

function test_NonAttesterRevoke() public {
    // should not allow a non attester to revoke
    test_AttestInvalidSchema();
    vm.startPrank(alice);
    assertTrue(services.isAddressActive(attestationUUID));
        vm.expectRevert("Access denied");
        services.revoke(attestationUUID);
        vm.stopPrank();
        
}

function test_RevokeNonExistentUUID() public {
    // should not allow revoking a non existent attestation uuid
    test_NonAttesterRevoke();
        vm.expectRevert("Not found");
        services.revoke(
                schemaUUID1);
       
}

function test_RevokeExistingAttestation() public {
    // should revoke an existing attestation
    test_RevokeNonExistentUUID();
    services.revoke(attestationUUID);
    bool isActive = services.isAddressActive(attestationUUID);
    assertFalse(isActive, "Existing attestation should be revoked");
}

function test_RevokeAlreadyRevokedAttestation() public {
    // should not allow revoking an already revoked attestation
    test_RevokeExistingAttestation();
        vm.expectRevert("Already Revoked");
        services.revoke(attestationUUID);
        
}

}