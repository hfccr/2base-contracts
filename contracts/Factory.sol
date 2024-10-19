// SPDX-License-Identifier: MIT
pragma solidity 0.8.27;

// import Strings library from openzeppelin
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

import "./Token.sol";

contract Factory is AccessControl {
    bytes32 public constant TOKEN_ROLE = keccak256("TOKEN_ROLE");

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

    // track inviter for a specific account
    mapping(Provider => mapping(string => address)) public inviters;

    mapping(address => address) public tokenInviter;

    // mapping for invite reward
    mapping(address => uint256) public points;

    // track invites count by address
    mapping(address => uint256) public inviteCounts;

    uint256 public INVITE_FEE = 0.001 ether;
    struct DeployedContract {
        address contractAddress;
        string profile;
        Provider provider;
        uint256 id;
        address inviter;
    }

    function createContract(
        Provider provider,
        string memory profile
    ) public payable {
        // Check if a contract for this profile was already deployed
        // check if provider is valid
        require(
            provider == Provider.GITHUB ||
                provider == Provider.TWITTER ||
                provider == Provider.YOUTUBE ||
                provider == Provider.INSTAGRAM,
            "Invalid provider"
        );
        require(msg.value == INVITE_FEE, "Invalid amount");
        require(
            !deployedProfiles[provider][profile],
            "Contract for this profile already deployed"
        );
        string memory ticker = string(
            abi.encodePacked("2B", Strings.toString(count))
        );
        address tokens = address(
            new Token(address(this), count, "2Based", ticker, provider, profile)
        );
        _grantRole(TOKEN_ROLE, tokens);
        deployedAccounts[tokens] = Account(profile, provider);
        deployedContracts.push(tokens);
        points[msg.sender] += 200;
        inviters[provider][profile] = msg.sender;
        inviteCounts[msg.sender]++;
        tokenInviter[tokens] = msg.sender;
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
                i,
                tokenInviter[contractAddress]
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

    function getPoints(address user) public view returns (uint256) {
        // Reset points for the sender
        return points[user];
    }
}
