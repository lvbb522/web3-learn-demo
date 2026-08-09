package models

import (
	"time"

	"gorm.io/gorm"
)

type Post struct {
	ID        uint   `gorm:"primaryKey"`
	Title     string `gorm:"not null;varchar(100)"`
	Content   string `gorm:"type:text;not null"`
	UserID    uint   `gorm:"not null"`
	CreatedAt time.Time
	UpdatedAt time.Time
	DeletedAt gorm.DeletedAt `gorm:"index"`

	// 关联关系
	User     User      `gorm:"foreignKey:UserID"`
	Comments []Comment `gorm:"foreignKey:PostID"`
}
