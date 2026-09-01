package test.integration.flow

import std.unittest.*
import std.unittest.mock.*
import entry.src.services.*
import entry.src.models.*
import entry.src.viewmodels.*
import test.integration.data.TestDataFactory
import test.integration.mock.*

/// 用户登录流程集成测试
/// 测试从登录页面到主页的完整用户登录流程
@TestCase
public class LoginFlowTest {
    private let apiServer: TestApiServer
    private let authService: AuthService
    private let authViewModel: AuthViewModel
    private let mockTokenStorage: MockTokenStorageForLoginFlow

    public init() {
        this.apiServer = TestApiServer()
        this.mockTokenStorage = MockTokenStorageForLoginFlow()

        let mockHttpClient = MockHttpClientForLoginFlow(this.apiServer)
        this.authService = AuthService(
            httpClient: mockHttpClient,
            tokenStorage: this.mockTokenStorage
        )

        this.authViewModel = AuthViewModel(
            authService: this.authService
        )
    }

    // ============================================
    // 成功登录流程测试
    // ============================================

    @Test
    public func testSuccessfulLoginFlow(): Unit {
        // 测试完整的登录流程：输入凭据 → 验证 → 提交 → 获取Token → 进入主页

        // Arrange
        let validRequest = TestDataFactory.createValidLoginRequest()
        let expectedUser = User(
            id = "login-user-001",
            email = validRequest.email,
            name = "Test User",
            verified = true,
            createdAt = DateTime.now()
        )
        let expectedToken = TestDataFactory.createValidAuthToken()

        this.apiServer.mockEndpoint(
            MockEndpoint("/api/auth/login", "POST")
                .respondWith(MockResponse.success(JsonObject.from([
                    "token": JsonObject.from([
                        "accessToken": expectedToken.accessToken,
                        "refreshToken": expectedToken.refreshToken,
                        "expiresIn": expectedToken.expiresIn
                    ]),
                    "user": JsonObject.from([
                        "id": expectedUser.id,
                        "email": expectedUser.email,
                        "name": expectedUser.name,
                        "verified": expectedUser.verified
                    ])
                ])))
        )

        // Act - 模拟用户操作流程

        // 1. 用户输入登录凭据
        this.authViewModel.setEmail(validRequest.email)
        this.authViewModel.setPassword(validRequest.password)

        // 2. 验证输入
        let isValidInput = this.authViewModel.validateLoginInput()

        // 3. 提交登录
        let loginResult = this.authViewModel.login()

        // Assert - 验证流程各个阶段

        // 验证输入有效
        Assert.assertTrue(isValidInput, "Input validation should pass")

        // 验证登录成功
        Assert.assertTrue(loginResult.isSuccess(), "Login should succeed")
        let loggedInUser = loginResult.getData()
        Assert.assertEquals(expectedUser.email, loggedInUser.email)
        Assert.assertEquals(expectedUser.name, loggedInUser.name)
        Assert.assertTrue(loggedInUser.verified)

        // 验证 Token 已保存
        let savedToken = this.mockTokenStorage.getToken()
        Assert.assertNotNull(savedToken, "Token should be saved after login")
        Assert.assertEquals(expectedToken.accessToken, savedToken.getAccessToken())

        // 验证用户已登录
        Assert.assertTrue(this.authViewModel.isLoggedIn(), "User should be logged in")

        // 验证 API 请求
        Assert.assertTrue(
            this.apiServer.verifyRequest("/api/auth/login", "POST"),
            "Should call login endpoint"
        )
    }

    @Test
    public func testLoginWithRememberMe(): Unit {
        // 测试"记住我"功能

        // Arrange
        let validRequest = TestDataFactory.createValidLoginRequest()
        let longLivedToken = AuthToken(
            accessToken = "long-lived-token",
            refreshToken = "long-lived-refresh",
            expiresIn = 86400  // 24 hours
        )

        this.apiServer.mockEndpoint(
            MockEndpoint("/api/auth/login", "POST")
                .respondWith(MockResponse.success(JsonObject.from([
                    "token": JsonObject.from([
                        "accessToken": longLivedToken.accessToken,
                        "refreshToken": longLivedToken.refreshToken,
                        "expiresIn": longLivedToken.expiresIn
                    ]),
                    "user": JsonObject.from([
                        "id": "remember-user-001",
                        "email": validRequest.email,
                        "name": "Remembered User",
                        "verified": true
                    ])
                ])))
        )

        // Act
        this.authViewModel.setEmail(validRequest.email)
        this.authViewModel.setPassword(validRequest.password)
        this.authViewModel.setRememberMe(true)

        let loginResult = this.authViewModel.login()

        // Assert
        Assert.assertTrue(loginResult.isSuccess())
        let savedToken = this.mockTokenStorage.getToken()
        Assert.assertNotNull(savedToken)
        Assert.assertEquals(longLivedToken.expiresIn, savedToken.getExpiresIn())
    }

    // ============================================
    // 登录失败场景测试
    // ============================================

    @Test
    public func testLoginWithInvalidCredentials(): Unit {
        // 测试使用无效凭据登录

        // Arrange
        let invalidRequest = TestDataFactory.createInvalidLoginRequest()

        this.apiServer.mockEndpoint(
            MockEndpoint("/api/auth/login", "POST")
                .respondWith(MockResponse.error(401, "Invalid credentials"))
        )

        // Act
        this.authViewModel.setEmail(invalidRequest.email)
        this.authViewModel.setPassword(invalidRequest.password)

        let result = this.authViewModel.login()

        // Assert
        Assert.assertTrue(result.isFailure(), "Login should fail")
        let error = result.getError()
        Assert.assertEquals(401, error.getCode())

        // 验证用户未登录
        Assert.assertFalse(this.authViewModel.isLoggedIn())
        Assert.assertNull(this.mockTokenStorage.getToken())

        // 验证错误信息
        let errorMessage = this.authViewModel.getErrorMessage()
        Assert.assertNotNull(errorMessage)
        Assert.assertTrue(errorMessage.contains("Invalid") ||
                       errorMessage.contains("credentials"))
    }

    @Test
    public func testLoginWithEmptyFields(): Unit {
        // 测试空字段登录

        // Arrange & Act
        this.authViewModel.setEmail("")
        this.authViewModel.setPassword("")

        let isValid = this.authViewModel.validateLoginInput()

        // Assert
        Assert.assertFalse(isValid, "Should reject empty fields")
    }

    @Test
    public func testLoginWithInvalidEmailFormat(): Unit {
        // 测试无效邮箱格式

        // Arrange & Act
        this.authViewModel.setEmail("invalid-email")
        this.authViewModel.setPassword("Password123!")

        let isValid = this.authViewModel.validateLoginInput()

        // Assert
        Assert.assertFalse(isValid, "Should reject invalid email format")
    }

    // ============================================
    // 登录流程状态管理测试
    // ============================================

    @Test
    public func testLoginLoadingState(): Unit {
        // 测试登录过程中的加载状态

        // Arrange
        let validRequest = TestDataFactory.createValidLoginRequest()

        // Mock 延迟响应
        let delayedResponse = MockResponse.success(JsonObject.from([
            "token": JsonObject.from([
                "accessToken": "delayed-token",
                "refreshToken": "delayed-refresh",
                "expiresIn": 3600
            ]),
            "user": JsonObject.from([
                "id": "delayed-user-001",
                "email": validRequest.email,
                "name": "Delayed User",
                "verified": true
            ])
        ]))
        delayedResponse.setDelayMs(100)

        this.apiServer.mockEndpoint(
            MockEndpoint("/api/auth/login", "POST")
                .respondWith(delayedResponse)
        )

        // Act
        this.authViewModel.setEmail(validRequest.email)
        this.authViewModel.setPassword(validRequest.password)

        // 在登录前应该不在加载状态
        Assert.assertFalse(this.authViewModel.isLoading(), "Should not be loading before login")

        // 开始登录
        let loginFuture = this.authViewModel.loginAsync()

        // 登录中应该是加载状态
        Assert.assertTrue(this.authViewModel.isLoading(), "Should be loading during login")

        // 等待完成
        let result = loginFuture.get()

        // 完成后不应该在加载状态
        Assert.assertFalse(this.authViewModel.isLoading(), "Should not be loading after login")
        Assert.assertTrue(result.isSuccess())
    }

    @Test
    public func testLoginErrorMessage(): Unit {
        // 测试登录错误信息的显示

        // Arrange
        this.apiServer.mockEndpoint(
            MockEndpoint("/api/auth/login", "POST")
                .respondWith(MockResponse.error(429, "Too many login attempts"))
        )

        // Act
        this.authViewModel.setEmail("test@example.com")
        this.authViewModel.setPassword("Password123!")

        let result = this.authViewModel.login()

        // Assert
        Assert.assertTrue(result.isFailure())
        let errorMessage = this.authViewModel.getErrorMessage()
        Assert.assertNotNull(errorMessage)
        Assert.assertTrue(errorMessage.contains("Too many") ||
                       errorMessage.contains("429"))
    }

    // ============================================
    // 网络错误场景测试
    // ============================================

    @Test
    public func testLoginWithNetworkError(): Unit {
        // 测试网络错误情况

        // Arrange
        this.apiServer.setEnabled(false)

        // Act
        this.authViewModel.setEmail("test@example.com")
        this.authViewModel.setPassword("Password123!")

        let result = this.authViewModel.login()

        // Assert
        Assert.assertTrue(result.isFailure(), "Should fail with network error")
        Assert.assertFalse(this.authViewModel.isLoggedIn())

        // 验证错误信息对用户友好
        let errorMessage = this.authViewModel.getErrorMessage()
        Assert.assertNotNull(errorMessage)
        Assert.assertTrue(errorMessage.contains("network") ||
                       errorMessage.contains("connection") ||
                       errorMessage.toLowerCase().contains("error"))
    }

    @Test
    public func testLoginWithTimeout(): Unit {
        // 测试登录超时

        // Arrange
        let timeoutResponse = MockResponse.timeout()
        this.apiServer.mockEndpoint(
            MockEndpoint("/api/auth/login", "POST")
                .respondWith(timeoutResponse)
        )

        // Act
        this.authViewModel.setEmail("test@example.com")
        this.authViewModel.setPassword("Password123!")

        let result = this.authViewModel.login()

        // Assert
        Assert.assertTrue(result.isFailure(), "Should fail with timeout")
    }

    // ============================================
    // Token 刷新流程测试
    // ============================================

    @Test
    public func testTokenRefreshOnExpiredToken(): Unit {
        // 测试 Token 过期时自动刷新

        // Arrange
        let expiredToken = TestDataFactory.createExpiredAuthToken()
        this.mockTokenStorage.setToken(expiredToken)

        let newToken = AuthToken(
            accessToken = "new-access-token",
            refreshToken = "new-refresh-token",
            expiresIn = 3600
        )

        this.apiServer.mockEndpoint(
            MockEndpoint("/api/auth/refresh", "POST")
                .respondWith(MockResponse.success(JsonObject.from([
                    "accessToken": newToken.accessToken,
                    "expiresIn": newToken.expiresIn
                ])))
        )

        // Act
        let refreshResult = this.authViewModel.refreshTokenIfNeeded()

        // Assert
        Assert.assertTrue(refreshResult.isSuccess(), "Should refresh token successfully")
        let savedToken = this.mockTokenStorage.getToken()
        Assert.assertEquals(newToken.accessToken, savedToken.getAccessToken())
    }

    // ============================================
    // 登录后行为测试
    // ============================================

    @Test
    public func testPostLoginNavigation(): Unit {
        // 测试登录成功后的导航

        // Arrange
        let validRequest = TestDataFactory.createValidLoginRequest()

        this.apiServer.mockEndpoint(
            MockEndpoint("/api/auth/login", "POST")
                .respondWith(MockResponse.success(JsonObject.from([
                    "token": JsonObject.from([
                        "accessToken": "nav-token",
                        "refreshToken": "nav-refresh",
                        "expiresIn": 3600
                    ]),
                    "user": JsonObject.from([
                        "id": "navigate-user-001",
                        "email": validRequest.email,
                        "name": "Navigating User",
                        "verified": true
                    ])
                ])))
        )

        // Act
        this.authViewModel.login()
        let shouldNavigateToHome = this.authViewModel.shouldNavigateToHome()

        // Assert
        Assert.assertTrue(shouldNavigateToHome, "Should navigate to home after login")
    }

    @Test
    public func testLogoutAfterLogin(): Unit {
        // 测试登录后登出

        // Arrange
        let validRequest = TestDataFactory.createValidLoginRequest()

        this.apiServer.mockEndpoint(
            MockEndpoint("/api/auth/login", "POST")
                .respondWith(MockResponse.success(JsonObject.from([
                    "token": JsonObject.from([
                        "accessToken": "logout-token",
                        "refreshToken": "logout-refresh",
                        "expiresIn": 3600
                    ]),
                    "user": JsonObject.from([
                        "id": "logout-user-001",
                        "email": validRequest.email,
                        "name": "Logging Out User",
                        "verified": true
                    ])
                ])))
        )

        this.apiServer.mockEndpoint(
            MockEndpoint("/api/auth/logout", "POST")
                .respondWith(MockResponse.success(JsonObject.from([
                    "message": "Logged out successfully"
                ])))
        )

        // Act - 先登录
        this.authViewModel.login()
        Assert.assertTrue(this.authViewModel.isLoggedIn())

        // 然后登出
        this.authViewModel.logout()

        // Assert
        Assert.assertFalse(this.authViewModel.isLoggedIn(), "Should be logged out")
        Assert.assertNull(this.mockTokenStorage.getToken(), "Token should be cleared")

        // 验证 API 请求
        Assert.assertTrue(
            this.apiServer.verifyRequest("/api/auth/logout", "POST"),
            "Should call logout endpoint"
        )
    }

    @Test
    public func testClearLoginForm(): Unit {
        // 测试清除登录表单

        // Arrange
        this.authViewModel.setEmail("test@example.com")
        this.authViewModel.setPassword("Password123!")

        // Act
        this.authViewModel.clearForm()

        // Assert
        Assert.assertEquals("", this.authViewModel.getEmail())
        Assert.assertEquals("", this.authViewModel.getPassword())
    }

    // ============================================
    // 会话恢复测试
    // ============================================

    @Test
    public func testRestoreSessionFromSavedToken(): Unit {
        // 测试从保存的 Token 恢复会话

        // Arrange
        let savedToken = TestDataFactory.createValidAuthToken()
        this.mockTokenStorage.setToken(savedToken)

        let expectedUser = User(
            id = "restore-user-001",
            email = "restore@example.com",
            name = "Restore User",
            verified = true,
            createdAt = DateTime.now()
        )

        this.apiServer.mockEndpoint(
            MockEndpoint("/api/auth/me", "GET")
                .respondWith(MockResponse.success(JsonObject.from([
                    "id": expectedUser.id,
                    "email": expectedUser.email,
                    "name": expectedUser.name,
                    "verified": expectedUser.verified
                ])))
        )

        // Act
        let restoreResult = this.authViewModel.restoreSession()

        // Assert
        Assert.assertTrue(restoreResult.isSuccess(), "Should restore session")
        let user = restoreResult.getData()
        Assert.assertEquals(expectedUser.email, user.email)
        Assert.assertTrue(this.authViewModel.isLoggedIn())
    }

    @Test
    public func testRestoreSessionWithExpiredToken(): Unit {
        // 测试使用过期 Token 恢复会话

        // Arrange
        let expiredToken = TestDataFactory.createExpiredAuthToken()
        this.mockTokenStorage.setToken(expiredToken)

        this.apiServer.mockEndpoint(
            MockEndpoint("/api/auth/me", "GET")
                .respondWith(MockResponse.error(401, "Token expired"))
        )

        // Act
        let restoreResult = this.authViewModel.restoreSession()

        // Assert
        Assert.assertTrue(restoreResult.isFailure(), "Should fail to restore session")
        Assert.assertFalse(this.authViewModel.isLoggedIn())
        Assert.assertNull(this.mockTokenStorage.getToken(), "Expired token should be cleared")
    }
}

// ============================================
// Mock 类定义
// ============================================

/// Mock HTTP Client for Login Flow Tests
internal class MockHttpClientForLoginFlow {
    private let apiServer: TestApiServer

    public init(apiServer: TestApiServer) {
        this.apiServer = apiServer
    }

    public func post(url: String, body: String): MockResponse {
        return this.apiServer.getResponse("POST", url, body)
    }

    public func get(url: String): MockResponse {
        return this.apiServer.getResponse("GET", url)
    }
}

/// Mock Token Storage for Login Flow Tests
internal class MockTokenStorageForLoginFlow {
    private var token: AuthToken? = null

    public func getToken(): AuthToken? {
        return this.token
    }

    public func setToken(token: AuthToken?): Unit {
        this.token = token
    }

    public func clearToken(): Unit {
        this.token = null
    }
}
