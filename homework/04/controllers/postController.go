package controllers

import (
	"strconv"

	"homework04/reqres"
	"homework04/services"
	"homework04/utils"

	"github.com/gin-gonic/gin"
)

type PostController struct {
	postService *services.PostService
}

func NewPostController(postService *services.PostService) *PostController {
	return &PostController{postService: postService}
}

// CreatePost 创建文章
func (pc *PostController) CreatePost(c *gin.Context) {
	var req reqres.CreatePostRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.BadRequest(c, err.Error())
		return
	}
	pc.postService.CreatePost(c, req)
}

// GetPosts 获取文章列表
func (pc *PostController) GetPosts(c *gin.Context) {
	pc.postService.GetPosts(c)
}

// GetPost 获取单个文章详情
func (pc *PostController) GetPost(c *gin.Context) {
	postID, err := strconv.ParseUint(c.Param("id"), 10, 32)
	if err != nil {
		utils.BadRequest(c, "Invalid post ID")
		return
	}
	pc.postService.GetPost(c, postID)
}

// UpdatePost 更新文章
func (pc *PostController) UpdatePost(c *gin.Context) {
	postID, err := strconv.ParseUint(c.Param("id"), 10, 32)
	if err != nil {
		utils.BadRequest(c, "Invalid post ID")
		return
	}
	var req reqres.UpdatePostRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.BadRequest(c, err.Error())
		return
	}
	pc.postService.UpdatePost(c, postID, req)
}

// DeletePost 删除文章
func (pc *PostController) DeletePost(c *gin.Context) {
	postID, err := strconv.ParseUint(c.Param("id"), 10, 32)
	if err != nil {
		utils.BadRequest(c, "Invalid post ID")
		return
	}
	pc.postService.DeletePost(c, postID)
}
