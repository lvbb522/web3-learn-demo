package routes

import (
	"homework04/controllers"
	"homework04/middleware"
	"homework04/models"
	"homework04/repository"
	"homework04/services"
	"homework04/utils"
	"log"
	"net/http"

	"github.com/gin-gonic/gin"
	"gorm.io/gorm"
)

// SetupRoutes 设置路由
func SetupRoutes(db *gorm.DB) *gin.Engine {
	r := gin.New()

	// 使用中间件
	r.Use(middleware.LoggerMiddleware())
	r.Use(middleware.ErrorHandlerMiddleware())
	r.Use(gin.Recovery())

	// 创建控制器实例
	userService := services.NewUserService(db)
	postService := services.NewPostService(db)
	commentService := services.NewCommentService(db)
	userController := controllers.NewUserController(userService)
	postController := controllers.NewPostController(postService)
	commentController := controllers.NewCommentController(commentService)

	api := r.Group("/api")
	{
		// 认证相关路由（无需认证）
		auth := api.Group("/auth")
		{
			auth.POST("/register", userController.Register)
			auth.POST("/login", userController.Login)
		}

		// 需要认证的路由
		authenticated := api.Group("")
		authenticated.Use(middleware.AuthMiddleware())
		{
			// 用户信息
			authenticated.GET("/user/profile", userController.GetProfile)

			// 文章相关路由
			posts := authenticated.Group("/posts")
			{
				posts.POST("", postController.CreatePost)
				posts.PUT("/:id", postController.UpdatePost)
				posts.DELETE("/:id", postController.DeletePost)
			}

			// 评论相关路由
			comments := authenticated.Group("/comments/:post_id")
			{
				comments.POST("", commentController.CreateComment)
			}
		}

		// 公开路由（无需认证）
		public := api.Group("")
		{
			// 文章公开路由
			publicPosts := public.Group("/posts")
			{
				publicPosts.GET("", postController.GetPosts)
				publicPosts.GET("/:id", postController.GetPost)
			}

			// 评论公开路由（单独分组避免路由冲突）
			publicComments := public.Group("/comments")
			{
				publicComments.GET("/:post_id", commentController.GetComments)
			}

		}

	}

	r.GET("/bcryptPwd/:pwd", func(c *gin.Context) {
		pwd := c.Param("pwd")
		bcryptPwd, err := utils.GeneratePassword(pwd)
		if err != nil {
			log.Fatalf("获取加密密码失败: %v", err)
		}
		c.JSON(http.StatusOK, gin.H{
			"bcryptPwd": bcryptPwd,
		})
	})

	// 初始化数据库表结构
	r.GET("/migrate", func(c *gin.Context) {
		repository.Migrate(db)

		users := []models.User{
			{
				Username: "zhangyi",
				Email:    "zhangyi@163.com",
				Password: "123456",
				Posts: []models.Post{
					{
						Title:   "张翼的文章1标题",
						Content: "张翼的文章1内容",
					},
					{
						Title:   "张翼的文章2标题",
						Content: "张翼的文章2内容",
					},
				},
			},
			{
				Username: "lier",
				Email:    "lier@163.com",
				Password: "123456",
			},
			{
				Username: "zhangsan",
				Email:    "zhangsan@163.com",
				Password: "123456",
			},
			{
				Username: "lisi",
				Email:    "lisi@163.com",
				Password: "123456",
			},
		}

		if err := db.Session(&gorm.Session{FullSaveAssociations: true}).Create(&users).Error; err != nil {
			log.Fatalf("create users: %v", err)
		}

		c.JSON(http.StatusOK, gin.H{
			"status": "ok",
		})
	})

	return r
}
