pragma solidity 0.8.11;

// SPDX-License-Identifier: MIT

interface IAttestationRegistry {

    /**
     * @title A struct representing a record for a submitted AS (Attestation Schema).
     */
    struct ASRecord {
        // A unique identifier of the Attestation Registry.
        bytes32 uuid;
        // Auto-incrementing index for reference, assigned by the registry itself.
        uint256 index;
        // Custom specification of the Attestation Registry (e.g., an ABI).
        bytes schema;
    }

    /**
     * @dev Submits and reserve a new AS
     *
     * @param schema The AS data schema.
     *
     * @return The UUID of the new AS.
     */
    function register(bytes calldata schema) external returns (bytes32);

     /**
     * @dev Returns an existing AS by UUID
     *
     * @param uuid The UUID of the AS to retrieve.
     *
     * @return The AS data members.
     */
    function getAS(bytes32 uuid) external view returns (ASRecord memory);
}
