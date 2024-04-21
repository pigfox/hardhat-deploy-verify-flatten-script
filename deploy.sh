#!/bin/bash
network=sepolia
contract=Arbitrage
set -x
set -e
#npx hardhat
npx hardhat compile
npx hardhat test
npx hardhat ignition deploy ./ignition/modules/"$contract".js --network "$network" --verify
npx hardhat flatten ./contracts/"$contract".sol > ./flattened/"$contract"-flattened.sol
#Localhost dev
#npx hardhat node
#npx hardhat ignition deploy ./ignition/modules/Lock.js --network localhost
