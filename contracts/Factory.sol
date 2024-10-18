// SPDX-License-Identifier: MIT
pragma solidity 0.8.27;

// import Strings library from openzeppelin
import "@openzeppelin/contracts/utils/Strings.sol";
import "./Token.sol";

contract Factory {
    enum Provider {
        GITHUB,
        TWITTER,
        YOUTUBE,
        INSTAGRAM
    }
    address[] public deployedContracts;
    uint256 public count = 0;
    struct Account {
        string profile;
        Provider provider;
    }
    mapping(uint256 => address) public deployedContract;
    mapping(address => Account) public deployedAccounts;

    // Create a mapping from Provider to profile to bool to check if a contract for this was deployed
    mapping(Provider => mapping(string => bool)) public deployedProfiles;

    struct DeployedContract {
        address contractAddress;
        string profile;
        Provider provider;
        uint256 id;
    }

    function createContract(Provider provider, string memory profile) public {
        // Check if a contract for this profile was already deployed
        require(
            !deployedProfiles[provider][profile],
            "Contract for this profile already deployed"
        );
        string memory ticker = string(
            abi.encodePacked("2B", Strings.toString(count))
        );
        address tokens = address(
            new Token("2Based", ticker, provider, profile)
        );
        deployedAccounts[tokens] = Account(profile, provider);
        deployedContracts.push(tokens);
        count++;
    }

    function getDeployedContracts()
        public
        view
        returns (DeployedContract[] memory)
    {
        DeployedContract[] memory contracts = new DeployedContract[](
            deployedContracts.length
        );
        for (uint256 i = 0; i < deployedContracts.length; i++) {
            address contractAddress = deployedContracts[i];
            Account memory account = deployedAccounts[contractAddress];
            contracts[i] = DeployedContract(
                contractAddress,
                account.profile,
                account.provider,
                i
            );
        }
        return contracts;
    }

    function isCreated(
        Provider provider,
        string memory profile
    ) public view returns (bool) {
        return deployedProfiles[provider][profile];
    }
}
