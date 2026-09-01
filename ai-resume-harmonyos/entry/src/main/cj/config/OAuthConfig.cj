package config

/**
 * OAuth 配置类
 * 集中管理 OAuth 相关配置参数
 */
public class OAuthConfig {
    // 微信配置
    public static let WECHAT_APP_ID: String = "YOUR_WECHAT_APP_ID"
    public static let WECHAT_APP_SECRET: String = "YOUR_WECHAT_APP_SECRET"
    public static let WECHAT_REDIRECT_URI: String = "yourapp://oauth/wechat"

    // 支付宝配置
    public static let ALIPAY_APP_ID: String = "YOUR_ALIPAY_APP_ID"
    public static let ALIPAY_APP_SECRET: String = "YOUR_ALIPAY_PRIVATE_KEY"
    public static let ALIPAY_REDIRECT_URI: String = "yourapp://oauth/alipay"
    public static let ALIPAY_PUBLIC_KEY: String = "YOUR_ALIPAY_PUBLIC_KEY"

    // 通用配置
    public static let TOKEN_BUFFER_TIME: Int64 = 300000  // 5分钟缓冲时间
    public static let CONNECTION_TIMEOUT: Int32 = 30000  // 30秒连接超时
    public static let READ_TIMEOUT: Int32 = 30000        // 30秒读取超时

    /**
     * 开发环境配置
     */
    public static func isDevelopment(): Bool {
        return true
    }

    /**
     * 获取微信AppID
     * @returns 微信AppID
     */
    public static func getWeChatAppId(): String {
        if (isDevelopment()) {
            return "DEV_WECHAT_APP_ID"
        }
        return WECHAT_APP_ID
    }

    /**
     * 获取支付宝AppID
     * @returns 支付宝AppID
     */
    public static func getAlipayAppId(): String {
        if (isDevelopment()) {
            return "DEV_ALIPAY_APP_ID"
        }
        return ALIPAY_APP_ID
    }
}
