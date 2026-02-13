// SPDX-License-Identifier: MIT
pragma solidity >=0.8.30;

/* Compose
 * https://compose.diamonds
 */

import "src/token/ERC1155/Approve/ERC1155ApproveMod.sol" as ApproveMod;

/**
 * @title ERC1155ApproveHarness
 * @notice Test harness that exposes ERC1155ApproveMod's internal functions as external
 * and also provides a facet-style setApprovalForAll (using msg.sender)
 */
contract ERC1155ApproveHarness {
    error ERC1155InvalidOperator(address _operator);

    event ApprovalForAll(address indexed _account, address indexed _operator, bool _approved);

    /**
     * @notice Mod-level: set approval using explicit user address
     */
    function setApprovalForAll_Mod(address _user, address _operator, bool _approved) external {
        ApproveMod.setApprovalForAll(_user, _operator, _approved);
    }

    /**
     * @notice Facet-level: set approval using msg.sender as owner
     */
    function setApprovalForAll(address _operator, bool _approved) external {
        if (_operator == address(0)) {
            revert ERC1155InvalidOperator(address(0));
        }
        ApproveMod.getStorage().isApprovedForAll[msg.sender][_operator] = _approved;
        emit ApprovalForAll(msg.sender, _operator, _approved);
    }

    /**
     * @notice Check if an operator is approved for all tokens of an account
     */
    function isApprovedForAll(address _account, address _operator) external view returns (bool) {
        return ApproveMod.getStorage().isApprovedForAll[_account][_operator];
    }
}
