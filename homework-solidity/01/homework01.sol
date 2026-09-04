// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Homework01 {
    
    // 反转字符串 (Reverse String) 题目描述：反转一个字符串。输入 "abcde"，输出 "edcba"
    function ReverseString(string memory str) pure external returns (string memory) {
        bytes memory b = bytes(str);
        uint256 len = b.length;
        // 空字符串或单字符直接返回
        if (len <= 1) return str;
        bytes memory reversed = new bytes(len);
        for (uint256 i = 0; i < len; i++) {
            reversed[i] = b[len - 1 - i];
        }
        return string(reversed);
    }

    // 用 solidity 实现整数转罗马数字
    uint16 private constant NUM_VALUES = 13;
    function intToRoman(uint256 num) external pure returns (string memory) {
        require(num > 0 && num <= 3999, "Input must be between 1 and 3999");

        uint16[13] memory values = [
            1000, 900, 500, 400, 100, 90, 50, 40, 10, 9, 5, 4, 1
        ];
        string[13] memory symbols = [
            "M", "CM", "D", "CD", "C", "XC", "L", "XL", "X", "IX", "V", "IV", "I"
        ];
        
        bytes memory result = new bytes(15); // 最大长度: 3888 -> MMMDCCCLXXXVIII (15字符)
        uint256 len = 0;
        
        for (uint256 i = 0; i < NUM_VALUES; i++) {
            while (num >= values[i]) {
                // 将当前符号追加到结果中
                bytes memory symbol = bytes(symbols[i]);
                for (uint256 j = 0; j < symbol.length; j++) {
                    result[len++] = symbol[j];
                }
                num -= values[i];
            }
        }
        
        // 截取实际长度并返回
        bytes memory trimmed = new bytes(len);
        for (uint256 i = 0; i < len; i++) {
            trimmed[i] = result[i];
        }
        
        return string(trimmed);
    }

    // 用 solidity 实现罗马数字转数整数
    function romanToInt(string memory roman) external pure returns (uint256) {
        bytes memory b = bytes(roman);
        uint256 len = b.length;
        require(len > 0, "Empty string");

        uint256 result = 0;
        uint256 prevValue = 0;

        for (uint256 i = len-1; i >= 0; i--) {
            uint256 currValue = _charToValue(b[i]);
            require(currValue != 0, "Invalid Roman character");

            if (currValue < prevValue) {
                // 当前值小于右侧值 → 减法
                result -= currValue;
            } else {
                // 当前值 >= 右侧值 → 加法
                result += currValue;
                prevValue = currValue;
            }
        }

        return result;
    }

    // @dev 单个罗马字符 → 数值映射 返回 0 表示非法字符（由调用方 require 检查）
    function _charToValue(bytes1 c) internal pure returns (uint256) {
        if (c == 'I') return 1;
        if (c == 'V') return 5;
        if (c == 'X') return 10;
        if (c == 'L') return 50;
        if (c == 'C') return 100;
        if (c == 'D') return 500;
        if (c == 'M') return 1000;
        return 0;
    }

    // 合并两个有序数组 (Merge Sorted Array) 题目描述：将两个有序数组合并为一个有序数组。
    function mergeSortedArray(uint256[] memory ary1, uint256[] memory ary2) external pure returns (uint256[] memory) {

        uint i;
        uint j;
        uint k;
        uint256 len1 = ary1.length;
        uint256 len2 = ary2.length;
        uint256[] memory result = new uint256[](len1 + len2);

        while ((i < ary1.length)&&(j < ary2.length)) {
            if (ary1[i] <= ary2[j]) {
                result[k] = ary1[i];
                i++;
            } else {
                result[k] = ary2[j];
                j++;
            }
            k++;
        }

        while (i < len1) {
            result[k] = ary1[i];
            i++;
            k++;
        }
        while (j < len2) {
            result[k] = ary2[j];
            j++;
            k++;
        }

        return result;
    }

    // 二分查找 (Binary Search) 题目描述：在一个有序数组中查找目标值。
    function binarySearch(uint256[] memory arr, uint target) external pure returns (bool found, uint256 index) {
        uint256 len = arr.length;
        if (len == 0) return (false, 0);

        uint256 low = 0;
        uint256 high = len - 1;

        while (low <= high) {
            uint256 mid = low + (high - low) / 2;

            if (arr[mid] == target) {
                return (true, mid);
            } else if (arr[mid] < target) {
                low = mid + 1;
            } else {
                high = mid - 1; 
            }
        }

        return (false, 0);
    }

}