// SPDX-License-Identifier: MIT
pragma solidity 0.8.27;

import "./Reclaim.sol";

contract Attestor {
    address public reclaimAddress = 0xF90085f5Fd1a3bEb8678623409b3811eCeC5f6A5;

    // add providersHashes for your permitted providers
    string[] public providersHashes;

    constructor(string[] memory _providersHashes) {
        providersHashes = _providersHashes;
        // TODO: Replace with network you are deploying on
    }

    function verifyProof(
        Reclaim.Proof memory proof,
        string memory profileClaim
    ) public returns (bool) {
        // Reclaim(reclaimAddress).verifyProof(proof);
        // TODO: your business logic upon success
        // verify proof.context is what you expect

        // check the users' github id from the verification matches the profileClaim

        return true;
    }
}
