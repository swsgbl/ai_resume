# 变更日志 (CHANGELOG)

## [2026-05-13] 基础设施重大变更 + Paperclip 全面维护

### 基础设施：Docker → 直接部署迁移

**变更类型**: 架构重构 (BREAKING)

将 AI Resume Platform 从 Docker 容器部署迁移为系统级直接部署。

| 组件 | 迁移前 | 迁移后 |
|------|--------|--------|
| Backend (FastAPI) | Docker 容器 (`ai-resume-backend`) | systemd 服务 (`ai-resume-backend.service`) |
| Frontend (Nginx) | Docker 容器 (`ai-resume-frontend`) | 系统 Nginx (`/etc/nginx/sites-available/ai-resume`) |
| Redis | Docker 容器 (`ai-resume-redis`) | 系统服务 (`redis-server.service`) |
| 域名路由+SSL | Dokploy (Traefik) | Dokploy 仅保留 Traefik (路由指向 `172.17.0.1:8081`) |

**新增文件/配置**:
- `/etc/systemd/system/ai-resume-backend.service` — Backend systemd 服务
- `/etc/nginx/sites-available/ai-resume` — Nginx 前端+API反代配置
- `/var/www/ai-resume/backend/venv/` — Python 3.12 虚拟环境

**变更文件**:
- `/var/www/ai-resume/.env` — `REDIS_URL` 从 `redis://ai-resume-redis:6379/0` 改为 `redis://localhost:6379/0`
- `/etc/dokploy/traefik/dynamic/ai-resume.yml` — 路由目标从 `http://ai-resume-frontend:80` 改为 `http://172.17.0.1:8081`

**删除资源**:
- Docker 容器: `ai-resume-backend`, `ai-resume-frontend`, `ai-resume-redis`
- Docker 镜像: `ai-resume-ai-resume-backend:latest` (1.98G), `nginx:alpine` (62M)
- Docker 网络: `ai-resume_ai-resume-network`

**资源回收**:
- 磁盘: 35G/50G (74%) → 31G/50G (66%), 释放约 4G
- 内存: Dokploy 容器内存从 830MiB 降至 820MiB

**服务管理命令变更**:
```bash
# 旧 (Docker)
docker compose -f /var/www/ai-resume/docker-compose.yml restart backend
docker logs ai-resume-backend --tail 50

# 新 (systemd)
systemctl restart ai-resume-backend
journalctl -u ai-resume-backend -f
```

### 安全漏洞修复 (resource-activation-site)

**仓库**: `18606559294/resource-activation-site`

| CVE | 包名 | 旧版本 | 新版本 | 严重程度 |
|-----|------|--------|--------|----------|
| CVE-2026-44728 | @babel/plugin-transform-modules-systemjs | 7.25.9 | 7.29.4 | High |
| CVE-2026-6321 | fast-uri (路径遍历) | 3.0.6 | 3.1.2 | High |
| CVE-2026-6322 | fast-uri (主机混淆) | 3.0.6 | 3.1.2 | High |

- 提交: `951d8c2` — 推送到 atomgit.com
- 构建: Vite build (750ms)
- 部署: 已同步到 `/var/www/ndtool/resources/`，HTTP 200 验证通过

### 云服务器磁盘清理

| 清理项 | 释放空间 |
|--------|----------|
| journal 日志 (32个归档文件) | 1.3G |
| hostguard 旧日志 | ~90M |
| /tmp 临时文件 | ~242M |
| apt 缓存 | ~122M |
| 压缩日志 (.gz/.1/.old) | ~100M |
| Docker 无用镜像 | ~2G |
| **总计** | **~4G** |

磁盘使用: 35G/50G (74%) → 31G/50G (66%)

### Paperclip AI 公司维护

**版本**: 2026.512.0 (最新)
**实例**: default @ http://127.0.0.1:3100
**公司**: 智能体AI简历 (AIAAAA)

#### 1. Paperclip 重启
- 应用 39 个待处理的数据库迁移
- 9 项健康检查全部通过
- OpenClaw Gateway 运行正常 (port 18789)

#### 2. Agent 上下文重置
所有 14 个 Agent 的运行时状态已重置：
- Session ID 清空
- Token 计数器归零
- 错误状态清除

| Agent | 重置前 Token 使用 | 重置前状态 | 重置后状态 |
|-------|-------------------|-----------|-----------|
| DevOps工程师 | 22.8M input | running | idle |
| CTO | 12.9M input | running | idle |
| CEO | 7.8M input | running | idle |
| CMO | 6.8M input (429错误) | error | idle |
| 前端工程师 | 5.5M input | running | idle |
| 鸿蒙开发工程师 | 5.3M input (429错误) | error | idle |
| 后端工程师 | 5.2M input (500错误) | error | idle |
| CPO | 4.8M input | running | idle |

#### 3. 数据库清理
- 清理 2965 条过期 heartbeat_runs (7天前)
- 清理 8917 条 heartbeat_run_events
- 清理 2648 条 activity_log
- 清理 9 条 agent_task_sessions
- 数据库大小: 98MB

#### 4. Issue 清理
关闭 9 个过期/无效 Issue：
- "Create and configure Supabase project" → done (不需要，用SQLite)
- "Phase 1.1 Completed: NTFS to Linux Migration" → done
- "鸿蒙开发工程师智能体创建配置" → done (已完成)
- "Hire and onboard additional engineers" → done (暂不需要)
- "Recover stalled issue AIAAAA-36" → done
- "Recover stalled issue AIAAAA-37" → done
- "Phase 4: Dokploy 生产环境部署" → done (直接部署替代)

更新 Goals 状态：
- Phase 4: Dokploy 生产环境部署 → done

#### 5. 新任务分配 (8个)

| 部门 | 任务 | 优先级 |
|------|------|--------|
| CTO | Phase 3: 测试体系建设 - 制定测试策略 | high |
| CMO | Phase 5: 市场推广启动 - 制定推广计划 | high |
| CPO | 产品路线图更新与优先级评审 | high |
| DevOps工程师 | 监控直接部署架构的系统稳定性 | high |
| 后端工程师 | 后端API集成测试编写 | high |
| 前端工程师 | 前端组件单元测试编写 | medium |
| 鸿蒙开发工程师 | Phase 7: 鸿蒙应用核心功能完善 | high |
| 产品经理 | Phase 6: 付费转化功能设计 | medium |
| 运营经理 | 用户运营策略和留存方案 | medium |

#### 6. 基础设施变更同步 Issue
- 创建 Issue "基础设施变更同步：Docker→直接部署 + 安全修复"
- 分配给 CEO (a6f37e82)，状态 in_progress
- 包含完整变更说明供各部门参考

---

## [2026-05-13] DevOps 监控轮次 #1452

- 服务器运行时间: 23天5小时 (557H)
- 系统负载: 0.02, 0.02, 0.00
- 所有 7 个 Docker 容器运行正常
- Backend: HTTP 200, 3.2ms
- Frontend: HTTP 200, 0.9ms
- 磁盘: 70% (清理后)
- DEVOPS_LIVE_STATUS.md 已更新
