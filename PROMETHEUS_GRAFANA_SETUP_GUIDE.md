# Prometheus + Grafana 监控系统实施指南
**创建时间**: 2026-04-17 11:00
**DevOps Agent**: 29126157-6833-4f1e-94bd-6493bd95d3f2
**优先级**: P2 (中等优先级)
**预计完成时间**: 2026-04-19

---

## 📋 当前状态评估

### ✅ 已有配置
- **配置文件完整**: Prometheus、Grafana、Alertmanager配置已就绪
- **Docker Compose**: 监控服务配置文件已创建
- **仪表板模板**: 系统资源、应用健康、容器监控仪表板
- **告警规则**: 基础告警规则已定义

### ⚠️ 当前问题
- **监控容器未运行**: Prometheus、Grafana未启动
- **应用指标未集成**: 后端缺少Prometheus客户端
- **数据收集不完整**: cAdvisor、Node Exporter未配置
- **告警未激活**: Alertmanager未启动

---

## 🎯 监控系统架构

### 完整监控栈
```
┌─────────────────────────────────────────────────────┐
│                   监控系统架构                        │
├─────────────────────────────────────────────────────┤
│                                                      │
│  ┌──────────────┐       ┌──────────────┐           │
│  │   应用层      │       │   基础设施层   │           │
│  ├──────────────┤       ├──────────────┤           │
│  │ Backend API  │───────│ Node Exporter│           │
│  │ /metrics     │       │ cAdvisor     │           │
│  └──────────────┘       └──────────────┘           │
│         │                      │                    │
│         └──────────┬───────────┘                    │
│                    ▼                                │
│         ┌──────────────────┐                       │
│         │   Prometheus     │◄──── 指标收集          │
│         │   :9090          │                        │
│         └──────────────────┘                       │
│                    │                                │
│         ┌──────────┼──────────┐                    │
│         ▼          ▼          ▼                    │
│  ┌──────────┐ ┌─────────┐ ┌─────────────┐          │
│  │ Grafana  │ │AlertMgr │ │    Loki     │          │
│  │  :3001   │ │ :9093   │ │   :3100     │          │
│  └──────────┘ └─────────┘ └─────────────┘          │
│                                                      │
└─────────────────────────────────────────────────────┘
```

### 监控数据流
1. **应用指标** → Backend暴露 `/metrics` 端点
2. **系统指标** → Node Exporter收集主机资源
3. **容器指标** → cAdvisor收集容器状态
4. **日志收集** → Promtail + Loki聚合日志
5. **数据展示** → Grafana可视化仪表板
6. **告警通知** → Alertmanager发送告警

---

## 🚀 实施方案

### 阶段1: 基础监控启动 (2小时)

#### 1.1 启动核心监控服务
```bash
# 启动Prometheus + Grafana
docker-compose -f docker-compose.prod.yml \
  -f docker-compose.monitoring.yml \
  up -d prometheus grafana

# 验证服务状态
docker ps | grep -E "(prometheus|grafana)"
docker logs prometheus -f
docker logs grafana -f
```

#### 1.2 启动系统指标收集
```bash
# 添加Node Exporter (系统指标)
# 更新docker-compose.monitoring.yml
cat >> docker-compose.monitoring.yml << 'EOF'
  # Node Exporter - 系统指标
  node-exporter:
    image: prom/node-exporter:latest
    container_name: ai-resume-node-exporter
    command:
      - '--path.procfs=/host/proc'
      - '--path.sysfs=/host/sys'
      - '--collector.filesystem.mount-points-exclude=^/(sys|proc|dev|host|etc)($$|/)'
    ports:
      - "9100:9100"
    volumes:
      - /proc:/host/proc:ro
      - /sys:/host/sys:ro
      - /:/rootfs:ro
    restart: unless-stopped
    networks:
      - ai-resume-network
    profiles:
      - monitoring

  # cAdvisor - 容器指标
  cadvisor:
    image: gcr.io/cadvisor/cadvisor:latest
    container_name: ai-resume-cadvisor
    ports:
      - "8081:8080"
    volumes:
      - /:/rootfs:ro
      - /var/run:/var/run:ro
      - /sys:/sys:ro
      - /var/lib/docker/:/var/lib/docker:ro
      - /dev/disk/:/dev/disk:ro
    privileged: true
    restart: unless-stopped
    networks:
      - ai-resume-network
    profiles:
      - monitoring
EOF

# 启动系统指标收集
docker-compose -f docker-compose.prod.yml \
  -f docker-compose.monitoring.yml \
  up -d node-exporter cadvisor
```

#### 1.3 验证基础监控
```bash
# 验证Prometheus目标
curl http://localhost:9090/api/v1/targets | jq '.data.activeTargets[] | {job: .labels.job, health: .health}'

# 验证指标数据
curl http://localhost:9090/api/v1/query?query=up | jq '.data.result[] | {metric: .metric.__name__, value: .value[1]}'

# 访问Grafana
echo "Grafana: http://localhost:3001"
echo "默认用户名: admin"
echo "默认密码: admin"
```

---

### 阶段2: 应用指标集成 (3小时)

#### 2.1 后端Prometheus集成
```bash
# 安装Python Prometheus客户端
pip install prometheus-fastapi-instrumentator

# 或添加到requirements.txt
echo "prometheus-fastapi-instrumentator==6.1.0" >> backend/requirements.txt
```

#### 2.2 更新Backend主应用
```python
# backend/app/main.py
from prometheus_fastapi_instrumentator import Instrumentator
from prometheus_client import Counter, Histogram, Gauge
import time

# 创建业务指标
resume_generations = Counter('resume_generations_total', 'Total resume generations')
api_requests = Counter('api_requests_total', 'Total API requests', ['method', 'endpoint', 'status'])
request_duration = Histogram('request_duration_seconds', 'Request duration')
active_users = Gauge('active_users', 'Currently active users')

# 初始化FastAPI应用
app = FastAPI(title=settings.APP_NAME)

# 配置Prometheus监控
instrumentator = Instrumentator()
instrumentator.instrument(app).expose(app, endpoint="/metrics")

# 添加自定义指标中间件
@app.middleware("http")
async def metrics_middleware(request: Request, call_next):
    start_time = time.time()
    
    response = await call_next(request)
    
    # 记录请求指标
    duration = time.time() - start_time
    api_requests.labels(
        method=request.method,
        endpoint=request.url.path,
        status=response.status_code
    ).inc()
    request_duration.observe(duration)
    
    return response

# 业务指标示例
@app.post("/api/v1/resume/generate")
async def generate_resume():
    resume_generations.inc()
    # ... 业务逻辑
    pass
```

#### 2.3 更新Prometheus配置
```yaml
# monitoring/prometheus/prometheus.yml
scrape_configs:
  # 后端应用指标
  - job_name: 'backend'
    static_configs:
      - targets: ['ai-resume-backend:8000']
    metrics_path: '/metrics'
    scrape_interval: 30s
    
  # 前端指标 (可选)
  - job_name: 'frontend'
    static_configs:
      - targets: ['ai-resume-frontend:80']
    metrics_path: '/metrics'
    scrape_interval: 30s
```

#### 2.4 重启Backend服务
```bash
# 重建Backend容器
docker-compose -f docker-compose.prod.yml up -d --build backend

# 验证metrics端点
curl http://localhost:8000/metrics | head -20
```

---

### 阶段3: Grafana仪表板配置 (2小时)

#### 3.1 导入预配置仪表板
```bash
# 仪表板已存在于 monitoring/grafana/dashboards/
# application-overview.json - 应用概览
# system-resources.json - 系统资源
# container-health.json - 容器健康

# 访问Grafana并导入仪表板
# http://localhost:3001
```

#### 3.2 创建自定义仪表板
```json
{
  "dashboard": {
    "title": "AI Resume Platform - 业务监控",
    "panels": [
      {
        "title": "简历生成趋势",
        "targets": [
          {
            "expr": "rate(resume_generations_total[5m])",
            "legendFormat": "生成速率"
          }
        ]
      },
      {
        "title": "API请求量",
        "targets": [
          {
            "expr": "sum(rate(api_requests_total[5m])) by (endpoint)",
            "legendFormat": "{{endpoint}}"
          }
        ]
      },
      {
        "title": "响应时间分布",
        "targets": [
          {
            "expr": "histogram_quantile(0.95, rate(request_duration_seconds_bucket[5m]))",
            "legendFormat": "P95响应时间"
          }
        ]
      }
    ]
  }
}
```

#### 3.3 配置数据源
```bash
# Grafana已通过provisioning配置Prometheus数据源
# 验证数据源连接
curl -u admin:admin http://localhost:3001/api/datasources | jq '.'
```

---

### 阶段4: 告警配置 (2小时)

#### 4.1 启动Alertmanager
```bash
# 启动告警管理器
docker-compose -f monitoring/alertmanager/docker-compose.alertmanager.yml up -d

# 验证Alertmanager
curl http://localhost:9093/api/v1/status
```

#### 4.2 配置告警规则
```yaml
# monitoring/prometheus/rules/alerts.yml
groups:
  - name: ai_resume_alerts
    interval: 30s
    rules:
      # 服务可用性告警
      - alert: ServiceDown
        expr: up{job="backend"} == 0
        for: 1m
        labels:
          severity: critical
        annotations:
          summary: "Backend service is down"
          description: "Backend service has been down for more than 1 minute"
      
      # 高错误率告警
      - alert: HighErrorRate
        expr: rate(api_requests_total{status=~"5.."}[5m]) > 0.05
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "High error rate detected"
          description: "Error rate is {{ $value }} errors per second"
      
      # 响应时间告警
      - alert: SlowResponse
        expr: histogram_quantile(0.95, rate(request_duration_seconds_bucket[5m])) > 2
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "Slow API responses"
          description: "P95 response time is {{ $value }} seconds"
      
      # 资源使用告警
      - alert: HighCPUUsage
        expr: rate(process_cpu_seconds_total[5m]) > 0.8
        for: 10m
        labels:
          severity: warning
        annotations:
          summary: "High CPU usage"
          description: "CPU usage is {{ $value }}%"
      
      - alert: HighMemoryUsage
        expr: (process_resident_memory_bytes / total_memory_bytes) > 0.9
        for: 10m
        labels:
          severity: critical
        annotations:
          summary: "High memory usage"
          description: "Memory usage is {{ $value }}%"
```

#### 4.3 配置告警通知
```yaml
# monitoring/alertmanager/config/alertmanager.yml
global:
  resolve_timeout: 5m

route:
  group_by: ['alertname', 'cluster', 'service']
  group_wait: 10s
  group_interval: 10s
  repeat_interval: 12h
  receiver: 'default'
  routes:
    - match:
        severity: critical
      receiver: 'critical'
    - match:
        severity: warning
      receiver: 'warnings'

receivers:
  - name: 'default'
    webhook_configs:
      - url: 'http://localhost:5001/webhook'
  
  - name: 'critical'
    webhook_configs:
      - url: 'http://localhost:5001/critical'
    # 邮件通知
    email_configs:
      - to: 'admin@airesume.com'
        from: 'alertmanager@airesume.com'
        smarthost: 'smtp.gmail.com:587'
        auth_username: 'your-email@gmail.com'
        auth_password: 'your-app-password'
  
  - name: 'warnings'
    webhook_configs:
      - url: 'http://localhost:5001/warnings'
```

#### 4.4 更新Prometheus告警配置
```yaml
# monitoring/prometheus/prometheus.yml
alerting:
  alertmanagers:
    - static_configs:
        - targets: ['alertmanager:9093']
```

---

### 阶段5: 日志聚合 (2小时)

#### 5.1 启动日志聚合服务
```bash
# 启动Loki + Promtail
docker-compose -f docker-compose.prod.yml \
  -f docker-compose.monitoring.yml \
  up -d loki promtail

# 验证服务
curl http://localhost:3100/ready
curl http://localhost:9080/ready
```

#### 5.2 配置日志收集
```yaml
# monitoring/promtail/config.yml
server:
  http_listen_port: 9080

positions:
  filename: /tmp/positions.yaml

clients:
  - url: http://loki:3100/loki/api/v1/push

scrape_configs:
  # 应用日志
  - job_name: containers
    static_configs:
      - targets:
          - localhost
        labels:
          job: containerlogs
          __path__: /var/lib/docker/containers/*/*-json.log

    pipeline_stages:
      - json:
          expressions:
            output: log
            stream: stream
            attrs:
      - json:
          expressions:
            tag:
          source: attrs
      - regex:
          source: tag
          expression: (?P<container_name>(?:[^|]*))\|
      - labels:
          stream:
          container_name:
      - output:
          source: output
```

---

### 阶段6: 监控验证 (1小时)

#### 6.1 基础功能验证
```bash
# 验证所有监控组件
echo "=== 监控组件状态 ==="
docker ps | grep -E "(prometheus|grafana|alertmanager|loki|promtail|node-exporter|cadvisor)"

echo "=== Prometheus健康检查 ==="
curl http://localhost:9090/-/healthy | jq '.'

echo "=== Grafana健康检查 ==="
curl http://localhost:3001/api/health | jq '.'

echo "=== 指标收集测试 ==="
curl http://localhost:9090/api/v1/query?query=up | jq '.data.result[] | select(.metric.job=="backend")'
```

#### 6.2 仪表板验证
```bash
# 访问Grafana仪表板
echo "Grafana Dashboard: http://localhost:3001"
echo "检查以下仪表板:"
echo "- 应用概览 (Application Overview)"
echo "- 系统资源 (System Resources)" 
echo "- 容器健康 (Container Health)"
```

#### 6.3 告警测试
```bash
# 测试告警规则
echo "=== 测试服务宕机告警 ==="
# 停止backend服务
docker stop ai-resume-backend
# 等待1分钟检查告警
sleep 60
curl http://localhost:9093/api/v1/alerts | jq '.data.alerts[] | select(.labels.alertname=="ServiceDown")'

# 恢复服务
docker start ai-resume-backend
```

---

## 📊 监控指标定义

### 核心业务指标
| 指标名称 | 类型 | 描述 | 重要性 |
|---------|------|------|--------|
| `resume_generations_total` | Counter | 简历生成总数 | 高 |
| `api_requests_total` | Counter | API请求总数 | 高 |
| `request_duration_seconds` | Histogram | 请求响应时间 | 高 |
| `active_users` | Gauge | 当前活跃用户 | 中 |
| `error_rate` | Gauge | 错误率 | 高 |

### 系统资源指标
| 指标名称 | 描述 | 阈值 |
|---------|------|------|
| `cpu_usage_percent` | CPU使用率 | >80% 告警 |
| `memory_usage_bytes` | 内存使用量 | >90% 告警 |
| `disk_usage_percent` | 磁盘使用率 | >85% 告警 |
| `network_io_bytes` | 网络IO | 监控趋势 |

### 应用健康指标
| 指标名称 | 描述 | 目标 |
|---------|------|------|
| `up{job="backend"}` | 后端服务状态 | =1 |
| `http_requests_total{status="200"}` | 成功请求数 | 趋势上升 |
| `http_requests_total{status="5xx"}` | 错误请求数 | <5% |

---

## 🔧 配置文件清单

### 必需配置文件
```
monitoring/
├── prometheus/
│   ├── prometheus.yml          # Prometheus主配置
│   └── rules/
│       └── alerts.yml          # 告警规则
├── grafana/
│   ├── provisioning/
│   │   ├── datasources/
│   │   │   └── prometheus.yml  # 数据源配置
│   │   └── dashboards/
│   │       └── dashboards.yml  # 仪表板配置
│   └── dashboards/
│       ├── application-overview.json
│       ├── system-resources.json
│       └── container-health.json
├── alertmanager/
│   └── config/
│       └── alertmanager.yml    # 告警管理器配置
├── loki/
│   └── config.yml              # 日志聚合配置
└── promtail/
    └── config.yml              # 日志收集配置
```

---

## 🎯 验证清单

### 功能验证
- [ ] Prometheus启动正常，可访问Web界面
- [ ] Grafana启动正常，数据源配置正确
- [ ] 所有目标服务器状态为UP
- [ ] 指标数据正常收集
- [ ] 仪表板显示正确数据

### 告警验证
- [ ] Alertmanager启动正常
- [ ] 告警规则加载成功
- [ ] 测试告警正常触发
- [ ] 告警通知正常发送
- [ ] 告警恢复通知正常

### 日志验证
- [ ] Loki启动正常
- [ ] Promtail启动正常
- [ ] 日志正常收集到Loki
- [ ] Grafana可查询日志
- [ ] 日志标签正确设置

### 性能验证
- [ ] 监控系统资源使用合理
- [ ] 指标收集不影响应用性能
- [ ] Grafana仪表板加载速度正常
- [ ] 告警响应时间及时

---

## 🐛 故障排除

### 问题1: Prometheus目标状态DOWN
**症状**: Prometheus Web界面显示目标DOWN
**解决方案**:
```bash
# 检查目标服务是否运行
docker ps | grep backend

# 检查metrics端点
curl http://backend:8000/metrics

# 检查网络连接
docker exec prometheus ping backend

# 查看Prometheus日志
docker logs prometheus | grep backend
```

### 问题2: Grafana无法连接数据源
**症状**: Grafana显示数据源连接失败
**解决方案**:
```bash
# 检查Prometheus是否运行
curl http://localhost:9090/api/v1/status

# 检查网络连接
docker exec grafana ping prometheus

# 重新配置数据源
curl -u admin:admin -X POST http://localhost:3001/api/datasources \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Prometheus",
    "type": "prometheus",
    "url": "http://prometheus:9090",
    "access": "proxy",
    "isDefault": true
  }'
```

### 问题3: 告警未触发
**症状**: 测试条件下告警未触发
**解决方案**:
```bash
# 检查告警规则加载
curl http://localhost:9090/api/v1/rules | jq '.'

# 检查告警状态
curl http://localhost:9090/api/v1/alerts | jq '.'

# 验证Alertmanager连接
curl http://localhost:9093/api/v1/status

# 测试告警规则
curl 'http://localhost:9090/api/v1/query?query=up{job="backend"}' | jq '.'
```

### 问题4: 日志未收集
**症状**: Loki中无日志数据
**解决方案**:
```bash
# 检查Promtail配置
docker exec promtail cat /etc/promtail/config.yml

# 检查日志文件路径
docker exec promtail ls -la /var/lib/docker/containers/

# 测试Loki连接
docker exec promtail curl http://loki:3100/ready

# 查看Promtail日志
docker logs promtail | tail -50
```

---

## 📈 监控最佳实践

### 1. 分层监控
- **基础设施层**: CPU、内存、磁盘、网络
- **容器层**: 容器状态、资源使用
- **应用层**: API性能、业务指标
- **用户层**: 用户体验、业务结果

### 2. 告警策略
- **P0告警**: 服务宕机、数据丢失 (立即处理)
- **P1告警**: 性能下降、错误率上升 (1小时内)
- **P2告警**: 资源预警、趋势异常 (当天处理)
- **P3告警**: 优化建议、容量规划 (每周review)

### 3. 仪表板设计
- **执行仪表板**: 用于日常运维，关键指标一目了然
- **分析仪表板**: 用于问题排查，详细信息展示
- **业务仪表板**: 用于业务分析，业务指标跟踪
- **系统仪表板**: 用于容量规划，长期趋势分析

### 4. 性能优化
- **合理设置采样率**: 关键指标高频，辅助指标低频
- **使用记录规则**: 预计算复杂查询，提高仪表板性能
- **数据保留策略**: 高精度数据短保留，低精度数据长保留
- **标签基数控制**: 避免高基数标签，如用户ID、请求ID

---

## 📅 时间估算

| 阶段 | 预计时间 | 实际时间 | 状态 |
|------|----------|----------|------|
| 基础监控启动 | 2小时 | - | 待开始 |
| 应用指标集成 | 3小时 | - | 待开始 |
| Grafana仪表板配置 | 2小时 | - | 待开始 |
| 告警配置 | 2小时 | - | 待开始 |
| 日志聚合 | 2小时 | - | 待开始 |
| 监控验证 | 1小时 | - | 待开始 |
| **总计** | **12小时** | - | **待开始** |

---

## 🎯 预期效果

### 运维效率提升
- ✅ **主动监控**: 问题发现时间从小时级降到分钟级
- ✅ **快速定位**: 故障定位时间减少50%
- ✅ **趋势分析**: 容量规划和性能优化有数据支撑
- ✅ **自动化告警**: 关键问题自动通知，减少人工巡检

### 系统可靠性提升
- ✅ **性能监控**: 及时发现性能瓶颈
- ✅ **资源优化**: 合理分配资源使用
- ✅ **容量规划**: 基于历史数据预测未来需求
- ✅ **业务洞察**: 了解用户行为和业务趋势

---

## 📞 联系信息

**实施负责人**: DevOps Agent (29126157-6833-4f1e-94bd-6493bd95d3f2)
**技术支持**: Backend Team
**运维团队**: Operations Team

---

**文档版本**: v1.0
**最后更新**: 2026-04-17 11:00
**下次评审**: 监控系统上线后
