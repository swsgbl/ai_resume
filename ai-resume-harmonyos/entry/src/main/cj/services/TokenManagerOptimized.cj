package services

import ohos.data.preferences.Preferences
import ohos.data.preferences.PreferencesOptions
import utils.crypto.OptimizedCryptoUtils

/**
 * 优化的Token管理器
 * 使用缓存、预加载、批量操作等性能优化技术
 */
public class TokenManagerOptimized {
    private let preferences: Preferences
    private let cryptoUtils: OptimizedCryptoUtils
    private let accessTokenKey: String = "oauth_access_token"
    private let refreshTokenKey: String = "oauth_refresh_token"
    private let tokenExpiryKey: String = "oauth_token_expiry"
    private let tokenTypeKey: String = "oauth_token_type"

    // 性能优化：内存缓存
    private let memoryCache: TokenCache
    private let cacheLock: ReentrantLock

    // 性能优化：预刷新阈值
    private let refreshThreshold: Int64 = 300000 // 5分钟

    // 性能优化：批量操作支持
    private let batchOperationSize: Int = 10

    public init(context: Context) {
        let options = PreferencesOptions()
        options.name = "oauth_tokens"
        preferences = Preferences.getPreferences(context, options)
        cryptoUtils = OptimizedCryptoUtils()

        // 初始化内存缓存（容量5，过期时间5分钟）
        memoryCache = TokenCache(5, 300000)
        cacheLock = ReentrantLock()

        // 预加载Token到内存缓存
        this.preloadTokens()
    }

    /**
     * 优化的访问令牌获取 - 使用内存缓存
     * @returns 访问令牌，如果不存在则返回 null
     */
    public func getAccessToken(): String? {
        // 首先尝试从内存缓存获取
        let cachedToken = this.memoryCache.get("access_token")
        if (cachedToken != null && !cachedToken.isEmpty()) {
            return cachedToken
        }

        // 缓存未命中，从持久存储读取
        let encryptedToken = this.preferences.get(accessTokenKey, "")
        if (encryptedToken.isEmpty()) {
            return null
        }

        // 解密并缓存
        let decryptedToken = this.cryptoUtils.decryptOptimized(encryptedToken)
        if (!decryptedToken.isEmpty()) {
            this.memoryCache.put("access_token", decryptedToken)
        }

        return decryptedToken.isEmpty() ? null : decryptedToken
    }

    /**
     * 优化的访问令牌保存 - 使用内存缓存和异步持久化
     * @param token 访问令牌
     */
    public func saveAccessToken(token: String) {
        this.cacheLock.lock()
        try {
            // 先更新内存缓存
            this.memoryCache.put("access_token", token)

            // 异步持久化到存储
            this.asyncPersistAccessToken(token)
        } finally {
            this.cacheLock.unlock()
        }
    }

    /**
     * 检查令牌是否需要刷新 - 使用预测性刷新
     * @returns true 表示需要刷新
     */
    public func needsRefresh(): Bool {
        // 先从缓存检查
        let expiryTime = this.getTokenExpiry()
        if (expiryTime == 0) {
            return true
        }

        let currentTime = System.currentTimeMillis()
        let timeUntilExpiry = expiryTime - currentTime

        // 在过期前5分钟就开始刷新（预测性刷新）
        return timeUntilExpiry <= this.refreshThreshold
    }

    /**
     * 批量保存Token信息 - 减少I/O操作
     * @param tokenInfo Token信息映射
     */
    public func saveTokenInfoBatch(tokenInfo: Map<String, String>) {
        this.cacheLock.lock()
        try {
            // 批量更新内存缓存
            for ((key, value) in tokenInfo) {
                this.memoryCache.put(key, value)
            }

            // 批量持久化
            this.batchPersistTokens(tokenInfo)
        } finally {
            this.cacheLock.unlock()
        }
    }

    /**
     * 智能Token刷新 - 自动检测并刷新
     * @param refreshTokenFunc 刷新令牌的函数
     * @returns 刷新后的访问令牌
     */
    public func smartRefresh(refreshTokenFunc: () -> String): String {
        if (this.needsRefresh()) {
            let newToken = refreshTokenFunc()
            this.saveAccessToken(newToken)
            return newToken
        }

        return this.getAccessToken()
    }

    /**
     * 预加载Token到内存缓存
     */
    private func preloadTokens() {
        // 异步预加载，不阻塞初始化
        Thread({
            let accessToken = this.getAccessTokenFromStorage()
            if (accessToken != null) {
                this.memoryCache.put("access_token", accessToken)
            }

            let refreshToken = this.getRefreshTokenFromStorage()
            if (refreshToken != null) {
                this.memoryCache.put("refresh_token", refreshToken)
            }
        }).start()
    }

    /**
     * 异步持久化访问令牌
     * @param token 访问令牌
     */
    private func asyncPersistAccessToken(token: String) {
        // 使用后台线程异步持久化
        Thread({
            let encryptedToken = this.cryptoUtils.encryptOptimized(token)
            this.preferences.put(accessTokenKey, encryptedToken)
            this.preferences.flush()
        }).start()
    }

    /**
     * 批量持久化Token
     * @param tokenInfo Token信息映射
     */
    private func batchPersistTokens(tokenInfo: Map<String, String>) {
        // 使用事务批量写入
        let editor = this.preferences.edit()

        for ((key, value) in tokenInfo) {
            let encryptedValue = this.cryptoUtils.encryptOptimized(value)
            editor.put(key, encryptedValue)
        }

        editor.apply() // 异步提交
    }

    /**
     * 从存储获取访问令牌（不使用缓存）
     * @returns 访问令牌
     */
    private func getAccessTokenFromStorage(): String? {
        let encryptedToken = this.preferences.get(accessTokenKey, "")
        if (encryptedToken.isEmpty()) {
            return null
        }

        let decryptedToken = this.cryptoUtils.decryptOptimized(encryptedToken)
        return decryptedToken.isEmpty() ? null : decryptedToken
    }

    /**
     * 从存储获取刷新令牌（不使用缓存）
     * @returns 刷新令牌
     */
    private func getRefreshTokenFromStorage(): String? {
        let encryptedToken = this.preferences.get(refreshTokenKey, "")
        if (encryptedToken.isEmpty()) {
            return null
        }

        let decryptedToken = this.cryptoUtils.decryptOptimized(encryptedToken)
        return decryptedToken.isEmpty() ? null : decryptedToken
    }

    /**
     * 获取Token过期时间
     * @returns 过期时间戳
     */
    public func getTokenExpiry(): Int64 {
        // 先从缓存获取
        let cachedExpiry = this.memoryCache.get("token_expiry")
        if (cachedExpiry != null) {
            return cachedExpiry.toInt64()
        }

        // 从存储获取
        let expiryStr = this.preferences.get(tokenExpiryKey, "0")
        return expiryStr.toInt64()
    }

    /**
     * 保存刷新令牌
     * @param token 刷新令牌
     */
    public func saveRefreshToken(token: String) {
        this.cacheLock.lock()
        try {
            this.memoryCache.put("refresh_token", token)
            let encryptedToken = this.cryptoUtils.encryptOptimized(token)
            this.preferences.put(refreshTokenKey, encryptedToken)
            this.preferences.flush()
        } finally {
            this.cacheLock.unlock()
        }
    }

    /**
     * 获取刷新令牌
     * @returns 刷新令牌
     */
    public func getRefreshToken(): String? {
        // 先从缓存获取
        let cachedToken = this.memoryCache.get("refresh_token")
        if (cachedToken != null && !cachedToken.isEmpty()) {
            return cachedToken
        }

        // 从存储获取
        return this.getRefreshTokenFromStorage()
    }

    /**
     * 清除所有Token
     */
    public func clearTokens() {
        this.cacheLock.lock()
        try {
            // 清除内存缓存
            this.memoryCache.clear()

            // 清除持久存储
            this.preferences.delete(accessTokenKey)
            this.preferences.delete(refreshTokenKey)
            this.preferences.delete(tokenExpiryKey)
            this.preferences.delete(tokenTypeKey)
            this.preferences.flush()
        } finally {
            this.cacheLock.unlock()
        }
    }

    /**
     * 获取缓存统计信息
     * @returns 缓存统计
     */
    public func getCacheStats(): Map<String, Object> {
        let stats = HashMap<String, Object>()
        stats.put("memoryCacheSize", this.memoryCache.size())
        stats.put("memoryCacheHitRate", this.memoryCache.getHitRate())
        return stats
    }
}

/**
 * Token内存缓存
 * 使用LRU策略和TTL过期
 */
internal class TokenCache {
    private let cache: LinkedHashMap<String, CacheEntry>
    private let maxSize: Int
    private let ttl: Int64
    private let lock: ReentrantLock

    public init(maxSize: Int, ttl: Int64) {
        this.maxSize = maxSize
        this.ttl = ttl
        this.lock = ReentrantLock()

        // LRU缓存：按访问顺序排序
        this.cache = LinkedHashMap<String, CacheEntry>(16, 0.75f, true) {
            protected override func removeEldestEntry(
                eldest: Map.Entry<String, CacheEntry>
            ): Bool {
                return size() > this.maxSize
            }
        }
    }

    /**
     * 获取缓存值
     * @param key 键
     * @returns 值，如果不存在或已过期则返回null
     */
    public func get(key: String): String? {
        this.lock.lock()
        try {
            let entry = this.cache.get(key)
            if (entry == null) {
                return null
            }

            // 检查是否过期
            if (this.isExpired(entry)) {
                this.cache.remove(key)
                return null
            }

            return entry.value
        } finally {
            this.lock.unlock()
        }
    }

    /**
     * 放入缓存
     * @param key 键
     * @param value 值
     */
    public func put(key: String, value: String) {
        this.lock.lock()
        try {
            let entry = CacheEntry(value, System.currentTimeMillis())
            this.cache.put(key, entry)
        } finally {
            this.lock.unlock()
        }
    }

    /**
     * 清除缓存
     */
    public func clear() {
        this.lock.lock()
        try {
            this.cache.clear()
        } finally {
            this.lock.unlock()
        }
    }

    /**
     * 获取缓存大小
     * @returns 缓存大小
     */
    public func size(): Int {
        this.lock.lock()
        try {
            return this.cache.size()
        } finally {
            this.lock.unlock()
        }
    }

    /**
     * 获取缓存命中率
     * @returns 命中率（百分比）
     */
    public func getHitRate(): Float {
        // TODO: 实现命中率统计
        return 0.0f
    }

    /**
     * 检查条目是否过期
     * @param entry 缓存条目
     * @returns 是否过期
     */
    private func isExpired(entry: CacheEntry): Bool {
        let currentTime = System.currentTimeMillis()
        return (currentTime - entry.timestamp) > this.ttl
    }
}

/**
 * 缓存条目
 */
internal class CacheEntry {
    public let value: String
    public let timestamp: Int64

    public init(value: String, timestamp: Int64) {
        this.value = value
        this.timestamp = timestamp
    }
}
