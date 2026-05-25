package models.oauth

import std.testing.*
import models.oauth.OAuthUser
import models.oauth.OAuthProvider
import models.oauth.Gender

/**
 * OAuthUser 单元测试
 */
class OAuthUserTest {

    /**
     * 测试OAuthUser创建
     */
    @Test
    func testOAuthUserCreation() {
        let user = OAuthUser(
            provider: OAuthProvider.WECHAT,
            openId: "test_open_id_123",
            nickname: "测试用户",
            avatarUrl: "https://example.com/avatar.jpg",
            gender: Gender.MALE
        )

        Assert.assertEquals(OAuthProvider.WECHAT, user.provider, "提供商应该正确设置")
        Assert.assertEquals("test_open_id_123", user.openId, "OpenID应该正确设置")
        Assert.assertEquals("测试用户", user.nickname, "昵称应该正确设置")
        Assert.assertEquals(Gender.MALE, user.gender, "性别应该正确设置")
    }

    /**
     * 测试微信用户创建
     */
    @Test
    func testWeChatUserCreation() {
        let wechatUser = OAuthUser(
            provider: OAuthProvider.WECHAT,
            openId: "wx_open_id_456",
            unionId: "wx_union_id_789",
            nickname: "微信用户",
            avatarUrl: "https://wx.qlogo.cn/avatar.jpg",
            gender: Gender.FEMALE,
            country: "中国",
            province: "广东",
            city: "深圳",
            language: "zh_CN"
        )

        Assert.assertEquals(OAuthProvider.WECHAT, wechatUser.provider, "应该是微信用户")
        Assert.assertEquals("wx_open_id_456", wechatUser.openId, "OpenID应该正确")
        Assert.assertEquals("wx_union_id_789", wechatUser.unionId, "UnionID应该正确")
        Assert.assertEquals("微信用户", wechatUser.nickname, "昵称应该正确")
    }

    /**
     * 测试支付宝用户创建
     */
    @Test
    func testAlipayUserCreation() {
        let alipayUser = OAuthUser(
            provider: OAuthProvider.ALIPAY,
            openId: "alipay_user_id_123",
            nickname: "支付宝用户",
            avatarUrl: "https://alipay.com/avatar.jpg",
            gender: Gender.MALE,
            city: "杭州"
        )

        Assert.assertEquals(OAuthProvider.ALIPAY, alipayUser.provider, "应该是支付宝用户")
        Assert.assertEquals("alipay_user_id_123", alipayUser.openId, "用户ID应该正确")
        Assert.assertNull(alipayUser.unionId, "支付宝用户没有UnionID")
    }

    /**
     * 测试可选字段的null值
     */
    @Test
    func testOptionalFields() {
        let minimalUser = OAuthUser(
            provider: OAuthProvider.WECHAT,
            openId: "minimal_user"
        )

        Assert.assertNull(minimalUser.unionId, "UnionID应该为null")
        Assert.assertNull(minimalUser.nickname, "昵称应该为null")
        Assert.assertNull(minimalUser.avatarUrl, "头像应该为null")
        Assert.assertNull(minimalUser.gender, "性别应该为null")
        Assert.assertNull(minimalUser.country, "国家应该为null")
        Assert.assertNull(minimalUser.province, "省份应该为null")
        Assert.assertNull(minimalUser.city, "城市应该为null")
        Assert.assertNull(minimalUser.language, "语言应该为null")
    }

    /**
     *测试性别枚举
     */
    @Test
    func testGenderEnum() {
        let maleUser = OAuthUser(
            provider: OAuthProvider.WECHAT,
            openId: "male_user",
            gender: Gender.MALE
        )
        Assert.assertEquals(Gender.MALE, maleUser.gender, "应该是男性")

        let femaleUser = OAuthUser(
            provider: OAuthProvider.WECHAT,
            openId: "female_user",
            gender: Gender.FEMALE
        )
        Assert.assertEquals(Gender.FEMALE, femaleUser.gender, "应该是女性")

        let unknownUser = OAuthUser(
            provider: OAuthProvider.WECHAT,
            openId: "unknown_user",
            gender: Gender.UNKNOWN
        )
        Assert.assertEquals(Gender.UNKNOWN, unknownUser.gender, "应该是未知性别")
    }

    /**
     * 测试提供商枚举
     */
    @Test
    func testProviderEnum() {
        let wechatUser = OAuthUser(
            provider: OAuthProvider.WECHAT,
            openId: "wx_user"
        )
        Assert.assertEquals(OAuthProvider.WECHAT, wechatUser.provider, "应该是微信")

        let alipayUser = OAuthUser(
            provider: OAuthProvider.ALIPAY,
            openId: "alipay_user"
        )
        Assert.assertEquals(OAuthProvider.ALIPAY, alipayUser.provider, "应该是支付宝")

        let unknownUser = OAuthUser(
            provider: OAuthProvider.UNKNOWN,
            openId: "unknown_provider_user"
        )
        Assert.assertEquals(OAuthProvider.UNKNOWN, unknownUser.provider, "应该是未知提供商")
    }

    /**
     * 测试用户信息的完整性
     */
    @Test
    func testUserInformationCompleteness() {
        let completeUser = OAuthUser(
            provider: OAuthProvider.WECHAT,
            openId: "complete_user_123",
            unionId: "union_id_456",
            nickname: "完整用户",
            avatarUrl: "https://example.com/avatar.jpg",
            gender: Gender.MALE,
            country: "中国",
            province: "广东",
            city: "深圳",
            language: "zh_CN"
        )

        Assert.assertNotNull(completeUser.provider, "提供商不能为null")
        Assert.assertNotNull(completeUser.openId, "OpenID不能为null")
        Assert.assertFalse(completeUser.openId.isEmpty(), "OpenID不能为空")
    }

    /**
     * 测试边界情况
     */
    @Test
    func testEdgeCases() {
        // 测试空字符串字段
        let emptyFieldsUser = OAuthUser(
            provider: OAuthProvider.WECHAT,
            openId: "",
            nickname: "",
            avatarUrl: ""
        )
        Assert.assertEquals("", emptyFieldsUser.openId, "应该支持空字符串OpenID")
        Assert.assertEquals("", emptyFieldsUser.nickname, "应该支持空字符串昵称")

        // 测试特殊字符
        let specialCharUser = OAuthUser(
            provider: OAuthProvider.WECHAT,
            openId: "user@#$%^&*()",
            nickname: "用户<>\"'&",
            avatarUrl: "https://example.com/image.jpg?v=1&test=2"
        )
        Assert.assertEquals("user@#$%^&*()", specialCharUser.openId, "应该支持特殊字符")
        Assert.assertEquals("用户<>\"'&", specialCharUser.nickname, "应该支持特殊字符昵称")
    }

    /**
     * 测试用户数据的持久化友好性
     */
    @Test
    func testDataSerializationFriendliness() {
        // 验证所有字段都可以正常序列化
        let user = OAuthUser(
            provider: OAuthProvider.WECHAT,
            openId: "serialization_test",
            nickname: "序列化测试用户",
            avatarUrl: "https://example.com/avatar.jpg",
            gender: Gender.MALE,
            country: "中国",
            province: "北京",
            city: "北京",
            language: "zh_CN"
        )

        // 验证数据完整性
        Assert.assertEquals("serialization_test", user.openId, "数据应该保持完整")
        Assert.assertEquals("序列化测试用户", user.nickname, "中文应该正确处理")
        Assert.assertEquals("中国", user.country, "中文国家名应该正确处理")
    }
}
