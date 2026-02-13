// SPDX-License-Identifier: MIT
pragma solidity >=0.8.30;

/* Compose
 * https://compose.diamonds
 */

import {Base_Test} from "test/Base.t.sol";
import {ERC1155BurnFacetHarness} from "./harnesses/ERC1155BurnFacetHarness.sol";
import {ERC1155BurnFacet} from "src/token/ERC1155/Burn/ERC1155BurnFacet.sol";

/**
 * @title ERC1155BurnFacet_Base_Test
 * @notice Base test contract for ERC1155BurnFacet tests
 */
abstract contract ERC1155BurnFacet_Base_Test is Base_Test {
    ERC1155BurnFacetHarness internal facet;

    function setUp() public virtual override {
        Base_Test.setUp();
        vm.stopPrank(); // Cancel persistent prank from Base_Test
        facet = new ERC1155BurnFacetHarness();
        vm.label(address(facet), "ERC1155BurnFacetHarness");
    }

    function _mint(address _to, uint256 _id, uint256 _value) internal {
        facet.mint(_to, _id, _value);
    }

    function _mintBatch(address _to, uint256[] memory _ids, uint256[] memory _values) internal {
        facet.mintBatch(_to, _ids, _values);
    }
}

// =============================================================
//                   BURN FACET - SINGLE
// =============================================================

/**
 * @title Burn_ERC1155BurnFacet_Test
 * @notice Tests for burn function in ERC1155BurnFacet (WITH authorization)
 */
contract Burn_ERC1155BurnFacet_Test is ERC1155BurnFacet_Base_Test {
    event TransferSingle(
        address indexed _operator, address indexed _from, address indexed _to, uint256 _id, uint256 _value
    );

    // ==================== AUTHORIZATION TESTS ====================

    function test_ShouldRevert_WhenCallerIsNotOwnerOrApproved() external {
        _mint(users.alice, TOKEN_ID_1, 100);

        vm.prank(users.bob);
        vm.expectRevert(
            abi.encodeWithSelector(ERC1155BurnFacet.ERC1155MissingApprovalForAll.selector, users.bob, users.alice)
        );
        facet.burn(users.alice, TOKEN_ID_1, 50);
    }

    function test_ShouldBurn_WhenCallerIsOwner() external {
        _mint(users.alice, TOKEN_ID_1, 100);

        vm.prank(users.alice);
        facet.burn(users.alice, TOKEN_ID_1, 50);
        assertEq(facet.balanceOf(users.alice, TOKEN_ID_1), 50);
    }

    function test_ShouldBurn_WhenCallerIsApprovedOperator() external {
        _mint(users.alice, TOKEN_ID_1, 100);

        vm.prank(users.alice);
        facet.setApprovalForAll(users.bob, true);

        vm.prank(users.bob);
        facet.burn(users.alice, TOKEN_ID_1, 50);
        assertEq(facet.balanceOf(users.alice, TOKEN_ID_1), 50);
    }

    // ==================== REVERT TESTS ====================

    function test_ShouldRevert_WhenFromIsZeroAddress() external {
        vm.prank(users.alice);
        vm.expectRevert(abi.encodeWithSelector(ERC1155BurnFacet.ERC1155InvalidSender.selector, address(0)));
        facet.burn(ADDRESS_ZERO, TOKEN_ID_1, 100);
    }

    function test_ShouldRevert_WhenInsufficientBalance() external {
        _mint(users.alice, TOKEN_ID_1, 50);

        vm.prank(users.alice);
        vm.expectRevert(
            abi.encodeWithSelector(
                ERC1155BurnFacet.ERC1155InsufficientBalance.selector, users.alice, 50, 100, TOKEN_ID_1
            )
        );
        facet.burn(users.alice, TOKEN_ID_1, 100);
    }

    // ==================== SUCCESS TESTS ====================

    function test_ShouldEmitTransferSingleEvent_WhenOwnerBurns() external {
        _mint(users.alice, TOKEN_ID_1, 100);

        vm.expectEmit(true, true, true, true);
        emit TransferSingle(users.alice, users.alice, address(0), TOKEN_ID_1, 50);

        vm.prank(users.alice);
        facet.burn(users.alice, TOKEN_ID_1, 50);
    }

    function test_ShouldEmitTransferSingleEvent_WhenOperatorBurns() external {
        _mint(users.alice, TOKEN_ID_1, 100);

        vm.prank(users.alice);
        facet.setApprovalForAll(users.bob, true);

        vm.expectEmit(true, true, true, true);
        emit TransferSingle(users.bob, users.alice, address(0), TOKEN_ID_1, 50);

        vm.prank(users.bob);
        facet.burn(users.alice, TOKEN_ID_1, 50);
    }

    // ==================== FUZZ TESTS ====================

    function testFuzz_Burn_WhenCallerIsOwner(address owner, uint256 id, uint256 mintAmount, uint256 burnAmount)
        external
    {
        vm.assume(owner != ADDRESS_ZERO);
        vm.assume(mintAmount >= burnAmount);
        _mint(owner, id, mintAmount);

        vm.prank(owner);
        facet.burn(owner, id, burnAmount);
        assertEq(facet.balanceOf(owner, id), mintAmount - burnAmount);
    }

    function testFuzz_Burn_WhenCallerIsApproved(
        address owner,
        address operator,
        uint256 id,
        uint256 mintAmount,
        uint256 burnAmount
    ) external {
        vm.assume(owner != ADDRESS_ZERO);
        vm.assume(operator != ADDRESS_ZERO);
        vm.assume(owner != operator);
        vm.assume(mintAmount >= burnAmount);
        _mint(owner, id, mintAmount);

        vm.prank(owner);
        facet.setApprovalForAll(operator, true);

        vm.prank(operator);
        facet.burn(owner, id, burnAmount);
        assertEq(facet.balanceOf(owner, id), mintAmount - burnAmount);
    }
}

// =============================================================
//                   BURN FACET - BATCH
// =============================================================

/**
 * @title BurnBatch_ERC1155BurnFacet_Test
 * @notice Tests for burnBatch function in ERC1155BurnFacet (WITH authorization)
 */
contract BurnBatch_ERC1155BurnFacet_Test is ERC1155BurnFacet_Base_Test {
    event TransferBatch(
        address indexed _operator, address indexed _from, address indexed _to, uint256[] _ids, uint256[] _values
    );

    // ==================== AUTHORIZATION TESTS ====================

    function test_ShouldRevert_WhenCallerIsNotOwnerOrApproved() external {
        uint256[] memory ids = new uint256[](2);
        ids[0] = TOKEN_ID_1;
        ids[1] = TOKEN_ID_2;
        uint256[] memory values = new uint256[](2);
        values[0] = 100;
        values[1] = 200;

        _mintBatch(users.alice, ids, values);

        vm.prank(users.bob);
        vm.expectRevert(
            abi.encodeWithSelector(ERC1155BurnFacet.ERC1155MissingApprovalForAll.selector, users.bob, users.alice)
        );
        facet.burnBatch(users.alice, ids, values);
    }

    function test_ShouldBurnBatch_WhenCallerIsOwner() external {
        uint256[] memory ids = new uint256[](2);
        ids[0] = TOKEN_ID_1;
        ids[1] = TOKEN_ID_2;
        uint256[] memory mintValues = new uint256[](2);
        mintValues[0] = 100;
        mintValues[1] = 200;
        uint256[] memory burnValues = new uint256[](2);
        burnValues[0] = 50;
        burnValues[1] = 100;

        _mintBatch(users.alice, ids, mintValues);

        vm.prank(users.alice);
        facet.burnBatch(users.alice, ids, burnValues);

        assertEq(facet.balanceOf(users.alice, TOKEN_ID_1), 50);
        assertEq(facet.balanceOf(users.alice, TOKEN_ID_2), 100);
    }

    function test_ShouldBurnBatch_WhenCallerIsApprovedOperator() external {
        uint256[] memory ids = new uint256[](2);
        ids[0] = TOKEN_ID_1;
        ids[1] = TOKEN_ID_2;
        uint256[] memory mintValues = new uint256[](2);
        mintValues[0] = 100;
        mintValues[1] = 200;
        uint256[] memory burnValues = new uint256[](2);
        burnValues[0] = 50;
        burnValues[1] = 100;

        _mintBatch(users.alice, ids, mintValues);

        vm.prank(users.alice);
        facet.setApprovalForAll(users.bob, true);

        vm.prank(users.bob);
        facet.burnBatch(users.alice, ids, burnValues);

        assertEq(facet.balanceOf(users.alice, TOKEN_ID_1), 50);
        assertEq(facet.balanceOf(users.alice, TOKEN_ID_2), 100);
    }

    // ==================== REVERT TESTS ====================

    function test_ShouldRevert_WhenFromIsZeroAddress() external {
        uint256[] memory ids = new uint256[](2);
        ids[0] = TOKEN_ID_1;
        ids[1] = TOKEN_ID_2;
        uint256[] memory values = new uint256[](2);
        values[0] = 50;
        values[1] = 50;

        vm.prank(users.alice);
        vm.expectRevert(abi.encodeWithSelector(ERC1155BurnFacet.ERC1155InvalidSender.selector, address(0)));
        facet.burnBatch(ADDRESS_ZERO, ids, values);
    }

    function test_ShouldRevert_WhenArrayLengthMismatch() external {
        uint256[] memory ids = new uint256[](2);
        ids[0] = TOKEN_ID_1;
        ids[1] = TOKEN_ID_2;
        uint256[] memory values = new uint256[](1);
        values[0] = 50;

        vm.prank(users.alice);
        vm.expectRevert(abi.encodeWithSelector(ERC1155BurnFacet.ERC1155InvalidArrayLength.selector, 2, 1));
        facet.burnBatch(users.alice, ids, values);
    }

    // ==================== SUCCESS TESTS ====================

    function test_ShouldEmitTransferBatchEvent_WhenOwnerBurns() external {
        uint256[] memory ids = new uint256[](2);
        ids[0] = TOKEN_ID_1;
        ids[1] = TOKEN_ID_2;
        uint256[] memory values = new uint256[](2);
        values[0] = 100;
        values[1] = 200;

        _mintBatch(users.alice, ids, values);

        vm.expectEmit(true, true, true, true);
        emit TransferBatch(users.alice, users.alice, address(0), ids, values);

        vm.prank(users.alice);
        facet.burnBatch(users.alice, ids, values);
    }

    function test_ShouldEmitTransferBatchEvent_WhenOperatorBurns() external {
        uint256[] memory ids = new uint256[](2);
        ids[0] = TOKEN_ID_1;
        ids[1] = TOKEN_ID_2;
        uint256[] memory values = new uint256[](2);
        values[0] = 100;
        values[1] = 200;

        _mintBatch(users.alice, ids, values);

        vm.prank(users.alice);
        facet.setApprovalForAll(users.bob, true);

        vm.expectEmit(true, true, true, true);
        emit TransferBatch(users.bob, users.alice, address(0), ids, values);

        vm.prank(users.bob);
        facet.burnBatch(users.alice, ids, values);
    }
}
