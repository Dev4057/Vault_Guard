// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/VaultGuard.sol";

/**
 * @title VaultGuard Interaction Examples
 * @notice Example scripts for interacting with deployed VaultGuard
 */

// ============================================================
// EXAMPLE 1: Create a Simple ETH Transfer Proposal
// ============================================================
contract CreateETHProposal is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address vaultAddress = vm.envAddress("VAULT_ADDRESS");
        address recipient = vm.envAddress("RECIPIENT");
        
        vm.startBroadcast(deployerPrivateKey);
        
        VaultGuard vault = VaultGuard(payable(vaultAddress));
        
        uint256 proposalId = vault.createProposal(
            recipient,
            address(0),  // ETH
            1 ether,
            "",
            "Monthly team payment - November 2025"
        );
        
        console.log("Created proposal:", proposalId);
        
        vm.stopBroadcast();
    }
}

// ============================================================
// EXAMPLE 2: Create ERC20 Transfer Proposal
// ============================================================
contract CreateTokenProposal is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address vaultAddress = vm.envAddress("VAULT_ADDRESS");
        address recipient = vm.envAddress("RECIPIENT");
        address tokenAddress = vm.envAddress("TOKEN_ADDRESS");
        
        vm.startBroadcast(deployerPrivateKey);
        
        VaultGuard vault = VaultGuard(payable(vaultAddress));
        
        uint256 amount = 1000 * 10**18; // 1000 tokens (assuming 18 decimals)
        
        uint256 proposalId = vault.createProposal(
            recipient,
            tokenAddress,
            amount,
            "",
            "Grant payment to developer"
        );
        
        console.log("Created token proposal:", proposalId);
        
        vm.stopBroadcast();
    }
}

// ============================================================
// EXAMPLE 3: Approve a Proposal
// ============================================================
contract ApproveProposal is Script {
    function run() external {
        uint256 signerPrivateKey = vm.envUint("PRIVATE_KEY");
        address vaultAddress = vm.envAddress("VAULT_ADDRESS");
        uint256 proposalId = vm.envUint("PROPOSAL_ID");
        
        vm.startBroadcast(signerPrivateKey);
        
        VaultGuard vault = VaultGuard(payable(vaultAddress));
        
        vault.approve(proposalId);
        
        console.log("Approved proposal:", proposalId);
        
        // Get updated approval count
        (,,,,,, uint256 approvalCount,,,,,) = vault.getProposal(proposalId);
        console.log("Current approvals:", approvalCount);
        console.log("Threshold:", vault.approvalThreshold());
        
        vm.stopBroadcast();
    }
}

// ============================================================
// EXAMPLE 4: Execute a Proposal (after timelock)
// ============================================================
contract ExecuteProposal is Script {
    function run() external {
        uint256 executorPrivateKey = vm.envUint("PRIVATE_KEY");
        address vaultAddress = vm.envAddress("VAULT_ADDRESS");
        uint256 proposalId = vm.envUint("PROPOSAL_ID");
        
        vm.startBroadcast(executorPrivateKey);
        
        VaultGuard vault = VaultGuard(payable(vaultAddress));
        
        // Check state
        VaultGuard.ProposalState state = vault.getProposalState(proposalId);
        console.log("Current state:", uint(state));
        
        // Check timelock
        uint256 timeLeft = vault.getTimeLockRemaining(proposalId);
        console.log("Time remaining:", timeLeft);
        
        if (timeLeft > 0) {
            console.log("ERROR: Timelock not expired yet. Wait", timeLeft, "seconds");
            vm.stopBroadcast();
            return;
        }
        
        // Execute
        vault.executeProposal(proposalId);
        
        console.log("Executed proposal:", proposalId);
        
        vm.stopBroadcast();
    }
}

// ============================================================
// EXAMPLE 5: Cancel a Proposal (Admin only)
// ============================================================
contract CancelProposal is Script {
    function run() external {
        uint256 adminPrivateKey = vm.envUint("PRIVATE_KEY");
        address vaultAddress = vm.envAddress("VAULT_ADDRESS");
        uint256 proposalId = vm.envUint("PROPOSAL_ID");
        
        vm.startBroadcast(adminPrivateKey);
        
        VaultGuard vault = VaultGuard(payable(vaultAddress));
        
        vault.cancelProposal(proposalId);
        
        console.log("Cancelled proposal:", proposalId);
        
        vm.stopBroadcast();
    }
}

// ============================================================
// EXAMPLE 6: Query Proposal Details
// ============================================================
contract QueryProposal is Script {
    function run() external view {
        address vaultAddress = vm.envAddress("VAULT_ADDRESS");
        uint256 proposalId = vm.envUint("PROPOSAL_ID");
        
        VaultGuard vault = VaultGuard(payable(vaultAddress));
        
        (
            uint256 id,
            address proposer,
            address recipient,
            address token,
            uint256 amount,
            string memory description,
            uint256 approvalCount,
            uint256 rejectionCount,
            uint256 createdAt,
            uint256 queuedAt,
            uint256 executedAt,
            VaultGuard.ProposalState state
        ) = vault.getProposal(proposalId);
        
        console.log("=== Proposal Details ===");
        console.log("ID:", id);
        console.log("Proposer:", proposer);
        console.log("Recipient:", recipient);
        console.log("Token:", token);
        console.log("Amount:", amount);
        console.log("Description:", description);
        console.log("Approvals:", approvalCount);
        console.log("Rejections:", rejectionCount);
        console.log("Created:", createdAt);
        console.log("Queued:", queuedAt);
        console.log("Executed:", executedAt);
        console.log("State:", uint(state));
        
        uint256 timeLeft = vault.getTimeLockRemaining(proposalId);
        if (timeLeft > 0) {
            console.log("Timelock remaining:", timeLeft, "seconds");
        }
    }
}

// ============================================================
// EXAMPLE 7: Deposit Funds
// ============================================================
contract DepositFunds is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address vaultAddress = vm.envAddress("VAULT_ADDRESS");
        
        vm.startBroadcast(deployerPrivateKey);
        
        // Deposit ETH
        (bool success, ) = payable(vaultAddress).call{value: 10 ether}("");
        require(success, "ETH deposit failed");
        
        console.log("Deposited 10 ETH to vault");
        
        VaultGuard vault = VaultGuard(payable(vaultAddress));
        uint256 balance = vault.getTreasuryBalance(address(0));
        console.log("New ETH balance:", balance);
        
        vm.stopBroadcast();
    }
}

// ============================================================
// EXAMPLE 8: Add New Signer (Admin only)
// ============================================================
contract AddSigner is Script {
    function run() external {
        uint256 adminPrivateKey = vm.envUint("PRIVATE_KEY");
        address vaultAddress = vm.envAddress("VAULT_ADDRESS");
        address newSigner = vm.envAddress("NEW_SIGNER");
        
        vm.startBroadcast(adminPrivateKey);
        
        VaultGuard vault = VaultGuard(payable(vaultAddress));
        
        uint256 oldCount = vault.signerCount();
        
        vault.addSigner(newSigner);
        
        uint256 newCount = vault.signerCount();
        
        console.log("Added signer:", newSigner);
        console.log("Old signer count:", oldCount);
        console.log("New signer count:", newCount);
        
        vm.stopBroadcast();
    }
}

// ============================================================
// EXAMPLE 9: Update Approval Threshold (Admin only)
// ============================================================
contract UpdateThreshold is Script {
    function run() external {
        uint256 adminPrivateKey = vm.envUint("PRIVATE_KEY");
        address vaultAddress = vm.envAddress("VAULT_ADDRESS");
        uint256 newThreshold = vm.envUint("NEW_THRESHOLD");
        
        vm.startBroadcast(adminPrivateKey);
        
        VaultGuard vault = VaultGuard(payable(vaultAddress));
        
        uint256 oldThreshold = vault.approvalThreshold();
        uint256 signerCount = vault.signerCount();
        
        console.log("Current threshold:", oldThreshold);
        console.log("Signer count:", signerCount);
        console.log("New threshold:", newThreshold);
        
        require(newThreshold > 0 && newThreshold <= signerCount, "Invalid threshold");
        
        vault.updateApprovalThreshold(newThreshold);
        
        console.log("Threshold updated successfully");
        
        vm.stopBroadcast();
    }
}

// ============================================================
// EXAMPLE 10: Check Treasury Balances
// ============================================================
contract CheckBalances is Script {
    function run() external view {
        address vaultAddress = vm.envAddress("VAULT_ADDRESS");
        
        VaultGuard vault = VaultGuard(payable(vaultAddress));
        
        console.log("=== Treasury Balances ===");
        
        // ETH balance
        uint256 ethBalance = vault.getTreasuryBalance(address(0));
        console.log("ETH:", ethBalance);
        
        // If you have token addresses in .env, check those too
        // address token1 = vm.envAddress("TOKEN_1");
        // uint256 token1Balance = vault.getTreasuryBalance(token1);
        // console.log("Token 1:", token1Balance);
    }
}

// ============================================================
// EXAMPLE 11: Batch Operations - Create Multiple Proposals
// ============================================================
contract BatchCreateProposals is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address vaultAddress = vm.envAddress("VAULT_ADDRESS");
        
        vm.startBroadcast(deployerPrivateKey);
        
        VaultGuard vault = VaultGuard(payable(vaultAddress));
        
        // Create multiple proposals
        address[] memory recipients = new address[](3);
        recipients[0] = 0x70997970C51812dc3A010C7d01b50e0d17dc79C8;
        recipients[1] = 0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC;
        recipients[2] = 0x90F79bf6EB2c4f870365E785982E1f101E93b906;
        
        uint256[] memory amounts = new uint256[](3);
        amounts[0] = 1 ether;
        amounts[1] = 2 ether;
        amounts[2] = 3 ether;
        
        string[] memory descriptions = new string[](3);
        descriptions[0] = "Payment to developer 1";
        descriptions[1] = "Payment to developer 2";
        descriptions[2] = "Payment to developer 3";
        
        for (uint i = 0; i < 3; i++) {
            uint256 proposalId = vault.createProposal(
                recipients[i],
                address(0),
                amounts[i],
                "",
                descriptions[i]
            );
            console.log("Created proposal", i + 1, "ID:", proposalId);
        }
        
        vm.stopBroadcast();
    }
}

// ============================================================
// EXAMPLE 12: Emergency Pause (Admin only)
// ============================================================
contract EmergencyPause is Script {
    function run() external {
        uint256 adminPrivateKey = vm.envUint("PRIVATE_KEY");
        address vaultAddress = vm.envAddress("VAULT_ADDRESS");
        
        vm.startBroadcast(adminPrivateKey);
        
        VaultGuard vault = VaultGuard(payable(vaultAddress));
        
        vault.pause();
        
        console.log("Contract paused - all operations disabled");
        console.log("Use EmergencyUnpause script to resume");
        
        vm.stopBroadcast();
    }
}

contract EmergencyUnpause is Script {
    function run() external {
        uint256 adminPrivateKey = vm.envUint("PRIVATE_KEY");
        address vaultAddress = vm.envAddress("VAULT_ADDRESS");
        
        vm.startBroadcast(adminPrivateKey);
        
        VaultGuard vault = VaultGuard(payable(vaultAddress));
        
        vault.unpause();
        
        console.log("Contract unpaused - operations resumed");
        
        vm.stopBroadcast();
    }
}

// ============================================================
// HOW TO RUN THESE SCRIPTS
// ============================================================
/*

1. Set environment variables in .env:
   PRIVATE_KEY=your_private_key
   VAULT_ADDRESS=deployed_vault_address
   PROPOSAL_ID=proposal_id_to_interact_with
   RECIPIENT=recipient_address
   TOKEN_ADDRESS=token_contract_address
   NEW_SIGNER=new_signer_address
   NEW_THRESHOLD=new_threshold_value

2. Run scripts using forge script:

   # Create ETH proposal
   forge script script/Interaction.s.sol:CreateETHProposal \
       --rpc-url $SEPOLIA_RPC_URL \
       --broadcast

   # Approve proposal
   forge script script/Interaction.s.sol:ApproveProposal \
       --rpc-url $SEPOLIA_RPC_URL \
       --broadcast

   # Execute proposal
   forge script script/Interaction.s.sol:ExecuteProposal \
       --rpc-url $SEPOLIA_RPC_URL \
       --broadcast

   # Query proposal (no broadcast needed)
   forge script script/Interaction.s.sol:QueryProposal \
       --rpc-url $SEPOLIA_RPC_URL

3. Monitor transactions:
   Check on block explorer (etherscan.io)
   
4. Best practices:
   - Always query state before making changes
   - Test on testnet first
   - Double-check addresses and amounts
   - Keep private keys secure
   - Use hardware wallet for mainnet

*/