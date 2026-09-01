// ObjectPool.cj - 对象池（内存优化 - Phase 7）
package utils

import std.collection.*

/**
 * 对象池
 *
 * 重用对象减少内存分配和GC压力
 * 适用于频繁创建销毁的对象（如HTTP响应、数据模型等）
 */
public class ObjectPool<T> {
    private var pool: ArrayList<T> = ArrayList<T>()
    private let maxSize: Int32
    private let factory: () -> T
    private let reset: (T) -> Unit

    /**
     * 创建对象池
     *
     * @param maxSize 最大池大小
     * @param factory 对象创建工厂函数
     * @param reset 对象重置函数
     */
    public init(maxSize: Int32, factory: () -> T, reset: (T) -> Unit) {
        this.maxSize = maxSize
        this.factory = factory
        this.reset = reset
    }

    /**
     * 获取对象（从池中取出或创建新对象）
     */
    public func acquire(): T {
        if (pool.size() > 0) {
            return pool.removeAt(pool.size() - 1)
        }
        return factory()
    }

    /**
     * 归还对象到池中
     */
    public func release(obj: T): Unit {
        if (pool.size() < maxSize) {
            reset(obj)
            pool.add(obj)
        }
    }

    /**
     * 清空对象池
     */
    public func clear(): Unit {
        pool.clear()
    }

    /**
     * 获取池大小
     */
    public func size(): Int32 {
        return pool.size()
    }
}

/**
 * 常用对象池实例
 */
public class ObjectPools {
    // HashMap对象池（用于HTTP headers等）
    private static let hashMapPool = ObjectPool<HashMap<String, String>>(
        maxSize: 20,
        factory: { || => HashMap<String, String>() },
        reset: { (map: HashMap<String, String>) => Unit =>
            map.clear()
        }
    )

    // StringBuilder对象池（用于字符串拼接）
    private static let stringBuilderPool = ObjectPool<StringBuilder>(
        maxSize: 10,
        factory: { || => StringBuilder() },
        reset: { (sb: StringBuilder) => Unit =>
            // StringBuilder的清理实现
        }
    )

    /**
     * 获取HashMap对象
     */
    public static func borrowHashMap(): HashMap<String, String> {
        return hashMapPool.acquire()
    }

    /**
     * 归还HashMap对象
     */
    public static func returnHashMap(map: HashMap<String, String>): Unit {
        hashMapPool.release(map)
    }

    /**
     * 获取StringBuilder对象
     */
    public static func borrowStringBuilder(): StringBuilder {
        return stringBuilderPool.acquire()
    }

    /**
     * 归还StringBuilder对象
     */
    public static func returnStringBuilder(sb: StringBuilder): Unit {
        stringBuilderPool.release(sb)
    }

    /**
     * 清理所有对象池
     */
    public static func cleanup(): Unit {
        hashMapPool.clear()
        stringBuilderPool.clear()
    }
}
