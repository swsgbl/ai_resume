# MySQL 数据库迁移指南

本文档介绍如何将 AI Resume Platform 从 SQLite 迁移到 MySQL。

---

## 为什么迁移到 MySQL？

- **并发性能**: MySQL 支持更高的并发连接
- **数据完整性**: 更强的事务支持
- **生产就绪**: 适合生产环境部署
- **可扩展性**: 支持主从复制、分片等

---

## 快速开始

### 1. 启动 MySQL 数据库

```bash
# 使用 Docker Compose 启动 MySQL
docker-compose --profile production up -d db

# 检查 MySQL 状态
docker-compose ps db

# 查看 MySQL 日志
docker-compose logs db
```

### 2. 等待 MySQL 就绪

```bash
# 等待约 30 秒让 MySQL 完全启动

# 测试连接
docker exec -it ai-resume-db mysql -u airesume -pairesume_password ai_resume
```

### 3. 初始化数据库表结构

```bash
# 方法一：启动后端服务自动创建
cd backend
export USE_SQLITE=false
export DATABASE_URL="mysql+aiomysql://airesume:airesume_password@localhost:3306/ai_resume"
python -c "from app.core.database import init_db; import asyncio; asyncio.run(init_db())"

# 方法二：使用 Alembic（如果有迁移脚本）
# alembic upgrade head
```

### 4. 迁移现有数据

```bash
# 安装迁移依赖
cd backend
pip install aiosqlite aiomysql tqdm

# 设置 MySQL 连接环境变量
export MYSQL_HOST=localhost
export MYSQL_PORT=3306
export MYSQL_USER=airesume
export MYSQL_PASSWORD=airesume_password
export MYSQL_DATABASE=ai_resume

# 运行迁移脚本
python scripts/migrate_sqlite_to_mysql.py
```

### 5. 验证迁移结果

```bash
# 连接 MySQL 检查数据
docker exec -it ai-resume-db mysql -u airesume -pairesume_password ai_resume

# 在 MySQL 中执行
SHOW TABLES;
SELECT COUNT(*) FROM users;
SELECT COUNT(*) FROM resumes;
SELECT COUNT(*) FROM templates;
```

### 6. 切换到 MySQL

更新 `.env` 文件：

```bash
USE_SQLITE=false
DATABASE_URL=mysql+aiomysql://airesume:airesume_password@db:3306/ai_resume
```

重启后端服务：

```bash
docker-compose restart backend
```

---

## 详细步骤

### 准备工作

#### 1. 备份现有 SQLite 数据

```bash
cp backend/ai_resume.db backend/ai_resume.db.backup.$(date +%Y%m%d_%H%M%S)
```

#### 2. 检查 SQLite 数据

```bash
# 查看表结构
sqlite3 backend/ai_resume.db ".schema"

# 查看数据量
sqlite3 backend/ai_resume.db "SELECT 'users:' as table_name, COUNT(*) FROM users
UNION ALL SELECT 'resumes:', COUNT(*) FROM resumes
UNION ALL SELECT 'templates:', COUNT(*) FROM templates
UNION ALL SELECT 'resume_versions:', COUNT(*) FROM resume_versions
UNION ALL SELECT 'favorites:', COUNT(*) FROM favorites
UNION ALL SELECT 'operation_logs:', COUNT(*) FROM operation_logs;"
```

### MySQL 配置

#### MySQL 配置文件

配置文件位于 `mysql/conf.d/production.cnf`，包含：

- 字符集设置 (utf8mb4)
- 连接数限制 (200)
- InnoDB 缓冲池 (256M)
- 慢查询日志
- 二进制日志

#### 初始化脚本

初始化脚本位于 `mysql/init/01-init.sql`，自动执行：

- 创建数据库
- 创建用户
- 授权访问

### 迁移脚本说明

迁移脚本 `backend/scripts/migrate_sqlite_to_mysql.py` 功能：

1. 连接 SQLite 和 MySQL
2. 按依赖顺序导出数据
3. 批量插入到 MySQL
4. 重置自增 ID
5. 验证数据一致性

---

## 生产环境部署

### 使用 Docker Compose

```yaml
# docker-compose.prod.yml
services:
  backend:
    environment:
      - USE_SQLITE=false
      - DATABASE_URL=mysql+aiomysql://airesume:ai_resume_prod_password@db:3306/ai_resume
    depends_on:
      - db

  db:
    image: mysql:8.0
    environment:
      - MYSQL_ROOT_PASSWORD=secure_root_password
      - MYSQL_DATABASE=ai_resume
      - MYSQL_USER=airesume
      - MYSQL_PASSWORD=ai_resume_prod_password
    volumes:
      - mysql_data:/var/lib/mysql
      - ./mysql/conf.d:/etc/mysql/conf.d:ro
    restart: always
```

### 数据库优化

```sql
-- 创建索引优化查询
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_resumes_user_id ON resumes(user_id);
CREATE INDEX idx_resumes_status ON resumes(status);

-- 分析表
ANALYZE TABLE users, resumes, templates, resume_versions;
```

---

## 故障排查

### 问题 1: MySQL 连接失败

```
Error: Can't connect to MySQL server on 'localhost:3306'
```

**解决方案**:

```bash
# 检查 MySQL 是否运行
docker-compose ps db

# 检查 MySQL 日志
docker-compose logs db

# 确认端口未被占用
netstat -tuln | grep 3306
```

### 问题 2: 字符编码问题

```
Error: Incorrect string value
```

**解决方案**:

确保 MySQL 配置使用 `utf8mb4`:

```sql
ALTER DATABASE ai_resume CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
```

### 问题 3: JSON 字段导入失败

```
Error: JSON decode error
```

**解决方案**:

迁移脚本已自动处理 JSON 字段，如果仍有问题：

```sql
-- 检查并修复 JSON 字段
UPDATE resumes SET content = '{}' WHERE content IS NULL;
```

---

## 回滚到 SQLite

如果需要回滚：

```bash
# 1. 停止服务
docker-compose down

# 2. 恢复 SQLite 数据
cp backend/ai_resume.db.backup.YYYYMMDD_HHMMSS backend/ai_resume.db

# 3. 修改配置
# .env 文件中设置:
USE_SQLITE=true
DATABASE_URL=sqlite+aiosqlite:///./ai_resume.db

# 4. 重启服务
docker-compose up -d
```

---

## 性能对比

| 指标 | SQLite | MySQL |
|------|--------|-------|
| 并发连接 | 单连接 | 200+ |
| 读取性能 | 快 | 快 |
| 写入性能 | 中等 | 高 |
| 数据完整性 | 好 | 优秀 |
| 备份恢复 | 文件复制 | 工具支持 |
| 水平扩展 | 不支持 | 支持 |

---

## 安全建议

1. **修改默认密码**: 生产环境必须修改所有默认密码
2. **限制访问**: MySQL 不应暴露到公网
3. **定期备份**: 设置自动备份计划
4. **监控日志**: 监控慢查询和错误日志
5. **SSL 连接**: 生产环境使用 SSL 连接

---

## 维护操作

### 备份数据库

```bash
# 备份 MySQL 数据库
docker exec ai-resume-db mysqldump \
  -u airesume -pairesume_password \
  --single-transaction \
  --quick \
  --lock-tables=false \
  ai_resume > backup_$(date +%Y%m%d).sql

# 压缩备份
gzip backup_$(date +%Y%m%d).sql
```

### 恢复数据库

```bash
# 解压备份
gunzip backup_YYYYMMDD.sql.gz

# 恢复数据
docker exec -i ai-resume-db mysql \
  -u airesume -pairesume_password \
  ai_resume < backup_YYYYMMDD.sql
```

### 监控连接

```sql
-- 查看当前连接
SHOW PROCESSLIST;

-- 查看连接统计
SHOW STATUS LIKE 'Threads_connected';
SHOW STATUS LIKE 'Max_used_connections';
```

---

## 相关文档

- [PRODUCTION.md](PRODUCTION.md) - 生产环境部署
- [DEPLOYMENT.md](DEPLOYMENT.md) - 部署指南
- [MySQL 8.0 文档](https://dev.mysql.com/doc/refman/8.0/en/)
