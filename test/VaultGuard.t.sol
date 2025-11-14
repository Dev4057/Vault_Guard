// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/VaultGuard.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/**
 * @title Mock ERC20 Token for testing
 */
contract MockERC20 is ERC20 {
    constructor() ERC20("Mock Token", "MOCK") {
        _mint(msg.sender, 1000000 * 10**18);
    }

    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }
}

/**
 * @title VaultGuard Test Suite
 */
contract VaultGuardTest is Test {
    VaultGuard public vault;
    MockERC20 public token;

    address public admin = address(1);
    address public signer1 = address(2);
    address public signer2 = address(3);
    address public signer3 = address(4);
    address public signer4 = address(5);
    address public signer5 = address(6);
    address public recipient = address(7);
    address public nonSigner = address(8);

    address[] public signers;
    uint256 public constant APPROVAL_THRESHOLD = 3;
    uint256 public constant TIME_LOCK_PERIOD = 2 days;

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

    event ProposalQueued(
        uint256 indexed proposalId,
        uint256 executionTime
    );

    event ProposalExecuted(
        uint256 indexed proposalId,
        address indexed executor
    );

    function setUp() public {
        // Setup signers
        signers.push(signer1);
        signers.push(signer2);
        signers.push(signer3);
        signers.push(signer4);
        signers.push(signer5);

        // Deploy contracts
        vm.startPrank(admin);
        vault = new VaultGuard(signers, APPROVAL_THRESHOLD);
        token = new MockERC20();
        vm.stopPrank();

        // Fund vault with ETH
        vm.deal(address(vault), 100 ether);

        // Fund vault with tokens
        vm.prank(admin);
        token.transfer(address(vault), 10000 * 10**18);

        // Label addresses for better trace output
        vm.label(admin, "Admin");
        vm.label(signer1, "Signer1");
        vm.label(signer2, "Signer2");
        vm.label(signer3, "Signer3");
        vm.label(recipient, "Recipient");
        vm.label(address(vault), "VaultGuard");
    }

    // ========== DEPLOYMENT TESTS ==========

    function test_Deployment() public view {
        assertEq(vault.approvalThreshold(), APPROVAL_THRESHOLD);
        assertEq(vault.signerCount(), 5);
        assertTrue(vault.hasRole(vault.SIGNER_ROLE(), signer1));
        assertTrue(vault.hasRole(vault.ADMIN_ROLE(), admin));
    }

    function test_RevertDeploymentZeroThreshold() public {
        address[] memory testSigners = new address[](3);
        testSigners[0] = address(10);
        testSigners[1] = address(11);
        testSigners[2] = address(12);

        vm.expectRevert(VaultGuard.InvalidThreshold.selector);
        new VaultGuard(testSigners, 0);
    }

    function test_RevertDeploymentThresholdTooHigh() public {
        address[] memory testSigners = new address[](3);
        testSigners[0] = address(10);
        testSigners[1] = address(11);
        testSigners[2] = address(12);

        vm.expectRevert(VaultGuard.InvalidThreshold.selector);
        new VaultGuard(testSigners, 4);
    }

    // ========== TREASURY TESTS ==========

    function test_ReceiveETH() public {
        uint256 balanceBefore = address(vault).balance;
        
        vm.deal(address(this), 10 ether);
        (bool success, ) = address(vault).call{value: 10 ether}("");
        
        assertTrue(success);
        assertEq(address(vault).balance, balanceBefore + 10 ether);
    }

    function test_DepositERC20() public {
        uint256 amount = 1000 * 10**18;
        
        vm.startPrank(admin);
        token.approve(address(vault), amount);
        vault.depositERC20(address(token), amount);
        vm.stopPrank();

        assertEq(token.balanceOf(address(vault)), 10000 * 10**18 + amount);
    }

    function test_GetTreasuryBalance() public view {
        assertEq(vault.getTreasuryBalance(address(0)), 100 ether);
        assertEq(vault.getTreasuryBalance(address(token)), 10000 * 10**18);
    }

    // ========== PROPOSAL CREATION TESTS ==========

    function test_CreateProposal() public {
    vm.prank(signer1);
    
    vm.expectEmit(true, true, false, true);
    emit ProposalCreated(0, signer1, recipient, address(0), 1 ether, "Test proposal");
    
    uint256 proposalId = vault.createProposal(
        recipient,
        address(0),
        1 ether,
        "",
        "Test proposal"
    );

    assertEq(proposalId, 0);
    assertEq(vault.proposalCount(), 1);

    (
        uint256 id,
        address proposer,
        address recip,
        address tok,
        uint256 amount,
        string memory description,
        uint256 approvalCount,
        ,,,,
        VaultGuard.ProposalState state
    ) = vault.getProposal(proposalId);

    assertEq(id, 0);
    assertEq(proposer, signer1);
    assertEq(recip, recipient);
    assertEq(tok, address(0));
    assertEq(amount, 1 ether);
    assertEq(description, "Test proposal");
    assertEq(approvalCount, 0);
    assertTrue(state == VaultGuard.ProposalState.Active);
}
    function test_RevertCreateProposalNonProposer() public {
        vm.prank(nonSigner);
        
        vm.expectRevert();
        vault.createProposal(
            recipient,
            address(0),
            1 ether,
            "",
            "Test proposal"
        );
    }

    function test_RevertCreateProposalZeroAddress() public {
        vm.prank(signer1);
        
        vm.expectRevert(VaultGuard.InvalidAddress.selector);
        vault.createProposal(
            address(0),
            address(0),
            1 ether,
            "",
            "Test proposal"
        );
    }

    function test_RevertCreateProposalZeroAmount() public {
        vm.prank(signer1);
        
        vm.expectRevert(VaultGuard.InvalidAmount.selector);
        vault.createProposal(
            recipient,
            address(0),
            0,
            "",
            "Test proposal"
        );
    }

    function test_RevertCreateProposalInsufficientBalance() public {
        vm.prank(signer1);
        
        vm.expectRevert(VaultGuard.InsufficientBalance.selector);
        vault.createProposal(
            recipient,
            address(0),
            1000 ether, // More than treasury has
            "",
            "Test proposal"
        );
    }

    // ========== VOTING TESTS ==========

    function test_ApproveProposal() public {
        // Create proposal
        vm.prank(signer1);
        uint256 proposalId = vault.createProposal(
            recipient,
            address(0),
            1 ether,
            "",
            "Test proposal"
        );

        // Approve by signer2
        vm.prank(signer2);
        vm.expectEmit(true, true, false, true);
        emit ProposalApproved(proposalId, signer2, 1);
        vault.approve(proposalId);

        (, , , , , , uint256 approvalCount, , , , , ) = vault.getProposal(proposalId);
        assertEq(approvalCount, 1);
        
        assertEq(uint(vault.getVote(proposalId, signer2)), uint(VaultGuard.VoteType.Approve));
    }

    function test_RejectProposal() public {
        // Create proposal
        vm.prank(signer1);
        uint256 proposalId = vault.createProposal(
            recipient,
            address(0),
            1 ether,
            "",
            "Test proposal"
        );

        // Reject by signer2
        vm.prank(signer2);
        vault.reject(proposalId);

        (, , , , , , , uint256 rejectionCount, , , , ) = vault.getProposal(proposalId);
        assertEq(rejectionCount, 1);
    }

    function test_ChangeVote() public {
        // Create proposal
        vm.prank(signer1);
        uint256 proposalId = vault.createProposal(
            recipient,
            address(0),
            1 ether,
            "",
            "Test proposal"
        );

        // First approve
        vm.prank(signer2);
        vault.approve(proposalId);

        (, , , , , , uint256 approvalCount1, , , , , ) = vault.getProposal(proposalId);
        assertEq(approvalCount1, 1);

        // Change to reject
        vm.prank(signer2);
        vault.reject(proposalId);

        (, , , , , , uint256 approvalCount2, uint256 rejectionCount, , , , ) = vault.getProposal(proposalId);
        assertEq(approvalCount2, 0);
        assertEq(rejectionCount, 1);
    }

    function test_RevertVoteNonSigner() public {
        vm.prank(signer1);
        uint256 proposalId = vault.createProposal(
            recipient,
            address(0),
            1 ether,
            "",
            "Test proposal"
        );

        vm.prank(nonSigner);
        vm.expectRevert(VaultGuard.NotSigner.selector);
        vault.approve(proposalId);
    }

    // ========== QUEUING TESTS ==========

    function test_AutoQueueWhenThresholdMet() public {
        // Create proposal
        vm.prank(signer1);
        uint256 proposalId = vault.createProposal(
            recipient,
            address(0),
            1 ether,
            "",
            "Test proposal"
        );

        // Get 3 approvals (threshold)
        vm.prank(signer2);
        vault.approve(proposalId);

        vm.prank(signer3);
        vault.approve(proposalId);

        // Third approval should auto-queue
        vm.prank(signer4);
        vm.expectEmit(true, false, false, false);
        emit ProposalQueued(proposalId, block.timestamp + TIME_LOCK_PERIOD);
        vault.approve(proposalId);

        assertEq(uint(vault.getProposalState(proposalId)), uint(VaultGuard.ProposalState.Queued));
    }

    function test_AutoRejectWhenThresholdMet() public {
        // Create proposal
        vm.prank(signer1);
        uint256 proposalId = vault.createProposal(
            recipient,
            address(0),
            1 ether,
            "",
            "Test proposal"
        );

        // Rejection threshold is signerCount - approvalThreshold + 1 = 5 - 3 + 1 = 3
        vm.prank(signer2);
        vault.reject(proposalId);

        vm.prank(signer3);
        vault.reject(proposalId);

        vm.prank(signer4);
        vault.reject(proposalId);

        assertEq(uint(vault.getProposalState(proposalId)), uint(VaultGuard.ProposalState.Rejected));
    }

    // ========== EXECUTION TESTS ==========

    function test_ExecuteProposal() public {
        // Create and approve proposal
        vm.prank(signer1);
        uint256 proposalId = vault.createProposal(
            recipient,
            address(0),
            1 ether,
            "",
            "Test proposal"
        );

        // Get approvals to queue it
        vm.prank(signer2);
        vault.approve(proposalId);
        vm.prank(signer3);
        vault.approve(proposalId);
        vm.prank(signer4);
        vault.approve(proposalId);

        // Fast forward past time-lock
        vm.warp(block.timestamp + TIME_LOCK_PERIOD + 1);

        // Check state is executable
        assertEq(uint(vault.getProposalState(proposalId)), uint(VaultGuard.ProposalState.Executable));

        // Execute
        uint256 recipientBalanceBefore = recipient.balance;
        
        vm.prank(signer1);
        vm.expectEmit(true, true, false, false);
        emit ProposalExecuted(proposalId, signer1);
        vault.executeProposal(proposalId);

        assertEq(recipient.balance, recipientBalanceBefore + 1 ether);
        assertEq(uint(vault.getProposalState(proposalId)), uint(VaultGuard.ProposalState.Executed));
    }

    function test_ExecuteProposalERC20() public {
        uint256 amount = 100 * 10**18;

        // Create and approve proposal
        vm.prank(signer1);
        uint256 proposalId = vault.createProposal(
            recipient,
            address(token),
            amount,
            "",
            "ERC20 transfer"
        );

        // Get approvals
        vm.prank(signer2);
        vault.approve(proposalId);
        vm.prank(signer3);
        vault.approve(proposalId);
        vm.prank(signer4);
        vault.approve(proposalId);

        // Fast forward
        vm.warp(block.timestamp + TIME_LOCK_PERIOD + 1);

        // Execute
        uint256 recipientBalanceBefore = token.balanceOf(recipient);
        
        vm.prank(signer1);
        vault.executeProposal(proposalId);

        assertEq(token.balanceOf(recipient), recipientBalanceBefore + amount);
    }

    function test_RevertExecuteBeforeTimeLock() public {
        // Create and approve proposal
        vm.prank(signer1);
        uint256 proposalId = vault.createProposal(
            recipient,
            address(0),
            1 ether,
            "",
            "Test proposal"
        );

        vm.prank(signer2);
        vault.approve(proposalId);
        vm.prank(signer3);
        vault.approve(proposalId);
        vm.prank(signer4);
        vault.approve(proposalId);

        // Try to execute immediately
        vm.prank(signer1);
        vm.expectRevert(VaultGuard.NotInCorrectState.selector);
        vault.executeProposal(proposalId);
    }

    function test_RevertExecuteAfterWindow() public {
        // Create and approve proposal
        vm.prank(signer1);
        uint256 proposalId = vault.createProposal(
            recipient,
            address(0),
            1 ether,
            "",
            "Test proposal"
        );

        vm.prank(signer2);
        vault.approve(proposalId);
        vm.prank(signer3);
        vault.approve(proposalId);
        vm.prank(signer4);
        vault.approve(proposalId);

        // Fast forward past execution window
        vm.warp(block.timestamp + TIME_LOCK_PERIOD + 4 days);

        // Try to execute
        vm.prank(signer1);
        vm.expectRevert(VaultGuard.ExecutionWindowExpired.selector);
        vault.executeProposal(proposalId);
    }

    // ========== CANCELLATION TESTS ==========

    function test_CancelProposal() public {
        // Create proposal
        vm.prank(signer1);
        uint256 proposalId = vault.createProposal(
            recipient,
            address(0),
            1 ether,
            "",
            "Test proposal"
        );

        // Cancel as admin
        vm.prank(admin);
        vault.cancelProposal(proposalId);

        assertEq(uint(vault.getProposalState(proposalId)), uint(VaultGuard.ProposalState.Cancelled));
    }

    function test_CancelQueuedProposal() public {
        // Create and approve proposal
        vm.prank(signer1);
        uint256 proposalId = vault.createProposal(
            recipient,
            address(0),
            1 ether,
            "",
            "Test proposal"
        );

        vm.prank(signer2);
        vault.approve(proposalId);
        vm.prank(signer3);
        vault.approve(proposalId);
        vm.prank(signer4);
        vault.approve(proposalId);

        // Should be queued
        assertEq(uint(vault.getProposalState(proposalId)), uint(VaultGuard.ProposalState.Queued));

        // Cancel
        vm.prank(admin);
        vault.cancelProposal(proposalId);

        assertEq(uint(vault.getProposalState(proposalId)), uint(VaultGuard.ProposalState.Cancelled));
    }

    function test_RevertCancelExecutedProposal() public {
        // Create, approve, and execute proposal
        vm.prank(signer1);
        uint256 proposalId = vault.createProposal(
            recipient,
            address(0),
            1 ether,
            "",
            "Test proposal"
        );

        vm.prank(signer2);
        vault.approve(proposalId);
        vm.prank(signer3);
        vault.approve(proposalId);
        vm.prank(signer4);
        vault.approve(proposalId);

        vm.warp(block.timestamp + TIME_LOCK_PERIOD + 1);
        
        vm.prank(signer1);
        vault.executeProposal(proposalId);

        // Try to cancel executed proposal
        vm.prank(admin);
        vm.expectRevert(VaultGuard.NotInCorrectState.selector);
        vault.cancelProposal(proposalId);
    }

    // ========== ADMIN TESTS ==========

    function test_AddSigner() public {
        address newSigner = address(100);
        
        vm.prank(admin);
        vault.addSigner(newSigner);

        assertTrue(vault.hasRole(vault.SIGNER_ROLE(), newSigner));
        assertEq(vault.signerCount(), 6);
    }

    function test_RemoveSigner() public {
        vm.prank(admin);
        vault.removeSigner(signer5);

        assertFalse(vault.hasRole(vault.SIGNER_ROLE(), signer5));
        assertEq(vault.signerCount(), 4);
    }

    function test_RevertRemoveSignerBelowThreshold() public {
        // Remove signers until we're at threshold
        vm.startPrank(admin);
        vault.removeSigner(signer5);
        vault.removeSigner(signer4);

        // Now signerCount = 3, threshold = 3
        // Can't remove more
        vm.expectRevert(VaultGuard.InvalidThreshold.selector);
        vault.removeSigner(signer3);
        vm.stopPrank();
    }

    function test_UpdateThreshold() public {
        vm.prank(admin);
        vault.updateApprovalThreshold(4);

        assertEq(vault.approvalThreshold(), 4);
    }

    function test_RevertUpdateThresholdTooHigh() public {
        vm.prank(admin);
        vm.expectRevert(VaultGuard.InvalidThreshold.selector);
        vault.updateApprovalThreshold(6); // More than signerCount
    }

    function test_RevertUpdateThresholdZero() public {
        vm.prank(admin);
        vm.expectRevert(VaultGuard.InvalidThreshold.selector);
        vault.updateApprovalThreshold(0);
    }

    // ========== PAUSE TESTS ==========

    function test_Pause() public {
        vm.prank(admin);
        vault.pause();

        // Try to create proposal while paused
        vm.prank(signer1);
        vm.expectRevert();
        vault.createProposal(
            recipient,
            address(0),
            1 ether,
            "",
            "Test proposal"
        );
    }

    function test_Unpause() public {
        vm.prank(admin);
        vault.pause();

        vm.prank(admin);
        vault.unpause();

        // Should work now
        vm.prank(signer1);
        vault.createProposal(
            recipient,
            address(0),
            1 ether,
            "",
            "Test proposal"
        );
    }

    function test_EmergencyWithdraw() public {
        // Pause first
        vm.prank(admin);
        vault.pause();

        uint256 amount = 10 ether;
        uint256 adminBalanceBefore = admin.balance;

        vm.prank(admin);
        vault.emergencyWithdraw(address(0), admin, amount);

        assertEq(admin.balance, adminBalanceBefore + amount);
    }

    // ========== HELPER VIEW FUNCTION TESTS ==========

    function test_GetTimeLockRemaining() public {
        // Create and queue proposal
        vm.prank(signer1);
        uint256 proposalId = vault.createProposal(
            recipient,
            address(0),
            1 ether,
            "",
            "Test proposal"
        );

        vm.prank(signer2);
        vault.approve(proposalId);
        vm.prank(signer3);
        vault.approve(proposalId);
        vm.prank(signer4);
        vault.approve(proposalId);

        // Should have time remaining
        uint256 remaining = vault.getTimeLockRemaining(proposalId);
        assertGt(remaining, 0);
        assertLe(remaining, TIME_LOCK_PERIOD);

        // Fast forward
        vm.warp(block.timestamp + TIME_LOCK_PERIOD + 1);

        // Should be 0
        assertEq(vault.getTimeLockRemaining(proposalId), 0);
    }

    // ========== EDGE CASE TESTS ==========

    function test_VotingPeriodExpiration() public {
        // Create proposal
        vm.prank(signer1);
        uint256 proposalId = vault.createProposal(
            recipient,
            address(0),
            1 ether,
            "",
            "Test proposal"
        );

        // Fast forward past voting period
        vm.warp(block.timestamp + 8 days);

        // State should be expired
        assertEq(uint(vault.getProposalState(proposalId)), uint(VaultGuard.ProposalState.Expired));

        // Can't vote anymore
        vm.prank(signer2);
        vm.expectRevert(VaultGuard.VotingPeriodExpired.selector);
        vault.approve(proposalId);
    }

    function test_MultipleProposals() public {
        // Create multiple proposals
        vm.startPrank(signer1);
        uint256 id1 = vault.createProposal(recipient, address(0), 1 ether, "", "Proposal 1");
        uint256 id2 = vault.createProposal(recipient, address(0), 2 ether, "", "Proposal 2");
        uint256 id3 = vault.createProposal(recipient, address(0), 3 ether, "", "Proposal 3");
        vm.stopPrank();

        assertEq(id1, 0);
        assertEq(id2, 1);
        assertEq(id3, 2);
        assertEq(vault.proposalCount(), 3);
    }

    function test_MaxActiveProposalsPerAddress() public {
        // Create max proposals
        vm.startPrank(signer1);
        for (uint256 i = 0; i < 5; i++) {
            vault.createProposal(recipient, address(0), 1 ether, "", "Proposal");
        }

        // Next one should fail
        vm.expectRevert(VaultGuard.TooManyActiveProposals.selector);
        vault.createProposal(recipient, address(0), 1 ether, "", "Proposal");
        vm.stopPrank();
    }
}