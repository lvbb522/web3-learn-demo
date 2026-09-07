// SPDX-License-Identifier: MIT
pragma solidity ^0.8.34;

import {Test} from "forge-std/Test.sol";
import {MetaNFT} from "./MetaNFT.sol";

contract MetaNFTTest is Test {
    MetaNFT public nft;
    address public alice;
    address public bob;
    address public charlie;

    function setUp() public {
        // 创建测试地址
        alice = makeAddr("alice");
        bob = makeAddr("bob");
        charlie = makeAddr("charlie");

        // 部署 NFT 合约
        nft = new MetaNFT();
    }

    // ========== 测试构造函数 ==========
    function test_NameAndSymbol() public view {
        assertEq(nft.name(), "MetaNFT");
        assertEq(nft.symbol(), "MFT");
    }

    // ========== 测试 mint ==========
    function test_Mint() public {
        uint256 tokenId = 1;
        vm.prank(alice);
        nft.mint(alice, tokenId);

        // 验证代币归属
        assertEq(nft.ownerOf(tokenId), alice);
        assertEq(nft.balanceOf(alice), 1);
    }

    function test_MintByNonOwner() public {
        uint256 tokenId = 1;
        // bob 尝试 mint（应该成功，因为 mint 没有权限限制）
        vm.prank(bob);
        nft.mint(bob, tokenId);

        assertEq(nft.ownerOf(tokenId), bob);
        assertEq(nft.balanceOf(bob), 1);
    }

    function test_MintDuplicateTokenId() public {
        uint256 tokenId = 1;
        vm.prank(alice);
        nft.mint(alice, tokenId);

        // 尝试 mint 相同的 tokenId（应该 revert）
        vm.prank(bob);
        vm.expectRevert();
        nft.mint(bob, tokenId);
    }

    // ========== 测试 mintNext ==========
    function test_MintNext() public {
        vm.prank(alice);
        uint256 tokenId = nft.mintNext(alice);

        // 第一次 mint，_nextId 从 1 开始
        assertEq(tokenId, 1);
        assertEq(nft.ownerOf(tokenId), alice);
        assertEq(nft.balanceOf(alice), 1);
    }

    function test_MintNext_Multiple() public {
        // alice mint 第一个
        vm.prank(alice);
        uint256 tokenId1 = nft.mintNext(alice);
        assertEq(tokenId1, 1);

        // bob mint 第二个
        vm.prank(bob);
        uint256 tokenId2 = nft.mintNext(bob);
        assertEq(tokenId2, 2);

        // alice mint 第三个
        vm.prank(alice);
        uint256 tokenId3 = nft.mintNext(alice);
        assertEq(tokenId3, 3);

        // 验证所有权
        assertEq(nft.ownerOf(1), alice);
        assertEq(nft.ownerOf(2), bob);
        assertEq(nft.ownerOf(3), alice);

        // 验证余额
        assertEq(nft.balanceOf(alice), 2);
        assertEq(nft.balanceOf(bob), 1);
    }

    // ========== 测试 burn ==========
    function test_Burn() public {
        // 先 mint 一个 NFT 给 alice
        vm.prank(alice);
        nft.mint(alice, 1);

        // alice 销毁自己的 NFT
        vm.prank(alice);
        nft.burn(1);

        // 验证已销毁
        vm.expectRevert();
        nft.ownerOf(1);

        assertEq(nft.balanceOf(alice), 0);
    }

    function test_BurnByNonOwner() public {
        // 先 mint 一个 NFT 给 alice
        vm.prank(alice);
        nft.mint(alice, 1);

        // bob 尝试销毁 alice 的 NFT（应该 revert）
        vm.prank(bob);
        vm.expectRevert("not owner");
        nft.burn(1);

        // 验证代币仍然属于 alice
        assertEq(nft.ownerOf(1), alice);
        assertEq(nft.balanceOf(alice), 1);
    }

    function test_BurnAlreadyBurned() public {
        // 先 mint 一个 NFT 给 alice
        vm.prank(alice);
        nft.mint(alice, 1);

        // alice 销毁自己的 NFT
        vm.prank(alice);
        nft.burn(1);

        // 再次尝试销毁（应该 revert）
        vm.prank(alice);
        vm.expectRevert();
        nft.burn(1);
    }

    // ========== 模糊测试 (Fuzz Testing) ==========
    function testFuzz_MintNext_GeneratesSequentialIds(uint8 count) public {
        // 限制 count 不要太大，防止 gas 耗尽
        vm.assume(count > 0 && count <= 50);

        for (uint8 i = 0; i < count; i++) {
            vm.prank(alice);
            uint256 tokenId = nft.mintNext(alice);
            assertEq(tokenId, i + 1);
            assertEq(nft.ownerOf(tokenId), alice);
        }

        assertEq(nft.balanceOf(alice), count);
    }

    function testFuzz_BurnOnlyOwner(address mintTo, address burner) public {
        // 限制地址不为零地址
        vm.assume(mintTo != address(0));
        vm.assume(burner != address(0));

        // 先 mint 一个 NFT
        vm.prank(mintTo);
        nft.mint(mintTo, 1);

        // 如果 mintTo 就是 burner，应该成功
        if (mintTo == burner) {
            vm.prank(burner);
            nft.burn(1);
            vm.expectRevert();
            nft.ownerOf(1);
        } else {
            // 否则应该 revert
            vm.prank(burner);
            vm.expectRevert("not owner");
            nft.burn(1);
            // 验证代币仍然属于原主人
            assertEq(nft.ownerOf(1), mintTo);
        }
    }

    // ========== 测试转账后的销毁 ==========
    function test_BurnAfterTransfer() public {
        // alice mint
        vm.prank(alice);
        nft.mint(alice, 1);

        // alice 转给 bob
        vm.prank(alice);
        nft.transferFrom(alice, bob, 1);

        // bob 销毁（应该成功）
        vm.prank(bob);
        nft.burn(1);

        vm.expectRevert();
        nft.ownerOf(1);

        assertEq(nft.balanceOf(alice), 0);
        assertEq(nft.balanceOf(bob), 0);
    }

    // ========== 测试安全转移 (safeTransferFrom) ==========
    function test_SafeTransferFrom() public {
        vm.prank(alice);
        nft.mint(alice, 1);

        vm.prank(alice);
        nft.safeTransferFrom(alice, bob, 1);

        assertEq(nft.ownerOf(1), bob);
        assertEq(nft.balanceOf(alice), 0);
        assertEq(nft.balanceOf(bob), 1);
    }

    // ========== 测试接收者是一个合约 ==========
    // 注意：ERC721 默认不会阻止向合约转账，除非该合约没有实现 onERC721Received
    function test_TransferToContract() public {
        // 创建一个没有实现 onERC721Received 的合约
        address simpleContract = address(new SimpleContract());

        vm.prank(alice);
        nft.mint(alice, 1);

        // 转账到合约应该成功（因为 ERC721 默认允许）
        vm.prank(alice);
        nft.transferFrom(alice, simpleContract, 1);

        assertEq(nft.ownerOf(1), simpleContract);
    }
}

// 辅助合约：用于测试转账到合约
contract SimpleContract {
    // 没有实现 onERC721Received，测试安全转账行为
}