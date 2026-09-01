// RequestCache.cj - HTTP请求缓存（性能优化 - Phase 7）
package utils

import std.collection.*
import std.time.*

/**
 * HTTP请求缓存
 *
 * 使用LRU策略缓存GET请求的响应，减少网络请求次数
 * 支持TTL（Time To Live）过期机制
 */
public class RequestCache {
    private var cache: HashMap<String, CacheEntry> = HashMap<String, CacheEntry>()
    private let maxSize: Int32 = 50  // 最大缓存条目数
    private let defaultTTL: Int64 = 300000  // 默认TTL: 5分钟（毫秒）

    public init() {}

    /**
     * 缓存条目
     */
    private class CacheEntry {
        public var data: String
        public var timestamp: Int64
        public var ttl: Int64

        public init(data: String, ttl: Int64) {
            this.data = data
            this.timestamp = System.currentTimeMillis()
            this.ttl = ttl
        }

        public func isExpired(): Bool {
            let elapsed = System.currentTimeMillis() - timestamp
            return elapsed > ttl
        }
    }

    /**
     * 获取缓存数据
     *
     * @param key 缓存键（通常是URL）
     * @return 缓存的数据，如果不存在或已过期返回null
     */
    public func get(key: String): ?String {
        if (cache.containsKey(key)) {
            let entry = cache.get(key)
            if (entry != null && !entry.isExpired()) {
                return Some(entry.data)
            } else {
                // 过期，移除
                cache.remove(key)
            }
        }
        return None
    }

    /**
     * 存储缓存数据
     *
     * @param key 缓存键
     * @param data 要缓存的数据
     * @param ttl 生存时间（毫秒），默认使用defaultTTL
     */
    public func put(key: String, data: String, ttl: Int64 = defaultTTL): Unit {
        // 如果缓存已满，移除最旧的条目
        if (cache.size() >= maxSize) {
            removeOldestEntry()
        }

        cache.put(key, CacheEntry(data, ttl))
    }

    /**
     * 移除最旧的缓存条目（LRU策略的简化实现）
     */
    private func removeOldestEntry(): Unit {
        var oldestKey: String = ""
        var oldestTime: Int64 = System.currentTimeMillis()

        for (entry in cache.entries) {
            if (entry.value.timestamp < oldestTime) {
                oldestTime = entry.value.timestamp
                oldestKey = entry.key
            }
        }

        if (oldestKey != "") {
            cache.remove(oldestKey)
        }
    }

    /**
     * 清除所有缓存
     */
    public func clear(): Unit {
        cache.clear()
    }

    /**
     * 清除过期缓存
     */
    public func cleanupExpired(): Unit {
        let keysToRemove: ArrayList<String> = ArrayList<String>()

        for (entry in cache.entries) {
            if (entry.value.isExpired()) {
                keysToRemove.add(entry.key)
            }
        }

        for (key in keysToRemove) {
            cache.remove(key)
        }
    }

    /**
     * 获取缓存统计信息
     */
    public func getStats(): CacheStats {
        let expiredCount = countExpired()
        return CacheStats(
            cache.size(),
            maxSize,
            cache.size() - expiredCount,
            expiredCount
        )
    }

    /**
     * 统计过期条目数
     */
    private func countExpired(): Int32 {
        var count: Int32 = 0
        for (entry in cache.entries) {
            if (entry.value.isExpired()) {
                count++
            }
        }
        return count
    }
}

/**
 * 缓存统计信息
 */
public class CacheStats {
    public let size: Int32
    public let maxSize: Int32
    public let activeCount: Int32
    public let expiredCount: Int32

    public init(size: Int32, maxSize: Int32, activeCount: Int32, expiredCount: Int32) {
        this.size = size
        this.maxSize = maxSize
        this.activeCount = activeCount
        this.expiredCount = expiredCount
    }
}
