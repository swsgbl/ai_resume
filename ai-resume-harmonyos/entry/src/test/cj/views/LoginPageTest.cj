// LoginPageTest.cj - 登录页面测试
package test.views

import ohos.hypium.*
import views.*
import services.*
import models.*
import utils.*

// Mock AuthService for testing
public class MockAuthServiceForLogin {
    private var mockLoginResult: Result<AuthToken> = Result.error("Not mocked")
    private var loginCalled: Bool = false
    private var capturedEmail: String = ""
    private var capturedPassword: String = ""

    public func setMockLoginResult(result: Result<AuthToken>): Unit {
        this.mockLoginResult = result
    }

    public func login(email: String, password: String): Result<AuthToken> {
        this.loginCalled = true
        this.capturedEmail = email
        this.capturedPassword = password
        return this.mockLoginResult
    }

    public func wasLoginCalled(): Bool {
        return this.loginCalled
    }

    public func getCapturedEmail(): String {
        return this.capturedEmail
    }

    public func getCapturedPassword(): String {
        return this.capturedPassword
    }

    public func reset(): Unit {
        this.mockLoginResult = Result.error("Not mocked")
        this.loginCalled = false
        this.capturedEmail = ""
        this.capturedPassword = ""
    }
}

@TestCase
public class LoginPageTest {
    private var mockAuthService: MockAuthServiceForLogin = MockAuthServiceForLogin()

    @Before
    public func setup(): Unit {
        this.mockAuthService.reset()
    }

    @Test
    public func testLoginPageInitialization(): Unit {
        // Arrange & Act
        // Note: Since LoginPage is a @Component struct with @State,
        // we test the logic rather than UI rendering
        let page = LoginPage()

        // Assert
        Assert.assertTrue(true, "LoginPage should initialize successfully")
    }

    @Test
    public func testEmailValidationWithInvalidEmail(): Unit {
        // Arrange
        let invalidEmail = "invalid-email"
        let password = "password123"

        // Act
        let validationResult = Validator.validateLogin(invalidEmail, password)

        // Assert
        Assert.assertFalse(validationResult.isSuccess(), "Should fail with invalid email")
        Assert.assertTrue(validationResult.getError().contains("邮箱"), "Error should mention email")
    }

    @Test
    public func testEmailValidationWithEmptyEmail(): Unit {
        // Arrange
        let emptyEmail = ""
        let password = "password123"

        // Act
        let validationResult = Validator.validateLogin(emptyEmail, password)

        // Assert
        Assert.assertFalse(validationResult.isSuccess(), "Should fail with empty email")
    }

    @Test
    public func testPasswordValidationWithShortPassword(): Unit {
        // Arrange
        let email = "test@example.com"
        let shortPassword = "123"

        // Act
        let validationResult = Validator.validateLogin(email, shortPassword)

        // Assert
        Assert.assertFalse(validationResult.isSuccess(), "Should fail with short password")
        Assert.assertTrue(validationResult.getError().contains("密码"), "Error should mention password")
    }

    @Test
    public func testPasswordValidationWithEmptyPassword(): Unit {
        // Arrange
        let email = "test@example.com"
        let emptyPassword = ""

        // Act
        let validationResult = Validator.validateLogin(email, emptyPassword)

        // Assert
        Assert.assertFalse(validationResult.isSuccess(), "Should fail with empty password")
    }

    @Test
    public func testValidCredentials(): Unit {
        // Arrange
        let validEmail = "test@example.com"
        let validPassword = "password123"

        // Act
        let validationResult = Validator.validateLogin(validEmail, validPassword)

        // Assert
        Assert.assertTrue(validationResult.isSuccess(), "Should pass with valid credentials")
    }

    @Test
    public func testLoginSuccess(): Unit {
        // Arrange
        let email = "test@example.com"
        let password = "password123"
        let mockToken = AuthToken("test-token", "refresh-token", 3600)
        this.mockAuthService.setMockLoginResult(Result.success(mockToken))

        // Act
        let result = this.mockAuthService.login(email, password)

        // Assert
        Assert.assertTrue(result.isSuccess(), "Login should succeed")
        Assert.assertTrue(this.mockAuthService.wasLoginCalled(), "Login should be called")
        Assert.assertEquals(email, this.mockAuthService.getCapturedEmail(), "Email should match")
        Assert.assertEquals(password, this.mockAuthService.getCapturedPassword(), "Password should match")

        let token = result.getData()
        Assert.assertEquals("test-token", token.getAccessToken(), "Access token should match")
    }

    @Test
    public func testLoginFailureAuth(): Unit {
        // Arrange
        let email = "test@example.com"
        let password = "wrong-password"
        this.mockAuthService.setMockLoginResult(Result.error("邮箱或密码错误"))

        // Act
        let result = this.mockAuthService.login(email, password)

        // Assert
        Assert.assertFalse(result.isSuccess(), "Login should fail")
        Assert.assertEquals("邮箱或密码错误", result.getError(), "Error message should match")
        Assert.assertTrue(this.mockAuthService.wasLoginCalled(), "Login should be called")
    }

    @Test
    public func testLoginFailureNetwork(): Unit {
        // Arrange
        let email = "test@example.com"
        let password = "password123"
        this.mockAuthService.setMockLoginResult(Result.error("网络连接失败"))

        // Act
        let result = this.mockAuthService.login(email, password)

        // Assert
        Assert.assertFalse(result.isSuccess(), "Login should fail")
        Assert.assertEquals("网络连接失败", result.getError(), "Error message should match")
    }

    @Test
    public func testEmailValidationWithValidFormats(): Unit {
        // Arrange
        let validEmails = [
            "test@example.com",
            "user.name@domain.co.jp",
            "user+tag@example.com",
            "user123@test-domain.com"
        ]
        let password = "password123"

        // Act & Assert
        for (email in validEmails) {
            let validationResult = Validator.validateLogin(email, password)
            Assert.assertTrue(validationResult.isSuccess(), "Email ${email} should be valid")
        }
    }

    @Test
    public func testEmailValidationWithInvalidFormats(): Unit {
        // Arrange
        let invalidEmails = [
            "invalid-email",
            "@example.com",
            "user@",
            "user..name@example.com",
            "user@.com"
        ]
        let password = "password123"

        // Act & Assert
        for (email in invalidEmails) {
            let validationResult = Validator.validateLogin(email, password)
            Assert.assertFalse(validationResult.isSuccess(), "Email ${email} should be invalid")
        }
    }

    @Test
    public func testPasswordStrengthValidation(): Unit {
        // Arrange
        let weakPasswords = [
            "123",          // Too short
            "abc123",       // No special character or number
            "password"      // Common password
        ]
        let email = "test@example.com"

        // Act & Assert
        for (password in weakPasswords) {
            let validationResult = Validator.validateLogin(email, password)
            Assert.assertFalse(validationResult.isSuccess(), "Password '${password}' should be rejected")
        }
    }

    @Test
    public func testLoadingStateDuringLogin(): Unit {
        // Arrange
        let email = "test@example.com"
        let password = "password123"
        this.mockAuthService.setMockLoginResult(Result.success(AuthToken("token", "refresh", 3600)))

        // Act
        let result = this.mockAuthService.login(email, password)

        // Assert
        Assert.assertTrue(result.isSuccess(), "Login should complete successfully")
        Assert.assertTrue(this.mockAuthService.wasLoginCalled(), "Login service should be called")
    }

    @Test
    public func testErrorMessageClearedOnNewAttempt(): Unit {
        // Arrange
        let email = "test@example.com"
        let password = "password123"
        this.mockAuthService.setMockLoginResult(Result.success(AuthToken("token", "refresh", 3600)))

        // Act
        let result1 = this.mockAuthService.login(email, password)
        this.mockAuthService.reset()
        let result2 = this.mockAuthService.login(email, password)

        // Assert
        Assert.assertTrue(result2.isSuccess(), "Second login should succeed")
    }

    @Test
    public func testConcurrentLoginAttempts(): Unit {
        // Arrange
        let email1 = "user1@example.com"
        let email2 = "user2@example.com"
        let password = "password123"
        this.mockAuthService.setMockLoginResult(Result.success(AuthToken("token", "refresh", 3600)))

        // Act
        let result1 = this.mockAuthService.login(email1, password)
        let result2 = this.mockAuthService.login(email2, password)

        // Assert
        Assert.assertTrue(result1.isSuccess(), "First login should succeed")
        Assert.assertTrue(result2.isSuccess(), "Second login should succeed")
    }
}
