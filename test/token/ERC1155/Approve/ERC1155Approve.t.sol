// SPDX-License-Identifier: MIT
pragma solidity >=0.8.30;

/* Compose
 * https://compose.diamonds
 */

import {Base_Test} from "test/Base.t.sol";
import {ERC1155ApproveHarness} from "./harnesses/ERC1155ApproveHarness.sol";
import "src/token/ERC1155/Approve/ERC1155ApproveMod.sol" as ApproveMod;

/**
 * @title ERC1155Approve_Base_Test
 * @notice Base test contract for ERC1155 Approve tests
 */
abstract contract ERC1155Approve_Base_Test is Base_Test {
    ERC1155ApproveHarness internal harness;

    function setUp() public virtual override {
        Base_Test.setUp();
        vm.stopPrank(); // Cancel persistent prank from Base_Test
        harness = new ERC1155ApproveHarness();
        vm.label(address(harness), "ERC1155ApproveHarness");
    }
}

// =============================================================
//                      MOD TESTS
// =============================================================

/**
 * @title SetApprovalForAll_Mod_Test
 * @notice Tests for the internal setApprovalForAll module function
 */
contract SetApprovalForAll_Mod_Test is ERC1155Approve_Base_Test {
    event ApprovalForAll(address indexed _account, address indexed _operator, bool _approved);

    // ==================== REVERT TESTS ====================

    function test_ShouldRevert_WhenOperatorIsZeroAddress() external {
        vm.expectRevert(abi.encodeWithSelector(ApproveMod.ERC1155InvalidOperator.selector, address(0)));
        harness.setApprovalForAll_Mod(users.alice, ADDRESS_ZERO, true);
    }

    // ==================== SUCCESS TESTS ====================

    function test_ShouldSetApproval_WhenOperatorIsValid() external {
        harness.setApprovalForAll_Mod(users.alice, users.bob, true);
        assertTrue(harness.isApprovedForAll(users.alice, users.bob));
    }

    function test_ShouldEmitApprovalForAllEvent() external {
        vm.expectEmit(true, true, true, true);
        emit ApprovalForAll(users.alice, users.bob, true);
        harness.setApprovalForAll_Mod(users.alice, users.bob, true);
    }

    function test_ShouldRevokeApproval() external {
        harness.setApprovalForAll_Mod(users.alice, users.bob, true);
        assertTrue(harness.isApprovedForAll(users.alice, users.bob));

        harness.setApprovalForAll_Mod(users.alice, users.bob, false);
        assertFalse(harness.isApprovedForAll(users.alice, users.bob));
    }

    function test_ShouldEmitApprovalForAllEvent_WhenRevokingApproval() external {
        harness.setApprovalForAll_Mod(users.alice, users.bob, true);

        vm.expectEmit(true, true, true, true);
        emit ApprovalForAll(users.alice, users.bob, false);
        harness.setApprovalForAll_Mod(users.alice, users.bob, false);
    }

    function test_ShouldAllowMultipleOperators() external {
        harness.setApprovalForAll_Mod(users.alice, users.bob, true);
        harness.setApprovalForAll_Mod(users.alice, users.charlee, true);

        assertTrue(harness.isApprovedForAll(users.alice, users.bob));
        assertTrue(harness.isApprovedForAll(users.alice, users.charlee));
    }

    function test_ShouldNotAffectOtherOwners() external {
        harness.setApprovalForAll_Mod(users.alice, users.bob, true);

        assertTrue(harness.isApprovedForAll(users.alice, users.bob));
        assertFalse(harness.isApprovedForAll(users.charlee, users.bob));
    }

    // ==================== FUZZ TESTS ====================

    function testFuzz_SetApprovalForAll(address owner, address operator, bool approved) external {
        vm.assume(operator != ADDRESS_ZERO);
        harness.setApprovalForAll_Mod(owner, operator, approved);
        assertEq(harness.isApprovedForAll(owner, operator), approved);
    }
}

// =============================================================
//                     FACET TESTS
// =============================================================

/**
 * @title SetApprovalForAll_Facet_Test
 * @notice Tests for the facet-level setApprovalForAll (uses msg.sender)
 */
contract SetApprovalForAll_Facet_Test is ERC1155Approve_Base_Test {
    event ApprovalForAll(address indexed _account, address indexed _operator, bool _approved);

    // ==================== REVERT TESTS ====================

    function test_ShouldRevert_WhenOperatorIsZeroAddress() external {
        vm.prank(users.alice);
        vm.expectRevert(abi.encodeWithSelector(ERC1155ApproveHarness.ERC1155InvalidOperator.selector, address(0)));
        harness.setApprovalForAll(ADDRESS_ZERO, true);
    }

    // ==================== SUCCESS TESTS ====================

    function test_ShouldSetApproval_WhenCalledByOwner() external {
        vm.prank(users.alice);
        harness.setApprovalForAll(users.bob, true);

        assertTrue(harness.isApprovedForAll(users.alice, users.bob));
    }

    function test_ShouldUseMessageSenderAsOwner() external {
        vm.prank(users.alice);
        harness.setApprovalForAll(users.bob, true);

        assertTrue(harness.isApprovedForAll(users.alice, users.bob));
        assertFalse(harness.isApprovedForAll(users.bob, users.alice));
    }

    function test_ShouldEmitApprovalForAllEvent() external {
        vm.expectEmit(true, true, true, true);
        emit ApprovalForAll(users.alice, users.bob, true);

        vm.prank(users.alice);
        harness.setApprovalForAll(users.bob, true);
    }

    function test_ShouldRevokeApproval() external {
        vm.prank(users.alice);
        harness.setApprovalForAll(users.bob, true);

        vm.prank(users.alice);
        harness.setApprovalForAll(users.bob, false);

        assertFalse(harness.isApprovedForAll(users.alice, users.bob));
    }

    // ==================== FUZZ TESTS ====================

    function testFuzz_SetApprovalForAll(address owner, address operator, bool approved) external {
        vm.assume(operator != ADDRESS_ZERO);
        vm.assume(owner != ADDRESS_ZERO);

        vm.prank(owner);
        harness.setApprovalForAll(operator, approved);

        assertEq(harness.isApprovedForAll(owner, operator), approved);
    }
}
