// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test, console2} from "forge-std/Test.sol";
import {MetaNodeStake} from "../src/MetaNodeStake.sol";
import {MetaNodeToken} from "../src/MetaNodeToken.sol";
import {TestERC20} from "../src/TestERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract MetaNodeStakeTest is Test {
    MetaNodeStake public stake;
    MetaNodeToken public metaNode;
    TestERC20 public stToken;

    address public admin = address(0xAD);
    address public alice = address(0xA11CE);
    address public bob = address(0xB0B);

    uint256 public constant INITIAL_SUPPLY = 10_000_000 * 1e18;
    uint256 public constant REWARD_PER_BLOCK = 1e18;
    uint256 public constant START_BLOCK = 100;
    uint256 public constant END_BLOCK = 10_000_000;
    uint256 public constant UNSTAKE_LOCKED_BLOCKS = 100;
    uint256 public constant MIN_DEPOSIT = 0;

    // 重新声明事件，签名必须和 MetaNodeStake 里完全一致
    event SetMetaNode(IERC20 indexed MetaNode);

    function setUp() public {
        // 1. 部署代币
        metaNode = new MetaNodeToken();
        stToken = new TestERC20("StakeToken", "STK", INITIAL_SUPPLY);

        // 2. 部署实现合约
        MetaNodeStake impl = new MetaNodeStake();

        // 3. 部署代理，调用 initialize
        bytes memory initData = abi.encodeWithSelector(
            MetaNodeStake.initialize.selector,
            IERC20(address(metaNode)),
            START_BLOCK,
            END_BLOCK,
            REWARD_PER_BLOCK
        );
        ERC1967Proxy proxy = new ERC1967Proxy(address(impl), initData);
        stake = MetaNodeStake(address(proxy));

        // 4. 把 admin 角色转给 admin 地址（可选，方便测试 onlyRole）
        // 当前 msg.sender 是测试合约，已拥有所有角色，不转也能测

        // 5. 给 stake 合约打赏奖励代币
        metaNode.transfer(address(stake), 5_000_000 * 1e18);

        // 6. 给测试用户发质押代币
        stToken.transfer(alice, 1_000_000 * 1e18);
        stToken.transfer(bob, 1_000_000 * 1e18);

        // 7. 把区块号推进到 startBlock 之后
        vm.roll(START_BLOCK + 1);
    }

    // =============================================================
    //                      初始化 / 构造函数
    // =============================================================

    function test_Initialize() public view{
        assertEq(address(stake.MetaNode()), address(metaNode));
        assertEq(stake.startBlock(), START_BLOCK);
        assertEq(stake.endBlock(), END_BLOCK);
        assertEq(stake.MetaNodePerBlock(), REWARD_PER_BLOCK);
        assertEq(stake.totalPoolWeight(), 0);
        assertEq(stake.poolLength(), 0);
        assertTrue(stake.hasRole(stake.DEFAULT_ADMIN_ROLE(), address(this)));
        assertTrue(stake.hasRole(stake.ADMIN_ROLE(), address(this)));
        assertTrue(stake.hasRole(stake.UPGRADE_ROLE(), address(this)));
    }

    function test_Initialize_RevertInvalidParams() public {
        MetaNodeStake impl = new MetaNodeStake();
        // startBlock > endBlock
        bytes memory initData = abi.encodeWithSelector(
            MetaNodeStake.initialize.selector,
            IERC20(address(metaNode)),
            1000,
            100,
            REWARD_PER_BLOCK
        );
        vm.expectRevert("invalid parameters");
        new ERC1967Proxy(address(impl), initData);

        // MetaNodePerBlock == 0
        bytes memory initData2 = abi.encodeWithSelector(
            MetaNodeStake.initialize.selector,
            IERC20(address(metaNode)),
            START_BLOCK,
            END_BLOCK,
            0
        );
        vm.expectRevert("invalid parameters");
        new ERC1967Proxy(address(impl), initData2);
    }

    // =============================================================
    //                          Admin 函数
    // =============================================================

    function test_SetMetaNode() public {
        MetaNodeToken newToken = new MetaNodeToken();
        // 1. 声明预期事件（参数先占位，稍后 emit 一次告诉 Foundry 事件签名）
        vm.expectEmit(true, false, false, true, address(stake));
        // 2. emit 一次预期的事件，告诉 Foundry 你要匹配哪个事件
        emit SetMetaNode(IERC20(address(newToken)));
        stake.setMetaNode(IERC20(address(newToken)));
        assertEq(address(stake.MetaNode()), address(newToken));
    }

    function test_SetMetaNode_RevertNotAdmin() public {
        vm.prank(alice);
        vm.expectRevert();
        stake.setMetaNode(IERC20(address(metaNode)));
    }

    function test_PauseWithdraw() public {
        stake.pauseWithdraw();
        assertTrue(stake.withdrawPaused());

        vm.expectRevert("withdraw has been already paused");
        stake.pauseWithdraw();
    }

    function test_UnpauseWithdraw() public {
        stake.pauseWithdraw();
        stake.unpauseWithdraw();
        assertFalse(stake.withdrawPaused());

        vm.expectRevert("withdraw has been already unpaused");
        stake.unpauseWithdraw();
    }

    function test_PauseClaim() public {
        stake.pauseClaim();
        assertTrue(stake.claimPaused());

        vm.expectRevert("claim has been already paused");
        stake.pauseClaim();
    }

    function test_UnpauseClaim() public {
        stake.pauseClaim();
        stake.unpauseClaim();
        assertFalse(stake.claimPaused());

        vm.expectRevert("claim has been already unpaused");
        stake.unpauseClaim();
    }

    function test_SetStartBlock() public {
        stake.setStartBlock(200);
        assertEq(stake.startBlock(), 200);

        vm.expectRevert("start block must be smaller than end block");
        stake.setStartBlock(END_BLOCK + 1);
    }

    function test_SetEndBlock() public {
        stake.setEndBlock(20_000_000);
        assertEq(stake.endBlock(), 20_000_000);

        vm.expectRevert("start block must be smaller than end block");
        stake.setEndBlock(START_BLOCK - 1);
    }

    function test_SetMetaNodePerBlock() public {
        stake.setMetaNodePerBlock(2e18);
        assertEq(stake.MetaNodePerBlock(), 2e18);

        vm.expectRevert("invalid parameter");
        stake.setMetaNodePerBlock(0);
    }

    // =============================================================
    //                          addPool
    // =============================================================

    function test_AddPool_ETH() public {
        // 第一个池必须是 ETH 池 (stTokenAddress == address(0))
        stake.addPool(address(0), 100, MIN_DEPOSIT, UNSTAKE_LOCKED_BLOCKS, false);

        assertEq(stake.poolLength(), 1);
        assertEq(stake.totalPoolWeight(), 100);

        (
            address stTokenAddress,
            uint256 poolWeight,
            uint256 lastRewardBlock,
            uint256 accMetaNodePerST,
            uint256 stTokenAmount,
            uint256 minDepositAmount,
            uint256 unstakeLockedBlocks
        ) = stake.pool(0);

        assertEq(stTokenAddress, address(0));
        assertEq(poolWeight, 100);
        assertEq(lastRewardBlock, block.number);
        assertEq(accMetaNodePerST, 0);
        assertEq(stTokenAmount, 0);
        assertEq(minDepositAmount, MIN_DEPOSIT);
        assertEq(unstakeLockedBlocks, UNSTAKE_LOCKED_BLOCKS);
    }

    function test_AddPool_Token() public {
        stake.addPool(address(0), 100, MIN_DEPOSIT, UNSTAKE_LOCKED_BLOCKS, false);
        stake.addPool(address(stToken), 200, MIN_DEPOSIT, UNSTAKE_LOCKED_BLOCKS, false);

        assertEq(stake.poolLength(), 2);
        assertEq(stake.totalPoolWeight(), 300);
    }

    function test_AddPool_RevertFirstPoolNotETH() public {
        vm.expectRevert("invalid staking token address");
        stake.addPool(address(stToken), 100, MIN_DEPOSIT, UNSTAKE_LOCKED_BLOCKS, false);
    }

    function test_AddPool_RevertSecondPoolIsETH() public {
        stake.addPool(address(0), 100, MIN_DEPOSIT, UNSTAKE_LOCKED_BLOCKS, false);
        vm.expectRevert("invalid staking token address");
        stake.addPool(address(0), 100, MIN_DEPOSIT, UNSTAKE_LOCKED_BLOCKS, false);
    }

    function test_AddPool_RevertInvalidLockedBlocks() public {
        vm.expectRevert("invalid withdraw locked blocks");
        stake.addPool(address(0), 100, MIN_DEPOSIT, 0, false);
    }

    function test_AddPool_RevertAlreadyEnded() public {
        vm.roll(END_BLOCK + 1);
        vm.expectRevert("Already ended");
        stake.addPool(address(0), 100, MIN_DEPOSIT, UNSTAKE_LOCKED_BLOCKS, false);
    }

    function test_AddPool_RevertNotAdmin() public {
        vm.prank(alice);
        vm.expectRevert();
        stake.addPool(address(0), 100, MIN_DEPOSIT, UNSTAKE_LOCKED_BLOCKS, false);
    }

    // =============================================================
    //                    updatePool / setPoolWeight
    // =============================================================

    function test_UpdatePoolInfo() public {
        stake.addPool(address(0), 100, MIN_DEPOSIT, UNSTAKE_LOCKED_BLOCKS, false);
        stake.updatePool(0, 1e18, 200);

        (, , , , , uint256 minDepositAmount, uint256 unstakeLockedBlocks) = stake.pool(0);
        assertEq(minDepositAmount, 1e18);
        assertEq(unstakeLockedBlocks, 200);
    }

    function test_UpdatePoolInfo_RevertInvalidPid() public {
        vm.expectRevert("invalid pid");
        stake.updatePool(0, 1e18, 200);
    }

    function test_SetPoolWeight() public {
        stake.addPool(address(0), 100, MIN_DEPOSIT, UNSTAKE_LOCKED_BLOCKS, false);
        stake.setPoolWeight(0, 300, false);

        (, uint256 poolWeight, , , , , ) = stake.pool(0);
        assertEq(poolWeight, 300);
        assertEq(stake.totalPoolWeight(), 300);
    }

    function test_SetPoolWeight_RevertInvalidWeight() public {
        stake.addPool(address(0), 100, MIN_DEPOSIT, UNSTAKE_LOCKED_BLOCKS, false);
        vm.expectRevert("invalid pool weight");
        stake.setPoolWeight(0, 0, false);
    }

    // =============================================================
    //                        ETH 质押流程
    // =============================================================

    function test_DepositETH() public {
        stake.addPool(address(0), 100, MIN_DEPOSIT, UNSTAKE_LOCKED_BLOCKS, false);

        vm.deal(alice, 10 ether);
        vm.prank(alice);
        stake.depositETH{value: 1 ether}();

        assertEq(stake.stakingBalance(0, alice), 1 ether);
    }

    function test_DepositETH_RevertTooSmall() public {
        stake.addPool(address(0), 100, 1 ether, UNSTAKE_LOCKED_BLOCKS, false);

        vm.deal(alice, 10 ether);
        vm.prank(alice);
        vm.expectRevert("deposit amount is too small");
        stake.depositETH{value: 0.5 ether}();
    }

    function test_UnstakeAndWithdrawETH() public {
        stake.addPool(address(0), 100, MIN_DEPOSIT, UNSTAKE_LOCKED_BLOCKS, false);

        vm.deal(alice, 10 ether);
        vm.prank(alice);
        stake.depositETH{value: 1 ether}();

        // 推进区块，让奖励累积
        vm.roll(block.number + 10);

        vm.prank(alice);
        stake.unstake(0, 1 ether);

        assertEq(stake.stakingBalance(0, alice), 0);

        // 还没到解锁区块
        vm.prank(alice);
        stake.withdraw(0);

        // 推进到解锁
        vm.roll(block.number + UNSTAKE_LOCKED_BLOCKS + 1);

        uint256 balBefore = alice.balance;
        vm.prank(alice);
        stake.withdraw(0);

        assertEq(alice.balance, balBefore + 1 ether);
    }

    // =============================================================
    //                        ERC20 质押流程
    // =============================================================

    function test_Deposit() public {
        stake.addPool(address(0), 100, MIN_DEPOSIT, UNSTAKE_LOCKED_BLOCKS, false);
        stake.addPool(address(stToken), 200, MIN_DEPOSIT, UNSTAKE_LOCKED_BLOCKS, false);

        vm.startPrank(alice);
        stToken.approve(address(stake), 1000 * 1e18);
        stake.deposit(1, 1000 * 1e18);
        vm.stopPrank();

        assertEq(stake.stakingBalance(1, alice), 1000 * 1e18);
        assertEq(stToken.balanceOf(address(stake)), 1000 * 1e18);
    }

    function test_Deposit_RevertPid0() public {
        stake.addPool(address(0), 100, MIN_DEPOSIT, UNSTAKE_LOCKED_BLOCKS, false);
        stake.addPool(address(stToken), 200, MIN_DEPOSIT, UNSTAKE_LOCKED_BLOCKS, false);

        vm.startPrank(alice);
        stToken.approve(address(stake), 1000 * 1e18);
        vm.expectRevert("deposit not support ETH staking");
        stake.deposit(0, 1000 * 1e18);
        vm.stopPrank();
    }

    function test_Deposit_RevertTooSmall() public {
        stake.addPool(address(0), 100, MIN_DEPOSIT, UNSTAKE_LOCKED_BLOCKS, false);
        stake.addPool(address(stToken), 200, 1 ether, UNSTAKE_LOCKED_BLOCKS, false);

        vm.startPrank(alice);
        stToken.approve(address(stake), 1000 * 1e18);
        vm.expectRevert("deposit amount is too small");
        stake.deposit(1, 0.5 ether);
        vm.stopPrank();
    }

    // =============================================================
    //                        unstake
    // =============================================================

    function test_Unstake_RevertNotEnough() public {
        stake.addPool(address(0), 100, MIN_DEPOSIT, UNSTAKE_LOCKED_BLOCKS, false);

        vm.prank(alice);
        vm.expectRevert("Not enough staking token balance");
        stake.unstake(0, 1 ether);
    }

    function test_Unstake_WhenWithdrawPaused() public {
        stake.addPool(address(0), 100, MIN_DEPOSIT, UNSTAKE_LOCKED_BLOCKS, false);

        vm.deal(alice, 10 ether);
        vm.prank(alice);
        stake.depositETH{value: 1 ether}();

        stake.pauseWithdraw();

        vm.prank(alice);
        vm.expectRevert("withdraw is paused");
        stake.unstake(0, 1 ether);
    }

    // =============================================================
    //                        claim
    // =============================================================

    function test_Claim() public {
        stake.addPool(address(0), 100, MIN_DEPOSIT, UNSTAKE_LOCKED_BLOCKS, false);

        vm.deal(alice, 10 ether);
        vm.prank(alice);
        stake.depositETH{value: 1 ether}();

        // 推进区块累积奖励
        vm.roll(block.number + 100);

        uint256 balBefore = metaNode.balanceOf(alice);
        vm.prank(alice);
        stake.claim(0);
        uint256 balAfter = metaNode.balanceOf(alice);

        assertGt(balAfter, balBefore);
    }

    function test_Claim_WhenClaimPaused() public {
        stake.addPool(address(0), 100, MIN_DEPOSIT, UNSTAKE_LOCKED_BLOCKS, false);

        vm.deal(alice, 10 ether);
        vm.prank(alice);
        stake.depositETH{value: 1 ether}();

        stake.pauseClaim();

        vm.prank(alice);
        vm.expectRevert("claim is paused");
        stake.claim(0);
    }

    // =============================================================
    //                        查询函数
    // =============================================================

    function test_GetMultiplier() public {
        stake.addPool(address(0), 100, MIN_DEPOSIT, UNSTAKE_LOCKED_BLOCKS, false);

        // _from < startBlock 会被截断为 startBlock
        uint256 multiplier = stake.getMultiplier(0, START_BLOCK + 10);
        assertEq(multiplier, 10 * REWARD_PER_BLOCK);

        // _to > endBlock 会被截断为 endBlock
        multiplier = stake.getMultiplier(START_BLOCK, END_BLOCK + 100);
        assertEq(multiplier, (END_BLOCK - START_BLOCK) * REWARD_PER_BLOCK);
    }

    function test_GetMultiplier_RevertInvalidBlock() public {
        stake.addPool(address(0), 100, MIN_DEPOSIT, UNSTAKE_LOCKED_BLOCKS, false);
        vm.expectRevert("invalid block");
        stake.getMultiplier(200, 100);
    }

    function test_PendingMetaNode() public {
        stake.addPool(address(0), 100, MIN_DEPOSIT, UNSTAKE_LOCKED_BLOCKS, false);

        vm.deal(alice, 10 ether);
        vm.prank(alice);
        stake.depositETH{value: 1 ether}();

        vm.roll(block.number + 100);

        uint256 pending = stake.pendingMetaNode(0, alice);
        assertGt(pending, 0);
    }

    function test_PendingMetaNodeByBlockNumber() public {
        stake.addPool(address(0), 100, MIN_DEPOSIT, UNSTAKE_LOCKED_BLOCKS, false);

        vm.deal(alice, 10 ether);
        vm.prank(alice);
        stake.depositETH{value: 1 ether}();

        uint256 pending = stake.pendingMetaNodeByBlockNumber(0, alice, block.number + 100);
        assertGt(pending, 0);
    }

    function test_WithdrawAmount() public {
        stake.addPool(address(0), 100, MIN_DEPOSIT, UNSTAKE_LOCKED_BLOCKS, false);

        vm.deal(alice, 10 ether);
        vm.prank(alice);
        stake.depositETH{value: 1 ether}();

        vm.prank(alice);
        stake.unstake(0, 1 ether);

        (uint256 requestAmount, uint256 pendingWithdrawAmount) = stake.withdrawAmount(0, alice);
        assertEq(requestAmount, 1 ether);
        assertEq(pendingWithdrawAmount, 0);

        // 推进到解锁
        vm.roll(block.number + UNSTAKE_LOCKED_BLOCKS + 1);

        (requestAmount, pendingWithdrawAmount) = stake.withdrawAmount(0, alice);
        assertEq(requestAmount, 1 ether);
        assertEq(pendingWithdrawAmount, 1 ether);
    }

    // =============================================================
    //                        massUpdatePools
    // =============================================================

    function test_MassUpdatePools() public {
        stake.addPool(address(0), 100, MIN_DEPOSIT, UNSTAKE_LOCKED_BLOCKS, false);
        stake.addPool(address(stToken), 200, MIN_DEPOSIT, UNSTAKE_LOCKED_BLOCKS, false);

        vm.deal(alice, 10 ether);
        vm.prank(alice);
        stake.depositETH{value: 1 ether}();

        vm.startPrank(bob);
        stToken.approve(address(stake), 1000 * 1e18);
        stake.deposit(1, 1000 * 1e18);
        vm.stopPrank();

        vm.roll(block.number + 100);

        stake.massUpdatePools();

        (, , uint256 lastRewardBlock, , , , ) = stake.pool(0);
        assertEq(lastRewardBlock, block.number);
    }

    // =============================================================
    //                        升级测试
    // =============================================================

    function test_Upgrade() public {
        MetaNodeStake newImpl = new MetaNodeStake();
        stake.upgradeToAndCall(address(newImpl), "");
    }

    function test_Upgrade_RevertNotUpgradeRole() public {
        MetaNodeStake newImpl = new MetaNodeStake();
        vm.prank(alice);
        vm.expectRevert();
        stake.upgradeToAndCall(address(newImpl), "");
    }

    // =============================================================
    //                        暂停状态测试
    // =============================================================

    function test_Deposit_WhenPaused() public {
        stake.addPool(address(0), 100, MIN_DEPOSIT, UNSTAKE_LOCKED_BLOCKS, false);

        // 注意：PausableUpgradeable 的 whenNotPaused 需要先调用 _pause()
        // 但该合约没有暴露 pause() 函数，所以 whenNotPaused 实际上永远为 true
        // 这里只测试正常路径
        vm.deal(alice, 10 ether);
        vm.prank(alice);
        stake.depositETH{value: 1 ether}();
    }
}