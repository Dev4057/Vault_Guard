cat > README.md << 'EOF'
# 🏛️ VaultGuard - Multi-Signature Treasury Management

[![Solidity](https://img.shields.io/badge/Solidity-0.8.30-blue)](https://soliditylang.org/)
[![Foundry](https://img.shields.io/badge/Foundry-Latest-orange)](https://getfoundry.sh/)
[![React](https://img.shields.io/badge/React-18-blue)](https://react.dev/)
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](https://opensource.org/licenses/MIT)

**VaultGuard** is a secure, production-ready Multi-Signature Treasury Management system built on Ethereum. It requires multiple approvals (M-of-N) for all spending decisions, with built-in time-locks and role-based access control.

![VaultGuard Dashboard](https://via.placeholder.com/800x400?text=VaultGuard+Dashboard)

## ✨ Features

- 🔐 **Multi-Signature Security** - Requires 3 out of 5 approvals (configurable)
- ⏰ **Time-Lock Safety** - 48-hour waiting period after approval
- 🗳️ **Democratic Voting** - Transparent on-chain proposal system
- 👥 **Role-Based Access** - Granular permissions (Admin, Signer, Proposer, Executor)
- 💰 **ETH & ERC20 Support** - Manage multiple asset types
- 🎨 **Modern UI** - Beautiful, responsive React frontend
- ✅ **Fully Tested** - Comprehensive test suite with 95%+ coverage
- 🔍 **Verified on Etherscan** - Open-source and auditable

---

## 🎯 Use Cases

- **DAO Treasuries** - Secure fund management for decentralized organizations
- **Multi-Sig Wallets** - Corporate or team fund management
- **Grant Programs** - Transparent distribution of funds
- **Investment Clubs** - Collaborative investment decisions

---

## 🚀 Quick Start

### Prerequisites

- [Foundry](https://getfoundry.sh/)
- [Node.js](https://nodejs.org/) v18+
- [MetaMask](https://metamask.io/)

### Installation
```bash
# Clone the repository
git clone https://github.com/YOUR_USERNAME/vault_guard.git
cd vault_guard

# Install Foundry dependencies
forge install

# Install frontend dependencies
cd Frontend
npm install
```

### Configuration

1. **Create `.env` file:**
```bash
cp .env.example .env
```

2. **Fill in your values:**
```env
PRIVATE_KEY=0xYOUR_PRIVATE_KEY
SEPOLIA_RPC_URL=https://eth-sepolia.g.alchemy.com/v2/YOUR_KEY
ETHERSCAN_API_KEY=YOUR_KEY
SIGNER_1=0xYOUR_WALLET_1
SIGNER_2=0xYOUR_WALLET_2
# ... (continue for all 5 signers)
APPROVAL_THRESHOLD=3
```

### Deploy Smart Contract
```bash
# Deploy to Sepolia testnet
source .env
forge script script/Deploy.s.sol:DeployVaultGuard \
    --rpc-url $SEPOLIA_RPC_URL \
    --broadcast \
    --verify
```

Copy the deployed contract address and update:
- `.env` → `VAULT_ADDRESS=0xYOUR_CONTRACT_ADDRESS`
- `Frontend/src/App.jsx` → line 7

### Run Frontend
```bash
cd Frontend
npm run dev
```

Open http://localhost:5173 and connect your MetaMask!

---

## 📖 How It Works

### Proposal Lifecycle
```
1. CREATE → 2. VOTE (7 days) → 3. APPROVED → 4. QUEUED (48h) → 5. EXECUTABLE → 6. EXECUTED
```

### Example Flow

1. **Alice creates proposal**: "Send 1 ETH to Developer Bob"
2. **Signers vote**: 3 out of 5 approve ✓
3. **Auto-queued**: 48-hour time-lock begins ⏰
4. **After 48 hours**: Proposal becomes executable
5. **Alice executes**: 1 ETH sent to Bob ✅

---

## 🛠️ Smart Contract Architecture
```
VaultGuard.sol
├── Multi-Signature Logic (M-of-N approvals)
├── Time-Lock Mechanism (48-hour safety period)
├── Role-Based Access Control
│   ├── ADMIN_ROLE
│   ├── SIGNER_ROLE
│   ├── PROPOSER_ROLE
│   └── EXECUTOR_ROLE
├── Proposal State Machine
│   ├── Pending → Active → Approved
│   ├── Queued → Executable → Executed
│   └── Rejected / Cancelled / Expired
├── Treasury Management (ETH + ERC20)
└── Emergency Pause System
```

---

## 🧪 Testing
```bash
# Run all tests
forge test

# Run with verbosity
forge test -vvv

# Run specific test
forge test --match-test testCreateProposal

# Gas report
forge test --gas-report

# Coverage
forge coverage
```

**Test Results:**
```
✓ 37 tests passed
✓ Gas optimized
✓ 95%+ coverage
```

---

## 📊 Gas Usage

| Function | Gas Cost |
|----------|----------|
| Create Proposal | ~150k |
| Vote (Approve/Reject) | ~50k |
| Execute Proposal | ~80-200k |
| Add Signer | ~50k |

---

## 🔐 Security Features

- ✅ **ReentrancyGuard** - Protection against reentrancy attacks
- ✅ **Pausable** - Emergency stop mechanism
- ✅ **AccessControl** - OpenZeppelin role-based permissions
- ✅ **Time-Locks** - 48-hour delay prevents rushed decisions
- ✅ **Voting Limits** - Max 5 active proposals per address
- ✅ **SafeERC20** - Secure token transfers

**⚠️ Security Note:** This contract has NOT been professionally audited. Use at your own risk.

---

## 📱 Frontend Features

- 🎨 Modern glassmorphism UI
- 📊 Real-time proposal tracking
- 🔔 Transaction notifications
- 📋 Copy-to-clipboard for addresses
- 🔄 Auto-refresh data
- 📱 Fully responsive design
- 🌐 Etherscan integration

---

## 📁 Project Structure
```
vault_guard/
├── src/
│   └── VaultGuard.sol           # Main contract
├── test/
│   └── VaultGuard.t.sol         # Test suite
├── script/
│   ├── Deploy.s.sol             # Deployment scripts
│   └── Interactions.s.sol       # Interaction examples
├── Frontend/
│   ├── src/
│   │   ├── App.jsx              # Main React component
│   │   └── index.css            # Styles
│   └── package.json
├── foundry.toml                 # Foundry config
├── .env.example                 # Environment template
└── README.md
```

---

## 🌐 Deployed Contracts

### Sepolia Testnet
- **Contract**: `0x0a7a1acCED934484954214249fCfCb0c918E3729`
- **Explorer**: [View on Etherscan](https://sepolia.etherscan.io/address/0x0a7a1acced934484954214249fcfcb0c918e3729)

---

## 🛣️ Roadmap

- [ ] Add proposal categories/tags
- [ ] Implement delegate voting
- [ ] Add spending limits per role
- [ ] Create mobile app
- [ ] Add ENS support
- [ ] Integrate with Gnosis Safe
- [ ] Add recurring payment feature
- [ ] Professional security audit

---

## 🤝 Contributing

Contributions are welcome! Please:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit changes (`git commit -m 'Add amazing feature'`)
4. Push to branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

---

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## 🙏 Acknowledgments

- [OpenZeppelin](https://openzeppelin.com/) - Security contracts
- [Foundry](https://getfoundry.sh/) - Development framework
- [Ethers.js](https://ethers.org/) - Ethereum library
- [Tailwind CSS](https://tailwindcss.com/) - UI styling

---

## 📞 Contact

- **GitHub**: [@YOUR_USERNAME](https://github.com/Dev4057)
- **Twitter**: [@Dev_9007](https://twitter.com/Dev_9007)
- **Discord**: devang6061

---

## ⚠️ Disclaimer

This software is provided "as is" without warranty. Use at your own risk. The authors are not responsible for any losses incurred through the use of this software.

---

**Built with ❤️ for the Ethereum ecosystem**
