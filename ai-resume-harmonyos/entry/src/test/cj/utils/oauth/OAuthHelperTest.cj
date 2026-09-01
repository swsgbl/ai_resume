package utils.oauth

import std.testing.*
import utils.oauth.OAuthHelper

/**
 * OAuthHelper 单元测试
 */
class OAuthHelperTest {
    private let oauthHelper: OAuthHelper

    init() {
        this.oauthHelper = OAuthHelper()
    }

    /**
     * 测试state生成功能
     */
    @Test
    func testGenerateState() {
        // 生成state
        let state1 = this.oauthHelper.generateState()
        let state2 = this.oauthHelper.generateState()

        // 验证state不为空
        Assert.assertFalse(state1.isEmpty(), "生成的state不能为空")
        Assert.assertFalse(state2.isEmpty(), "生成的state不能为空")

        // 验证每次生成的state不同
        Assert.assertNotEquals(state1, state2, "每次生成的state应该不同")

        // 验证state长度（Base64编码后应该有固定长度）
        Assert.assertTrue(state1.length() >= 20, "state长度应该足够安全")
    }

    /**
     * 测试state验证功能
     */
    @Test
    func testValidateState() {
        let originalState = this.oauthHelper.generateState()

        // 测试正确的state
        Assert.assertTrue(
            this.oauthHelper.validateState(originalState, originalState),
            "正确的state应该验证通过"
        )

        // 测试错误的state
        let wrongState = this.oauthHelper.generateState()
        Assert.assertFalse(
            this.oauthHelper.validateState(wrongState, originalState),
            "错误的state应该验证失败"
        )

        // 测试空state
        Assert.assertFalse(
            this.oauthHelper.validateState("", originalState),
            "空state应该验证失败"
        )
    }

    /**
     * 测试PKCE code_verifier生成
     */
    @Test
    func testGenerateCodeVerifier() {
        let verifier = this.oauthHelper.generateCodeVerifier()

        // 验证verifier不为空
        Assert.assertFalse(verifier.isEmpty(), "code_verifier不能为空")

        // 验证verifier长度（PKCE要求43-128字符）
        let length = verifier.length()
        Assert.assertTrue(length >= 43 && length <= 128, "code_verifier长度应该在43-128之间")

        // 验证verifier只包含安全字符
        Assert.assertTrue(verifier.matches("[a-zA-Z0-9-._~]+"), "code_verifier应该只包含安全字符")
    }

    /**
     * 测试PKCE code_challenge生成
     */
    @Test
    func testGenerateCodeChallenge() {
        let verifier = this.oauthHelper.generateCodeVerifier()
        let challenge = this.oauthHelper.generateCodeChallenge(verifier)

        // 验证challenge不为空
        Assert.assertFalse(challenge.isEmpty(), "code_challenge不能为空")

        // 验证challenge长度
        Assert.assertTrue(challenge.length() >= 43, "code_challenge长度应该足够")

        // 验证challenge是SHA256哈希（Base64编码）
        Assert.assertTrue(challenge.matches("[a-zA-Z0-9-_]+"), "code_challenge格式正确")
    }

    /**
     * 测试code_challenge的一致性
     */
    @Test
    func testCodeChallengeConsistency() {
        let verifier = "test_verifier_12345"
        let challenge1 = this.oauthHelper.generateCodeChallenge(verifier)
        let challenge2 = this.oauthHelper.generateCodeChallenge(verifier)

        // 相同的verifier应该生成相同的challenge
        Assert.assertEquals(challenge1, challenge2, "相同verifier应该生成相同challenge")
    }

    /**
     * 测试授权URL构建
     */
    @Test
    func testBuildAuthorizationUrl() {
        let clientId = "test_client_id"
        let redirectUri = "https://example.com/callback"
        let scope = "user_info"
        let state = "test_state_123"

        let authUrl = this.oauthHelper.buildAuthorizationUrl(
            clientId: clientId,
            redirectUri: redirectUri,
            scope: scope,
            state: state
        )

        // 验证URL包含必要参数
        Assert.assertTrue(authUrl.contains(clientId), "URL应该包含client_id")
        Assert.assertTrue(authUrl.contains(redirectUri), "URL应该包含redirect_uri")
        Assert.assertTrue(authUrl.contains(scope), "URL应该包含scope")
        Assert.assertTrue(authUrl.contains(state), "URL应该包含state")
        Assert.assertTrue(authUrl.contains("response_type=code"), "URL应该包含response_type")
    }

    /**
     * 测试URL参数编码
     */
    @Test
    func testUrlParameterEncoding() {
        let specialChars = "test client&id=123"
        let authUrl = this.oauthHelper.buildAuthorizationUrl(
            clientId: specialChars,
            redirectUri: "https://example.com/callback",
            scope: "user_info",
            state: "test_state"
        )

        // 验证特殊字符被正确编码
        Assert.assertTrue(authUrl.contains("%20") || authUrl.contains("+"), "空格应该被编码")
    }

    /**
     * 测试安全性要求
     */
    @Test
    func testSecurityRequirements() {
        // 测试state的随机性（生成100个state，确保没有重复）
        let states = HashSet<String>()
        for (i in 0..100) {
            let state = this.oauthHelper.generateState()
            Assert.assertFalse(states.contains(state), "生成的state应该唯一")
            states.add(state)
        }
    }

    /**
     * 测试边界情况
     */
    @Test
    func testEdgeCases() {
        // 测试空字符串验证
        Assert.assertFalse(this.oauthHelper.validateState("", ""), "空state验证应该失败")

        // 测试极长的clientId
        let longClientId = "a" * 1000
        let authUrl = this.oauthHelper.buildAuthorizationUrl(
            clientId: longClientId,
            redirectUri: "https://example.com/callback",
            scope: "user_info",
            state: "test_state"
        )
        Assert.assertTrue(authUrl.contains(longClientId), "应该支持长clientId")
    }
}
