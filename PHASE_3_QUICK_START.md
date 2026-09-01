# Phase 3 快速启动指南

**DevOps工程师**: Agent 29126157-6833-4f1e-94bd-6493bd95d3f2
**目标**: 防火墙配置完成后快速完成 Phase 3 部署
**预计时间**: 30分钟

---

## 🚀 防火墙配置完成后立即执行

### 第1步: 验证防火墙配置 (2分钟)

```bash
# 快速验证Backend外部访问
curl http://113.45.64.145:8000/health

# 预期响应:
# {"status":"healthy","app":"AI简历智能生成平台","version":"1.0.0"}

# 如果成功，继续第2步
# 如果失败，参考 FIREWALL_EXECUTION_CHECKLIST.md 故障排查
```

### 第2步: 运行完整验证 (3分钟)

```bash
# 运行防火墙后验证脚本
bash /home/hongfu/ai-resume/scripts/post-firewall-verification.sh

# 检查验证结果
# 如果通过率 > 90%，继续第3步
# 如果有问题，查看详细报告修复
```

### 第3步: 修复 MySQL 容器 (10分钟)

```bash
# 运行MySQL容器修复脚本
bash /home/hongfu/ai-resume/scripts/mysql-container-fix.sh

# 验证MySQL容器状态
docker ps | grep mysql

# 检查MySQL连接
docker exec ai-resume-backend python -c "
import pymysql
conn = pymysql.connect(host='ai-resume-mysql', user='root', password='your_password')
print('MySQL连接成功')
conn.close()
" 2>/dev/null || echo "MySQL待配置"
```

### 第4步: 部署监控系统 (15分钟)

```bash
# 1. 安装监控组件
bash /home/hongfu/ai-resume/scripts/deploy-monitoring-system.sh

# 2. 启动监控服务
sudo systemctl start ai-resume-monitor
sudo systemctl enable ai-resume-monitor

# 3. 验证监控状态
systemctl status ai-resume-monitor

# 4. 查看监控数据
curl http://localhost:9090/metrics  # Prometheus metrics
```

### 第5步: 配置自动备份 (5分钟)

```bash
# 1. 配置备份自动化
bash /home/hongfu/ai-resume/scripts/setup-backup-automation.sh

# 2. 验证备份配置
crontab -l | grep ai-resume

# 3. 测试备份功能
sudo systemctl start ai-resume-backup
```

### 第6步: 完整系统验证 (5分钟)

```bash
# 运行详细健康检查
bash /home/hongfu/ai-resume/scripts/health-detailed-check.sh

# 生成最终报告
./ai-resume-deploy.sh status > /tmp/final-status.txt
cat /tmp/final-status.txt
```

---

## ✅ 完成标准

### 所有服务健康
- [ ] Backend外部访问正常 (8000端口)
- [ ] Frontend外部访问正常 (3000端口)
- [ ] Redis运行正常 (6379端口)
- [ ] MySQL运行正常 (3306端口)

### 监控系统运行
- [ ] Prometheus监控运行中
- [ ] 健康检查脚本定时执行
- [ ] 告警系统配置完成

### 备份系统就绪
- [ ] 自动备份任务配置
- [ ] 备份存储位置确认
- [ ] 恢复流程测试通过

### 文档更新完成
- [ ] 部署文档更新
- [ ] 运维手册更新
- [ ] 故障排查指南完整

---

## 📊 执行进度跟踪

```
Phase 3 执行进度:

□ 第1步: 防火墙验证 (2分钟)
□ 第2步: 完整验证 (3分钟)
□ 第3步: MySQL修复 (10分钟)
□ 第4步: 监控部署 (15分钟)
□ 第5步: 备份配置 (5分钟)
□ 第6步: 最终验证 (5分钟)

总预计时间: 40分钟 (含缓冲时间)
```

---

## 🎯 快速命令参考

### 验证命令
```bash
# Backend健康检查
curl http://113.45.64.145:8000/health

# Frontend访问测试
curl -I http://113.45.64.145:3000

# 容器状态检查
docker ps --filter "name=ai-resume"

# 资源使用监控
docker stats --no-stream ai-resume-backend ai-resume-frontend ai-resume-redis
```

### 故障排查
```bash
# 查看Backend日志
docker logs ai-resume-backend --tail 50 -f

# 查看Frontend日志
docker logs ai-resume-frontend --tail 50 -f

# 系统诊断
./ai-resume-deploy.sh diagnose

# 网络诊断
bash /home/hongfu/ai-resume/scripts/network-diagnosis.sh
```

### 紧急恢复
```bash
# 重启所有服务
docker compose -f docker-compose.prod.yml restart

# 强制重建Backend
docker compose -f docker-compose.prod.yml up -d --force-recreate backend

# 回滚到上一个版本
./ai-resume-deploy.sh rollback
```

---

## 📞 遇到问题?

### 常见问题快速解决

**问题**: Backend外部访问失败
```bash
# 检查防火墙规则
sudo iptables -L -n | grep 8000

# 检查云安全组
# 登录云控制台确认8000端口已开放
```

**问题**: MySQL容器启动失败
```bash
# 查看MySQL日志
docker logs ai-resume-mysql

# 检查端口占用
sudo netstat -tlnp | grep 3306

# 运行修复脚本
bash /home/hongfu/ai-resume/scripts/mysql-container-fix.sh
```

**问题**: 监控系统异常
```bash
# 检查监控服务状态
systemctl status ai-resume-monitor

# 查看监控日志
sudo journalctl -u ai-resume-monitor -f

# 重启监控服务
sudo systemctl restart ai-resume-monitor
```

---

## 🎉 完成后

### 更新项目状态
```bash
# 更新文档
echo "Phase 3 完成: $(date)" >> /home/hongfu/ai-resume/PHASE_3_COMPLETION.log

# 生成最终报告
bash /home/hongfu/ai-resume/scripts/generate-final-report.sh

# 通知团队
echo "AI Resume Platform Phase 3 部署完成" | \
  mail -s "部署完成通知" team@example.com
```

### 归档部署记录
```bash
# 保存部署日志
cp /tmp/final-status.txt ~/ai-resume-deploy-$(date +%Y%m%d).log

# 更新项目文档
git add docs/
git commit -m "docs: 更新Phase 3部署完成文档"
```

---

**准备状态**: ✅ 所有脚本就绪
**等待条件**: ⏸️ 防火墙配置完成
**预计完成时间**: 防火墙配置后 40分钟内

**DevOps工程师**: Agent 29126157-6833-4f1e-94bd-6493bd95d3f2

*防火墙配置完成后，按照本指南快速完成Phase 3部署*
