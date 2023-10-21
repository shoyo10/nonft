// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

contract NFTReceiver is IERC721Receiver {
    function onERC721Received(address, address from, uint256 tokenId, bytes memory) public override returns (bytes4) {
        // Receiver 收到一個的其他 ERC721 token (此 Token 隨意設計就行)，
        // 若此 Token 非我們上述的 NONFT Token，就將其傳回去給原始 Token owner，
        // 同時 mint 一個這個 NONFT token 給 owner。
        // 1. check the msg.sender is same as HW_Token
        // 2. if not, please transfer the NoUseful token back to the original owner
        // 3. and also mint HW_Token for the original owner
        if (msg.sender != address(this)) {
            IERC721(msg.sender).safeTransferFrom(address(this), from, tokenId);
            HW_Token(address(this)).mint(from);
        }
        return IERC721Receiver.onERC721Received.selector;
    }
}

contract NoUseful is ERC721, IERC721Receiver {
    constructor() ERC721("NoUseful", "NU") {}

    function mint(address to, uint256 tokenId) public {
        _mint(to, tokenId);
    }

    function onERC721Received(address, address, uint256, bytes memory) public override returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }
}

contract HW_Token is ERC721, NFTReceiver {
    uint256 private _tokenId;

    // owner => tokenIds
    mapping(address => uint256[]) public ownerTokens;
    // tokenId => index int ownerTokens
    mapping(uint256 tokenId => uint256 index) public tokenIndex;

    constructor() ERC721("Don't send NFT to me", "NONFT") {
        // NFT token id start from 1
        _tokenId = 1;
    }

    function mint(address to) public returns (uint256) {
        uint256 mintedTokenId = _tokenId;

        ownerTokens[to].push(mintedTokenId);
        tokenIndex[mintedTokenId] = ownerTokens[to].length - 1;

        _tokenId++;
        _mint(to, mintedTokenId);
        return mintedTokenId;
    }

    function transferFrom(address from, address to, uint256 tokenId) public override {
        if (to == address(0)) {
            revert ERC721InvalidReceiver(address(0));
        }

        // Setting an "auth" arguments enables the `_isAuthorized` check which verifies that the token exists
        // (from != 0). Therefore, it is not needed to verify that the return value is not 0 here.
        address previousOwner = _update(to, tokenId, _msgSender());
        if (previousOwner != from) {
            revert ERC721IncorrectOwner(from, tokenId, previousOwner);
        }

        uint256 index = tokenIndex[tokenId];
        uint256[] storage tokens = ownerTokens[from];
        require(tokens[index] == tokenId, "address from do not have the iput tokenId");

        delete tokenIndex[tokenId];
        tokens[index] = tokens[tokens.length - 1];
        tokens.pop();

        ownerTokens[to].push(tokenId);
        tokenIndex[tokenId] = ownerTokens[to].length - 1;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        _requireOwned(tokenId);

        string memory baseURI = _baseURI();
        return string.concat(baseURI, "0");
    }

    function _baseURI() internal view override returns (string memory) {
        return "ipfs://QmP3De1hC7fQxUaY3rXpMV3DH5DLJ5VjyS1XhncBawgdxJ/";
    }

    function ownerTokenIds(address owner) public view returns (uint256[] memory) {
        return ownerTokens[owner];
    }

    function getTokenIndex(uint256 tokenId) public view returns (uint256) {
        return tokenIndex[tokenId];
    }
}
