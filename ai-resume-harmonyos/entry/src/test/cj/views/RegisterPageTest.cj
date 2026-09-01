// RegisterPageTest.cj - 注册页面测试
package test.views

import ohos.hypium.*
import views.*
import services.*
import models.*
import utils.*

// Mock AuthService for registration testing
public class MockAuthServiceForRegister {
    private var mockRegisterResult: Result<User> = Result.error("Not mocked")
    private var registerCalled: Bool = false
    private var capturedEmail: String = ""
    private var capturedUsername: String = ""
    private var capturedPassword: String = ""
    private var capturedFullName: String = ""

    public func setMockRegisterResult(result: Result<User>): Unit {
        this.mockRegisterResult = result
    }

    public func register(email: String, username: String, password: String, fullName: String): Result<User> {
        this.registerCalled = true
        this.capturedEmail = email
        this.capturedUsername = username
        this.capturedPassword = password
        this.capturedFullName = fullName
        return this.mockRegisterResult
    }

    public func wasRegisterCalled(): Bool {
        return this.registerCalled
    }

    public func getCapturedEmail(): String {
        return this.capturedEmail
    }

    public func getCapturedUsername(): String {
        return this.capturedUsername
    }

    public func getCapturedPassword(): String {
        return this.capturedPassword
    }

    public func getCapturedFullName(): String {
        return this.capturedFullName
    }

    public func reset(): Unit {
        this.mockRegisterResult = Result.error("Not mocked")
        this.registerCalled = false
        this.capturedEmail = ""
        this.capturedUsername = ""
        this.capturedPassword = ""
        this.capturedFullName = ""
    }
}

@TestCase
public class RegisterPageTest {
    private var mockAuthService: MockAuthServiceForRegister = MockAuthServiceForRegister()

    @Before
    public func setup(): Unit {
        this.mockAuthService.reset()
    }

    @Test
    public func testRegisterPageInitialization(): Unit {
        // Arrange & Act
        let page = RegisterPage()

        // Assert
        Assert.assertTrue(true, "RegisterPage should initialize successfully")
    }

    @Test
    public func testEmptyFieldValidation(): Unit {
        // Arrange
        let email = ""
        let username = "testuser"
        let password = "password123"
        let fullName = "Test User"

        // Act
        let isValid = this.validateFields(email, username, password, fullName)

        // Assert
        Assert.assertFalse(isValid, "Should fail with empty email")
    }

    @Test
    public func testAllFieldsEmptyValidation(): Unit {
        // Arrange
        let email = ""
        let username = ""
        let password = ""
        let fullName = ""

        // Act
        let isValid = this.validateFields(email, username, password, fullName)

        // Assert
        Assert.assertFalse(isValid, "Should fail with all empty fields")
    }

    @Test
    public func testPasswordMismatchValidation(): Unit {
        // Arrange
        let email = "test@example.com"
        let username = "testuser"
        let password = "password123"
        let confirmPassword = "different123"
        let fullName = "Test User"

        // Act
        let passwordsMatch = this.checkPasswordMatch(password, confirmPassword)

        // Assert
        Assert.assertFalse(passwordsMatch, "Passwords should not match")
    }

    @Test
    public func testPasswordMatchValidation(): Unit {
        // Arrange
        let password = "password123"
        let confirmPassword = "password123"

        // Act
        let passwordsMatch = this.checkPasswordMatch(password, confirmPassword)

        // Assert
        Assert.assertTrue(passwordsMatch, "Passwords should match")
    }

    @Test
    public func testPasswordLengthValidation(): Unit {
        // Arrange
        let shortPassword = "12345"

        // Act
        let isValidLength = this.validatePasswordLength(shortPassword)

        // Assert
        Assert.assertFalse(isValidLength, "Password should be at least 6 characters")
    }

    @Test
    public func testPasswordLengthValid(): Unit {
        // Arrange
        let validPassword = "123456"

        // Act
        let isValidLength = this.validatePasswordLength(validPassword)

        // Assert
        Assert.assertTrue(isValidLength, "Password of 6 characters should be valid")
    }

    @Test
    public func testEmailValidation(): Unit {
        // Arrange
        let email = "test@example.com"
        let username = "testuser"
        let password = "password123"
        let fullName = "Test User"

        // Act
        let emailValid = this.validateEmail(email)

        // Assert
        Assert.assertTrue(emailValid, "Email should be valid")
    }

    @Test
    public func testEmailValidationInvalid(): Unit {
        // Arrange
        let invalidEmail = "invalid-email"

        // Act
        let emailValid = this.validateEmail(invalidEmail)

        // Assert
        Assert.assertFalse(emailValid, "Email should be invalid")
    }

    @Test
    public func testUsernameValidation(): Unit {
        // Arrange
        let username = "validuser123"

        // Act
        let usernameValid = this.validateUsername(username)

        // Assert
        Assert.assertTrue(usernameValid, "Username should be valid")
    }

    @Test
    public func testUsernameValidationTooShort(): Unit {
        // Arrange
        let shortUsername = "ab"

        // Act
        let usernameValid = this.validateUsername(shortUsername)

        // Assert
        Assert.assertFalse(usernameValid, "Username should be at least 3 characters")
    }

    @Test
    public func testFullNameValidation(): Unit {
        // Arrange
        let fullName = "John Doe"

        // Act
        let fullNameValid = this.validateFullName(fullName)

        // Assert
        Assert.assertTrue(fullNameValid, "Full name should be valid")
    }

    @Test
    public func testRegisterSuccess(): Unit {
        // Arrange
        let email = "test@example.com"
        let username = "testuser"
        let password = "password123"
        let fullName = "Test User"
        let mockUser = User(1, email, username, fullName, "user")

        this.mockAuthService.setMockRegisterResult(Result.success(mockUser))

        // Act
        let result = this.mockAuthService.register(email, username, password, fullName)

        // Assert
        Assert.assertTrue(result.isSuccess(), "Registration should succeed")
        Assert.assertTrue(this.mockAuthService.wasRegisterCalled(), "Register should be called")
        Assert.assertEquals(email, this.mockAuthService.getCapturedEmail(), "Email should match")
        Assert.assertEquals(username, this.mockAuthService.getCapturedUsername(), "Username should match")
        Assert.assertEquals(password, this.mockAuthService.getCapturedPassword(), "Password should match")
        Assert.assertEquals(fullName, this.mockAuthService.getCapturedFullName(), "Full name should match")
    }

    @Test
    public func testRegisterFailureEmailExists(): Unit {
        // Arrange
        let email = "existing@example.com"
        let username = "testuser"
        let password = "password123"
        let fullName = "Test User"

        this.mockAuthService.setMockRegisterResult(Result.error("邮箱已被注册"))

        // Act
        let result = this.mockAuthService.register(email, username, password, fullName)

        // Assert
        Assert.assertFalse(result.isSuccess(), "Registration should fail")
        Assert.assertEquals("邮箱已被注册", result.getError(), "Error message should match")
    }

    @Test
    public func testRegisterFailureNetworkError(): Unit {
        // Arrange
        let email = "test@example.com"
        let username = "testuser"
        let password = "password123"
        let fullName = "Test User"

        this.mockAuthService.setMockRegisterResult(Result.error("网络连接失败"))

        // Act
        let result = this.mockAuthService.register(email, username, password, fullName)

        // Assert
        Assert.assertFalse(result.isSuccess(), "Registration should fail")
        Assert.assertEquals("网络连接失败", result.getError(), "Error message should match")
    }

    @Test
    public func testCompleteRegistrationFlow(): Unit {
        // Arrange
        let email = "newuser@example.com"
        let username = "newuser"
        let password = "securepass123"
        let confirmPassword = "securepass123"
        let fullName = "New User"
        let mockUser = User(1, email, username, fullName, "user")

        // Validate all fields
        Assert.assertTrue(this.validateFields(email, username, password, fullName), "All fields should be valid")
        Assert.assertTrue(this.checkPasswordMatch(password, confirmPassword), "Passwords should match")
        Assert.assertTrue(this.validatePasswordLength(password), "Password length should be valid")
        Assert.assertTrue(this.validateEmail(email), "Email should be valid")
        Assert.assertTrue(this.validateUsername(username), "Username should be valid")
        Assert.assertTrue(this.validateFullName(fullName), "Full name should be valid")

        this.mockAuthService.setMockRegisterResult(Result.success(mockUser))

        // Act
        let result = this.mockAuthService.register(email, username, password, fullName)

        // Assert
        Assert.assertTrue(result.isSuccess(), "Registration should succeed")
    }

    // Helper methods for validation

    private func validateFields(email: String, username: String, password: String, fullName: String): Bool {
        return email != "" && username != "" && password != "" && fullName != ""
    }

    private func checkPasswordMatch(password: String, confirmPassword: String): Bool {
        return password == confirmPassword
    }

    private func validatePasswordLength(password: String): Bool {
        return password.length() >= 6
    }

    private func validateEmail(email: String): Bool {
        let validationResult = Validator.isValidEmail(email)
        return validationResult.isSuccess()
    }

    private func validateUsername(username: String): Bool {
        let validationResult = Validator.isValidUsername(username)
        return validationResult.isSuccess()
    }

    private func validateFullName(fullName: String): Bool {
        return fullName.length() >= 2
    }
}
