package services.oauth

import models.oauth.OAuthUser
import models.oauth.OAuthProvider
import services.HttpClient
import utils.oauth.OAuthHelper

/**
 * 微信登录服务
 * 实现微信 OAuth 2.0 登录流程
 */
public class WeChatAuthService extends BaseOAuthService {
    private let httpClient: HttpClient
    private let oauthHelper: OAuthHelper
    private let authorizeUrl: String = "https://open.weixin.qq.com/connect/oauth2/authorize"
    private let tokenUrl: String = "https://api.weixin.qq.com/sns/oauth2/access_token"
    private let userInfoUrl: String = "https://api.weixin.qq.com/sns/userinfo"

    public init(appId: String, appSecret: String, redirectUri: String) {
        super(appId, appSecret, redirectUri)
        httpClient = HttpClient()
        oauthHelper = OAuthHelper()
    }

    /**
     * 获取微信授权 URL
     * @param state state 参数
     * @returns 微信授权 URL
     */
    public override func getAuthorizationUrl(state: String): String {
        let params = Map<String, String>()
        params.put("appid", appId)
        params.put("redirect_uri", redirectUri)
        params.put("response_type", "code")
        params.put("scope", "snsapi_userinfo")
        params.put("state", state)

        return "${authorizeUrl}?${buildParams(params)}#wechat_redirect"
    }

    /**
     * 处理微信授权回调
     * @param code 授权码
     * @param state state 参数
     * @returns OAuth 用户信息
     */
    public override func handleAuthorizationCallback(code: String, state: String): OAuthUser {
        // 1. 使用 code 换取 access_token
        let tokenResponse = exchangeCodeForToken(code)
        let accessToken = tokenResponse.get("access_token")
        let openId = tokenResponse.get("openid")

        // 2. 使用 access_token 获取用户信息
        let userInfo = getUserInfo(accessToken, openId)

        return OAuthUser(
            provider: OAuthProvider.WECHAT,
            openId: openId,
            unionId: userInfo.get("unionid"),
            nickname: userInfo.get("nickname"),
            avatarUrl: userInfo.get("headimgurl"),
            gender: parseGender(userInfo.get("sex")),
            country: userInfo.get("country"),
            province: userInfo.get("province"),
            city: userInfo.get("city"),
            language: userInfo.get("language")
        )
    }

    /**
     * 刷新令牌
     * @param refreshToken 刷新令牌
     * @returns 新的访问令牌
     */
    public override func refreshToken(refreshToken: String): String {
        let params = Map<String, String>()
        params.put("appid", appId)
        params.put("grant_type", "refresh_token")
        params.put("refresh_token", refreshToken)

        let response = httpClient.post(tokenUrl, params)
        let jsonResponse = parseJson(response)
        return jsonResponse.get("access_token")
    }

    /**
     * 获取提供商
     * @returns OAuth 提供商
     */
    public override func getProvider(): OAuthProvider {
        return OAuthProvider.WECHAT
    }

    /**
     * 使用授权码换取 access_token
     * @param code 授权码
     * @returns 包含 access_token 的响应
     */
    private func exchangeCodeForToken(code: String): Map<String, String> {
        let params = Map<String, String>()
        params.put("appid", appId)
        params.put("secret", appSecret)
        params.put("code", code)
        params.put("grant_type", "authorization_code")

        let response = httpClient.get(tokenUrl, params)
        return parseJson(response)
    }

    /**
     * 获取用户信息
     * @param accessToken 访问令牌
     * @param openId OpenID
     * @returns 用户信息映射
     */
    private func getUserInfo(accessToken: String, openId: String): Map<String, String> {
        let params = Map<String, String>()
        params.put("access_token", accessToken)
        params.put("openid", openId)
        params.put("lang", "zh_CN")

        let response = httpClient.get(userInfoUrl, params)
        return parseJson(response)
    }

    /**
     * 解析性别
     * @param sex 性别代码（1=男，2=女）
     * @returns 性别枚举
     */
    private func parseGender(sex: String?): Gender {
        if (sex == null) {
            return Gender.UNKNOWN
        }
        let sexCode = sex.toInt()
        if (sexCode == 1) {
            return Gender.MALE
        } else if (sexCode == 2) {
            return Gender.FEMALE
        } else {
            return Gender.UNKNOWN
        }
    }

    /**
     * 解析 JSON 响应为 Map
     * @param json JSON 字符串
     * @returns 键值对映射
     */
    private func parseJson(json: String): Map<String, String> {
        // 简化实现，实际应使用 JSON 解析库
        let result = HashMap<String, String>()
        // JSON 解析逻辑
        return result
    }
}
