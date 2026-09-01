// AuthService.cj - 认证服务（同步自 Web 版 AuthApi + auth store）
package services

import models.*
import std.collection.*
import std.json.*
import utils.*

public class AuthService {
    private let httpClient: HttpClient
    private let tokenStorage: TokenStorage
    private static let logger = Logger("AuthService")

    public init() {
        this.httpClient = HttpClient(ApiConfig.BASE_URL + ApiConfig.API_VERSION)
        this.tokenStorage = TokenStorage()
    }

    // ==================== 邮箱密码登录 ====================
    // 同步自 Web 版 AuthApi.login
    public func login(email: String, password: String): Result<AuthToken> {
        // 使用 form-data 格式（与 Web 版 URLSearchParams 一致）
        let params = "username=${email}&password=${password}"
        let response = httpClient.postWithContentType(
            ApiConfig.AUTH_LOGIN,
            params,
            "application/x-www-form-urlencoded"
        )

        if (response.isSuccess()) {
            let result = parseAuthToken(response.body)
            if (result.isSuccess()) {
                let token = result.getValue()!!
                tokenStorage.saveToken(token)
                httpClient.setAuthToken(token.accessToken)
                logger.info("User logged in successfully: ${email}")
                return Result<AuthToken>.success(token)
            } else {
                return Result<AuthToken>.failure(result.getError())
            }
        } else {
            let error = ErrorHandler.handleHttpError(response.statusCode, response.body)
            ErrorHandler.logError(error)
            return Result<AuthToken>.failure(error.message)
        }
    }

    // ==================== 用户注册 ====================
    // 同步自 Web 版 AuthApi.register
    public func register(data: RegisterRequest): Result<AuthToken> {
        let obj = JsonObject()
        obj.put("email", data.email)
        obj.put("password", data.password)
        if (data.phone != "") { obj.put("phone", data.phone) }
        if (data.username != "") { obj.put("username", data.username) }
        if (data.verificationCode != "") { obj.put("verification_code", data.verificationCode) }

        let response = httpClient.post(ApiConfig.AUTH_REGISTER, obj.toJson())

        if (response.isSuccess()) {
            let result = parseAuthToken(response.body)
            if (result.isSuccess()) {
                let token = result.getValue()!!
                tokenStorage.saveToken(token)
                httpClient.setAuthToken(token.accessToken)
                logger.info("User registered successfully: ${data.email}")
                return Result<AuthToken>.success(token)
            } else {
                return Result<AuthToken>.failure(result.getError())
            }
        } else {
            let error = ErrorHandler.handleHttpError(response.statusCode, response.body)
            ErrorHandler.logError(error)
            return Result<AuthToken>.failure(error.message)
        }
    }

    // ==================== 发送邮箱验证码 ====================
    // 同步自 Web 版 AuthApi.sendVerificationCode
    public func sendVerificationCode(email: String): Result<Void> {
        let obj = JsonObject()
        obj.put("email", email)
        let response = httpClient.post(ApiConfig.EMAIL_SEND_CODE, obj.toJson())

        if (response.isSuccess()) {
            return Result<Void>.success()
        }
        return Result<Void>.failure(response.error)
    }

    // ==================== 验证邮箱验证码 ====================
    // 同步自 Web 版 AuthApi.verifyEmailCode
    public func verifyEmailCode(email: String, code: String): Result<Void> {
        let obj = JsonObject()
        obj.put("email", email)
        obj.put("code", code)
        let response = httpClient.post(ApiConfig.EMAIL_VERIFY_CODE, obj.toJson())

        if (response.isSuccess()) {
            return Result<Void>.success()
        }
        return Result<Void>.failure(response.error)
    }

    // ==================== SMS 短信验证码 ====================
    // 同步自 Web 版 VerificationCodeInput
    public func sendSmsCode(phone: String): Result<Int64> {
        let obj = JsonObject()
        obj.put("phone", phone)
        let response = httpClient.post(ApiConfig.AUTH_SMS_SEND, obj.toJson())

        if (response.isSuccess()) {
            var cooldown: Int64 = 60
            try {
                let jsonObj = JsonParser.parse(response.body)
                let dataObj = jsonObj.getObject("data")
                cooldown = dataObj.getInt64("cooldown", 60)
            } catch (_: Exception) {}
            return Result<Int64>.success(cooldown)
        }
        return Result<Int64>.failure(response.error)
    }

    // ==================== SMS 登录 ====================
    // 同步自 Web 版 UnifiedLoginPage handleSMSLogin
    public func loginWithSms(phone: String, code: String): Result<AuthToken> {
        let obj = JsonObject()
        obj.put("phone", phone)
        obj.put("code", code)
        let response = httpClient.post(ApiConfig.AUTH_SMS_LOGIN, obj.toJson())

        if (response.isSuccess()) {
            let result = parseAuthTokenFromData(response.body)
            if (result.isSuccess()) {
                let token = result.getValue()!!
                tokenStorage.saveToken(token)
                httpClient.setAuthToken(token.accessToken)
                return Result<AuthToken>.success(token)
            }
            return Result<AuthToken>.failure(result.getError())
        }
        return Result<AuthToken>.failure(response.error)
    }

    // ==================== OAuth 登录 ====================
    // 同步自 Web 版 initiateOAuth
    public func getOAuthAuthorizeUrl(provider: String): Result<String> {
        let endpoint = ApiConfig.AUTH_OAUTH_AUTHORIZE.replace("{provider}", provider)
        let response = httpClient.get(endpoint)

        if (response.isSuccess()) {
            try {
                let jsonObj = JsonParser.parse(response.body)
                let dataObj = jsonObj.getObject("data")
                let authUrl = dataObj.getString("auth_url", "")
                if (authUrl != "") {
                    return Result<String>.success(authUrl)
                }
            } catch (_: Exception) {}
        }
        return Result<String>.failure("获取OAuth授权地址失败")
    }

    // ==================== 密码重置 ====================
    // 同步自 Web 版 ForgotPasswordPage
    public func requestPasswordReset(email: String): Result<Void> {
        let obj = JsonObject()
        obj.put("email", email)
        let response = httpClient.post(ApiConfig.AUTH_PASSWORD_RESET_REQUEST, obj.toJson())

        if (response.isSuccess()) {
            return Result<Void>.success()
        }
        return Result<Void>.failure(response.error)
    }

    public func verifyPasswordReset(email: String, code: String, newPassword: String): Result<Void> {
        let obj = JsonObject()
        obj.put("email", email)
        obj.put("code", code)
        obj.put("new_password", newPassword)
        let response = httpClient.post(ApiConfig.AUTH_PASSWORD_RESET_VERIFY, obj.toJson())

        if (response.isSuccess()) {
            return Result<Void>.success()
        }
        return Result<Void>.failure(response.error)
    }

    // ==================== 获取当前用户 ====================
    // 同步自 Web 版 AuthApi.getCurrentUser
    public func getCurrentUser(): Result<User> {
        let response = httpClient.get(ApiConfig.AUTH_ME)

        if (response.isSuccess()) {
            return parseUser(response.body)
        }
        return Result<User>.failure(response.error)
    }

    // ==================== 刷新Token ====================
    public func refreshToken(): Result<AuthToken> {
        let savedToken = tokenStorage.getToken()
        if (savedToken.refreshToken == "") {
            return Result<AuthToken>.failure("没有可用的刷新令牌")
        }

        let obj = JsonObject()
        obj.put("refresh_token", savedToken.refreshToken)
        let response = httpClient.post(ApiConfig.AUTH_REFRESH, obj.toJson())

        if (response.isSuccess()) {
            let result = parseAuthToken(response.body)
            if (result.isSuccess()) {
                let token = result.getValue()!!
                tokenStorage.saveToken(token)
                httpClient.setAuthToken(token.accessToken)
                return Result<AuthToken>.success(token)
            }
            return Result<AuthToken>.failure(result.getError())
        }
        return Result<AuthToken>.failure(response.error)
    }

    // ==================== 登出 ====================
    public func logout(): Unit {
        try {
            httpClient.post(ApiConfig.AUTH_LOGOUT, "{}")
        } catch (e: Exception) {
            logger.warn("Logout request failed: ${e.message}")
        }
        tokenStorage.clearToken()
        httpClient.clearAuthToken()
        logger.info("User logged out")
    }

    // ==================== 状态检查 ====================
    public func isAuthenticated(): Bool {
        let token = tokenStorage.getToken()
        return token.accessToken != ""
    }

    public func getCurrentToken(): AuthToken {
        return tokenStorage.getToken()
    }

    // ==================== 账号绑定 ====================
    // 同步自 Web 版 AccountSettingsPage
    public func getAccountBindings(): Result<AccountBindings> {
        let response = httpClient.get(ApiConfig.ACCOUNT_BINDINGS)
        if (response.isSuccess()) {
            return parseAccountBindings(response.body)
        }
        return Result<AccountBindings>.failure(response.error)
    }

    public func bindEmail(email: String, password: String, code: String): Result<Void> {
        let obj = JsonObject()
        obj.put("email", email)
        obj.put("password", password)
        obj.put("verification_code", code)
        let response = httpClient.post(ApiConfig.ACCOUNT_BIND_EMAIL, obj.toJson())

        if (response.isSuccess()) {
            return Result<Void>.success()
        }
        return Result<Void>.failure(response.error)
    }

    public func bindPhone(phone: String): Result<Void> {
        let obj = JsonObject()
        obj.put("phone", phone)
        let response = httpClient.post(ApiConfig.ACCOUNT_BIND_PHONE, obj.toJson())

        if (response.isSuccess()) {
            return Result<Void>.success()
        }
        return Result<Void>.failure(response.error)
    }

    public func unbind(accountType: String, password: String): Result<Void> {
        let obj = JsonObject()
        obj.put("account_type", accountType)
        obj.put("password", password)
        let response = httpClient.post(ApiConfig.ACCOUNT_UNBIND, obj.toJson())

        if (response.isSuccess()) {
            return Result<Void>.success()
        }
        return Result<Void>.failure(response.error)
    }

    // ==================== 解析方法 ====================

    private func parseAuthToken(json: String): Result<AuthToken> {
        try {
            let obj = JsonParser.parse(json)
            let token = AuthToken()
            token.accessToken = obj.getString("access_token", "")
            token.refreshToken = obj.getString("refresh_token", "")
            token.tokenType = obj.getString("token_type", "bearer")
            token.expiresIn = obj.getInt64("expires_in", 0)

            if (obj.containsKey("user")) {
                let userObj = obj.getObject("user")
                token.user = Some(parseUserFromObject(userObj))
            }

            if (token.accessToken == "") {
                return Result<AuthToken>.failure("无效的访问令牌")
            }

            return Result<AuthToken>.success(token)
        } catch (e: Exception) {
            return Result<AuthToken>.failure("解析认证响应失败: ${e.message}")
        }
    }

    // 从 data 字段解析 token（SMS/OAuth 登录返回格式）
    private func parseAuthTokenFromData(json: String): Result<AuthToken> {
        try {
            let obj = JsonParser.parse(json)
            var tokenObj = obj

            if (obj.containsKey("data")) {
                tokenObj = obj.getObject("data")
            }

            let token = AuthToken()
            token.accessToken = tokenObj.getString("access_token", "")
            token.refreshToken = tokenObj.getString("refresh_token", "")
            token.tokenType = tokenObj.getString("token_type", "bearer")
            token.expiresIn = tokenObj.getInt64("expires_in", 0)

            if (token.accessToken == "") {
                return Result<AuthToken>.failure("无效的访问令牌")
            }

            return Result<AuthToken>.success(token)
        } catch (e: Exception) {
            return Result<AuthToken>.failure("解析认证响应失败: ${e.message}")
        }
    }

    private func parseUser(json: String): Result<User> {
        try {
            let obj = JsonParser.parse(json)
            return Result<User>.success(parseUserFromObject(obj))
        } catch (e: Exception) {
            return Result<User>.failure("解析用户信息失败: ${e.message}")
        }
    }

    private func parseUserFromObject(obj: JsonObject): User {
        let user = User()
        user.id = obj.getInt64("id", 0)
        user.email = obj.getString("email", "")
        user.phone = obj.getString("phone", "")
        user.username = obj.getString("username", "")
        user.fullName = obj.getString("full_name", "")
        user.avatar = obj.getString("avatar", "")
        user.nickname = obj.getString("nickname", "")
        user.role = obj.getString("role", "user")
        user.isActive = obj.getBool("is_active", false)
        user.isVerified = obj.getBool("is_verified", false)
        user.createdAt = obj.getString("created_at", "")
        user.updatedAt = obj.getString("updated_at", "")
        return user
    }

    private func parseAccountBindings(json: String): Result<AccountBindings> {
        try {
            let obj = JsonParser.parse(json)
            var dataObj = obj
            if (obj.containsKey("data")) {
                dataObj = obj.getObject("data")
            }

            let bindings = AccountBindings()
            bindings.email = parseBinding(dataObj, "email")
            bindings.phone = parseBinding(dataObj, "phone")
            bindings.wechat = parseBinding(dataObj, "wechat")
            bindings.google = parseBinding(dataObj, "google")
            bindings.github = parseBinding(dataObj, "github")
            bindings.gitee = parseBinding(dataObj, "gitee")
            bindings.discord = parseBinding(dataObj, "discord")

            return Result<AccountBindings>.success(bindings)
        } catch (e: Exception) {
            return Result<AccountBindings>.failure("解析绑定信息失败: ${e.message}")
        }
    }

    private func parseBinding(obj: JsonObject, key: String): AccountBinding {
        let binding = AccountBinding()
        try {
            let bObj = obj.getObject(key)
            binding.bound = bObj.getBool("bound", false)
            binding.value = bObj.getString("value", "")
            binding.isPrimary = bObj.getBool("is_primary", false)
            binding.verified = bObj.getBool("verified", false)
        } catch (_: Exception) {}
        return binding
    }
}

// ==================== Token存储类 ====================
public class TokenStorage {
    private let prefs: Preferences
    private static let logger = Logger("TokenStorage")

    public init() {
        this.prefs = Preferences.get("auth_prefs")
    }

    public func saveToken(token: AuthToken): Unit {
        prefs.putString("access_token", token.accessToken)
        prefs.putString("refresh_token", token.refreshToken)
        prefs.putString("token_type", token.tokenType)
        prefs.putInt64("expires_in", token.expiresIn)
        prefs.flush()
        logger.debug("Token saved to storage")
    }

    public func getToken(): AuthToken {
        let token = AuthToken()
        token.accessToken = prefs.getString("access_token", "")
        token.refreshToken = prefs.getString("refresh_token", "")
        token.tokenType = prefs.getString("token_type", "bearer")
        token.expiresIn = prefs.getInt64("expires_in", 0)
        return token
    }

    public func clearToken(): Unit {
        prefs.remove("access_token")
        prefs.remove("refresh_token")
        prefs.remove("token_type")
        prefs.remove("expires_in")
        prefs.flush()
        logger.debug("Token cleared from storage")
    }
}
