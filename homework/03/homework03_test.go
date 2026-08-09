package homework03

import (
	"fmt"
	"homework03/testutil"
	"testing"
)

// 题目1：模型定义
func TestInitDb(t *testing.T) {
	InitDb(t)
}

// 题目2：关联查询
// 查询某个用户发布的所有文章及其对应的评论信息。
// 查询评论数量最多的文章信息。
func Test02(t *testing.T) {
	posts, _ := QueryUserPostsWithComments(t, 1)
	post, count, _ := QueryMostCommentedPost(t)

	fmt.Printf("ID为1用户文章数: %d\n", len(posts))
	fmt.Printf("ID为1用户的所有文章及评论信息:\n")
	fmt.Printf("%+v\n", posts)

	fmt.Printf("评论数量最多的文章的评论数量: %d\n", count)
	fmt.Printf("评论数量最多的文章信息:\n")
	fmt.Printf("%+v\n", post)
}

// 题目3：钩子函数
func Test03(t *testing.T) {
	db := testutil.NewTestDB(t, "")
	user := User{Name: "wangwu", Email: "wangwu@163.com", PostCount: 0}
	db.Create(&user)

	post := Post{Title: "王五文章1标题", Content: "王五文章1内容", UserID: user.ID, CommentStatus: "有评论"}
	// 测试 AfterCreate，执行完wangwu的PostCount为1
	db.Create(&post)

	comment := Comment{Content: "王五文章1的评论1", PostID: post.ID}
	db.Create(&comment)
	// 测试 AfterDelete，执行完post的CommentStatus为无评论
	db.Delete(&comment)
}
