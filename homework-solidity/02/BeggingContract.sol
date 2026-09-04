// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract BeggingContract {
    
    address public owner;
    // 记录每个地址的累计捐赠
    mapping(address => uint256) public donations;
    
    // 额外挑战1: 捐赠事件
    event Donation(address indexed donor, uint256 amount, uint256 timestamp);
    
    // 额外挑战2: 排行榜追踪
    struct TopDonor {
        address addr;
        uint256 amount;
    }
    TopDonor[3] public topDonors;

    // 额外挑战3: 时间限制
    uint256 public donationStartTime;
    uint256 public donationEndTime;

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this");
        _;
    }
    
    modifier withinDonationPeriod() {
        // require(
        //     block.timestamp >= donationStartTime && block.timestamp <= donationEndTime,
        //     "Donation period not active"
        // );
        _;
    }

    constructor(uint256 _startTime, uint256 _endTime) {
        require(_startTime < _endTime, "Invalid time range");
        owner = msg.sender;
        donationStartTime = _startTime;
        donationEndTime = _endTime;
    }

    
    // 捐赠函数
    function donate() external payable withinDonationPeriod {
        require(msg.value > 0, "Donation must be > 0");
        
        donations[msg.sender] += msg.value;
        
        emit Donation(msg.sender, msg.value, block.timestamp);
        
        // 更新排行榜
        _updateLeaderboard(msg.sender, donations[msg.sender]);
    }

    function getDonation(address donor) external view returns (uint256) {
        return donations[donor];
    }

    // 所有者提取全部资金
    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No funds to withdraw");
        
        // 使用 call 替代 transfer（transfer 有 2300 gas 限制，可能导致提款失败）
        (bool success, ) = owner.call{value: balance}("");
        require(success, "Withdraw failed");
    }

    // 维护前3名捐赠者排行榜（插入排序）
    function _updateLeaderboard(address donor, uint256 newAmount) internal {
        for (uint256 i = 0; i < 3; i++) {
            if (newAmount > topDonors[i].amount) {
                for (uint256 j = 2; j > i; j--) {
                    topDonors[j] = topDonors[j - 1];
                }
                topDonors[i] = TopDonor(donor, newAmount);
                break;
            }
        }
    }
}