🔐 VaultGuard
Multi-Signature Treasury with Time-Locked Governance

A production-ready, security-driven smart contract system that powers decentralized treasury management with multi-signature approvals, proposal voting, and time-delayed execution.

Built for DAOs, DeFi protocols, investment collectives, and teams that need secure, transparent, and governance-aligned fund control.

⭐ Features at a Glance
✔️ Multi-Signature Approvals

Configurable M-of-N signer threshold (e.g., 3-of-5)

Approvals, rejections & vote changes

Automatic majority/rejection calculations

✔️ Time-Locked Execution

Default: 48-hour time-lock

Prevents rushed or malicious execution

Optional extended execution window (3 days, configurable)

✔️ Role-Based Access Control

ADMIN_ROLE: Manage signers, parameters, emergency controls

SIGNER_ROLE: Vote on proposals

PROPOSER_ROLE: Create proposals

EXECUTOR_ROLE: Execute after the time-lock

✔️ Governance-Driven Proposal Lifecycle
Created → Active → Approved → Queued → Executable → Executed  
                     ↓
               Rejected / Cancelled / Expired

✔️ Compatible Treasury

ETH + ERC20 support

Contract interactions through calldata

Deposit tracking per token

Emergency recovery

✔️ Hardened Security

ReentrancyGuard

Pausable circuit breaker

SafeERC20

Explicit state management

Extensive unit tests

🏗️ Architecture
VaultGuard.sol
VaultGuard
├── AccessControl
│   ├── ADMIN_ROLE
│   ├── SIGNER_ROLE
│   ├── PROPOSER_ROLE
│   └── EXECUTOR_ROLE
├── Proposal Management
│   ├── creation
│   ├── voting
│   ├── queueing
│   └── execution
├── Treasury (ETH + ERC20)
└── Security
    ├── Pausable
    ├── ReentrancyGuard
    └── Emergency recovery

Proposal States
State	Description	Transition
Pending	Just created	→ Active
Active	Voting period	→ Approved, Rejected, Expired
Approved	Majority met	→ Queued
Queued	Time-lock	→ Executable, Cancelled
Executable	Ready to execute	→ Executed, Expired
Executed	Completed	Terminal
Rejected	Failed vote	Terminal
Cancelled	Admin cancel	Terminal
Expired	Time exceeded	Terminal
🚀 Quick Start
Install
git clone https://github.com/yourusername/vaultguard
cd vaultguard
forge install
forge build
forge test

Deploy to Testnet
cp .env.example .env
forge script script/Deploy.s.sol:DeployVaultGuardTestnet \
  --rpc-url $SEPOLIA_RPC_URL \
  --broadcast \
  --verify

📚 Usage
Create Proposal
vaultGuard.createProposal(
    recipient,
    address(0),      // ETH
    10 ether,
    "",
    "Q4 Development Milestone"
);

Vote
vaultGuard.approve(proposalId);
vaultGuard.reject(proposalId);

Execute
vaultGuard.executeProposal(proposalId);

Query
vaultGuard.getProposal(proposalId);
vaultGuard.getTimeLockRemaining(proposalId);
vaultGuard.getTreasuryBalance(token);

🔒 Security
Built-In Protections

ReentrancyGuard

Pausable emergency switch

SafeERC20

Input validation on all proposals

No delegatecall usage

Full event logging

Best Practices Followed

Checks-Effects-Interactions

Minimal trust assumptions

Strict governance control

Well-tested edge cases

🧪 Testing Suite
forge test
forge test --match-test test_ExecuteProposal
forge test --gas-report
forge coverage

Coverage Includes:

Deployment

Proposal creation

Voting flows

Time-lock logic

ETH & ERC20 execution

Emergency actions

Access control

Reentrancy & security

Expirations & edge cases

Target: >95% coverage

⚙️ Configuration
Default Parameters
TIME_LOCK_PERIOD = 2 days;
VOTING_PERIOD = 7 days;
EXECUTION_WINDOW = 3 days;
MAX_ACTIVE_PROPOSALS_PER_ADDRESS = 5;

Configurable

Approval threshold

Signer set

Role assignments

📊 Gas Benchmarks (Approx.)
Operation	Gas
Deploy	~3,500,000
Create Proposal	~150,000
Vote	~80,000
Execute (ETH)	~70,000
Execute (ERC20)	~90,000
Cancel	~50,000
🎯 Use Cases
🏛️ 1. DAO Treasury

Secure, transparent fund governance.

💧 2. Protocol Treasury

Multi-sig protection for protocol-controlled liquidity.

💼 3. Investment DAO

Collective decisioning with auditability.

🎁 4. Grant Programs

Milestone-based funding with community oversight.

🏢 5. Corporate Treasury

Secure treasury operations for crypto-native teams.

🔧 Advanced Features
Contract Interactions
bytes memory data = abi.encodeWithSignature(
    "stake(uint256)", 
    stakeAmount
);

vaultGuard.createProposal(
    stakingContract,
    tokenAddress,
    stakeAmount,
    data,
    "Stake 1000 tokens"
);

Emergency Controls
vaultGuard.pause();
vaultGuard.emergencyWithdraw(token, safeAddress, amount);
vaultGuard.unpause();

🛣️ Roadmap
✅ Phase 1 – Core

Multi-sig voting

Time-lock

Roles

ERC20 + ETH

🔜 Phase 2 – Enhanced Governance

Weighted voting

Delegation

Recurring payments

Spending limits

🔜 Phase 3 – Integrations

Subgraph

Notification bots

Dashboard UI

🔜 Phase 4 – Advanced Governance

Quadratic voting

Time-weighted voting

Category-based thresholds

Veto logic

🤝 Contributing

Fork the repo

Create a feature branch

Add tests

Ensure all tests pass:

forge test


Open a PR

Dev Tools
forge fmt --check
solhint 'src/**/*.sol'
forge coverage

📄 License

MIT License — see LICENSE.

❤️ Acknowledgments

Built with:

Foundry

OpenZeppelin

Solidity

Inspired by:

Gnosis Safe

Compound Timelock

OpenZeppelin Governor

📞 Support

Issues: GitHub Issues

Discussions: GitHub Discussions

Twitter: @Dev_9007