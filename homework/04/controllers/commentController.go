package controllers

import (
	"homework04/reqres"
	"homework04/services"
	"homework04/utils"
	"strconv"

	"github.com/gin-gonic/gin"
)

type CommentController struct {
	commentService *services.CommentService
}

func NewCommentController(commentService *services.CommentService) *CommentController {
	return &CommentController{commentService: commentService}
}

// CreateComment 创建评论
func (cs *CommentController) CreateComment(c *gin.Context) {
	postID, err := strconv.ParseUint(c.Param("post_id"), 10, 32)
	if err != nil {
		utils.BadRequest(c, "Invalid post ID")
		return
	}

	var req reqres.CreateCommentRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.BadRequest(c, err.Error())
		return
	}

	cs.commentService.CreateComment(c, postID, req)
}

// GetComments 获取文章的评论列表
func (cs *CommentController) GetComments(c *gin.Context) {
	postID, err := strconv.ParseUint(c.Param("post_id"), 10, 32)
	if err != nil {
		utils.BadRequest(c, "Invalid post ID")
		return
	}
	cs.commentService.GetComments(c, postID)
}
