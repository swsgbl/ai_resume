// User.cj - 用户数据模型（同步自 Web 版 @ai-resume/shared/types）
package models

import std.collection.*

/**
 * 用户角色枚举 - 同步自 Web 版 UserRole
 */
public enum UserRole {
    USER
    PREMIUM
    ENTERPRISE
    ADMIN

    public func toString(): String {
        match (this) {
            case USER => "user"
            case PREMIUM => "premium"
            case ENTERPRISE => "enterprise"
            case ADMIN => "admin"
        }
    }

    public static func fromString(value: String): UserRole {
        match (value) {
            case "user" => UserRole.USER
            case "premium" => UserRole.PREMIUM
            case "enterprise" => UserRole.ENTERPRISE
            case "admin" => UserRole.ADMIN
            case _ => UserRole.USER
        }
    }
}

/**
 * 简历状态枚举 - 同步自 Web 版 ResumeStatus
 */
public enum ResumeStatus {
    DRAFT
    PUBLISHED
    ARCHIVED

    public func toString(): String {
        match (this) {
            case DRAFT => "draft"
            case PUBLISHED => "published"
            case ARCHIVED => "archived"
        }
    }

    public static func fromString(value: String): ResumeStatus {
        match (value) {
            case "draft" => ResumeStatus.DRAFT
            case "published" => ResumeStatus.PUBLISHED
            case "archived" => ResumeStatus.ARCHIVED
            case _ => ResumeStatus.DRAFT
        }
    }
}

/**
 * AI 提供商枚举 - 同步自 Web 版 AIProvider
 */
public enum AIProvider {
    OPENAI
    DEEPSEEK
    XIAOMI

    public func toString(): String {
        match (this) {
            case OPENAI => "openai"
            case DEEPSEEK => "deepseek"
            case XIAOMI => "xiaomi"
        }
    }
}

/**
 * 用户模型 - 同步自 Web 版 User 接口
 */
public class User {
    public var id: Int64 = 0
    public var email: String = ""
    public var phone: String = ""
    public var username: String = ""
    public var fullName: String = ""
    public var avatar: String = ""
    public var nickname: String = ""
    public var role: String = "user"
    public var isActive: Bool = false
    public var isVerified: Bool = false
    public var createdAt: String = ""
    public var updatedAt: String = ""

    public init() {}

    public init(
        id: Int64,
        email: String,
        phone: String,
        username: String,
        fullName: String,
        avatar: String,
        nickname: String,
        role: String,
        isActive: Bool,
        isVerified: Bool,
        createdAt: String,
        updatedAt: String
    ) {
        this.id = id
        this.email = email
        this.phone = phone
        this.username = username
        this.fullName = fullName
        this.avatar = avatar
        this.nickname = nickname
        this.role = role
        this.isActive = isActive
        this.isVerified = isVerified
        this.createdAt = createdAt
        this.updatedAt = updatedAt
    }
}

/**
 * 认证令牌 - 同步自 Web 版 AuthResponse
 */
public class AuthToken {
    public var accessToken: String = ""
    public var refreshToken: String = ""
    public var tokenType: String = "bearer"
    public var expiresIn: Int64 = 0
    public var user: ?User = None

    public init() {}

    public init(accessToken: String, refreshToken: String, tokenType: String, expiresIn: Int64) {
        this.accessToken = accessToken
        this.refreshToken = refreshToken
        this.tokenType = tokenType
        this.expiresIn = expiresIn
    }
}

/**
 * 登录请求 - 同步自 Web 版 LoginRequest
 */
public class LoginRequest {
    public var email: String = ""
    public var password: String = ""

    public init(email: String, password: String) {
        this.email = email
        this.password = password
    }
}

/**
 * 注册请求 - 同步自 Web 版 RegisterRequest
 */
public class RegisterRequest {
    public var email: String = ""
    public var password: String = ""
    public var phone: String = ""
    public var username: String = ""
    public var verificationCode: String = ""

    public init(email: String, username: String, password: String, fullName: String) {
        this.email = email
        this.username = username
        this.password = password
    }
}

/**
 * OAuth 提供商配置 - 同步自 Web 版 OAuthProviderConfig
 */
public class OAuthProviderConfig {
    public var key: String = ""
    public var name: String = ""
    public var enabled: Bool = true
    public var color: String = ""
    public var bgColor: String = ""
    public var icon: String = ""

    public init() {}

    public init(key: String, name: String, enabled: Bool, color: String, bgColor: String, icon: String) {
        this.key = key
        this.name = name
        this.enabled = enabled
        this.color = color
        this.bgColor = bgColor
        this.icon = icon
    }
}

/**
 * 账号绑定状态 - 同步自 Web 版 AccountBinding
 */
public class AccountBinding {
    public var bound: Bool = false
    public var value: String = ""
    public var isPrimary: Bool = false
    public var verified: Bool = false

    public init() {}
}

/**
 * 账号绑定集合 - 同步自 Web 版 AccountBindings
 */
public class AccountBindings {
    public var email: AccountBinding = AccountBinding()
    public var phone: AccountBinding = AccountBinding()
    public var wechat: AccountBinding = AccountBinding()
    public var google: AccountBinding = AccountBinding()
    public var github: AccountBinding = AccountBinding()
    public var gitee: AccountBinding = AccountBinding()
    public var discord: AccountBinding = AccountBinding()

    public init() {}
}
