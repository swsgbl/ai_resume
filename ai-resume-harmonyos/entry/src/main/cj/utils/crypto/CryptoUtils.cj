package utils.crypto

import ohos.security.encryption.*
import std.convert.Base64

/**
 * 加密工具类
 * 提供对称加密、哈希等加密功能
 */
public class CryptoUtils {
    private let cipher: Cipher
    private let keyFactory: SecretKeyFactory
    private let base64: Base64
    private let algorithm: String = "AES/GCB/NoPadding"
    private let keyAlgorithm: String = "AES"
    private let keySize: Int = 256

    // 默认初始化向量（实际应用中应该从配置获取）
    private let defaultIV: ByteArray = byteArrayOf[
        0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07,
        0x08, 0x09, 0x0A, 0x0B, 0x0C, 0x0D, 0x0E, 0x0F
    ]

    public init() {
        cipher = Cipher.getInstance(algorithm)
        keyFactory = SecretKeyFactory.getInstance(keyAlgorithm)
        base64 = Base64()
    }

    /**
     * 生成密钥
     * @returns 密钥字节数组
     */
    private func generateKey(): ByteArray {
        let keyGen = KeyGenerator.getInstance(keyAlgorithm)
        keyGen.init(keySize)
        let secretKey = keyGen.generateKey()
        return secretKey.getEncoded()
    }

    /**
     * 加密字符串
     * @param plainText 明文
     * @returns Base64 编码的密文
     */
    public func encrypt(plainText: String): String {
        try {
            let key = generateKey()
            let secretKey = SecretKeySpec(key, keyAlgorithm)
            let ivParameterSpec = IvParameterSpec(defaultIV)

            cipher.init(Cipher.ENCRYPT_MODE, secretKey, ivParameterSpec)
            let encryptedBytes = cipher.doFinal(plainText.toByteArray())
            return base64.encodeToString(encryptedBytes)
        } catch (e: Exception) {
            // 日志记录错误
            return ""
        }
    }

    /**
     * 解密字符串
     * @param cipherText Base64 编码的密文
     * @returns 明文
     */
    public func decrypt(cipherText: String): String {
        try {
            let key = generateKey()
            let secretKey = SecretKeySpec(key, keyAlgorithm)
            let ivParameterSpec = IvParameterSpec(defaultIV)

            cipher.init(Cipher.DECRYPT_MODE, secretKey, ivParameterSpec)
            let encryptedBytes = base64.decode(cipherText)
            let decryptedBytes = cipher.doFinal(encryptedBytes)
            return String(decryptedBytes)
        } catch (e: Exception) {
            // 日志记录错误
            return ""
        }
    }

    /**
     * 哈希字符串
     * @param input 输入字符串
     * @returns 哈希值的十六进制字符串
     */
    public func hash(input: String): String {
        let digest = MessageDigest.getInstance("SHA-256")
        let hashBytes = digest.digest(input.toByteArray())
        return bytesToHex(hashBytes)
    }

    /**
     * 将字节数组转换为十六进制字符串
     * @param bytes 字节数组
     * @returns 十六进制字符串
     */
    private func bytesToHex(bytes: ByteArray): String {
        let hexString = StringBuilder()
        for (byte in bytes) {
            let hex = Integer.toHexString(byte.toInt() & 0xFF)
            if (hex.length < 2) {
                hexString.append('0')
            }
            hexString.append(hex)
        }
        return hexString.toString()
    }
}
