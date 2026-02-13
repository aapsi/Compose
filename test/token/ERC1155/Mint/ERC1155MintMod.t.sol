// SPDX-License-Identifier: MIT
pragma solidity >=0.8.30;

/* Compose
 * https://compose.diamonds
 */

import {Base_Test} from "test/Base.t.sol";
import {ERC1155MintHarness} from "./harnesses/ERC1155MintHarness.sol";
import {ERC1155ReceiverMock} from "../shared/ERC1155ReceiverMock.sol";
import "src/token/ERC1155/Mint/ERC1155MintMod.sol" as MintMod;

/**
 * @title ERC1155MintMod_Base_Test
 * @notice Base test contract for ERC1155MintMod tests
 */
abstract contract ERC1155MintMod_Base_Test is Base_Test {
    ERC1155MintHarness internal harness;

    function setUp() public virtual override {
        Base_Test.setUp();
        vm.stopPrank(); // Cancel persistent prank from Base_Test
        harness = new ERC1155MintHarness();
        vm.label(address(harness), "ERC1155MintHarness");
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

    function _createPanickingReceiver() internal returns (ERC1155ReceiverMock) {
        return new ERC1155ReceiverMock(
            RECEIVER_SINGLE_MAGIC_VALUE, RECEIVER_BATCH_MAGIC_VALUE, ERC1155ReceiverMock.RevertType.Panic
        );
    }
}

// =============================================================
//                      MINT SINGLE
// =============================================================

contract Mint_ERC1155MintMod_Test is ERC1155MintMod_Base_Test {
    event TransferSingle(
        address indexed _operator, address indexed _from, address indexed _to, uint256 _id, uint256 _value
    );

    // ==================== REVERT TESTS ====================

    function test_ShouldRevert_WhenToIsZeroAddress() external {
        vm.expectRevert(abi.encodeWithSelector(MintMod.ERC1155InvalidReceiver.selector, address(0)));
        harness.mint(ADDRESS_ZERO, TOKEN_ID_1, 100);
    }

    function test_ShouldRevert_WhenReceiverReturnsWrongValue() external {
        ERC1155ReceiverMock receiver = _createInvalidReceiver();
        vm.expectRevert(abi.encodeWithSelector(MintMod.ERC1155InvalidReceiver.selector, address(receiver)));
        harness.mint(address(receiver), TOKEN_ID_1, 100);
    }

    function test_ShouldRevert_WhenReceiverRevertsWithMessage() external {
        ERC1155ReceiverMock receiver = _createRevertingReceiver();
        vm.expectRevert("ERC1155ReceiverMock: reverting on receive");
        harness.mint(address(receiver), TOKEN_ID_1, 100);
    }

    function test_ShouldRevert_WhenReceiverRevertsWithoutMessage() external {
        ERC1155ReceiverMock receiver = _createRevertingReceiverNoMessage();
        vm.expectRevert(abi.encodeWithSelector(MintMod.ERC1155InvalidReceiver.selector, address(receiver)));
        harness.mint(address(receiver), TOKEN_ID_1, 100);
    }

    function test_ShouldRevert_WhenReceiverPanics() external {
        ERC1155ReceiverMock receiver = _createPanickingReceiver();
        vm.expectRevert();
        harness.mint(address(receiver), TOKEN_ID_1, 100);
    }

    // ==================== SUCCESS TESTS ====================

    function test_ShouldMint_WhenToIsEOA() external {
        harness.mint(users.alice, TOKEN_ID_1, 100);
        assertEq(harness.balanceOf(users.alice, TOKEN_ID_1), 100);
    }

    function test_ShouldMint_WhenToIsValidReceiver() external {
        ERC1155ReceiverMock receiver = _createValidReceiver();
        harness.mint(address(receiver), TOKEN_ID_1, 100);
        assertEq(harness.balanceOf(address(receiver), TOKEN_ID_1), 100);
    }

    function test_ShouldEmitTransferSingleEvent() external {
        vm.expectEmit(true, true, true, true);
        emit TransferSingle(address(this), address(0), users.alice, TOKEN_ID_1, 100);
        harness.mint(users.alice, TOKEN_ID_1, 100);
    }

    function test_ShouldMintZeroAmount() external {
        harness.mint(users.alice, TOKEN_ID_1, 0);
        assertEq(harness.balanceOf(users.alice, TOKEN_ID_1), 0);
    }

    function test_ShouldAccumulateBalance_WhenMintedMultipleTimes() external {
        harness.mint(users.alice, TOKEN_ID_1, 100);
        harness.mint(users.alice, TOKEN_ID_1, 50);
        assertEq(harness.balanceOf(users.alice, TOKEN_ID_1), 150);
    }

    function test_ShouldMintDifferentTokenIds() external {
        harness.mint(users.alice, TOKEN_ID_1, 100);
        harness.mint(users.alice, TOKEN_ID_2, 200);
        assertEq(harness.balanceOf(users.alice, TOKEN_ID_1), 100);
        assertEq(harness.balanceOf(users.alice, TOKEN_ID_2), 200);
    }

    function test_ShouldPassDataToReceiver() external {
        ERC1155ReceiverMock receiver = _createValidReceiver();
        harness.mint(address(receiver), TOKEN_ID_1, 100, "test data");
        assertEq(harness.balanceOf(address(receiver), TOKEN_ID_1), 100);
    }

    // ==================== FUZZ TESTS ====================

    function testFuzz_Mint(address to, uint256 id, uint256 value) external {
        vm.assume(to != ADDRESS_ZERO);
        vm.assume(to.code.length == 0);
        harness.mint(to, id, value);
        assertEq(harness.balanceOf(to, id), value);
    }
}

// =============================================================
//                      MINT BATCH
// =============================================================

contract MintBatch_ERC1155MintMod_Test is ERC1155MintMod_Base_Test {
    event TransferBatch(
        address indexed _operator, address indexed _from, address indexed _to, uint256[] _ids, uint256[] _values
    );

    // ==================== REVERT TESTS ====================

    function test_ShouldRevert_WhenToIsZeroAddress() external {
        uint256[] memory ids = new uint256[](2);
        ids[0] = TOKEN_ID_1;
        ids[1] = TOKEN_ID_2;
        uint256[] memory values = new uint256[](2);
        values[0] = 100;
        values[1] = 200;

        vm.expectRevert(abi.encodeWithSelector(MintMod.ERC1155InvalidReceiver.selector, address(0)));
        harness.mintBatch(ADDRESS_ZERO, ids, values);
    }

    function test_ShouldRevert_WhenArrayLengthMismatch() external {
        uint256[] memory ids = new uint256[](2);
        ids[0] = TOKEN_ID_1;
        ids[1] = TOKEN_ID_2;
        uint256[] memory values = new uint256[](1);
        values[0] = 100;

        vm.expectRevert(abi.encodeWithSelector(MintMod.ERC1155InvalidArrayLength.selector, 2, 1));
        harness.mintBatch(users.alice, ids, values);
    }

    function test_ShouldRevert_WhenReceiverReturnsWrongValue() external {
        ERC1155ReceiverMock receiver = _createInvalidReceiver();
        uint256[] memory ids = new uint256[](2);
        ids[0] = TOKEN_ID_1;
        ids[1] = TOKEN_ID_2;
        uint256[] memory values = new uint256[](2);
        values[0] = 100;
        values[1] = 200;

        vm.expectRevert(abi.encodeWithSelector(MintMod.ERC1155InvalidReceiver.selector, address(receiver)));
        harness.mintBatch(address(receiver), ids, values);
    }

    function test_ShouldRevert_WhenReceiverRevertsWithMessage() external {
        ERC1155ReceiverMock receiver = _createRevertingReceiver();
        uint256[] memory ids = new uint256[](2);
        ids[0] = TOKEN_ID_1;
        ids[1] = TOKEN_ID_2;
        uint256[] memory values = new uint256[](2);
        values[0] = 100;
        values[1] = 200;

        vm.expectRevert("ERC1155ReceiverMock: reverting on batch receive");
        harness.mintBatch(address(receiver), ids, values);
    }

    function test_ShouldRevert_WhenReceiverRevertsWithoutMessage() external {
        ERC1155ReceiverMock receiver = _createRevertingReceiverNoMessage();
        uint256[] memory ids = new uint256[](2);
        ids[0] = TOKEN_ID_1;
        ids[1] = TOKEN_ID_2;
        uint256[] memory values = new uint256[](2);
        values[0] = 100;
        values[1] = 200;

        vm.expectRevert(abi.encodeWithSelector(MintMod.ERC1155InvalidReceiver.selector, address(receiver)));
        harness.mintBatch(address(receiver), ids, values);
    }

    // ==================== SUCCESS TESTS ====================

    function test_ShouldMintBatch_WhenToIsEOA() external {
        uint256[] memory ids = new uint256[](2);
        ids[0] = TOKEN_ID_1;
        ids[1] = TOKEN_ID_2;
        uint256[] memory values = new uint256[](2);
        values[0] = 100;
        values[1] = 200;

        harness.mintBatch(users.alice, ids, values);

        assertEq(harness.balanceOf(users.alice, TOKEN_ID_1), 100);
        assertEq(harness.balanceOf(users.alice, TOKEN_ID_2), 200);
    }

    function test_ShouldMintBatch_WhenToIsValidReceiver() external {
        ERC1155ReceiverMock receiver = _createValidReceiver();
        uint256[] memory ids = new uint256[](2);
        ids[0] = TOKEN_ID_1;
        ids[1] = TOKEN_ID_2;
        uint256[] memory values = new uint256[](2);
        values[0] = 100;
        values[1] = 200;

        harness.mintBatch(address(receiver), ids, values);

        assertEq(harness.balanceOf(address(receiver), TOKEN_ID_1), 100);
        assertEq(harness.balanceOf(address(receiver), TOKEN_ID_2), 200);
    }

    function test_ShouldEmitTransferBatchEvent() external {
        uint256[] memory ids = new uint256[](2);
        ids[0] = TOKEN_ID_1;
        ids[1] = TOKEN_ID_2;
        uint256[] memory values = new uint256[](2);
        values[0] = 100;
        values[1] = 200;

        vm.expectEmit(true, true, true, true);
        emit TransferBatch(address(this), address(0), users.alice, ids, values);
        harness.mintBatch(users.alice, ids, values);
    }

    function test_ShouldMintBatch_WithEmptyArrays() external {
        uint256[] memory ids = new uint256[](0);
        uint256[] memory values = new uint256[](0);
        harness.mintBatch(users.alice, ids, values);
    }

    function test_ShouldMintBatch_WithDuplicateIds() external {
        uint256[] memory ids = new uint256[](2);
        ids[0] = TOKEN_ID_1;
        ids[1] = TOKEN_ID_1;
        uint256[] memory values = new uint256[](2);
        values[0] = 100;
        values[1] = 50;

        harness.mintBatch(users.alice, ids, values);
        assertEq(harness.balanceOf(users.alice, TOKEN_ID_1), 150);
    }

    function test_ShouldPassDataToReceiver() external {
        ERC1155ReceiverMock receiver = _createValidReceiver();
        uint256[] memory ids = new uint256[](2);
        ids[0] = TOKEN_ID_1;
        ids[1] = TOKEN_ID_2;
        uint256[] memory values = new uint256[](2);
        values[0] = 100;
        values[1] = 200;

        harness.mintBatch(address(receiver), ids, values, "test data");

        assertEq(harness.balanceOf(address(receiver), TOKEN_ID_1), 100);
        assertEq(harness.balanceOf(address(receiver), TOKEN_ID_2), 200);
    }
}
