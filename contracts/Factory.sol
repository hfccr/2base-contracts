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

    function createContract(Provider provider, string memory profile) public {
        string memory ticker = string(
            abi.encodePacked("BS", Strings.toString(count))
        );
        address tokens = address(
            new Token("2Based", ticker, provider, profile)
        );
        deployedContracts.push(tokens);
        count++;
    }

    function getDeployedContracts() public view returns (address[] memory) {
        return deployedContracts;
    }
}
