# AI Resume HarmonyOS - Phase 8 OAuth 技术调研

**文档创建时间**: 2026-05-14 01:48  
**负责人**: 鸿蒙开发工程师  
**优先级**: P0 (核心功能)

---

## 1. 技术背景

### 1.1 OAuth 2.0 协议概述

OAuth 2.0 是一个授权框架，允许第三方应用获得有限的用户授权权限。它是当前业界标准的授权协议。

**核心角色**:
- **Resource Owner**: 用户
- **Client**: 我们的应用（AI Resume HarmonyOS）
- **Authorization Server**: 微信/支付宝等授权服务器
- **Resource Server**: API 服务器

**授权流程**:
1. 用户点击"微信登录"按钮
2. 应用跳转到微信授权页面
3. 用户同意授权
4. 微信返回授权码
5. 应用使用授权码换取 access_token
6. 应用使用 access_token 访问用户信息

### 1.2 HarmonyOS OAuth 支持

HarmonyOS 提供了原生的 OAuth 支持：
- **Account Manager**: 账号管理框架
- **WebAuth**: 基于 Web 的 OAuth 认证
- **第三方 SDK**: 微信/支付宝开放平台 SDK

---

## 2. 微信登录集成方案

### 2.1 微信开放平台配置

**准备工作**:
1. 注册微信开放平台账号
2. 创建移动应用
3. 获取 AppID 和 AppSecret
4. 配置应用签名和包名

**HarmonyOS 应用信息**:
- 应用包名: `com.airesume.harmonyos`
- 应用签名: 需要使用正式签名证书

### 2.2 技术实现方案

#### 方案 A: 使用微信鸿蒙 SDK（推荐）

**优势**:
- 原生支持，用户体验最佳
- 官方维护，稳定性高
- 支持所有微信功能

**实现步骤**:
1. 集成微信鸿蒙 SDK
2. 配置 WXEntryActivity
3. 调用微信登录接口
4. 处理登录回调

```cangjie
// 伪代码示例
import { WeChatSDK } from '@wechat/sdk'

public class WeChatAuthService {
    private let appID: String = "your_app_id"
    
    public func login() {
        WeChatSDK.sendAuthRequest(
            appId: appID,
            scope: "snsapi_userinfo",
            state: generateState()
        )
    }
    
    public func handleAuthResponse(code: String) {
        // 1. 使用授权码换取 access_token
        let token = exchangeCodeForToken(code)
        // 2. 使用 access_token 获取用户信息
        let userInfo = getUserInfo(token)
        // 3. 登录到我们的后端
        loginToBackend(userInfo)
    }
}
```

#### 方案 B: 使用 Web OAuth

**优势**:
- 不依赖第三方 SDK
- 实现简单，维护成本低

**劣势**:
- 用户体验稍差（需要跳转浏览器）
- 需要手动处理授权码

### 2.3 后端集成

**需要实现的后端接口**:
1. `POST /api/auth/wechat/login` - 微信登录
2. `POST /api/auth/alipay/login` - 支付宝登录

**后端实现要点**:
- 验证微信签名
- 检查授权码有效性
- 创建或更新用户账号
- 生成 JWT token
- 返回登录结果

---

## 3. 支付宝登录集成方案

### 3.1 支付宝开放平台配置

**准备工作**:
1. 注册支付宝开放平台账号
2. 创建应用
3. 获取 AppID 和私钥
4. 配置应用公钥

### 3.2 技术实现方案

**支付宝鸿蒙 SDK 集成**:
```cangjie
import { AlipaySDK } from '@alipay/sdk'

public class AlipayAuthService {
    private let appID: String = "your_app_id"
    
    public func login() {
        AlipaySDK.auth(
            appId: appID,
            scope: "auth_user",
            state: generateState()
        )
    }
    
    public func handleAuthResponse(authCode: String) {
        // 处理支付宝授权码
        let token = exchangeAuthCodeForToken(authCode)
        let userInfo = getUserInfo(token)
        loginToBackend(userInfo)
    }
}
```

---

## 4. 安全考虑

### 4.1 Token 管理

**存储策略**:
- Access Token: 使用加密的 Preferences 存储
- Refresh Token: 后端管理，不在本地存储
- Token 过期: 自动刷新机制

**安全措施**:
```cangjie
public class TokenManager {
    private let encryptedPrefs: EncryptedPreferences
    
    public func saveToken(token: String) {
        encryptedPrefs.put("access_token", encrypt(token))
    }
    
    public func getToken(): String? {
        guard let encrypted = encryptedPrefs.get("access_token") else {
            return nil
        }
        return decrypt(encrypted)
    }
    
    public func isTokenExpired(): Boolean {
        // 检查 token 是否过期
    }
}
```

### 4.2 防重放攻击

**措施**:
- 使用随机 state 参数
- 授权码只能使用一次
- 设置合理的过期时间

### 4.3 防CSRF攻击

**措施**:
- 验证 state 参数
- 检查 Referer 头
- 使用 SameSite Cookie

---

## 5. 用户体验设计

### 5.1 登录流程

```
用户打开应用
    ↓
显示登录页面
    ↓
用户选择"微信登录"
    ↓
跳转微信授权页面
    ↓
用户确认授权
    ↓
返回应用，显示加载状态
    ↓
获取用户信息成功
    ↓
跳转到主页
```

### 5.2 错误处理

**常见错误场景**:
1. 用户取消授权
2. 网络连接失败
3. 授权码过期
4. 后端服务异常

**错误处理策略**:
```cangjie
public enum OAuthError {
    case USER_CANCELLED
    case NETWORK_ERROR
    case AUTH_CODE_EXPIRED
    case SERVER_ERROR
}

public func handleOAuthError(error: OAuthError) {
    match error {
        case USER_CANCELLED => {
            // 提示用户取消登录
        }
        case NETWORK_ERROR => {
            // 提示网络错误，提供重试按钮
        }
        case AUTH_CODE_EXPIRED => {
            // 提示授权过期，重新登录
        }
        case SERVER_ERROR => {
            // 提示服务异常，稍后重试
        }
    }
}
```

---

## 6. 测试计划

### 6.1 单元测试

**测试覆盖**:
- OAuth 服务类
- Token 管理器
- 错误处理逻辑

**测试用例**:
```cangjie
@Test
public fun testWeChatLoginSuccess() {
    // 测试微信登录成功流程
}

@Test
public fun testTokenEncryption() {
    // 测试 Token 加密存储
}

@Test
public fun testOAuthErrorHandling() {
    // 测试错误处理
}
```

### 6.2 集成测试

**测试场景**:
1. 完整登录流程
2. Token 刷新机制
3. 网络异常处理
4. 授权过期处理

### 6.3 UI 测试

**测试用例**:
1. 登录按钮点击
2. 授权页面跳转
3. 加载状态显示
4. 错误提示显示

---

## 7. 开发时间估算

| 任务 | 预估时间 |
|------|----------|
| 微信 SDK 集成 | 3-5 天 |
| 支付宝 SDK 集成 | 2-3 天 |
| 后端接口开发 | 2-3 天 |
| UI 开发 | 2 天 |
| 测试和调试 | 3-4 天 |
| 文档编写 | 1 天 |
| **总计** | **15-20 天** |

---

## 8. 风险和挑战

### 8.1 技术风险

**风险点**:
- 微信/支付宝 SDK 兼容性问题
- HarmonyOS 系统更新导致 API 变化
- 第三方平台政策变化

**应对措施**:
- 使用官方最新 SDK
- 关注平台公告
- 预留 API 升级时间

### 8.2 审核风险

**风险点**:
- 应用审核不通过
- OAuth 权限被拒绝

**应对措施**:
- 仔细阅读审核规范
- 提供详细的使用说明
- 准备隐私政策文档

---

## 9. 参考资料

### 9.1 官方文档

- [微信开放平台](https://open.weixin.qq.com/)
- [支付宝开放平台](https://opendocs.alipay.com/)
- [HarmonyOS Account Kit](https://developer.harmonyos.com/cn/docs/documentation/doc-references-V3/js-apis-account-V3)

### 9.2 技术文章

- OAuth 2.0 规范 (RFC 6749)
- HarmonyOS 第三方登录开发指南
- 微信鸿蒙 SDK 接入文档

---

## 10. 下一步行动

1. **本周** (准备阶段)
   - [ ] 注册微信开放平台账号
   - [ ] 注册支付宝开放平台账号
   - [ ] 创建应用并获取 AppID
   - [ ] 下载微信鸿蒙 SDK
   - [ ] 下载支付宝鸿蒙 SDK

2. **下周** (开发阶段)
   - [ ] 创建 OAuth 服务分支
   - [ ] 实现微信登录功能
   - [ ] 实现支付宝登录功能
   - [ ] 开发后端接口
   - [ ] 编写单元测试

3. **第三周** (测试阶段)
   - [ ] 集成测试
   - [ ] UI 测试
   - [ ] 性能测试
   - [ ] 安全测试

---

**文档状态**: ✅ 完成  
**下一步**: 开始 OAuth 登录功能开发  
**更新时间**: 根据开发进度动态更新

