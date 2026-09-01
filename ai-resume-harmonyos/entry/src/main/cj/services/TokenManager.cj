package services

import ohos.data.preferences.Preferences
import ohos.data.preferences.PreferencesOptions
import utils.crypto.CryptoUtils

/**
 * Token 管理器
 * 负责 OAuth Token 的安全存储和管理
 */
public class TokenManager {
    private let preferences: Preferences
    private let cryptoUtils: CryptoUtils
    private let accessTokenKey: String = "oauth_access_token"
    private let refreshTokenKey: String = "oauth_refresh_token"
    private let tokenExpiryKey: String = "oauth_token_expiry"
    private let tokenTypeKey: String = "oauth_token_type"

    public init(context: Context) {
        let options = PreferencesOptions()
        options.name = "oauth_tokens"
        preferences = Preferences.getPreferences(context, options)
        cryptoUtils = CryptoUtils()
    }

    /**
     * 保存访问令牌
     * @param token 访问令牌
     */
    public func saveAccessToken(token: String) {
        let encryptedToken = cryptoUtils.encrypt(token)
        preferences.put(accessTokenKey, encryptedToken)
        preferences.flush()
    }

    /**
     * 获取访问令牌
     * @returns 访问令牌，如果不存在则返回 null
     */
    public func getAccessToken(): String? {
        let encryptedToken = preferences.get(accessTokenKey, "")
        if (encryptedToken.isEmpty()) {
            return null
        }
        return cryptoUtils.decrypt(encryptedToken)
    }

    /**
     * 保存刷新令牌
     * @param token 刷新令牌
     */
    public func saveRefreshToken(token: String) {
        let encryptedToken = cryptoUtils.encrypt(token)
        preferences.put(refreshTokenKey, encryptedToken)
        preferences.flush()
    }

    /**
     * 获取刷新令牌
     * @returns 刷新令牌，如果不存在则返回 null
     */
    public func getRefreshToken(): String? {
        let encryptedToken = preferences.get(refreshTokenKey, "")
        if (encryptedToken.isEmpty()) {
            return null
        }
        return cryptoUtils.decrypt(encryptedToken)
    }

    /**
     * 保存令牌过期时间
     * @param expiryTime 过期时间戳（毫秒）
     */
    public func saveTokenExpiry(expiryTime: Int64) {
        preferences.put(tokenExpiryKey, expiryTime.toString())
        preferences.flush()
    }

    /**
     * 获取令牌过期时间
     * @returns 过期时间戳（毫秒），如果不存在则返回 0
     */
    public func getTokenExpiry(): Int64 {
        let expiryStr = preferences.get(tokenExpiryKey, "0")
        return expiryStr.toInt64()
    }

    /**
     * 检查令牌是否过期
     * @returns true 表示已过期或不存在，false 表示有效
     */
    public func isTokenExpired(): Bool {
        let expiryTime = getTokenExpiry()
        if (expiryTime == 0) {
            return true
        }
        let currentTime = System.currentTimeMillis()
        return currentTime >= expiryTime
    }

    /**
     * 检查令牌是否即将过期（在指定时间内）
     * @param bufferMillis 缓冲时间（毫秒），默认 5 分钟
     * @returns true 表示即将过期
     */
    public func isTokenExpiringSoon(bufferMillis: Int64 = 300000): Bool {
        let expiryTime = getTokenExpiry()
        if (expiryTime == 0) {
            return true
        }
        let currentTime = System.currentTimeMillis()
        return (expiryTime - currentTime) <= bufferMillis
    }

    /**
     * 保存完整的令牌信息
     * @param accessToken 访问令牌
     * @param refreshToken 刷新令牌
     * @param expiresIn 多少秒后过期
     * @param tokenType 令牌类型，默认为 Bearer
     */
    public func saveTokenInfo(
        accessToken: String,
        refreshToken: String?,
        expiresIn: Int64,
        tokenType: String = "Bearer"
    ) {
        saveAccessToken(accessToken)
        if (refreshToken != null) {
            saveRefreshToken(refreshToken)
        }

        let expiryTime = System.currentTimeMillis() + (expiresIn * 1000)
        saveTokenExpiry(expiryTime)

        preferences.put(tokenTypeKey, tokenType)
        preferences.flush()
    }

    /**
     * 清除所有令牌信息
     */
    public func clearTokens() {
        preferences.delete(accessTokenKey)
        preferences.delete(refreshTokenKey)
        preferences.delete(tokenExpiryKey)
        preferences.delete(tokenTypeKey)
        preferences.flush()
    }

    /**
     * 检查是否有有效的令牌
     * @returns true 表示有有效令牌
     */
    public func hasValidToken(): Bool {
        return !isTokenExpired() && getAccessToken() != null
    }

    /**
     * 获取令牌类型
     * @returns 令牌类型，默认为 Bearer
     */
    public func getTokenType(): String {
        return preferences.get(tokenTypeKey, "Bearer")
    }
}
