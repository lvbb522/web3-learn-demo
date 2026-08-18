package controllers

import (
	"homework04/reqres"
	"homework04/services"
	"homework04/utils"

	"github.com/gin-gonic/gin"
)

type UserController struct {
	userService *services.UserService
}

func NewUserController(userService *services.UserService) *UserController {
	return &UserController{userService: userService}
}

// Register 用户注册
func (uc *UserController) Register(c *gin.Context) {
	var req reqres.RegisterRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.BadRequest(c, err.Error())
		return
	}
	uc.userService.Register(c, req)
}

// Login 用户登录
func (uc *UserController) Login(c *gin.Context) {
	var req reqres.LoginRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.BadRequest(c, err.Error())
		return
	}
	uc.userService.Login(c, req)
}

func (uc *UserController) GetProfile(c *gin.Context) {
	userID, exists := c.Get("user_id")
	if !exists {
		utils.Unauthorized(c, "User not authenticated")
		return
	}
	uc.userService.GetProfile(c, userID.(uint))
}
