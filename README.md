# <u>2Base Contracts - Hardhat</u>
This Hardhat project demonstrates the smart contracts behind **2Base**, designed to help onboard Web2 creators into the Base ecosystem. It includes contract testing and deployment using the hardhat framework and deployed contract on the **Base Sepolia** testnet.

### <u>Prerequisites</u>
Make sure to have the following installed:


- **Node.js (v16.x or above)**
- **npm or yarn or pnpm**
- **Hardhat**

### <u>Setup</u>
Clone the repository:
```bash Copy code
git clone https://github.com/yourusername/2base-contracts.git
cd 2base-contracts
```

Install dependencies:
```bash Copy code
npm install
# or
yarn install
```

### <u>Key Commands</u>
Here are steps and Hardhat commands to get going:

Compile contracts:

```bash Copy code
npx hardhat compile
```

Run a local network:

```bash Copy code
npx hardhat node
```

Deploy the factory contract:

```bash Copy code
npx hardhat run scripts/deploy.js --network sepolia
```

Verify contracts (optional):

```bash Copy code
npx hardhat verify --network sepolia
```

Factory gets deployed on `0xe3f967438614f51D12a83db471b052eE928d9518`

<hr />

##### <u>To Interact with **Base Sepolia** Testnet Deployment</u>
**2Base Factory**
`0xF5CD700Cb63696CAb29987AC22fd431eB8A15886`
