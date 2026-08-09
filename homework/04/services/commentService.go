package services

import (
	"homework04/models"
	"homework04/reqres"
	"homework04/utils"
	"strconv"

	"github.com/gin-gonic/gin"
	"gorm.io/gorm"
)

type CommentService struct {
	db *gorm.DB
}

func NewCommentService(db *gorm.DB) *CommentService {
	return &CommentService{db: db}
}

func (cs *CommentService) CreateComment(c *gin.Context, postID uint64, req reqres.CreateCommentRequest) {
	userID, exists := c.Get("user_id")
	if !exists {
		utils.Unauthorized(c, "User not authenticated")
		return
	}

	// 检查文章是否存在
	var post models.Post
	if err := cs.db.First(&post, postID).Error; err != nil {
		utils.InternalServerError(c, "Post not found")
		return
	}

	comment := models.Comment{
		Content: req.Content,
		UserID:  userID.(uint),
		PostID:  uint(postID),
	}

	if err := cs.db.Create(&comment).Error; err != nil {
		utils.InternalServerError(c, "Failed to create comment")
		return
	}

	// 预加载用户信息
	cs.db.Preload("User").First(&comment, comment.ID)

	utils.Success(c, comment)
}

func (cs *CommentService) GetComments(c *gin.Context, postID uint64) {
	// 检查文章是否存在
	var post models.Post
	if err := cs.db.First(&post, postID).Error; err != nil {
		utils.InternalServerError(c, "Post not found")
		return
	}

	var comments []models.Comment

	// 分页参数
	page, _ := strconv.Atoi(c.DefaultQuery("page", "1"))
	pageSize, _ := strconv.Atoi(c.DefaultQuery("page_size", "20"))

	if page < 1 {
		page = 1
	}
	if pageSize < 1 || pageSize > 100 {
		pageSize = 20
	}

	offset := (page - 1) * pageSize

	// 查询评论列表，预加载用户信息
	if err := cs.db.Preload("User").
		Where("post_id = ?", postID).
		Order("created_at ASC").
		Limit(pageSize).
		Offset(offset).
		Find(&comments).Error; err != nil {
		utils.InternalServerError(c, "Failed to get comments")
		return
	}

	// 获取总数
	var total int64
	cs.db.Model(&models.Comment{}).Where("post_id = ?", postID).Count(&total)

	utils.Success(c, gin.H{
		"comments":  comments,
		"total":     total,
		"page":      page,
		"page_size": pageSize,
	})
}
