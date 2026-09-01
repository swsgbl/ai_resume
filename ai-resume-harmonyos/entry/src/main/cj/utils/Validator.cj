// Validator.cj - 输入验证工具
package utils

import std.regex.*
import utils.*

/**
 * 输入验证工具类
 *
 * 提供常用的输入验证功能，确保数据安全性和完整性
 */
public class Validator {
    private static let logger = Logger("Validator")

    // 正则表达式模式
    private static let EMAIL_PATTERN = Regex(
        "^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Z|a-z]{2,}$"
    )

    private static let USERNAME_PATTERN = Regex(
        "^[a-zA-Z0-9_]{3,20}$"
    )

    private static let PASSWORD_MIN_LENGTH = 8
    private static let PASSWORD_MAX_LENGTH = 128

    private static let TITLE_MIN_LENGTH = 1
    private static let TITLE_MAX_LENGTH = 100

    /**
     * 验证邮箱格式
     *
     * @param email 待验证的邮箱地址
     * @return Result<Boolean> 验证结果
     */
    public static func isValidEmail(email: String): Result<Boolean> {
        if (email.isEmpty()) {
            return Result<Boolean>.failure("邮箱不能为空")
        }

        if (EMAIL_PATTERN.matches(email)) {
            return Result<Boolean>.success(true)
        }

        return Result<Boolean>.failure("邮箱格式不正确")
    }

    /**
     * 验证用户名格式
     *
     * 规则：3-20个字符，只能包含字母、数字和下划线
     *
     * @param username 待验证的用户名
     * @return Result<Boolean> 验证结果
     */
    public static func isValidUsername(username: String): Result<Boolean> {
        if (username.isEmpty()) {
            return Result<Boolean>.failure("用户名不能为空")
        }

        if (USERNAME_PATTERN.matches(username)) {
            return Result<Boolean>.success(true)
        }

        return Result<Boolean>.failure(
            "用户名必须为3-20个字符，只能包含字母、数字和下划线"
        )
    }

    /**
     * 验证密码强度
     *
     * 规则：
     * - 最少8个字符
     * - 最多128个字符
     * - 建议包含大小写字母、数字和特殊字符
     *
     * @param password 待验证的密码
     * @return Result<Boolean> 验证结果
     */
    public static func isValidPassword(password: String): Result<Boolean> {
        if (password.isEmpty()) {
            return Result<Boolean>.failure("密码不能为空")
        }

        if (password.size() < PASSWORD_MIN_LENGTH) {
            return Result<Boolean>.failure("密码至少需要${PASSWORD_MIN_LENGTH}个字符")
        }

        if (password.size() > PASSWORD_MAX_LENGTH) {
            return Result<Boolean>.failure("密码最多${PASSWORD_MAX_LENGTH}个字符")
        }

        // 检查密码强度（可选）
        let hasUpperCase = containsUpperCase(password)
        let hasLowerCase = containsLowerCase(password)
        let hasDigit = containsDigit(password)

        if (!hasUpperCase || !hasLowerCase || !hasDigit) {
            logger.warn("Password strength: weak (建议使用大小写字母和数字)")
        }

        return Result<Boolean>.success(true)
    }

    /**
     * 验证标题（如简历标题）
     *
     * @param title 待验证的标题
     * @return Result<Boolean> 验证结果
     */
    public static func isValidTitle(title: String): Result<Boolean> {
        if (title.isEmpty()) {
            return Result<Boolean>.failure("标题不能为空")
        }

        if (title.size() < TITLE_MIN_LENGTH) {
            return Result<Boolean>.failure("标题至少${TITLE_MIN_LENGTH}个字符")
        }

        if (title.size() > TITLE_MAX_LENGTH) {
            return Result<Boolean>.failure("标题最多${TITLE_MAX_LENGTH}个字符")
        }

        return Result<Boolean>.success(true)
    }

    /**
     * 验证URL格式
     *
     * @param url 待验证的URL
     * @return Result<Boolean> 验证结果
     */
    public static func isValidUrl(url: String): Result<Boolean> {
        if (url.isEmpty()) {
            return Result<Boolean>.failure("URL不能为空")
        }

        try {
            let urlPattern = Regex(
                "^(http|https)://[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}(/[^\\s]*)?$"
            )
            if (urlPattern.matches(url)) {
                return Result<Boolean>.success(true)
            }
        } catch (e: Exception) {
            logger.error("URL validation failed: ${e.message}")
        }

        return Result<Boolean>.failure("URL格式不正确")
    }

    /**
     * 验证手机号格式（中国）
     *
     * @param phone 待验证的手机号
     * @return Result<Boolean> 验证结果
     */
    public static func isValidPhone(phone: String): Result<Boolean> {
        if (phone.isEmpty()) {
            return Result<Boolean>.failure("手机号不能为空")
        }

        let phonePattern = Regex("^1[3-9]\\d{9}$")
        if (phonePattern.matches(phone)) {
            return Result<Boolean>.success(true)
        }

        return Result<Boolean>.failure("手机号格式不正确")
    }

    /**
     * 验证ID（简历ID、模板ID等）
     *
     * @param id 待验证的ID
     * @return Result<Boolean> 验证结果
     */
    public static func isValidId(id: Int64): Result<Boolean> {
        if (id <= 0) {
            return Result<Boolean>.failure("ID必须大于0")
        }
        return Result<Boolean>.success(true)
    }

    /**
     * 验证字符串长度
     *
     * @param value 待验证的字符串
     * @param minLength 最小长度
     * @param maxLength 最大长度
     * @return Result<Boolean> 验证结果
     */
    public static func isValidLength(
        value: String,
        minLength: Int32,
        maxLength: Int32
    ): Result<Boolean> {
        if (value.size() < minLength) {
            return Result<Boolean>.failure("至少需要${minLength}个字符")
        }

        if (value.size() > maxLength) {
            return Result<Boolean>.failure("最多${maxLength}个字符")
        }

        return Result<Boolean>.success(true)
    }

    /**
     * 验证是否包含大写字母
     */
    private static func containsUpperCase(s: String): Bool {
        for (ch in s) {
            if (ch >= 'A' && ch <= 'Z') {
                return true
            }
        }
        return false
    }

    /**
     * 验证是否包含小写字母
     */
    private static func containsLowerCase(s: String): Bool {
        for (ch in s) {
            if (ch >= 'a' && ch <= 'z') {
                return true
            }
        }
        return false
    }

    /**
     * 验证是否包含数字
     */
    private static func containsDigit(s: String): Bool {
        for (ch in s) {
            if (ch >= '0' && ch <= '9') {
                return true
            }
        }
        return false
    }

    /**
     * 综合验证登录信息
     */
    public static func validateLogin(email: String, password: String): Result<Void> {
        let emailResult = isValidEmail(email)
        if (!emailResult.isSuccess()) {
            return Result<Void>.failure(emailResult.getError())
        }

        let passwordResult = isValidPassword(password)
        if (!passwordResult.isSuccess()) {
            return Result<Void>.failure(passwordResult.getError())
        }

        return Result<Void>.success()
    }

    /**
     * 综合验证注册信息
     */
    public static func validateRegister(
        email: String,
        username: String,
        password: String,
        fullName: String
    ): Result<Void> {
        let emailResult = isValidEmail(email)
        if (!emailResult.isSuccess()) {
            return Result<Void>.failure(emailResult.getError())
        }

        let usernameResult = isValidUsername(username)
        if (!usernameResult.isSuccess()) {
            return Result<Void>.failure(usernameResult.getError())
        }

        let passwordResult = isValidPassword(password)
        if (!passwordResult.isSuccess()) {
            return Result<Void>.failure(passwordResult.getError())
        }

        if (fullName.isEmpty()) {
            return Result<Void>.failure("姓名不能为空")
        }

        return Result<Void>.success()
    }
}

// Result<Void> 特化用于无返回值的验证结果
public class Void {}
