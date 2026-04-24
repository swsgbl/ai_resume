// ApiConfig.cj - API配置（同步自 Web 版所有 API 端点）
package services

/**
 * API 配置类
 *
 * 同步自 Web 版 @ai-resume/shared/api 和后端路由
 * 提供统一的 API 端点配置和环境管理
 */
public class ApiConfig {
    // 环境配置
    private static let IS_DEV = isDevelopmentMode()
    private static let ENABLE_SSL = !IS_DEV

    // API基础URL - 根据环境自动切换
    public static let BASE_URL: String = IS_DEV
        ? "http://localhost:8000"
        : "https://api.yourapp.com"

    public static let API_VERSION: String = "/api/v1"

    // SSL证书校验（生产环境必须启用）
    public static let ENABLE_SSL_PINNING: Bool = ENABLE_SSL

    // ==================== 认证相关 ====================
    // 同步自 Web 版 AuthApi
    public static let AUTH_LOGIN: String = "/auth/login"
    public static let AUTH_REGISTER: String = "/auth/register"
    public static let AUTH_REFRESH: String = "/auth/refresh"
    public static let AUTH_LOGOUT: String = "/auth/logout"
    public static let AUTH_ME: String = "/auth/me"

    // 邮箱验证 - 同步自 Web 版 AuthApi.sendVerificationCode/verifyEmailCode
    public static let EMAIL_SEND_CODE: String = "/email/send-code"
    public static let EMAIL_VERIFY_CODE: String = "/email/verify-code"

    // 密码重置 - 同步自 Web 版 ForgotPasswordPage
    public static let AUTH_PASSWORD_RESET_REQUEST: String = "/auth/password-reset/request"
    public static let AUTH_PASSWORD_RESET_VERIFY: String = "/auth/password-reset/verify"

    // SMS 短信 - 同步自 Web 版 VerificationCodeInput
    public static let AUTH_SMS_SEND: String = "/auth/sms/send"
    public static let AUTH_SMS_LOGIN: String = "/auth/sms/login"

    // 微信 - 同步自 Web 版 AuthApi
    public static let AUTH_WECHAT_LOGIN: String = "/auth/wechat/login"
    public static let AUTH_WECHAT_BIND: String = "/auth/wechat/bind"
    public static let AUTH_WECHAT_UNBIND: String = "/auth/wechat/unbind"

    // OAuth - 同步自 Web 版 oauth.config
    public static let AUTH_OAUTH_AUTHORIZE: String = "/auth/oauth/{provider}/authorize"
    public static let AUTH_OAUTH_CALLBACK: String = "/auth/oauth/{provider}/callback"

    // ==================== 简历相关 ====================
    // 同步自 Web 版 ResumeApi
    public static let RESUMES: String = "/resumes"
    public static let RESUME_BY_ID: String = "/resumes/{id}"
    public static let RESUME_COPY: String = "/resumes/{id}/copy"
    public static let RESUME_AI_GENERATE: String = "/resumes/{id}/ai/generate"
    public static let RESUME_AI_OPTIMIZE: String = "/resumes/ai/optimize"

    // ==================== 模板相关 ====================
    // 同步自 Web 版 TemplateApi
    public static let TEMPLATES: String = "/templates"
    public static let TEMPLATE_BY_ID: String = "/templates/{id}"
    public static let TEMPLATE_CATEGORIES: String = "/templates/categories"
    public static let TEMPLATE_FAVORITE: String = "/templates/{id}/favorite"
    public static let TEMPLATE_FAVORITES_LIST: String = "/templates/favorites/list"

    // ==================== AI 相关 ====================
    public static let AI_GENERATE: String = "/ai/generate"
    public static let AI_USAGE: String = "/ai/usage"

    // ==================== 导出相关 ====================
    // 同步自 Web 版 ResumeApi getPdfExportUrl 等
    public static let EXPORT_PDF: String = "/export/{id}/pdf"
    public static let EXPORT_DOCX: String = "/export/{id}/word"
    public static let EXPORT_HTML: String = "/export/{id}/html"
    public static let EXPORT_PREVIEW: String = "/export/{id}/preview"

    // ==================== 账号设置 ====================
    // 同步自 Web 版 AccountSettingsPage
    public static let ACCOUNT_BINDINGS: String = "/account/bindings"
    public static let ACCOUNT_BIND_EMAIL: String = "/account/bind/email"
    public static let ACCOUNT_BIND_PHONE: String = "/account/bind/phone"
    public static let ACCOUNT_UNBIND: String = "/account/unbind"

    // ==================== 职业智能 ====================
    // 同步自 Web 版 CareerPage
    public static let CAREER_EVALUATE: String = "/career/evaluate"

    // 请求超时配置
    public static let CONNECT_TIMEOUT: Int64 = 30 * SECOND  // 30秒
    public static let READ_TIMEOUT: Int64 = 60 * SECOND     // 60秒
    public static let WRITE_TIMEOUT: Int64 = 60 * SECOND    // 60秒

    // 时间常量
    public static let SECOND: Int64 = 1000
    public static let MINUTE: Int64 = 60 * SECOND

    /**
     * 检测是否为开发模式
     */
    private static func isDevelopmentMode(): Bool {
        return true  // 默认为开发模式
    }

    /**
     * 获取完整URL
     */
    public static func getFullUrl(endpoint: String): String {
        return BASE_URL + API_VERSION + endpoint
    }

    /**
     * 获取环境信息
     */
    public static func getEnvironment(): String {
        return IS_DEV ? "development" : "production"
    }

    /**
     * 是否为生产环境
     */
    public static func isProduction(): Bool {
        return !IS_DEV
    }
}
