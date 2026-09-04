// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Voting {

    address private owner;
    // 记录是否是候选人
    mapping (string => bool) private isCandidates;
    // 存储候选人的得票数
    mapping (string => uint256) private votes;
    // 候选人名单
    string[] private candidateList;
    // 记录是否已经投票
    mapping (address => bool) private hasVoted;
    // 已经投票的名单
    address[] private votedList;
    // 候选人最多人数限制
    uint public constant MaxLength = 20;

    // 权限控制
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this");
        _;
    }

    // 构造函数，传入候选人列表,初始化候选人名单
    constructor(string[] memory candidates){
        require(candidates.length <= MaxLength, "Maximum of 20 candidates!");
        for (uint i = 0; i < candidates.length; i++) {
            isCandidates[candidates[i]] = true;
        }
        candidateList = candidates;
        owner = msg.sender;
    }

    function vote(string calldata candidate) external {
        require(isCandidates[candidate], "Please confirm if the candidate is correct!");
        require(!hasVoted[msg.sender], "Cannot vote repeatedly!");
        votes[candidate]++;
        hasVoted[msg.sender] = true;
        votedList.push(msg.sender);
    }

    function getVotes(string calldata candidate) external view returns (uint) {
        return votes[candidate];
    }

    function resetVotes() external onlyOwner {
        uint candidateListLength = candidateList.length;
        for (uint256 i = 0; i < candidateListLength; i++) {
            delete votes[candidateList[i]];
        }
        uint votedListLength = votedList.length;
        for (uint256 i = 0; i < votedListLength; i++) {
            delete hasVoted[votedList[i]];
        }
        delete votedList;
    }

}