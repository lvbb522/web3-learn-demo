package homework01

// 1. 只出现一次的数字
// 给定一个非空整数数组，除了某个元素只出现一次以外，其余每个元素均出现两次。找出那个只出现了一次的元素。
func SingleNumber(nums []int) int {
	m := make(map[int]int)
	for i := 0; i < len(nums); i++ {
		if num, ok := m[nums[i]]; ok {
			m[nums[i]] = num + 1
		} else {
			m[nums[i]] = 1
		}
	}
	for key, value := range m {
		if value == 1 {
			return key
		}
	}
	return 0
}

// 2. 回文数
// 判断一个整数是否是回文数
func IsPalindrome(x int) bool {
	// 负数或末尾为0的非零数，直接排除
	if x < 0 || (x%10 == 0 && x != 0) {
		return false
	}

	// 为0
	if x == 0 {
		return true
	}

	// 只翻转后半部分，避免溢出
	y := 0
	for x > y {
		y = y*10 + x%10
		x /= 10
	}

	// 偶数位1221：x == y
	// 奇数位12321：x == y/10（中间位不影响回文）
	return x == y || x == y/10
}

// 3. 有效的括号
// 给定一个只包括 '(', ')', '{', '}', '[', ']' 的字符串，判断字符串是否有效
func IsValid(s string) bool {
	stack := make([]byte, 0)
	for i := 0; i < len(s); i++ {
		c := s[i]
		switch c {
		case '(', '[', '{':
			stack = append(stack, c)
		case ')':
			if len(stack) == 0 || stack[len(stack)-1] != '(' {
				return false
			}
			stack = stack[:len(stack)-1]
		case ']':
			if len(stack) == 0 || stack[len(stack)-1] != '[' {
				return false
			}
			stack = stack[:len(stack)-1]
		case '}':
			if len(stack) == 0 || stack[len(stack)-1] != '{' {
				return false
			}
			stack = stack[:len(stack)-1]
		}
	}
	return len(stack) == 0
}

// 4. 最长公共前缀
// 查找字符串数组中的最长公共前缀
func LongestCommonPrefix(strs []string) string {
	var templateStr string
	for index, str := range strs {
		if str == "" {
			return ""
		}
		if index == 0 {
			templateStr = str
		} else {
			minLen := 0
			if len(templateStr) > len(str) {
				minLen = len(str)
			} else {
				minLen = len(templateStr)
			}
			for i := 0; i < minLen; i++ {
				if templateStr[i] != str[i] {
					templateStr = templateStr[0:i]
					break
				}
			}
			if templateStr == "" {
				return ""
			}
		}
	}
	return templateStr
}

// func longestCommonPrefix(strs []string) string {
//     if len(strs) == 0 {
//         return ""
//     }

//     // 以第一个字符串为基准，逐列纵向扫描
//     for i := 0; i < len(strs[0]); i++ {
//         c := strs[0][i]
//         // 检查其余所有字符串在位置 i 的字符
//         for j := 1; j < len(strs); j++ {
//             // 两种情况终止：
//             // 1. 当前字符串长度不够（i 越界）
//             // 2. 字符不匹配
//             if i >= len(strs[j]) || strs[j][i] != c {
//                 return strs[0][:i]
//             }
//         }
//     }

//     // 第一个字符串本身就是最短公共前缀
//     return strs[0]
// }

// 5. 加一
// 给定一个由整数组成的非空数组所表示的非负整数，在该数的基础上加一
func PlusOne(digits []int) []int {
	for i := len(digits); i > 0; i-- {
		if digits[i-1] != 9 {
			digits[i-1] = digits[i-1] + 1
			break
		} else {
			digits[i-1] = 0
			if i == 1 {
				digits = append([]int{1}, digits...)
			}
		}
	}
	return digits
}

// 6. 删除有序数组中的重复项
// 给你一个有序数组 nums ，请你原地删除重复出现的元素，使每个元素只出现一次，返回删除后数组的新长度。
// 不要使用额外的数组空间，你必须在原地修改输入数组并在使用 O(1) 额外空间的条件下完成。
func RemoveDuplicates(nums []int) int {
	for i := 0; i < len(nums)-1; i++ {
		if nums[i] < nums[i+1] {
			continue
		}
		for j := i + 1; j < len(nums); j++ {
			if nums[i] < nums[j] {
				nums[i+1] = nums[j]
				break
			}
			if j == len(nums)-1 {
				return i + 1
			}
		}
	}
	return len(nums)
}

// func RemoveDuplicates(nums []int) int {
// 	if len(nums) == 0 {
// 		return 0
// 	}
// 	slow := 0 // slow 指向下一个不重复元素应放置的位置
// 	for fast := 1; fast < len(nums); fast++ {
// 		if nums[fast] != nums[slow] {
// 			slow++
// 			nums[slow] = nums[fast]
// 		}
// 	}
// 	return slow + 1
// }

// 7. 合并区间
// 以数组 intervals 表示若干个区间的集合，其中单个区间为 intervals[i] = [starti, endi] 。
// 请你合并所有重叠的区间，并返回一个不重叠的区间数组，该数组需恰好覆盖输入中的所有区间。
// {"Example 1", [][]int{{1, 3}, {2, 6}, {8, 10}, {15, 18}}, [][]int{{1, 6}, {8, 10}, {15, 18}}},
// {"Example 2", [][]int{{1, 4}, {4, 5}}, [][]int{{1, 5}}},
// {"Example 3", [][]int{{15, 18}, {2, 6}, {8, 10}, {1, 3}}, [][]int{{1, 6}, {8, 10}, {15, 18}}},
func Merge(intervals [][]int) [][]int {
	// 先对区间数组按照区间的起始位置进行排序
	n := len(intervals)
	for i := 0; i < n-1; i++ {
		for j := 0; j < n-1-i; j++ {
			if intervals[j][0] > intervals[j+1][0] {
				intervals[j], intervals[j+1] = intervals[j+1], intervals[j]
			}
		}
	}

	// 创建切片，并将第一个区间数据元素给切片
	result := [][]int{intervals[0]}

	for i := 1; i < len(intervals); i++ {
		last := result[len(result)-1]
		cur := intervals[i]

		// 当前区间的起始 <= 上一个区间的结束，说明有重叠
		if cur[0] <= last[1] {
			// 合并：更新上一个区间的结束位置为两者较大值
			if cur[1] > last[1] {
				result[len(result)-1][1] = cur[1]
			}
		} else {
			// 无重叠，直接追加
			result = append(result, cur)
		}
	}

	return result
}

// 8. 两数之和
// 给定一个整数数组 nums 和一个目标值 target，请你在该数组中找出和为目标值的那两个整数
func TwoSum(nums []int, target int) []int {
	for i := 0; i < len(nums)-1; i++ {
		findNum := target - nums[i]
		for j := i + 1; j < len(nums); j++ {
			if nums[j] == findNum {
				return []int{i, j}
			}
		}
	}
	return nil
}

// func TwoSum(nums []int, target int) []int {
// 	seen := make(map[int]int, len(nums)) // value -> index
// 	for i, num := range nums {
// 		complement := target - num
// 		if j, ok := seen[complement]; ok {
// 			return []int{j, i}
// 		}
// 		seen[num] = i
// 	}
// 	return nil
// }
