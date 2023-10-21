// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import {Test, Vm} from "forge-std/Test.sol";
import {NoUseful, HW_Token} from "../src/Nonft.sol";

contract NonftTest is Test {
    NoUseful public nousefulNft;
    HW_Token public noNft;
    address public user1;
    address public user2;

    function setUp() public {
        nousefulNft = new NoUseful();
        noNft = new HW_Token();
        user1 = makeAddr("user1");
        user2 = makeAddr("user2");
    }

    function test_NoUsefulMint() public {
        nousefulNft.mint(user1, 1);
        assertEq(nousefulNft.ownerOf(1), user1);
    }

    function test_NoUsefulSafeTransferFrom() public {
        nousefulNft.mint(user1, 1);
        assertEq(nousefulNft.ownerOf(1), user1);

        vm.startPrank(user1);
        nousefulNft.safeTransferFrom(user1, user2, 1);
        vm.stopPrank();
        
        assertEq(nousefulNft.ownerOf(1), user2);
    }

    function test_HWToknMint() public {
        uint256 tokenId = noNft.mint(user1);
        assertEq(noNft.ownerOf(tokenId), user1);

        uint256[] memory tokenIds = noNft.ownerTokenIds(user1);
        uint256[] memory expect1 = new uint256[](1);
        expect1[0] = 1;
        assertEq(expect1, tokenIds);
        assertEq(0, noNft.getTokenIndex(tokenId));

        tokenId = noNft.mint(user1);
        assertEq(noNft.ownerOf(tokenId), user1);

        tokenIds = noNft.ownerTokenIds(user1);
        uint256[] memory expect2 = new uint256[](2);
        expect2[0] = 1;
        expect2[1] = 2;
        assertEq(expect2, tokenIds);
        assertEq(0, noNft.getTokenIndex(1));
        assertEq(1, noNft.getTokenIndex(2));
    }

    function test_HWToknSafeTransferFrom() public {
        // user1 mint 1個 NFT 後轉給 user2 的 case
        uint256 tokenId = noNft.mint(user1);
        assertEq(noNft.ownerOf(tokenId), user1);

        vm.startPrank(user1);
        noNft.safeTransferFrom(user1, user2, tokenId);
        vm.stopPrank();
        
        assertEq(noNft.ownerOf(tokenId), user2);

        uint256[] memory tokenIds = noNft.ownerTokenIds(user1);
        uint256[] memory expect1 = new uint256[](0);
        assertEq(expect1, tokenIds);

        tokenIds = noNft.ownerTokenIds(user2);
        expect1 = new uint256[](1);
        expect1[0] = 1;
        assertEq(expect1, tokenIds);

        // user1 mint 2 個 NFT 後轉給 user2 一個的 case
        uint256 tokenId2 = noNft.mint(user1);
        assertEq(noNft.ownerOf(tokenId2), user1);
        assertEq(2, tokenId2);
        uint256 tokenId3 = noNft.mint(user1);
        assertEq(noNft.ownerOf(tokenId3), user1);
        assertEq(3, tokenId3);

        tokenIds = noNft.ownerTokenIds(user1);
        expect1 = new uint256[](2);
        expect1[0] = 2;
        expect1[1] = 3;
        assertEq(expect1, tokenIds);
        assertEq(0, noNft.getTokenIndex(tokenId2));
        assertEq(1, noNft.getTokenIndex(tokenId3));
        assertEq(2, noNft.balanceOf(user1));

        vm.startPrank(user1);
        noNft.safeTransferFrom(user1, user2, tokenId3);
        vm.stopPrank();

        assertEq(noNft.ownerOf(tokenId3), user2);

        tokenIds = noNft.ownerTokenIds(user1);
        expect1 = new uint256[](1);
        expect1[0] = 2;
        assertEq(expect1, tokenIds);
        assertEq(0, noNft.getTokenIndex(tokenId2));
        assertEq(1, noNft.balanceOf(user1));

        tokenIds = noNft.ownerTokenIds(user2);
        expect1 = new uint256[](2);
        expect1[0] = 1;
        expect1[1] = 3;
        assertEq(expect1, tokenIds);
        assertEq(0, noNft.getTokenIndex(tokenId));
        assertEq(1, noNft.getTokenIndex(tokenId3));
        assertEq(2, noNft.balanceOf(user2));
    }

    function test_NoUsefulSafeTransferFromToHWTokn() public {
        nousefulNft.mint(user1, 1);
        assertEq(nousefulNft.ownerOf(1), user1);

        vm.startPrank(user1);
        nousefulNft.safeTransferFrom(user1, address(noNft), 1);
        vm.stopPrank();
        
        assertEq(0, nousefulNft.balanceOf(address(noNft)));
        assertEq(nousefulNft.ownerOf(1), user1);
        assertEq(noNft.ownerOf(1), user1);
    }

    function test_test_HWToknTokenURI() public {
        uint256 tokenId1 = noNft.mint(user1);
        assertEq(noNft.ownerOf(tokenId1), user1);
        assertEq(1, tokenId1);
        uint256 tokenId2 = noNft.mint(user1);
        assertEq(noNft.ownerOf(tokenId2), user1);
        assertEq(2, tokenId2);
        assertEq(noNft.tokenURI(tokenId1), noNft.tokenURI(tokenId2));
        assertEq("ipfs://QmP3De1hC7fQxUaY3rXpMV3DH5DLJ5VjyS1XhncBawgdxJ/0", noNft.tokenURI(tokenId2));
    }
}