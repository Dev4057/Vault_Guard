// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

/**
 * @title VaultGuard
 * @notice Multi-signature treasury with time-locked spending proposals
 * @dev Implements M-of-N approval with role-based access control
 */
contract VaultGuard is ReentrancyGuard, Pausable, AccessControl {
    using SafeERC20 for IERC20;

    // ========== ROLES ==========
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant SIGNER_ROLE = keccak256("SIGNER_ROLE");
    bytes32 public constant PROPOSER_ROLE = keccak256("PROPOSER_ROLE");
    bytes32 public constant EXECUTOR_ROLE = keccak256("EXECUTOR_ROLE");

    // ========== ENUMS ==========
    enum ProposalState {
        Pending,      // 0 - Just created
        Active,       // 1 - Open for voting
        Approved,     // 2 - Threshold met
        Queued,       // 3 - In time-lock
        Executable,   // 4 - Ready to execute
        Executed,     // 5 - Completed
        Rejected,     // 6 - Rejected by signers
        Cancelled,    // 7 - Manually cancelled
        Expired       // 8 - Voting/execution window expired
    }

    enum VoteType {
        None,
        Approve,
        Reject
    }

    // ========== STRUCTS ==========
    struct Proposal {
        uint256 id;
        address proposer;
        address recipient;
        address token;              // address(0) for ETH
        uint256 amount;
        bytes data;                 // For contract calls
        string description;
        uint256 approvalCount;
        uint256 rejectionCount;
        uint256 createdAt;
        uint256 queuedAt;
        uint256 executedAt;
        ProposalState state;
        bool executed;
    }

    // ========== STATE VARIABLES ==========
    uint256 public proposalCount;
    uint256 public approvalThreshold;
    uint256 public signerCount;
    uint256 public constant TIME_LOCK_PERIOD = 2 days;     // 48 hours
    uint256 public constant VOTING_PERIOD = 7 days;
    uint256 public constant EXECUTION_WINDOW = 3 days;

    mapping(uint256 => Proposal) public proposals;
    mapping(uint256 => mapping(address => VoteType)) public votes;
    
    // Track active proposals per address to prevent spam
    mapping(address => uint256) public activeProposalsByAddress;
    uint256 public constant MAX_ACTIVE_PROPOSALS_PER_ADDRESS = 5;

    // ========== EVENTS ==========
    event ProposalCreated(
        uint256 indexed proposalId,
        address indexed proposer,
        address recipient,
        address token,
        uint256 amount,
        string description
    );
    
    event ProposalApproved(
        uint256 indexed proposalId,
        address indexed signer,
        uint256 approvalCount
    );
    
    event ProposalRejected(
        uint256 indexed proposalId,
        address indexed signer,
        uint256 rejectionCount
    );
    
    event VoteChanged(
        uint256 indexed proposalId,
        address indexed signer,
        VoteType oldVote,
        VoteType newVote
    );
    
    event ProposalQueued(
        uint256 indexed proposalId,
        uint256 executionTime
    );
    
    event ProposalExecuted(
        uint256 indexed proposalId,
        address indexed executor
    );
    
    event ProposalCancelled(
        uint256 indexed proposalId,
        address indexed canceller
    );
    
    event SignerAdded(address indexed signer);
    event SignerRemoved(address indexed signer);
    event ThresholdUpdated(uint256 oldThreshold, uint256 newThreshold);
    
    event Deposit(
        address indexed token,
        address indexed from,
        uint256 amount
    );
    
    event EmergencyWithdraw(
        address indexed token,
        address indexed to,
        uint256 amount
    );

    // ========== ERRORS ==========
    error InvalidThreshold();
    error InvalidAddress();
    error InvalidAmount();
    error ProposalNotFound();
    error AlreadyVoted();
    error NotInCorrectState();
    error TimeLockNotExpired();
    error ExecutionWindowExpired();
    error InsufficientBalance();
    error TransferFailed();
    error TooManyActiveProposals();
    error NotSigner();
    error VotingPeriodExpired();

    // ========== MODIFIERS ==========
    modifier onlyValidProposal(uint256 proposalId) {
        if (proposalId >= proposalCount) revert ProposalNotFound();
        _;
    }

    modifier onlySigner() {
        if (!hasRole(SIGNER_ROLE, msg.sender)) revert NotSigner();
        _;
    }

    // ========== CONSTRUCTOR ==========
    constructor(
        address[] memory _signers,
        uint256 _approvalThreshold
    ) {
        if (_signers.length == 0) revert InvalidAddress();
        if (_approvalThreshold == 0 || _approvalThreshold > _signers.length) {
            revert InvalidThreshold();
        }

        // Setup roles
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(ADMIN_ROLE, msg.sender);

        // Add signers
        for (uint256 i = 0; i < _signers.length; i++) {
            if (_signers[i] == address(0)) revert InvalidAddress();
            _grantRole(SIGNER_ROLE, _signers[i]);
            _grantRole(PROPOSER_ROLE, _signers[i]);
            _grantRole(EXECUTOR_ROLE, _signers[i]);
            emit SignerAdded(_signers[i]);
        }

        signerCount = _signers.length;
        approvalThreshold = _approvalThreshold;
    }

    // ========== RECEIVE FUNCTION ==========
    receive() external payable {
        emit Deposit(address(0), msg.sender, msg.value);
    }

    // ========== TREASURY FUNCTIONS ==========
    
    /**
     * @notice Deposit ERC20 tokens into treasury
     * @param token Token address
     * @param amount Amount to deposit
     */
    function depositERC20(address token, uint256 amount) external {
        if (token == address(0)) revert InvalidAddress();
        if (amount == 0) revert InvalidAmount();

        IERC20(token).safeTransferFrom(msg.sender, address(this), amount);
        emit Deposit(token, msg.sender, amount);
    }

    /**
     * @notice Get treasury balance for a token
     * @param token Token address (address(0) for ETH)
     * @return balance Current balance
     */
    function getTreasuryBalance(address token) external view returns (uint256) {
        if (token == address(0)) {
            return address(this).balance;
        }
        return IERC20(token).balanceOf(address(this));
    }

    // ========== PROPOSAL FUNCTIONS ==========
    
    /**
     * @notice Create a new spending proposal
     * @param recipient Address to receive funds
     * @param token Token address (address(0) for ETH)
     * @param amount Amount to transfer
     * @param data Additional call data for contract interactions
     * @param description Human-readable description
     * @return proposalId ID of created proposal
     */
    function createProposal(
        address recipient,
        address token,
        uint256 amount,
        bytes calldata data,
        string calldata description
    ) external onlyRole(PROPOSER_ROLE) whenNotPaused returns (uint256) {
        if (recipient == address(0)) revert InvalidAddress();
        if (amount == 0) revert InvalidAmount();
        
        // Check active proposal limit
        if (activeProposalsByAddress[msg.sender] >= MAX_ACTIVE_PROPOSALS_PER_ADDRESS) {
            revert TooManyActiveProposals();
        }

        // Check treasury has sufficient balance
        uint256 balance = token == address(0) 
            ? address(this).balance 
            : IERC20(token).balanceOf(address(this));
        
        if (balance < amount) revert InsufficientBalance();

        uint256 proposalId = proposalCount++;

        Proposal storage proposal = proposals[proposalId];
        proposal.id = proposalId;
        proposal.proposer = msg.sender;
        proposal.recipient = recipient;
        proposal.token = token;
        proposal.amount = amount;
        proposal.data = data;
        proposal.description = description;
        proposal.createdAt = block.timestamp;
        proposal.state = ProposalState.Active;

        activeProposalsByAddress[msg.sender]++;

        emit ProposalCreated(
            proposalId,
            msg.sender,
            recipient,
            token,
            amount,
            description
        );

        return proposalId;
    }

    // ========== VOTING FUNCTIONS ==========
    
    /**
     * @notice Approve a proposal
     * @param proposalId ID of proposal to approve
     */
    function approve(uint256 proposalId) 
        external 
        onlyValidProposal(proposalId)
        onlySigner
        whenNotPaused
    {
        _vote(proposalId, VoteType.Approve);
    }

    /**
     * @notice Reject a proposal
     * @param proposalId ID of proposal to reject
     */
    function reject(uint256 proposalId)
        external
        onlyValidProposal(proposalId)
        onlySigner
        whenNotPaused
    {
        _vote(proposalId, VoteType.Reject);
    }

    /**
     * @dev Internal vote function
     * @param proposalId ID of proposal
     * @param voteType Type of vote
     */
    function _vote(uint256 proposalId, VoteType voteType) internal {
        Proposal storage proposal = proposals[proposalId];
        
        // Check if voting period expired
        if (block.timestamp > proposal.createdAt + VOTING_PERIOD) {
            revert VotingPeriodExpired();
        }

        // Only allow voting on Active proposals
        ProposalState currentState = getProposalState(proposalId);
        if (currentState != ProposalState.Active) {
            revert NotInCorrectState();
        }

        VoteType previousVote = votes[proposalId][msg.sender];
        
        // Allow changing vote
        if (previousVote != VoteType.None) {
            // Remove previous vote count
            if (previousVote == VoteType.Approve) {
                proposal.approvalCount--;
            } else if (previousVote == VoteType.Reject) {
                proposal.rejectionCount--;
            }
            
            emit VoteChanged(proposalId, msg.sender, previousVote, voteType);
        }

        // Record new vote
        votes[proposalId][msg.sender] = voteType;

        if (voteType == VoteType.Approve) {
            proposal.approvalCount++;
            emit ProposalApproved(proposalId, msg.sender, proposal.approvalCount);

            // Auto-queue if threshold met
            if (proposal.approvalCount >= approvalThreshold) {
                _queueProposal(proposalId);
            }
        } else if (voteType == VoteType.Reject) {
            proposal.rejectionCount++;
            emit ProposalRejected(proposalId, msg.sender, proposal.rejectionCount);

            // Auto-reject if rejection threshold met
            uint256 rejectionThreshold = signerCount - approvalThreshold + 1;
            if (proposal.rejectionCount >= rejectionThreshold) {
                proposal.state = ProposalState.Rejected;
                activeProposalsByAddress[proposal.proposer]--;
            }
        }
    }

    /**
     * @dev Queue proposal after approval
     * @param proposalId ID of proposal
     */
    function _queueProposal(uint256 proposalId) internal {
        Proposal storage proposal = proposals[proposalId];
        
        proposal.state = ProposalState.Queued;
        proposal.queuedAt = block.timestamp;
        
        emit ProposalQueued(
            proposalId,
            block.timestamp + TIME_LOCK_PERIOD
        );
    }

    // ========== EXECUTION FUNCTIONS ==========
    
    /**
     * @notice Execute an approved proposal after time-lock
     * @param proposalId ID of proposal to execute
     */
    function executeProposal(uint256 proposalId)
        external
        onlyValidProposal(proposalId)
        onlyRole(EXECUTOR_ROLE)
        nonReentrant
        whenNotPaused
    {
        Proposal storage proposal = proposals[proposalId];
             // Check execution window hasn't expired
        if (proposal.state == ProposalState.Queued && 
        block.timestamp > proposal.queuedAt + TIME_LOCK_PERIOD + EXECUTION_WINDOW) {
        proposal.state = ProposalState.Expired;
        activeProposalsByAddress[proposal.proposer]--;
        revert ExecutionWindowExpired();
    } 
        
        ProposalState currentState = getProposalState(proposalId);
        if (currentState != ProposalState.Executable) {
            revert NotInCorrectState();
        }

   

        // Mark as executed
        proposal.state = ProposalState.Executed;
        proposal.executed = true;
        proposal.executedAt = block.timestamp;
        activeProposalsByAddress[proposal.proposer]--;

        // Execute transfer
        bool success;
        if (proposal.token == address(0)) {
            // ETH transfer
            (success, ) = proposal.recipient.call{value: proposal.amount}(proposal.data);
        } else {
            // ERC20 transfer
            if (proposal.data.length > 0) {
                // Contract call with ERC20
                IERC20(proposal.token).safeTransfer(proposal.recipient, proposal.amount);
                (success, ) = proposal.recipient.call(proposal.data);
            } else {
                // Simple ERC20 transfer
                IERC20(proposal.token).safeTransfer(proposal.recipient, proposal.amount);
                success = true;
            }
        }

        if (!success) revert TransferFailed();

        emit ProposalExecuted(proposalId, msg.sender);
    }

    /**
     * @notice Cancel a proposal before execution
     * @param proposalId ID of proposal to cancel
     */
    function cancelProposal(uint256 proposalId)
        external
        onlyValidProposal(proposalId)
        onlyRole(ADMIN_ROLE)
    {
        Proposal storage proposal = proposals[proposalId];
        
        ProposalState currentState = getProposalState(proposalId);
        
        // Can only cancel if not yet executed
        if (currentState == ProposalState.Executed) {
            revert NotInCorrectState();
        }

        proposal.state = ProposalState.Cancelled;
        
        if (currentState == ProposalState.Active || 
            currentState == ProposalState.Queued || 
            currentState == ProposalState.Executable) {
            activeProposalsByAddress[proposal.proposer]--;
        }

        emit ProposalCancelled(proposalId, msg.sender);
    }

    // ========== VIEW FUNCTIONS ==========
    
    /**
     * @notice Get current state of a proposal
     * @param proposalId ID of proposal
     * @return Current state
     */
    function getProposalState(uint256 proposalId)
        public
        view
        onlyValidProposal(proposalId)
        returns (ProposalState)
    {
        Proposal storage proposal = proposals[proposalId];

        // Return terminal states immediately
        if (proposal.state == ProposalState.Executed ||
            proposal.state == ProposalState.Cancelled ||
            proposal.state == ProposalState.Rejected) {
            return proposal.state;
        }

        // Check if voting period expired
        if (block.timestamp > proposal.createdAt + VOTING_PERIOD &&
            proposal.state == ProposalState.Active) {
            return ProposalState.Expired;
        }

        // Check if in queued state
        if (proposal.state == ProposalState.Queued) {
            // Check if time-lock expired
            if (block.timestamp >= proposal.queuedAt + TIME_LOCK_PERIOD) {
                // Check if execution window expired
                if (block.timestamp > proposal.queuedAt + TIME_LOCK_PERIOD + EXECUTION_WINDOW) {
                    return ProposalState.Expired;
                }
                return ProposalState.Executable;
            }
            return ProposalState.Queued;
        }

        return proposal.state;
    }

    /**
     * @notice Get full proposal details
     * @param proposalId ID of proposal
     */
    function getProposal(uint256 proposalId)
        external
        view
        onlyValidProposal(proposalId)
        returns (
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
        )
    {
        Proposal storage p = proposals[proposalId];
        return (
            p.id,
            p.proposer,
            p.recipient,
            p.token,
            p.amount,
            p.description,
            p.approvalCount,
            p.rejectionCount,
            p.createdAt,
            p.queuedAt,
            p.executedAt,
            getProposalState(proposalId)
        );
    }

    /**
     * @notice Check if address has voted on proposal
     * @param proposalId ID of proposal
     * @param voter Address to check
     * @return Vote type
     */
    function getVote(uint256 proposalId, address voter)
        external
        view
        onlyValidProposal(proposalId)
        returns (VoteType)
    {
        return votes[proposalId][voter];
    }

    /**
     * @notice Get time until proposal can be executed
     * @param proposalId ID of proposal
     * @return Seconds until executable (0 if ready or not queued)
     */
    function getTimeLockRemaining(uint256 proposalId)
        external
        view
        onlyValidProposal(proposalId)
        returns (uint256)
    {
        Proposal storage proposal = proposals[proposalId];
        
        if (proposal.state != ProposalState.Queued) {
            return 0;
        }

        uint256 executionTime = proposal.queuedAt + TIME_LOCK_PERIOD;
        if (block.timestamp >= executionTime) {
            return 0;
        }

        return executionTime - block.timestamp;
    }

    // ========== ADMIN FUNCTIONS ==========
    
    /**
     * @notice Add a new signer
     * @param signer Address to add as signer
     */
    function addSigner(address signer) external onlyRole(ADMIN_ROLE) {
        if (signer == address(0)) revert InvalidAddress();
        
        _grantRole(SIGNER_ROLE, signer);
        _grantRole(PROPOSER_ROLE, signer);
        _grantRole(EXECUTOR_ROLE, signer);
        
        signerCount++;
        emit SignerAdded(signer);
    }

    /**
     * @notice Remove a signer
     * @param signer Address to remove
     */
    function removeSigner(address signer) external onlyRole(ADMIN_ROLE) {
        if (signerCount <= approvalThreshold) revert InvalidThreshold();
        
        _revokeRole(SIGNER_ROLE, signer);
        signerCount--;
        
        emit SignerRemoved(signer);
    }

    /**
     * @notice Update approval threshold
     * @param newThreshold New threshold value
     */
    function updateApprovalThreshold(uint256 newThreshold)
        external
        onlyRole(ADMIN_ROLE)
    {
        if (newThreshold == 0 || newThreshold > signerCount) {
            revert InvalidThreshold();
        }

        uint256 oldThreshold = approvalThreshold;
        approvalThreshold = newThreshold;

        emit ThresholdUpdated(oldThreshold, newThreshold);
    }

    /**
     * @notice Pause the contract (emergency)
     */
    function pause() external onlyRole(ADMIN_ROLE) {
        _pause();
    }

    /**
     * @notice Unpause the contract
     */
    function unpause() external onlyRole(ADMIN_ROLE) {
        _unpause();
    }

    /**
     * @notice Emergency withdraw (only if contract is paused)
     * @param token Token to withdraw (address(0) for ETH)
     * @param to Recipient address
     * @param amount Amount to withdraw
     */
    function emergencyWithdraw(
        address token,
        address to,
        uint256 amount
    ) external onlyRole(ADMIN_ROLE) whenPaused {
        if (to == address(0)) revert InvalidAddress();
        if (amount == 0) revert InvalidAmount();

        if (token == address(0)) {
            (bool success, ) = to.call{value: amount}("");
            if (!success) revert TransferFailed();
        } else {
            IERC20(token).safeTransfer(to, amount);
        }

        emit EmergencyWithdraw(token, to, amount);
    }
}