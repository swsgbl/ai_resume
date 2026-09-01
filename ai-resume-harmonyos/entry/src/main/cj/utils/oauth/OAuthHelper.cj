package utils.oauth

import std.random.Random
import std.crypto.hash.Sha256
import std.convert.Base64

/**
 * OAuth 辅助工具类
 * 提供 OAuth 2.0 协议相关的工具函数
 */
public class OAuthHelper {
    private let random: Random
    private let sha256: Sha256
    private let base64: Base64

    public init() {
        random = Random()
        sha256 = Sha256()
        base64 = Base64()
    }

    /**
     * 生成随机 state 参数，用于防止 CSRF 攻击
     * @returns 随机生成的 state 字符串
     */
    public func generateState(): String {
        let randomBytes = random.nextBytes(32)
        let hash = sha256.hash(randomBytes)
        return base64.encodeToString(hash)
    }

    /**
     * 验证 state 参数是否有效
     * @param state 待验证的 state
     * @param storedState 存储的正确 state
     * @returns state 是否有效
     */
    public func validateState(state: String, storedState: String): Bool {
        return state == storedState
    }

    /**
     * 生成 code_verifier，用于 PKCE (Proof Key for Code Exchange)
     * @returns code_verifier 字符串
     */
    public func generateCodeVerifier(): String {
        let randomBytes = random.nextBytes(32)
        return base64.encodeToString(randomBytes)
            .replace("+", "-")
            .replace("/", "_")
            .replace("=", "")
    }

    /**
     * 根据 code_verifier 生成 code_challenge
     * @param verifier code_verifier
     * @returns code_challenge
     */
    public func generateCodeChallenge(verifier: String): String {
        let hash = sha256.hash(verifier.toArray())
        return base64.encodeToString(hash)
            .replace("+", "-")
            .replace("/", "_")
            .replace("=", "")
    }

    /**
     * 构建 OAuth 授权 URL
     * @param clientId 应用 ID
     * @param redirectUri 回调地址
     * @param scope 权限范围
     * @param state state 参数
     * @param responseType 响应类型，默认为 code
     * @returns 完整的授权 URL
     */
    public func buildAuthorizationUrl(
        clientId: String,
        redirectUri: String,
        scope: String,
        state: String,
        responseType: String = "code"
    ): String {
        return "${clientId}&redirect_uri=${redirectUri}&response_type=${responseType}&scope=${scope}&state=${state}"
    }
}
