# homework04

## 项目结构

```
homework04/
├── cmd/
│   ├── app.log          # 日志文件
│   └── main.go          # 程序入口
├── config/
│   ├── config.yaml      # 配置文件
│   └── config.go        # 配置文件读取
├── controllers/
│   ├── userController.go          # 用户控制器
│   ├── postController.go          # 文章控制器
│   └── commentController.go       # 评论控制器
├── middleware/
│   ├── auth.go          # JWT认证中间件
│   └── logger.go        # 日志中间件
├── models/
│   ├── user.go          # 用户模型
│   ├── post.go          # 文章模型
│   └── comment.go       # 评论模型
├── repository/
│   └── database.go      # 数据库连接初始化
├── roqres/
│   ├── req.go           # http请求信息实体
│   └── res.go           # http响应信息实体
├── routes/
│   └── routes.go        # 路由配置
├── services/
│   ├── userService.go          # 用户服务层
│   ├── postService.go          # 文章服务层
│   └── commentService.go       # 评论服务层
├── utils/
│   ├── bcrypt.go        # 加密工具
│   ├── jwt.go           # JWT工具
│   └── response.go      # 响应工具
├── go.mod
├── go.sum
└── README.md
```

## 数据库设计

### Users表
- id (主键)
- username (用户名，唯一)
- email (邮箱，唯一)
- password (加密密码)
- created_at, updated_at, deleted_at

### Posts表
- id (主键)
- title (标题)
- content (内容)
- user_id (外键，关联users表)
- created_at, updated_at, deleted_at

### Comments表
- id (主键)
- content (内容)
- user_id (外键，关联users表)
- post_id (外键，关联posts表)
- created_at, updated_at, deleted_at

## API接口

### 认证接口
- `POST /api/auth/register` - 用户注册
- `POST /api/auth/login` - 用户登录
- `GET /api/profile` - 获取用户信息 (需要认证)

### 文章接口
- `GET /api/posts` - 获取文章列表 (公开)
- `GET /api/posts/:id` - 获取文章详情 (公开)
- `POST /api/posts` - 创建文章 (需要认证)
- `PUT /api/posts/:id` - 更新文章 (需要认证，仅作者)
- `DELETE /api/posts/:id` - 删除文章 (需要认证，仅作者)

### 评论接口
- `GET /api/comments/:post_id` - 获取文章评论 (公开)
- `POST /api/comments/:post_id` - 创建评论 (需要认证)

### 其他接口
- `GET /migrate` - 数据库迁移

## 运行项目

1. Go 1.25.0
2. 克隆项目到本地
3. 安装依赖：
   ```bash
   go mod tidy
   ```
4. 运行项目：
   ```bash
   cd cmd
   go run main.go
   ```
5. 服务器将在 `http://localhost:8080` 启动