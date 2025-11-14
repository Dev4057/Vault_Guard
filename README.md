Got you — you want a **clean, ready-to-paste README.md** in **proper Markdown**, formatted exactly like GitHub expects, with headings, tables, badges, code blocks, emojis, everything clean and attractive.

Here is a **FULLY FORMATTED README.md** for your repo — **just copy–paste this directly into `README.md`** and push to GitHub.

---

# 🏛️ DAO Governance DApp

A decentralized autonomous organization (DAO) governance platform built on Ethereum that enables democratic decision-making through proposal creation, voting, execution, treasury management, and member-based access control.

![Solidity](https://img.shields.io/badge/Solidity-0.8.19-blue)
![React](https://img.shields.io/badge/React-18-blue)
![Foundry](https://img.shields.io/badge/Foundry-Latest-orange)
![License](https://img.shields.io/badge/license-MIT-green)

---

## 📋 Table of Contents

* [✨ Features](#-features)
* [🛠️ Tech Stack](#️-tech-stack)
* [📦 Prerequisites](#-prerequisites)
* [🚀 Installation](#-installation)
* [🔧 Smart Contract Deployment](#-smart-contract-deployment)
* [🎨 Frontend Setup](#-frontend-setup)
* [📱 Usage](#-usage)
* [🧪 Testing](#-testing)
* [📁 Project Structure](#-project-structure)
* [🔐 Smart Contract Details](#-smart-contract-details)
* [🐛 Troubleshooting](#-troubleshooting)
* [🌐 Deployment Checklist](#-deployment-checklist)
* [📊 Gas Usage](#-gas-usage)
* [🔒 Security Considerations](#-security-considerations)
* [🤝 Contributing](#-contributing)
* [📝 License](#-license)
* [🙏 Acknowledgments](#-acknowledgments)
* [📞 Contact](#-contact)
* [🗺️ Roadmap](#-roadmap)

---

## ✨ Features

### **Core Functionality**

* 🗳️ **Democratic Voting System**
* 📝 **Proposal Creation**
* ⚡ **Automatic Proposal Execution**
* 👥 **Member Management**
* 💰 **Treasury Management (ETH)**
* 🎯 **Configurable Quorum**

### **Advanced Features**

* ⏰ **Voting Period (3 days default)**
* 🔍 **Real-time Proposal Updates**
* 🎨 **Modern, Responsive UI**
* 🔐 **Secure Solidity Architecture**
* 📊 **DAO Dashboard Analytics**

---

## 🛠️ Tech Stack

### **Smart Contract**

* Solidity `^0.8.19`
* Foundry
* OpenZeppelin

### **Frontend**

* React 18
* Vite
* Ethers.js v6
* Tailwind CSS
* Lucide Icons

### **Networks**

* Anvil (local)
* Sepolia (recommended)
* Ethereum

---

## 📦 Prerequisites

Install:

* Node.js 18+
* Git
* Foundry
* MetaMask
* npm or yarn

Install Foundry:

```bash
curl -L https://foundry.paradigm.xyz | bash
foundryup
```

---

## 🚀 Installation

### 1. Clone the repo

```bash
git clone https://github.com/yourusername/dao-dapp.git
cd dao-dapp
```

### 2. Install contract dependencies

```bash
forge install
```

### 3. Install frontend dependencies

```bash
cd frontend
npm install
```

---

## 🔧 Smart Contract Deployment

### 1. Create `.env`

```bash
cp .env.example .env
nano .env
```

### Add:

```env
PRIVATE_KEY=your_private_key
SEPOLIA_RPC_URL=your_url
ETHERSCAN_API_KEY=your_key
MEMBER_1=0x123...
MEMBER_2=0x234...
MEMBER_3=0x345...
QUORUM=2
```

### 2. Compile

```bash
forge build
```

### 3. Run tests

```bash
forge test -vvv
```

### 4. Deploy locally (Anvil)

```bash
anvil
```

In another terminal:

```bash
forge script script/DeployDAO.s.sol:DeployDAO \
  --rpc-url http://127.0.0.1:8545 \
  --broadcast
```

### 5. Deploy to Sepolia

```bash
forge script script/DeployDAO.s.sol:DeployDAO \
  --rpc-url $SEPOLIA_RPC_URL \
  --broadcast \
  --verify -vvvv
```

---

## 🎨 Frontend Setup

### 1. Update contract address

Edit:

```javascript
const DAO_ADDRESS = "0xYourContractAddress";
```

### 2. Run development server

```bash
npm run dev
```

### 3. Build production

```bash
npm run build
```

---

## 📱 Usage

### **Connect Wallet**

* Click **"Connect Wallet"**
* Approve MetaMask

### **Create Proposal**

* Provide:

  * Description
  * Target address (optional)
  * ETH amount (optional)

### **Vote**

* Members can vote **For** or **Against**

### **Execute**

* After 3-day voting period
* If quorum + majority achieved

### **Fund DAO Treasury**

* Send ETH directly via UI

---

## 🧪 Testing

```bash
forge test
forge test -vvv
forge test --gas-report
forge test --match-test testCreateProposal
```

### Coverage Report

```bash
forge coverage
```

---

## 📁 Project Structure

```
dao-dapp/
├── src/
│   └── DAO.sol
├── test/
│   └── DAO.t.sol
├── script/
│   └── DeployDAO.s.sol
├── frontend/
│   ├── src/
│   │   ├── App.jsx
│   │   └── index.css
│   ├── public/
│   └── vite.config.js
├── .env
├── foundry.toml
└── README.md
```

---

## 🔐 Smart Contract Details

### **Key Functions**

* `createProposal()`
* `vote()`
* `executeProposal()`
* `addMember()`
* `removeMember()`
* `updateQuorum()`

### **Events**

```solidity
event ProposalCreated(uint256 proposalId, string description, uint256 deadline);
event Voted(uint256 proposalId, address voter, bool support);
event ProposalExecuted(uint256 proposalId, address executor);
event MemberAdded(address member);
event MemberRemoved(address member);
```

---

## 🐛 Troubleshooting

| Issue                   | Fix                               |
| ----------------------- | --------------------------------- |
| forge not found         | reinstall foundry                 |
| .env line errors        | `dos2unix .env`                   |
| Metamask not connecting | switch networks                   |
| Not a member error      | ensure deployed addresses correct |

---

## 🌐 Deployment Checklist

* [ ] Tests passing
* [ ] Contract verified
* [ ] Correct DAO members added
* [ ] Quorum configured
* [ ] Frontend updated
* [ ] No private keys pushed
* [ ] Treasury funded

---

## 📊 Gas Usage

| Function         | Gas      |
| ---------------- | -------- |
| Create Proposal  | ~150k    |
| Vote             | ~50k     |
| Execute Proposal | 80k–200k |
| Add Member       | 50k      |

---

## 🔒 Security Considerations

* Uses Solidity 0.8+ overflow protection
* Emits events for all critical actions
* No reentrancy for ETH transfers
* Public functions use access control
* Not audited — use at your own risk

---

## 🤝 Contributing

1. Fork repo
2. Create branch
3. Commit changes
4. Open PR

---

## 📝 License

MIT License — see `LICENSE`.

---

## 🙏 Acknowledgments

* OpenZeppelin
* Foundry
* Ethers.js
* Tailwind

---

## 📞 Contact

* **GitHub:** [https://github.com/Dev4057](https://github.com/Dev4057)
* **Twitter:** @Dev_9007
* **Discord:** devang6061

---

## 🗺️ Roadmap

* [ ] Delegated voting
* [ ] Proposal categories
* [ ] Time-lock mechanism
* [ ] Multi-sig support
* [ ] Token-weighted voting
* [ ] ENS integration
* [ ] Mobile app

---

**Built with ❤️ by Devang**
*Made in 2025*
