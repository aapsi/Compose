// SPDX-License-Identifier: MIT
pragma solidity >=0.8.30;

/* Compose
 * https://compose.diamonds
 */

import {Base_Test} from "test/Base.t.sol";
import {ERC1155TransferHarness} from "./harnesses/ERC1155TransferHarness.sol";
import {ERC1155TransferFacet} from "src/token/ERC1155/Transfer/ERC1155TransferFacet.sol";
import {ERC1155ReceiverMock} from "../shared/ERC1155ReceiverMock.sol";

/**
 * @title ERC1155Transfer_Base_Test
 * @notice Base test contract for ERC1155 Transfer tests
 */
abstract contract ERC1155Transfer_Base_Test is Base_Test {
    ERC1155TransferHarness internal facet;

    function setUp() public virtual override {
        Base_Test.setUp();
        vm.stopPrank(); // Cancel persistent prank from Base_Test
        facet = new ERC1155TransferHarness();
        vm.label(address(facet), "ERC1155TransferHarness");
    }

    function _mint(address _to, uint256 _id, uint256 _value) internal {
        facet.mint(_to, _id, _value);
    }

    function _mintBatch(address _to, uint256[] memory _ids, uint256[] memory _values) internal {
        facet.mintBatch(_to, _ids, _values);
    }

    function _createValidReceiver() internal returns (ERC1155ReceiverMock) {
        return new ERC1155ReceiverMock(
            RECEIVER_SINGLE_MAGIC_VALUE, RECEIVER_BATCH_MAGIC_VALUE, ERC1155ReceiverMock.RevertType.None
        );
    }

    function _createInvalidReceiver() internal returns (ERC1155ReceiverMock) {
        return new ERC1155ReceiverMock(bytes4(0xdeadbeef), bytes4(0xdeadbeef), ERC1155ReceiverMock.RevertType.None);
    }

    function _createRevertingReceiver() internal returns (ERC1155ReceiverMock) {
        return new ERC1155ReceiverMock(
            RECEIVER_SINGLE_MAGIC_VALUE, RECEIVER_BATCH_MAGIC_VALUE, ERC1155ReceiverMock.RevertType.RevertWithMessage
        );
    }

    function _createRevertingReceiverNoMessage() internal returns (ERC1155ReceiverMock) {
        return new ERC1155ReceiverMock(
            RECEIVER_SINGLE_MAGIC_VALUE,
            RECEIVER_BATCH_MAGIC_VALUE,
            ERC1155ReceiverMock.RevertType.RevertWithoutMessage
        );
    }
}

// =============================================================
//                    SAFE TRANSFER FROM
// =============================================================

contract SafeTransferFrom_ERC1155Transfer_Test is ERC1155Transfer_Base_Test {
    event TransferSingle(
        address indexed _operator, address indexed _from, address indexed _to, uint256 _id, uint256 _value
    );

    // ==================== AUTHORIZATION TESTS ====================

    function test_ShouldRevert_WhenCallerIsNotOwnerOrApproved() external {
        _mint(users.alice, TOKEN_ID_1, 100);

        vm.prank(users.bob);
        vm.expectRevert(
            abi.encodeWithSelector(ERC1155TransferFacet.ERC1155MissingApprovalForAll.selector, users.bob, users.alice)
        );
        facet.safeTransferFrom(users.alice, users.charlee, TOKEN_ID_1, 50, "");
    }

    function test_ShouldTransfer_WhenCallerIsOwner() external {
        _mint(users.alice, TOKEN_ID_1, 100);

        vm.prank(users.alice);
        facet.safeTransferFrom(users.alice, users.bob, TOKEN_ID_1, 50, "");

        assertEq(facet.balanceOf(users.alice, TOKEN_ID_1), 50);
        assertEq(facet.balanceOf(users.bob, TOKEN_ID_1), 50);
    }

    function test_ShouldTransfer_WhenCallerIsApprovedOperator() external {
        _mint(users.alice, TOKEN_ID_1, 100);

        vm.prank(users.alice);
        facet.setApprovalForAll(users.bob, true);

        vm.prank(users.bob);
        facet.safeTransferFrom(users.alice, users.charlee, TOKEN_ID_1, 50, "");

        assertEq(facet.balanceOf(users.alice, TOKEN_ID_1), 50);
        assertEq(facet.balanceOf(users.charlee, TOKEN_ID_1), 50);
    }

    // ==================== REVERT TESTS ====================

    function test_ShouldRevert_WhenFromIsZeroAddress() external {
        vm.prank(users.alice);
        vm.expectRevert(abi.encodeWithSelector(ERC1155TransferFacet.ERC1155InvalidSender.selector, address(0)));
        facet.safeTransferFrom(ADDRESS_ZERO, users.bob, TOKEN_ID_1, 100, "");
    }

    function test_ShouldRevert_WhenToIsZeroAddress() external {
        _mint(users.alice, TOKEN_ID_1, 100);

        vm.prank(users.alice);
        vm.expectRevert(abi.encodeWithSelector(ERC1155TransferFacet.ERC1155InvalidReceiver.selector, address(0)));
        facet.safeTransferFrom(users.alice, ADDRESS_ZERO, TOKEN_ID_1, 50, "");
    }

    function test_ShouldRevert_WhenInsufficientBalance() external {
        _mint(users.alice, TOKEN_ID_1, 50);

        vm.prank(users.alice);
        vm.expectRevert(
            abi.encodeWithSelector(
                ERC1155TransferFacet.ERC1155InsufficientBalance.selector, users.alice, 50, 100, TOKEN_ID_1
            )
        );
        facet.safeTransferFrom(users.alice, users.bob, TOKEN_ID_1, 100, "");
    }

    function test_ShouldRevert_WhenReceiverReturnsWrongValue() external {
        ERC1155ReceiverMock receiver = _createInvalidReceiver();
        _mint(users.alice, TOKEN_ID_1, 100);

        vm.prank(users.alice);
        vm.expectRevert(
            abi.encodeWithSelector(ERC1155TransferFacet.ERC1155InvalidReceiver.selector, address(receiver))
        );
        facet.safeTransferFrom(users.alice, address(receiver), TOKEN_ID_1, 50, "");
    }

    function test_ShouldRevert_WhenReceiverRevertsWithMessage() external {
        ERC1155ReceiverMock receiver = _createRevertingReceiver();
        _mint(users.alice, TOKEN_ID_1, 100);

        vm.prank(users.alice);
        vm.expectRevert("ERC1155ReceiverMock: reverting on receive");
        facet.safeTransferFrom(users.alice, address(receiver), TOKEN_ID_1, 50, "");
    }

    function test_ShouldRevert_WhenReceiverRevertsWithoutMessage() external {
        ERC1155ReceiverMock receiver = _createRevertingReceiverNoMessage();
        _mint(users.alice, TOKEN_ID_1, 100);

        vm.prank(users.alice);
        vm.expectRevert(
            abi.encodeWithSelector(ERC1155TransferFacet.ERC1155InvalidReceiver.selector, address(receiver))
        );
        facet.safeTransferFrom(users.alice, address(receiver), TOKEN_ID_1, 50, "");
    }

    // ==================== SUCCESS TESTS ====================

    function test_ShouldEmitTransferSingleEvent() external {
        _mint(users.alice, TOKEN_ID_1, 100);

        vm.expectEmit(true, true, true, true);
        emit TransferSingle(users.alice, users.alice, users.bob, TOKEN_ID_1, 50);

        vm.prank(users.alice);
        facet.safeTransferFrom(users.alice, users.bob, TOKEN_ID_1, 50, "");
    }

    function test_ShouldEmitTransferSingleEvent_WhenOperatorTransfers() external {
        _mint(users.alice, TOKEN_ID_1, 100);

        vm.prank(users.alice);
        facet.setApprovalForAll(users.bob, true);

        vm.expectEmit(true, true, true, true);
        emit TransferSingle(users.bob, users.alice, users.charlee, TOKEN_ID_1, 50);

        vm.prank(users.bob);
        facet.safeTransferFrom(users.alice, users.charlee, TOKEN_ID_1, 50, "");
    }

    function test_ShouldTransfer_WhenToIsValidReceiver() external {
        ERC1155ReceiverMock receiver = _createValidReceiver();
        _mint(users.alice, TOKEN_ID_1, 100);

        vm.prank(users.alice);
        facet.safeTransferFrom(users.alice, address(receiver), TOKEN_ID_1, 50, "");

        assertEq(facet.balanceOf(users.alice, TOKEN_ID_1), 50);
        assertEq(facet.balanceOf(address(receiver), TOKEN_ID_1), 50);
    }

    function test_ShouldTransferZeroAmount() external {
        _mint(users.alice, TOKEN_ID_1, 100);

        vm.prank(users.alice);
        facet.safeTransferFrom(users.alice, users.bob, TOKEN_ID_1, 0, "");

        assertEq(facet.balanceOf(users.alice, TOKEN_ID_1), 100);
        assertEq(facet.balanceOf(users.bob, TOKEN_ID_1), 0);
    }

    function test_ShouldTransferEntireBalance() external {
        _mint(users.alice, TOKEN_ID_1, 100);

        vm.prank(users.alice);
        facet.safeTransferFrom(users.alice, users.bob, TOKEN_ID_1, 100, "");

        assertEq(facet.balanceOf(users.alice, TOKEN_ID_1), 0);
        assertEq(facet.balanceOf(users.bob, TOKEN_ID_1), 100);
    }

    function test_ShouldTransferToSelf() external {
        _mint(users.alice, TOKEN_ID_1, 100);

        vm.prank(users.alice);
        facet.safeTransferFrom(users.alice, users.alice, TOKEN_ID_1, 50, "");

        assertEq(facet.balanceOf(users.alice, TOKEN_ID_1), 100);
    }

    // ==================== FUZZ TESTS ====================

    function testFuzz_SafeTransferFrom(address from, address to, uint256 id, uint256 mintAmount, uint256 transferAmount)
        external
    {
        vm.assume(from != ADDRESS_ZERO);
        vm.assume(to != ADDRESS_ZERO);
        vm.assume(to.code.length == 0);
        vm.assume(mintAmount >= transferAmount);
        _mint(from, id, mintAmount);

        vm.prank(from);
        facet.safeTransferFrom(from, to, id, transferAmount, "");

        if (from == to) {
            assertEq(facet.balanceOf(from, id), mintAmount);
        } else {
            assertEq(facet.balanceOf(from, id), mintAmount - transferAmount);
            assertEq(facet.balanceOf(to, id), transferAmount);
        }
    }
}

// =============================================================
//                  SAFE BATCH TRANSFER FROM
// =============================================================

contract SafeBatchTransferFrom_ERC1155Transfer_Test is ERC1155Transfer_Base_Test {
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
            abi.encodeWithSelector(ERC1155TransferFacet.ERC1155MissingApprovalForAll.selector, users.bob, users.alice)
        );
        facet.safeBatchTransferFrom(users.alice, users.charlee, ids, values, "");
    }

    function test_ShouldTransferBatch_WhenCallerIsOwner() external {
        uint256[] memory ids = new uint256[](2);
        ids[0] = TOKEN_ID_1;
        ids[1] = TOKEN_ID_2;
        uint256[] memory values = new uint256[](2);
        values[0] = 100;
        values[1] = 200;

        _mintBatch(users.alice, ids, values);

        vm.prank(users.alice);
        facet.safeBatchTransferFrom(users.alice, users.bob, ids, values, "");

        assertEq(facet.balanceOf(users.alice, TOKEN_ID_1), 0);
        assertEq(facet.balanceOf(users.alice, TOKEN_ID_2), 0);
        assertEq(facet.balanceOf(users.bob, TOKEN_ID_1), 100);
        assertEq(facet.balanceOf(users.bob, TOKEN_ID_2), 200);
    }

    function test_ShouldTransferBatch_WhenCallerIsApprovedOperator() external {
        uint256[] memory ids = new uint256[](2);
        ids[0] = TOKEN_ID_1;
        ids[1] = TOKEN_ID_2;
        uint256[] memory values = new uint256[](2);
        values[0] = 100;
        values[1] = 200;

        _mintBatch(users.alice, ids, values);

        vm.prank(users.alice);
        facet.setApprovalForAll(users.bob, true);

        vm.prank(users.bob);
        facet.safeBatchTransferFrom(users.alice, users.charlee, ids, values, "");

        assertEq(facet.balanceOf(users.charlee, TOKEN_ID_1), 100);
        assertEq(facet.balanceOf(users.charlee, TOKEN_ID_2), 200);
    }

    // ==================== REVERT TESTS ====================

    function test_ShouldRevert_WhenFromIsZeroAddress() external {
        uint256[] memory ids = new uint256[](2);
        ids[0] = TOKEN_ID_1;
        ids[1] = TOKEN_ID_2;
        uint256[] memory values = new uint256[](2);
        values[0] = 100;
        values[1] = 200;

        vm.prank(users.alice);
        vm.expectRevert(abi.encodeWithSelector(ERC1155TransferFacet.ERC1155InvalidSender.selector, address(0)));
        facet.safeBatchTransferFrom(ADDRESS_ZERO, users.bob, ids, values, "");
    }

    function test_ShouldRevert_WhenToIsZeroAddress() external {
        uint256[] memory ids = new uint256[](2);
        ids[0] = TOKEN_ID_1;
        ids[1] = TOKEN_ID_2;
        uint256[] memory values = new uint256[](2);
        values[0] = 100;
        values[1] = 200;

        _mintBatch(users.alice, ids, values);

        vm.prank(users.alice);
        vm.expectRevert(abi.encodeWithSelector(ERC1155TransferFacet.ERC1155InvalidReceiver.selector, address(0)));
        facet.safeBatchTransferFrom(users.alice, ADDRESS_ZERO, ids, values, "");
    }

    function test_ShouldRevert_WhenArrayLengthMismatch() external {
        uint256[] memory ids = new uint256[](2);
        ids[0] = TOKEN_ID_1;
        ids[1] = TOKEN_ID_2;
        uint256[] memory values = new uint256[](1);
        values[0] = 100;

        vm.prank(users.alice);
        vm.expectRevert(abi.encodeWithSelector(ERC1155TransferFacet.ERC1155InvalidArrayLength.selector, 2, 1));
        facet.safeBatchTransferFrom(users.alice, users.bob, ids, values, "");
    }

    function test_ShouldRevert_WhenInsufficientBalance() external {
        uint256[] memory ids = new uint256[](2);
        ids[0] = TOKEN_ID_1;
        ids[1] = TOKEN_ID_2;
        uint256[] memory mintValues = new uint256[](2);
        mintValues[0] = 100;
        mintValues[1] = 50;
        uint256[] memory transferValues = new uint256[](2);
        transferValues[0] = 50;
        transferValues[1] = 100;

        _mintBatch(users.alice, ids, mintValues);

        vm.prank(users.alice);
        vm.expectRevert(
            abi.encodeWithSelector(
                ERC1155TransferFacet.ERC1155InsufficientBalance.selector, users.alice, 50, 100, TOKEN_ID_2
            )
        );
        facet.safeBatchTransferFrom(users.alice, users.bob, ids, transferValues, "");
    }

    function test_ShouldRevert_WhenReceiverReturnsWrongValue() external {
        ERC1155ReceiverMock receiver = _createInvalidReceiver();
        uint256[] memory ids = new uint256[](2);
        ids[0] = TOKEN_ID_1;
        ids[1] = TOKEN_ID_2;
        uint256[] memory values = new uint256[](2);
        values[0] = 100;
        values[1] = 200;

        _mintBatch(users.alice, ids, values);

        vm.prank(users.alice);
        vm.expectRevert(
            abi.encodeWithSelector(ERC1155TransferFacet.ERC1155InvalidReceiver.selector, address(receiver))
        );
        facet.safeBatchTransferFrom(users.alice, address(receiver), ids, values, "");
    }

    // ==================== SUCCESS TESTS ====================

    function test_ShouldEmitTransferBatchEvent() external {
        uint256[] memory ids = new uint256[](2);
        ids[0] = TOKEN_ID_1;
        ids[1] = TOKEN_ID_2;
        uint256[] memory values = new uint256[](2);
        values[0] = 100;
        values[1] = 200;

        _mintBatch(users.alice, ids, values);

        vm.expectEmit(true, true, true, true);
        emit TransferBatch(users.alice, users.alice, users.bob, ids, values);

        vm.prank(users.alice);
        facet.safeBatchTransferFrom(users.alice, users.bob, ids, values, "");
    }

    function test_ShouldEmitTransferBatchEvent_WhenOperatorTransfers() external {
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
        emit TransferBatch(users.bob, users.alice, users.charlee, ids, values);

        vm.prank(users.bob);
        facet.safeBatchTransferFrom(users.alice, users.charlee, ids, values, "");
    }

    function test_ShouldTransferBatch_WithEmptyArrays() external {
        uint256[] memory ids = new uint256[](0);
        uint256[] memory values = new uint256[](0);

        vm.prank(users.alice);
        facet.safeBatchTransferFrom(users.alice, users.bob, ids, values, "");
    }

    function test_ShouldTransferBatch_WhenToIsValidReceiver() external {
        ERC1155ReceiverMock receiver = _createValidReceiver();
        uint256[] memory ids = new uint256[](2);
        ids[0] = TOKEN_ID_1;
        ids[1] = TOKEN_ID_2;
        uint256[] memory values = new uint256[](2);
        values[0] = 100;
        values[1] = 200;

        _mintBatch(users.alice, ids, values);

        vm.prank(users.alice);
        facet.safeBatchTransferFrom(users.alice, address(receiver), ids, values, "");

        assertEq(facet.balanceOf(address(receiver), TOKEN_ID_1), 100);
        assertEq(facet.balanceOf(address(receiver), TOKEN_ID_2), 200);
    }
}
