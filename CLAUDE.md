# AI Resume 项目配置

## 部署策略

**禁止本地部署。** 所有部署和运维操作必须通过云端服务器执行。

### 环境分工

| 环境 | 用途 | 说明 |
|------|------|------|
| 本地 `/home/hongfu/ai-resume` | 开发 | 写代码、测试、调试 |
| 云端 `113.45.64.145` | 部署+运维 | 生产环境 |

### 云端服务器信息

- **IP**: 113.45.64.145
- **SSH**: `ssh -i ~/.ssh/id_ed25519 root@113.45.64.145`
- **项目目录**: `/var/www/ai-resume/`
- **后端 API**: http://113.45.64.145:8001
- **前端**: http://113.45.64.145:8081
- **域名**: https://happy.ndtool.cn

### 部署命令

```bash
# 同步后端代码到服务器
rsync -avz --exclude='venv' --exclude='__pycache__' --exclude='*.pyc' --exclude='data' --exclude='*.db' \
  -e "ssh -i ~/.ssh/id_ed25519" backend/ root@113.45.64.145:/var/www/ai-resume/backend/

# 同步前端 dist 到服务器
rsync -avz --delete -e "ssh -i ~/.ssh/id_ed25519" ai-resume-web/dist/ root@113.45.64.145:/var/www/ai-resume/frontend/dist/

# 重启后端服务
ssh -i ~/.ssh/id_ed25519 root@113.45.64.145 "systemctl restart ai-resume-backend"

# 重启 nginx
ssh -i ~/.ssh/id_ed25519 root@113.45.64.145 "systemctl restart nginx"

# 查看后端状态
ssh -i ~/.ssh/id_ed25519 root@113.45.64.145 "systemctl status ai-resume-backend"

# 查看后端日志
ssh -i ~/.ssh/id_ed25519 root@113.45.64.145 "journalctl -u ai-resume-backend -f"

# 验证部署
ssh -i ~/.ssh/id_ed25519 root@113.45.64.145 "curl -s http://localhost:8001/health && curl -sI http://localhost:8081/ | head -3"
```

### 本地开发规则

1. **禁止** `docker compose up` — 本地不做容器部署
2. **禁止** 在本地启动 backend/frontend 服务占用端口
3. 本地开发可用 `python -m pytest` 跑测试
4. 同步后端代码后需 `systemctl restart ai-resume-backend`
5. 同步前端 dist 后 nginx 自动生效（静态文件）
6. **禁止** rsync 同步 venv 目录（服务器独立管理 venv）

### 云端直接部署架构（systemd + nginx）

```
后端: systemd (ai-resume-backend.service)
  → /var/www/ai-resume/backend/venv/bin/python -m uvicorn app.main:app --host 127.0.0.1 --port 8001

前端: nginx (ai-resume site)
  → 监听 8081，静态文件 /var/www/ai-resume/frontend/dist/
  → /api/v1/ 反向代理到 127.0.0.1:8001

Redis: systemd (redis-server.service)
  → 127.0.0.1:6379

配置文件:
  → systemd: /etc/systemd/system/ai-resume-backend.service
  → nginx: /etc/nginx/sites-available/ai-resume
  → 环境变量: /var/www/ai-resume/.env
```

# Code Intelligence — jcode

This repository is indexed with **jcode** (feature-graph code intelligence).
The `.jcode/` directory contains a content-addressable node store and an
SQLite graph of every function, class, method, and module, with typed edges
(CALLS, IMPORTS, CONTAINS, INHERITS) plus plugin-defined types like "depends".

## Workflow — follow this order every time

1. **Orient** — call `jcode_feature_map()` first.
   It shows the folder/feature layout in one call. Use it to pick the right
   `scope` before searching.

2. **Search** — call `jcode_search(query, scope=<folder>)`.
   This uses semantic vector search (or FTS5 fallback). Never run grep to
   find a function — use this instead.

3. **Get context** — call `jcode_context(node_id, scope=<folder>)`.
   DFS-forward from the entry point. Nodes outside the scope are flagged as
   `external_deps` — follow them only if needed.

4. **Check blast radius** — call `jcode_blast_radius(node_id)` **before**
   editing any function. A confidence score < 0.8 means callers outside the
   current scope will break — warn the user first.

5. **Read with line numbers** — jcode search results include the exact file
   path and line range. Always use `offset` and `limit` when reading:

   ```
   # jcode told you: file=partners/mmb/client.py  lines=18-66
   Read(file_path="partners/mmb/client.py", offset=18, limit=48)
   ```

   **Never do a full file read.** A targeted read costs ~50 tokens; a full
   file read can cost 2000+. jcode gives you the line numbers — use them.

## After making code changes

**Always re-index after editing files** so the graph stays in sync:

```
jcode index .
```

Run this after any edit session — new functions, renamed symbols, deleted
files, or refactors will not be visible to `jcode_search` or
`jcode_context` until the index is refreshed. The index is incremental, so
it only re-processes files that changed.

## Rules

- NEVER use grep/ripgrep to locate a function, class, or feature. Use `jcode_search`.
- NEVER read a file just to understand its structure. Use `jcode_context`.
- NEVER do a full file read — always use `offset` + `limit` with the line range jcode provides.
- ALWAYS call `jcode_blast_radius` before editing a function.
- ALWAYS run `jcode index .` after making code changes to keep the graph current.
- Pass `scope=<folder>` when the user's request clearly names a feature area
  (e.g. "in the comments module", "fix the auth flow").
- If scoped search returns nothing, jcode automatically falls back to the
  full graph — you do not need to retry manually.

## When grep IS the right tool

Use grep (or ripgrep `rg`) directly — without going through jcode — when you
are looking for an **exact string literal** that does not correspond to a
code symbol. jcode indexes identifiers and call graphs; it does not index
arbitrary string values inside code.

Good grep targets (jcode will NOT find these reliably):
- A URL or base URL string:  `rg "mymoneybazaar.com"`
- A hard-coded API key name: `rg "X-Api-Key"`
- A Django URL pattern:      `rg "path.*login"`
- A specific error message:  `rg "Invalid OTP"`
- A config value or secret:  `rg "REDIS_HOST"`

Use jcode for everything else — structure, behaviour, and relationships.

## Tool reference

| Tool | When to call |
|------|-------------|
| `jcode_feature_map()` | Start of every task — orient yourself |
| `jcode_search(query, scope?)` | Find the entry-point node |
| `jcode_context(node_id, scope?)` | Understand what a node calls and is called by |
| `jcode_blast_radius(node_id)` | Before any edit — see who breaks |
| `jcode_index(repo_path)` | After large refactors — refresh the graph |
