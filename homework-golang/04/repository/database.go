package repository

import (
	"fmt"
	"homework04/config"
	"homework04/models"
	"log"

	"gorm.io/driver/mysql"
	"gorm.io/gorm"
	"gorm.io/gorm/logger"
)

func InitDatabase(config *config.Config) *gorm.DB {
	// 获取MySQL连接配置
	dbHost := config.Database.Host
	dbPort := config.Database.Port
	dbUser := config.Database.Username
	dbPassword := config.Database.Password
	dbName := config.Database.DBName

	// 构建MySQL连接字符串
	dsn := fmt.Sprintf("%s:%s@tcp(%s:%s)/%s?charset=utf8mb4&parseTime=True&loc=Local",
		dbUser, dbPassword, dbHost, dbPort, dbName)

	// 连接MySQL数据库
	db, err := gorm.Open(mysql.Open(dsn), &gorm.Config{
		Logger: logger.Default.LogMode(logger.Info),
	})

	if err != nil {
		log.Fatal("Failed to connect to MySQL database:", err)
	}

	log.Println("MySQL database connected and migrated successfully")
	return db

}

func Migrate(db *gorm.DB) (err error) {
	if err := db.AutoMigrate(&models.User{}, &models.Post{}, &models.Comment{}); err != nil {
		log.Fatalf("Failed to migrate database: %v", err)
		return err
	}
	return nil
}
