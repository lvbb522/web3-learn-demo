package main

import (
	"fmt"
	"homework04/config"
	"homework04/repository"
	"homework04/routes"
	"log"

	"github.com/gin-gonic/gin"
)

func init() {}

func main() {
	// 加载配置信息
	config := config.LoadConfig()
	// 设置 Gin 模式
	gin.SetMode(config.Server.Mode)
	// 获取数据库db
	db := repository.InitDatabase(config)
	// 设置路由
	r := routes.SetupRoutes(db)

	// 启动服务器
	addr := fmt.Sprintf("%s:%s", config.Server.Host, config.Server.Port)
	log.Printf("Server starting on %s", addr)
	r.Run(addr)
}
