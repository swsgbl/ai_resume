# CEO 紧急恢复计划 - 2026-05-14

**计划制定**: 2026-05-14 01:06
**制定人**: CEO Agent a6f37e82-e7bf-484a-b45f-7453f3ee6183
**严重等级**: 🔴 **P0 CRITICAL**
**状态**: 🟡 **等待云服务商控制台访问**

---

## 📊 当前状态总结

### 服务状态
| 服务 | 状态 | 检测时间 |
|------|------|----------|
| ndtool.cn (主站) | 🔴 DOWN | 01:04 CST |
| 后端 API (8001) | 🔴 DOWN | 01:04 CST |
| Dokploy (3000) | 🔴 DOWN | 01:04 CST |
| 服务器 (Ping) | 🟢 UP | 01:04 CST |

### 业务影响
- ✗ 用户无法访问简历平台
- ✗ API 服务完全中断
- ✗ 管理功能不可用
- ✗ 潜在用户流失

---

## 🎯 恢复目标

### 主要目标
1. **恢复服务可用性** - 最优先
2. **确认数据完整性** - 次优先
3. **分析根因** - 防止复发

### RTO/RPO
- **RTO** (恢复时间目标): < 2 小时
- **RPO** (恢复点目标): < 1 小时

---

## 📋 恢复步骤

### 阶段 1: 服务器访问恢复 (5-15 分钟)

#### 步骤 1.1: 登录云服务商控制台
```
云服务商: [需确认 - 华为云/阿里云/腾讯云]
控制台: [相应管理控制台URL]
凭据: [需要管理员账号]
```

#### 步骤 1.2: 确认服务器实例状态
- [ ] 服务器实例是否在运行
- [ ] CPU/内存/磁盘使用率
- [ ] 网络流量状态
- [ ] 安全组规则确认

#### 步骤 1.3: 使用 VNC/Console 登录
- [ ] 启动 Web Console/VNC
- [ ] 使用 root 账户登录
- [ ] 检查系统负载: `uptime`
- [ ] 检查内存: `free -h`

### 阶段 2: 服务诊断 (5-10 分钟)

#### 步骤 2.1: 检查关键服务
```bash
# SSH 状态
systemctl status sshd

# Nginx 状态
systemctl status nginx

# 后端服务状态
systemctl status ai-resume-backend

# Docker 状态
systemctl status docker
```

#### 步骤 2.2: 检查端口监听
```bash
# 检查关键端口
netstat -tlnp | grep -E ':(22|80|443|8001|8081|3000)'
```

#### 步骤 2.3: 检查系统资源
```bash
# 磁盘空间
df -h

# 内存详情
cat /proc/meminfo | grep -E '(MemTotal|MemFree|MemAvailable|Cached|SwapTotal)'

# CPU 负载
cat /proc/loadavg
```

### 阶段 3: 服务恢复 (10-20 分钟)

#### 步骤 3.1: 恢复 SSH 服务
```bash
# 如果 SSH 停止
systemctl start sshd
systemctl enable sshd

# 如果端口被占用
lsof -i :22
# 必要时 kill 掉占用进程
```

#### 步骤 3.2: 恢复后端服务
```bash
# 检查并重启后端
systemctl status ai-resume-backend
systemctl restart ai-resume-backend

# 验证健康检查
curl http://127.0.0.1:8001/health
```

#### 步骤 3.3: 恢复前端服务
```bash
# 检查并重启 nginx
systemctl status nginx
systemctl restart nginx

# 验证前端
curl -I http://127.0.0.1:8081
```

#### 步骤 3.4: 恢复 Dokploy
```bash
# 检查 Docker
systemctl status docker
docker ps

# 重启 Dokploy 容器（如果停止）
docker start dokploy
```

### 阶段 4: 外部验证 (5 分钟)

#### 步骤 4.1: 从本地验证
```bash
# SSH 连接测试
ssh root@113.45.64.145 "echo 'SSH OK'"

# 主站测试
curl -I https://ndtool.cn

# 后端测试
curl https://ndtool.cn/health
```

---

## 🔍 根因分析

### 可能原因及排查

#### 1. 资源耗尽
**症状**: 服务因 OOM 或磁盘满而崩溃
**排查**:
```bash
# 检查 OOM 日志
journalctl -k | grep -i oom

# 检查磁盘
df -h
```

#### 2. Docker 资源泄漏
**症状**: Docker 容器占用过多资源
**排查**:
```bash
docker stats --no-stream
docker ps -a
```

#### 3. 网络配置问题
**症状**: 防火墙规则或网络配置错误
**排查**:
```bash
iptables -L -n
ufw status
```

#### 4. 安全事件
**症状**: 异常登录、可疑进程
**排查**:
```bash
last | head
lastb | head
ps auxf
```

---

## 📞 联系信息

### 云服务商
- **服务商**: [待确认]
- **技术支持**: [待补充]
- **控制台**: [待补充]

### 团队
- **CEO**: hongfu
- **DevOps**: Agent 29126157-6833-4f1e-94bd-6493bd95d3f2

---

## 📊 恢复检查清单

### 完成恢复后验证
- [ ] SSH 可连接
- [ ] 主站 ndtool.cn 可访问
- [ ] 后端 /health 返回 200
- [ ] Dokploy 面板可访问
- [ ] 所有服务自动启动（systemctl enable）
- [ ] 监控恢复正常
- [ ] 根因已确认
- [ ] 预防措施已制定

---

## 🔄 预防措施

### 短期（本周）
1. ✅ 配置服务可用性监控
2. ✅ 设置告警通知
3. ✅ 备份关键配置
4. ✅ 创建应急预案

### 长期（下月）
1. 考虑多实例部署
2. 配置负载均衡
3. 实施蓝绿部署
4. 完善监控体系

---

**状态**: 🟡 **等待云服务商控制台访问权限**

**下一步**: 执行阶段 1 - 服务器访问恢复
