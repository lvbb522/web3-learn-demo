package config

import (
	"log"

	"github.com/spf13/viper"
)

type Config struct {
	Server   ServerConfig   `mapstructure:"server"`
	Database DatabaseConfig `mapstructure:"database"`
	JWT      JWTConfig      `mapstructure:"jwt"`
}

type ServerConfig struct {
	Port string `mapstructure:"port"`
	Host string `mapstructure:"host"`
	Mode string `mapstructure:"mode"`
}

type DatabaseConfig struct {
	Host     string `mapstructure:"host"`
	Port     string `mapstructure:"port"`
	Username string `mapstructure:"username"`
	Password string `mapstructure:"password"`
	DBName   string `mapstructure:"dbname"`
}

type JWTConfig struct {
	Secret string `mapstructure:"secret"`
}

// LoadConfig 加载并解析配置文件，将 Viper 中的配置数据映射到 Config 结构体
// 返回解析后的配置对象指针和可能的错误
// 配置数据来源包括：配置文件、环境变量和默认值
func LoadConfig() *Config {
	// 设置配置文件名称（不含扩展名）
	viper.SetConfigName("config")
	// 设置配置文件类型
	viper.SetConfigType("yaml")
	// 添加配置文件搜索路径
	viper.AddConfigPath("../config")

	// 读取配置文件
	if err := viper.ReadInConfig(); err != nil {
		log.Printf("Warning: Error reading config file: %v", err)
		log.Println("Using default values and environment variables")
	} else {
		log.Printf("Using config file: %s", viper.ConfigFileUsed())
	}

	var config Config

	// 使用 viper.Unmarshal 将配置数据解析到 config 结构体中
	// 如果解析失败，返回错误
	if err := viper.Unmarshal(&config); err != nil {
		log.Fatalf("Error loading config: %v", err)
	}

	// 返回解析成功的配置对象
	return &config
}
