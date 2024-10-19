// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./Factory.sol";

contract Token is ERC20, Ownable {
    // Define a structure for a price step
    struct BondStep {
        uint256 rangeTo; // The upper limit of the supply range
        uint256 price; // The price per token for this range
    }

    // Array of bonding steps
    BondStep[] public bondSteps;

    // Total supply of tokens (tracked for bonding curve logic)
    uint256 public totalSupplyTokens;

    // Maximum supply of tokens
    uint256 public maxSupply = 1000000;

    // Fee percentages (in basis points, e.g., 100 = 1%)
    uint256 public buyFee = 1000; // Fee for buying tokens
    uint256 public sellFee = 1000; // Fee for selling tokens

    // Events for logging purchases and sales
    event TokensPurchased(address indexed buyer, uint256 amount, uint256 cost);
    event TokensSold(address indexed seller, uint256 amount, uint256 revenue);

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

        uint256 cost = calculateCost(_amount);
        uint256 fee = (cost * buyFee) / 10000; // Calculate buy fee
        uint256 totalCost = cost + fee; // Total cost including fee

        require(msg.value >= totalCost, "Insufficient funds sent");

        totalSupplyTokens += _amount;
        _mint(msg.sender, _amount); // Mint new tokens to the buyer

        emit TokensPurchased(msg.sender, _amount, cost);

        // Refund any excess Ether sent
        if (msg.value > totalCost) {
            payable(msg.sender).transfer(msg.value - totalCost);
        }

        factory.onFeeCollected(tokenId, fee);
        factory.onTokensChange(tokenId, totalSupplyTokens);
    }

    // Function to sell tokens back to the contract
    function sellTokens(uint256 _amount) external {
        require(
            _amount > 0 && balanceOf(msg.sender) >= _amount,
            "Invalid amount"
        );

        uint256 revenue = calculateRevenue(_amount);
        uint256 fee = (revenue * sellFee) / 10000; // Calculate sell fee
        uint256 totalRevenue = revenue - fee; // Total revenue after fee

        totalSupplyTokens -= _amount;
        _burn(msg.sender, _amount); // Burn the sold tokens

        emit TokensSold(msg.sender, _amount, revenue);

        payable(msg.sender).transfer(totalRevenue); // Send revenue after deducting fee

        // Transfer the fee to the owner's address
        payable(owner()).transfer(fee);
        factory.onFeeCollected(tokenId, fee);
        factory.onTokensChange(tokenId, totalSupplyTokens);
    }

    // Function to calculate the cost of buying tokens based on current supply
    function calculateCost(uint256 _amount) internal view returns (uint256) {
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

        return cost;
    }

    // Function to calculate the revenue from selling tokens based on current supply
    function calculateRevenue(uint256 _amount) internal view returns (uint256) {
        uint256 revenue = 0;
        uint256 currentSupply = totalSupplyTokens - _amount;

        for (uint256 i = bondSteps.length; i > 0; i--) {
            if (currentSupply < bondSteps[i - 1].rangeTo) {
                uint256 remainingInRange = bondSteps[i - 1].rangeTo -
                    currentSupply;
                if (_amount <= remainingInRange) {
                    revenue += _amount * bondSteps[i - 1].price;
                    break;
                } else {
                    revenue += remainingInRange * bondSteps[i - 1].price;
                    _amount -= remainingInRange;
                    currentSupply += remainingInRange;
                }
            }
            currentSupply = bondSteps[i - 1].rangeTo; // Move to the previous range
        }

        return revenue;
    }

    function claimTokenAcccount() external {
        tokenOwner = msg.sender;
        factory.onClaimed(tokenId, tokenOwner);
        claimed = true;
    }

    function withdraw() external {
        require(
            msg.sender == tokenOwner,
            "Only token profile owner can withdraw"
        );
        payable(tokenOwner).transfer(address(this).balance);
    }
}
