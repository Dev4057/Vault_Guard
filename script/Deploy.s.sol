// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/VaultGuard.sol";

contract DeployVaultGuard is Script {
    function run() external {
        // Load environment variables
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        // Load signer addresses from environment
        address[] memory signers = new address[](5);
        signers[0] = vm.envAddress("SIGNER_1");
        signers[1] = vm.envAddress("SIGNER_2");
        signers[2] = vm.envAddress("SIGNER_3");
        signers[3] = vm.envAddress("SIGNER_4");
        signers[4] = vm.envAddress("SIGNER_5");
        
        uint256 approvalThreshold = vm.envUint("APPROVAL_THRESHOLD");

        vm.startBroadcast(deployerPrivateKey);

        // Deploy VaultGuard
        VaultGuard vault = new VaultGuard(signers, approvalThreshold);

        console.log("VaultGuard deployed to:", address(vault));
        console.log("Approval Threshold:", approvalThreshold);
        console.log("Number of Signers:", signers.length);
        
        for (uint256 i = 0; i < signers.length; i++) {
            console.log("Signer", i + 1, ":", signers[i]);
        }

        vm.stopBroadcast();
    }
}

contract DeployVaultGuardTestnet is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        vm.startBroadcast(deployerPrivateKey);

        // For testnet, use test signers
        address[] memory signers = new address[](5);
        signers[0] = 0x70997970C51812dc3A010C7d01b50e0d17dc79C8; // Hardhat account 1
        signers[1] = 0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC; // Hardhat account 2
        signers[2] = 0x90F79bf6EB2c4f870365E785982E1f101E93b906; // Hardhat account 3
        signers[3] = 0x15d34AAf54267DB7D7c367839AAf71A00a2C6A65; // Hardhat account 4
        signers[4] = 0x9965507D1a55bcC2695C58ba16FB37d819B0A4dc; // Hardhat account 5
        
        uint256 approvalThreshold = 3;

        VaultGuard vault = new VaultGuard(signers, approvalThreshold);

        console.log("=== VaultGuard Testnet Deployment ===");
        console.log("Contract Address:", address(vault));
        console.log("Approval Threshold:", approvalThreshold);
        console.log("Time Lock Period: 2 days");
        console.log("Voting Period: 7 days");
        console.log("Execution Window: 3 days");
        console.log("");
        console.log("Signers:");
        for (uint256 i = 0; i < signers.length; i++) {
            console.log("  ", i + 1, ":", signers[i]);
        }

        vm.stopBroadcast();
    }
}