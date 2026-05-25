package models.oauth

/**
 * OAuth 用户信息模型
 * 存储第三方登录返回的用户信息
 */
public class OAuthUser {
    public let provider: OAuthProvider          // 提供商
    public let openId: String                   // OpenID
    public let unionId: String?                 // UnionID（部分平台提供）
    public let nickname: String?                // 昵称
    public let avatarUrl: String?               // 头像 URL
    public let gender: Gender?                  // 性别
    public let country: String?                 // 国家
    public let province: String?                // 省份
    public let city: String?                    // 城市
    public let language: String?                // 语言

    public init(
        provider: OAuthProvider,
        openId: String,
        unionId: String? = null,
        nickname: String? = null,
        avatarUrl: String? = null,
        gender: Gender? = null,
        country: String? = null,
        province: String? = null,
        city: String? = null,
        language: String? = null
    ) {
        this.provider = provider
        this.openId = openId
        this.unionId = unionId
        this.nickname = nickname
        this.avatarUrl = avatarUrl
        this.gender = gender
        this.country = country
        this.province = province
        this.city = city
        this.language = language
    }
}

/**
 * OAuth 提供商枚举
 */
public enum OAuthProvider {
    case WECHAT                                // 微信
    case ALIPAY                                // 支付宝
    case UNKNOWN                               // 未知
}

/**
 * 性别枚举
 */
public enum Gender {
    case MALE                                  // 男
    case FEMALE                                // 女
    case UNKNOWN                               // 未知
}
