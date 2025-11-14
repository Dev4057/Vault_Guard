🔐 VaultGuard
Multi-Signature Treasury with Time-Locked Spending Proposals

A secure, production-ready smart contract system for managing organizational treasuries with multi-signature approval and time-delayed execution.

Show Image
Show Image
Show Image

📖 Overview
VaultGuard is an advanced multi-signature treasury management system that extends traditional multi-sig wallets with:

✅ Time-locked execution for security buffer
✅ Role-based access control for flexible governance
✅ Spending proposals with voting mechanism
✅ Support for ETH and ERC20 tokens
✅ Emergency pause & recovery mechanisms
✅ Transparent on-chain governance
Perfect for DAOs, DeFi protocols, investment funds, and any organization requiring secure treasury management.

🎯 Key Features
Multi-Signature Approvals
Configurable M-of-N signature requirement (e.g., 3-of-5)
Signers can change their votes before execution
Automatic rejection threshold calculation
Time-Lock Security
48-hour mandatory delay after approval
Prevents immediate execution of compromised proposals
Provides community review period
Configurable execution window (3 days default)
Role-Based Access
Admin: Manage signers, configure parameters, emergency controls
Signer: Vote on spending proposals
Proposer: Create spending proposals
Executor: Execute approved proposals after time-lock
Proposal Lifecycle
Created → Active → Approved → Queued → Executable → Executed
                           ↓
                     Rejected/Cancelled/Expired
Treasury Management
Hold ETH and multiple ERC20 tokens
Track balances per token
Support for contract interactions via calldata
Emergency withdrawal capabilities
🏗️ Architecture
Core Components
solidity
VaultGuard (Main Contract)
├── Roles (AccessControl)
│   ├── ADMIN_ROLE
│   ├── SIGNER_ROLE
│   ├── PROPOSER_ROLE
│   └── EXECUTOR_ROLE
├── Proposal Management
│   ├── Create proposals
│   ├── Vote (approve/reject)
│   ├── Queue approved proposals
│   └── Execute after time-lock
├── Treasury
│   ├── ETH balance
│   ├── ERC20 balances
│   └── Deposit functions
└── Security
    ├── ReentrancyGuard
    ├── Pausable
    └── Emergency functions
Proposal States
State	Description	Can Transition To
Pending	Just created	Active
Active	Open for voting	Approved, Rejected, Expired
Approved	Threshold met	Queued
Queued	In time-lock period	Executable, Cancelled
Executable	Ready to execute	Executed, Expired
Executed	Completed ✓	Terminal
Rejected	Failed voting	Terminal
Cancelled	Manually cancelled	Terminal
Expired	Time window passed	Terminal
🚀 Quick Start
Installation
bash
# Clone the repository
git clone https://github.com/yourusername/vaultguard
cd vaultguard

# Install dependencies
forge install

# Build contracts
forge build

# Run tests
forge test
Deployment
bash
# Setup environment
cp .env.example .env
# Edit .env with your configuration

# Deploy to testnet
forge script script/Deploy.s.sol:DeployVaultGuardTestnet \
    --rpc-url $SEPOLIA_RPC_URL \
    --broadcast \
    --verify
📚 Usage Examples
Creating a Proposal
solidity
// Example: Send 10 ETH to recipient
vaultGuard.createProposal(
    recipientAddress,           // Where to send
    address(0),                 // address(0) for ETH
    10 ether,                   // Amount
    "",                         // No calldata
    "Q4 Development Milestone"  // Description
);
Voting on Proposals
solidity
// Approve proposal
vaultGuard.approve(proposalId);

// Or reject it
vaultGuard.reject(proposalId);

// Change your vote (before execution)
vaultGuard.approve(proposalId); // Switch to approval
Executing Proposals
solidity
// After time-lock expires (48 hours)
vaultGuard.executeProposal(proposalId);
Querying State
solidity
// Get proposal details
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
    ProposalState state
) = vaultGuard.getProposal(proposalId);

// Check time remaining
uint256 timeLeft = vaultGuard.getTimeLockRemaining(proposalId);

// Check treasury balance
uint256 ethBalance = vaultGuard.getTreasuryBalance(address(0));
uint256 tokenBalance = vaultGuard.getTreasuryBalance(tokenAddress);
🔒 Security Features
Built-in Protections
ReentrancyGuard: Prevents reentrancy attacks on execution
Pausable: Emergency circuit breaker
Access Control: Role-based permissions
Time-Lock: 48-hour delay prevents rushed/malicious execution
Input Validation: Comprehensive checks on all inputs
SafeERC20: Protection against non-standard tokens
Security Best Practices
✅ Checks-Effects-Interactions pattern
✅ No delegatecall usage (reduces attack surface)
✅ Explicit state management
✅ Comprehensive event logging
✅ Gas-efficient operations
✅ Well-tested edge cases
Auditing
bash
# Run static analysis
slither src/VaultGuard.sol

# Check coverage
forge coverage

# Gas profiling
forge test --gas-report
🧪 Testing
Run Test Suite
bash
# All tests
forge test

# Specific test
forge test --match-test test_ExecuteProposal

# With gas report
forge test --gas-report

# With coverage
forge coverage
Test Coverage
The test suite covers:

✅ Deployment scenarios
✅ Treasury management (ETH & ERC20)
✅ Proposal creation & validation
✅ Voting mechanisms (approve/reject/change)
✅ Time-lock functionality
✅ Execution (ETH & ERC20)
✅ Cancellation flows
✅ Admin functions (add/remove signers, threshold updates)
✅ Emergency pause & recovery
✅ Edge cases (expiration, limits, etc.)
✅ Access control enforcement
✅ Reentrancy protection
Target Coverage: >95% line and branch coverage

⚙️ Configuration
Default Parameters
solidity
TIME_LOCK_PERIOD = 2 days     // 48 hours
VOTING_PERIOD = 7 days         // 1 week
EXECUTION_WINDOW = 3 days      // After time-lock
MAX_ACTIVE_PROPOSALS_PER_ADDRESS = 5
Configurable Parameters
solidity
approvalThreshold   // Number of approvals needed (3-of-5, etc.)
signerCount        // Total number of signers
Role Management
Admins can:

Add/remove signers
Update approval threshold
Grant/revoke roles
Pause/unpause contract
Emergency withdraw (when paused)
📊 Gas Costs
Approximate gas costs on Ethereum mainnet:

Operation	Gas Cost (approx)
Deploy Contract	~3,500,000
Create Proposal	~150,000
Vote (Approve/Reject)	~80,000
Execute Proposal (ETH)	~70,000
Execute Proposal (ERC20)	~90,000
Cancel Proposal	~50,000
Note: Actual costs vary with network conditions and proposal complexity

🎯 Use Cases
1. DAO Treasury Management
Manage community funds with transparent governance
Time-lock protects against governance attacks
Public proposal history builds trust
2. DeFi Protocol Treasuries
Secure protocol-owned liquidity
Multi-sig protection for admin functions
Integration with DeFi protocols via calldata
3. Investment DAOs
Pooled investment funds
Democratic decision-making on investments
Clear audit trail for investors
4. Grant Programs
Transparent grant distribution
Community oversight on spending
Milestone-based funding
5. Startup/Company Treasuries
Corporate governance for crypto assets
Require multiple executive approvals
Professional treasury management
🔧 Advanced Features
Contract Interactions
Proposals can include calldata for complex operations:

solidity
// Example: Approve and stake in DeFi protocol
bytes memory calldata = abi.encodeWithSignature(
    "stake(uint256)", 
    stakeAmount
);

vaultGuard.createProposal(
    stakingContract,
    tokenAddress,
    stakeAmount,
    calldata,
    "Stake 1000 tokens in Protocol X"
);
Batch Operations
Create multiple proposals for coordinated actions:

solidity
// Proposal 1: Approve tokens
// Proposal 2: Execute swap
// Proposal 3: Distribute proceeds
Emergency Procedures
solidity
// Pause all operations
vaultGuard.pause();

// Emergency withdrawal (only when paused)
vaultGuard.emergencyWithdraw(tokenAddress, safeAddress, amount);

// Resume operations
vaultGuard.unpause();
🛣️ Roadmap
Phase 1: Core Implementation ✅
Multi-sig voting
Time-lock mechanism
Role-based access
ETH & ERC20 support
Phase 2: Enhanced Features (Planned)
 Weighted voting (based on token holdings)
 Delegation support
 Recurring payments
 Spending limits per role
 Advanced queuing (priority system)
Phase 3: Integration (Planned)
 Subgraph for proposal indexing
 Discord/Telegram notification bot
 Frontend dashboard
 Mobile app
Phase 4: Advanced Governance (Planned)
 Quadratic voting
 Time-weighted voting
 Proposal categories with different thresholds
 Veto powers for specific roles
🤝 Contributing
Contributions are welcome! Please follow these guidelines:

Fork the repository
Create a feature branch (git checkout -b feature/amazing-feature)
Write tests for your changes
Ensure all tests pass (forge test)
Commit your changes (git commit -m 'Add amazing feature')
Push to the branch (git push origin feature/amazing-feature)
Open a Pull Request
Development Setup
bash
# Install pre-commit hooks
forge fmt --check

# Run linter
solhint 'src/**/*.sol'

# Check coverage before PR
forge coverage
📄 License
This project is licensed under the MIT License - see the LICENSE file for details.

🙏 Acknowledgments
Built with:

Foundry - Ethereum development toolkit
OpenZeppelin - Secure smart contract library
Solidity - Smart contract language
Inspired by:

Gnosis Safe
Compound Timelock
OpenZeppelin Governor
📞 Support
Issues: GitHub Issues
Discussions: GitHub Discussions
Twitter: @Dev_9007
⚠️ Disclaimer
This software is provided "as is", without warranty of any kind. Use at your own risk. Always conduct thorough testing and security audits before deploying to mainnet with real funds.

Built with ❤️ for the Ethereum community

