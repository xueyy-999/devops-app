# 云原生DevOps平台 - 示例应用

这是一个完整的三层Web应用，用于演示云原生DevOps平台的CI/CD流程。

## 🏗️ 架构

```
┌─────────────┐
│   Frontend  │  (Nginx + HTML/CSS/JS)
│   Port 8888 │
└──────┬──────┘
       │
┌──────▼──────┐
│   Backend   │  (Flask REST API)
│   Port 5001 │
└──────┬──────┘
       │
   ┌───┴────┐
   │        │
┌──▼──┐  ┌─▼────┐
│ PG  │  │Redis │
└─────┘  └──────┘
```

## 🚀 快速启动

### 本地开发环境

```bash
# 构建并启动所有服务
docker-compose up -d

# 查看日志
docker-compose logs -f

# 停止服务
docker-compose down
```

### 访问应用

- **前端**: http://localhost:8888
- **后端API**: http://localhost:5001
- **健康检查**: http://localhost:5001/health
- **API文档**: http://localhost:5001/api/messages

## 📋 功能特性

### 前端
- 响应式设计
- 实时状态监控
- 留言板功能
- 自动刷新

### 后端
- RESTful API
- PostgreSQL数据持久化
- Redis缓存
- 健康检查端点
- CORS支持

### 数据库
- PostgreSQL 13
- 自动初始化表结构
- 数据持久化

### 缓存
- Redis 7
- 访问计数
- 会话管理

## 🔧 API端点

### GET /
获取API信息

### GET /health
健康检查

### GET /api/messages
获取所有留言

### POST /api/messages
创建新留言

**请求体**:
```json
{
  "author": "张三",
  "content": "这是一条测试留言"
}
```

### GET /api/stats
获取统计信息

## 🧪 测试

```bash
# 测试后端健康检查
curl http://localhost:5001/health

# 获取留言列表
curl http://localhost:5001/api/messages

# 创建新留言
curl -X POST http://localhost:5001/api/messages \
  -H "Content-Type: application/json" \
  -d '{"author":"测试用户","content":"Hello DevOps!"}'

# 获取统计信息
curl http://localhost:5001/api/stats
```

## 📦 构建镜像

```bash
# 构建后端镜像
cd backend
docker build -t demo-backend:latest .

# 构建前端镜像
cd frontend
docker build -t demo-frontend:latest .
```

## 🔄 CI/CD集成

这个应用设计用于与GitLab CI/Jenkins集成：

1. 代码提交到GitLab
2. 触发CI/CD流水线
3. 自动构建Docker镜像
4. 推送到Registry
5. 部署到Kubernetes

详见 `.gitlab-ci.yml` 和 `Jenkinsfile`

## 🐛 故障排查

### 后端无法连接数据库
```bash
# 检查PostgreSQL状态
docker-compose ps demo-postgres

# 查看数据库日志
docker-compose logs demo-postgres
```

### 前端无法访问后端
检查 `frontend/app.js` 中的 `API_URL` 配置

### Redis连接失败
```bash
# 检查Redis状态
docker-compose ps demo-redis

# 测试Redis连接
docker-compose exec demo-redis redis-cli ping
```

## 📝 环境变量

### 后端
- `DB_HOST`: 数据库主机 (默认: demo-postgres)
- `DB_PORT`: 数据库端口 (默认: 5432)
- `DB_NAME`: 数据库名称 (默认: demo_app)
- `DB_USER`: 数据库用户 (默认: demo)
- `DB_PASSWORD`: 数据库密码 (默认: demo123)
- `REDIS_HOST`: Redis主机 (默认: demo-redis)
- `REDIS_PORT`: Redis端口 (默认: 6379)
- `PORT`: 应用端口 (默认: 5000)

## 🎓 用于毕业设计演示

这个应用完美展示了：
- ✅ 微服务架构
- ✅ 容器化部署
- ✅ 前后端分离
- ✅ 数据持久化
- ✅ 缓存机制
- ✅ 健康检查
- ✅ CI/CD就绪

## 📄 许可证

MIT License

