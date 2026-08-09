package models

import (
	"time"

	"gorm.io/gorm"
)

type Comment struct {
	ID        uint   `gorm:"primaryKey"`
	Content   string `gorm:"type:text;not null"`
	UserID    uint   `gorm:"not null"`
	PostID    uint   `gorm:"not null"`
	CreatedAt time.Time
	UpdatedAt time.Time
	DeletedAt gorm.DeletedAt `gorm:"index"`

	// 关联关系
	User User `gorm:"foreignKey:UserID"`
	Post Post `gorm:"foreignKey:PostID"`
}
