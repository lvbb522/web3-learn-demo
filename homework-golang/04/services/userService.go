package services

import (
	"homework04/models"
	"homework04/reqres"
	"homework04/utils"

	"github.com/gin-gonic/gin"
	"gorm.io/gorm"
)

type UserService struct {
	db *gorm.DB
}

func NewUserService(db *gorm.DB) *UserService {
	return &UserService{db: db}
}

func (us *UserService) Register(c *gin.Context, req reqres.RegisterRequest) {
	// 检查用户名是否已存在
	var existingUser models.User
	if err := us.db.Where("username = ?", req.Username).First(&existingUser).Error; err == nil {
		utils.BadRequest(c, "Username already exists")
		return
	}

	// 检查邮箱是否已存在
	if err := us.db.Where("email = ?", req.Email).First(&existingUser).Error; err == nil {
		utils.BadRequest(c, "Email already exists")
		return
	}

	// 创建新用户
	user := models.User{
		Username: req.Username,
		Email:    req.Email,
		Password: req.Password, // 密码会在BeforeCreate钩子中自动加密
	}

	if err := us.db.Create(&user).Error; err != nil {
		utils.InternalServerError(c, "Failed to create user")
		return
	}

	// 生成JWT token
	token, err := utils.GenerateToken(user.ID, user.Username)
	if err != nil {
		utils.InternalServerError(c, "Failed to generate token")
		return
	}

	utils.Success(c, reqres.AuthResponse{
		Token: token,
		User:  user,
	})
}

func (us *UserService) Login(c *gin.Context, req reqres.LoginRequest) {
	// 查找用户
	var user models.User
	if err := us.db.Where("username = ?", req.Username).First(&user).Error; err != nil {
		utils.Unauthorized(c, "Invalid username or password")
		return
	}

	// 验证密码
	if !user.CheckPassword(req.Password) {
		utils.Unauthorized(c, "Invalid username or password")
		return
	}

	// 生成JWT token
	token, err := utils.GenerateToken(user.ID, user.Username)
	if err != nil {
		utils.InternalServerError(c, "Failed to generate token")
		return
	}
	user.Password = ""
	utils.Success(c, reqres.AuthResponse{
		Token: token,
		User:  user,
	})
}

func (us *UserService) GetProfile(c *gin.Context, userID uint) {
	var user models.User
	if err := us.db.First(&user, userID).Error; err != nil {
		utils.NotFound(c, "User not found")
		return
	}
	user.Password = ""
	utils.Success(c, user)
}
