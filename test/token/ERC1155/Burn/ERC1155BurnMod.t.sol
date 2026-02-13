// SPDX-License-Identifier: MIT
pragma solidity >=0.8.30;

/* Compose
 * https://compose.diamonds
 */

import {Base_Test} from "test/Base.t.sol";
import {ERC1155BurnHarness} from "./harnesses/ERC1155BurnHarness.sol";
import "src/token/ERC1155/Burn/ERC1155BurnMod.sol" as BurnMod;

/**
 * @title ERC1155BurnMod_Base_Test
 * @notice Base test contract for ERC1155BurnMod tests
 */
abstract contract ERC1155BurnMod_Base_Test is Base_Test {
    ERC1155BurnHarness internal harness;

    function setUp() public virtual override {
        Base_Test.setUp();
        vm.stopPrank(); // Cancel persistent prank from Base_Test
        harness = new ERC1155BurnHarness();
        vm.label(address(harness), "ERC1155BurnHarness");
    }

    function _mint(address _to, uint256 _id, uint256 _value) internal {
        harness.mint(_to, _id, _value);
    }

    function _mintBatch(address _to, uint256[] memory _ids, uint256[] memory _values) internal {
        harness.mintBatch(_to, _ids, _values);
    }
}

// =============================================================
//                      BURN SINGLE
// =============================================================

contract Burn_ERC1155BurnMod_Test is ERC1155BurnMod_Base_Test {
    event TransferSingle(
        address indexed _operator, address indexed _from, address indexed _to, uint256 _id, uint256 _value
    );

    // ==================== REVERT TESTS ====================

    function test_ShouldRevert_WhenFromIsZeroAddress() external {
        vm.expectRevert(abi.encodeWithSelector(BurnMod.ERC1155InvalidSender.selector, address(0)));
        harness.burn(ADDRESS_ZERO, TOKEN_ID_1, 100);
    }

    function test_ShouldRevert_WhenInsufficientBalance() external {
        _mint(users.alice, TOKEN_ID_1, 50);
        vm.expectRevert(
            abi.encodeWithSelector(BurnMod.ERC1155InsufficientBalance.selector, users.alice, 50, 100, TOKEN_ID_1)
        );
        harness.burn(users.alice, TOKEN_ID_1, 100);
    }

    function test_ShouldRevert_WhenBurningFromZeroBalance() external {
        vm.expectRevert(
            abi.encodeWithSelector(BurnMod.ERC1155InsufficientBalance.selector, users.alice, 0, 100, TOKEN_ID_1)
        );
        harness.burn(users.alice, TOKEN_ID_1, 100);
    }

    // ==================== SUCCESS TESTS ====================

    function test_ShouldBurn_WhenBalanceIsSufficient() external {
        _mint(users.alice, TOKEN_ID_1, 100);
        harness.burn(users.alice, TOKEN_ID_1, 50);
        assertEq(harness.balanceOf(users.alice, TOKEN_ID_1), 50);
    }

    function test_ShouldBurnEntireBalance() external {
        _mint(users.alice, TOKEN_ID_1, 100);
        harness.burn(users.alice, TOKEN_ID_1, 100);
        assertEq(harness.balanceOf(users.alice, TOKEN_ID_1), 0);
    }

    function test_ShouldEmitTransferSingleEvent() external {
        _mint(users.alice, TOKEN_ID_1, 100);

        vm.expectEmit(true, true, true, true);
        emit TransferSingle(address(this), users.alice, address(0), TOKEN_ID_1, 50);
        harness.burn(users.alice, TOKEN_ID_1, 50);
    }

    function test_ShouldBurnZeroAmount() external {
        _mint(users.alice, TOKEN_ID_1, 100);
        harness.burn(users.alice, TOKEN_ID_1, 0);
        assertEq(harness.balanceOf(users.alice, TOKEN_ID_1), 100);
    }

    // ==================== FUZZ TESTS ====================

    function testFuzz_Burn(address from, uint256 id, uint256 mintAmount, uint256 burnAmount) external {
        vm.assume(from != ADDRESS_ZERO);
        vm.assume(from.code.length == 0); // EOA only - contracts require receiver hooks
        vm.assume(mintAmount >= burnAmount);
        _mint(from, id, mintAmount);
        harness.burn(from, id, burnAmount);
        assertEq(harness.balanceOf(from, id), mintAmount - burnAmount);
    }
}

// =============================================================
//                      BURN BATCH
// =============================================================

contract BurnBatch_ERC1155BurnMod_Test is ERC1155BurnMod_Base_Test {
    event TransferBatch(
        address indexed _operator, address indexed _from, address indexed _to, uint256[] _ids, uint256[] _values
    );

    // ==================== REVERT TESTS ====================

    function test_ShouldRevert_WhenFromIsZeroAddress() external {
        uint256[] memory ids = new uint256[](2);
        ids[0] = TOKEN_ID_1;
        ids[1] = TOKEN_ID_2;
        uint256[] memory values = new uint256[](2);
        values[0] = 50;
        values[1] = 50;

        vm.expectRevert(abi.encodeWithSelector(BurnMod.ERC1155InvalidSender.selector, address(0)));
        harness.burnBatch(ADDRESS_ZERO, ids, values);
    }

    function test_ShouldRevert_WhenArrayLengthMismatch() external {
        uint256[] memory ids = new uint256[](2);
        ids[0] = TOKEN_ID_1;
        ids[1] = TOKEN_ID_2;
        uint256[] memory values = new uint256[](1);
        values[0] = 50;

        vm.expectRevert(abi.encodeWithSelector(BurnMod.ERC1155InvalidArrayLength.selector, 2, 1));
        harness.burnBatch(users.alice, ids, values);
    }

    function test_ShouldRevert_WhenInsufficientBalance() external {
        uint256[] memory ids = new uint256[](2);
        ids[0] = TOKEN_ID_1;
        ids[1] = TOKEN_ID_2;
        uint256[] memory mintValues = new uint256[](2);
        mintValues[0] = 100;
        mintValues[1] = 50;
        uint256[] memory burnValues = new uint256[](2);
        burnValues[0] = 50;
        burnValues[1] = 100;

        _mintBatch(users.alice, ids, mintValues);
        vm.expectRevert(
            abi.encodeWithSelector(BurnMod.ERC1155InsufficientBalance.selector, users.alice, 50, 100, TOKEN_ID_2)
        );
        harness.burnBatch(users.alice, ids, burnValues);
    }

    // ==================== SUCCESS TESTS ====================

    function test_ShouldBurnBatch_WhenBalancesAreSufficient() external {
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
        harness.burnBatch(users.alice, ids, burnValues);

        assertEq(harness.balanceOf(users.alice, TOKEN_ID_1), 50);
        assertEq(harness.balanceOf(users.alice, TOKEN_ID_2), 100);
    }

    function test_ShouldEmitTransferBatchEvent() external {
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

        vm.expectEmit(true, true, true, true);
        emit TransferBatch(address(this), users.alice, address(0), ids, burnValues);
        harness.burnBatch(users.alice, ids, burnValues);
    }

    function test_ShouldBurnBatch_WithEmptyArrays() external {
        uint256[] memory ids = new uint256[](0);
        uint256[] memory values = new uint256[](0);
        harness.burnBatch(users.alice, ids, values);
    }

    function test_ShouldBurnBatch_WithDuplicateIds() external {
        uint256[] memory ids = new uint256[](2);
        ids[0] = TOKEN_ID_1;
        ids[1] = TOKEN_ID_1;
        uint256[] memory mintValues = new uint256[](2);
        mintValues[0] = 100;
        mintValues[1] = 100;
        uint256[] memory burnValues = new uint256[](2);
        burnValues[0] = 50;
        burnValues[1] = 50;

        _mintBatch(users.alice, ids, mintValues);
        harness.burnBatch(users.alice, ids, burnValues);
        assertEq(harness.balanceOf(users.alice, TOKEN_ID_1), 100);
    }
}
