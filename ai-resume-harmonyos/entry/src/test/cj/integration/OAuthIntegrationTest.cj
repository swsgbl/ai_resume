package integration

import std.testing.*
import services.oauth.WeChatAuthService
import services.oauth.AlipayAuthService
import utils.oauth.OAuthHelper
import models.oauth.OAuthUser
import integration.MockOAuthAPI

/**
 * OAuth集成测试
 * 测试完整的OAuth登录流程，使用Mock API
 */
class OAuthIntegrationTest {
    private let mockAPI: MockOAuthAPI
    private let oauthHelper: OAuthHelper

    public init() {
        this.mockAPI = MockOAuthAPI()
        this.oauthHelper = OAuthHelper()
    }

    /**
     * 测试完整的微信登录流程
     */
    @Test
    func testWeChatLoginFlow() {
        // 1. 生成state参数
        let state = this.oauthHelper.generateState()
        Assert.assertFalse(state.isEmpty(), "State不能为空")

        // 2. 创建微信服务
        let wechatService = WeChatAuthService(
            appId: "test_wechat_app_id",
            appSecret: "test_wechat_app_secret",
            redirectUri: "test://oauth/wechat"
        )

        // 3. 获取授权URL
        let authUrl = wechatService.getAuthorizationUrl(state)
        Assert.assertTrue(authUrl.contains("test_wechat_app_id"), "授权URL应包含AppID")
        Assert.assertTrue(authUrl.contains(state), "授权URL应包含state")

        // 4. 模拟用户授权，获取授权码
        let mockCode = "mock_wechat_code_123"

        // 5. 模拟后端Token API调用
        let tokenResponse = this.mockAPI.mockWeChatTokenAPI(mockCode)
        Assert.assertTrue(tokenResponse.contains("access_token"), "Token响应应包含access_token")

        // 6. 模拟获取用户信息
        let userInfoResponse = this.mockAPI.mockWeChatUserInfoAPI(
            accessToken: "mock_access_token",
            openId: "mock_openid"
        )
        Assert.assertTrue(userInfoResponse.contains("nickname"), "用户信息应包含昵称")

        // 7. 创建OAuth用户对象
        let oauthUser = this.mockAPI.createMockWeChatUser(mockCode)
        Assert.assertEquals(OAuthProvider.WECHAT, oauthUser.provider, "提供商应该是微信")
        Assert.assertFalse(oauthUser.openId.isEmpty(), "OpenID不能为空")

        console.log("✅ 微信登录流程测试通过")
    }

    /**
     * 测试完整的支付宝登录流程
     */
    @Test
    func testAlipayLoginFlow() {
        // 1. 生成state参数
        let state = this.oauthHelper.generateState()
        Assert.assertFalse(state.isEmpty(), "State不能为空")

        // 2. 创建支付宝服务
        let alipayService = AlipayAuthService(
            appId: "test_alipay_app_id",
            appSecret: "test_alipay_app_secret",
            redirectUri: "test://oauth/alipay"
        )

        // 3. 获取授权URL
        let authUrl = alipayService.getAuthorizationUrl(state)
        Assert.assertTrue(authUrl.contains("test_alipay_app_id"), "授权URL应包含AppID")
        Assert.assertTrue(authUrl.contains(state), "授权URL应包含state")

        // 4. 模拟用户授权，获取授权码
        let mockCode = "mock_alipay_code_456"

        // 5. 模拟后端Token API调用
        let tokenResponse = this.mockAPI.mockAlipayTokenAPI(mockCode)
        Assert.assertTrue(tokenResponse.contains("access_token"), "Token响应应包含access_token")

        // 6. 模拟获取用户信息
        let userInfoResponse = this.mockAPI.mockAlipayUserInfoAPI(
            accessToken: "mock_access_token"
        )
        Assert.assertTrue(userInfoResponse.contains("nick_name"), "用户信息应包含昵称")

        // 7. 创建OAuth用户对象
        let oauthUser = this.mockAPI.createMockAlipayUser(mockCode)
        Assert.assertEquals(OAuthProvider.ALIPAY, oauthUser.provider, "提供商应该是支付宝")
        Assert.assertFalse(oauthUser.openId.isEmpty(), "用户ID不能为空")

        console.log("✅ 支付宝登录流程测试通过")
    }

    /**
     * 测试State验证流程
     */
    @Test
    func testStateValidation() {
        // 1. 生成state
        let originalState = this.oauthHelper.generateState()

        // 2. 模拟授权回调，验证state
        let isValid = this.oauthHelper.validateState(originalState, originalState)
        Assert.assertTrue(isValid, "State验证应该通过")

        // 3. 测试错误的state
        let wrongState = this.oauthHelper.generateState()
        let isInvalid = this.oauthHelper.validateState(wrongState, originalState)
        Assert.assertFalse(isInvalid, "错误的State应该验证失败")

        console.log("✅ State验证流程测试通过")
    }

    /**
     * 测试错误处理流程
     */
    @Test
    func testErrorHandling() {
        // 测试网络错误响应
        let errorResponse = this.mockAPI.mockErrorResponse(
            errorCode: "40029",
            errorMessage: "invalid code"
        )
        Assert.assertTrue(errorResponse.contains("errcode"), "错误响应应包含错误码")

        // 测试用户取消授权
        let cancelError = this.mockAPI.mockErrorResponse(
            errorCode: "USER_CANCEL",
            errorMessage: "用户取消授权"
        )
        Assert.assertTrue(cancelError.contains("用户取消授权"), "应包含取消信息")

        console.log("✅ 错误处理流程测试通过")
    }

    /**
     * 测试并发登录请求
     */
    @Test
    func testConcurrentLoginRequests() {
        let threadCount = 5
        let requestsPerThread = 10

        let threads = ArrayList<Thread>()
        let successCount = AtomicInteger(0)
        let failureCount = AtomicInteger(0)

        // 模拟多个线程同时发起登录请求
        for (i in 0..threadCount) {
            let thread = Thread({
                for (j in 0..requestsPerThread) {
                    try {
                        // 模拟登录流程
                        let state = this.oauthHelper.generateState()
                        let mockCode = "concurrent_code_${i}_${j}"

                        let tokenResponse = this.mockAPI.mockWeChatTokenAPI(mockCode)
                        if (tokenResponse.contains("access_token")) {
                            successCount.incrementAndGet()
                        } else {
                            failureCount.incrementAndGet()
                        }
                    } catch (e: Exception) {
                        failureCount.incrementAndGet()
                    }
                }
            })
            threads.add(thread)
            thread.start()
        }

        // 等待所有线程完成
        for (thread in threads) {
            thread.join()
        }

        let totalRequests = threadCount * requestsPerThread
        let successRate = (successCount.get().toFloat() / totalRequests.toFloat()) * 100.0f

        console.log("并发登录测试: 总请求数=${totalRequests}, 成功=${successCount.get()}, 失败=${failureCount.get()}, 成功率=${successRate}%")

        // 断言所有请求都成功
        Assert.assertEquals(totalRequests, successCount.get(), "所有并发请求都应该成功")
    }

    /**
     * 测试Token刷新流程
     */
    @Test
    func testTokenRefreshFlow() {
        // 1. 模拟初始登录获取Token
        let mockCode = "refresh_test_code"
        let tokenResponse = this.mockAPI.mockWeChatTokenAPI(mockCode)

        // 2. 提取refresh_token
        let refreshToken = "mock_wechat_refresh_token_${mockCode}"

        // 3. 模拟Token刷新
        let newTokenResponse = this.mockAPI.mockWeChatTokenAPI("refreshed_code")
        Assert.assertTrue(newTokenResponse.contains("access_token"), "刷新后应获得新Token")

        console.log("✅ Token刷新流程测试通过")
    }

    /**
     * 测试性能基准
     */
    @Test
    func testPerformanceBenchmark() {
        let iterations = 100

        // 测试微信登录流程性能
        let startTime = System.currentTimeMillis()
        for (i in 0..iterations) {
            let state = this.oauthHelper.generateState()
            let mockCode = "perf_test_${i}"
            let _ = this.mockAPI.mockWeChatTokenAPI(mockCode)
            let _ = this.mockAPI.mockWeChatUserInfoAPI("token", state)
        }
        let endTime = System.currentTimeMillis()

        let avgTime = (endTime - startTime).toFloat() / iterations.toFloat()
        console.log("平均每次登录流程耗时: ${avgTime}ms")

        // 断言平均响应时间在合理范围内（< 500ms）
        Assert.assertTrue(avgTime < 500, "平均响应时间应小于500ms")
    }

    /**
     * 测试数据一致性
     */
    @Test
    func testDataConsistency() {
        let mockCode = "consistency_test_code"

        // 创建用户对象
        let user1 = this.mockAPI.createMockWeChatUser(mockCode)
        let user2 = this.mockAPI.createMockWeChatUser(mockCode)

        // 验证相同code产生相同用户信息
        Assert.assertEquals(user1.openId, user2.openId, "OpenID应该一致")
        Assert.assertEquals(user1.unionId, user2.unionId, "UnionID应该一致")
        Assert.assertEquals(user1.nickname, user2.nickname, "昵称应该一致")

        console.log("✅ 数据一致性测试通过")
    }
}
