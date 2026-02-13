// SPDX-License-Identifier: MIT
pragma solidity >=0.8.30;

/* Compose
 * https://compose.diamonds
 */

import "src/token/ERC1155/Mint/ERC1155MintMod.sol" as MintMod;

/**
 * @title ERC1155MintHarness
 * @notice Test harness that exposes ERC1155MintMod's internal functions as external
 */
contract ERC1155MintHarness {
    function mint(address _to, uint256 _id, uint256 _value, bytes memory _data) external {
        MintMod.mint(_to, _id, _value, _data);
    }

    function mint(address _to, uint256 _id, uint256 _value) external {
        MintMod.mint(_to, _id, _value, new bytes(0));
    }

    function mintBatch(address _to, uint256[] memory _ids, uint256[] memory _values, bytes memory _data) external {
        MintMod.mintBatch(_to, _ids, _values, _data);
    }

    function mintBatch(address _to, uint256[] memory _ids, uint256[] memory _values) external {
        MintMod.mintBatch(_to, _ids, _values, new bytes(0));
    }

    function balanceOf(address _account, uint256 _id) external view returns (uint256) {
        return MintMod.getStorage().balanceOf[_id][_account];
    }
}
