// SPDX-License-Identifier: MIT
pragma solidity ^0.8.34;

import {Test, console2} from "forge-std/Test.sol";
import {TransparentUpgradeableProxy, ITransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import {ProxyAdmin} from "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";
import {IERC1967} from "@openzeppelin/contracts/interfaces/IERC1967.sol";

import {MetaNFTAuction} from "./MetaNFTAuction.sol";
import {MetaNFTAuctionV2} from "./MetaNFTAuctionV2.sol";
import {MetaNFT} from "./MetaNFT.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {MockOracle} from "./MockOracle.sol";
import {MockERC20} from "./MockERC20.sol";

contract MetaNFTAuctionTest is Test {
    MetaNFTAuction private auction;
    MetaNFT private nft;
    MockERC20 private usdc;
    MockOracle private ethOracle;
    MockOracle private usdcOracle;
    ProxyAdmin private proxyAdminInstance;

    address private admin = address(0xA11CE);
    address private proxyAdmin = address(0xBEEF);
    address private seller = address(0xB0B);
    address private bidder1 = address(0xB0123);
    address private bidder2 = address(0xB0124);

    event Bid(address indexed sender, uint256 amount);

    function setUp() public {
        MetaNFTAuction impl = new MetaNFTAuction();
        bytes memory initData = abi.encodeCall(MetaNFTAuction.initialize, (admin));
        
        TransparentUpgradeableProxy proxy = new TransparentUpgradeableProxy(address(impl), proxyAdmin, initData);

        auction = MetaNFTAuction(address(proxy));
        
        bytes32 adminSlot = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;
        address proxyAdminAddress = address(uint160(uint256(vm.load(address(proxy), adminSlot))));
        proxyAdminInstance = ProxyAdmin(proxyAdminAddress);
        
        nft = new MetaNFT();
        usdc = new MockERC20("USDC", "USDC", 6, 1000000e6);
        
        ethOracle = new MockOracle(3000e8);
        usdcOracle = new MockOracle(1e8);
        
        vm.startPrank(admin);
        auction.setTokenOracle(address(0), address(ethOracle));
        auction.setTokenOracle(address(usdc), address(usdcOracle));
        vm.stopPrank();
        
        nft.mint(seller, 1);
        nft.mint(seller, 2);
        nft.mint(seller, 10);
        vm.startPrank(seller);
        nft.setApprovalForAll(address(auction), true);
        vm.stopPrank();
    }

    function test_getVersion() public view {
        assertEq(auction.getVersion(), "MetaNFTAuctionV1");
    }

    function test_getPriceInDollar() public view {
        uint256 ethPrice = auction.getPriceInDollar(address(0));
        uint256 usdcPrice = auction.getPriceInDollar(address(usdc));
        console2.log("ETH/USD price", ethPrice);
        console2.log("USDC/USD price", usdcPrice);
        assertGt(ethPrice, 0);
        assertGt(usdcPrice, 0);
    }

    function test_initializeOnlyOnce() public {
        vm.startPrank(admin);
        vm.expectRevert();
        auction.initialize(admin);
        vm.stopPrank();
    }

    function test_startOnlyAdmin() public {
        vm.startPrank(seller);
        vm.expectRevert("not admin");
        auction.start(seller, 1, address(nft), 1000, 3600, address(usdc));
        vm.stopPrank();
    }

    function test_startIncrementsAuctionId() public {
        vm.startPrank(admin);
        auction.start(seller, 1, address(nft), 1000, 3600, address(usdc));
        assertEq(auction.auctionId(), 1);
        auction.start(seller, 2, address(nft), 1000, 3600, address(usdc));
        assertEq(auction.auctionId(), 2);
        vm.stopPrank();
    }

    function test_startAuctionGtDuration() public {
        vm.startPrank(admin);
        auction.start(seller, 1, address(nft), 1000, 30, address(usdc));
        uint256 currentAuctionId = auction.auctionId() - 1;

        vm.deal(seller, 1 ether);
        vm.warp(block.timestamp + 50);
        console2.log("current time", block.timestamp);
        vm.expectRevert("ended");
        vm.startPrank(seller);
        auction.bid{value: 1 ether}(currentAuctionId, 1 ether);
        vm.stopPrank();
    }

    function test_bidLowerThanHighestBid() public {
        vm.startPrank(admin);
        auction.start(seller, 1, address(nft), 1000, 30, address(usdc));
        uint256 currentAuctionId = auction.auctionId() - 1;
        
        vm.deal(seller, 2 ether);
        vm.deal(bidder1, 2 ether);
        
        vm.startPrank(seller);
        auction.bid{value: 2 ether}(currentAuctionId, 2 ether);
        
        vm.startPrank(bidder1);
        vm.expectRevert("invalid highestBid");
        auction.bid{value: 1.2 ether}(currentAuctionId, 1.2 ether);
        vm.stopPrank();
    }

    function test_bidResult() public {
        vm.startPrank(admin);
        auction.start(seller, 1, address(nft), 1000, 3600, address(usdc));
        uint256 currentAuctionId = auction.auctionId() - 1;
        
        vm.deal(seller, 20 ether);
        vm.deal(bidder1, 20 ether);
        vm.deal(bidder2, 20 ether);

        vm.startPrank(bidder1);
        auction.bid{value: 2 ether}(currentAuctionId, 2 ether);
        vm.startPrank(bidder2);
        auction.bid{value: 3 ether}(currentAuctionId, 3 ether);
        vm.startPrank(bidder1);
        auction.bid{value: 4 ether}(currentAuctionId, 4 ether);

        (, , , , address highestBidder, , , , uint256 highestBid, , ) = auction.auctions(currentAuctionId);

        assertEq(highestBidder, bidder1);
        assertEq(highestBid, 4 ether);
        vm.stopPrank();
    }

    function test_upgrade() public {
        vm.startPrank(admin);
        auction.start(seller, 10, address(nft), 1000, 3600, address(usdc));
        uint256 oldAuctionId = auction.auctionId();
        vm.stopPrank();
        
        MetaNFTAuctionV2 newImpl = new MetaNFTAuctionV2();
        
        vm.prank(proxyAdmin);
        proxyAdminInstance.upgradeAndCall(ITransparentUpgradeableProxy(payable(address(auction))), address(newImpl), "");
        
        MetaNFTAuctionV2 upgradedAuction = MetaNFTAuctionV2(payable(address(auction)));
        
        assertEq(upgradedAuction.auctionId(), oldAuctionId);
        assertEq(keccak256(abi.encodePacked(upgradedAuction.getVersion())), keccak256(abi.encodePacked("MetaNFTAuctionV2")));
        
        string memory newFeature = upgradedAuction.newFeature();
        assertEq(keccak256(abi.encodePacked(newFeature)), keccak256(abi.encodePacked("This is a new feature in V2")));
    }

    function test_upgradeByNonAdmin() public {
        vm.startPrank(admin);
        auction.start(seller, 10, address(nft), 1000, 3600, address(usdc));
        vm.stopPrank();
        
        MetaNFTAuctionV2 newImpl = new MetaNFTAuctionV2();
        
        vm.startPrank(seller);
        vm.expectRevert();
        proxyAdminInstance.upgradeAndCall(ITransparentUpgradeableProxy(payable(address(auction))), address(newImpl), "");
        vm.stopPrank();
    }

    function test_changeOracleAfterUpgrade() public {
        vm.startPrank(admin);
        auction.start(seller, 10, address(nft), 1000, 3600, address(usdc));
        vm.stopPrank();
        
        MockOracle newEthOracle = new MockOracle(3000e8);
        
        MetaNFTAuctionV2 newImpl = new MetaNFTAuctionV2();
        
        vm.prank(proxyAdmin);
        proxyAdminInstance.upgradeAndCall(ITransparentUpgradeableProxy(payable(address(auction))), address(newImpl), "");
        
        MetaNFTAuctionV2 upgradedAuction = MetaNFTAuctionV2(payable(address(auction)));
        
        vm.startPrank(admin);
        upgradedAuction.setTokenOracle(address(0), address(newEthOracle));
        
        uint256 newPrice = upgradedAuction.getPriceInDollar(address(0));
        assertEq(newPrice, 3000e8);
        
        vm.stopPrank();
    }

    // ================================================================
    // 新增测试用例 - 补全覆盖率
    // ================================================================

    // ========== 覆盖行 112-116: bid 函数中的 ERC20 出价逻辑 ==========
    
    function test_bidWithERC20() public {
        // 创建 ERC20 拍卖
        vm.startPrank(admin);
        auction.start(seller, 1, address(nft), 1000, 3600, address(usdc));
        uint256 currentAuctionId = auction.auctionId() - 1;
        vm.stopPrank();

        // 给 bidder1 一些 USDC
        uint256 bidAmount = 2000e6; // 2000 USDC (6 decimals)
        vm.startPrank(admin);
        usdc.mint(bidder1, bidAmount);
        vm.stopPrank();

        // bidder1 授权并出价
        vm.startPrank(bidder1);
        usdc.approve(address(auction), bidAmount);
        auction.bid(currentAuctionId, bidAmount);
        vm.stopPrank();

        // 验证状态
        (, , , , address highestBidder, , , , uint256 highestBid, , ) = auction.auctions(currentAuctionId);
        assertEq(highestBidder, bidder1);
        assertEq(highestBid, bidAmount);
        
        // 验证 USDC 已转入合约
        assertEq(usdc.balanceOf(address(auction)), bidAmount);
    }

    // ========== 覆盖行 112-116: ERC20 出价被非管理员拒绝 ==========
    
    function test_bidWithERC20ByNonAdmin() public {
        vm.startPrank(admin);
        auction.start(seller, 1, address(nft), 1000, 3600, address(usdc));
        uint256 currentAuctionId = auction.auctionId() - 1;
        vm.stopPrank();

        uint256 bidAmount = 2000e6;
        vm.startPrank(admin);
        usdc.mint(bidder1, bidAmount);
        vm.stopPrank();

        vm.startPrank(bidder1);
        usdc.approve(address(auction), bidAmount);
        auction.bid(currentAuctionId, bidAmount);
        vm.stopPrank();

        // 验证出价成功（ERC20 出价不需要是 admin）
        (, , , , address highestBidder, , , , , , ) = auction.auctions(currentAuctionId);
        assertEq(highestBidder, bidder1);
    }

    // ========== 覆盖行 127: 出价低于当前最高价 ==========
    
    function test_bidLowerThanHighestBidWithERC20() public {
        vm.startPrank(admin);
        auction.start(seller, 1, address(nft), 1000, 3600, address(usdc));
        uint256 currentAuctionId = auction.auctionId() - 1;
        vm.stopPrank();

        uint256 bidAmount1 = 3000e6;
        uint256 bidAmount2 = 2000e6;

        vm.startPrank(admin);
        usdc.mint(bidder1, bidAmount1);
        usdc.mint(bidder2, bidAmount2);
        vm.stopPrank();

        // bidder1 出价 3000 USDC
        vm.startPrank(bidder1);
        usdc.approve(address(auction), bidAmount1);
        auction.bid(currentAuctionId, bidAmount1);
        vm.stopPrank();

        // bidder2 尝试出价 2000 USDC（低于最高价）
        vm.startPrank(bidder2);
        usdc.approve(address(auction), bidAmount2);
        vm.expectRevert("invalid highestBid");
        auction.bid(currentAuctionId, bidAmount2);
        vm.stopPrank();
    }

    // ========== 覆盖行 135-136: ERC20 退款逻辑 ==========
    
    function test_bidWithERC20Refund() public {
        vm.startPrank(admin);
        auction.start(seller, 1, address(nft), 1000, 3600, address(usdc));
        uint256 currentAuctionId = auction.auctionId() - 1;
        vm.stopPrank();

        uint256 bidAmount1 = 2000e6;
        uint256 bidAmount2 = 3000e6;

        vm.startPrank(admin);
        usdc.mint(bidder1, bidAmount1);
        usdc.mint(bidder2, bidAmount2);
        vm.stopPrank();

        // bidder1 出价 2000 USDC
        vm.startPrank(bidder1);
        usdc.approve(address(auction), bidAmount1);
        auction.bid(currentAuctionId, bidAmount1);
        vm.stopPrank();

        uint256 bidder1BalanceBefore = usdc.balanceOf(bidder1);

        // bidder2 出价 3000 USDC（超过 bidder1）
        vm.startPrank(bidder2);
        usdc.approve(address(auction), bidAmount2);
        auction.bid(currentAuctionId, bidAmount2);
        vm.stopPrank();

        // 验证 bidder1 收到了退款
        uint256 bidder1BalanceAfter = usdc.balanceOf(bidder1);
        assertEq(bidder1BalanceAfter, bidder1BalanceBefore + bidAmount1);
        
        // 验证 bidder2 成为最高出价者
        (, , , , address highestBidder, , , , uint256 highestBid, , ) = auction.auctions(currentAuctionId);
        assertEq(highestBidder, bidder2);
        assertEq(highestBid, bidAmount2);
    }

    // ========== 覆盖行 135-136: 同一人多次出价不退款 ==========
    
    function test_bidSameBidderNoRefund() public {
        vm.startPrank(admin);
        auction.start(seller, 1, address(nft), 1000, 3600, address(usdc));
        uint256 currentAuctionId = auction.auctionId() - 1;
        vm.stopPrank();

        uint256 bidAmount1 = 2000e6;
        uint256 bidAmount2 = 3000e6;

        vm.startPrank(admin);
        usdc.mint(bidder1, bidAmount1 + bidAmount2);
        vm.stopPrank();

        uint256 bidder1BalanceBefore = usdc.balanceOf(bidder1);

        // bidder1 第一次出价
        vm.startPrank(bidder1);
        usdc.approve(address(auction), bidAmount1);
        auction.bid(currentAuctionId, bidAmount1);
        vm.stopPrank();

        // bidder1 再次出价（自己超越自己）
        vm.startPrank(bidder1);
        usdc.approve(address(auction), bidAmount2);
        auction.bid(currentAuctionId, bidAmount2);
        vm.stopPrank();

        // 验证 bidder1 没有收到退款（因为是自己超越自己）
        uint256 bidder1BalanceAfter = usdc.balanceOf(bidder1);
        // 余额应该减少了 bidAmount1 + bidAmount2
        assertEq(bidder1BalanceAfter, bidder1BalanceBefore - bidAmount1 - bidAmount2);
        
        // 验证最高出价者仍是 bidder1
        (, , , , address highestBidder, , , , uint256 highestBid, , ) = auction.auctions(currentAuctionId);
        assertEq(highestBidder, bidder1);
        assertEq(highestBid, bidAmount2);
    }

    // ========== 覆盖行 149-151: ETH 出价更新逻辑 ==========
    
    function test_bidWithETHUpdateLogic() public {
        vm.startPrank(admin);
        auction.start(seller, 1, address(nft), 1000, 3600, address(usdc));
        uint256 currentAuctionId = auction.auctionId() - 1;
        vm.stopPrank();

        vm.deal(bidder1, 3 ether);
        vm.deal(bidder2, 4 ether);

        // bidder1 出价 2 ETH
        vm.startPrank(bidder1);
        auction.bid{value: 2 ether}(currentAuctionId, 2 ether);
        vm.stopPrank();

        // 验证最高出价 token 是 address(0)（ETH）
        (, , , , , , , , , , address highestBidToken) = auction.auctions(currentAuctionId);
        assertEq(highestBidToken, address(0));

        // bidder2 出价 3 ETH（超过 bidder1）
        vm.startPrank(bidder2);
        auction.bid{value: 3 ether}(currentAuctionId, 3 ether);
        vm.stopPrank();

        // 验证最高出价 token 仍是 address(0)
        (, , , , , , , , , , address highestBidToken2) = auction.auctions(currentAuctionId);
        assertEq(highestBidToken2, address(0));
        
        // 验证合约中的 ETH 余额
        assertEq(address(auction).balance, 3 ether);
    }

    // ========== 覆盖行 153: ERC20 出价更新逻辑 ==========
    
    function test_bidWithERC20UpdateLogic() public {
        vm.startPrank(admin);
        auction.start(seller, 1, address(nft), 1000, 3600, address(usdc));
        uint256 currentAuctionId = auction.auctionId() - 1;
        vm.stopPrank();

        uint256 bidAmount = 2000e6;
        vm.startPrank(admin);
        usdc.mint(bidder1, bidAmount);
        vm.stopPrank();

        vm.startPrank(bidder1);
        usdc.approve(address(auction), bidAmount);
        auction.bid(currentAuctionId, bidAmount);
        vm.stopPrank();

        // 验证最高出价 token 是 USDC 地址
        (, , , , , , , , , , address highestBidToken) = auction.auctions(currentAuctionId);
        assertEq(highestBidToken, address(usdc));
    }

    // ========== 覆盖行 155-158: 出价记录更新 ==========
    
    function test_bidRecordUpdate() public {
        vm.startPrank(admin);
        auction.start(seller, 1, address(nft), 1000, 3600, address(usdc));
        uint256 currentAuctionId = auction.auctionId() - 1;
        vm.stopPrank();

        vm.deal(bidder1, 2 ether);

        vm.startPrank(bidder1);
        auction.bid{value: 1.5 ether}(currentAuctionId, 1.5 ether);
        vm.stopPrank();

        // 验证所有字段都被正确更新
        (
        ,
        ,
        ,
        ,
        address highestBidder,
        uint256 startingPrice,
        ,
        ,
        uint256 highestBid,
        uint256 highestBidInDollar,
        address highestBidToken
        ) = auction.auctions(currentAuctionId);
        
        assertEq(highestBidder, bidder1);
        assertGt(startingPrice, 0);
        assertGt(highestBidInDollar, 0);
        assertEq(highestBid, 1.5 ether);
        assertEq(highestBidToken, address(0));
    }

    // ========== 覆盖行 160: Bid 事件 ==========
    
    function test_bidEmitsEvent() public {
        vm.startPrank(admin);
        auction.start(seller, 1, address(nft), 1000, 3600, address(usdc));
        uint256 currentAuctionId = auction.auctionId() - 1;
        vm.stopPrank();

        vm.deal(bidder1, 2 ether);

        // 监听 Bid 事件
        vm.expectEmit(true, false, false, true);
        emit Bid(bidder1, 1.5 ether);

        vm.startPrank(bidder1);
        auction.bid{value: 1.5 ether}(currentAuctionId, 1.5 ether);
        vm.stopPrank();
    }

    // ========== 覆盖行 163: end 函数中的 NFT 转账 ==========
    
    function test_endTransfersNFTToWinner() public {
        vm.startPrank(admin);
        auction.start(seller, 1, address(nft), 1000, 3600, address(usdc));
        uint256 currentAuctionId = auction.auctionId() - 1;
        vm.stopPrank();

        vm.deal(bidder1, 2 ether);

        // bidder1 出价
        vm.startPrank(bidder1);
        auction.bid{value: 1.5 ether}(currentAuctionId, 1.5 ether);
        vm.stopPrank();

        // 时间快进到拍卖结束
        vm.warp(block.timestamp + 3600);

        // 结束拍卖
        vm.startPrank(admin);
        auction.end(currentAuctionId);
        vm.stopPrank();

        // 验证 NFT 已转移给最高出价者
        assertEq(nft.ownerOf(1), bidder1);
    }

    // ========== 覆盖行 163: end 函数中的 NFT 转账（ERC20 出价场景） ==========
    
    function test_endTransfersNFTToWinnerWithERC20() public {
        vm.startPrank(admin);
        auction.start(seller, 1, address(nft), 1000, 3600, address(usdc));
        uint256 currentAuctionId = auction.auctionId() - 1;
        vm.stopPrank();

        uint256 bidAmount = 2000e6;
        vm.startPrank(admin);
        usdc.mint(bidder1, bidAmount);
        vm.stopPrank();

        // bidder1 出价 USDC
        vm.startPrank(bidder1);
        usdc.approve(address(auction), bidAmount);
        auction.bid(currentAuctionId, bidAmount);
        vm.stopPrank();

        // 时间快进到拍卖结束
        vm.warp(block.timestamp + 3600);

        // 结束拍卖
        vm.startPrank(admin);
        auction.end(currentAuctionId);
        vm.stopPrank();

        // 验证 NFT 已转移给最高出价者
        assertEq(nft.ownerOf(1), bidder1);
        
        // 验证 USDC 已转移给卖家
        assertEq(usdc.balanceOf(seller), bidAmount);
    }

    // ========== 额外补充测试 ==========

    // 测试 start 函数中 NFT 转移
    function test_startTransfersNFTToContract() public {
        vm.startPrank(admin);
        auction.start(seller, 1, address(nft), 1000, 3600, address(usdc));
        vm.stopPrank();

        // 验证 NFT 已转移到拍卖合约
        assertEq(nft.ownerOf(1), address(auction));
    }

    // 测试 start 函数参数验证
    function test_startInvalidNFT() public {
        vm.startPrank(admin);
        vm.expectRevert("invalid nft");
        auction.start(seller, 1, address(0), 1000, 3600, address(usdc));
        vm.stopPrank();
    }

    function test_startInvalidDuration() public {
        vm.startPrank(admin);
        vm.expectRevert("invalid duration");
        auction.start(seller, 1, address(nft), 1000, 29, address(usdc));
        vm.stopPrank();
    }

    function test_startInvalidPaymentToken() public {
        vm.startPrank(admin);
        vm.expectRevert("invalid payment token");
        auction.start(seller, 1, address(nft), 1000, 3600, address(0));
        vm.stopPrank();
    }

    // 测试 end 函数在没有出价时回滚
    function test_endWithNoBids() public {
        vm.startPrank(admin);
        auction.start(seller, 1, address(nft), 1000, 3600, address(usdc));
        uint256 currentAuctionId = auction.auctionId() - 1;
        vm.stopPrank();

        vm.warp(block.timestamp + 3600);

        vm.startPrank(admin);
        vm.expectRevert("no bids");
        auction.end(currentAuctionId);
        vm.stopPrank();
    }

    // 测试 setTokenOracle 只有 admin 可以调用
    function test_setTokenOracleOnlyAdmin() public {
        MockOracle newOracle = new MockOracle(4000e8);
        
        vm.startPrank(seller);
        vm.expectRevert("not admin");
        auction.setTokenOracle(address(0), address(newOracle));
        vm.stopPrank();
    }

    // 测试 setTokenOracle 不能设置零地址
    function test_setTokenOracleInvalidOracle() public {
        vm.startPrank(admin);
        vm.expectRevert("invalid oracle");
        auction.setTokenOracle(address(0), address(0));
        vm.stopPrank();
    }

    // 测试 getPriceInDollar 预言机未设置
    function test_getPriceInDollarOracleNotSet() public {
        address unknownToken = address(0x1234);
        
        vm.startPrank(admin);
        vm.expectRevert("oracle not set");
        auction.getPriceInDollar(unknownToken);
        vm.stopPrank();
    }

    // 测试 initialize 不能设置零地址 admin
    function test_initializeInvalidAdmin() public {
        MetaNFTAuction newImpl = new MetaNFTAuction();
        bytes memory initData = abi.encodeCall(MetaNFTAuction.initialize, (address(0)));
        
        vm.expectRevert("invalid admin");
        new TransparentUpgradeableProxy(address(newImpl), proxyAdmin, initData);
    }
}
