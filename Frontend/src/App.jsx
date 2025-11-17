import React, { useState, useEffect } from 'react';
import { ethers } from 'ethers';
import { AlertCircle, Wallet, Plus, CheckCircle, XCircle, Clock, Send, Users, Shield, TrendingUp, Settings, RefreshCw, Lock, Unlock } from 'lucide-react';

// Contract ABI (condensed for essential functions)
const VAULTGUARD_ABI = [
  "function proposalCount() view returns (uint256)",
  "function approvalThreshold() view returns (uint256)",
  "function signerCount() view returns (uint256)",
  "function getTreasuryBalance(address token) view returns (uint256)",
  "function createProposal(address recipient, address token, uint256 amount, bytes data, string description) returns (uint256)",
  "function approve(uint256 proposalId)",
  "function reject(uint256 proposalId)",
  "function executeProposal(uint256 proposalId)",
  "function cancelProposal(uint256 proposalId)",
  "function getProposal(uint256 proposalId) view returns (uint256 id, address proposer, address recipient, address token, uint256 amount, string description, uint256 approvalCount, uint256 rejectionCount, uint256 createdAt, uint256 queuedAt, uint256 executedAt, uint8 state)",
  "function getProposalState(uint256 proposalId) view returns (uint8)",
  "function getVote(uint256 proposalId, address voter) view returns (uint8)",
  "function getTimeLockRemaining(uint256 proposalId) view returns (uint256)",
  "function hasRole(bytes32 role, address account) view returns (bool)",
  "function pause()",
  "function unpause()",
  "function addSigner(address signer)",
  "function removeSigner(address signer)",
  "function updateApprovalThreshold(uint256 newThreshold)",
  "event ProposalCreated(uint256 indexed proposalId, address indexed proposer, address recipient, address token, uint256 amount, string description)",
  "event ProposalApproved(uint256 indexed proposalId, address indexed signer, uint256 approvalCount)",
  "event ProposalExecuted(uint256 indexed proposalId, address indexed executor)"
];

const PROPOSAL_STATES = {
  0: { name: 'Pending', color: 'bg-gray-500', icon: Clock },
  1: { name: 'Active', color: 'bg-blue-500', icon: Clock },
  2: { name: 'Approved', color: 'bg-green-500', icon: CheckCircle },
  3: { name: 'Queued', color: 'bg-yellow-500', icon: Lock },
  4: { name: 'Executable', color: 'bg-emerald-500', icon: Unlock },
  5: { name: 'Executed', color: 'bg-green-600', icon: CheckCircle },
  6: { name: 'Rejected', color: 'bg-red-500', icon: XCircle },
  7: { name: 'Cancelled', color: 'bg-gray-600', icon: XCircle },
  8: { name: 'Expired', color: 'bg-orange-500', icon: AlertCircle }
};

const VaultGuardDApp = () => {
  // State management
  const [account, setAccount] = useState('');
  const [provider, setProvider] = useState(null);
  const [signer, setSigner] = useState(null);
  const [contract, setContract] = useState(null);
  const [chainId, setChainId] = useState(null);
  
  // Contract data
  const [vaultAddress, setVaultAddress] = useState('');
  const [treasuryBalance, setTreasuryBalance] = useState('0');
  const [proposalCount, setProposalCount] = useState(0);
  const [approvalThreshold, setApprovalThreshold] = useState(0);
  const [signerCount, setSignerCount] = useState(0);
  const [proposals, setProposals] = useState([]);
  const [userRoles, setUserRoles] = useState({
    isSigner: false,
    isAdmin: false,
    isProposer: false,
    isExecutor: false
  });
  
  // UI state
  const [activeTab, setActiveTab] = useState('dashboard');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');
  const [success, setSuccess] = useState('');
  
  // Form states
  const [newProposal, setNewProposal] = useState({
    recipient: '',
    token: '0x0000000000000000000000000000000000000000',
    amount: '',
    description: ''
  });

  // Role constants
  const ROLES = {
    ADMIN: '0xa49807205ce4d355092ef5a8a18f56e8913cf4a201fbe287825b095693c21775',
    SIGNER: '0xe2f4eaae4a9751e85a3e4a7b9587827a877f29914755229b07a7b2da98285f70',
    PROPOSER: '0x5e9c6d22e3f5a3e9c1c65f9e3d1d2b0f3a4f7c9e8b7d6e5f4c3b2a1d0e9f8b7c',
    EXECUTOR: '0x8e2f4eaae4a9751e85a3e4a7b9587827a877f29914755229b07a7b2da98285f71'
  };

  // Connect wallet
  const connectWallet = async () => {
    try {
      setError('');
      if (!window.ethereum) {
        setError('Please install MetaMask or another Web3 wallet');
        return;
      }

      const accounts = await window.ethereum.request({ 
        method: 'eth_requestAccounts' 
      });
      
      const chainId = await window.ethereum.request({ 
        method: 'eth_chainId' 
      });

      setAccount(accounts[0]);
      setChainId(chainId);
      
      // Initialize ethers
      const provider = new ethers.BrowserProvider(window.ethereum);
      const signer = await provider.getSigner();
      
      setProvider(provider);
      setSigner(signer);
      
      setSuccess('Wallet connected successfully!');
      setTimeout(() => setSuccess(''), 3000);
    } catch (err) {
      setError('Failed to connect wallet: ' + err.message);
    }
  };

  // Initialize contract
  const initializeContract = async () => {
    if (!vaultAddress || !signer) return;
    
    try {
      setLoading(true);
      setError('');
      
      const vaultContract = new ethers.Contract(vaultAddress, VAULTGUARD_ABI, signer);
      setContract(vaultContract);
      
      await loadContractData(vaultContract);
      setSuccess('Contract loaded successfully!');
      setTimeout(() => setSuccess(''), 3000);
    } catch (err) {
      setError('Failed to load contract: ' + err.message);
    } finally {
      setLoading(false);
    }
  };

  // Load contract data
  const loadContractData = async (vaultContract = contract) => {
    if (!vaultContract || !account) return;
    
    try {
      setLoading(true);
      
      // Load basic info
      const [balance, count, threshold, signers] = await Promise.all([
        vaultContract.getTreasuryBalance(''),
        vaultContract.proposalCount(),
        vaultContract.approvalThreshold(),
        vaultContract.signerCount()
      ]);
      
      setTreasuryBalance(ethers.formatEther(balance));
      setProposalCount(Number(count));
      setApprovalThreshold(Number(threshold));
      setSignerCount(Number(signers));
      
      // Check user roles
      const roles = await Promise.all([
        vaultContract.hasRole(ROLES.SIGNER, account),
        vaultContract.hasRole(ROLES.ADMIN, account),
        vaultContract.hasRole(ROLES.PROPOSER, account),
        vaultContract.hasRole(ROLES.EXECUTOR, account)
      ]);
      
      setUserRoles({
        isSigner: roles[0],
        isAdmin: roles[1],
        isProposer: roles[2],
        isExecutor: roles[3]
      });
      
      // Load proposals
      await loadProposals(vaultContract, Number(count));
      
    } catch (err) {
      console.error('Error loading data:', err);
      setError('Failed to load contract data: ' + err.message);
    } finally {
      setLoading(false);
    }
  };

  // Load all proposals
  const loadProposals = async (vaultContract = contract, count = proposalCount) => {
    if (!vaultContract || count === 0) return;
    
    try {
      const proposalPromises = [];
      for (let i = 0; i < count; i++) {
        proposalPromises.push(loadProposalDetails(vaultContract, i));
      }
      
      const loadedProposals = await Promise.all(proposalPromises);
      setProposals(loadedProposals.filter(p => p !== null).reverse());
    } catch (err) {
      console.error('Error loading proposals:', err);
    }
  };

  // Load single proposal
  const loadProposalDetails = async (vaultContract = contract, proposalId) => {
    try {
      const [proposal, state, vote, timelock] = await Promise.all([
        vaultContract.getProposal(proposalId),
        vaultContract.getProposalState(proposalId),
        vaultContract.getVote(proposalId, account),
        vaultContract.getTimeLockRemaining(proposalId)
      ]);
      
      return {
        id: Number(proposal.id),
        proposer: proposal.proposer,
        recipient: proposal.recipient,
        token: proposal.token,
        amount: ethers.formatEther(proposal.amount),
        description: proposal.description,
        approvalCount: Number(proposal.approvalCount),
        rejectionCount: Number(proposal.rejectionCount),
        createdAt: Number(proposal.createdAt),
        queuedAt: Number(proposal.queuedAt),
        executedAt: Number(proposal.executedAt),
        state: Number(state),
        userVote: Number(vote),
        timelockRemaining: Number(timelock)
      };
    } catch (err) {
      console.error(`Error loading proposal ${proposalId}:`, err);
      return null;
    }
  };

  // Create proposal
  const createProposal = async () => {
    if (!contract) return;
    
    try {
      setLoading(true);
      setError('');
      
      const amount = ethers.parseEther(newProposal.amount);
      
      const tx = await contract.createProposal(
        newProposal.recipient,
        newProposal.token,
        amount,
        '0x',
        newProposal.description
      );
      
      await tx.wait();
      
      setSuccess('Proposal created successfully!');
      setNewProposal({ recipient: '', token: '0x0000000000000000000000000000000000000000', amount: '', description: '' });
      await loadContractData();
      setActiveTab('proposals');
    } catch (err) {
      setError('Failed to create proposal: ' + err.message);
    } finally {
      setLoading(false);
    }
  };

  // Approve proposal
  const approveProposal = async (proposalId) => {
    if (!contract) return;
    
    try {
      setLoading(true);
      setError('');
      
      const tx = await contract.approve(proposalId);
      await tx.wait();
      
      setSuccess(`Proposal #${proposalId} approved!`);
      await loadContractData();
    } catch (err) {
      setError('Failed to approve proposal: ' + err.message);
    } finally {
      setLoading(false);
    }
  };

  // Reject proposal
  const rejectProposal = async (proposalId) => {
    if (!contract) return;
    
    try {
      setLoading(true);
      setError('');
      
      const tx = await contract.reject(proposalId);
      await tx.wait();
      
      setSuccess(`Proposal #${proposalId} rejected!`);
      await loadContractData();
    } catch (err) {
      setError('Failed to reject proposal: ' + err.message);
    } finally {
      setLoading(false);
    }
  };

  // Execute proposal
  const executeProposal = async (proposalId) => {
    if (!contract) return;
    
    try {
      setLoading(true);
      setError('');
      
      const tx = await contract.executeProposal(proposalId);
      await tx.wait();
      
      setSuccess(`Proposal #${proposalId} executed successfully!`);
      await loadContractData();
    } catch (err) {
      setError('Failed to execute proposal: ' + err.message);
    } finally {
      setLoading(false);
    }
  };

  // Cancel proposal
  const cancelProposal = async (proposalId) => {
    if (!contract) return;
    
    try {
      setLoading(true);
      setError('');
      
      const tx = await contract.cancelProposal(proposalId);
      await tx.wait();
      
      setSuccess(`Proposal #${proposalId} cancelled!`);
      await loadContractData();
    } catch (err) {
      setError('Failed to cancel proposal: ' + err.message);
    } finally {
      setLoading(false);
    }
  };

  // Format time
  const formatTimeRemaining = (seconds) => {
    if (seconds === 0) return 'Ready';
    const days = Math.floor(seconds / 86400);
    const hours = Math.floor((seconds % 86400) / 3600);
    const mins = Math.floor((seconds % 3600) / 60);
    
    if (days > 0) return `${days}d ${hours}h`;
    if (hours > 0) return `${hours}h ${mins}m`;
    return `${mins}m`;
  };

  // Format date
  const formatDate = (timestamp) => {
    if (timestamp === 0) return 'N/A';
    return new Date(timestamp * 1000).toLocaleString();
  };

  // Format address
  const formatAddress = (address) => {
    if (!address) return '';
    return `${address.slice(0, 6)}...${address.slice(-4)}`;
  };

  // Listen for account changes
  useEffect(() => {
    if (window.ethereum) {
      window.ethereum.on('accountsChanged', (accounts) => {
        if (accounts.length > 0) {
          setAccount(accounts[0]);
          if (contract) loadContractData();
        } else {
          setAccount('');
        }
      });

      window.ethereum.on('chainChanged', () => {
        window.location.reload();
      });
    }
  }, [contract]);

  return (
    <div className="min-h-screen bg-gradient-to-br from-slate-900 via-purple-900 to-slate-900">
      {/* Header */}
      <div className="bg-black/30 backdrop-blur-lg border-b border-white/10">
        <div className="max-w-7xl mx-auto px-4 py-4">
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-3">
              <Shield className="w-8 h-8 text-purple-400" />
              <div>
                <h1 className="text-2xl font-bold text-white">VaultGuard</h1>
                <p className="text-sm text-gray-400">Multi-Signature Treasury</p>
              </div>
            </div>
            
            <div className="flex items-center gap-4">
              {account ? (
                <div className="flex items-center gap-3">
                  <div className="text-right">
                    <p className="text-sm text-gray-400">Connected</p>
                    <p className="text-sm font-mono text-white">{formatAddress(account)}</p>
                  </div>
                  <div className="w-10 h-10 rounded-full bg-gradient-to-br from-purple-500 to-pink-500 flex items-center justify-center">
                    <Wallet className="w-5 h-5 text-white" />
                  </div>
                </div>
              ) : (
                <button
                  onClick={connectWallet}
                  className="px-6 py-2 bg-gradient-to-r from-purple-600 to-pink-600 rounded-lg font-semibold text-white hover:from-purple-700 hover:to-pink-700 transition-all flex items-center gap-2"
                >
                  <Wallet className="w-4 h-4" />
                  Connect Wallet
                </button>
              )}
            </div>
          </div>
        </div>
      </div>

      {/* Notifications */}
      {error && (
        <div className="max-w-7xl mx-auto px-4 mt-4">
          <div className="bg-red-500/20 border border-red-500/50 rounded-lg p-4 flex items-center gap-3">
            <AlertCircle className="w-5 h-5 text-red-400" />
            <p className="text-red-200">{error}</p>
            <button onClick={() => setError('')} className="ml-auto text-red-200 text-xl">×</button>
          </div>
        </div>
      )}
      
      {success && (
        <div className="max-w-7xl mx-auto px-4 mt-4">
          <div className="bg-green-500/20 border border-green-500/50 rounded-lg p-4 flex items-center gap-3">
            <CheckCircle className="w-5 h-5 text-green-400" />
            <p className="text-green-200">{success}</p>
            <button onClick={() => setSuccess('')} className="ml-auto text-green-200 text-xl">×</button>
          </div>
        </div>
      )}

      {/* Main Content */}
      <div className="max-w-7xl mx-auto px-4 py-8">
        {!account ? (
          <div className="text-center py-20">
            <Wallet className="w-20 h-20 text-purple-400 mx-auto mb-4" />
            <h2 className="text-3xl font-bold text-white mb-2">Welcome to VaultGuard</h2>
            <p className="text-gray-400 mb-8">Connect your wallet to get started</p>
          </div>
        ) : !contract ? (
          <div className="bg-white/5 backdrop-blur-lg rounded-2xl border border-white/10 p-8">
            <h2 className="text-2xl font-bold text-white mb-6">Enter Vault Address</h2>
            <div className="space-y-4">
              <input
                type="text"
                placeholder="0x..."
                value={vaultAddress}
                onChange={(e) => setVaultAddress(e.target.value)}
                className="w-full px-4 py-3 bg-white/10 border border-white/20 rounded-lg text-white placeholder-gray-400 focus:outline-none focus:ring-2 focus:ring-purple-500"
              />
              <button
                onClick={initializeContract}
                disabled={!vaultAddress || loading}
                className="w-full px-6 py-3 bg-gradient-to-r from-purple-600 to-pink-600 rounded-lg font-semibold text-white hover:from-purple-700 hover:to-pink-700 transition-all disabled:opacity-50"
              >
                {loading ? 'Loading...' : 'Connect to Vault'}
              </button>
            </div>
          </div>
        ) : (
          <>
            {/* Navigation Tabs */}
            <div className="flex gap-2 mb-6 overflow-x-auto pb-2">
              {['dashboard', 'proposals', 'create', 'admin'].map((tab) => (
                <button
                  key={tab}
                  onClick={() => setActiveTab(tab)}
                  className={`px-6 py-3 rounded-lg font-semibold capitalize transition-all whitespace-nowrap ${
                    activeTab === tab
                      ? 'bg-gradient-to-r from-purple-600 to-pink-600 text-white'
                      : 'bg-white/5 text-gray-400 hover:bg-white/10'
                  }`}
                >
                  {tab}
                </button>
              ))}
            </div>

            {/* Dashboard Tab */}
            {activeTab === 'dashboard' && (
              <div className="space-y-6">
                {/* Stats Grid */}
                <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
                  <div className="bg-gradient-to-br from-purple-500/20 to-pink-500/20 backdrop-blur-lg rounded-2xl border border-white/10 p-6">
                    <div className="flex items-center justify-between mb-2">
                      <TrendingUp className="w-8 h-8 text-purple-400" />
                      <button onClick={() => loadContractData()} className="text-purple-400 hover:text-purple-300">
                        <RefreshCw className="w-4 h-4" />
                      </button>
                    </div>
                    <p className="text-gray-400 text-sm">Treasury Balance</p>
                    <p className="text-3xl font-bold text-white">{parseFloat(treasuryBalance).toFixed(4)} ETH</p>
                  </div>
                  
                  <div className="bg-gradient-to-br from-blue-500/20 to-cyan-500/20 backdrop-blur-lg rounded-2xl border border-white/10 p-6">
                    <Clock className="w-8 h-8 text-blue-400 mb-2" />
                    <p className="text-gray-400 text-sm">Total Proposals</p>
                    <p className="text-3xl font-bold text-white">{proposalCount}</p>
                  </div>
                  
                  <div className="bg-gradient-to-br from-green-500/20 to-emerald-500/20 backdrop-blur-lg rounded-2xl border border-white/10 p-6">
                    <Users className="w-8 h-8 text-green-400 mb-2" />
                    <p className="text-gray-400 text-sm">Approval Threshold</p>
                    <p className="text-3xl font-bold text-white">{approvalThreshold} / {signerCount}</p>
                  </div>
                  
                  <div className="bg-gradient-to-br from-orange-500/20 to-red-500/20 backdrop-blur-lg rounded-2xl border border-white/10 p-6">
                    <Shield className="w-8 h-8 text-orange-400 mb-2" />
                    <p className="text-gray-400 text-sm">Your Roles</p>
                    <div className="flex flex-wrap gap-1 mt-2">
                      {userRoles.isSigner && <span className="px-2 py-1 bg-purple-500/30 rounded text-xs text-purple-200">Signer</span>}
                      {userRoles.isAdmin && <span className="px-2 py-1 bg-red-500/30 rounded text-xs text-red-200">Admin</span>}
                      {userRoles.isProposer && <span className="px-2 py-1 bg-blue-500/30 rounded text-xs text-blue-200">Proposer</span>}
                      {userRoles.isExecutor && <span className="px-2 py-1 bg-green-500/30 rounded text-xs text-green-200">Executor</span>}
                    </div>
                  </div>
                </div>

                {/* Recent Proposals */}
                <div className="bg-white/5 backdrop-blur-lg rounded-2xl border border-white/10 p-6">
                  <h3 className="text-xl font-bold text-white mb-4">Recent Proposals</h3>
                  <div className="space-y-3">
                    {proposals.slice(0, 5).map((proposal) => {
                      const stateInfo = PROPOSAL_STATES[proposal.state];
                      const StateIcon = stateInfo.icon;
                      return (
                        <div key={proposal.id} className="bg-white/5 rounded-lg p-4 border border-white/10">
                          <div className="flex items-center justify-between">
                            <div className="flex-1">
                              <div className="flex items-center gap-3 mb-2">
                                <span className="text-gray-400 font-mono">#{proposal.id}</span>
                                <span className={`px-3 py-1 ${stateInfo.color} rounded-full text-xs font-semibold text-white flex items-center gap-1`}>
                                  <StateIcon className="w-3 h-3" />
                                  {stateInfo.name}
                                </span>
                              </div>
                              <p className="text-white font-medium">{proposal.description}</p>
                              <div className="flex items-center gap-4 mt-2 text-sm text-gray-400">
                                <span>{proposal.amount} ETH</span>
                                <span>→ {formatAddress(proposal.recipient)}</span>
                                <span>{proposal.approvalCount}/{approvalThreshold} approvals</span>
                              </div>
                            </div>
                          </div>
                        </div>
                      );
                    })}
                    {proposals.length === 0 && (
                      <div className="text-center py-8">
                        <p className="text-gray-400">No proposals yet</p>
                      </div>
                    )}
                  </div>
                </div>
              </div>
            )}

            {/* Proposals Tab */}
            {activeTab === 'proposals' && (
              <div className="space-y-4">
                <div className="flex items-center justify-between mb-6">
                  <h2 className="text-2xl font-bold text-white">All Proposals</h2>
                  <button onClick={() => loadContractData()} className="px-4 py-2 bg-white/10 rounded-lg text-white hover:bg-white/20 transition-all flex items-center gap-2">
                    <RefreshCw className="w-4 h-4" />
                    Refresh
                  </button>
                </div>
                
                {proposals.map((proposal) => {
                  const stateInfo = PROPOSAL_STATES[proposal.state];
                  const StateIcon = stateInfo.icon;
                  const canVote = userRoles.isSigner && proposal.state === 1;
                  const canExecute = userRoles.isExecutor && proposal.state === 4;
                  const canCancel = userRoles.isAdmin && proposal.state !== 5;
                  
                  return (
                    <div key={proposal.id} className="bg-white/5 backdrop-blur-lg rounded-2xl border border-white/10 p-6">
                      <div className="flex items-start justify-between mb-4">
                        <div>
                          <div className="flex items-center gap-3 mb-2">
                            <span className="text-2xl font-bold text-white">#{proposal.id}</span>
                            <span className={`px-3 py-1 ${stateInfo.color} rounded-full text-xs font-semibold text-white flex items-center gap-1`}>
                              <StateIcon className="w-3 h-3" />
                              {stateInfo.name}
                            </span>
                          </div>
                          <h3 className="text-xl text-white font-semibold">{proposal.description}</h3>
                        </div>
                      </div>
                      
                      <div className="grid grid-cols-2 md:grid-cols-4 gap-4 mb-4">
                        <div>
                          <p className="text-gray-400 text-sm">Amount</p>
                          <p className="text-white font-semibold">{proposal.amount} ETH</p>
                        </div>
                        <div>
                          <p className="text-gray-400 text-sm">Recipient</p>
                          <p className="text-white font-mono text-sm">{formatAddress(proposal.recipient)}</p>
                        </div>
                        <div>
                          <p className="text-gray-400 text-sm">Approvals</p>
                          <p className="text-white font-semibold">{proposal.approvalCount} / {approvalThreshold}</p>
                        </div>
                        <div>
                          <p className="text-gray-400 text-sm">Rejections</p>
                          <p className="text-white font-semibold">{proposal.rejectionCount}</p>
                        </div>
                      </div>
                      
                      {proposal.state === 3 && proposal.timelockRemaining > 0 && (
                        <div className="bg-yellow-500/20 border border-yellow-500/50 rounded-lg p-3 mb-4">
                          <div className="flex items-center gap-2">
                            <Lock className="w-4 h-4 text-yellow-400" />
                            <span className="text-yellow-200 text-sm">Time-lock remaining: {formatTimeRemaining(proposal.timelockRemaining)}</span>
                          </div>
                        </div>
                      )}
                      
                      <div className="flex flex-wrap gap-2">
                        {canVote && proposal.userVote === 0 && (
                          <>
                            <button
                              onClick={() => approveProposal(proposal.id)}
                              disabled={loading}
                              className="px-4 py-2 bg-green-600 hover:bg-green-700 rounded-lg text-white font-semibold transition-all flex items-center gap-2 disabled:opacity-50"
                            >
                              <CheckCircle className="w-4 h-4" />
                              Approve
                            </button>
                            <button
                              onClick={() => rejectProposal(proposal.id)}
                              disabled={loading}
                              className="px-4 py-2 bg-red-600 hover:bg-red-700 rounded-lg text-white font-semibold transition-all flex items-center gap-2 disabled:opacity-50"
                            >
                              <XCircle className="w-4 h-4" />
                              Reject
                            </button>
                          </>
                        )}
                        
                        {canVote && proposal.userVote === 1 && (
                          <div className="px-4 py-2 bg-green-500/20 border border-green-500/50 rounded-lg text-green-200 flex items-center gap-2">
                            <CheckCircle className="w-4 h-4" />
                            You approved this
                          </div>
                        )}
                        
                        {canVote && proposal.userVote === 2 && (
                          <div className="px-4 py-2 bg-red-500/20 border border-red-500/50 rounded-lg text-red-200 flex items-center gap-2">
                            <XCircle className="w-4 h-4" />
                            You rejected this
                          </div>
                        )}
                        
                        {canExecute && (
                          <button
                            onClick={() => executeProposal(proposal.id)}
                            disabled={loading}
                            className="px-4 py-2 bg-purple-600 hover:bg-purple-700 rounded-lg text-white font-semibold transition-all flex items-center gap-2 disabled:opacity-50"
                          >
                            <Send className="w-4 h-4" />
                            Execute
                          </button>
                        )}
                        
                        {canCancel && (
                          <button
                            onClick={() => cancelProposal(proposal.id)}
                            disabled={loading}
                            className="px-4 py-2 bg-gray-600 hover:bg-gray-700 rounded-lg text-white font-semibold transition-all disabled:opacity-50"
                          >
                            Cancel
                          </button>
                        )}
                      </div>
                      
                      <div className="mt-4 pt-4 border-t border-white/10 text-sm text-gray-400">
                        <div className="grid grid-cols-2 md:grid-cols-3 gap-2">
                          <div>Created: {formatDate(proposal.createdAt)}</div>
                          {proposal.queuedAt > 0 && <div>Queued: {formatDate(proposal.queuedAt)}</div>}
                          {proposal.executedAt > 0 && <div>Executed: {formatDate(proposal.executedAt)}</div>}
                        </div>
                      </div>
                    </div>
                  );
                })}
                
                {proposals.length === 0 && (
                  <div className="text-center py-12">
                    <Clock className="w-16 h-16 text-gray-600 mx-auto mb-4" />
                    <p className="text-gray-400">No proposals yet</p>
                  </div>
                )}
              </div>
            )}

            {/* Create Proposal Tab */}
            {activeTab === 'create' && (
              <div className="bg-white/5 backdrop-blur-lg rounded-2xl border border-white/10 p-6">
                <h2 className="text-2xl font-bold text-white mb-6">Create New Proposal</h2>
                
                {!userRoles.isProposer ? (
                  <div className="bg-red-500/20 border border-red-500/50 rounded-lg p-4">
                    <AlertCircle className="w-5 h-5 text-red-400 mb-2" />
                    <p className="text-red-200">You don't have permission to create proposals</p>
                  </div>
                ) : (
                  <div className="space-y-4">
                    <div>
                      <label className="block text-gray-400 text-sm mb-2">Recipient Address</label>
                      <input
                        type="text"
                        placeholder="0x..."
                        value={newProposal.recipient}
                        onChange={(e) => setNewProposal({...newProposal, recipient: e.target.value})}
                        className="w-full px-4 py-3 bg-white/10 border border-white/20 rounded-lg text-white placeholder-gray-400 focus:outline-none focus:ring-2 focus:ring-purple-500"
                      />
                    </div>
                    
                    <div>
                      <label className="block text-gray-400 text-sm mb-2">Token Address (0x0...0 for ETH)</label>
                      <input
                        type="text"
                        placeholder="0x0000000000000000000000000000000000000000"
                        value={newProposal.token}
                        onChange={(e) => setNewProposal({...newProposal, token: e.target.value})}
                        className="w-full px-4 py-3 bg-white/10 border border-white/20 rounded-lg text-white placeholder-gray-400 focus:outline-none focus:ring-2 focus:ring-purple-500"
                      />
                    </div>
                    
                    <div>
                      <label className="block text-gray-400 text-sm mb-2">Amount (ETH)</label>
                      <input
                        type="number"
                        step="0.01"
                        placeholder="0.0"
                        value={newProposal.amount}
                        onChange={(e) => setNewProposal({...newProposal, amount: e.target.value})}
                        className="w-full px-4 py-3 bg-white/10 border border-white/20 rounded-lg text-white placeholder-gray-400 focus:outline-none focus:ring-2 focus:ring-purple-500"
                      />
                      <p className="text-gray-500 text-sm mt-1">Available: {treasuryBalance} ETH</p>
                    </div>
                    
                    <div>
                      <label className="block text-gray-400 text-sm mb-2">Description</label>
                      <textarea
                        placeholder="Describe the purpose of this proposal..."
                        value={newProposal.description}
                        onChange={(e) => setNewProposal({...newProposal, description: e.target.value})}
                        rows={4}
                        className="w-full px-4 py-3 bg-white/10 border border-white/20 rounded-lg text-white placeholder-gray-400 focus:outline-none focus:ring-2 focus:ring-purple-500"
                      />
                    </div>
                    
                    <button
                      onClick={createProposal}
                      disabled={loading || !newProposal.recipient || !newProposal.amount || !newProposal.description}
                      className="w-full px-6 py-3 bg-gradient-to-r from-purple-600 to-pink-600 rounded-lg font-semibold text-white hover:from-purple-700 hover:to-pink-700 transition-all disabled:opacity-50 flex items-center justify-center gap-2"
                    >
                      <Plus className="w-5 h-5" />
                      {loading ? 'Creating...' : 'Create Proposal'}
                    </button>
                  </div>
                )}
              </div>
            )}

            {/* Admin Tab */}
            {activeTab === 'admin' && (
              <div className="space-y-6">
                <h2 className="text-2xl font-bold text-white">Admin Panel</h2>
                
                {!userRoles.isAdmin ? (
                  <div className="bg-red-500/20 border border-red-500/50 rounded-lg p-4">
                    <AlertCircle className="w-5 h-5 text-red-400 mb-2" />
                    <p className="text-red-200">You don't have admin permissions</p>
                  </div>
                ) : (
                  <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                    {/* Contract Info */}
                    <div className="bg-white/5 backdrop-blur-lg rounded-2xl border border-white/10 p-6">
                      <h3 className="text-xl font-bold text-white mb-4 flex items-center gap-2">
                        <Settings className="w-5 h-5" />
                        Contract Settings
                      </h3>
                      <div className="space-y-3">
                        <div className="flex justify-between items-center">
                          <span className="text-gray-400">Contract Address</span>
                          <span className="text-white font-mono text-sm">{formatAddress(vaultAddress)}</span>
                        </div>
                        <div className="flex justify-between items-center">
                          <span className="text-gray-400">Approval Threshold</span>
                          <span className="text-white font-semibold">{approvalThreshold}</span>
                        </div>
                        <div className="flex justify-between items-center">
                          <span className="text-gray-400">Total Signers</span>
                          <span className="text-white font-semibold">{signerCount}</span>
                        </div>
                        <div className="flex justify-between items-center">
                          <span className="text-gray-400">Time Lock</span>
                          <span className="text-white font-semibold">2 days</span>
                        </div>
                        <div className="flex justify-between items-center">
                          <span className="text-gray-400">Voting Period</span>
                          <span className="text-white font-semibold">7 days</span>
                        </div>
                      </div>
                    </div>
                    
                    {/* Quick Actions */}
                    <div className="bg-white/5 backdrop-blur-lg rounded-2xl border border-white/10 p-6">
                      <h3 className="text-xl font-bold text-white mb-4">Quick Actions</h3>
                      <div className="space-y-3">
                        <button
                          onClick={() => {
                            const address = prompt('Enter signer address to add:');
                            if (address) {
                              contract.addSigner(address).then(tx => tx.wait()).then(() => {
                                setSuccess('Signer added!');
                                loadContractData();
                              }).catch(e => setError(e.message));
                            }
                          }}
                          className="w-full px-4 py-2 bg-green-600 hover:bg-green-700 rounded-lg text-white font-semibold transition-all"
                        >
                          Add Signer
                        </button>
                        
                        <button
                          onClick={() => {
                            const threshold = prompt('Enter new approval threshold:');
                            if (threshold) {
                              contract.updateApprovalThreshold(threshold).then(tx => tx.wait()).then(() => {
                                setSuccess('Threshold updated!');
                                loadContractData();
                              }).catch(e => setError(e.message));
                            }
                          }}
                          className="w-full px-4 py-2 bg-blue-600 hover:bg-blue-700 rounded-lg text-white font-semibold transition-all"
                        >
                          Update Threshold
                        </button>
                        
                        <button
                          onClick={() => {
                            if (window.confirm('Are you sure you want to pause the contract?')) {
                              contract.pause().then(tx => tx.wait()).then(() => {
                                setSuccess('Contract paused!');
                              }).catch(e => setError(e.message));
                            }
                          }}
                          className="w-full px-4 py-2 bg-orange-600 hover:bg-orange-700 rounded-lg text-white font-semibold transition-all"
                        >
                          Pause Contract
                        </button>
                        
                        <button
                          onClick={() => {
                            contract.unpause().then(tx => tx.wait()).then(() => {
                              setSuccess('Contract unpaused!');
                            }).catch(e => setError(e.message));
                          }}
                          className="w-full px-4 py-2 bg-green-600 hover:bg-green-700 rounded-lg text-white font-semibold transition-all"
                        >
                          Unpause Contract
                        </button>
                      </div>
                    </div>
                  </div>
                )}
              </div>
            )}
          </>
        )}
      </div>

      {/* Footer */}
      <div className="mt-12 pb-8 text-center text-gray-500 text-sm">
        <p>VaultGuard Multi-Signature Treasury • Secured by Time-Locks & M-of-N Approvals</p>
        <p className="mt-1">Always verify contract addresses and transactions before signing</p>
      </div>
    </div>
  );
};

export default VaultGuardDApp;