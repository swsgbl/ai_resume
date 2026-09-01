package test.integration.flow

import std.unittest.*
import std.unittest.mock.*
import entry.src.services.*
import entry.src.models.*
import entry.src.viewmodels.*
import test.integration.data.TestDataFactory
import test.integration.mock.*

/// 用户注册流程集成测试
/// 测试从注册页面到主页的完整用户注册流程
@TestCase
public class RegistrationFlowTest {
    private let apiServer: TestApiServer
    private let authService: AuthService
    private let authViewModel: AuthViewModel
    private let mockTokenStorage: MockTokenStorageForFlow

    public init() {
        this.apiServer = TestApiServer()
        this.mockTokenStorage = MockTokenStorageForFlow()

        let mockHttpClient = MockHttpClientForFlow(this.apiServer)
        this.authService = AuthService(
            httpClient: mockHttpClient,
            tokenStorage: this.mockTokenStorage
        )

        this.authViewModel = AuthViewModel(
            authService: this.authService
        )
    }

    // ============================================
    // 成功注册流程测试
    // ============================================

    @Test
    public func testSuccessfulRegistrationFlow(): Unit {
        // 测试完整的注册流程：填写信息 → 提交 → 验证 → 登录 → 进入主页

        // Arrange
        let validRequest = TestDataFactory.createValidRegisterRequest()
        let expectedUser = User(
            id = "new-user-001",
            email = validRequest.email,
            name = validRequest.name,
            verified = false,
            createdAt = DateTime.now()
        )
        let expectedToken = TestDataFactory.createValidAuthToken()

        this.apiServer.mockEndpoint(
            MockEndpoint("/api/auth/register", "POST")
                .respondWith(MockResponse.success(JsonObject.from([
                    "user": JsonObject.from([
                        "id": expectedUser.id,
                        "email": expectedUser.email,
                        "name": expectedUser.name,
                        "verified": expectedUser.verified
                    ]),
                    "token": JsonObject.from([
                        "accessToken": expectedToken.accessToken,
                        "refreshToken": expectedToken.refreshToken,
                        "expiresIn": expectedToken.expiresIn
                    ])
                ])))
        )

        // Act - 模拟用户操作流程

        // 1. 用户输入注册信息
        this.authViewModel.setEmail(validRequest.email)
        this.authViewModel.setPassword(validRequest.password)
        this.authViewModel.setName(validRequest.name)
        this.authViewModel.setConfirmPassword(validRequest.confirmPassword)

        // 2. 验证输入
        let isValidInput = this.authViewModel.validateRegistrationInput()

        // 3. 提交注册
        let registrationResult = this.authViewModel.register()

        // Assert - 验证流程各个阶段

        // 验证输入有效
        Assert.assertTrue(isValidInput, "Input validation should pass")

        // 验证注册成功
        Assert.assertTrue(registrationResult.isSuccess(), "Registration should succeed")
        let registeredUser = registrationResult.getData()
        Assert.assertEquals(expectedUser.email, registeredUser.email)
        Assert.assertEquals(expectedUser.name, registeredUser.name)
        Assert.assertFalse(registeredUser.verified, "New user should not be verified")

        // 验证 Token 已保存
        let savedToken = this.mockTokenStorage.getToken()
        Assert.assertNotNull(savedToken, "Token should be saved after registration")
        Assert.assertEquals(expectedToken.accessToken, savedToken.getAccessToken())

        // 验证用户已登录
        Assert.assertTrue(this.authViewModel.isLoggedIn(), "User should be logged in after registration")

        // 验证 API 请求
        Assert.assertTrue(
            this.apiServer.verifyRequest("/api/auth/register", "POST"),
            "Should call registration endpoint"
        )
    }

    @Test
    public func testRegistrationWithAutoLogin(): Unit {
        // 测试注册后自动登录

        // Arrange
        let validRequest = TestDataFactory.createValidRegisterRequest()
        let expectedToken = TestDataFactory.createValidAuthToken()

        this.apiServer.mockEndpoint(
            MockEndpoint("/api/auth/register", "POST")
                .respondWith(MockResponse.success(JsonObject.from([
                    "user": JsonObject.from([
                        "id": "autologin-user-001",
                        "email": validRequest.email,
                        "name": validRequest.name,
                        "verified": false
                    ]),
                    "token": JsonObject.from([
                        "accessToken": expectedToken.accessToken,
                        "refreshToken": expectedToken.refreshToken,
                        "expiresIn": expectedToken.expiresIn
                    ])
                ])))
        )

        // Act
        this.authViewModel.setEmail(validRequest.email)
        this.authViewModel.setPassword(validRequest.password)
        this.authViewModel.setName(validRequest.name)
        this.authViewModel.setConfirmPassword(validRequest.confirmPassword)

        let registrationResult = this.authViewModel.register()

        // Assert
        Assert.assertTrue(registrationResult.isSuccess())
        Assert.assertTrue(this.authViewModel.isLoggedIn(), "Should auto-login after registration")

        // 验证可以访问受保护的资源
        this.apiServer.mockEndpoint(
            MockEndpoint("/api/auth/me", "GET")
                .respondWith(MockResponse.success(JsonObject.from([
                    "id": "autologin-user-001",
                    "email": validRequest.email,
                    "name": validRequest.name,
                    "verified": false
                ])))
        )

        let currentUserResult = this.authViewModel.getCurrentUser()
        Assert.assertTrue(currentUserResult.isSuccess(), "Should be able to get current user")
    }

    // ============================================
    // 注册失败场景测试
    // ============================================

    @Test
    public func testRegistrationWithExistingEmail(): Unit {
        // 测试使用已存在的邮箱注册

        // Arrange
        let existingEmail = "existing@example.com"
        let validRequest = RegisterRequest(
            email = existingEmail,
            password = "Password123!",
            name = "Test User",
            confirmPassword = "Password123!"
        )

        this.apiServer.mockEndpoint(
            MockEndpoint("/api/auth/register", "POST")
                .respondWith(MockResponse.error(409, "Email already exists"))
        )

        // Act
        this.authViewModel.setEmail(existingEmail)
        this.authViewModel.setPassword(validRequest.password)
        this.authViewModel.setName(validRequest.name)
        this.authViewModel.setConfirmPassword(validRequest.confirmPassword)

        let result = this.authViewModel.register()

        // Assert
        Assert.assertTrue(result.isFailure(), "Registration should fail")
        let error = result.getError()
        Assert.assertEquals(409, error.getCode())
        Assert.assertTrue(error.getMessage().contains("already exists"))

        // 验证用户未登录
        Assert.assertFalse(this.authViewModel.isLoggedIn())
        Assert.assertNull(this.mockTokenStorage.getToken())
    }

    @Test
    public func testRegistrationWithWeakPassword(): Unit {
        // 测试使用弱密码注册

        // Arrange
        let weakPassword = "123"

        // Act
        this.authViewModel.setEmail("test@example.com")
        this.authViewModel.setPassword(weakPassword)
        this.authViewModel.setName("Test User")
        this.authViewModel.setConfirmPassword(weakPassword)

        let isValid = this.authViewModel.validateRegistrationInput()

        // Assert
        Assert.assertFalse(isValid, "Should reject weak password")
    }

    @Test
    public func testRegistrationWithPasswordMismatch(): Unit {
        // 测试密码不匹配

        // Arrange
        let password = "Password123!"
        let confirmPassword = "DifferentPassword123!"

        // Act
        this.authViewModel.setEmail("test@example.com")
        this.authViewModel.setPassword(password)
        this.authViewModel.setName("Test User")
        this.authViewModel.setConfirmPassword(confirmPassword)

        let isValid = this.authViewModel.validateRegistrationInput()

        // Assert
        Assert.assertFalse(isValid, "Should reject password mismatch")
    }

    @Test
    public func testRegistrationWithInvalidEmail(): Unit {
        // 测试无效邮箱格式

        // Arrange
        let invalidEmail = "invalid-email"

        // Act
        this.authViewModel.setEmail(invalidEmail)
        this.authViewModel.setPassword("Password123!")
        this.authViewModel.setName("Test User")
        this.authViewModel.setConfirmPassword("Password123!")

        let isValid = this.authViewModel.validateRegistrationInput()

        // Assert
        Assert.assertFalse(isValid, "Should reject invalid email")
    }

    // ============================================
    // 注册流程状态管理测试
    // ============================================

    @Test
    public func testRegistrationLoadingState(): Unit {
        // 测试注册过程中的加载状态

        // Arrange
        let validRequest = TestDataFactory.createValidRegisterRequest()

        // Mock 延迟响应
        let delayedResponse = MockResponse.success(JsonObject.from([
            "user": JsonObject.from([
                "id": "delayed-user-001",
                "email": validRequest.email,
                "name": validRequest.name,
                "verified": false
            ]),
            "token": JsonObject.from([
                "accessToken": "delayed-token",
                "refreshToken": "delayed-refresh",
                "expiresIn": 3600
            ])
        ]))
        delayedResponse.setDelayMs(100)

        this.apiServer.mockEndpoint(
            MockEndpoint("/api/auth/register", "POST")
                .respondWith(delayedResponse)
        )

        // Act
        this.authViewModel.setEmail(validRequest.email)
        this.authViewModel.setPassword(validRequest.password)
        this.authViewModel.setName(validRequest.name)
        this.authViewModel.setConfirmPassword(validRequest.confirmPassword)

        // 在注册前应该不在加载状态
        Assert.assertFalse(this.authViewModel.isLoading(), "Should not be loading before registration")

        // 开始注册
        let registrationFuture = this.authViewModel.registerAsync()

        // 注册中应该是加载状态
        Assert.assertTrue(this.authViewModel.isLoading(), "Should be loading during registration")

        // 等待完成
        let result = registrationFuture.get()

        // 完成后不应该在加载状态
        Assert.assertFalse(this.authViewModel.isLoading(), "Should not be loading after registration")
        Assert.assertTrue(result.isSuccess())
    }

    @Test
    public func testRegistrationErrorMessage(): Unit {
        // 测试注册错误信息的显示

        // Arrange
        this.apiServer.mockEndpoint(
            MockEndpoint("/api/auth/register", "POST")
                .respondWith(MockResponse.error(400, "Invalid registration data"))
        )

        // Act
        this.authViewModel.setEmail("test@example.com")
        this.authViewModel.setPassword("Password123!")
        this.authViewModel.setName("Test User")
        this.authViewModel.setConfirmPassword("Password123!")

        let result = this.authViewModel.register()

        // Assert
        Assert.assertTrue(result.isFailure())
        let errorMessage = this.authViewModel.getErrorMessage()
        Assert.assertNotNull(errorMessage)
        Assert.assertTrue(errorMessage.contains("Invalid registration data") ||
                       errorMessage.contains("400"))
    }

    // ============================================
    // 网络错误场景测试
    // ============================================

    @Test
    public func testRegistrationWithNetworkError(): Unit {
        // 测试网络错误情况

        // Arrange
        this.apiServer.setEnabled(false)

        // Act
        this.authViewModel.setEmail("test@example.com")
        this.authViewModel.setPassword("Password123!")
        this.authViewModel.setName("Test User")
        this.authViewModel.setConfirmPassword("Password123!")

        let result = this.authViewModel.register()

        // Assert
        Assert.assertTrue(result.isFailure(), "Should fail with network error")
        Assert.assertFalse(this.authViewModel.isLoggedIn())

        // 验证错误信息对用户友好
        let errorMessage = this.authViewModel.getErrorMessage()
        Assert.assertNotNull(errorMessage)
    }

    // ============================================
    // 注册后行为测试
    // ============================================

    @Test
    public func testPostRegistrationNavigation(): Unit {
        // 测试注册成功后的导航

        // Arrange
        let validRequest = TestDataFactory.createValidRegisterRequest()

        this.apiServer.mockEndpoint(
            MockEndpoint("/api/auth/register", "POST")
                .respondWith(MockResponse.success(JsonObject.from([
                    "user": JsonObject.from([
                        "id": "navigate-user-001",
                        "email": validRequest.email,
                        "name": validRequest.name,
                        "verified": false
                    ]),
                    "token": JsonObject.from([
                        "accessToken": "nav-token",
                        "refreshToken": "nav-refresh",
                        "expiresIn": 3600
                    ])
                ])))
        )

        // Act
        this.authViewModel.register()
        let shouldNavigateToHome = this.authViewModel.shouldNavigateToHome()
        let shouldShowVerification = this.authViewModel.shouldShowVerificationPrompt()

        // Assert
        Assert.assertTrue(shouldNavigateToHome, "Should navigate to home after registration")
        Assert.assertTrue(shouldShowVerification, "Should show verification prompt for new user")
    }

    @Test
    public func testClearRegistrationForm(): Unit {
        // 测试清除注册表单

        // Arrange
        this.authViewModel.setEmail("test@example.com")
        this.authViewModel.setPassword("Password123!")
        this.authViewModel.setName("Test User")
        this.authViewModel.setConfirmPassword("Password123!")

        // Act
        this.authViewModel.clearForm()

        // Assert
        Assert.assertEquals("", this.authViewModel.getEmail())
        Assert.assertEquals("", this.authViewModel.getPassword())
        Assert.assertEquals("", this.authViewModel.getName())
        Assert.assertEquals("", this.authViewModel.getConfirmPassword())
    }
}

// ============================================
// Mock 类定义
// ============================================

/// Mock HTTP Client for Flow Tests
internal class MockHttpClientForFlow {
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

/// Mock Token Storage for Flow Tests
internal class MockTokenStorageForFlow {
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
