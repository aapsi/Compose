// SPDX-License-Identifier: MIT
pragma solidity >=0.8.30;

/* Compose
 * https://compose.diamonds
 */

import {Base_Test} from "test/Base.t.sol";
import {ERC1155MetadataHarness} from "./harnesses/ERC1155MetadataHarness.sol";

/**
 * @title ERC1155Metadata_Base_Test
 * @notice Base test contract for ERC1155 Metadata tests
 */
abstract contract ERC1155Metadata_Base_Test is Base_Test {
    ERC1155MetadataHarness internal harness;

    function setUp() public virtual override {
        Base_Test.setUp();
        harness = new ERC1155MetadataHarness();
        vm.label(address(harness), "ERC1155MetadataHarness");
    }
}

// =============================================================
//                         SET URI
// =============================================================

contract SetURI_ERC1155Metadata_Test is ERC1155Metadata_Base_Test {
    function test_ShouldSetDefaultURI() external {
        harness.setURI(DEFAULT_URI);
        assertEq(harness.getDefaultURI(), DEFAULT_URI);
    }

    function test_ShouldOverwriteExistingURI() external {
        harness.setURI(DEFAULT_URI);
        harness.setURI("https://new.uri/{id}.json");
        assertEq(harness.getDefaultURI(), "https://new.uri/{id}.json");
    }

    function test_ShouldSetEmptyURI() external {
        harness.setURI(DEFAULT_URI);
        harness.setURI("");
        assertEq(harness.getDefaultURI(), "");
    }

    function testFuzz_SetURI(string memory _uri) external {
        harness.setURI(_uri);
        assertEq(harness.getDefaultURI(), _uri);
    }
}

// =============================================================
//                       SET BASE URI
// =============================================================

contract SetBaseURI_ERC1155Metadata_Test is ERC1155Metadata_Base_Test {
    function test_ShouldSetBaseURI() external {
        harness.setBaseURI(BASE_URI);
        assertEq(harness.getBaseURI(), BASE_URI);
    }

    function test_ShouldOverwriteExistingBaseURI() external {
        harness.setBaseURI(BASE_URI);
        harness.setBaseURI("https://new.base/");
        assertEq(harness.getBaseURI(), "https://new.base/");
    }

    function test_ShouldSetEmptyBaseURI() external {
        harness.setBaseURI(BASE_URI);
        harness.setBaseURI("");
        assertEq(harness.getBaseURI(), "");
    }

    function testFuzz_SetBaseURI(string memory baseURI) external {
        harness.setBaseURI(baseURI);
        assertEq(harness.getBaseURI(), baseURI);
    }
}

// =============================================================
//                      SET TOKEN URI
// =============================================================

contract SetTokenURI_ERC1155Metadata_Test is ERC1155Metadata_Base_Test {
    event URI(string _value, uint256 indexed _id);

    function test_ShouldSetTokenURI() external {
        harness.setTokenURI(TOKEN_ID_1, TOKEN_URI);
        assertEq(harness.getTokenURI(TOKEN_ID_1), TOKEN_URI);
    }

    function test_ShouldOverwriteExistingTokenURI() external {
        harness.setTokenURI(TOKEN_ID_1, TOKEN_URI);
        harness.setTokenURI(TOKEN_ID_1, "new-token.json");
        assertEq(harness.getTokenURI(TOKEN_ID_1), "new-token.json");
    }

    function test_ShouldSetDifferentURIsForDifferentTokens() external {
        harness.setTokenURI(TOKEN_ID_1, "token1.json");
        harness.setTokenURI(TOKEN_ID_2, "token2.json");
        harness.setTokenURI(TOKEN_ID_3, "token3.json");
        assertEq(harness.getTokenURI(TOKEN_ID_1), "token1.json");
        assertEq(harness.getTokenURI(TOKEN_ID_2), "token2.json");
        assertEq(harness.getTokenURI(TOKEN_ID_3), "token3.json");
    }

    function test_ShouldEmitURIEvent_WithBaseURIConcatenated() external {
        harness.setBaseURI(BASE_URI);

        vm.expectEmit(true, true, true, true);
        emit URI(string.concat(BASE_URI, TOKEN_URI), TOKEN_ID_1);
        harness.setTokenURI(TOKEN_ID_1, TOKEN_URI);
    }

    function test_ShouldEmitURIEvent_WithDefaultURI_WhenTokenURIIsEmpty() external {
        harness.setURI(DEFAULT_URI);

        vm.expectEmit(true, true, true, true);
        emit URI(DEFAULT_URI, TOKEN_ID_1);
        harness.setTokenURI(TOKEN_ID_1, "");
    }

    function test_ShouldClearTokenURI() external {
        harness.setTokenURI(TOKEN_ID_1, TOKEN_URI);
        harness.setTokenURI(TOKEN_ID_1, "");
        assertEq(harness.getTokenURI(TOKEN_ID_1), "");
    }

    function testFuzz_SetTokenURI(uint256 tokenId, string memory tokenURI) external {
        harness.setTokenURI(tokenId, tokenURI);
        assertEq(harness.getTokenURI(tokenId), tokenURI);
    }
}

// =============================================================
//                       URI (VIEW)
// =============================================================

contract Uri_ERC1155Metadata_Test is ERC1155Metadata_Base_Test {
    function test_ShouldReturnDefaultURI_WhenNoTokenURISet() external {
        harness.setURI(DEFAULT_URI);
        assertEq(harness.uri(TOKEN_ID_1), DEFAULT_URI);
    }

    function test_ShouldReturnEmptyString_WhenNoURIsSet() external view {
        assertEq(harness.uri(TOKEN_ID_1), "");
    }

    function test_ShouldReturnTokenURI_WhenTokenURISet() external {
        harness.setTokenURI(TOKEN_ID_1, TOKEN_URI);
        assertEq(harness.uri(TOKEN_ID_1), TOKEN_URI);
    }

    function test_ShouldReturnConcatenatedURI_WhenBaseAndTokenURISet() external {
        harness.setBaseURI(BASE_URI);
        harness.setTokenURI(TOKEN_ID_1, TOKEN_URI);
        assertEq(harness.uri(TOKEN_ID_1), string.concat(BASE_URI, TOKEN_URI));
    }

    function test_ShouldReturnDefaultURI_WhenOnlyBaseURISet() external {
        harness.setURI(DEFAULT_URI);
        harness.setBaseURI(BASE_URI);
        // No token-specific URI, should fall back to default
        assertEq(harness.uri(TOKEN_ID_1), DEFAULT_URI);
    }

    function test_ShouldReturnDifferentURIs_ForDifferentTokens() external {
        harness.setURI(DEFAULT_URI);
        harness.setBaseURI(BASE_URI);
        harness.setTokenURI(TOKEN_ID_1, "token1.json");
        harness.setTokenURI(TOKEN_ID_2, "token2.json");

        assertEq(harness.uri(TOKEN_ID_1), string.concat(BASE_URI, "token1.json"));
        assertEq(harness.uri(TOKEN_ID_2), string.concat(BASE_URI, "token2.json"));
        assertEq(harness.uri(TOKEN_ID_3), DEFAULT_URI); // fallback
    }

    function test_ShouldReturnDefaultURI_AfterClearingTokenURI() external {
        harness.setURI(DEFAULT_URI);
        harness.setTokenURI(TOKEN_ID_1, TOKEN_URI);
        harness.setTokenURI(TOKEN_ID_1, "");
        assertEq(harness.uri(TOKEN_ID_1), DEFAULT_URI);
    }
}
