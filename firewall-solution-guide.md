# 🔥 Backend 外部访问问题解决方案

**日期**: 2026-04-06
**工程师**: DevOps Agent (29126157-6833-4f1e-94bd-6493bd95d3f2)
**问题**: Backend 服务 (8000端口) 外部无法访问 - 防火墙阻止

---

## 🎯 问题确认

### 验证结果
- ✅ **本地访问**: `localhost:8000/health` → HTTP 200 (0.002秒)
- ❌ **外部访问**: `113.45.64.145:8000/health` → 连接超时
- ✅ **容器状态**: Backend 容器健康运行
- ✅ **端口映射**: Docker 端口映射正确 (0.0.0.0:8000->8000/tcp)

### 问题性质
**网络层问题** - 防火墙规则未配置 8000 端口

---

## 🛠️ 解决方案

### 方案1: UFW 防火墙配置（推荐）⭐

**适用场景**: Ubuntu 服务器，使用 UFW 防火墙

**操作步骤**:
```bash
# 1. SSH 到服务器
ssh -i ~/.ssh/id_ed25519 root@113.45.64.145

# 2. 检查当前防火墙状态
ufw status verbose

# 3. 允许 8000 端口
ufw allow 8000/tcp
ufw allow from any to any port 8000 proto tcp

# 4. 验证规则已添加
ufw status numbered

# 5. 如果需要删除规则
# ufw delete allow 8000/tcp
```

**预期结果**:
```
Status: active

To                         Action      From
--                         ------      ----
8000/tcp                   ALLOW       Anywhere
8000/tcp (v6)              ALLOW       Anywhere (v6)
```

### 方案2: iptables 配置

**适用场景**: 服务器使用 iptables 防火墙

**操作步骤**:
```bash
# 1. SSH 到服务器
ssh -i ~/.ssh/id_ed25519 root@113.45.64.145

# 2. 添加 iptables 规则
iptables -A INPUT -p tcp --dport 8000 -j ACCEPT
iptables -A INPUT -p tcp --dport 8000 -m state --state NEW,ESTABLISHED -j ACCEPT

# 3. 保存规则
iptables-save > /etc/iptables/rules.v4
# 或
netfilter-persistent save

# 4. 查看规则
iptables -L -n -v | grep 8000
```

### 方案3: 云服务商安全组配置

**适用场景**: 使用云服务器（阿里云、腾讯云等）

**操作步骤**:
1. **登录云服务商控制台**
2. **找到实例 113.45.64.145**
3. **进入安全组设置**
4. **添加入站规则**:
   - **协议**: TCP
   - **端口**: 8000
   - **源地址**: 0.0.0.0/0 (或限制为特定IP)
   - **描述**: Backend API 服务

### 方案4: firewalld 配置

**适用场景**: CentOS/RHEL 系统使用 firewalld

```bash
# 1. 启用防火墙
systemctl start firewalld
systemctl enable firewalld

# 2. 添加端口规则
firewall-cmd --permanent --add-port=8000/tcp
firewall-cmd --reload

# 3. 验证规则
firewall-cmd --list-ports
```

---

## 🧪 验证步骤

### 配置前验证
```bash
# 应该失败或超时
curl http://113.45.64.145:8000/health
```

### 配置后验证
```bash
# 应该成功响应
curl http://113.45.64.145:8000/health
# 预期响应: {"status":"healthy","app":"AI简历智能生成平台","version":"1.0.0"}

# 测试 API 端点
curl http://113.45.64.145:8000/api/v1/
curl http://113.45.64.145:8000/docs
```

### 完整验证脚本
```bash
# 运行我们的验证脚本
./scripts/deployment-verification.sh

# 或手动验证
curl -v http://113.45.64.145:8000/health
curl -v http://113.45.64.145:8000/api/v1/
```

---

## 🔒 安全建议

### 限制访问来源（推荐）
```bash
# 只允许特定 IP 访问
ufw allow from 203.0.113.0 to any port 8000 proto tcp

# 或只允许特定IP段
ufw allow from 203.0.113.0/24 to any port 8000 proto tcp
```

### 云服务商安全组
- 源地址设置为特定IP而非 0.0.0.0/0
- 定期审查和更新访问规则

### SSL/TLS 配置
```bash
# 配置 HTTPS（后续步骤）
# 1. 获取 SSL 证书
# 2. 配置 Nginx 反向代理
# 3. 强制 HTTPS 重定向
```

---

## 📋 故障排查

### 如果配置后仍然无法访问

1. **检查防火墙状态**
   ```bash
   ufw status verbose
   iptables -L -n -v | grep 8000
   ```

2. **检查 Docker 端口映射**
   ```bash
   docker port ai-resume-backend
   # 应该显示: 8000/tcp -> 0.0.0.0:8000
   ```

3. **检查容器日志**
   ```bash
   docker logs ai-resume-backend --tail 50
   ```

4. **测试本地连接**
   ```bash
   curl -v http://localhost:8000/health
   ```

5. **检查网络连通性**
   ```bash
   ping 113.45.64.145
   traceroute 113.45.64.145
   ```

### 常见错误和解决方案

**错误1**: `ufw: command not found`
```bash
# 安装 UFW
apt-get update
apt-get install ufw

# 启用 UFW
ufw enable
```

**错误2**: `Permission denied`
```bash
# 使用 sudo 或 root 用户
sudo ufw allow 8000/tcp
```

**错误3**: 防火墙规则已存在
```bash
# 先删除现有规则
ufw delete allow 8000/tcp
# 重新添加
ufw allow 8000/tcp
```

---

## 📊 当前网络拓扑

### 配置前
```
外部用户
    ↓
防火墙 (3000✅, 8000❌) ← 问题在这里
    ↓
Docker 容器 (Backend✅, Frontend✅, Redis✅)
```

### 配置后
```
外部用户
    ↓
防火墙 (3000✅, 8000✅) ← 已修复
    ↓
Docker 容器 (Backend✅, Frontend✅, Redis✅)
```

---

## 🎯 预期结果

配置完成后，所有服务应能正常从外部访问：

| 服务 | 端口 | 本地访问 | 外部访问 | 预期响应 |
|------|------|----------|----------|----------|
| **Backend** | 8000 | ✅ 正常 | ✅ 修复后 | HTTP 200 |
| **Frontend** | 3000 | ✅ 正常 | ✅ 正常 | HTTP 200 |
| **Redis** | 6379 | ✅ 正常 | ❌ 内部 | N/A |
| **MySQL** | 3306 | ❌ 占用 | ❌ 内部 | N/A |

---

## 📞 技术支持

### 如果问题仍未解决

1. **检查云服务商控制台**
   - 确认实例安全组规则
   - 检查网络ACL配置

2. **联系网络管理员**
   - 确认网络策略
   - 验证路由配置

3. **查看详细日志**
   ```bash
   # Docker 日志
   docker logs ai-resume-backend --tail 100 --follow
   
   # 系统防火墙日志
   journalctl -u ufw -n 50
   ```

---

**文档版本**: 1.0
**最后更新**: 2026-04-06
**预计解决时间**: 5-10分钟
**难度等级**: 简单
**风险等级**: 低
