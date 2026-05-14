# AI Resume 开发日志

## [2026-05-14] 认证系统修复 + 直接部署上线

### 修复

- **注册后无法登录**: `is_verified` 默认 `False`，注册时改为 `True`，移除登录时的邮箱验证阻断
- **CORS 跨域问题**: 添加 `127.0.0.1:5173` 等地址到 `CORS_ORIGINS`（之前只有 `localhost`）
- **SMS 登录缺少 sms_token**: `VerificationCodeInput` 组件未将发送验证码返回的 `sms_token` 传递给登录请求
  - 新增 `onSmsTokenChange` 回调属性
  - `UnifiedLoginPage` 新增 `smsToken` 状态，传递给登录 API
- **手机登录误导文案**: "未注册手机号将自动创建账号" 改为 "未注册手机号请先注册账号"
- **Dockerfile pip 超时**: 国内服务器访问 pypi.org 超时，添加清华 apt + pip 镜像源

### 架构变更

- **部署方式从 Docker 迁移到 systemd + nginx 直接部署**
  - 后端: systemd `ai-resume-backend.service` (uvicorn on 127.0.0.1:8001)
  - 前端: nginx 直接服务 `/var/www/ai-resume/frontend/dist/` (listen 8081)
  - API 代理: nginx `/api/v1/` → `127.0.0.1:8001`
  - Redis: 系统 `redis-server.service` (127.0.0.1:6379)
  - 原因: Docker 构建在国内服务器网络不稳定，直接部署更轻量可靠

### 测试

- 前端: 35 个测试文件，393 tests passed，3 skipped
- 后端: 18/18 认证 API 测试通过
- 生产环境验证: 注册、登录、SMS 发送、前端页面、nginx 代理全部通过

### 文件变更

| 文件 | 变更 |
|------|------|
| `backend/Dockerfile` | 添加清华镜像源 |
| `backend/app/core/config.py` | CORS 添加 127.0.0.1 域名 |
| `ai-resume-web/src/components/VerificationCodeInput.tsx` | 新增 `onSmsTokenChange` 回调 |
| `ai-resume-web/src/pages/UnifiedLoginPage.tsx` | 添加 `smsToken` 状态，修复误导文案 |
| `CLAUDE.md` | 更新部署架构为 systemd + nginx |
| `docs/FULL-DIAGNOSTIC-REPORT-20260514.md` | 添加部署方式变更记录 |

### 服务器配置

| 文件 | 说明 |
|------|------|
| `/etc/systemd/system/ai-resume-backend.service` | 后端 systemd 服务 |
| `/etc/nginx/sites-available/ai-resume` | nginx 配置 (8081 端口) |
| `/var/www/ai-resume/.env` | 环境变量（密钥、数据库、AI 配置） |
| `/var/www/ai-resume/backend/venv/` | Python 虚拟环境（服务器本地） |

---

## [2026-05-14] CI/CD 流水线修复

### 修复

- npm/pnpm 不匹配: 改用 pnpm
- Node.js 20 弃用: 升级到 22
- Python 升级到 3.12
- 通知步骤添加 `continue-on-error`
- 移除无法工作的 MySQL service（测试用 SQLite）
- 跳过依赖外部凭证的测试（微信、小米、模板增强）

---

## [2026-05-14] DevOps 基础设施搭建

### 完成

- 云端服务器环境调研和诊断
- Dokploy (PaaS) 配置和修复
- SSH 密钥配置
- Docker Compose 配置（后迁移为直接部署）
- 部署策略文档和验证脚本

---

## 待完成事项

### 必须配置
- [ ] 阿里云短信模板 `SMS_TEMPLATE_CODE`
- [ ] Google/GitHub/Gitee/Discord OAuth Client ID/Secret
- [ ] 各平台 Redirect URI 更新为生产域名

### 功能开发
- [ ] 前端修改密码功能（后端 API 已存在）
- [ ] PDF/Word 导出功能
- [ ] AI 服务配置页面
- [ ] 重复注册防护

### 运维
- [ ] HTTPS / SSL 证书配置
- [ ] 域名绑定 (happy.ndtool.cn)
- [ ] Redis 用于 SMS token 持久化
