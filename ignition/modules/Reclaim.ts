// This setup uses Hardhat Ignition to manage smart contract deployments.
// Learn more about it at https://hardhat.org/ignition

import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

const ReclaimModule = buildModule("ReclaimModule", (m) => {
  const reclaim = m.contract("Reclaim", [], {});

  return { reclaim };
});

export default ReclaimModule;
