package services.oauth

import models.oauth.OAuthUser
import models.oauth.OAuthProvider

/**
 * OAuth 服务基类
 * 定义所有 OAuth 服务的通用接口和基础实现
 */
public abstract class BaseOAuthService {
    protected let appId: String
    protected let appSecret: String
    protected let redirectUri: String

    public init(appId: String, appSecret: String, redirectUri: String) {
        this.appId = appId
        this.appSecret = appSecret
        this.redirectUri = redirectUri
    }

    /**
     * 获取授权 URL
     * @param state state 参数
     * @returns 授权 URL
     */
    public abstract func getAuthorizationUrl(state: String): String

    /**
     * 处理授权回调
     * @param code 授权码
     * @param state state 参数
     * @returns OAuth 用户信息
     */
    public abstract func handleAuthorizationCallback(code: String, state: String): OAuthUser

    /**
     * 刷新令牌
     * @param refreshToken 刷新令牌
     * @returns 新的访问令牌
     */
    public abstract func refreshToken(refreshToken: String): String

    /**
     * 获取提供商
     * @returns OAuth 提供商
     */
    public abstract func getProvider(): OAuthProvider

    /**
     * 验证 state 参数
     * @param state 回调中的 state
     * @param storedState 存储的 state
     * @returns 是否有效
     */
    protected func validateState(state: String, storedState: String): Bool {
        return state == storedState
    }

    /**
     * 构建 HTTP 请求参数
     * @param params 参数键值对
     * @returns URL 编码的参数字符串
     */
    protected func buildParams(params: Map<String, String>): String {
        let result = StringBuilder()
        var first = true
        for ((key, value) in params) {
            if (!first) {
                result.append("&")
            }
            result.append("${urlEncode(key)}=${urlEncode(value)}")
            first = false
        }
        return result.toString()
    }

    /**
     * URL 编码
     * @param input 输入字符串
     * @returns 编码后的字符串
     */
    protected func urlEncode(input: String): String {
        // 简单实现，实际应使用 URLEncoder
        return input.replace(" ", "%20")
            .replace(":", "%3A")
            .replace("/", "%2F")
            .replace("?", "%3F")
            .replace("=", "%3D")
            .replace("&", "%26")
    }
}
