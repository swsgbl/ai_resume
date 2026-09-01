# 安全策略 (Security Policy)

## 支持的安全版本

本项目遵循负责任的漏洞披露流程。以下是当前支持的安全版本：

- **主分支**: `main` - 接收安全更新
- **最新稳定版本**: 所有标签版本

## 漏洞报告流程

### 报告安全问题

如果您发现安全漏洞，**请不要**创建公开的 issue。

**请通过以下方式报告**：

1. **邮件**: security@yourdomain.com
2. **GitHub Security Advisory**: 使用 GitHub 的 [Private Vulnerability Reporting](https://github.com/your-org/ai-resume/security/advisories) 功能

### 报告内容应包含

- 漏洞描述
- 受影响的版本
- 复现步骤
- 潜在影响
- 建议的修复方案（如有）

### 响应承诺

- **确认时间**: 48 小时内确认收到报告
- **初步评估**: 7 个工作日内完成初步评估
- **修复时间**: 根据严重程度，在合理时间内修复
- **公开披露**: 修复发布后公开披露漏洞详情

## 漏洞严重程度分类

| 级别 | 描述 | 示例 |
|------|------|------|
| 🔴 **严重** | 可远程执行代码、数据泄露 | SQL注入、RCE、认证绕过 |
| 🟠 **高危** | 重要功能受损、敏感数据暴露 | XSS、CSRF、权限提升 |
| 🟡 **中危** | 功能受限、部分数据泄露 | DoS、信息泄露 |
| 🟢 **低危** | 轻微影响 | 配置错误、日志泄露 |

## 安全最佳实践

### 环境变量

生产环境**必须**设置以下环境变量：

```bash
# 安全密钥（使用强随机密钥）
SECRET_KEY=your_32_character_random_key_here
JWT_SECRET=your_32_character_random_key_here

# CORS 配置（限制为实际域名）
CORS_ORIGINS=https://yourdomain.com,https://www.yourdomain.com

# 数据库连接
DATABASE_URL=mysql+aiomysql://user:password@host:3306/dbname
```

### 密钥生成

生成安全密钥：

```bash
python -c "import secrets; print(secrets.token_urlsafe(32))"
```

### CORS 配置

**开发环境**:
```bash
CORS_ORIGINS=http://localhost:3000,http://localhost:5173
```

**生产环境**（禁止使用通配符）:
```bash
CORS_ORIGINS=https://yourdomain.com,https://www.yourdomain.com
```

### Docker 部署安全

1. **不要**在 `docker-compose.yml` 中硬编码密钥
2. 使用 `.env` 文件或 secrets manager
3. 确保 `.env` 文件不提交到版本控制
4. 定期更新基础镜像

```bash
# .gitignore 应包含：
.env
*.key
*.pem
```

## 依赖安全

### 依赖更新

- 定期更新依赖包
- 关注安全公告（CVE）
- 使用自动化工具检查漏洞

### 安全工具

项目使用以下安全工具：

- **pip-audit**: Python 依赖漏洞扫描
- **safety**: 安全策略检查
- **bandit**: 代码安全检查

运行安全检查：

```bash
# 后端安全扫描
cd backend
pip-audit
safety check
bandit -r app/
```

## 常见安全问题

### 1. CORS 配置错误

❌ **错误配置**:
```python
CORS_ORIGINS=["*"]  # 允许所有来源
```

✅ **正确配置**:
```python
CORS_ORIGINS=["https://yourdomain.com"]
```

### 2. 硬编码密钥

❌ **错误做法**:
```python
SECRET_KEY="48f5ff7d1aa60c67f2a48636b4ee450fce688f9816f66dea152aa66745916ba9"
```

✅ **正确做法**:
```python
SECRET_KEY=os.getenv("SECRET_KEY")
```

### 3. 数据库连接

❌ **错误做法**:
```python
DATABASE_URL="mysql://root:password@localhost/db"
```

✅ **正确做法**:
```python
DATABASE_URL=os.getenv("DATABASE_URL")
```

## 安全更新通知

- **GitHub Dependabot**: 自动创建 PR 更新依赖
- **Security Advisories**: 发布安全公告
- **Release Notes**: 标注安全修复

## 合规性

本项目遵循以下安全标准：

- **OWASP Top 10**: Web 应用安全风险
- **CWE**: 通用弱点枚举
- **CVE**: 通用漏洞披露

## 联系方式

- **安全团队邮箱**: security@yourdomain.com
- **PGP 公钥**: [下载 PGP 公钥](https://yourdomain.com/pgp-key.asc)

## 许可

本安全策略遵循 [Creative Commons CC BY 4.0](https://creativecommons.org/licenses/by/4.0/) 许可。
