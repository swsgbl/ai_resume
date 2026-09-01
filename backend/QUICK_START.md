# AI 简历后端快速参考

## 一键启动

```bash
cd /media/hongfu/软件/ai_resume/backend
bash start_backend.sh
```

## 常用命令

```bash
# 启动服务
bash start_backend.sh

# 停止服务
bash stop_backend.sh

# 测试服务
bash test_backend.sh

# 手动测试健康检查
curl http://127.0.0.1:8000/health

# 访问 API 文档
# 浏览器打开: http://127.0.0.1:8000/docs
```

## 端口信息

- **服务端口**: 8000
- **健康检查**: http://127.0.0.1:8000/health
- **API 文档**: http://127.0.0.1:8000/docs
- **ReDoc 文档**: http://127.0.0.1:8000/redoc

## 环境变量

启动脚本会自动设置以下环境变量：

```bash
USE_SQLITE=true
DATABASE_URL=sqlite+aiosqlite:///./data/ai_resume.db
DEBUG=false
SECRET_KEY=JBDCZNkLElMPkWlTn9l1_CyvOmhiEt5e1PJVi84VldU
```

## 故障排查

### 端口被占用

```bash
# 查看占用进程
lsof -i:8000

# 停止服务
bash stop_backend.sh
```

### 清除缓存重启

```bash
# 停止服务
bash stop_backend.sh

# 清除 Python 缓存
find . -type d -name "__pycache__" -exec rm -rf {} + 2>/dev/null || true
find . -type f -name "*.pyc" -delete 2>/dev/null || true

# 重新启动
bash start_backend.sh
```

### 查看日志

```bash
# 实时查看应用日志
tail -f logs/*.log

# 查看最近的错误
grep -i error logs/*.log | tail -20
```

## 服务状态检查

```bash
# 检查进程
ps aux | grep uvicorn

# 检查端口
netstat -tuln | grep 8000

# 测试连接
curl -v http://127.0.0.1:8000/health
```

## 文件位置

- **数据库**: `data/ai_resume.db`
- **上传文件**: `uploads/`
- **日志文件**: `logs/`
- **配置文件**: `.env`

## 修改后的文件

1. `/media/hongfu/软件/ai_resume/backend/app/core/database.py` - 修复了数据库连接检查逻辑
2. 新增启动管理脚本：
   - `start_backend.sh` - 启动脚本
   - `stop_backend.sh` - 停止脚本
   - `test_backend.sh` - 测试脚本
   - `STARTUP_GUIDE.md` - 详细启动指南
   - `QUICK_START.md` - 快速参考（本文件）

## 问题已解决

✅ 环境变量冲突（DATABASE_URL 被全局 PostgreSQL 配置覆盖）
✅ SQLAlchemy 异步驱动兼容性问题
✅ 后端启动立即退出的问题
✅ 健康检查和 API 访问验证

## 技术支持

详细文档请参阅：`STARTUP_GUIDE.md`
