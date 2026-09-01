# 告警配置指南

> **AI Resume Platform - 监控告警配置**
> 最后更新: 2026-04-02

## 目录

- [告警概览](#告警概览)
- [配置 Slack 通知](#配置-slack-通知)
- [配置邮件通知](#配置邮件通知)
- [告警规则](#告警规则)
- [测试告警](#测试告警)

---

## 告警概览

AI Resume Platform 使用以下告警组件:

- **Prometheus**: 指标收集和规则评估
- **Alertmanager**: 告警路由和通知
- **Grafana**: 可视化和告警面板

### 告警级别

| 级别 | 说明 | 响应时间 | 通知渠道 |
|------|------|----------|----------|
| Critical | 严重故障，服务不可用 | 立即 | Slack + Email + SMS |
| Warning | 警告状态，需要关注 | 5 分钟内 | Slack |
| Info | 信息通知 | 记录 | 日志 |

---

## 配置 Slack 通知

### 1. 创建 Slack App

1. 访问 https://api.slack.com/apps
2. 创建新 App → "From scratch"
3. 配置权限:
   - `chat:write`
   - `chat:write.public`
   - `links:read`
   - `incoming-webhook`

### 2. 创建 Webhook

1. 在 App 设置中启用 "Incoming Webhooks"
2. 点击 "Add New Webhook to Workspace"
3. 选择目标频道:
   - `#alerts` - 所有告警
   - `#critical-alerts` - 关键告警
   - `#warnings` - 警告告警
   - `#backend-alerts` - 后端服务告警
   - `#frontend-alerts` - 前端服务告警

### 3. 配置环境变量

```bash
# 添加到 .env.production 或系统环境变量
export SLACK_WEBHOOK_URL="https://hooks.slack.com/services/YOUR/WEBHOOK/URL"
```

### 4. 更新 Alertmanager 配置

编辑 `monitoring/alertmanager/config/alertmanager.yml`:

```yaml
global:
  slack_api_url: '${SLACK_WEBHOOK_URL}'
```

### 5. 重启 Alertmanager

```bash
docker-compose -f monitoring/alertmanager/docker-compose.alertmanager.yml restart alertmanager
```

---

## 配置邮件通知

### 1. 配置 SMTP

编辑 `monitoring/alertmanager/config/alertmanager.yml`:

```yaml
receivers:
  - name: 'email-alerts'
    email_configs:
      - to: 'ops@yourdomain.com'
        from: 'alertmanager@yourdomain.com'
        smarthost: 'smtp.gmail.com:587'
        auth_username: 'your-email@gmail.com'
        auth_password: 'your-app-password'
        require_tls: true
```

### 2. 使用应用专用密码

对于 Gmail，需要使用应用专用密码:
1. 访问 https://myaccount.google.com/apppasswords
2. 生成新应用专用密码
3. 在配置中使用该密码

---

## 告警规则

### Critical 级别告警

| 告警名称 | 触发条件 | 持续时间 |
|----------|----------|----------|
| ServiceDown | 服务不可用 | 1 分钟 |
| DiskSpaceLow | 磁盘空间 < 15% | 5 分钟 |
| RedisDown | Redis 宕机 | 1 分钟 |

### Warning 级别告警

| 告警名称 | 触发条件 | 持续时间 |
|----------|----------|----------|
| HighErrorRate | 错误率 > 5% | 5 分钟 |
| HighResponseTime | P95 响应时间 > 1 秒 | 5 分钟 |
| HighCPUUsage | CPU 使用率 > 80% | 10 分钟 |
| HighMemoryUsage | 内存使用 > 1GB | 10 分钟 |

### 修改告警规则

编辑 `monitoring/prometheus/rules/alerts.yml`:

```yaml
- alert: CustomAlert
  expr: your_expression_here
  for: 5m
  labels:
    severity: warning
  annotations:
    summary: "自定义告警摘要"
    description: "自定义告警描述"
```

重启 Prometheus:
```bash
docker-compose -f docker-compose.monitoring.yml restart prometheus
```

---

## 测试告警

### 1. 测试 Slack 通知

```bash
curl -X POST $SLACK_WEBHOOK_URL \
  -H 'Content-Type: application/json' \
  -d '{"text":"🧪 告警测试 - 这是一条测试消息"}'
```

### 2. 测试 Alertmanager

```bash
# 发送测试告警
curl -X POST http://localhost:9093/api/v1/alerts \
  -H 'Content-Type: application/json' \
  -d '[
    {
      "labels": {
        "alertname": "TestAlert",
        "severity": "warning",
        "service": "test"
      },
      "annotations": {
        "summary": "测试告警",
        "description": "这是一条测试告警消息"
      }
    }
  ]'
```

### 3. 查看告警状态

```bash
# Prometheus 告警
curl http://localhost:9090/api/v1/alerts | jq

# Alertmanager 状态
curl http://localhost:9093/api/v1/status | jq
```

---

## 告警最佳实践

1. **设置合理的阈值**: 避免告警疲劳
2. **使用抑制规则**: 避免重复通知
3. **定期测试**: 确保告警正常工作
4. **更新联系人**: 保持联系信息准确
5. **文档化流程**: 记录告警处理流程

---

## 故障排查

### 问题: 告警未发送

**检查清单:**
- [ ] Slack Webhook URL 正确
- [ ] Alertmanager 运行正常
- [ ] 告警规则已加载
- [ ] 网络连接正常

**调试命令:**
```bash
# 查看 Alertmanager 日志
docker logs ai-resume-alertmanager

# 检查告警状态
curl http://localhost:9093/api/v1/alerts
```

### 问题: 重复告警

**解决方案:**
- 增加告警持续时间
- 配置抑制规则
- 设置合理的重复间隔

---

## 相关文档

- [DEVOPS_GUIDE.md](DEVOPS_GUIDE.md) - DevOps 操作指南
- [monitoring/prometheus/rules/alerts.yml](monitoring/prometheus/rules/alerts.yml) - 告警规则配置
