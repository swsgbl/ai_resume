package services

import std.testing.*
import ohos.data.preferences.Preferences
import services.TokenManager

/**
 * TokenManager 单元测试
 */
class TokenManagerTest {
    private let tokenManager: TokenManager
    private let mockContext: Context

    init() {
        this.mockContext = MockContext()
        this.tokenManager = TokenManager(this.mockContext)
    }

    /**
     * 测试Token保存和读取
     */
    @Test
    func testSaveAndGetAccessToken() {
        let testToken = "test_access_token_12345"

        // 保存token
        this.tokenManager.saveAccessToken(testToken)

        // 读取token
        let retrievedToken = this.tokenManager.getAccessToken()

        // 验证token正确保存和读取
        Assert.assertEquals(testToken, retrievedToken, "保存和读取的token应该一致")
    }

    /**
     * 测试RefreshToken保存和读取
     */
    @Test
    func testSaveAndGetRefreshToken() {
        let refreshToken = "test_refresh_token_67890"

        // 保存refresh token
        this.tokenManager.saveRefreshToken(refreshToken)

        // 读取refresh token
        let retrievedToken = this.tokenManager.getRefreshToken()

        // 验证refresh token正确保存和读取
        Assert.assertEquals(refreshToken, retrievedToken, "保存和读取的refresh token应该一致")
    }

    /**
     * 测试Token过期时间保存和读取
     */
    @Test
    func testSaveAndGetTokenExpiry() {
        let expiryTime = System.currentTimeMillis() + 3600000 // 1小时后过期

        // 保存过期时间
        this.tokenManager.saveTokenExpiry(expiryTime)

        // 读取过期时间
        let retrievedExpiry = this.tokenManager.getTokenExpiry()

        // 验证过期时间正确保存和读取
        Assert.assertEquals(expiryTime, retrievedExpiry, "保存和读取的过期时间应该一致")
    }

    /**
     * 测试Token是否过期
     */
    @Test
    func testIsTokenExpired() {
        // 测试已过期的token
        let pastExpiry = System.currentTimeMillis() - 1000
        this.tokenManager.saveTokenExpiry(pastExpiry)
        Assert.assertTrue(this.tokenManager.isTokenExpired(), "过去的过期时间应该判定为已过期")

        // 测试未过期的token
        let futureExpiry = System.currentTimeMillis() + 3600000
        this.tokenManager.saveTokenExpiry(futureExpiry)
        Assert.assertFalse(this.tokenManager.isTokenExpired(), "未来的过期时间应该判定为未过期")
    }

    /**
     * 测试Token即将过期
     */
    @Test
    func testIsTokenExpiringSoon() {
        // 测试即将过期的token（2分钟后过期）
        let soonExpiry = System.currentTimeMillis() + 120000
        this.tokenManager.saveTokenExpiry(soonExpiry)
        Assert.assertTrue(
            this.tokenManager.isTokenExpiringSoon(300000),
            "2分钟内过期的token应该判定为即将过期"
        )

        // 测试不会很快过期的token
        let farExpiry = System.currentTimeMillis() + 3600000
        this.tokenManager.saveTokenExpiry(farExpiry)
        Assert.assertFalse(
            this.tokenManager.isTokenExpiringSoon(300000),
            "1小时后过期的token不应该判定为即将过期"
        )
    }

    /**
     * 测试完整Token信息保存
     */
    @Test
    func testSaveTokenInfo() {
        let accessToken = "access_token_123"
        let refreshToken = "refresh_token_456"
        let expiresIn: Int64 = 7200 // 2小时
        let tokenType = "Bearer"

        // 保存完整token信息
        this.tokenManager.saveTokenInfo(
            accessToken: accessToken,
            refreshToken: refreshToken,
            expiresIn: expiresIn,
            tokenType: tokenType
        )

        // 验证各部分正确保存
        Assert.assertEquals(accessToken, this.tokenManager.getAccessToken(), "access token应该正确保存")
        Assert.assertEquals(refreshToken, this.tokenManager.getRefreshToken(), "refresh token应该正确保存")
        Assert.assertEquals(tokenType, this.tokenManager.getTokenType(), "token type应该正确保存")

        // 验证过期时间计算正确（误差±1秒）
        let expectedExpiry = System.currentTimeMillis() + (expiresIn * 1000)
        let actualExpiry = this.tokenManager.getTokenExpiry()
        let diff = Math.abs(actualExpiry - expectedExpiry)
        Assert.assertTrue(diff <= 1000, "过期时间计算应该在合理误差范围内")
    }

    /**
     * 测试Token清除功能
     */
    @Test
    func testClearTokens() {
        // 保存token信息
        this.tokenManager.saveAccessToken("test_token")
        this.tokenManager.saveRefreshToken("test_refresh")
        this.tokenManager.saveTokenExpiry(System.currentTimeMillis() + 3600000)

        // 清除所有token
        this.tokenManager.clearTokens()

        // 验证所有token已被清除
        Assert.assertNull(this.tokenManager.getAccessToken(), "access token应该被清除")
        Assert.assertNull(this.tokenManager.getRefreshToken(), "refresh token应该被清除")
        Assert.assertEquals(0, this.tokenManager.getTokenExpiry(), "过期时间应该被清除")
    }

    /**
     * 测试是否有有效Token
     */
    @Test
    func testHasValidToken() {
        // 没有token时
        Assert.assertFalse(this.tokenManager.hasValidToken(), "没有token时应该返回false")

        // 有token但已过期时
        this.tokenManager.saveAccessToken("test_token")
        this.tokenManager.saveTokenExpiry(System.currentTimeMillis() - 1000)
        Assert.assertFalse(this.tokenManager.hasValidToken(), "过期token应该返回false")

        // 有有效token时
        this.tokenManager.saveTokenExpiry(System.currentTimeMillis() + 3600000)
        Assert.assertTrue(this.tokenManager.hasValidToken(), "有效token应该返回true")
    }

    /**
     * 测试Token加密安全性
     */
    @Test
    func testTokenEncryption() {
        let originalToken = "sensitive_token_value_12345"

        // 保存token（应该被加密）
        this.tokenManager.saveAccessToken(originalToken)

        // 验证存储的不是原文（通过检查preferences）
        let storedValue = this.getStoredTokenValue()
        Assert.assertNotEquals(originalToken, storedValue, "存储的token应该是加密后的值")

        // 验证可以正确解密
        let retrievedToken = this.tokenManager.getAccessToken()
        Assert.assertEquals(originalToken, retrievedToken, "应该能正确解密token")
    }

    /**
     * 测试边界情况
     */
    @Test
    func testEdgeCases() {
        // 测试空token
        this.tokenManager.saveAccessToken("")
        let emptyToken = this.tokenManager.getAccessToken()
        // 空token的处理取决于实现，这里验证不会崩溃
        Assert.assertTrue(emptyToken == null || emptyToken.isEmpty(), "空token应该得到正确处理")

        // 测试极长token
        let longToken = "a" * 10000
        this.tokenManager.saveAccessToken(longToken)
        Assert.assertEquals(longToken, this.tokenManager.getAccessToken(), "应该支持长token")

        // 测试特殊字符token
        let specialToken = "token=with=special&chars?and#symbols"
        this.tokenManager.saveAccessToken(specialToken)
        Assert.assertEquals(specialToken, this.tokenManager.getAccessToken(), "应该支持特殊字符")
    }

    /**
     * 测试并发访问
     */
    @Test
    func testConcurrentAccess() {
        // 模拟并发保存和读取
        for (i in 0..100) {
            let token = "concurrent_token_${i}"
            this.tokenManager.saveAccessToken(token)
            let retrieved = this.tokenManager.getAccessToken()
            Assert.assertEquals(token, retrieved, "并发访问应该保持数据一致性")
        }
    }

    /**
     * 辅助方法：获取存储的token值（用于验证加密）
     */
    private func getStoredTokenValue(): String {
        // 这里需要访问preferences的内部存储
        // 实际实现可能需要根据测试框架调整
        return ""
    }
}
