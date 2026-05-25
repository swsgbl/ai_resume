package integration

import models.oauth.OAuthUser
import models.oauth.OAuthProvider
import models.oauth.Gender
import services.HttpClient
import std.json.JSONObject

/**
 * Mock OAuth API
 * 模拟微信和支付宝OAuth API响应，用于集成测试
 */
public class MockOAuthAPI {
    private let responseDelay: Int64 = 100 // 模拟100ms网络延迟

    /**
     * 模拟微信Token API响应
     * @param code 授权码
     * @returns JSON响应字符串
     */
    public func mockWeChatTokenAPI(code: String): String {
        this.simulateNetworkDelay()

        let response = JSONObject()
        response.put("access_token", "mock_wechat_access_token_${code}")
        response.put("expires_in", 7200)
        response.put("refresh_token", "mock_wechat_refresh_token_${code}")
        response.put("openid", "mock_wechat_openid_${code}")
        response.put("scope", "snsapi_userinfo")
        response.put("unionid", "mock_wechat_unionid_${code}")

        return response.toString()
    }

    /**
     * 模拟支付宝Token API响应
     * @param authCode 授权码
     * @returns JSON响应字符串
     */
    public func mockAlipayTokenAPI(authCode: String): String {
        this.simulateNetworkDelay()

        let response = JSONObject()
        response.put("access_token", "mock_alipay_access_token_${authCode}")
        response.put("expires_in", 7200)
        response.put("refresh_token", "mock_alipay_refresh_token_${authCode}")
        response.put("user_id", "mock_alipay_user_id_${authCode}")

        return response.toString()
    }

    /**
     * 模拟微信用户信息API响应
     * @param accessToken 访问令牌
     * @param openId OpenID
     * @returns JSON响应字符串
     */
    public func mockWeChatUserInfoAPI(accessToken: String, openId: String): String {
        this.simulateNetworkDelay()

        let response = JSONObject()
        response.put("openid", openId)
        response.put("nickname", "微信测试用户")
        response.put("sex", 1) // 1=男性
        response.put("province", "广东")
        response.put("city", "深圳")
        response.put("country", "中国")
        response.put("headimgurl", "https://thirdwx.qlogo.cn/mock/avatar.jpg")
        response.put("privilege", JSONArray()) // 空数组
        response.put("unionid", "mock_wechat_unionid_${openId}")

        return response.toString()
    }

    /**
     * 模拟支付宝用户信息API响应
     * @param accessToken 访问令牌
     * @returns JSON响应字符串
     */
    public func mockAlipayUserInfoAPI(accessToken: String): String {
        this.simulateNetworkDelay()

        let response = JSONObject()
        response.put("user_id", "mock_alipay_user_id_12345")
        response.put("nick_name", "支付宝测试用户")
        response.put("gender", "F") // F=女性
        response.put("city", "杭州")
        response.put("province", "浙江")
        response.put("avatar", "https://alipay.mock/avatar.jpg")

        return response.toString()
    }

    /**
     * 模拟错误响应
     * @param errorCode 错误代码
     * @param errorMessage 错误消息
     * @returns JSON错误响应
     */
    public func mockErrorResponse(errorCode: String, errorMessage: String): String {
        this.simulateNetworkDelay()

        let response = JSONObject()
        response.put("errcode", errorCode.toInt())
        response.put("errmsg", errorMessage)

        return response.toString()
    }

    /**
     * 模拟网络超时
     * @throws IOException 网络超时异常
     */
    public func mockNetworkTimeout() {
        Thread.sleep(30000) // 30秒超时
        throw IOException("Network timeout")
    }

    /**
     * 模拟网络延迟
     */
    private func simulateNetworkDelay() {
        Thread.sleep(this.responseDelay)
    }

    /**
     * 创建Mock微信用户
     * @param code 授权码
     * @returns OAuth用户对象
     */
    public func createMockWeChatUser(code: String): OAuthUser {
        return OAuthUser(
            provider: OAuthProvider.WECHAT,
            openId: "mock_wechat_openid_${code}",
            unionId: "mock_wechat_unionid_${code}",
            nickname: "微信测试用户",
            avatarUrl: "https://thirdwx.qlogo.cn/mock/avatar.jpg",
            gender: Gender.MALE,
            country: "中国",
            province: "广东",
            city: "深圳",
            language: "zh_CN"
        )
    }

    /**
     * 创建Mock支付宝用户
     * @param authCode 授权码
     * @returns OAuth用户对象
     */
    public func createMockAlipayUser(authCode: String): OAuthUser {
        return OAuthUser(
            provider: OAuthProvider.ALIPAY,
            openId: "mock_alipay_user_id_${authCode}",
            unionId: null,
            nickname: "支付宝测试用户",
            avatarUrl: "https://alipay.mock/avatar.jpg",
            gender: Gender.FEMALE,
            country: null,
            province: "浙江",
            city: "杭州",
            language: null
        )
    }

    /**
     * 创建Mock后端Token响应
     * @param userId 用户ID
     * @returns 后端Token响应
     */
    public func createMockBackendTokenResponse(userId: Int): String {
        let response = JSONObject()
        response.put("access_token", "mock_jwt_token_${userId}")
        response.put("refresh_token", "mock_jwt_refresh_token_${userId}")
        response.put("expires_in", 7200)
        response.put("user_id", userId)

        let user = JSONObject()
        user.put("id", userId)
        user.put("username", "testuser_${userId}")
        user.put("email", "testuser${userId}@example.com")
        response.put("user", user)

        return response.toString()
    }

    /**
     * 验证Mock State
     * @param state 待验证的state
     * @returns 是否有效
     */
    public func validateMockState(state: String): Bool {
        return state != null && !state.isEmpty() && state.startsWith("mock_state_")
    }

    /**
     * 生成Mock State
     * @returns Mock state字符串
     */
    public func generateMockState(): String {
        return "mock_state_${System.currentTimeMillis()}"
    }
}
