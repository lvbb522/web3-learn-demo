package services

import (
	"homework04/models"
	"homework04/reqres"
	"homework04/utils"
	"strconv"

	"github.com/gin-gonic/gin"
	"gorm.io/gorm"
)

type PostService struct {
	db *gorm.DB
}

func NewPostService(db *gorm.DB) *PostService {
	return &PostService{db: db}
}

func (ps *PostService) CreatePost(c *gin.Context, req reqres.CreatePostRequest) {
	userID, exists := c.Get("user_id")
	if !exists {
		utils.Unauthorized(c, "User not authenticated")
		return
	}

	post := models.Post{
		Title:   req.Title,
		Content: req.Content,
		UserID:  userID.(uint),
	}

	if err := ps.db.Create(&post).Error; err != nil {
		utils.InternalServerError(c, "Failed to create post")
		return
	}

	// 预加载用户信息
	ps.db.Preload("User").First(&post, post.ID)

	utils.Success(c, post)
}

func (ps *PostService) GetPosts(c *gin.Context) {
	var posts []models.Post

	// 分页参数
	page, _ := strconv.Atoi(c.DefaultQuery("page", "1"))
	pageSize, _ := strconv.Atoi(c.DefaultQuery("page_size", "10"))

	if page < 1 {
		page = 1
	}
	if pageSize < 1 || pageSize > 100 {
		pageSize = 10
	}

	offset := (page - 1) * pageSize

	// 查询文章列表，预加载用户信息
	if err := ps.db.Preload("User").
		Order("created_at DESC").
		Limit(pageSize).
		Offset(offset).
		Find(&posts).Error; err != nil {
		utils.InternalServerError(c, "Failed to get posts")
		return
	}

	// 获取总数
	var total int64
	ps.db.Model(&models.Post{}).Count(&total)

	utils.Success(c, gin.H{
		"posts":     posts,
		"total":     total,
		"page":      page,
		"page_size": pageSize,
	})
}

func (ps *PostService) GetPost(c *gin.Context, postID uint64) {
	var post models.Post
	if err := ps.db.Preload("User").Preload("Comments.User").First(&post, postID).Error; err != nil {
		utils.NotFound(c, "Post not found")
		return
	}

	utils.Success(c, post)
}

func (ps *PostService) UpdatePost(c *gin.Context, postID uint64, req reqres.UpdatePostRequest) {
	userID, exists := c.Get("user_id")
	if !exists {
		utils.Unauthorized(c, "User not authenticated")
		return
	}

	var post models.Post
	if err := ps.db.First(&post, postID).Error; err != nil {
		utils.NotFound(c, "Post not found")
		return
	}

	// 检查是否是文章作者
	if post.UserID != userID.(uint) {
		utils.Forbidden(c, "You can only update your own posts")
		return
	}

	// 更新文章
	post.Title = req.Title
	post.Content = req.Content

	if err := ps.db.Save(&post).Error; err != nil {
		utils.InternalServerError(c, "Failed to update post")
		return
	}

	// 预加载用户信息
	ps.db.Preload("User").First(&post, post.ID)

	utils.Success(c, post)
}

func (ps *PostService) DeletePost(c *gin.Context, postID uint64) {
	userID, exists := c.Get("user_id")
	if !exists {
		utils.Unauthorized(c, "User not authenticated")
		return
	}

	var post models.Post
	if err := ps.db.First(&post, postID).Error; err != nil {
		utils.NotFound(c, "Post not found")
		return
	}

	// 检查是否是文章作者
	if post.UserID != userID.(uint) {
		utils.Forbidden(c, "You can only delete your own posts")
		return
	}

	// 删除文章（软删除）
	if err := ps.db.Delete(&post).Error; err != nil {
		utils.InternalServerError(c, "Failed to delete post")
		return
	}

	utils.Success(c, gin.H{"message": "Post deleted successfully"})
}
