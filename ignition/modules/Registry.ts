// This setup uses Hardhat Ignition to manage smart contract deployments.
// Learn more about it at https://hardhat.org/ignition

import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

const RegistryModule = buildModule("RegistryModule", (m) => {
  const registry = m.contract("Registry", [], {});

  return { registry };
});

export default RegistryModule;
