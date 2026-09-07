// SPDX-License-Identifier: MIT
pragma solidity ^0.8.34;

import "forge-std/Test.sol";
import "../contracts/MetaNFTAuctionUUPS.sol";
import "../contracts/MetaNFTAuctionUUPS_V2.sol";
import "../contracts/MetaNFT.sol";
import "../contracts/MockERC20.sol";
import "../contracts/MockOracle.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract MetaNFTAuctionUUPSTest is Test {
    MetaNFTAuctionUUPS public auction;
    MetaNFTAuctionUUPS_V2 public auctionV2;
    MetaNFT public nft;
    MockERC20 public usdc;
    MockOracle public ethOracle;
    MockOracle public usdcOracle;
    
    address public admin = address(0x1);
    address public seller = address(0x2);
    address public bidder1 = address(0x3);
    address public bidder2 = address(0x4);

    event EndBid(uint256 indexed auctionId);
    
    function setUp() public {
        MetaNFTAuctionUUPS implementation = new MetaNFTAuctionUUPS();
        
        bytes memory initData = abi.encodeCall(MetaNFTAuctionUUPS.initialize, (admin));
        
        ERC1967Proxy proxy = new ERC1967Proxy(
            address(implementation),
            initData
        );
        
        auction = MetaNFTAuctionUUPS(address(proxy));
        
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
        
        vm.deal(seller, 10 ether);
        vm.deal(bidder1, 10 ether);
        vm.deal(bidder2, 10 ether);
    }

    function test_initialize() public view {
        assertEq(auction.owner(), admin);
        assertEq(auction.getVersion(), "MetaNFTAuctionUUPS V1");
    }

    function test_initializeCannotBeCalledTwice() public {
        vm.expectRevert(abi.encodeWithSelector(Initializable.InvalidInitialization.selector));
        auction.initialize(admin);
    }

    function test_setTokenOracle() public {
        vm.startPrank(admin);
        address newOracle = address(0x123);
        auction.setTokenOracle(address(0), newOracle);
        assertEq(auction.tokenToOracle(address(0)), newOracle);
        vm.stopPrank();
    }

    function test_setTokenOracleOnlyOwner() public {
        vm.startPrank(seller);
        vm.expectRevert(abi.encodeWithSelector(MetaNFTAuctionUUPS.OwnableUnauthorizedAccount.selector, seller));
        auction.setTokenOracle(address(0), address(0x123));
        vm.stopPrank();
    }

    function test_startAuction() public {
        vm.startPrank(admin);
        auction.start(seller, 1, address(nft), 1000, 3600, address(usdc));
        assertEq(auction.auctionId(), 1);
        
        (
            IERC721 nftContract,
            uint256 nftId,
            address sellerAddr,
            uint256 startingTime,
            address highestBidder,
            uint256 startingPriceInDollar,
            uint256 duration,
            IERC20 paymentTokenContract,
            uint256 highestBid,
            uint256 highestBidInDollar,
            address highestBidToken
        ) = auction.auctions(0);
        
        assertEq(address(nftContract), address(nft));
        assertEq(nftId, 1);
        assertEq(sellerAddr, seller);
        assertGt(startingTime, 0);
        assertEq(highestBidder, address(0));
        assertEq(startingPriceInDollar, 1000e8);
        assertEq(duration, 3600);
        assertEq(address(paymentTokenContract), address(usdc));
        assertEq(highestBid, 0);
        assertEq(highestBidInDollar, 0);
        assertEq(highestBidToken, address(0));
        vm.stopPrank();
    }

    function test_startAuctionOnlyOwner() public {
        vm.startPrank(seller);
        vm.expectRevert(abi.encodeWithSelector(MetaNFTAuctionUUPS.OwnableUnauthorizedAccount.selector, seller));
        auction.start(seller, 1, address(nft), 1000, 3600, address(usdc));
        vm.stopPrank();
    }

    function test_bidWithETH() public {
        vm.startPrank(admin);
        auction.start(seller, 1, address(nft), 1000, 3600, address(usdc));
        vm.stopPrank();
        
        uint256 auctionId_ = auction.auctionId() - 1;
        
        vm.startPrank(bidder1);
        auction.bid{value: 2 ether}(auctionId_, 2 ether);
        
        (,,,, address highestBidder,,,, uint256 highestBid,,) = auction.auctions(auctionId_);
        assertEq(highestBidder, bidder1);
        assertEq(highestBid, 2 ether);
        vm.stopPrank();
    }

    function test_bidWithERC20() public {
        vm.startPrank(admin);
        auction.start(seller, 1, address(nft), 1000, 3600, address(usdc));
        vm.stopPrank();
        
        uint256 auctionId_ = auction.auctionId() - 1;
        
        vm.startPrank(bidder1);
        usdc.mint(bidder1, 100000e18);
        usdc.approve(address(auction), 100000e18);
        auction.bid(auctionId_, 100000e18);
        
        (,,,, address highestBidder,,,, uint256 highestBid,,) = auction.auctions(auctionId_);
        assertEq(highestBidder, bidder1);
        assertEq(highestBid, 100000e18);
        vm.stopPrank();
    }

    function test_bidEnded() public {
        vm.startPrank(admin);
        auction.start(seller, 1, address(nft), 1000, 30, address(usdc));
        uint256 auctionId_ = auction.auctionId() - 1;
        vm.stopPrank();
        
        vm.warp(block.timestamp + 50);
        
        vm.startPrank(bidder1);
        vm.expectRevert("ended");
        auction.bid{value: 1 ether}(auctionId_, 1 ether);
        vm.stopPrank();
    }

    function test_bidLowerThanHighestBid() public {
        vm.startPrank(admin);
        auction.start(seller, 1, address(nft), 1000, 3600, address(usdc));
        uint256 auctionId_ = auction.auctionId() - 1;
        vm.stopPrank();
        
        vm.startPrank(bidder1);
        auction.bid{value: 2 ether}(auctionId_, 2 ether);
        vm.stopPrank();
        
        vm.startPrank(bidder2);
        vm.expectRevert("invalid highestBid");
        auction.bid{value: 1 ether}(auctionId_, 1 ether);
        vm.stopPrank();
    }

    function test_endAuction() public {
        vm.startPrank(admin);
        auction.start(seller, 1, address(nft), 1000, 30, address(usdc));
        uint256 auctionId_ = auction.auctionId() - 1;
        vm.stopPrank();
        
        vm.startPrank(bidder1);
        auction.bid{value: 2 ether}(auctionId_, 2 ether);
        vm.stopPrank();
        
        vm.warp(block.timestamp + 50);
        
        uint256 sellerBalanceBefore = seller.balance;
        
        auction.end(auctionId_);
        
        assertEq(nft.ownerOf(1), bidder1);
        assertGt(seller.balance, sellerBalanceBefore);
    }

    function test_upgradeToV2() public {
        vm.startPrank(admin);
        auction.start(seller, 1, address(nft), 1000, 3600, address(usdc));
        uint256 oldAuctionId = auction.auctionId();
        vm.stopPrank();
        
        MetaNFTAuctionUUPS_V2 newImplementation = new MetaNFTAuctionUUPS_V2();
        
        vm.startPrank(admin);
        auction.upgradeToAndCall(address(newImplementation), "");
        vm.stopPrank();
        
        auctionV2 = MetaNFTAuctionUUPS_V2(address(auction));
        
        assertEq(auctionV2.auctionId(), oldAuctionId);
        assertEq(auctionV2.getVersion(), "MetaNFTAuctionUUPS V2");
        assertEq(auctionV2.newFeature(), "This is a new feature in UUPS V2");
    }

    function test_upgradeOnlyOwner() public {
        MetaNFTAuctionUUPS_V2 newImplementation = new MetaNFTAuctionUUPS_V2();
        
        vm.startPrank(seller);
        vm.expectRevert(abi.encodeWithSelector(MetaNFTAuctionUUPS.OwnableUnauthorizedAccount.selector, seller));
        auction.upgradeToAndCall(address(newImplementation), "");
        vm.stopPrank();
    }

    function test_upgradeAndSetNewOracle() public {
        vm.startPrank(admin);
        auction.start(seller, 1, address(nft), 1000, 3600, address(usdc));
        vm.stopPrank();
        
        MetaNFTAuctionUUPS_V2 newImplementation = new MetaNFTAuctionUUPS_V2();
        
        vm.startPrank(admin);
        auction.upgradeToAndCall(address(newImplementation), "");
        
        auctionV2 = MetaNFTAuctionUUPS_V2(address(auction));
        
        MockOracle newEthOracle = new MockOracle(4000e8);
        auctionV2.setTokenOracle(address(0), address(newEthOracle));
        
        uint256 price = auctionV2.getPriceInDollar(address(0));
        assertEq(price, 4000e8);
        vm.stopPrank();
    }

    function test_getPriceInDollar() public view {
        uint256 price = auction.getPriceInDollar(address(0));
        assertEq(price, 3000e8);
        
        uint256 usdcPrice = auction.getPriceInDollar(address(usdc));
        assertEq(usdcPrice, 1e8);
    }

    function test_isEnded() public {
        vm.startPrank(admin);
        auction.start(seller, 1, address(nft), 1000, 30, address(usdc));
        uint256 auctionId_ = auction.auctionId() - 1;
        vm.stopPrank();
        
        assertFalse(auction.isEnded(auctionId_));
        
        vm.warp(block.timestamp + 50);
        
        assertTrue(auction.isEnded(auctionId_));
    }

    function test_ownershipTransfer() public {
        address newOwner = address(0x5);
        
        vm.startPrank(admin);
        auction.transferOwnership(newOwner);
        assertEq(auction.owner(), newOwner);
        vm.stopPrank();
    }

    // ================================================================
    // 新增测试用例 - 补全覆盖率
    // ================================================================

    // ========== 覆盖行 122-126: ETH 退款逻辑（bid 函数中的退款） ==========
    
    function test_bidRefundWithETH() public {
        // 创建 ETH 拍卖（使用 USDC 作为支付代币，但用 ETH 出价）
        vm.startPrank(admin);
        auction.start(seller, 1, address(nft), 1000, 3600, address(usdc));
        uint256 auctionId_ = auction.auctionId() - 1;
        vm.stopPrank();

        // bidder1 出价 2 ETH
        vm.startPrank(bidder1);
        auction.bid{value: 2 ether}(auctionId_, 2 ether);
        vm.stopPrank();

        uint256 bidder1BalanceBefore = bidder1.balance;

        // bidder2 出价 3 ETH（超过 bidder1，触发退款）
        vm.startPrank(bidder2);
        auction.bid{value: 3 ether}(auctionId_, 3 ether);
        vm.stopPrank();

        // 验证 bidder1 收到了 2 ETH 退款（覆盖行 124-126: call 和 require success）
        uint256 bidder1BalanceAfter = bidder1.balance;
        assertEq(bidder1BalanceAfter, bidder1BalanceBefore + 2 ether);
        
        // 验证 bidder2 成为最高出价者
        (,,,, address highestBidder,,,, uint256 highestBid,,) = auction.auctions(auctionId_);
        assertEq(highestBidder, bidder2);
        assertEq(highestBid, 3 ether);
    }

    // ========== 覆盖行 122-126: 退款失败的情况 ==========
    
    // 注意：由于 Solidity 的 call 在发送到没有接收函数的合约时可能会失败
    // 但 auction 合约本身可以接收 ETH，所以退款通常不会失败
    // 这个测试通过模拟一个特殊场景来测试 require(success) 分支
    
    function test_bidRefundWithETH_WhenReceiverCannotReceiveETH() public {
        // 创建一个接收 ETH 时 revert 的合约
        address nonPayableBidder = address(new NonPayableContract());
        
        vm.startPrank(admin);
        auction.start(seller, 1, address(nft), 1000, 3600, address(usdc));
        uint256 auctionId_ = auction.auctionId() - 1;
        vm.stopPrank();

        // 给 nonPayableBidder 一些 ETH
        vm.deal(nonPayableBidder, 5 ether);
        
        // bidder 出价
        vm.startPrank(nonPayableBidder);
        auction.bid{value: 2 ether}(auctionId_, 2 ether);
        vm.stopPrank();

        // 验证 nonPayableBidder 成为最高出价者
        (,,,, address highestBidder,,,, uint256 highestBid,,) = auction.auctions(auctionId_);
        assertEq(highestBidder, nonPayableBidder);
        assertEq(highestBid, 2 ether);

        // bidder2 出价 3 ETH，触发退款给 nonPayableBidder
        // 由于 nonPayableBidder 的 receive 会 revert，所以 call 失败
        vm.startPrank(bidder2);
        vm.expectRevert("Refund failed");
        auction.bid{value: 3 ether}(auctionId_, 3 ether);
        vm.stopPrank();
    }

    // ========== 覆盖行 128: ETH 出价时 highestBidToken 设置为 address(0) ==========
    
    function test_bidWithETH_setsHighestBidTokenToZero() public {
        vm.startPrank(admin);
        auction.start(seller, 1, address(nft), 1000, 3600, address(usdc));
        uint256 auctionId_ = auction.auctionId() - 1;
        vm.stopPrank();

        vm.startPrank(bidder1);
        auction.bid{value: 2 ether}(auctionId_, 2 ether);
        vm.stopPrank();

        // 验证 highestBidToken 为 address(0)（覆盖行 128）
        (, , , , , , , , , , address highestBidToken) = auction.auctions(auctionId_);
        assertEq(highestBidToken, address(0));
    }

    // ========== 覆盖行 161: EndBid 事件 ==========
    
    function test_endAuction_emitsEndBidEvent() public {
        vm.startPrank(admin);
        auction.start(seller, 1, address(nft), 1000, 30, address(usdc));
        uint256 auctionId_ = auction.auctionId() - 1;
        vm.stopPrank();

        vm.startPrank(bidder1);
        auction.bid{value: 2 ether}(auctionId_, 2 ether);
        vm.stopPrank();

        vm.warp(block.timestamp + 50);

        // 监听 EndBid 事件（覆盖行 161）
        vm.expectEmit(true, false, false, true);
        emit EndBid(auctionId_);

        auction.end(auctionId_);
    }

    // ========== 额外补充测试：end 函数中的 NFT 转账和资金转移 ==========
    
    function test_endAuction_withERC20Payment() public {
        vm.startPrank(admin);
        auction.start(seller, 1, address(nft), 1000, 3600, address(usdc));
        uint256 auctionId_ = auction.auctionId() - 1;
        vm.stopPrank();

        uint256 bidAmount = 2000e6;
        vm.startPrank(admin);
        usdc.mint(bidder1, bidAmount);
        vm.stopPrank();

        vm.startPrank(bidder1);
        usdc.approve(address(auction), bidAmount);
        auction.bid(auctionId_, bidAmount);
        vm.stopPrank();

        vm.warp(block.timestamp + 3600);

        uint256 sellerBalanceBefore = usdc.balanceOf(seller);

        vm.startPrank(admin);
        auction.end(auctionId_);
        vm.stopPrank();

        // 验证 NFT 已转移给最高出价者
        assertEq(nft.ownerOf(1), bidder1);
        
        // 验证 USDC 已转移给卖家
        assertEq(usdc.balanceOf(seller), sellerBalanceBefore + bidAmount);
    }

    // ========== 测试 end 函数在没有出价时回滚 ==========
    
    function test_endAuction_withNoBids() public {
        vm.startPrank(admin);
        auction.start(seller, 1, address(nft), 1000, 30, address(usdc));
        uint256 auctionId_ = auction.auctionId() - 1;
        vm.stopPrank();

        vm.warp(block.timestamp + 50);

        vm.startPrank(admin);
        vm.expectRevert("no bids");
        auction.end(auctionId_);
        vm.stopPrank();
    }

    // ========== 测试 start 函数的参数验证 ==========
    
    function test_startAuction_invalidNFT() public {
        vm.startPrank(admin);
        vm.expectRevert("invalid nft");
        auction.start(seller, 1, address(0), 1000, 3600, address(usdc));
        vm.stopPrank();
    }

    function test_startAuction_invalidDuration() public {
        vm.startPrank(admin);
        vm.expectRevert("invalid duration");
        auction.start(seller, 1, address(nft), 1000, 29, address(usdc));
        vm.stopPrank();
    }

    function test_startAuction_invalidPaymentToken() public {
        vm.startPrank(admin);
        vm.expectRevert("invalid payment token");
        auction.start(seller, 1, address(nft), 1000, 3600, address(0));
        vm.stopPrank();
    }

    // ========== 测试 setTokenOracle 不能设置零地址 ==========
    
    function test_setTokenOracle_invalidOracle() public {
        vm.startPrank(admin);
        vm.expectRevert("invalid oracle");
        auction.setTokenOracle(address(0), address(0));
        vm.stopPrank();
    }

    // ========== 测试 getPriceInDollar 预言机未设置 ==========
    
    function test_getPriceInDollar_oracleNotSet() public {
        address unknownToken = address(0x1234);
        
        vm.startPrank(admin);
        vm.expectRevert("oracle not set");
        auction.getPriceInDollar(unknownToken);
        vm.stopPrank();
    }

    // ========== 测试 transferOwnership 只有 owner 可以调用 ==========
    
    function test_transferOwnership_onlyOwner() public {
        address newOwner = address(0x5);
        
        vm.startPrank(seller);
        vm.expectRevert(abi.encodeWithSelector(MetaNFTAuctionUUPS.OwnableUnauthorizedAccount.selector, seller));
        auction.transferOwnership(newOwner);
        vm.stopPrank();
    }

    // ========== 测试 transferOwnership 不能设置零地址 ==========
    
    function test_transferOwnership_invalidAddress() public {
        vm.startPrank(admin);
        vm.expectRevert("invalid new owner");
        auction.transferOwnership(address(0));
        vm.stopPrank();
    }

    // ========== 测试 initialize 不能设置零地址 ==========
    
    function test_initialize_invalidAdmin() public {
        MetaNFTAuctionUUPS implementation = new MetaNFTAuctionUUPS();
        
        bytes memory initData = abi.encodeCall(MetaNFTAuctionUUPS.initialize, (address(0)));
        
        vm.expectRevert("invalid admin");
        new ERC1967Proxy(address(implementation), initData);
    }

    // ========== 测试 bid 函数中 amount mismatch 的情况 ==========
    
    function test_bid_amountMismatch() public {
        vm.startPrank(admin);
        auction.start(seller, 1, address(nft), 1000, 3600, address(usdc));
        uint256 auctionId_ = auction.auctionId() - 1;
        vm.stopPrank();

        vm.startPrank(bidder1);
        vm.deal(bidder1, 2 ether);
        vm.expectRevert("amount mismatch");
        auction.bid{value: 2 ether}(auctionId_, 1.5 ether);
        vm.stopPrank();
    }

    // ========== 测试 bid 函数中无效的 ERC20 amount ==========
    
    function test_bid_invalidERC20Amount() public {
        vm.startPrank(admin);
        auction.start(seller, 1, address(nft), 1000, 3600, address(usdc));
        uint256 auctionId_ = auction.auctionId() - 1;
        vm.stopPrank();

        vm.startPrank(bidder1);
        vm.expectRevert("invalid amount");
        auction.bid(auctionId_, 0);
        vm.stopPrank();
    }

    // ========== 测试 bid 函数中出价低于起拍价 ==========
    
    function test_bid_lowerThanStartingPrice() public {
        vm.startPrank(admin);
        // 起拍价 1000 USDC
        auction.start(seller, 1, address(nft), 1000, 3600, address(usdc));
        uint256 auctionId_ = auction.auctionId() - 1;
        vm.stopPrank();

        // 出价 500 USDC（低于起拍价）
        uint256 bidAmount = 500e6;
        vm.startPrank(admin);
        usdc.mint(bidder1, bidAmount);
        vm.stopPrank();

        vm.startPrank(bidder1);
        usdc.approve(address(auction), bidAmount);
        vm.expectRevert("invalid startingPrice");
        auction.bid(auctionId_, bidAmount);
        vm.stopPrank();
    }
}

// ========== 辅助合约：不能接收 ETH 的合约 ==========
contract NonPayableContract {
    receive() external payable {
        revert("Cannot receive ETH");
    }
}