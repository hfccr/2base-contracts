import "@nomicfoundation/hardhat-toolbox-viem";
import type { HardhatUserConfig } from "hardhat/config";

const config: HardhatUserConfig = {
  solidity: "0.8.27",
  networks: {
    baseSepolia: {
      url: "https://base-sepolia.blastapi.io/5f00f6d9-6bd9-493e-a62d-8586ada7f665",
    },
  },
};

export default config;
