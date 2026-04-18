# AI Resume API 文档

## 概述

AI Resume是一个基于FastAPI的智能简历生成平台，提供简历创建、编辑、AI生成、导出等功能。

**基础URL**: `https://api.ai-resume.com/api/v1`  
**API版本**: v1  
**认证方式**: JWT Bearer Token

---

## 目录

- [认证](#认证)
- [用户管理](#用户管理)
- [简历管理](#简历管理)
- [AI生成](#ai生成)
- [模板管理](#模板管理)
- [导出任务](#导出任务)
- [JD匹配](#jd匹配)
- [面试预测](#面试预测)

---

## 认证

### 注册用户

**POST** `/auth/register`

注册新用户账户。

**请求体**:
```json
{
  "email": "user@example.com",
  "password": "SecurePass123!",
  "username": "johndoe"
}
```

**响应** (201 Created):
```json
{
  "message": "注册成功",
  "user": {
    "id": 1,
    "email": "user@example.com",
    "username": "johndoe",
    "created_at": "2026-04-19T00:00:00Z"
  }
}
```

### 用户登录

**POST** `/auth/login`

用户登录获取访问令牌。

**请求体**:
```json
{
  "username": "user@example.com",
  "password": "SecurePass123!"
}
```

**响应** (200 OK):
```json
{
  "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "token_type": "bearer",
  "expires_in": 86400,
  "user": {
    "id": 1,
    "email": "user@example.com",
    "username": "johndoe"
  }
}
```

### 刷新令牌

**POST** `/auth/refresh`

刷新访问令牌。

**请求头**:
```
Authorization: Bearer <access_token>
```

**响应** (200 OK):
```json
{
  "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "token_type": "bearer",
  "expires_in": 86400
}
```

---

## 用户管理

### 获取当前用户信息

**GET** `/users/me`

获取当前登录用户的详细信息。

**请求头**:
```
Authorization: Bearer <access_token>
```

**响应** (200 OK):
```json
{
  "id": 1,
  "email": "user@example.com",
  "username": "johndoe",
  "created_at": "2026-04-19T00:00:00Z",
  "subscription_tier": "free"
}
```

### 更新用户信息

**PUT** `/users/me`

更新当前用户信息。

**请求头**:
```
Authorization: Bearer <access_token>
```

**请求体**:
```json
{
  "username": "newusername"
}
```

**响应** (200 OK):
```json
{
  "id": 1,
  "email": "user@example.com",
  "username": "newusername",
  "updated_at": "2026-04-19T01:00:00Z"
}
```

### 修改密码

**POST** `/users/change-password`

修改用户密码。

**请求头**:
```
Authorization: Bearer <access_token>
```

**请求体**:
```json
{
  "old_password": "OldPass123!",
  "new_password": "NewPass456!"
}
```

**响应** (200 OK):
```json
{
  "message": "密码修改成功"
}
```

---

## 简历管理

### 创建简历

**POST** `/resumes`

创建新简历。

**请求头**:
```
Authorization: Bearer <access_token>
```

**请求体**:
```json
{
  "title": "我的第一份简历",
  "template_id": 1,
  "data": {
    "basics": {
      "name": "张三",
      "email": "zhangsan@example.com",
      "phone": "+86 138 0000 0000",
      "location": "北京市"
    },
    "education": [],
    "experience": [],
    "skills": []
  }
}
```

**响应** (201 Created):
```json
{
  "id": 1,
  "title": "我的第一份简历",
  "template_id": 1,
  "created_at": "2026-04-19T00:00:00Z",
  "updated_at": "2026-04-19T00:00:00Z"
}
```

### 获取简历列表

**GET** `/resumes`

获取用户的所有简历。

**请求头**:
```
Authorization: Bearer <access_token>
```

**查询参数**:
- `page` (int, 可选): 页码，默认1
- `limit` (int, 可选): 每页数量，默认20

**响应** (200 OK):
```json
{
  "total": 5,
  "page": 1,
  "limit": 20,
  "items": [
    {
      "id": 1,
      "title": "我的第一份简历",
      "template_id": 1,
      "created_at": "2026-04-19T00:00:00Z",
      "updated_at": "2026-04-19T00:00:00Z"
    }
  ]
}
```

### 获取简历详情

**GET** `/resumes/{resume_id}`

获取指定简历的详细信息。

**请求头**:
```
Authorization: Bearer <access_token>
```

**响应** (200 OK):
```json
{
  "id": 1,
  "title": "我的第一份简历",
  "template_id": 1,
  "data": {
    "basics": {...},
    "education": [...],
    "experience": [...],
    "skills": [...]
  },
  "created_at": "2026-04-19T00:00:00Z",
  "updated_at": "2026-04-19T00:00:00Z"
}
```

### 更新简历

**PUT** `/resumes/{resume_id}`

更新指定简历。

**请求头**:
```
Authorization: Bearer <access_token>
```

**请求体**: 同创建简历

**响应** (200 OK):
```json
{
  "id": 1,
  "title": "更新的简历",
  "updated_at": "2026-04-19T01:00:00Z"
}
```

### 删除简历

**DELETE** `/resumes/{resume_id}`

删除指定简历。

**请求头**:
```
Authorization: Bearer <access_token>
```

**响应** (204 No Content)

---

## AI生成

### AI生成简历内容

**POST** `/ai/generate`

使用AI生成简历内容。

**请求头**:
```
Authorization: Bearer <access_token>
```

**请求体**:
```json
{
  "resume_id": 1,
  "job_description": "高级前端工程师，要求精通React、TypeScript...",
  "provider": "xiaomi",
  "options": {
    "tone": "professional",
    "language": "zh-CN"
  }
}
```

**响应** (200 OK):
```json
{
  "task_id": "abc123",
  "status": "processing",
  "estimated_time": 30
}
```

### 获取AI生成结果

**GET** `/ai/tasks/{task_id}`

获取AI生成任务的结果。

**请求头**:
```
Authorization: Bearer <access_token>
```

**响应** (200 OK):
```json
{
  "task_id": "abc123",
  "status": "completed",
  "result": {
    "basics": {...},
    "summary": "经验丰富的前端工程师...",
    "skills": [...]
  },
  "completed_at": "2026-04-19T00:30:00Z"
}
```

---

## 模板管理

### 获取模板列表

**GET** `/templates`

获取所有可用的简历模板。

**响应** (200 OK):
```json
{
  "total": 10,
  "items": [
    {
      "id": 1,
      "name": "专业简约",
      "description": "适合商务场景的专业模板",
      "thumbnail": "https://cdn.ai-resume.com/templates/1.png",
      "category": "professional",
      "is_free": true
    }
  ]
}
```

### 获取模板详情

**GET** `/templates/{template_id}`

获取指定模板的详细信息。

**响应** (200 OK):
```json
{
  "id": 1,
  "name": "专业简约",
  "description": "适合商务场景的专业模板",
  "thumbnail": "https://cdn.ai-resume.com/templates/1.png",
  "preview": "https://cdn.ai-resume.com/templates/1-preview.png",
  "category": "professional",
  "is_free": true,
  "sections": ["basics", "education", "experience", "skills"]
}
```

---

## 导出任务

### 创建导出任务

**POST** `/export`

创建简历导出任务（支持PDF、Word等格式）。

**请求头**:
```
Authorization: Bearer <access_token>
```

**请求体**:
```json
{
  "resume_id": 1,
  "format": "pdf",
  "options": {
    "watermark": false,
    "high_quality": true
  }
}
```

**响应** (201 Created):
```json
{
  "task_id": "export-123",
  "status": "processing",
  "estimated_time": 10
}
```

### 获取导出任务结果

**GET** `/export/tasks/{task_id}`

获取导出任务的结果。

**请求头**:
```
Authorization: Bearer <access_token>
```

**响应** (200 OK):
```json
{
  "task_id": "export-123",
  "status": "completed",
  "download_url": "https://cdn.ai-resume.com/exports/abc123.pdf",
  "expires_at": "2026-04-26T00:00:00Z",
  "file_size": 102400
}
```

---

## JD匹配

### 分析JD匹配度

**POST** `/jd-match`

分析简历与职位描述的匹配度。

**请求头**:
```
Authorization: Bearer <access_token>
```

**请求体**:
```json
{
  "resume_id": 1,
  "job_description": "职位描述内容..."
}
```

**响应** (200 OK):
```json
{
  "overall_score": 85,
  "match_details": {
    "skills_match": 90,
    "experience_match": 80,
    "education_match": 85
  },
  "suggestions": [
    "建议增加XX技能的描述",
    "可以补充XX项目经验"
  ]
}
```

---

## 面试预测

### 获取面试预测

**POST** `/interview-prediction`

基于简历和JD预测可能的面试问题。

**请求头**:
```
Authorization: Bearer <access_token>
```

**请求体**:
```json
{
  "resume_id": 1,
  "job_description": "职位描述内容..."
}
```

**响应** (200 OK):
```json
{
  "predicted_questions": [
    {
      "question": "请介绍一下你的React项目经验",
      "category": "技术问题",
      "difficulty": "中等"
    }
  ],
  "preparation_tips": [
    "复习React Hooks相关概念",
    "准备性能优化案例"
  ]
}
```

---

## 错误响应

所有API错误遵循统一格式：

**响应** (4xx/5xx):
```json
{
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "请求数据验证失败",
    "details": {
      "email": "邮箱格式不正确"
    }
  }
}
```

### 常见错误码

| 状态码 | 错误码 | 描述 |
|--------|--------|------|
| 400 | VALIDATION_ERROR | 请求数据验证失败 |
| 401 | UNAUTHORIZED | 未授权或令牌无效 |
| 403 | FORBIDDEN | 无权限访问 |
| 404 | NOT_FOUND | 资源不存在 |
| 429 | RATE_LIMIT_EXCEEDED | 请求过于频繁 |
| 500 | INTERNAL_ERROR | 服务器内部错误 |

---

## 速率限制

API调用受速率限制：

- **免费用户**: 100次/小时
- **付费用户**: 1000次/小时

超出限制时返回429状态码。

---

## SDK和客户端库

### JavaScript/TypeScript

```bash
npm install @ai-resume/sdk
```

```typescript
import { AIClient } from '@ai-resume/sdk';

const client = new AIClient({
  baseURL: 'https://api.ai-resume.com/api/v1',
  apiKey: 'your-api-key'
});

const resumes = await client.resumes.list();
```

### Python

```bash
pip install ai-resume-sdk
```

```python
from ai_resume import AIClient

client = AIClient(
    base_url="https://api.ai-resume.com/api/v1",
    api_key="your-api-key"
)

resumes = client.resumes.list()
```

---

## 支持与反馈

- **文档**: https://docs.ai-resume.com
- **GitHub**: https://github.com/ai-resume/api
- **问题反馈**: https://github.com/ai-resume/api/issues
- **邮箱**: support@ai-resume.com
