# 账号注销与数据导出 API 文档

本文档描述账号注销和数据导出功能的后端API规范。

## 概述

根据 **GDPR（欧盟通用数据保护条例）** 第17条和**中国个人信息保护法**相关规定，用户有权要求删除其个人数据（被遗忘权）。

## API 端点

### 1. 请求注销账号

**请求**
```
POST /auth/account/deletion-request
```

**请求头**
```
Authorization: Bearer {access_token}
Content-Type: application/json
```

**请求体**
```json
{
  "reason": "string (optional)",  // 注销原因
  "exportData": "boolean",         // 是否需要导出数据
  "password": "string"             // 用户密码（身份验证）
}
```

**响应**
```json
{
  "success": true,
  "message": "注销请求已提交",
  "deletionDays": 30               // 删除倒计时天数
}
```

**后端处理流程**
1. 验证用户密码
2. 验证用户身份（通过Token）
3. 将账户状态标记为 "pending_deletion"
4. 记录注销原因和请求时间
5. 发送确认邮件到用户注册邮箱
6. 设置定时任务：30天后永久删除数据
7. 如果 `exportData=true`，触发数据导出流程

**错误响应**
```json
{
  "success": false,
  "message": "密码错误"
}
```

### 2. 取消注销请求

**请求**
```
POST /auth/account/cancel-deletion
```

**请求头**
```
Authorization: Bearer {access_token}
```

**响应**
```json
{
  "success": true,
  "message": "已取消注销请求"
}
```

**后端处理流程**
1. 验证用户身份
2. 检查账户是否处于 "pending_deletion" 状态
3. 取消定时删除任务
4. 恢复账户状态为 "active"

### 3. 导出个人数据

**请求**
```
POST /auth/account/export
```

**请求头**
```
Authorization: Bearer {access_token}
```

**响应**
```json
{
  "success": true,
  "message": "数据导出请求已提交",
  "exportUrl": "string (optional)",  // 下载链接（如果已生成）
  "expiresAt": "2024-02-08T00:00:00Z" // 链接过期时间
}
```

**后端处理流程**
1. 验证用户身份
2. 收集用户所有个人数据：
   - 基本信息（邮箱、昵称、头像）
   - 简历数据
   - 模板使用记录
   - VIP购买记录
   - 登录日志
3. 生成JSON/ZIP格式数据包
4. 加密数据包
5. 上传到云存储（生成临时下载链接）
6. 发送下载链接到用户邮箱
7. 设置链接24小时后过期

**数据包格式**
```
user-data-{userId}-{timestamp}.zip
├── personal-info.json        # 个人信息
├── resumes/                  # 简历数据
│   ├── resume-1.json
│   └── resume-2.json
├── templates/                # 模板使用记录
├── payments/                 # 支付记录
└── activity-logs/            # 活动日志
```

### 4. 修改密码

**请求**
```
POST /auth/change-password
```

**请求体**
```json
{
  "oldPassword": "string",
  "newPassword": "string"
}
```

**响应**
```json
{
  "success": true,
  "message": "密码修改成功"
}
```

### 5. 重置密码

**请求**
```
POST /auth/reset-password
```

**请求体**
```json
{
  "email": "string",
  "code": "string",
  "newPassword": "string"
}
```

**响应**
```json
{
  "success": true,
  "message": "密码重置成功"
}
```

## 数据库设计

### 用户表扩展字段

```sql
ALTER TABLE users ADD COLUMN status VARCHAR(20) DEFAULT 'active';
ALTER TABLE users ADD COLUMN deletion_requested_at TIMESTAMP NULL;
ALTER TABLE users ADD COLUMN deletion_reason VARCHAR(500) NULL;
```

### 注销状态枚举

- `active` - 正常状态
- `pending_deletion` - 待删除（30天倒计时中）
- `deleted` - 已删除

## 定时任务

### 每日扫描待删除账户

```python
# 伪代码
def scan_pending_deletions():
    users = User.where(
        status='pending_deletion',
        deletion_requested_at <= NOW() - INTERVAL 30 DAY
    )

    for user in users:
        # 永久删除用户数据
        delete_user_data(user.id)

        # 发送删除确认邮件
        send_deletion_confirmation_email(user.email)
```

## 安全考虑

1. **身份验证**：所有注销相关操作需要验证用户密码
2. **确认邮件**：注销请求需要邮件确认，防止恶意操作
3. **宽限期**：30天宽限期允许用户反悔
4. **数据加密**：导出的数据包需要加密
5. **访问日志**：记录所有注销相关操作
6. **限制频率**：防止频繁请求/取消注销

## 合规要求

### GDPR 第17条（被遗忘权）
- 用户有权要求数据控制者删除其个人数据
- 数据控制者必须在1个月内响应请求
- 某些情况下可以拒绝删除（如法律义务）

### 中国个人信息保护法
- 个人有权撤回同意
- 个人有权要求删除个人信息
- 服务提供者应当及时响应删除请求

## 实现检查清单

- [ ] 实现请求注销API
- [ ] 实现取消注销API
- [ ] 实现数据导出API
- [ ] 添加账户状态字段到数据库
- [ ] 实现定时删除任务
- [ ] 实现邮件通知
- [ ] 添加操作日志记录
- [ ] 添加请求频率限制
