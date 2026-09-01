// ValidatorTest.cj - Validator 工具类单元测试
package test.utils

import utils.*
import testing.*
import ohos.hypium.*

/**
 * Validator 工具类测试套件
 */
@TestCase
public class ValidatorTest {
    private let validator: Validator

    public init() {
        this.validator = Validator()
    }

    /**
     * 测试邮箱验证 - 有效邮箱
     */
    @Test
    public func testValidEmail(): Unit {
        let validEmails = [
            "test@example.com",
            "user.name@example.com",
            "user+tag@example.co.uk",
            "user123@test-domain.com"
        ]

        for (email in validEmails) {
            let result = Validator.isValidEmail(email)
            Assert.assertTrue(
                "${email} should be valid",
                result.isSuccess()
            )
        }
    }

    /**
     * 测试邮箱验证 - 无效邮箱
     */
    @Test
    public func testInvalidEmail(): Unit {
        let invalidEmails = [
            "",
            "invalid",
            "@example.com",
            "user@",
            "user..name@example.com",
            "user@.com"
        ]

        for (email in invalidEmails) {
            let result = Validator.isValidEmail(email)
            Assert.assertFalse(
                "${email} should be invalid",
                result.isSuccess()
            )
        }
    }

    /**
     * 测试用户名验证 - 有效用户名
     */
    @Test
    public func testValidUsername(): Unit {
        let validUsernames = [
            "user123",
            "test_user",
            "User_Name",
            "abc123"
        ]

        for (username in validUsernames) {
            let result = Validator.isValidUsername(username)
            Assert.assertTrue(
                "${username} should be valid",
                result.isSuccess()
            )
        }
    }

    /**
     * 测试用户名验证 - 无效用户名
     */
    @Test
    public func testInvalidUsername(): Unit {
        let invalidUsernames = [
            "",
            "ab",  // 太短
            "user@name",  // 包含特殊字符
            "a".repeat(25),  // 太长（假设最大20）
            "user-name",  // 包含连字符
            "user.name"  // 包含点号
        ]

        for (username in invalidUsernames) {
            let result = Validator.isValidUsername(username)
            Assert.assertFalse(
                "${username} should be invalid",
                result.isSuccess()
            )
        }
    }

    /**
     * 测试密码验证 - 有效密码
     */
    @Test
    public func testValidPassword(): Unit {
        let validPasswords = [
            "Password123",
            "Test1234",
            "MySecureP@ssw0rd"
        ]

        for (password in validPasswords) {
            let result = Validator.isValidPassword(password)
            Assert.assertTrue(
                "Password should be valid",
                result.isSuccess()
            )
        }
    }

    /**
     * 测试密码验证 - 无效密码
     */
    @Test
    public func testInvalidPassword(): Unit {
        let invalidPasswords = [
            "",
            "short",
            "onlylowercase",
            "ONLYUPPERCASE",
            "12345678"
        ]

        for (password in invalidPasswords) {
            let result = Validator.isValidPassword(password)
            Assert.assertFalse(
                "${password} should be invalid",
                result.isSuccess()
            )
        }
    }

    /**
     * 测试标题验证 - 有效标题
     */
    @Test
    public func testValidTitle(): Unit {
        let validTitles = [
            "Software Engineer",
            "我的简历",
            "CV-2024"
        ]

        for (title in validTitles) {
            let result = Validator.isValidTitle(title)
            Assert.assertTrue(
                "${title} should be valid",
                result.isSuccess()
            )
        }
    }

    /**
     * 测试标题验证 - 无效标题
     */
    @Test
    public func testInvalidTitle(): Unit {
        let invalidTitles = [
            "",
            "a".repeat(105)  // 超过最大长度
        ]

        for (title in invalidTitles) {
            let result = Validator.isValidTitle(title)
            Assert.assertFalse(
                "Title should be invalid",
                result.isSuccess()
            )
        }
    }

    /**
     * 测试 URL 验证 - 有效 URL
     */
    @Test
    public func testValidUrl(): Unit {
        let validUrls = [
            "http://example.com",
            "https://www.example.com",
            "https://example.com/path"
        ]

        for (url in validUrls) {
            let result = Validator.isValidUrl(url)
            Assert.assertTrue(
                "${url} should be valid",
                result.isSuccess()
            )
        }
    }

    /**
     * 测试 URL 验证 - 无效 URL
     */
    @Test
    public func testInvalidUrl(): Unit {
        let invalidUrls = [
            "",
            "not-a-url",
            "ftp://example.com",
            "//example.com"
        ]

        for (url in invalidUrls) {
            let result = Validator.isValidUrl(url)
            Assert.assertFalse(
                "${url} should be invalid",
                result.isSuccess()
            )
        }
    }

    /**
     * 测试手机号验证 - 有效手机号
     */
    @Test
    public func testValidPhone(): Unit {
        let validPhones = [
            "13812345678",
            "15912345678",
            "18812345678"
        ]

        for (phone in validPhones) {
            let result = Validator.isValidPhone(phone)
            Assert.assertTrue(
                "${phone} should be valid",
                result.isSuccess()
            )
        }
    }

    /**
     * 测试手机号验证 - 无效手机号
     */
    @Test
    public func testInvalidPhone(): Unit {
        let invalidPhones = [
            "",
            "12345678901",
            "1381234567",
            "abcdefghijk"
        ]

        for (phone in invalidPhones) {
            let result = Validator.isValidPhone(phone)
            Assert.assertFalse(
                "${phone} should be invalid",
                result.isSuccess()
            )
        }
    }

    /**
     * 测试 ID 验证 - 有效 ID
     */
    @Test
    public func testValidId(): Unit {
        let validIds = [
            1L,
            100L,
            999999L
        ]

        for (id in validIds) {
            let result = Validator.isValidId(id)
            Assert.assertTrue(
                "ID ${id} should be valid",
                result.isSuccess()
            )
        }
    }

    /**
     * 测试 ID 验证 - 无效 ID
     */
    @Test
    public func testInvalidId(): Unit {
        let invalidIds = [
            0L,
            -1L,
            -100L
        ]

        for (id in invalidIds) {
            let result = Validator.isValidId(id)
            Assert.assertFalse(
                "ID ${id} should be invalid",
                result.isSuccess()
            )
        }
    }

    /**
     * 测试综合登录验证
     */
    @Test
    public func testValidateLoginSuccess(): Unit {
        let result = Validator.validateLogin(
            "test@example.com",
            "Password123"
        )
        Assert.assertTrue("Valid login should pass", result.isSuccess())
    }

    /**
     * 测试综合登录验证 - 失败场景
     */
    @Test
    public func testValidateLoginFailure(): Unit {
        let result = Validator.validateLogin(
            "invalid-email",
            "short"
        )
        Assert.assertFalse("Invalid login should fail", result.isSuccess())
    }

    /**
     * 测试综合注册验证
     */
    @Test
    public func testValidateRegisterSuccess(): Unit {
        let result = Validator.validateRegister(
            "test@example.com",
            "testuser",
            "Password123",
            "Test User"
        )
        Assert.assertTrue("Valid registration should pass", result.isSuccess())
    }

    /**
     * 测试综合注册验证 - 失败场景
     */
    @Test
    public func testValidateRegisterFailure(): Unit {
        let result = Validator.validateRegister(
            "invalid",
            "ab",
            "short",
            ""
        )
        Assert.assertFalse("Invalid registration should fail", result.isSuccess())
    }
}
