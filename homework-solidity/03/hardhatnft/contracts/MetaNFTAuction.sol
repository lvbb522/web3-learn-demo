// SPDX-License-Identifier: MIT
pragma solidity ^0.8.34;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";

contract MetaNFTAuction is Initializable {
    address admin;
    mapping(address => address) public tokenToOracle;   // 代币 → 预言机地址

    struct Auction {
    IERC721 nft;              // NFT 合约地址
    uint256 nftId;            // NFT ID
    address payable seller;   // 卖家地址
    uint256 startingTime;     // 开始时间
    address highestBidder;    // 最高出价者
    uint256 startingPriceInDollar; // 起拍价（美元，8位小数）
    uint256 duration;         // 拍卖时长（秒）
    IERC20 paymentToken;      // 支付代币地址
    uint256 highestBid;       // 最高出价（原始代币数量）
    uint256 highestBidInDollar; // 最高出价（美元价值）
    address highestBidToken;  // 最高出价使用的代币地址
}
    mapping(uint256 => Auction) public auctions;

    event StartBid(uint256 startingBid);
    event Bid(address indexed sender, uint256 amount);
    event EndBid(uint256 indexed auctionId);

    uint256 public auctionId;

    modifier onlyAdmin() {
        require(msg.sender == admin, "not admin");
        _;
    }
    // 初始化
    constructor() {
       _disableInitializers();
    }

    function initialize(address admin_) external initializer {
        require(admin_ != address(0), "invalid admin");
        admin = admin_;
    }

    function setTokenOracle(address token, address oracle) external onlyAdmin {
        require(oracle != address(0), "invalid oracle");
        tokenToOracle[token] = oracle;
    }

// 管理员启动一个新的拍卖
// 1. 验证参数（NFT 地址、时长、支付代币）
// 2. 创建 Auction 结构体
// 3. 将 NFT 从卖家转移到合约（托管）
// 4. auctionId 自增
// 5. 触发 StartBid 事件
    // 卖家发起拍卖
    function start(
        address seller,
        uint256 nftId,
        address nft,
        uint256 startingPriceInDollar,
        uint256 duration,
        address paymentToken
    ) external onlyAdmin {
        require(nft != address(0), "invalid nft");
        require(duration >= 30, "invalid duration");
        require(paymentToken != address(0), "invalid payment token");
        Auction storage auction = auctions[auctionId];
        auction.nft = IERC721(nft);
        auction.nftId = nftId;
        auction.seller = payable(seller);
        auction.startingTime = block.timestamp;
        auction.startingPriceInDollar = startingPriceInDollar * 10**8;
        auction.duration = duration;
        auction.paymentToken = IERC20(paymentToken);
        auction.highestBid = 0;
        auction.highestBidder = address(0);
        auction.highestBidInDollar = 0;
        auction.highestBidToken = address(0);
        IERC721(nft).transferFrom(seller, address(this), nftId);
        auctionId++;
        emit StartBid(auctionId);
    }

// 1. 验证拍卖状态（已开始、未结束）
// 2. 计算出价的美元价值
//    ├─ ETH 出价: msg.value > 0
//    │   └─ 调用 ETH/USD 预言机
//    └─ ERC20 出价: amount > 0
//        └─ 调用代币/USD 预言机
// 3. 验证出价金额 > 起拍价
// 4. 验证出价金额 > 当前最高价
// 5. 退款给前最高出价者（如果存在）
// 6. 更新最高出价信息
// 7. 触发 Bid 事件
    // 买家竞价
    function bid(uint256 auctionId_, uint256 amount) external payable {
        Auction storage auction = auctions[auctionId_];
        require(auction.startingTime > 0, "not started");
        require(!isEnded(auctionId_), "ended");
        uint256 bidPrice;
        bool isEthBid = msg.value > 0;
        if (isEthBid) {
            require(amount == msg.value, "amount mismatch");
            uint256 price = getPriceInDollar(address(0));
            bidPrice = _toUsd(msg.value, 18, price);
        } else {
            require(amount > 0, "invalid amount");
            uint256 price = getPriceInDollar(address(auction.paymentToken));
            uint8 tokenDecimals = IERC20Metadata(address(auction.paymentToken)).decimals();
            bidPrice = _toUsd(amount, tokenDecimals, price);
            IERC20(address(auction.paymentToken)).transferFrom(msg.sender, address(this), amount);
        }
        require(auction.startingPriceInDollar < bidPrice, "invalid startingPrice");
        require(auction.highestBidInDollar < bidPrice, "invalid highestBid");
        if (auction.highestBidder != address(0) && auction.highestBidder != msg.sender) {
            uint256 refundAmount = auction.highestBid;
            if (refundAmount > 0) {
                if (auction.highestBidToken == address(0)) {
                    (bool success, ) = payable(auction.highestBidder).call{value: refundAmount}("");
                    require(success, "Refund failed");
                } else {
                    IERC20(address(auction.paymentToken)).transfer(auction.highestBidder, refundAmount);
                }
            }
        }
        if (isEthBid) {
            auction.highestBid = msg.value;
            auction.highestBidToken = address(0);
        } else {
            auction.highestBid = amount;
            auction.highestBidToken = address(auction.paymentToken);
        }
        auction.highestBidder = msg.sender;
        auction.highestBidInDollar = bidPrice;
        emit Bid(msg.sender, msg.value);
    }

    function isEnded(uint256 auctionId_) public view returns (bool) {
        Auction storage auction = auctions[auctionId_];
        return auction.startingTime > 0 && block.timestamp >= auction.startingTime + auction.duration;
    }

    function end(uint256 auctionId_) external {
        Auction storage auction = auctions[auctionId_];
        require(isEnded(auctionId_), "not ended");
        require(auction.highestBidder != address(0), "no bids");
        
        auction.nft.transferFrom(address(this), auction.highestBidder, auction.nftId);
        
        if (auction.highestBid > 0) {
            if (auction.highestBidToken == address(0)) {
                (bool success, ) = payable(auction.seller).call{value: auction.highestBid}("");
                require(success, "Refund failed");
            } else {
                IERC20(auction.highestBidToken).transfer(auction.seller, auction.highestBid);
            }
        }
        emit EndBid(auctionId_);
    }

    function getPriceInDollar(address token) public view returns (uint256) {
        AggregatorV3Interface dataFeed;
        address oracle = tokenToOracle[token];
        require(oracle != address(0), "oracle not set");
        dataFeed = AggregatorV3Interface(oracle);
        (
            /* uint80 roundId */
            ,
            int256 answer,
            /*uint256 startedAt*/
            ,
            /*uint256 updatedAt*/
            ,
            /*uint80 answeredInRound*/
        ) = dataFeed.latestRoundData();
        return uint256(answer);
    }

    // 8位小数的usd
    function _toUsd(uint256 amount, uint256 amountDecimals, uint256 price)
        internal
        pure
        returns (uint256)
    {
        // amount is in smallest units; convert to USD using price decimals.
        uint256 scale = 10 ** amountDecimals;
        uint256 usd = (amount * price) / scale;
        return usd;
    }
    
    function getVersion() external pure virtual returns (string memory) {
        return "MetaNFTAuctionV1";
    }
}
