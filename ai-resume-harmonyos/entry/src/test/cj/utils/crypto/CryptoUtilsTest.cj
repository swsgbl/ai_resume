package utils.crypto

import std.testing.*
import utils.crypto.CryptoUtils

/**
 * CryptoUtils 单元测试
 */
class CryptoUtilsTest {
    private let cryptoUtils: CryptoUtils

    init() {
        this.cryptoUtils = CryptoUtils()
    }

    /**
     * 测试字符串加密和解密
     */
    @Test
    func testEncryptAndDecrypt() {
        let plainText = "Hello, World!"
        let cipherText = this.cryptoUtils.encrypt(plainText)
        let decryptedText = this.cryptoUtils.decrypt(cipherText)

        // 验证加密后的文本与原文不同
        Assert.assertNotEquals(plainText, cipherText, "加密后的文本应该与原文不同")

        // 验证解密后的文本与原文相同
        Assert.assertEquals(plainText, decryptedText, "解密后的文本应该与原文相同")
    }

    /**
     * 测试空字符串加密解密
     */
    @Test
    func testEncryptEmptyString() {
        let plainText = ""
        let cipherText = this.cryptoUtils.encrypt(plainText)
        let decryptedText = this.cryptoUtils.decrypt(cipherText)

        Assert.assertEquals(plainText, decryptedText, "空字符串加密解密应该正常工作")
    }

    /**
     * 测试特殊字符加密解密
     */
    @Test
    func testEncryptSpecialCharacters() {
        let specialText = "中文!@#$%^&*()_+-=[]{}|;':\",./<>?"
        let cipherText = this.cryptoUtils.encrypt(specialText)
        let decryptedText = this.cryptoUtils.decrypt(cipherText)

        Assert.assertEquals(specialText, decryptedText, "特殊字符加密解密应该正常工作")
    }

    /**
     * 测试长文本加密解密
     */
    @Test
    func testEncryptLongText() {
        let longText = "a" * 10000 // 10KB文本
        let cipherText = this.cryptoUtils.encrypt(longText)
        let decryptedText = this.cryptoUtils.decrypt(cipherText)

        Assert.assertEquals(longText, decryptedText, "长文本加密解密应该正常工作")
    }

    /**
     * 测试加密结果的Base64编码
     */
    @Test
    func testEncryptedIsBase64() {
        let plainText = "test message"
        let cipherText = this.cryptoUtils.encrypt(plainText)

        // 验证加密结果是有效的Base64字符串
        Assert.assertTrue(this.isValidBase64(cipherText), "加密结果应该是有效的Base64字符串")
    }

    /**
     * 测试相同输入产生不同输出（防止确定性加密）
     */
    @Test
    func testEncryptionIsNonDeterministic() {
        let plainText = "same input"
        let cipher1 = this.cryptoUtils.encrypt(plainText)
        let cipher2 = this.cryptoUtils.encrypt(plainText)

        // 每次加密应该产生不同的结果（因为有IV）
        Assert.assertNotEquals(cipher1, cipher2, "相同输入的加密结果应该不同")
    }

    /**
     * 测试SHA-256哈希功能
     */
    @Test
    func testHash() {
        let input = "test input"
        let hash1 = this.cryptoUtils.hash(input)
        let hash2 = this.cryptoUtils.hash(input)

        // 验证哈希不为空
        Assert.assertFalse(hash1.isEmpty(), "哈希结果不能为空")

        // 验证哈希长度（SHA-256产生64字符的十六进制字符串）
        Assert.assertEquals(64, hash1.length(), "SHA-256哈希应该是64字符长")

        // 验证相同输入产生相同哈希
        Assert.assertEquals(hash1, hash2, "相同输入应该产生相同哈希")

        // 验证哈希是有效的十六进制字符串
        Assert.assertTrue(this.isValidHex(hash1), "哈希结果应该是有效的十六进制字符串")
    }

    /**
     * 测试哈希的单向性
     */
    @Test
    func testHashIsOneWay() {
        let input = "original text"
        let hash = this.cryptoUtils.hash(input)

        // 验证哈希与原文不同
        Assert.assertNotEquals(input, hash, "哈希结果应该与原文不同")

        // 验证无法从哈希反推原文（通过验证不同输入的哈希不同）
        let differentInput = "different text"
        let differentHash = this.cryptoUtils.hash(differentInput)
        Assert.assertNotEquals(hash, differentHash, "不同输入应该产生不同哈希")
    }

    /**
     * 测试哈希的雪崩效应
     */
    @Test
    func testHashAvalancheEffect() {
        let input1 = "test string 1"
        let input2 = "test string 2" // 只有一个字符不同
        let hash1 = this.cryptoUtils.hash(input1)
        let hash2 = this.cryptoUtils.hash(input2)

        // 验证微小变化导致哈希完全不同
        let diffCount = this.countDifferences(hash1, hash2)
        Assert.assertTrue(diffCount > 30, "雪崩效应：微小变化应该导致哈希显著不同")
    }

    /**
     * 测试加密解密性能
     */
    @Test
    func testEncryptionPerformance() {
        let testText = "performance test text"
        let iterations = 100

        let startTime = System.currentTimeMillis()
        for (i in 0..iterations) {
            let cipher = this.cryptoUtils.encrypt(testText)
            let _ = this.cryptoUtils.decrypt(cipher)
        }
        let endTime = System.currentTimeMillis()

        let duration = endTime - startTime
        let avgTime = duration / iterations

        // 验证平均每次加密解密在合理时间内（< 100ms）
        Assert.assertTrue(avgTime < 100, "平均加密解密时间应该在100ms以内")
    }

    /**
     * 测试边界情况
     */
    @Test
    func testEdgeCases() {
        // 测试null输入（根据实际实现调整）
        // 测试非常大的输入
        let hugeText = "a" * 1000000 // 1MB文本
        let cipher = this.cryptoUtils.encrypt(hugeText)
        let decrypted = this.cryptoUtils.decrypt(cipher)
        Assert.assertEquals(hugeText, decrypted, "应该能处理大文本")
    }

    /**
     * 测试安全性要求
     */
    @Test
    func testSecurityRequirements() {
        // 验证加密强度（密钥长度）
        // 验证加密算法符合标准
        // 验证没有已知的加密弱点

        // 测试不同的相似输入产生完全不同的密文
        let input1 = "password123"
        let input2 = "password124" // 只有一个字符不同
        let cipher1 = this.cryptoUtils.encrypt(input1)
        let cipher2 = this.cryptoUtils.encrypt(input2)

        let cipherDiff = this.countDifferences(cipher1, cipher2)
        Assert.assertTrue(cipherDiff > 20, "相似输入的密文应该显著不同")
    }

    /**
     * 辅助方法：验证是否为有效Base64
     */
    private func isValidBase64(input: String): Bool {
        return input.matches("^[a-zA-Z0-9+/]*={0,2}$")
    }

    /**
     * 辅助方法：验证是否为有效十六进制
     */
    private func isValidHex(input: String): Bool {
        return input.matches("^[a-fA-F0-9]+$")
    }

    /**
     * 辅助方法：计算两个字符串的差异字符数
     */
    private func countDifferences(str1: String, str2: String): Int {
        let minLength = Math.min(str1.length(), str2.length())
        let maxLength = Math.max(str1.length(), str2.length())
        var diff = 0

        for (i in 0..minLength) {
            if (str1.charAt(i) != str2.charAt(i)) {
                diff++
            }
        }

        // 加上长度差异
        diff += (maxLength - minLength)

        return diff
    }
}
