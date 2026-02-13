// SPDX-License-Identifier: MIT
pragma solidity >=0.8.30;

/* Compose
 * https://compose.diamonds
 */

import {ERC1155TransferFacet} from "src/token/ERC1155/Transfer/ERC1155TransferFacet.sol";

/**
 * @title ERC1155TransferHarness
 * @notice Test harness for ERC1155 Transfer (Facet + helpers for setup)
 */
contract ERC1155TransferHarness is ERC1155TransferFacet {
    error ERC1155InvalidOperator(address _operator);

    event ApprovalForAll(address indexed _account, address indexed _operator, bool _approved);

    function mint(address _to, uint256 _id, uint256 _value) external {
        if (_to == address(0)) revert ERC1155InvalidReceiver(address(0));
        ERC1155Storage storage s = getStorage();
        s.balanceOf[_id][_to] += _value;
        emit TransferSingle(msg.sender, address(0), _to, _id, _value);
    }

    function mintBatch(address _to, uint256[] memory _ids, uint256[] memory _values) external {
        if (_to == address(0)) revert ERC1155InvalidReceiver(address(0));
        if (_ids.length != _values.length) revert ERC1155InvalidArrayLength(_ids.length, _values.length);
        ERC1155Storage storage s = getStorage();
        for (uint256 i = 0; i < _ids.length; i++) {
            s.balanceOf[_ids[i]][_to] += _values[i];
        }
        emit TransferBatch(msg.sender, address(0), _to, _ids, _values);
    }

    function balanceOf(address _account, uint256 _id) external view returns (uint256) {
        return getStorage().balanceOf[_id][_account];
    }

    function setApprovalForAll(address _operator, bool _approved) external {
        if (_operator == address(0)) revert ERC1155InvalidOperator(address(0));
        getStorage().isApprovedForAll[msg.sender][_operator] = _approved;
        emit ApprovalForAll(msg.sender, _operator, _approved);
    }

    function isApprovedForAll(address _account, address _operator) external view returns (bool) {
        return getStorage().isApprovedForAll[_account][_operator];
    }
}
