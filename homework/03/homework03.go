package homework03

import (
	"fmt"
	"homework03/testutil"
	"log"
	"testing"
	"time"

	"gorm.io/gorm"
)

type User struct {
	ID        uint   `gorm:"primaryKey"`
	Email     string `gorm:"type:varchar(255)"`
	Name      string `gorm:"type:varchar(255)"`
	PostCount int    `gorm:"default:0;comment:文章数量统计"`
	CreatedAt time.Time
	UpdatedAt time.Time
	Posts     []Post
	// Comments  []Comment
}

type Post struct {
	ID            uint   `gorm:"primaryKey"`
	Title         string `gorm:"type:varchar(255);not null"`
	Content       string `gorm:"type:text"`
	UserID        uint   `gorm:"index;not null"`
	CommentStatus string `gorm:"type:varchar(255);default:'无评论'"`
	CreatedAt     time.Time
	UpdatedAt     time.Time
	Comments      []Comment
}

type Comment struct {
	ID      uint   `gorm:"primaryKey"`
	Content string `gorm:"type:text;not null"`
	PostID  uint   `gorm:"index;not null"`
	// UserID    uint   `gorm:"index;not null"`
	CreatedAt time.Time
	UpdatedAt time.Time
}

func InitDb(t *testing.T) {
	db := testutil.NewTestDB(t, "")

	if err := db.AutoMigrate(&User{}, &Post{}, &Comment{}); err != nil {
		t.Fatalf("auto migrate: %v", err)
	}

	db.Exec("SET FOREIGN_KEY_CHECKS = 0")
	db.Exec("TRUNCATE users")
	db.Exec("TRUNCATE posts")
	db.Exec("TRUNCATE comments")
	db.Exec("SET FOREIGN_KEY_CHECKS = 1")

	// comment1 := Comment{
	// 	Content: "张三文章1的评论1-李四",
	// }
	// comment2 := Comment{
	// 	Content: "张三文章1的评论2-李四",
	// }
	// comment3 := Comment{
	// 	Content: "张三文章2的评论1-李四",
	// }
	// comment4 := Comment{
	// 	Content: "张三文章2的评论2-李四",
	// }

	users := []User{
		{
			Email:     "zhangsan@163.com",
			Name:      "zhangsan",
			PostCount: 14,
			Posts: []Post{
				{
					Title:         "张三文章1标题",
					Content:       "张三文章1内容",
					CommentStatus: "有评论",
					Comments: []Comment{
						// comment1,
						// comment2,
						{
							Content: "张三文章1的评论1",
						},
						{
							Content: "张三文章1的评论2",
						},
						{
							Content: "张三文章1的评论3",
						},
					},
				},
				{
					Title:         "张三文章2标题",
					Content:       "张三文章2内容",
					CommentStatus: "有评论",
					Comments: []Comment{
						// comment3,
						// comment4,
						{
							Content: "张三文章2的评论1",
						},
						{
							Content: "张三文章2的评论2",
						},
					},
				},
			},
		},
		{
			Email:     "lisi@163.com",
			Name:      "lisi",
			PostCount: 7,
			Posts: []Post{
				{
					Title:         "李四文章1标题",
					Content:       "李四文章1内容",
					CommentStatus: "有评论",
					Comments: []Comment{
						{
							Content: "李四文章1的评论1",
						},
						{
							Content: "李四文章1的评论2",
						},
					},
				},
			},
		},
	}

	if err := db.Session(&gorm.Session{FullSaveAssociations: true}).Create(&users).Error; err != nil {
		t.Fatalf("create user: %v", err)
	}

}

func QueryUserPostsWithComments(t *testing.T, userID uint) ([]Post, error) {
	db := testutil.NewTestDB(t, "")

	var posts []Post
	err := db.Where("user_id = ?", userID).
		Preload("Comments").
		Order("created_at DESC").
		Find(&posts).Error
	if err != nil {
		return nil, fmt.Errorf("查询用户文章及评论失败: %w", err)
	}
	return posts, nil
}

func QueryMostCommentedPost(t *testing.T) (Post, int64, error) {
	db := testutil.NewTestDB(t, "")

	var post Post
	var commentCount int64

	// 方法：通过子查询/JOIN按评论数排序取第一条
	err := db.Model(&Post{}).
		Select("posts.*, COUNT(comments.id) as comment_count").
		Joins("LEFT JOIN comments ON comments.post_id = posts.id").
		Group("posts.id").
		Order("comment_count DESC").
		Limit(1).
		Scan(&post).Error

	if err != nil {
		return Post{}, 0, fmt.Errorf("查询最多评论文章失败: %w", err)
	}

	db.Model(&Comment{}).Where("post_id = ?", post.ID).Count(&commentCount)

	return post, commentCount, nil
}

// AfterCreate Post创建后自动更新用户的文章数量统计
func (p *Post) AfterCreate(tx *gorm.DB) error {
	result := tx.Model(&User{}).Where("id = ?", p.UserID).UpdateColumn("post_count", gorm.Expr("post_count + 1"))
	if result.Error != nil {
		return fmt.Errorf("更新用户文章计数失败: %w", result.Error)
	}
	log.Printf("[Hook] 用户 %d 的文章计数已+1", p.UserID)
	return nil
}

// AfterDelete Comment删除后检查并更新文章评论状态
func (c *Comment) AfterDelete(tx *gorm.DB) error {
	var count int64
	// 查询该文章剩余的评论数
	if err := tx.Model(&Comment{}).Where("post_id = ?", c.PostID).Count(&count).Error; err != nil {
		return fmt.Errorf("查询评论数量失败: %w", err)
	}

	// 如果评论数为0，更新文章状态为"无评论"
	if count == 0 {
		result := tx.Model(&Post{}).Where("id = ?", c.PostID).Update("comment_status", "无评论")
		if result.Error != nil {
			return fmt.Errorf("更新文章评论状态失败: %w", result.Error)
		}
		log.Printf("[Hook] 文章 %d 评论已清空，状态更新为'无评论'", c.PostID)
	}
	return nil
}
