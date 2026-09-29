// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {TestERC20} from "../src/TestERC20.sol";
import {console} from "forge-std/console.sol";

contract TestERC20Test is Test {
    TestERC20 public tErc20;

    function setUp() public {
        tErc20 = new TestERC20("TestERC20", "TestERC20", 10000000*1_000_000_000_000_000_000);
    }

    function test_Constructor() public view {
        assertEq(tErc20.name(), "TestERC20");
        assertEq(tErc20.symbol(), "TestERC20");
        assertEq(tErc20.totalSupply(), 10000000*1_000_000_000_000_000_000);
        assertEq(tErc20.balanceOf(address(this)), 10000000*1_000_000_000_000_000_000);
    }

}