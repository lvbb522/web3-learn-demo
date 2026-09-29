// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {MetaNodeToken} from "../src/MetaNodeToken.sol";
import {console} from "forge-std/console.sol";

contract MetaNodeTokenTest is Test {
    MetaNodeToken public token;

    function setUp() public {
        token = new MetaNodeToken();
    }

    function test_Constructor() public view {
        assertEq(token.name(), "MetaNodeToken");
        assertEq(token.symbol(), "MetaNode");
        assertEq(token.totalSupply(), 10000000*1_000_000_000_000_000_000);
        console.log(address(this));
        console.log(token.balanceOf(address(this)));
        assertEq(token.balanceOf(address(this)), 10000000*1_000_000_000_000_000_000);
    }

    function test_Transfer() public {
        address alice = address(0xA11CE);
        uint256 amount = 1000 * 10 ** 18;

        // 测试合约当前持有全部代币
        uint256 initialBalance = token.balanceOf(address(this));
        assertEq(initialBalance, token.totalSupply());

        // 测试合约转给 alice
        token.transfer(alice, amount);

        // 验证余额变化
        assertEq(token.balanceOf(alice), amount);
        assertEq(token.balanceOf(address(this)), initialBalance - amount);
    }

    function test_TransferFromAliceToBob() public {
        address alice = address(0xA11CE);
        address bob = address(0xB0B);
        uint256 amount = 1000 * 10 ** 18;

        // 1. 测试合约先转给 alice
        token.transfer(alice, amount);
        assertEq(token.balanceOf(alice), amount);

        // 2. 用 vm.prank 模拟 alice 调用 transfer
        vm.prank(alice);
        token.transfer(bob, amount);

        // 3. 验证余额
        assertEq(token.balanceOf(alice), 0);
        assertEq(token.balanceOf(bob), amount);
    }

    function test_TransferRevertsWhenInsufficientBalance() public {
        address alice = address(0xA11CE);
        uint256 amount = 1000 * 10 ** 18;

        // alice 没有任何代币，转账应该失败
        vm.prank(alice);
        vm.expectRevert();  // 预期回滚
        token.transfer(address(0xB0B), amount);
    }

    function test_TransferToZeroAddressReverts() public {
        vm.expectRevert();
        token.transfer(address(0), 1000);
    }
}
