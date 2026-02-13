// SPDX-License-Identifier: MIT
pragma solidity >=0.8.30;

/* Compose
 * https://compose.diamonds
 */

import {Base_Test} from "test/Base.t.sol";
import {ERC1155DataHarness} from "./harnesses/ERC1155DataHarness.sol";
import {ERC1155DataFacet} from "src/token/ERC1155/Data/ERC1155DataFacet.sol";

/**
 * @title ERC1155DataFacet_Base_Test
 * @notice Base test contract for ERC1155DataFacet tests
 */
abstract contract ERC1155DataFacet_Base_Test is Base_Test {
    ERC1155DataHarness internal facet;

    function setUp() public virtual override {
        Base_Test.setUp();
        vm.stopPrank(); // Cancel persistent prank from Base_Test
        facet = new ERC1155DataHarness();
        vm.label(address(facet), "ERC1155DataHarness");
    }

    function _mint(address _to, uint256 _id, uint256 _value) internal {
        facet.mint(_to, _id, _value);
    }
}

// =============================================================
//                       BALANCE OF
// =============================================================

contract BalanceOf_ERC1155DataFacet_Test is ERC1155DataFacet_Base_Test {
    function test_ShouldReturnZero_WhenAccountHasNoBalance() external view {
        assertEq(facet.balanceOf(users.alice, TOKEN_ID_1), 0);
    }

    function test_ShouldReturnCorrectBalance() external {
        _mint(users.alice, TOKEN_ID_1, 100);
        assertEq(facet.balanceOf(users.alice, TOKEN_ID_1), 100);
    }

    function test_ShouldReturnCorrectBalance_AfterMultipleMints() external {
        _mint(users.alice, TOKEN_ID_1, 100);
        _mint(users.alice, TOKEN_ID_1, 50);
        assertEq(facet.balanceOf(users.alice, TOKEN_ID_1), 150);
    }

    function test_ShouldReturnDifferentBalances_ForDifferentTokenIds() external {
        _mint(users.alice, TOKEN_ID_1, 100);
        _mint(users.alice, TOKEN_ID_2, 200);
        assertEq(facet.balanceOf(users.alice, TOKEN_ID_1), 100);
        assertEq(facet.balanceOf(users.alice, TOKEN_ID_2), 200);
    }

    function test_ShouldReturnDifferentBalances_ForDifferentAccounts() external {
        _mint(users.alice, TOKEN_ID_1, 100);
        _mint(users.bob, TOKEN_ID_1, 200);
        assertEq(facet.balanceOf(users.alice, TOKEN_ID_1), 100);
        assertEq(facet.balanceOf(users.bob, TOKEN_ID_1), 200);
    }

    function testFuzz_BalanceOf(address account, uint256 id, uint256 amount) external {
        vm.assume(account != ADDRESS_ZERO);
        _mint(account, id, amount);
        assertEq(facet.balanceOf(account, id), amount);
    }
}

// =============================================================
//                    BALANCE OF BATCH
// =============================================================

contract BalanceOfBatch_ERC1155DataFacet_Test is ERC1155DataFacet_Base_Test {
    // ==================== REVERT TESTS ====================

    function test_ShouldRevert_WhenArrayLengthMismatch() external {
        address[] memory accounts = new address[](2);
        accounts[0] = users.alice;
        accounts[1] = users.bob;
        uint256[] memory ids = new uint256[](1);
        ids[0] = TOKEN_ID_1;

        vm.expectRevert(abi.encodeWithSelector(ERC1155DataFacet.ERC1155InvalidArrayLength.selector, 1, 2));
        facet.balanceOfBatch(accounts, ids);
    }

    // ==================== SUCCESS TESTS ====================

    function test_ShouldReturnEmptyArray_WhenInputIsEmpty() external view {
        address[] memory accounts = new address[](0);
        uint256[] memory ids = new uint256[](0);
        uint256[] memory balances = facet.balanceOfBatch(accounts, ids);
        assertEq(balances.length, 0);
    }

    function test_ShouldReturnZeros_WhenNoBalances() external view {
        address[] memory accounts = new address[](2);
        accounts[0] = users.alice;
        accounts[1] = users.bob;
        uint256[] memory ids = new uint256[](2);
        ids[0] = TOKEN_ID_1;
        ids[1] = TOKEN_ID_2;

        uint256[] memory balances = facet.balanceOfBatch(accounts, ids);
        assertEq(balances.length, 2);
        assertEq(balances[0], 0);
        assertEq(balances[1], 0);
    }

    function test_ShouldReturnCorrectBalances() external {
        _mint(users.alice, TOKEN_ID_1, 100);
        _mint(users.bob, TOKEN_ID_2, 200);

        address[] memory accounts = new address[](2);
        accounts[0] = users.alice;
        accounts[1] = users.bob;
        uint256[] memory ids = new uint256[](2);
        ids[0] = TOKEN_ID_1;
        ids[1] = TOKEN_ID_2;

        uint256[] memory balances = facet.balanceOfBatch(accounts, ids);
        assertEq(balances[0], 100);
        assertEq(balances[1], 200);
    }

    function test_ShouldReturnCorrectBalances_ForSameAccountDifferentTokens() external {
        _mint(users.alice, TOKEN_ID_1, 100);
        _mint(users.alice, TOKEN_ID_2, 200);
        _mint(users.alice, TOKEN_ID_3, 300);

        address[] memory accounts = new address[](3);
        accounts[0] = users.alice;
        accounts[1] = users.alice;
        accounts[2] = users.alice;
        uint256[] memory ids = new uint256[](3);
        ids[0] = TOKEN_ID_1;
        ids[1] = TOKEN_ID_2;
        ids[2] = TOKEN_ID_3;

        uint256[] memory balances = facet.balanceOfBatch(accounts, ids);
        assertEq(balances[0], 100);
        assertEq(balances[1], 200);
        assertEq(balances[2], 300);
    }

    function test_ShouldReturnCorrectBalances_ForDifferentAccountsSameToken() external {
        _mint(users.alice, TOKEN_ID_1, 100);
        _mint(users.bob, TOKEN_ID_1, 200);
        _mint(users.charlee, TOKEN_ID_1, 300);

        address[] memory accounts = new address[](3);
        accounts[0] = users.alice;
        accounts[1] = users.bob;
        accounts[2] = users.charlee;
        uint256[] memory ids = new uint256[](3);
        ids[0] = TOKEN_ID_1;
        ids[1] = TOKEN_ID_1;
        ids[2] = TOKEN_ID_1;

        uint256[] memory balances = facet.balanceOfBatch(accounts, ids);
        assertEq(balances[0], 100);
        assertEq(balances[1], 200);
        assertEq(balances[2], 300);
    }
}

// =============================================================
//                    IS APPROVED FOR ALL
// =============================================================

contract IsApprovedForAll_ERC1155DataFacet_Test is ERC1155DataFacet_Base_Test {
    function test_ShouldReturnFalse_WhenNotApproved() external view {
        assertFalse(facet.isApprovedForAll(users.alice, users.bob));
    }

    function test_ShouldReturnTrue_WhenApproved() external {
        vm.prank(users.alice);
        facet.setApprovalForAll(users.bob, true);
        assertTrue(facet.isApprovedForAll(users.alice, users.bob));
    }

    function test_ShouldReturnFalse_AfterRevokingApproval() external {
        vm.prank(users.alice);
        facet.setApprovalForAll(users.bob, true);
        vm.prank(users.alice);
        facet.setApprovalForAll(users.bob, false);
        assertFalse(facet.isApprovedForAll(users.alice, users.bob));
    }

    function test_ShouldNotAffectOtherOperators() external {
        vm.prank(users.alice);
        facet.setApprovalForAll(users.bob, true);
        assertTrue(facet.isApprovedForAll(users.alice, users.bob));
        assertFalse(facet.isApprovedForAll(users.alice, users.charlee));
    }

    function test_ShouldNotAffectOtherOwners() external {
        vm.prank(users.alice);
        facet.setApprovalForAll(users.bob, true);
        assertTrue(facet.isApprovedForAll(users.alice, users.bob));
        assertFalse(facet.isApprovedForAll(users.charlee, users.bob));
    }

    function testFuzz_IsApprovedForAll(address owner, address operator, bool approved) external {
        vm.assume(owner != ADDRESS_ZERO);
        vm.assume(operator != ADDRESS_ZERO);
        vm.prank(owner);
        facet.setApprovalForAll(operator, approved);
        assertEq(facet.isApprovedForAll(owner, operator), approved);
    }
}
