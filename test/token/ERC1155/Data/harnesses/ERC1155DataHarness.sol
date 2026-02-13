// SPDX-License-Identifier: MIT
pragma solidity >=0.8.30;

/* Compose
 * https://compose.diamonds
 */

import {ERC1155DataFacet} from "src/token/ERC1155/Data/ERC1155DataFacet.sol";

/**
 * @title ERC1155DataHarness
 * @notice Test harness for ERC1155DataFacet, adds mint/approve helpers for test setup
 */
contract ERC1155DataHarness is ERC1155DataFacet {
    error ERC1155InvalidReceiver(address _receiver);
    error ERC1155InvalidOperator(address _operator);

    event TransferSingle(
        address indexed _operator, address indexed _from, address indexed _to, uint256 _id, uint256 _value
    );
    event TransferBatch(
        address indexed _operator, address indexed _from, address indexed _to, uint256[] _ids, uint256[] _values
    );
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

    function setApprovalForAll(address _operator, bool _approved) external {
        if (_operator == address(0)) revert ERC1155InvalidOperator(address(0));
        getStorage().isApprovedForAll[msg.sender][_operator] = _approved;
        emit ApprovalForAll(msg.sender, _operator, _approved);
    }
}
