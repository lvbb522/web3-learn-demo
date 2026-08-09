package middleware

import (
	"io"
	"os"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/sirupsen/logrus"
)

// LoggerMiddleware 日志记录中间件
func LoggerMiddleware() gin.HandlerFunc {
	// 创建logrus实例
	logger := logrus.New()
	logger.SetFormatter(&logrus.JSONFormatter{})

	// 打开日志文件（追加模式）
	file, err := os.OpenFile("../app.log", os.O_CREATE|os.O_WRONLY|os.O_APPEND, 0644)
	if err != nil {
		// 文件打开失败时降级为仅控制台输出，避免中间件初始化崩溃
		logrus.Errorf("无法打开日志文件: %v, 将仅输出到控制台", err)
	} else {
		// 关键：使用 MultiWriter 同时写入控制台和文件
		multiWriter := io.MultiWriter(os.Stdout, file)
		logger.SetOutput(multiWriter)
	}

	return gin.LoggerWithFormatter(func(param gin.LogFormatterParams) string {
		// 记录请求日志
		logger.WithFields(logrus.Fields{
			"status_code": param.StatusCode,
			"latency":     param.Latency,
			"client_ip":   param.ClientIP,
			"method":      param.Method,
			"path":        param.Path,
			"user_agent":  param.Request.UserAgent(),
			"error":       param.ErrorMessage,
			"timestamp":   param.TimeStamp.Format(time.RFC3339),
		}).Info("HTTP Request")

		return ""
	})
}

// ErrorHandlerMiddleware 全局错误处理中间件
func ErrorHandlerMiddleware() gin.HandlerFunc {
	return func(c *gin.Context) {
		defer func() {
			if err := recover(); err != nil {
				logrus.WithFields(logrus.Fields{
					"error":  err,
					"path":   c.Request.URL.Path,
					"method": c.Request.Method,
				}).Error("Panic recovered")

				c.JSON(500, gin.H{
					"code":    500,
					"message": "Internal server error",
				})
				c.Abort()
			}
		}()
		c.Next()
	}
}
