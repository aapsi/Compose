// SPDX-License-Identifier: MIT
pragma solidity >=0.8.30;

/* Compose
 * https://compose.diamonds
 */

import "src/token/ERC1155/Metadata/ERC1155MetadataMod.sol" as MetadataMod;

/**
 * @title ERC1155MetadataHarness
 * @notice Test harness that exposes ERC1155MetadataMod + MetadataFacet logic for testing
 */
contract ERC1155MetadataHarness {
    event URI(string _value, uint256 indexed _id);

    function setURI(string memory _uri) external {
        MetadataMod.setURI(_uri);
    }

    function setBaseURI(string memory _baseURI) external {
        MetadataMod.setBaseURI(_baseURI);
    }

    function setTokenURI(uint256 _tokenId, string memory _tokenURI) external {
        MetadataMod.setTokenURI(_tokenId, _tokenURI);
    }

    /// @notice Mirrors ERC1155MetadataFacet.uri() logic
    function uri(uint256 _id) external view returns (string memory) {
        MetadataMod.ERC1155MetadataStorage storage s = MetadataMod.getStorage();
        string memory tokenURI = s.tokenURIs[_id];
        return bytes(tokenURI).length > 0 ? string.concat(s.baseURI, tokenURI) : s.uri;
    }

    function getDefaultURI() external view returns (string memory) {
        return MetadataMod.getStorage().uri;
    }

    function getBaseURI() external view returns (string memory) {
        return MetadataMod.getStorage().baseURI;
    }

    function getTokenURI(uint256 _tokenId) external view returns (string memory) {
        return MetadataMod.getStorage().tokenURIs[_tokenId];
    }
}
