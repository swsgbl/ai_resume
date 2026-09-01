# AI 简历项目测试和优化解决方案

## 问题总结

### 1. 环境启动问题

#### 后端问题
- **Python 环境**: 项目使用 Python 3.14，与系统 Python 版本兼容
- **依赖问题**: 缺少 `slowapi`、`redis`、`email-validator` 等依赖
- **解决方案**: 安装完整的依赖包

#### 前端问题
- **esbuild 权限问题**: NTFS 文件系统不支持执行权限
- **解决方案**: 将项目复制到 Linux 文件系统（/tmp）或使用 Docker

### 2. 文件系统问题
- **NTFS 限制**: 项目位于 NTFS 挂载点 `/media/hongfu/软件`，不支持 Unix 执行权限
- **影响**: node_modules 中的二进制文件无法执行
- **解决方案**: 在 Linux 文件系统中工作

## 解决方案

### 快速启动方案

使用提供的启动脚本：
```bash
cd /media/hongfu/软件/ai_resume
bash START_AND_TEST.sh
```

#### 手动启动方式

**后端启动：**
```bash
cd /media/hongfu/软件/ai_resume/backend
python -m uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload
```

**前端启动：**
```bash
cd /media/hongfu/软件/ai_resume/ai-resume-web
npm run dev
```

### 依赖安装

#### 后端依赖安装
```bash
cd /media/hongfu/软件/ai_resume/backend
pip install fastapi uvicorn sqlalchemy aiosqlite slowapi redis \
            python-jose passlib bcrypt pydantic pydantic-settings \
            python-multipart python-dotenv loguru email-validator
```

#### 前端依赖安装
```bash
cd /media/hongfu/软件/ai_resume/ai-resume-web
npm install
```

## 测试方案

### 1. 基础连接测试
```bash
# 测试前端
curl http://localhost:3000

# 测试后端
curl http://localhost:8000/docs
```

### 2. 自动循环测试
```bash
# 使用启动脚本选择选项 5
bash START_AND_TEST.sh
```

### 3. E2E 测试
```bash
cd /media/hongfu/软件/ai_resume/ai-resume-web
npm run test
```

## 监控和日志

### 服务状态监控
```bash
# 检查端口占用
lsof -i :8000  # 后端
lsof -i :3000  # 前端

# 检查进程
ps aux | grep uvicorn  # 后端
ps aux | grep vite     # 前端
```

### 日志位置
- 后端日志：控制台输出
- 前端日志：控制台输出
- 测试报告：`/media/hongfu/软件/ai_resume/test-report-*.md`

## 常见问题解决

### 1. 端口被占用
```bash
# 查找占用进程
lsof -i :8000
# 停止进程
kill -9 <PID>
```

### 2. 依赖缺失
```bash
# 后端
pip install <missing-package>

# 前端
npm install <missing-package>
```

### 3. 权限问题
```bash
# 如果遇到权限问题，尝试在 /tmp 中工作
cp -r /media/hongfu/软件/ai_resume /tmp/ai-resume-work
cd /tmp/ai-resume-work/ai-resume-web
npm install
```

## 性能优化建议

### 1. 使用 Docker
避免 NTFS 权限问题，推荐使用 Docker：
```bash
docker-compose up
```

### 2. 数据库优化
- 默认使用 SQLite（开发环境）
- 生产环境建议使用 MySQL/PostgreSQL

### 3. 缓存优化
- Redis 配置需要根据实际环境调整
- 可以禁用 Redis（如果不需要）

## 自动化脚本说明

### START_AND_TEST.sh
主启动脚本，提供：
1. 单独启动后端
2. 单独启动前端
3. 同时启动所有服务
4. 运行测试
5. 设置自动循环测试

### simple-test.sh
快速测试脚本：
- 检查服务状态
- 生成测试报告
- 验证基本功能

## 长期解决方案

### 1. 迁移到 Linux 文件系统
将项目移动到非 NTFS 文件系统，避免权限问题：
```bash
cp -r /media/hongfu/软件/ai_resume ~/ai-resume
cd ~/ai-resume
```

### 2. 使用 WSL2（如果在 Windows 上）
- WSL2 提供完整的 Linux 文件系统支持
- 性能和兼容性更好

### 3. Docker 容器化
- 完全隔离环境
- 避免权限和依赖问题
- 便于部署和扩展

## 总结

当前项目存在的主要问题是 NTFS 文件系统限制，通过以下方式解决：

1. **立即解决**: 使用提供的启动脚本
2. **短期解决**: 在 /tmp 中工作
3. **长期解决**: 迁移到 Linux 文件系统或使用 Docker

所有脚本和配置文件已创建并测试，可以直接使用。