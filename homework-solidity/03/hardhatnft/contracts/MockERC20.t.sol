// SPDX-License-Identifier: MIT
pragma solidity ^0.8.34;

import {Test} from "forge-std/Test.sol";
import {MockERC20} from "./MockERC20.sol";

contract MockERC20Test is Test {
    MockERC20 public token;
    address public alice;
    address public bob;
    address public charlie;

    string public constant TOKEN_NAME = "MockToken";
    string public constant TOKEN_SYMBOL = "MTK";
    uint8 public constant TOKEN_DECIMALS = 18;
    uint256 public constant INITIAL_SUPPLY = 1_000_000 * 10**18; // 1 million tokens

    function setUp() public {
        alice = makeAddr("alice");
        bob = makeAddr("bob");
        charlie = makeAddr("charlie");

        // 部署 MockERC20 合约
        token = new MockERC20(
            TOKEN_NAME,
            TOKEN_SYMBOL,
            TOKEN_DECIMALS,
            INITIAL_SUPPLY
        );
    }

    // 声明事件以便在测试中 emit
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    // =============================================
    // 测试构造函数
    // =============================================

    function test_Constructor() public view {
        // 验证代币基本信息
        assertEq(token.name(), TOKEN_NAME, "Token name should match");
        assertEq(token.symbol(), TOKEN_SYMBOL, "Token symbol should match");
        assertEq(token.decimals(), TOKEN_DECIMALS, "Token decimals should match");
        
        // 验证初始供应量
        assertEq(token.totalSupply(), INITIAL_SUPPLY, "Total supply should match initial supply");
        
        // 验证部署者获得了所有初始代币
        assertEq(token.balanceOf(address(this)), INITIAL_SUPPLY, "Deployer should have all initial supply");
    }

    function test_Constructor_WithDifferentDecimals() public {
        // 测试不同的小数位数
        uint8 testDecimals = 6;
        MockERC20 token6Decimals = new MockERC20(
            "Test6Decimals",
            "T6D",
            testDecimals,
            1000 * 10**testDecimals
        );
        
        assertEq(token6Decimals.decimals(), testDecimals, "Decimals should be 6");
        assertEq(token6Decimals.totalSupply(), 1000 * 10**testDecimals, "Supply should account for decimals");
    }

    function test_Constructor_WithZeroSupply() public {
        // 测试初始供应量为 0
        MockERC20 zeroToken = new MockERC20("ZeroToken", "ZERO", 18, 0);
        assertEq(zeroToken.totalSupply(), 0, "Total supply should be 0");
        assertEq(zeroToken.balanceOf(address(this)), 0, "Deployer balance should be 0");
    }

    // =============================================
    // 测试 decimals()
    // =============================================

    function test_Decimals() public view {
        assertEq(token.decimals(), TOKEN_DECIMALS, "decimals() should return correct value");
    }

    function test_Decimals_WithDifferentValues() public {
        // 测试不同的小数位数
        uint8[] memory decimalValues = new uint8[](4);
        decimalValues[0] = 0;
        decimalValues[1] = 6;
        decimalValues[2] = 18;
        decimalValues[3] = 36;

        for (uint256 i = 0; i < decimalValues.length; i++) {
            MockERC20 testToken = new MockERC20(
                "TestToken",
                "TT",
                decimalValues[i],
                1000 * 10**decimalValues[i]
            );
            assertEq(testToken.decimals(), decimalValues[i], "decimals() should match set value");
        }
    }

    // =============================================
    // 测试 mint()
    // =============================================

    function test_Mint() public {
        uint256 mintAmount = 1000 * 10**TOKEN_DECIMALS;
        uint256 aliceInitialBalance = token.balanceOf(alice);
        uint256 totalSupplyBefore = token.totalSupply();

        vm.prank(alice);
        token.mint(alice, mintAmount);

        // 验证余额变化
        assertEq(token.balanceOf(alice), aliceInitialBalance + mintAmount, "Alice balance should increase");
        assertEq(token.totalSupply(), totalSupplyBefore + mintAmount, "Total supply should increase");
    }

    function test_Mint_ToDifferentAddresses() public {
        uint256 mintAmount = 500 * 10**TOKEN_DECIMALS;

        // alice mint 给自己
        vm.prank(alice);
        token.mint(alice, mintAmount);
        assertEq(token.balanceOf(alice), mintAmount, "Alice should have minted tokens");

        // bob mint 给自己
        vm.prank(bob);
        token.mint(bob, mintAmount * 2);
        assertEq(token.balanceOf(bob), mintAmount * 2, "Bob should have minted tokens");

        // charlie mint 给自己
        vm.prank(charlie);
        token.mint(charlie, mintAmount * 3);
        assertEq(token.balanceOf(charlie), mintAmount * 3, "Charlie should have minted tokens");

        // 验证总供应量
        uint256 expectedTotalSupply = INITIAL_SUPPLY + mintAmount * 6;
        assertEq(token.totalSupply(), expectedTotalSupply, "Total supply should be sum of all mints");
    }

    function test_Mint_ByMultipleCallers() public {
        // 任何人都可以 mint（无权限限制）
        uint256 mintAmount = 100 * 10**TOKEN_DECIMALS;

        vm.prank(alice);
        token.mint(alice, mintAmount);
        
        vm.prank(bob);
        token.mint(bob, mintAmount);

        vm.prank(charlie);
        token.mint(charlie, mintAmount);

        assertEq(token.balanceOf(alice), mintAmount, "Alice mint should succeed");
        assertEq(token.balanceOf(bob), mintAmount, "Bob mint should succeed");
        assertEq(token.balanceOf(charlie), mintAmount, "Charlie mint should succeed");
    }

    function test_Mint_MultipleTimes() public {
        uint256 mintAmount = 100 * 10**TOKEN_DECIMALS;
        uint256 aliceBalanceBefore = token.balanceOf(alice);

        vm.prank(alice);
        token.mint(alice, mintAmount);
        vm.prank(alice);
        token.mint(alice, mintAmount);
        vm.prank(alice);
        token.mint(alice, mintAmount);

        uint256 expectedBalance = aliceBalanceBefore + mintAmount * 3;
        assertEq(token.balanceOf(alice), expectedBalance, "Multiple mints should accumulate");
    }

    function test_Mint_ZeroAmount() public {
        uint256 aliceBalanceBefore = token.balanceOf(alice);
        uint256 totalSupplyBefore = token.totalSupply();

        vm.prank(alice);
        token.mint(alice, 0);

        // 余额和总供应量不变
        assertEq(token.balanceOf(alice), aliceBalanceBefore, "Balance should not change with zero mint");
        assertEq(token.totalSupply(), totalSupplyBefore, "Total supply should not change with zero mint");
    }

    // =============================================
    // 测试 ERC20 标准功能（继承自 OpenZeppelin）
    // =============================================

    function test_Transfer() public {
        uint256 transferAmount = 100 * 10**TOKEN_DECIMALS;
        uint256 aliceInitialBalance = token.balanceOf(alice);
        uint256 bobInitialBalance = token.balanceOf(bob);

        // 先给 alice 一些代币
        vm.prank(alice);
        token.mint(alice, transferAmount * 10);

        // alice 转账给 bob
        vm.prank(alice);
        token.transfer(bob, transferAmount);

        assertEq(token.balanceOf(alice), aliceInitialBalance + transferAmount * 9, "Alice balance should decrease");
        assertEq(token.balanceOf(bob), bobInitialBalance + transferAmount, "Bob balance should increase");
    }

    function test_ApproveAndTransferFrom() public {
        uint256 amount = 100 * 10**TOKEN_DECIMALS;

        // 给 alice 一些代币
        vm.prank(alice);
        token.mint(alice, amount * 10);

        // alice 授权给 bob
        vm.prank(alice);
        token.approve(bob, amount);

        // bob 从 alice 转账给 charlie
        vm.prank(bob);
        token.transferFrom(alice, charlie, amount);

        assertEq(token.balanceOf(alice), amount * 9, "Alice balance should decrease");
        assertEq(token.balanceOf(charlie), amount, "Charlie balance should increase");
        assertEq(token.allowance(alice, bob), 0, "Allowance should be used up");
    }

    function test_Transfer_InsufficientBalance() public {
        uint256 transferAmount = 100 * 10**TOKEN_DECIMALS;

        // alice 没有足够的代币，转账应该 revert
        vm.prank(alice);
        vm.expectRevert();
        token.transfer(bob, transferAmount);
    }

    function test_Approve() public {
        uint256 approveAmount = 1000 * 10**TOKEN_DECIMALS;

        vm.prank(alice);
        token.approve(bob, approveAmount);

        assertEq(token.allowance(alice, bob), approveAmount, "Allowance should be set correctly");
    }

    function test_Approve_ZeroAmount() public {
        vm.prank(alice);
        token.approve(bob, 0);

        assertEq(token.allowance(alice, bob), 0, "Allowance should be 0");
    }

    // =============================================
    // 综合测试：模拟代币应用场景
    // =============================================

    function test_MockToken_SimulatesRealERC20() public {
        // 模拟一个完整的使用场景
        
        // 1. mint 大量代币给 alice
        uint256 amount = 10000 * 10**TOKEN_DECIMALS;
        vm.prank(alice);
        token.mint(alice, amount);

        // 2. alice 给 bob 转账
        uint256 transferAmount = 1000 * 10**TOKEN_DECIMALS;
        vm.prank(alice);
        token.transfer(bob, transferAmount);

        // 3. bob 给 charlie 转账
        uint256 bobTransferAmount = 500 * 10**TOKEN_DECIMALS;
        vm.prank(bob);
        token.transfer(charlie, bobTransferAmount);

        // 4. 验证最终余额
        uint256 expectedAliceBalance = amount - transferAmount;
        uint256 expectedBobBalance = transferAmount - bobTransferAmount;
        uint256 expectedCharlieBalance = bobTransferAmount;

        assertEq(token.balanceOf(alice), expectedAliceBalance, "Alice final balance incorrect");
        assertEq(token.balanceOf(bob), expectedBobBalance, "Bob final balance incorrect");
        assertEq(token.balanceOf(charlie), expectedCharlieBalance, "Charlie final balance incorrect");
    }

    // =============================================
    // 模糊测试
    // =============================================

    function testFuzz_Mint_TotalSupplyIncreases(uint256 mintAmount) public {
        // 限制 mintAmount 不能太大，防止溢出
        vm.assume(mintAmount <= type(uint256).max / 2);
        
        uint256 totalSupplyBefore = token.totalSupply();

        vm.prank(alice);
        token.mint(alice, mintAmount);

        assertEq(token.totalSupply(), totalSupplyBefore + mintAmount, "Total supply should increase by mint amount");
        assertEq(token.balanceOf(alice), mintAmount, "Alice should have minted tokens");
    }

    function testFuzz_Mint_MultipleAddresses(uint256 amount1, uint256 amount2) public {
        vm.assume(amount1 <= type(uint256).max / 4);
        vm.assume(amount2 <= type(uint256).max / 4);
        
        uint256 totalSupplyBefore = token.totalSupply();

        vm.prank(alice);
        token.mint(alice, amount1);

        vm.prank(bob);
        token.mint(bob, amount2);

        assertEq(token.balanceOf(alice), amount1, "Alice balance should be amount1");
        assertEq(token.balanceOf(bob), amount2, "Bob balance should be amount2");
        assertEq(token.totalSupply(), totalSupplyBefore + amount1 + amount2, "Total supply should be sum");
    }

    function testFuzz_Transfer(uint256 mintAmount, uint256 transferAmount) public {
        vm.assume(mintAmount > 0 && mintAmount <= 10**9 * 10**18);
        vm.assume(transferAmount > 0 && transferAmount <= mintAmount);
        
        // alice mint 代币给自己
        vm.prank(alice);
        token.mint(alice, mintAmount);

        uint256 aliceBalanceBefore = token.balanceOf(alice);
        uint256 bobBalanceBefore = token.balanceOf(bob);

        // alice 转账给 bob
        vm.prank(alice);
        token.transfer(bob, transferAmount);

        assertEq(token.balanceOf(alice), aliceBalanceBefore - transferAmount, "Alice balance should decrease");
        assertEq(token.balanceOf(bob), bobBalanceBefore + transferAmount, "Bob balance should increase");
    }

    function testFuzz_ApproveAndTransferFrom(uint256 mintAmount, uint256 approveAmount, uint256 transferAmount) public {
        vm.assume(mintAmount > 0 && mintAmount <= 10**9 * 10**18);
        vm.assume(approveAmount > 0 && approveAmount <= mintAmount);
        vm.assume(transferAmount > 0 && transferAmount <= approveAmount);
        
        // alice mint 代币给自己
        vm.prank(alice);
        token.mint(alice, mintAmount);

        // alice 授权给 bob
        vm.prank(alice);
        token.approve(bob, approveAmount);

        // bob 从 alice 转账给 charlie
        vm.prank(bob);
        token.transferFrom(alice, charlie, transferAmount);

        assertEq(token.balanceOf(alice), mintAmount - transferAmount, "Alice balance should decrease");
        assertEq(token.balanceOf(charlie), transferAmount, "Charlie balance should increase");
        assertEq(token.allowance(alice, bob), approveAmount - transferAmount, "Allowance should be reduced");
    }

    // =============================================
    // 边界条件测试
    // =============================================

    function test_EdgeCase_MaxUint256Mint() public {
        uint256 maxAmount = type(uint256).max;
        
        // 注意：直接 mint type(uint256).max 可能导致溢出，这里只测试合理性
        vm.prank(alice);
        vm.expectRevert(); // 预期 revert（因为总供应量会溢出）
        token.mint(alice, maxAmount);
    }

    function test_EdgeCase_MintToZeroAddress() public {
        vm.prank(alice);
        vm.expectRevert();
        token.mint(address(0), 1000);
    }

    function test_EdgeCase_TransferToZeroAddress() public {
        vm.prank(alice);
        token.mint(alice, 1000);

        vm.prank(alice);
        vm.expectRevert();
        token.transfer(address(0), 100);
    }

    // =============================================
    // 事件测试
    // =============================================

    function test_TransferEmitsEvent() public {
        uint256 amount = 100 * 10**TOKEN_DECIMALS;
        
        vm.prank(alice);
        token.mint(alice, amount);

        vm.expectEmit(true, true, false, true);
        emit Transfer(alice, bob, amount);

        vm.prank(alice);
        token.transfer(bob, amount);
    }

    function test_ApprovalEmitsEvent() public {
        uint256 amount = 100 * 10**TOKEN_DECIMALS;

        vm.expectEmit(true, true, false, true);
        emit Approval(alice, bob, amount);

        vm.prank(alice);
        token.approve(bob, amount);
    }

    function test_MintEmitsEvent() public {
        uint256 amount = 100 * 10**TOKEN_DECIMALS;

        vm.expectEmit(true, true, false, true);
        emit Transfer(address(0), alice, amount);

        vm.prank(alice);
        token.mint(alice, amount);
    }
}