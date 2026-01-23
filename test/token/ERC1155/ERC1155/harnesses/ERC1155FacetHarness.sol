// SPDX-License-Identifier: MIT
pragma solidity >=0.8.30;

/* Compose
 * https://compose.diamonds
 */

import {ERC1155TransferFacet} from "../../../../../src/token/ERC1155/Transfer/ERC1155TransferFacet.sol";

/**
 * @title ERC1155FacetHarness
 * @notice Test harness for ERC1155 Facets that adds initialization and minting for testing
 * @dev Extends ERC1155TransferFacet and adds additional helper methods for testing
 */
contract ERC1155FacetHarness is ERC1155TransferFacet {
    /**
     * @notice Error indicating the operator address is invalid.
     * @param _operator Invalid operator address.
     */
    error ERC1155InvalidOperator(address _operator);

    /**
     * @notice Emitted when `account` grants or revokes permission to `operator` to transfer their tokens.
     * @param _account The token owner granting/revoking approval.
     * @param _operator The address being approved/revoked.
     * @param _approved True if approval is granted, false if revoked.
     */
    event ApprovalForAll(address indexed _account, address indexed _operator, bool _approved);

    /**
     * @notice Emitted when the URI for token type `_id` changes to `_value`.
     * @param _value The new URI for the token type.
     * @param _id The token type whose URI changed.
     */
    event URI(string _value, uint256 indexed _id);

    /**
     * @dev Storage position for ERC-1155 metadata.
     */
    bytes32 constant METADATA_STORAGE_POSITION = keccak256("erc1155.metadata");

    /**
     * @custom:storage-location erc8042:erc1155.metadata
     */
    struct ERC1155MetadataStorage {
        string uri;
        string baseURI;
        mapping(uint256 tokenId => string) tokenURIs;
    }

    /**
     * @notice Returns the ERC-1155 metadata storage struct.
     * @dev Uses inline assembly to set the storage slot reference.
     * @return s The ERC-1155 metadata storage struct reference.
     */
    function getMetadataStorage() internal pure returns (ERC1155MetadataStorage storage s) {
        bytes32 position = METADATA_STORAGE_POSITION;
        assembly {
            s.slot := position
        }
    }

    /**
     * @notice Initialize the ERC1155 storage
     * @dev Only used for testing - production diamonds should initialize in constructor
     */
    function initialize(string memory _uri) external {
        ERC1155MetadataStorage storage s = getMetadataStorage();
        s.uri = _uri;
    }

    /**
     * @notice Set the base URI
     * @dev Only used for testing
     */
    function setBaseURI(string memory _baseURI) external {
        ERC1155MetadataStorage storage s = getMetadataStorage();
        s.baseURI = _baseURI;
    }

    /**
     * @notice Set a token-specific URI
     * @dev Only used for testing
     */
    function setTokenURI(uint256 _tokenId, string memory _tokenURI) external {
        ERC1155MetadataStorage storage s = getMetadataStorage();
        s.tokenURIs[_tokenId] = _tokenURI;
        string memory fullURI = bytes(_tokenURI).length > 0 ? string.concat(s.baseURI, _tokenURI) : s.uri;
        emit URI(fullURI, _tokenId);
    }

    /**
     * @notice Returns the URI for token type `_id`.
     */
    function uri(uint256 _id) external view returns (string memory) {
        ERC1155MetadataStorage storage s = getMetadataStorage();
        string memory tokenURI = s.tokenURIs[_id];
        return bytes(tokenURI).length > 0 ? string.concat(s.baseURI, tokenURI) : s.uri;
    }

    /**
     * @notice Returns the amount of tokens of token type `id` owned by `account`.
     */
    function balanceOf(address _account, uint256 _id) external view returns (uint256) {
        return getStorage().balanceOf[_id][_account];
    }

    /**
     * @notice Batched version of {balanceOf}.
     */
    function balanceOfBatch(address[] calldata _accounts, uint256[] calldata _ids)
        external
        view
        returns (uint256[] memory balances)
    {
        if (_accounts.length != _ids.length) {
            revert ERC1155InvalidArrayLength(_ids.length, _accounts.length);
        }

        ERC1155Storage storage s = getStorage();
        balances = new uint256[](_accounts.length);

        for (uint256 i = 0; i < _accounts.length; i++) {
            balances[i] = s.balanceOf[_ids[i]][_accounts[i]];
        }
    }

    /**
     * @notice Returns true if `operator` is approved to transfer `account`'s tokens.
     */
    function isApprovedForAll(address _account, address _operator) external view returns (bool) {
        return getStorage().isApprovedForAll[_account][_operator];
    }

    /**
     * @notice Grants or revokes permission to `operator` to transfer the caller's tokens.
     * @dev Emits an {ApprovalForAll} event.
     * @param _operator The address to grant/revoke approval to.
     * @param _approved True to approve, false to revoke.
     */
    function setApprovalForAll(address _operator, bool _approved) external {
        if (_operator == address(0)) {
            revert ERC1155InvalidOperator(address(0));
        }
        getStorage().isApprovedForAll[msg.sender][_operator] = _approved;
        emit ApprovalForAll(msg.sender, _operator, _approved);
    }

    /**
     * @notice Mint tokens to an address
     * @dev Only used for testing - exposes internal mint functionality
     */
    function mint(address _to, uint256 _id, uint256 _value) external {
        if (_to == address(0)) {
            revert ERC1155InvalidReceiver(address(0));
        }
        ERC1155Storage storage s = getStorage();
        s.balanceOf[_id][_to] += _value;
        emit TransferSingle(msg.sender, address(0), _to, _id, _value);
    }

    /**
     * @notice Mint multiple token types to an address
     * @dev Only used for testing - exposes internal mintBatch functionality
     */
    function mintBatch(address _to, uint256[] memory _ids, uint256[] memory _values) external {
        if (_to == address(0)) {
            revert ERC1155InvalidReceiver(address(0));
        }
        if (_ids.length != _values.length) {
            revert ERC1155InvalidArrayLength(_ids.length, _values.length);
        }
        ERC1155Storage storage s = getStorage();
        for (uint256 i = 0; i < _ids.length; i++) {
            s.balanceOf[_ids[i]][_to] += _values[i];
        }
        emit TransferBatch(msg.sender, address(0), _to, _ids, _values);
    }

    /**
     * @notice Burn tokens from an address
     * @dev Only used for testing - exposes internal burn functionality
     */
    function burn(address _from, uint256 _id, uint256 _value) external {
        if (_from == address(0)) {
            revert ERC1155InvalidSender(address(0));
        }
        ERC1155Storage storage s = getStorage();
        uint256 fromBalance = s.balanceOf[_id][_from];
        if (fromBalance < _value) {
            revert ERC1155InsufficientBalance(_from, fromBalance, _value, _id);
        }
        unchecked {
            s.balanceOf[_id][_from] = fromBalance - _value;
        }
        emit TransferSingle(msg.sender, _from, address(0), _id, _value);
    }

    /**
     * @notice Burn multiple token types from an address
     * @dev Only used for testing - exposes internal burnBatch functionality
     */
    function burnBatch(address _from, uint256[] memory _ids, uint256[] memory _values) external {
        if (_from == address(0)) {
            revert ERC1155InvalidSender(address(0));
        }
        if (_ids.length != _values.length) {
            revert ERC1155InvalidArrayLength(_ids.length, _values.length);
        }
        ERC1155Storage storage s = getStorage();
        for (uint256 i = 0; i < _ids.length; i++) {
            uint256 id = _ids[i];
            uint256 value = _values[i];
            uint256 fromBalance = s.balanceOf[id][_from];
            if (fromBalance < value) {
                revert ERC1155InsufficientBalance(_from, fromBalance, value, id);
            }
            unchecked {
                s.balanceOf[id][_from] = fromBalance - value;
            }
        }
        emit TransferBatch(msg.sender, _from, address(0), _ids, _values);
    }
}
