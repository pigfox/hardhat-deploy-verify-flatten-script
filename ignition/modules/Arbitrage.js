const { buildModule } = require("@nomicfoundation/hardhat-ignition/modules");

module.exports = buildModule("LockModule", (m) => {
  const arbitrage = m.contract("Arbitrage", [], {
  });

  return { arbitrage };
});
