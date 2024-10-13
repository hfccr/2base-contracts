// SPDX-License-Identifier: MIT
pragma solidity 0.8.27;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./Reclaim.sol";

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
    struct ProfileDetails {
        string id;
        Provider provider;
        uint256 balance;
        uint256 claimed;
    }

    struct InviteeDetails {
        address invitee;
        uint256 totalInvites;
        uint256 claimedInvites;
    }

    struct ProfileInviteDetails {
        string id;
        Provider provider;
        uint256 inviteCount;
        uint256 claimCount;
    }

    address public reclaimAddress = 0xF90085f5Fd1a3bEb8678623409b3811eCeC5f6A5;

    uint256 public totalProfilesCount = 0;

    // create a registry of provider to profile(string) to pending balance mapping
    mapping(Provider => mapping(string => uint256)) public registry;

    // create a registry of provider to profile(string) created boolean
    mapping(Provider => mapping(string => bool)) public claimed;

    mapping(Provider => mapping(string => address)) public claimedAddress;
    mapping(address claimerAddress => Profile) public claimedProfiles;

    // track the profiles invited by an address
    mapping(address inviteSender => Profile[]) public invitedProfiles;

    // track invites count by address
    mapping(address inviteSender => uint256) public inviteCounts;

    // track successful/claimed invite counts by address
    mapping(address inviteSender => uint256) public claimedInviteCountsOfSender;

    mapping(Provider => mapping(string id => uint256))
        public claimedInvitesByProfileCounts;

    // track all the inviters for a specific provider
    mapping(Provider => mapping(string id => address[])) public inviters;

    mapping(address => mapping(Provider => string id)) public userProfiles;

    // array to track addresses that send invites
    address[] public inviteSenders;

    Profile[] public allProfiles;

    // helper mapping to check if address is already added to inviteSenders
    mapping(address => bool) public hasSentInvite;

    // mapping for invite reward
    mapping(address => uint256) public points;

    constructor(address _reclaimAddress) {
        reclaimAddress = _reclaimAddress;
    }

    // New function added by Ayush to calculate points
    function updatePoints() public {
        uint256 inviteCount = invitedProfiles[msg.sender].length;

        // Reset points for the sender
        points[msg.sender] = 0;

        for (uint256 i = 0; i < inviteCount; i++) {
            Profile memory profile = invitedProfiles[msg.sender][i];

            // Add 200 points for each invited profile
            points[msg.sender] += 200;

            // Add 500 points if the reward for this profile has been claimed
            if (claimed[profile.provider][profile.id]) {
                points[msg.sender] += 500;
            }
        }
    }

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
        // For now, fix the amount to simplify the app
        require(msg.value == 0.0001 ether, "Invalid amount");
        // require profile not already claimed
        require(
            claimed[profile.provider][profile.id] == false,
            "Profile already claimed"
        );

        // add balance to registry
        registry[profile.provider][profile.id] += msg.value;
        claimed[profile.provider][profile.id] = false;

        inviters[profile.provider][profile.id].push(msg.sender);
        // add invited profile to the sender's list
        invitedProfiles[msg.sender].push(profile);

        // increment the invite count for the sender
        inviteCounts[msg.sender]++;

        // add the address to inviteSenders if it's not already there
        if (!hasSentInvite[msg.sender]) {
            inviteSenders.push(msg.sender);
            hasSentInvite[msg.sender] = true;
        }

        if (inviters[profile.provider][profile.id].length == 1) {
            totalProfilesCount++;
            allProfiles.push(profile);
        }
    }

    // write a function to claim a profile
    function claim(Profile memory profile) public {
        require(
            claimed[profile.provider][profile.id] == false,
            "Profile already claimed"
        );

        // transfer balance to the caller
        uint256 balance = registry[profile.provider][profile.id];
        require(balance > 0, "No balance to claim");

        payable(msg.sender).transfer(balance);

        // reset the registry and mark as claimed
        registry[profile.provider][profile.id] = 0;
        claimed[profile.provider][profile.id] = true;

        uint256 invitersCount = inviters[profile.provider][profile.id].length;
        address[] memory profileInviters = inviters[profile.provider][
            profile.id
        ];

        // increment successful/claimed invite count for the sender
        for (uint256 i = 0; i < invitersCount; i++) {
            claimedInviteCountsOfSender[profileInviters[i]]++;
        }
        claimedInvitesByProfileCounts[profile.provider][profile.id]++;
    }

    function claimWithProof(
        Reclaim.Proof memory proof,
        Profile memory profile
    ) public {
        require(
            claimed[profile.provider][profile.id] == false,
            "Profile already claimed"
        );

        bool isVerified = Reclaim(reclaimAddress).verifyProof(proof);
        require(isVerified, "Invalid Proof");
        // transfer balance to the caller
        uint256 balance = registry[profile.provider][profile.id];
        require(balance > 0, "No balance to claim");

        payable(msg.sender).transfer(balance);

        // reset the registry and mark as claimed
        registry[profile.provider][profile.id] = 0;
        claimed[profile.provider][profile.id] = true;

        uint256 invitersCount = inviters[profile.provider][profile.id].length;
        address[] memory profileInviters = inviters[profile.provider][
            profile.id
        ];

        // increment successful/claimed invite count for the sender
        for (uint256 i = 0; i < invitersCount; i++) {
            claimedInviteCountsOfSender[profileInviters[i]]++;
        }
        claimedInvitesByProfileCounts[profile.provider][profile.id]++;
    }

    // view all the invited profiles with their inviteCounts and claimed counts
    function getInviters()
        external
        view
        returns (ProfileInviteDetails[] memory)
    {
        ProfileInviteDetails[]
            memory profileDetails = new ProfileInviteDetails[](
                totalProfilesCount
            );

        // Iterate through each invite sender and collect profiles' invite and claim counts
        for (uint256 i = 0; i < totalProfilesCount; i++) {
            // Populate the ProfileInviteDetails for each profile
            Profile memory profile = allProfiles[i];
            profileDetails[i] = ProfileInviteDetails({
                id: profile.id,
                provider: profile.provider,
                inviteCount: inviters[profile.provider][profile.id].length,
                claimCount: claimedInvitesByProfileCounts[profile.provider][
                    profile.id
                ]
            });
        }

        return profileDetails;
    }

    // write a function to return the balance and invite count for a profile
    function getProfileBalanceAndInviteCount(
        Profile memory profile
    )
        public
        view
        returns (uint256 balance, uint256 inviteCount, bool profileClaimed)
    {
        balance = registry[profile.provider][profile.id];
        profileClaimed = claimed[profile.provider][profile.id];
        inviteCount = inviters[profile.provider][profile.id].length;
    }

    // write a function to return the profiles that have been invited
    function getInvitedProfiles() public view returns (Profile[] memory) {
        return invitedProfiles[msg.sender];
    }

    // write a function to return the addresses that have sent invites with their invite count
    function getAddressesWithInviteCounts()
        public
        view
        returns (address[] memory, uint256[] memory)
    {
        uint256 totalAddresses = inviteSenders.length;

        address[] memory addressesWithInvites = new address[](totalAddresses);
        uint256[] memory counts = new uint256[](totalAddresses);

        for (uint256 i = 0; i < totalAddresses; i++) {
            address sender = inviteSenders[i];
            addressesWithInvites[i] = sender;
            counts[i] = inviteCounts[sender];
        }

        return (addressesWithInvites, counts);
    }

    // write a function to return addresses with successful/claimed invite counts
    function getAddressesWithClaimedInvites()
        public
        view
        returns (address[] memory, uint256[] memory)
    {
        uint256 totalAddresses = inviteSenders.length;

        address[] memory addressesWithClaims = new address[](totalAddresses);
        uint256[] memory counts = new uint256[](totalAddresses);

        for (uint256 i = 0; i < totalAddresses; i++) {
            address sender = inviteSenders[i];
            addressesWithClaims[i] = sender;
            counts[i] = claimedInviteCountsOfSender[sender];
        }

        return (addressesWithClaims, counts);
    }

    function getInviteAndClaimedCounts()
        external
        view
        returns (InviteeDetails[] memory)
    {
        uint256 totalAddresses = inviteSenders.length;
        InviteeDetails[] memory _inviteeDetails = new InviteeDetails[](
            totalAddresses
        );

        for (uint256 i = 0; i < totalAddresses; i++) {
            address sender = inviteSenders[i];
            _inviteeDetails[i] = InviteeDetails({
                invitee: sender,
                totalInvites: inviteCounts[sender],
                claimedInvites: claimedInviteCountsOfSender[sender]
            });
        }
        return _inviteeDetails;
    }

    // Write a function to reset the entire registry. Money will not be sent back.
    // TODO: check if this function is working properly
    function resetRegistry() public onlyOwner {
        for (uint256 i = 0; i < inviteSenders.length; i++) {
            address sender = inviteSenders[i];
            delete invitedProfiles[sender];
            delete inviteCounts[sender];
            delete claimedInviteCountsOfSender[sender];
            delete hasSentInvite[sender];
        }
        delete inviteSenders;
        // Manually delete entries in the registry mapping
        for (uint256 p = 0; p < 4; p++) {
            Provider provider = Provider(p);
            for (uint256 i = 0; i < inviteSenders.length; i++) {
                address sender = inviteSenders[i];
                Profile[] memory profiles = invitedProfiles[sender];
                for (uint256 j = 0; j < profiles.length; j++) {
                    string memory profileId = profiles[j].id;
                    delete registry[provider][profileId];
                    delete claimed[provider][profileId];
                }
            }
        }
    }
}
