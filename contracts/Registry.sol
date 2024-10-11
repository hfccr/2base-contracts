// SPDX-License-Identifier: MIT
pragma solidity 0.8.27;

import "@openzeppelin/contracts/access/Ownable.sol";

contract Registry is Ownable {
    enum Provider {
        github,
        twitter,
        youtube,
        instagram
    }
    struct Profile {
        string id;
        Provider provider;
    }
    struct ProfieWithBalance {
        string id;
        Provider provider;
        uint256 balance;
        uint256 claimed;
    }
    // create a registry of provider to profile(string) to pending balance mapping
    mapping(Provider => mapping(string => uint256)) public registry;

    // create a registry of provider to profile(string) to profile created boolean
    mapping(Provider => mapping(string => bool)) public claimed;

    // track the profiles invited by an address
    mapping(address => Profile[]) public invitedProfiles;

    // write a function to send 0.0001 eth to a profile
    function invite(Profile memory profile) public payable {
        // check if provider is valid
        require(
            profile.provider == Provider.github ||
                profile.provider == Provider.twitter ||
                profile.provider == Provider.youtube ||
                profile.provider == Provider.instagram,
            "Invalid provider"
        );
        // For now, fix the amout to simplify the app
        require(msg.value == 0.0001 ether, "Invalid amount");
        // require profile not already claimed
        require(
            claimed[profile.provider][profile.id] == false,
            "Profile already claimed"
        );
        registry[profile.provider][profile.id] += msg.value;
        claimed[profile.provider][profile.id] = false;
        // add invited profile to the sender's list
        invitedProfiles[msg.sender].push(profile);
    }

    // write a function to claim a profile
    function claim(Profile memory profile) public {
        require(
            claimed[profile.provider][profile.id] == false,
            "Profile already claimed"
        );
        payable(msg.sender).transfer(registry[profile.provider][profile.id]);
        registry[profile.provider][profile.id] = 0;
        // TODO: integrate reclaim verification
    }

    // view the list of profiles invited by an address along with balance and claimed status
    function viewInvitedProfiles() public view returns (Profile[] memory) {
        return invitedProfiles[msg.sender];
    }
}
