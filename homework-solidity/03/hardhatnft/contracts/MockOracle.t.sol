// SPDX-License-Identifier: MIT
pragma solidity ^0.8.34;

import {Test} from "forge-std/Test.sol";
import {MockOracle} from "./MockOracle.sol";

contract MockOracleTest is Test {
    MockOracle public oracle;
    int256 public constant INITIAL_PRICE = 1000;

    function setUp() public {
        // 部署 MockOracle 合约，初始价格设为 1000
        oracle = new MockOracle(INITIAL_PRICE);
    }

    // =============================================
    // 测试构造函数
    // =============================================

    function test_Constructor() public view {
        // 验证初始价格是否正确设置
        assertEq(oracle.getPrice(), INITIAL_PRICE, "Initial price should be 1000");
    }

    function test_Constructor_WithZeroPrice() public {
        // 测试初始价格为 0
        MockOracle zeroOracle = new MockOracle(0);
        assertEq(zeroOracle.getPrice(), 0, "Price should be 0");
    }

    function test_Constructor_WithNegativePrice() public {
        // 测试初始价格为负数
        int256 negativePrice = -500;
        MockOracle negativeOracle = new MockOracle(negativePrice);
        assertEq(negativeOracle.getPrice(), negativePrice, "Should handle negative price");
    }

    // =============================================
    // 测试 getPrice()
    // =============================================

    function test_GetPrice() public view {
        // 验证 getPrice 返回正确的当前价格
        assertEq(oracle.getPrice(), INITIAL_PRICE, "getPrice should return current price");
    }

    function test_GetPrice_AfterSetPrice() public {
        int256 newPrice = 2500;
        oracle.setPrice(newPrice);
        assertEq(oracle.getPrice(), newPrice, "getPrice should return updated price");
    }

    // =============================================
    // 测试 setPrice()
    // =============================================

    function test_SetPrice() public {
        int256 newPrice = 2000;
        oracle.setPrice(newPrice);
        assertEq(oracle.getPrice(), newPrice, "Price should be updated to 2000");
    }

    function test_SetPrice_ToZero() public {
        oracle.setPrice(0);
        assertEq(oracle.getPrice(), 0, "Price should be 0");
    }

    function test_SetPrice_ToNegative() public {
        int256 negativePrice = -1000;
        oracle.setPrice(negativePrice);
        assertEq(oracle.getPrice(), negativePrice, "Should handle negative price");
    }

    function test_SetPrice_MultipleTimes() public {
        // 多次设置价格，验证每次都能正确更新
        oracle.setPrice(1500);
        assertEq(oracle.getPrice(), 1500, "First update to 1500");

        oracle.setPrice(3000);
        assertEq(oracle.getPrice(), 3000, "Second update to 3000");

        oracle.setPrice(500);
        assertEq(oracle.getPrice(), 500, "Third update to 500");
    }

    function test_SetPrice_ByMultipleCallers() public {
        address alice = makeAddr("alice");
        address bob = makeAddr("bob");

        // alice 设置价格
        vm.prank(alice);
        oracle.setPrice(10000);
        assertEq(oracle.getPrice(), 10000, "alice set price to 10000");

        // bob 设置价格（无权限限制，任何人都可以）
        vm.prank(bob);
        oracle.setPrice(8888);
        assertEq(oracle.getPrice(), 8888, "bob set price to 8888");
    }

    // =============================================
    // 测试 latestRoundData()
    // =============================================

    function test_LatestRoundData() public view {
        (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound) = oracle
            .latestRoundData();

        // 验证返回值
        assertEq(roundId, 1, "roundId should be 1");
        assertEq(answer, INITIAL_PRICE, "answer should be initial price");
        assertEq(startedAt, block.timestamp, "startedAt should be current block timestamp");
        assertEq(updatedAt, block.timestamp, "updatedAt should be current block timestamp");
        assertEq(answeredInRound, 1, "answeredInRound should be 1");
    }

    function test_LatestRoundData_AfterPriceUpdate() public {
        int256 newPrice = 5000;
        oracle.setPrice(newPrice);

        (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound) = oracle
            .latestRoundData();

        // 验证价格已更新
        assertEq(roundId, 1, "roundId should remain 1");
        assertEq(answer, newPrice, "answer should be updated price");
        assertEq(startedAt, block.timestamp, "startedAt should be current block timestamp");
        assertEq(updatedAt, block.timestamp, "updatedAt should be current block timestamp");
        assertEq(answeredInRound, 1, "answeredInRound should remain 1");
    }

    function test_LatestRoundData_AfterMultiplePriceUpdates() public {
        // 多次更新价格
        oracle.setPrice(2000);
        oracle.setPrice(3000);
        oracle.setPrice(4000);

        (, int256 answer, , , ) = oracle.latestRoundData();

        // 验证返回最新的价格
        assertEq(answer, 4000, "Should return the latest price");
    }

    // =============================================
    // 综合测试：模拟 Chainlink 预言机行为
    // =============================================

    function test_MockOracle_SimulatesChainlinkOracle() public {
        // 模拟 Chainlink ETH/USD 价格
        int256 ethPrice = 3500 * 1e8; // $3500 with 8 decimals
        oracle.setPrice(ethPrice);

        (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound) = oracle
            .latestRoundData();

        // 验证返回的数据格式与 Chainlink 一致
        assertEq(roundId, 1, "roundId format matches Chainlink");
        assertEq(answer, ethPrice, "price should match set value");
        assertTrue(startedAt > 0, "startedAt should be set");
        assertTrue(updatedAt > 0, "updatedAt should be set");
        assertEq(answeredInRound, 1, "answeredInRound format matches Chainlink");
    }

    function test_MockOracle_WithDifferentPrices() public {
        // 测试使用不同的价格值
        int256[] memory prices = new int256[](5);
        prices[0] = 1000;
        prices[1] = 2500;
        prices[2] = 0;
        prices[3] = -500;
        prices[4] = 999999999;

        for (uint256 i = 0; i < prices.length; i++) {
            oracle.setPrice(prices[i]);
            assertEq(oracle.getPrice(), prices[i], "Price should match set value");

            (, int256 answer, , , ) = oracle.latestRoundData();
            assertEq(answer, prices[i], "latestRoundData should return current price");
        }
    }

    // =============================================
    // 模糊测试 (Fuzz Testing)
    // =============================================

    function testFuzz_SetPriceAndGetPrice(int256 randomPrice) public {
        // 模糊测试：设置任意价格，验证 getPrice 返回相同的值
        oracle.setPrice(randomPrice);
        assertEq(oracle.getPrice(), randomPrice, "getPrice should return set price");

        // 验证 latestRoundData 也返回相同的价格
        (, int256 answer, , , ) = oracle.latestRoundData();
        assertEq(answer, randomPrice, "latestRoundData should return set price");
    }

    function testFuzz_LatestRoundData_ReturnsConsistentValues(int256 randomPrice) public {
        // 模糊测试：验证 latestRoundData 的返回值一致性
        oracle.setPrice(randomPrice);

        // 多次调用应该返回相同的结果（在同一区块内）
        (uint80 roundId1, int256 answer1, uint256 startedAt1, uint256 updatedAt1, uint80 answeredInRound1) = oracle
            .latestRoundData();

        (uint80 roundId2, int256 answer2, uint256 startedAt2, uint256 updatedAt2, uint80 answeredInRound2) = oracle
            .latestRoundData();

        assertEq(roundId1, roundId2, "roundId should be consistent");
        assertEq(answer1, answer2, "answer should be consistent");
        assertEq(startedAt1, startedAt2, "startedAt should be consistent");
        assertEq(updatedAt1, updatedAt2, "updatedAt should be consistent");
        assertEq(answeredInRound1, answeredInRound2, "answeredInRound should be consistent");
    }

    function testFuzz_SetPrice_MultipleCalls(int256 price1, int256 price2) public {
        // 模糊测试：连续设置两个不同的价格
        vm.assume(price1 != price2);

        oracle.setPrice(price1);
        assertEq(oracle.getPrice(), price1, "First price set correctly");

        oracle.setPrice(price2);
        assertEq(oracle.getPrice(), price2, "Second price set correctly");

        // 验证 latestRoundData 返回最新的价格
        (, int256 answer, , , ) = oracle.latestRoundData();
        assertEq(answer, price2, "latestRoundData should return latest price");
    }

    // =============================================
    // 边界条件测试
    // =============================================

    function test_EdgeCase_MaxInt256() public {
        int256 maxInt = type(int256).max;
        oracle.setPrice(maxInt);
        assertEq(oracle.getPrice(), maxInt, "Should handle max int256 value");
    }

    function test_EdgeCase_MinInt256() public {
        int256 minInt = type(int256).min;
        oracle.setPrice(minInt);
        assertEq(oracle.getPrice(), minInt, "Should handle min int256 value");
    }

    function test_EdgeCase_VeryLargePrice() public {
        int256 hugePrice = 1_000_000_000_000_000_000; // 1e18
        oracle.setPrice(hugePrice);
        assertEq(oracle.getPrice(), hugePrice, "Should handle very large price");
    }
}