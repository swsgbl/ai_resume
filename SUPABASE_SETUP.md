# Supabase 项目设置指南

> **注意**: 此文档用于生产环境 Supabase 配置。本地开发继续使用 MySQL。

## 📋 前置准备

在开始之前，请确保您有：
- [ ] Supabase 账号 (https://supabase.com/dashboard)
- [ ] 项目名称（建议: `ai-resume-prod`）
- [ ] 选择的区域（建议: `Southeast Asia (Singapore)` 以服务中国用户）

---

## 🚀 步骤 1: 创建 Supabase 项目

1. 访问 https://supabase.com/dashboard
2. 点击 "New Project"
3. 填写项目信息：
   - **Name**: `ai-resume-prod` (或您喜欢的名称)
   - **Database Password**: 生成强密码并保存到密码管理器
   - **Region**: `Southeast Asia (Singapore)`
4. 点击 "Create new project"
5. 等待项目创建完成（约 2-3 分钟）

---

## 🗄️ 步骤 2: 配置数据库架构

### 2.1 在 SQL Editor 中运行以下 SQL

1. 进入 Supabase Dashboard
2. 左侧菜单点击 `SQL Editor`
3. 点击 `New Query`
4. 粘贴并运行以下 SQL：

```sql
-- ============================================
-- AI Resume Platform - 数据库架构
-- ============================================

-- 用户表
CREATE TABLE IF NOT EXISTS users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email VARCHAR(255) UNIQUE NOT NULL,
    username VARCHAR(100),
    phone VARCHAR(20),
    hashed_password VARCHAR(255),
    is_active BOOLEAN DEFAULT TRUE,
    is_verified BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 简历表
CREATE TABLE IF NOT EXISTS resumes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    title VARCHAR(255) NOT NULL,
    template_id INTEGER,
    content JSONB,
    is_public BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 简历版本表
CREATE TABLE IF NOT EXISTS resume_versions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    resume_id UUID REFERENCES resumes(id) ON DELETE CASCADE,
    content JSONB,
    version_name VARCHAR(100),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 模板表
CREATE TABLE IF NOT EXISTS templates (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    category VARCHAR(100),
    description TEXT,
    preview_url TEXT,
    content JSONB,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 收藏表
CREATE TABLE IF NOT EXISTS favorites (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    resume_id UUID REFERENCES resumes(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(user_id, resume_id)
);

-- 操作日志表
CREATE TABLE IF NOT EXISTS operation_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE SET NULL,
    action VARCHAR(100) NOT NULL,
    resource_type VARCHAR(50),
    resource_id UUID,
    details JSONB,
    ip_address INET,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- AI 使用记录表
CREATE TABLE IF NOT EXISTS ai_usage (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE SET NULL,
    provider VARCHAR(50) NOT NULL,
    model VARCHAR(100),
    tokens_used INTEGER,
    cost DECIMAL(10, 6),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 创建索引
CREATE INDEX IF NOT EXISTS idx_resumes_user_id ON resumes(user_id);
CREATE INDEX IF NOT EXISTS idx_resume_versions_resume_id ON resume_versions(resume_id);
CREATE INDEX IF NOT EXISTS idx_favorites_user_id ON favorites(user_id);
CREATE INDEX IF NOT EXISTS idx_operation_logs_user_id ON operation_logs(user_id);
CREATE INDEX IF NOT EXISTS idx_operation_logs_created_at ON operation_logs(created_at);
CREATE INDEX IF NOT EXISTS idx_ai_usage_user_id ON ai_usage(user_id);

-- 创建更新时间触发器函数
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- 为需要的表添加更新时间触发器
CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_resumes_updated_at BEFORE UPDATE ON resumes
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
```

---

## 🔐 步骤 3: 配置 Row Level Security (RLS)

```sql
-- ============================================
-- 行级安全策略 (RLS)
-- ============================================

-- 启用 RLS
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE resumes ENABLE ROW LEVEL SECURITY;
ALTER TABLE resume_versions ENABLE ROW LEVEL SECURITY;
ALTER TABLE favorites ENABLE ROW LEVEL SECURITY;
ALTER TABLE operation_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE ai_usage ENABLE ROW LEVEL SECURITY;

-- 用户策略：用户只能查看和修改自己的数据
CREATE POLICY "Users can view own profile" ON users
    FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Users can update own profile" ON users
    FOR UPDATE USING (auth.uid() = id);

-- 简历策略：用户只能操作自己的简历
CREATE POLICY "Users can view own resumes" ON resumes
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own resumes" ON resumes
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own resumes" ON resumes
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own resumes" ON resumes
    FOR DELETE USING (auth.uid() = user_id);

-- 公开简历策略
CREATE POLICY "Public resumes are viewable by all" ON resumes
    FOR SELECT USING (is_public = true);

-- 其他表的类似策略...
CREATE POLICY "Users can manage own favorites" ON favorites
    FOR ALL USING (auth.uid() = user_id);

CREATE POLICY "Users can view own operation logs" ON operation_logs
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can view own ai usage" ON ai_usage
    FOR SELECT USING (auth.uid() = user_id);
```

---

## 🔑 步骤 4: 获取 API 密钥

1. 在 Supabase Dashboard 左侧菜单点击 `Settings` → `API`
2. 复制以下信息：

| 配置项 | 获取位置 | 用途 |
|--------|----------|------|
| `SUPABASE_URL` | Project URL | API 端点 |
| `SUPABASE_ANON_KEY` | anon/public key | 前端使用 |
| `SUPABASE_SERVICE_ROLE_KEY` | service_role key | 后端使用 |

---

## 📧 步骤 5: 配置认证 (可选)

### 5.1 邮箱认证

1. 进入 `Authentication` → `Settings`
2. 确认 `Enable Email provider` 已开启
3. 配置邮件模板（可选）

### 5.2 Google OAuth (可选)

1. 进入 `Authentication` → `Providers`
2. 启用 `Google` provider
3. 需要提供 Google Client ID 和 Secret

### 5.3 GitHub OAuth (可选)

1. 进入 `Authentication` → `Providers`
2. 启用 `GitHub` provider
3. 需要提供 GitHub Client ID 和 Secret

---

## 📦 步骤 6: 配置存储 (可选，用于头像/文件上传)

1. 进入 `Storage` → `New bucket`
2. 创建名为 `avatars` 的 bucket
3. 设置为 Public 或 Private 根据需求

---

## 🔧 步骤 7: 更新环境变量

将获取的密钥添加到环境配置文件：

```bash
# 前端 .env.local
NEXT_PUBLIC_SUPABASE_URL=https://xxxxx.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...

# 后端 .env.production
SUPABASE_URL=https://xxxxx.supabase.co
SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
SUPABASE_SERVICE_ROLE_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

---

## ✅ 验证清单

完成后，请验证：

- [ ] Supabase 项目创建成功
- [ ] 数据库表创建成功（可以在 Table Editor 中查看）
- [ ] RLS 策略已启用
- [ ] API 密钥已获取并安全存储
- [ ] 环境变量已更新
- [ ] 应用可以连接到 Supabase

---

## 📚 相关资源

- [Supabase 文档](https://supabase.com/docs)
- [Row Level Security 指南](https://supabase.com/docs/guides/auth/row-level-security)
- [存储指南](https://supabase.com/docs/guides/storage)

---

## 🆘 故障排除

### 问题: 连接超时
- 检查区域选择，选择最近的区域
- 检查防火墙设置

### 问题: RLS 策略阻止访问
- 临时禁用 RLS 测试: `ALTER TABLE users DISABLE ROW LEVEL SECURITY;`
- 检查策略逻辑是否正确

### 问题: 认证失败
- 确认 Email provider 已启用
- 检查 JWT 设置
