package models

import (
	"homework04/utils"
	"time"

	"golang.org/x/crypto/bcrypt"
	"gorm.io/gorm"
)

type User struct {
	ID        uint   `gorm:"primaryKey"`
	Username  string `gorm:"uniqueIndex;not null;type:varchar(100)"`
	Email     string `gorm:"uniqueIndex;not null;type:varchar(255)"`
	Password  string `gorm:"not null;type:varchar(255)"`
	CreatedAt time.Time
	UpdatedAt time.Time
	DeletedAt gorm.DeletedAt `gorm:"index"`
	Posts     []Post         `gorm:"foreignKey:UserID"`
	Comments  []Comment      `gorm:"foreignKey:UserID"`
}

// CheckPassword 验证密码
func (u *User) CheckPassword(password string) bool {
	err := bcrypt.CompareHashAndPassword([]byte(u.Password), []byte(password))
	return err == nil
}

// BeforeCreate GORM钩子，在创建用户前自动哈希密码
func (u *User) BeforeCreate(tx *gorm.DB) error {
	bcryptPwd, err := utils.GeneratePassword(u.Password)
	u.Password = bcryptPwd
	return err
}
