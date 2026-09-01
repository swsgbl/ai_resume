# AI Resume Platform - 运维手册

**版本**: v1.0
**更新时间**: 2026-04-06 08:10 UTC+8
**维护**: AI DevOps Agent (29126157-6833-4f1e-94bd-6493bd95d3f2)

---

## 📋 目录

1. [日常检查](#日常检查)
2. [服务管理](#服务管理)
3. [监控和告警](#监控和告警)
4. [备份和恢复](#备份和恢复)
5. [故障排查](#故障排查)
6. [应急处理](#应急处理)

---

## 🔍 日常检查

### 每日检查清单 (5分钟)

```bash
# 1. 快速状态检查
bash scripts/quick-monitor.sh

# 2. 查看服务健康状态
docker ps

# 3. 检查磁盘空间
df -h

# 4. 查看系统负载
uptime
```

### 每周检查清单 (15分钟)

```bash
# 1. 完整系统诊断
./ai-resume-deploy.sh diagnose

# 2. 性能报告
bash scripts/performance-monitor.sh report

# 3. 日志分析
bash scripts/log-analyzer.sh all

# 4. 备份验证
/backup/ai-resume/list.sh
```

---

## 🛠️ 服务管理

### 启动服务

```bash
# 启动所有服务
./ai-resume-deploy.sh start

# 或使用 Docker Compose
docker compose -f docker-compose.prod.yml up -d

# 验证启动
bash scripts/quick-monitor.sh
```

### 停止服务

```bash
# 停止所有服务
./ai-resume-deploy.sh stop

# 或
docker compose -f docker-compose.prod.yml down
```

### 重启服务

```bash
# 重启所有服务
./ai-resume-deploy.sh restart

# 重启单个服务
docker restart ai-resume-backend
docker restart ai-resume-frontend
docker restart ai-resume-redis
```

### 查看服务状态

```bash
# 快速状态
bash scripts/quick-monitor.sh

# 详细状态
./ai-resume-deploy.sh status

# 容器详情
docker ps -a
```

---

## 📊 监控和告警

### 实时监控

```bash
# 启动实时仪表板
~/ai-resume-monitoring/scripts/dashboard.sh

# 或使用 systemd 监控
systemctl status ai-resume-monitor
```

### 性能监控

```bash
# 实时性能监控
bash scripts/performance-monitor.sh monitor

# API性能测试
bash scripts/performance-monitor.sh test

# 资源趋势
bash scripts/performance-monitor.sh trends

# 性能告警检查
bash scripts/performance-monitor.sh alerts

# 生成性能报告
bash scripts/performance-monitor.sh report
```

### 日志监控

```bash
# 实时查看Backend日志
docker logs -f ai-resume-backend

# 实时查看Frontend日志
docker logs -f ai-resume-frontend

# 使用日志分析工具
bash scripts/log-analyzer.sh container backend
bash scripts/log-analyzer.sh monitor
```

---

## 💾 备份和恢复

### 手动备份

```bash
# 执行完整备份
bash scripts/backup-manager.sh backup

# 或使用自动化备份脚本
/backup/ai-resume/backup.sh
```

### 查看备份

```bash
# 列出所有备份
bash scripts/backup-manager.sh list

# 或
/backup/ai-resume/list.sh

# 查看备份详情
ls -lh /backup/ai-resume/
```

### 恢复备份

```bash
# 恢复指定备份
bash scripts/backup-manager.sh restore <backup-name>

# 或使用自动化恢复
/backup/ai-resume/restore.sh <backup-file.tar.gz>

# 恢复后重启服务
./ai-resume-deploy.sh restart
```

### 定时备份配置

```bash
# 设置定时备份
bash scripts/backup-manager.sh cron

# 查看定时任务
crontab -l | grep backup

# 备份时间: 每天凌晨 02:00
```

---

## 🔧 故障排查

### Backend 服务异常

#### 症状: Backend 无法访问
```bash
# 1. 检查容器状态
docker ps | grep backend

# 2. 查看Backend日志
docker logs ai-resume-backend --tail 100

# 3. 检查本地访问
curl http://localhost:8000/health

# 4. 检查外部访问
curl http://113.45.64.145:8000/health

# 5. 重启Backend
docker restart ai-resume-backend
```

#### 症状: API 响应慢
```bash
# 1. 测试API响应时间
time curl http://localhost:8000/health

# 2. 查看资源使用
docker stats ai-resume-backend

# 3. 检查Redis连接
docker logs ai-resume-backend | grep redis

# 4. 查看性能报告
bash scripts/performance-monitor.sh test
```

### Frontend 服务异常

#### 症状: Frontend 无法访问
```bash
# 1. 检查容器状态
docker ps | grep frontend

# 2. 查看Frontend日志
docker logs ai-resume-frontend --tail 100

# 3. 检查Nginx配置
docker exec ai-resume-frontend nginx -t

# 4. 重启Frontend
docker restart ai-resume-frontend
```

### 数据库连接问题

#### 症状: MySQL 连接失败
```bash
# 1. 检查MySQL容器
docker ps | grep mysql

# 2. 查看MySQL日志
docker logs ai-resume-mysql --tail 100

# 3. 检查端口占用
netstat -tlnp | grep 3306

# 4. 测试MySQL连接
docker compose exec mysql mysql -u root -p

# 5. 运行修复工具
bash scripts/mysql-container-fix.sh
```

### Redis 连接问题

#### 症状: Redis 连接失败
```bash
# 1. 检查Redis容器
docker ps | grep redis

# 2. 查看Redis日志
docker logs ai-resume-redis --tail 100

# 3. 测试Redis连接
docker exec ai-resume-redis redis-cli ping

# 4. 重启Redis
docker restart ai-resume-redis
```

---

## 🚨 应急处理

### 服务全部宕机

```bash
# 1. 检查系统状态
systemctl status docker

# 2. 检查磁盘空间
df -h

# 3. 检查内存使用
free -h

# 4. 重启Docker服务
systemctl restart docker

# 5. 启动所有服务
./ai-resume-deploy.sh start

# 6. 验证服务状态
bash scripts/quick-monitor.sh
```

### 磁盘空间不足

```bash
# 1. 检查磁盘使用
df -h

# 2. 清理Docker未使用的资源
docker system prune -a

# 3. 清理旧的备份文件
find /backup/ai-resume -name "*.tar.gz" -mtime +30 -delete

# 4. 清理日志文件
truncate -s 0 ~/ai-resume-monitoring/logs/*.log

# 5. 检查容器日志大小
docker ps -s
```

### 内存不足

```bash
# 1. 检查内存使用
free -h

# 2. 查看进程内存使用
ps aux --sort=-%mem | head -20

# 3. 查看Docker容器资源使用
docker stats

# 4. 重启占用内存过多的容器
docker restart <container-name>

# 5. 清理系统缓存
sync && echo 3 > /proc/sys/vm/drop_caches
```

### 数据损坏恢复

```bash
# 1. 停止所有服务
./ai-resume-deploy.sh stop

# 2. 查看可用备份
/backup/ai-resume/list.sh

# 3. 选择最近的备份恢复
/backup/ai-resume/restore.sh <backup-file.tar.gz>

# 4. 启动服务
./ai-resume-deploy.sh start

# 5. 验证数据完整性
./ai-resume-deploy.sh diagnose
```

---

## 📞 联系支持

### 获取帮助

```bash
# 查看快速参考
cat QUICK_REFERENCE.md

# 查看工具索引
cat DEVOPS_TOOLS_INDEX.md

# 查看执行计划
cat DEVOPS_EXECUTION_PLAN.md

# 运行完整诊断
./ai-resume-deploy.sh diagnose
```

### 常用命令速查

```bash
# 状态检查
bash scripts/quick-monitor.sh

# 服务管理
./ai-resume-deploy.sh {start|stop|restart|status}

# 日志查看
docker logs -f <container-name>

# 备份恢复
bash scripts/backup-manager.sh {backup|restore|list}

# 性能监控
bash scripts/performance-monitor.sh {monitor|test|report}

# 故障排查
./ai-resume-deploy.sh diagnose
```

---

## 📅 维护日历

### 每日任务
- [ ] 运行快速状态检查
- [ ] 查看监控告警
- [ ] 检查服务健康状态

### 每周任务
- [ ] 完整系统诊断
- [ ] 性能报告生成
- [ ] 日志分析
- [ ] 备份验证

### 每月任务
- [ ] 系统更新检查
- [ ] 安全漏洞扫描
- [ ] 备份测试恢复
- [ ] 容量规划评估

---

**维护者**: AI DevOps Agent (29126157-6833-4f1e-94bd-6493bd95d3f2)
**最后更新**: 2026-04-06 08:10 UTC+8
