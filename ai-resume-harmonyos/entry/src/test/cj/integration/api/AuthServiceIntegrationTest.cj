package test.integration.api

import std.unittest.*
import std.unittest.mock.*
import entry.src.services.*
import entry.src.models.*
import test.integration.data.TestDataFactory
import test.integration.mock.*

/// 认证服务集成测试
/// 测试 AuthService 与 Mock API 服务器的集成
@TestCase
public class AuthServiceIntegrationTest {
    private let apiServer: TestApiServer
    private let authService: AuthService
    private let mockHttpClient: MockHttpClientForAuth
    private let mockTokenStorage: MockTokenStorageForAuth

    public init() {
        // 初始化 Mock API 服务器
        this.apiServer = TestApiServer()

        // 初始化 Mock Token Storage
        this.mockTokenStorage = MockTokenStorageForAuth()

        // 初始化 Mock HTTP Client
        this.mockHttpClient = MockHttpClientForAuth(this.apiServer)

        // 创建 AuthService 实例
        this.authService = AuthService(
            httpClient: this.mockHttpClient,
            tokenStorage: this.mockTokenStorage
        )
    }

    // ============================================
    // 注册功能测试
    // ============================================

    @Test
    public func testRegisterSuccess(): Unit {
        // Arrange
        let request = TestDataFactory.createValidRegisterRequest()
        this.apiServer.mockEndpoint(
            MockEndpoint("/api/auth/register", "POST")
                .respondWith(MockResponse.success(JsonObject.from([
                    "user": JsonObject.from([
                        "id": "new-user-001",
                        "email": request.email,
                        "name": request.name,
                        "verified": false
                    ]),
                    "token": JsonObject.from([
                        "accessToken": "new-access-token",
                        "refreshToken": "new-refresh-token",
                        "expiresIn": 3600
                    ])
                ])))
        )

        // Act
        let result = this.authService.register(
            request.email,
            request.password,
            request.name
        )

        // Assert
        Assert.assertTrue(result.isSuccess(), "Registration should succeed")
        let user = result.getData()
        Assert.assertEquals(request.email, user.email)
        Assert.assertEquals(request.name, user.name)
        Assert.assertFalse(user.verified)

        // 验证 API 请求
        Assert.assertTrue(
            this.apiServer.verifyRequest("/api/auth/register", "POST"),
            "Should call register endpoint"
        )
    }

    @Test
    public func testRegisterWithExistingEmail(): Unit {
        // Arrange
        let request = TestDataFactory.createValidRegisterRequest()
        this.apiServer.mockEndpoint(
            MockEndpoint("/api/auth/register", "POST")
                .respondWith(MockResponse.error(409, "Email already exists"))
        )

        // Act
        let result = this.authService.register(
            request.email,
            request.password,
            request.name
        )

        // Assert
        Assert.assertTrue(result.isFailure(), "Registration should fail")
        let error = result.getError()
        Assert.assertEquals(409, error.getCode())
        Assert.assertTrue(error.getMessage().contains("already exists"))
    }

    @Test
    public func testRegisterWithInvalidEmail(): Unit {
        // Arrange
        let invalidEmail = "invalid-email-format"

        // Act
        let result = this.authService.register(
            invalidEmail,
            "Password123!",
            "Test User"
        )

        // Assert
        Assert.assertTrue(result.isFailure(), "Should validate email format")
    }

    @Test
    public func testRegisterWithWeakPassword(): Unit {
        // Arrange
        let weakPassword = "123"

        // Act
        let result = this.authService.register(
            "test@example.com",
            weakPassword,
            "Test User"
        )

        // Assert
        Assert.assertTrue(result.isFailure(), "Should validate password strength")
    }

    // ============================================
    // 登录功能测试
    // ============================================

    @Test
    public func testLoginSuccess(): Unit {
        // Arrange
        let request = TestDataFactory.createValidLoginRequest()
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
                        "id": "test-user-001",
                        "email": request.email,
                        "name": "Test User",
                        "verified": true
                    ])
                ])))
        )

        // Act
        let result = this.authService.login(
            request.email,
            request.password
        )

        // Assert
        Assert.assertTrue(result.isSuccess(), "Login should succeed")
        let user = result.getData()
        Assert.assertEquals(request.email, user.email)
        Assert.assertTrue(user.verified)

        // 验证 Token 被保存
        let savedToken = this.mockTokenStorage.getToken()
        Assert.assertNotNull(savedToken, "Token should be saved")
        Assert.assertEquals(expectedToken.accessToken, savedToken.getAccessToken())

        // 验证 API 请求
        Assert.assertTrue(
            this.apiServer.verifyRequest("/api/auth/login", "POST"),
            "Should call login endpoint"
        )
    }

    @Test
    public func testLoginWithInvalidCredentials(): Unit {
        // Arrange
        let request = TestDataFactory.createInvalidLoginRequest()
        this.apiServer.mockEndpoint(
            MockEndpoint("/api/auth/login", "POST")
                .respondWith(MockResponse.error(401, "Invalid credentials"))
        )

        // Act
        let result = this.authService.login(
            request.email,
            request.password
        )

        // Assert
        Assert.assertTrue(result.isFailure(), "Login should fail")
        let error = result.getError()
        Assert.assertEquals(401, error.getCode())
    }

    @Test
    public func testLoginWithNetworkError(): Unit {
        // Arrange
        this.apiServer.setEnabled(false)

        // Act
        let result = this.authService.login(
            "test@example.com",
            "password"
        )

        // Assert
        Assert.assertTrue(result.isFailure(), "Should handle network error")
    }

    @Test
    public func testLoginSavesToken(): Unit {
        // Arrange
        let request = TestDataFactory.createValidLoginRequest()
        let expectedToken = TestDataFactory.createValidAuthToken()

        this.apiServer.scenarioLoginSuccess()

        // Act
        let result = this.authService.login(
            request.email,
            request.password
        )

        // Assert
        Assert.assertTrue(result.isSuccess())
        let savedToken = this.mockTokenStorage.getToken()
        Assert.assertNotNull(savedToken)
        Assert.assertEquals(expectedToken.accessToken, savedToken.getAccessToken())
    }

    // ============================================
    // Token 刷新功能测试
    // ============================================

    @Test
    public func testRefreshTokenSuccess(): Unit {
        // Arrange
        let oldRefreshToken = "old-refresh-token"
        let newAccessToken = "new-access-token"

        this.mockTokenStorage.setToken(TestDataFactory.createValidAuthToken())
        this.apiServer.mockEndpoint(
            MockEndpoint("/api/auth/refresh", "POST")
                .respondWith(MockResponse.success(JsonObject.from([
                    "accessToken": newAccessToken,
                    "expiresIn": 3600
                ])))
        )

        // Act
        let result = this.authService.refreshToken()

        // Assert
        Assert.assertTrue(result.isSuccess(), "Token refresh should succeed")
        let newToken = result.getData()
        Assert.assertEquals(newAccessToken, newToken.getAccessToken())

        // 验证新 Token 被保存
        let savedToken = this.mockTokenStorage.getToken()
        Assert.assertEquals(newAccessToken, savedToken.getAccessToken())
    }

    @Test
    public func testRefreshTokenWithInvalidToken(): Unit {
        // Arrange
        this.mockTokenStorage.setToken(null)
        this.apiServer.mockEndpoint(
            MockEndpoint("/api/auth/refresh", "POST")
                .respondWith(MockResponse.error(401, "Invalid refresh token"))
        )

        // Act
        let result = this.authService.refreshToken()

        // Assert
        Assert.assertTrue(result.isFailure(), "Should fail with invalid token")
    }

    // ============================================
    // 登出功能测试
    // ============================================

    @Test
    public func testLogoutSuccess(): Unit {
        // Arrange
        this.mockTokenStorage.setToken(TestDataFactory.createValidAuthToken())
        this.apiServer.mockEndpoint(
            MockEndpoint("/api/auth/logout", "POST")
                .respondWith(MockResponse.success(JsonObject.from([
                    "message": "Logged out successfully"
                ])))
        )

        // Act
        this.authService.logout()

        // Assert
        let savedToken = this.mockTokenStorage.getToken()
        Assert.assertNull(savedToken, "Token should be cleared")

        // 验证 API 请求
        Assert.assertTrue(
            this.apiServer.verifyRequest("/api/auth/logout", "POST"),
            "Should call logout endpoint"
        )
    }

    @Test
    public func testLogoutClearsToken(): Unit {
        // Arrange
        let token = TestDataFactory.createValidAuthToken()
        this.mockTokenStorage.setToken(token)

        // Act
        this.authService.logout()

        // Assert
        let savedToken = this.mockTokenStorage.getToken()
        Assert.assertNull(savedToken)
    }

    // ============================================
    // 用户信息获取测试
    // ============================================

    @Test
    public func testGetCurrentUser(): Unit {
        // Arrange
        let expectedUser = TestDataFactory.createValidUser()
        this.mockTokenStorage.setToken(TestDataFactory.createValidAuthToken())

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
        let result = this.authService.getCurrentUser()

        // Assert
        Assert.assertTrue(result.isSuccess())
        let user = result.getData()
        Assert.assertEquals(expectedUser.id, user.id)
        Assert.assertEquals(expectedUser.email, user.email)
        Assert.assertEquals(expectedUser.name, user.name)
    }

    @Test
    public func testGetCurrentUserWithoutToken(): Unit {
        // Arrange
        this.mockTokenStorage.setToken(null)

        // Act
        let result = this.authService.getCurrentUser()

        // Assert
        Assert.assertTrue(result.isFailure(), "Should fail without token")
    }

    // ============================================
    // 集成场景测试
    // ============================================

    @Test
    public func testCompleteAuthFlow(): Unit {
        // 测试完整的认证流程：注册 → 登录 → 获取用户 → 登出

        // 1. 注册
        let registerRequest = TestDataFactory.createValidRegisterRequest()
        this.apiServer.mockEndpoint(
            MockEndpoint("/api/auth/register", "POST")
                .respondWith(MockResponse.success(JsonObject.from([
                    "user": JsonObject.from([
                        "id": "flow-user-001",
                        "email": registerRequest.email,
                        "name": registerRequest.name,
                        "verified": false
                    ]),
                    "token": JsonObject.from([
                        "accessToken": "register-token",
                        "refreshToken": "register-refresh",
                        "expiresIn": 3600
                    ])
                ])))
        )

        let registerResult = this.authService.register(
            registerRequest.email,
            registerRequest.password,
            registerRequest.name
        )
        Assert.assertTrue(registerResult.isSuccess(), "Registration should succeed")

        // 2. 登出
        this.authService.logout()
        Assert.assertNull(this.mockTokenStorage.getToken())

        // 3. 登录
        let loginRequest = TestDataFactory.createValidLoginRequest()
        this.apiServer.mockEndpoint(
            MockEndpoint("/api/auth/login", "POST")
                .respondWith(MockResponse.success(JsonObject.from([
                    "token": JsonObject.from([
                        "accessToken": "login-token",
                        "refreshToken": "login-refresh",
                        "expiresIn": 3600
                    ]),
                    "user": JsonObject.from([
                        "id": "flow-user-001",
                        "email": loginRequest.email,
                        "name": "Test User",
                        "verified": true
                    ])
                ])))
        )

        let loginResult = this.authService.login(
            loginRequest.email,
            loginRequest.password
        )
        Assert.assertTrue(loginResult.isSuccess(), "Login should succeed")

        // 4. 获取当前用户
        this.apiServer.mockEndpoint(
            MockEndpoint("/api/auth/me", "GET")
                .respondWith(MockResponse.success(JsonObject.from([
                    "id": "flow-user-001",
                    "email": loginRequest.email,
                    "name": "Test User",
                    "verified": true
                ])))
        )

        let userResult = this.authService.getCurrentUser()
        Assert.assertTrue(userResult.isSuccess(), "Should get current user")

        // 验证完整的请求序列
        Assert.assertEquals(4, this.apiServer.getRequestCount("/api/auth/", "POST") +
                               this.apiServer.getRequestCount("/api/auth/", "GET"))
    }
}

// ============================================
// Mock 类定义
// ============================================

/// Mock HTTP Client for Auth Service
internal class MockHttpClientForAuth {
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

/// Mock Token Storage for Auth Service
internal class MockTokenStorageForAuth {
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
