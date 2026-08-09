package reqres

import "homework04/models"

type AuthResponse struct {
	Token string      `json:"token"`
	User  models.User `json:"user"`
}
