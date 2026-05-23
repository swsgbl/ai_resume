package utils.crypto

import ohos.security.encryption.*
import std.convert.Base64
import std.concurrent.ThreadPool
import std.concurrent.ConcurrentHashMap

/**
 * 优化的加密工具类
 * 提供高性能的对称加密、哈希等功能
 * 使用对象池和缓存机制提升性能
 */
public class OptimizedCryptoUtils {
    private let cipher: Cipher
    private let keyFactory: SecretKeyFactory
    private let base64: Base64
    private let algorithm: String = "AES/GCB/NoPadding"
    private let keyAlgorithm: String = "AES"
    private let keySize: Int = 256

    // 性能优化：密钥缓存
    private let keyCache: ConcurrentHashMap<String, ByteArray>
    private let cipherCache: ConcurrentHashMap<String, Cipher>

    // 性能优化：线程池
    private let executor: ThreadPool

    // 性能优化：预分配缓冲区
    private let bufferPool: ByteArrayPool

    // 默认初始化向量
    private let defaultIV: ByteArray = byteArrayOf[
        0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07,
        0x08, 0x09, 0x0A, 0x0B, 0x0C, 0x0D, 0x0E, 0x0F
    ]

    public init() {
        cipher = Cipher.getInstance(algorithm)
        keyFactory = SecretKeyFactory.getInstance(keyAlgorithm)
        base64 = Base64()

        // 初始化缓存（容量16，并发级别4）
        keyCache = ConcurrentHashMap<String, ByteArray>(16, 0.75f, 4)
        cipherCache = ConcurrentHashMap<String, Cipher>(16, 0.75f, 4)

        // 初始化线程池（核心线程数=CPU核心数，最大线程数=CPU核心数*2）
        let cores = Runtime.getRuntime().availableProcessors()
        executor = ThreadPool(cores, cores * 2, 60L, TimeUnit.SECONDS)

        // 初始化缓冲区池（预分配8KB缓冲区，最多16个）
        bufferPool = ByteArrayPool(8192, 16)
    }

    /**
     * 优化的加密方法 - 使用缓存和对象池
     * @param plainText 明文
     * @returns Base64 编码的密文
     */
    public func encryptOptimized(plainText: String): String {
        try {
            // 使用缓存的密钥
            let key = this.getOrCreateKey()

            // 使用缓存的Cipher实例
            let cachedCipher = this.getOrCreateCipher(key, Cipher.ENCRYPT_MODE)

            // 从对象池获取缓冲区
            let inputBuffer = this.bufferPool.borrow()
            let outputBuffer = this.bufferPool.borrow()

            try {
                // 加密操作
                let inputBytes = plainText.toByteArray(inputBuffer)
                let encryptedBytes = cachedCipher.doFinal(inputBytes, outputBuffer)

                // Base64编码
                return base64.encodeToString(encryptedBytes)
            } finally {
                // 归还缓冲区到对象池
                this.bufferPool.release(inputBuffer)
                this.bufferPool.release(outputBuffer)
            }
        } catch (e: Exception) {
            // 记录错误但不抛出异常，保持向后兼容
            return ""
        }
    }

    /**
     * 优化的解密方法 - 使用缓存和对象池
     * @param cipherText Base64 编码的密文
     * @returns 明文
     */
    public func decryptOptimized(cipherText: String): String {
        try {
            // 使用缓存的密钥
            let key = this.getOrCreateKey()

            // 使用缓存的Cipher实例
            let cachedCipher = this.getOrCreateCipher(key, Cipher.DECRYPT_MODE)

            // 从对象池获取缓冲区
            let inputBuffer = this.bufferPool.borrow()
            let outputBuffer = this.bufferPool.borrow()

            try {
                // Base64解码
                let encryptedBytes = base64.decode(cipherText, inputBuffer)

                // 解密操作
                let decryptedBytes = cachedCipher.doFinal(encryptedBytes, outputBuffer)

                return String(decryptedBytes)
            } finally {
                // 归还缓冲区到对象池
                this.bufferPool.release(inputBuffer)
                this.bufferPool.release(outputBuffer)
            }
        } catch (e: Exception) {
            return ""
        }
    }

    /**
     * 优化的哈希方法 - 使用缓存和批处理
     * @param input 输入字符串
     * @returns 哈希值的十六进制字符串
     */
    public func hashOptimized(input: String): String {
        // 使用缓存的MessageDigest实例
        let digest = this.getOrCreateMessageDigest()

        let inputBytes = input.toByteArray()
        let hashBytes = digest.digest(inputBytes)

        return this.bytesToHexOptimized(hashBytes)
    }

    /**
     * 批量哈希计算 - 利用并行处理
     * @param inputs 输入字符串数组
     * @returns 哈希值数组
     */
    public func hashBatch(inputs: Array<String>): Array<String> {
        let futures = ArrayList<Future<String>>()

        // 并行处理多个哈希计算
        for (input in inputs) {
            let future = this.executor.submit(() => {
                return this.hashOptimized(input)
            })
            futures.add(future)
        }

        // 收集结果
        let results = ArrayList<String>()
        for (future in futures) {
            try {
                results.add(future.get())
            } catch (e: Exception) {
                results.add("") // 失败时返回空字符串
            }
        }

        return results.toArray()
    }

    /**
     * 获取或创建密钥（带缓存）
     * @returns 密钥字节数组
     */
    private func getOrCreateKey(): ByteArray {
        let cacheKey = "default_key"

        // 尝试从缓存获取
        let cachedKey = this.keyCache.get(cacheKey)
        if (cachedKey != null) {
            return cachedKey
        }

        // 缓存未命中，生成新密钥
        let newKey = this.generateKey()

        // 放入缓存
        this.keyCache.put(cacheKey, newKey)

        return newKey
    }

    /**
     * 获取或创建Cipher实例（带缓存）
     * @param key 密钥
     * @param mode 模式（加密或解密）
     * @returns Cipher实例
     */
    private func getOrCreateCipher(key: ByteArray, mode: Int): Cipher {
        let cacheKey = "${mode}_${key.hashCode()}"

        // 尝试从缓存获取
        let cachedCipher = this.cipherCache.get(cacheKey)
        if (cachedCipher != null) {
            return cachedCipher
        }

        // 缓存未命中，创建新Cipher
        let newCipher = Cipher.getInstance(this.algorithm)
        let secretKey = SecretKeySpec(key, this.keyAlgorithm)
        let ivParameterSpec = IvParameterSpec(this.defaultIV)

        newCipher.init(mode, secretKey, ivParameterSpec)

        // 放入缓存
        this.cipherCache.put(cacheKey, newCipher)

        return newCipher
    }

    /**
     * 生成密钥
     * @returns 密钥字节数组
     */
    private func generateKey(): ByteArray {
        let keyGen = KeyGenerator.getInstance(this.keyAlgorithm)
        keyGen.init(this.keySize)
        let secretKey = keyGen.generateKey()
        return secretKey.getEncoded()
    }

    /**
     * 获取或创建MessageDigest实例（带缓存）
     * @returns MessageDigest实例
     */
    private func getOrCreateMessageDigest(): MessageDigest {
        // ThreadLocal模式，每个线程有自己的实例
        let threadLocal = ThreadLocal<MessageDigest>()
        let digest = threadLocal.get()

        if (digest == null) {
            let newDigest = MessageDigest.getInstance("SHA-256")
            threadLocal.set(newDigest)
            return newDigest
        }

        return digest
    }

    /**
     * 优化的字节数组转十六进制字符串
     * @param bytes 字节数组
     * @returns 十六进制字符串
     */
    private func bytesToHexOptimized(bytes: ByteArray): String {
        // 预分配StringBuilder容量（每个字节2个字符）
        let hexString = StringBuilder(bytes.length * 2)

        // 使用查找表代替运行时计算
        let hexTable = this.getHexTable()

        for (byte in bytes) {
            let value = byte.toInt() & 0xFF
            hexString.append(hexTable[value >>> 4])
            hexString.append(hexTable[value & 0x0F])
        }

        return hexString.toString()
    }

    /**
     * 获取十六进制查找表
     * @returns 十六进制字符数组
     */
    private func getHexTable(): Array<char> {
        return charArrayOf[
            '0', '1', '2', '3', '4', '5', '6', '7', '8', '9', 'a', 'b', 'c', 'd', 'e', 'f'
        ]
    }

    /**
     * 清理缓存
     */
    public func clearCache() {
        this.keyCache.clear()
        this.cipherCache.clear()
    }

    /**
     * 获取缓存统计信息
     * @returns 缓存统计
     */
    public func getCacheStats(): Map<String, Int> {
        let stats = HashMap<String, Int>()
        stats.put("keyCacheSize", this.keyCache.size())
        stats.put("cipherCacheSize", this.cipherCache.size())
        stats.put("bufferPoolSize", this.bufferPool.size())
        return stats
    }

    /**
     * 关闭资源
     */
    public func close() {
        this.executor.shutdown()
        this.clearCache()
    }
}

/**
 * 字节数组对象池
 * 减少内存分配和GC压力
 */
internal class ByteArrayPool {
    private let pool: ConcurrentLinkedQueue<ByteArray>
    private let bufferSize: Int
    private let maxPoolSize: Int

    public init(bufferSize: Int, maxPoolSize: Int) {
        this.bufferSize = bufferSize
        this.maxPoolSize = maxPoolSize
        this.pool = ConcurrentLinkedQueue<ByteArray>()
    }

    /**
     * 借用缓冲区
     * @returns 字节数组缓冲区
     */
    public func borrow(): ByteArray {
        let buffer = this.pool.poll()
        if (buffer != null) {
            return buffer
        }

        // 池中没有可用缓冲区，创建新的
        return ByteArray(this.bufferSize)
    }

    /**
     * 归还缓冲区
     * @param buffer 字节数组缓冲区
     */
    public func release(buffer: ByteArray) {
        // 如果池未满，归还到池中
        if (this.pool.size() < this.maxPoolSize) {
            // 清空缓冲区数据
            buffer.fill(0)
            this.pool.offer(buffer)
        }
        // 否则让GC回收
    }

    /**
     * 获取当前池大小
     * @returns 池中缓冲区数量
     */
    public func size(): Int {
        return this.pool.size()
    }
}
