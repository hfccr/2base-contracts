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
    // create a registry of provider to profile(string) to balance mapping
    mapping(Provider => mapping(string => uint256)) public registry;
}
