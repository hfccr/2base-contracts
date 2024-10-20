// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./Factory.sol";
import "hardhat/console.sol";
import "./Reclaim.sol";

contract Token is ERC20, Ownable {
    // Define a structure for a price step
    struct BondStep {
        uint256 rangeTo; // The upper limit of the supply range
        uint256 price; // The price per token for this range
    }
    struct Cost {
        uint256 cost;
        uint256 fee;
        uint256 totalCost;
    }

    Reclaim public reclaimContract =
        Reclaim(0xF90085f5Fd1a3bEb8678623409b3811eCeC5f6A5);

    // Array of bonding steps
    BondStep[] public bondSteps;

    // Total supply of tokens (tracked for bonding curve logic)
    uint256 public totalSupplyTokens;

    // Maximum supply of tokens
    uint256 public maxSupply = 1000000;

    // Fee percentages (in basis points, e.g., 100 = 1%)
    uint256 public buyFee = 1000; // Fee for buying tokens
    uint256 public sellFee = 1000; // Fee for selling tokens
    uint256 public feeBalance = 0;

    Factory.Provider public provider;
    string public profile;
    Factory factory;
    uint256 public tokenId;
    address public tokenOwner;
    bool public claimed;

    constructor(
        address _factoryAddress,
        uint256 _tokenId,
        string memory _name,
        string memory _ticker,
        Factory.Provider _provider,
        string memory _profile
    ) ERC20(_name, _ticker) {
        tokenId = _tokenId;
        factory = Factory(_factoryAddress);
        provider = _provider;
        profile = _profile;
        bondSteps.push(BondStep(300, 0.00001 ether)); // 0-300 tokens at 0.00001 Ether each
        bondSteps.push(BondStep(600, 0.0001 ether)); // 301-600 tokens at 0.0001 Ether each
        bondSteps.push(BondStep(1000, 0.001 ether)); // 601-1000 tokens at 0.001 Ether each
        bondSteps.push(BondStep(10000, 0.01 ether)); // 1001-10000 tokens at 0.01 Ether each
        bondSteps.push(BondStep(100000, 0.1 ether)); // 10001-100000 tokens at 0.1 Ether each
        bondSteps.push(BondStep(1000000, 1 ether)); // 100001-1000000 tokens at 1 Ether each
    }

    // Function to buy tokens based on the current total supply
    function buyTokens(uint256 _amount) external payable {
        require(_amount > 0, "Amount must be greater than zero");
        require(
            totalSupplyTokens + _amount <= maxSupply,
            "Exceeds maximum supply"
        );

        Cost memory cost = calculateCost(_amount);
        // uint256 fee = (cost * buyFee) / 10000; // Calculate buy fee
        // uint256 totalCost = cost + fee; // Total cost including fee

        require(msg.value >= cost.totalCost, "Insufficient funds sent");
        feeBalance += cost.fee; // Add fee to the fee balance
        totalSupplyTokens += _amount;
        _mint(msg.sender, _amount); // Mint new tokens to the buyer
        factory.onFeeCollected(tokenId, cost.fee);
        factory.onTokensChange(tokenId, totalSupplyTokens);
    }

    // Function to sell tokens back to the contract
    function sellTokens(uint256 _amount) external {
        require(
            _amount > 0 && balanceOf(msg.sender) >= _amount,
            "Invalid amount"
        );
        Cost memory cost = calculateRevenue(_amount);
        totalSupplyTokens -= _amount;
        payable(msg.sender).transfer(cost.cost); // Send revenue after deducting fee
        feeBalance += cost.fee; // Add fee to the fee balance

        // Transfer the fee to the owner's address
        factory.onFeeCollected(tokenId, cost.fee);
        factory.onTokensChange(tokenId, totalSupplyTokens);
    }

    // Function to calculate the cost of buying tokens based on current supply
    function calculateCost(uint256 _amount) public view returns (Cost memory) {
        uint256 cost = 0;
        uint256 currentSupply = totalSupplyTokens;
        for (uint256 i = 0; i < bondSteps.length; i++) {
            if (currentSupply < bondSteps[i].rangeTo) {
                uint256 remainingInRange = bondSteps[i].rangeTo - currentSupply;
                if (_amount <= remainingInRange) {
                    cost += _amount * bondSteps[i].price;
                    break;
                } else {
                    cost += remainingInRange * bondSteps[i].price;
                    _amount -= remainingInRange;
                    currentSupply += remainingInRange;
                }
            }
            currentSupply = bondSteps[i].rangeTo; // Move to the next range
        }
        uint256 fee = (cost * buyFee) / 10000; // Calculate buy fee
        uint256 totalCost = cost + fee; // Total cost including fee
        return Cost(cost, fee, totalCost);
    }

    // Function to calculate the revenue from selling tokens based on current supply
    function calculateRevenue(
        uint256 _amount
    ) public view returns (Cost memory) {
        require(
            _amount <= totalSupplyTokens,
            "Amount to sell is more than totalSupply"
        );
        uint256 revenue = 0;
        uint256 totalRemainingSupply = totalSupplyTokens;
        uint256 i = bondSteps.length;
        while (i > 0 && totalRemainingSupply < bondSteps[i - 1].rangeTo) {
            i--;
        }
        i++;

        for (i; i > 0; i--) {
            uint256 remainingInRange = totalRemainingSupply -
                (i > 1 ? bondSteps[i - 2].rangeTo : 0);
            if (_amount <= remainingInRange) {
                revenue += (_amount * bondSteps[i - 1].price);
                break;
            } else {
                revenue += (remainingInRange * bondSteps[i - 1].price);
                _amount -= remainingInRange;
            }
            totalRemainingSupply -= remainingInRange; // Move to the previous range
        }
        uint256 fee = (revenue * sellFee) / 10000; // Calculate sell fee
        uint256 totalRevenue = revenue - fee; // Total revenue after fee
        return Cost(revenue, fee, totalRevenue);
    }

    function claimTokenAccount(Reclaim.Proof memory proof) external {
        require(tokenOwner == address(0x0), "Profile already claimed");

        string memory username = extractValue(
            proof.claimInfo.context,
            "username"
        );

        bool isDataAndProofValid = isMatch(username, profile);
        require(isDataAndProofValid, "Data doesn't match with proof");
        reclaimContract.verifyProof(proof);
        tokenOwner = msg.sender;
        factory.onClaimed(tokenId, tokenOwner);
        claimed = true;
    }

    function claimWithoutProof() external {
        require(tokenOwner == address(0x0), "Profile already claimed");
        tokenOwner = msg.sender;
        factory.onClaimed(tokenId, tokenOwner);
        claimed = true;
    }

    function isMatch(
        string memory data,
        string memory target
    ) private pure returns (bool) {
        bytes memory dataBytes = bytes(data);
        bytes memory targetBytes = bytes(target);
        if (dataBytes.length != targetBytes.length) {
            return false;
        }
        uint256 i = 0;
        for (uint256 j = 0; j < targetBytes.length; j++) {
            if (dataBytes[i] != targetBytes[j]) {
                return false;
            }
            ++i;
        }
        return true;
    }

    function extractValue(
        string memory json,
        string memory key
    ) private pure returns (string memory) {
        bytes memory jsonBytes = bytes(json);
        // Construct the search pattern for the key
        bytes memory searchPattern = abi.encodePacked('"', key, '":"');
        // Search for the key in the JSON string
        for (uint256 i = 0; i <= jsonBytes.length - searchPattern.length; i++) {
            bool foundKey = true;
            // Check if the substring matches the search pattern
            for (uint256 j = 0; j < searchPattern.length; j++) {
                if (jsonBytes[i + j] != searchPattern[j]) {
                    foundKey = false;
                    break;
                }
            }
            if (foundKey) {
                // Key found, now extract the value
                uint256 startIndex = i + searchPattern.length;
                uint256 endIndex = startIndex;
                // Find the end of the value
                while (
                    endIndex < jsonBytes.length && jsonBytes[endIndex] != '"'
                ) {
                    endIndex++;
                }
                // Extract and return the value
                return string(substring(jsonBytes, startIndex, endIndex));
            }
        }
        revert("Key not found");
    }

    function substring(
        bytes memory str,
        uint256 startIndex,
        uint256 endIndex
    ) private pure returns (bytes memory) {
        require(
            startIndex < endIndex && endIndex <= str.length,
            "Invalid substring indices"
        );
        bytes memory result = new bytes(endIndex - startIndex);
        for (uint256 i = startIndex; i < endIndex; i++) {
            result[i - startIndex] = str[i];
        }
        return result;
    }

    function withdraw() external {
        require(
            msg.sender == tokenOwner,
            "Only token profile owner can withdraw"
        );
        payable(tokenOwner).transfer(feeBalance);
        feeBalance = 0;
    }
}
