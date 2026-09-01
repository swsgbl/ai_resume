# 监控和告警系统配置方案

## 🎯 目标
为AI智能体简历平台建立完整的监控告警体系，确保服务稳定性和问题快速响应。

---

## 📊 监控架构设计

### 三层监控体系

#### 第一层: 基础设施监控
- **服务器资源**: CPU、内存、磁盘、网络
- **Docker容器**: 容器状态、资源使用
- **数据库**: 连接数、查询性能、存储

#### 第二层: 应用监控
- **服务健康**: 健康检查端点
- **API性能**: 响应时间、错误率
- **业务指标**: 用户访问、注册、简历生成

#### 第三层: 日志监控
- **应用日志**: 错误日志、访问日志
- **系统日志**: 系统事件、安全事件
- **审计日志**: 用户操作、配置变更

---

## 🛠️ 技术方案选择

### 方案A: Prometheus + Grafana (推荐)
**优点:**
- 开源免费、功能强大
- 丰富的数据源和可视化
- 强大的告警系统
- Docker原生支持

**缺点:**
- 学习曲线较陡
- 需要独立服务器资源

**适用场景**: 中长期生产环境监控

### 方案B: Dokploy集成监控
**优点:**
- 与部署平台集成
- 配置简单、开箱即用
- 资源占用少

**缺点:**
- 功能相对基础
- 扩展性有限

**适用场景**: 快速部署、小规模应用

### 方案C: 云服务商监控
**优点:**
- 与云平台深度集成
- 无需额外部署
- 通常提供免费额度

**缺点:**
- 厂商锁定风险
- 跨平台迁移困难

**适用场景**: 使用特定云服务商的环境

---

## 🚀 推荐实施方案

### 阶段1: 基础监控 (立即实施)

#### 1.1 健康检查端点
**Backend健康检查**
```javascript
// 已有的 /health 端点增强
app.get('/health', async (req, res) => {
  const health = {
    status: 'healthy',
    timestamp: new Date().toISOString(),
    uptime: process.uptime(),
    checks: {
      database: await checkDatabase(),
      redis: await checkRedis(),
      external: await checkExternalServices()
    }
  };

  const isHealthy = Object.values(health.checks).every(check => check.status === 'ok');
  res.status(isHealthy ? 200 : 503).json(health);
});
```

**Frontend健康检查**
```javascript
// 添加前端健康监控
export const healthCheck = () => {
  const checks = {
    api: checkApiConnection(),
    localStorage: checkLocalStorage(),
    browser: checkBrowserCompatibility()
  };

  return {
    status: Object.values(checks).every(Boolean) ? 'healthy' : 'degraded',
    checks
  };
};
```

#### 1.2 容器监控脚本
**创建**: `scripts/container-monitor.sh`
```bash
#!/bin/bash
# 容器状态监控脚本

LOG_FILE="/var/log/container-monitor.log"
ALERT_EMAIL="admin@airesume.com"

check_containers() {
    local containers=("ai-resume-backend" "ai-resume-frontend" "ai-resume-redis")
    local failed=()

    for container in "${containers[@]}"; do
        if ! docker ps --format "{{.Names}}" | grep -q "^${container}$"; then
            failed+=("$container")
            echo "[$(date)] 容器 $container 未运行" >> "$LOG_FILE"
        fi
    done

    if [ ${#failed[@]} -gt 0 ]; then
        send_alert "容器异常: ${failed[*]}"
    fi
}

check_resources() {
    local backend_stats=$(docker stats ai-resume-backend --no-stream --format "{{.CPUPerc}},{{.MemUsage}}")
    local cpu_usage=$(echo $backend_stats | cut -d',' -f1 | sed 's/%//')

    if (( $(echo "$cpu_usage > 80" | bc -l) )); then
        echo "[$(date)] Backend CPU使用率过高: ${cpu_usage}%" >> "$LOG_FILE"
        send_alert "Backend CPU使用率: ${cpu_usage}%"
    fi
}

send_alert() {
    local message=$1
    # 这里可以集成邮件、微信、钉钉等告警
    echo "告警: $message" >> "$LOG_FILE"
}

# 每5分钟检查一次
while true; do
    check_containers
    check_resources
    sleep 300
done
```

#### 1.3 服务可用性监控
**创建**: `scripts/uptime-monitor.sh`
```bash
#!/bin/bash
# 服务可用性监控

services=(
    "Backend|http://localhost:8000/health"
    "Frontend|http://localhost:3000"
    "Backend-External|http://113.45.64.145:8000/health"
)

monitor_services() {
    for service in "${services[@]}"; do
        IFS='|' read -r name url <<< "$service"

        if curl -s -f "$url" > /dev/null 2>&1; then
            echo "[$(date)] $name: OK"
        else
            echo "[$(date)] $name: FAILED"
            # 可以添加重启逻辑
            # docker restart ai-resume-backend
        fi
    done
}

# 每分钟检查一次
while true; do
    monitor_services
    sleep 60
done
```

### 阶段2: 高级监控 (1-2周内)

#### 2.1 Prometheus配置
**docker-compose.monitoring.yml**
```yaml
version: '3.8'

services:
  prometheus:
    image: prom/prometheus:latest
    container_name: prometheus
    ports:
      - "9090:9090"
    volumes:
      - ./prometheus.yml:/etc/prometheus/prometheus.yml
      - prometheus-data:/prometheus
    command:
      - '--config.file=/etc/prometheus/prometheus.yml'
      - '--storage.tsdb.path=/prometheus'
    restart: unless-stopped

  grafana:
    image: grafana/grafana:latest
    container_name: grafana
    ports:
      - "3001:3000"
    environment:
      - GF_SECURITY_ADMIN_PASSWORD=admin123
    volumes:
      - grafana-data:/var/lib/grafana
    depends_on:
      - prometheus
    restart: unless-stopped

  node-exporter:
    image: prom/node-exporter:latest
    container_name: node-exporter
    ports:
      - "9100:9100"
    restart: unless-stopped

  cadvisor:
    image: gcr.io/cadvisor/cadvisor:latest
    container_name: cadvisor
    ports:
      - "8080:8080"
    volumes:
      - /:/rootfs:ro
      - /var/run:/var/run:ro
      - /sys:/sys:ro
      - /var/lib/docker/:/var/lib/docker:ro
    restart: unless-stopped

volumes:
  prometheus-data:
  grafana-data:
```

**prometheus.yml**
```yaml
global:
  scrape_interval: 15s
  evaluation_interval: 15s

scrape_configs:
  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']

  - job_name: 'node-exporter'
    static_configs:
      - targets: ['node-exporter:9100']

  - job_name: 'cadvisor'
    static_configs:
      - targets: ['cadvisor:8080']

  - job_name: 'ai-resume-backend'
    static_configs:
      - targets: ['host.docker.internal:8000']
    metrics_path: '/metrics'
```

#### 2.2 Grafana仪表板配置
**预配置的仪表板:**
- **系统概览**: CPU、内存、磁盘、网络
- **容器监控**: 各容器资源使用情况
- **应用性能**: API响应时间、请求量、错误率
- **业务指标**: 用户活跃度、简历生成数量

### 阶段3: 告警配置 (持续完善)

#### 3.1 告警规则
**Prometheus告警规则**
```yaml
groups:
  - name: ai-resume-alerts
    interval: 30s
    rules:
      # 服务可用性告警
      - alert: ServiceDown
        expr: up == 0
        for: 1m
        labels:
          severity: critical
        annotations:
          summary: "服务 {{ $labels.instance }} 不可用"
          description: "服务 {{ $labels.instance }} 已经宕机超过1分钟"

      # 高CPU使用率告警
      - alert: HighCPUUsage
        expr: rate(process_cpu_seconds_total[5m]) > 0.8
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "高CPU使用率"
          description: "{{ $labels.instance }} CPU使用率超过80%"

      # 高内存使用率告警
      - alert: HighMemoryUsage
        expr: process_resident_memory_bytes / 1024 / 1024 > 1024
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "高内存使用率"
          description: "{{ $labels.instance }} 内存使用超过1GB"

      # API响应时间告警
      - alert: SlowAPI
        expr: http_request_duration_seconds > 1
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "API响应缓慢"
          description: "API平均响应时间超过1秒"
```

#### 3.2 告警通知渠道

**邮件通知**
```yaml
# Prometheus AlertManager配置
receivers:
  - name: 'email-alerts'
    email_configs:
      - to: 'admin@airesume.com'
        from: 'alertmanager@airesume.com'
        smarthost: 'smtp.gmail.com:587'
        auth_username: 'your-email@gmail.com'
        auth_password: 'your-app-password'
```

**企业微信/钉钉通知**
```bash
# Webhook通知脚本
send_wechat_alert() {
    local webhook="https://qyapi.weixin.qq.com/cgi-bin/webhook/send?key=YOUR_KEY"
    local message=$1

    curl -X POST "$webhook" \
        -H 'Content-Type: application/json' \
        -d "{
            \"msgtype\": \"text\",
            \"text\": {
                \"content\": \"$message\"
            }
        }"
}
```

---

## 📈 监控指标定义

### 核心指标 (RED方法)
- **Rate (请求率)**: 每秒请求数
- **Errors (错误率)**: 错误请求百分比
- **Duration (响应时间)**: 请求处理时间

### 业务指标
- **用户活跃度**: DAU/MAU
- **简历生成数**: 每日生成简历数量
- **转化率**: 访问到注册的转化率

### 基础设施指标
- **CPU使用率**: 系统/容器CPU使用情况
- **内存使用率**: 系统/容器内存使用情况
- **磁盘IO**: 读写IOPS和吞吐量
- **网络流量**: 入站/出站流量

---

## 🔧 实施步骤

### 第1周: 基础监控
- [ ] 部署健康检查端点
- [ ] 配置容器监控脚本
- [ ] 设置基础告警规则
- [ ] 配置日志收集

### 第2周: 高级监控
- [ ] 部署Prometheus + Grafana
- [ ] 配置数据采集
- [ ] 创建监控仪表板
- [ ] 设置高级告警

### 第3-4周: 优化完善
- [ ] 调优监控精度
- [ ] 完善告警规则
- [ ] 配置告警通知
- [ ] 编写运维文档

---

## 💰 成本考虑

### 开源方案 (推荐)
- **软件成本**: 免费
- **服务器成本**: 需要独立监控服务器 (可选)
- **维护成本**: 中等

### 托管方案
- **Datadog**: $15-75/主机/月
- **New Relic**: $50-175/主机/月
- **云服务商监控**: 通常免费或低价

### 推荐方案
- **初期**: 开源方案 (免费)
- **中期**: 混合方案 (核心监控+增值服务)
- **长期**: 根据规模和需求评估

---

## ✅ 监控效果验证

### 验证清单
- [ ] 健康检查端点正常响应
- [ ] 监控数据正确采集
- [ ] 仪表板显示正常
- [ ] 告警规则触发正常
- [ ] 告警通知正常发送
- [ ] 日志收集正常工作

### 测试场景
1. **服务宕机测试**: 停止容器，检查告警
2. **高负载测试**: 压力测试，检查性能监控
3. **告警测试**: 触发告警条件，验证通知

---

## 📚 相关文档

- **安装部署**: Prometheus官方文档
- **配置指南**: Grafana仪表板配置
- **告警配置**: AlertManager配置指南
- **最佳实践**: 监控系统设计模式

---

**文档版本**: v1.0
**创建日期**: 2026-04-06
**优先级**: 🟡 中等优先级
**预计完成时间**: 3-4周