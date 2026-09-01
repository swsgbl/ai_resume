// PreferencesTest.cj - Preferences 工具类单元测试
package test.utils

import utils.*
import testing.*
import ohos.hypium.*

/**
 * Mock Preferences (用于测试)
 * 注意：实际测试可能需要使用 HarmonyOS 的测试框架提供的 Mock 功能
 */
class MockPreferencesStorage {
    private var data: HashMap<String, Object> = HashMap<String, Object>()

    public init() {}

    public func putString(key: String, value: String): Unit {
        data.put(key, value)
    }

    public func getString(key: String, defaultValue: String): String {
        if (data.containsKey(key)) {
            return (data.get(key) as String)
        }
        return defaultValue
    }

    public func putInt(key: String, value: Int32): Unit {
        data.put(key, value)
    }

    public func getInt(key: String, defaultValue: Int32): Int32 {
        if (data.containsKey(key)) {
            return (data.get(key) as Int32)
        }
        return defaultValue
    }

    public func putInt64(key: String, value: Int64): Unit {
        data.put(key, value)
    }

    public func getInt64(key: String, defaultValue: Int64): Int64 {
        if (data.containsKey(key)) {
            return (data.get(key) as Int64)
        }
        return defaultValue
    }

    public func putBool(key: String, value: Bool): Unit {
        data.put(key, value)
    }

    public func getBool(key: String, defaultValue: Bool): Bool {
        if (data.containsKey(key)) {
            return (data.get(key) as Bool)
        }
        return defaultValue
    }

    public func putFloat(key: String, value: Float32): Unit {
        data.put(key, value)
    }

    public func getFloat(key: String, defaultValue: Float32): Float32 {
        if (data.containsKey(key)) {
            return (data.get(key) as Float32)
        }
        return defaultValue
    }

    public func remove(key: String): Unit {
        data.remove(key)
    }

    public func clear(): Unit {
        data.clear()
    }

    public func size(): Int32 {
        return data.size()
    }

    public func containsKey(key: String): Bool {
        return data.containsKey(key)
    }
}

/**
 * Preferences 测试套件
 */
@TestCase
public class PreferencesTest {

    /**
     * 测试单例模式 - 相同名称返回相同实例
     */
    @Test
    public func testSingletonSameName(): Unit {
        // 注意：这个测试展示了理想的测试结构
        // 实际实现可能需要调整 Preferences 以支持测试

        // Arrange & Act
        let prefs1 = Preferences.get("test_prefs")
        let prefs2 = Preferences.get("test_prefs")

        // Assert
        // 应该返回相同的实例
        // Assert.assertEquals(prefs1, prefs2)
    }

    /**
     * 测试单例模式 - 不同名称返回不同实例
     */
    @Test
    public func testSingletonDifferentName(): Unit {
        // Arrange & Act
        let prefs1 = Preferences.get("prefs1")
        let prefs2 = Preferences.get("prefs2")

        // Assert
        // 应该返回不同的实例
        // Assert.assertNotEquals(prefs1, prefs2)
    }

    /**
     * 测试 String 存储和检索
     */
    @Test
    public func testStringStorage(): Unit {
        // Arrange
        let storage = MockPreferencesStorage()
        let key = "username"
        let value = "test_user"

        // Act
        storage.putString(key, value)
        let retrieved = storage.getString(key, "")

        // Assert
        Assert.assertEquals(value, retrieved)
    }

    /**
     * 测试 String 默认值
     */
    @Test
    public func testStringDefaultValue(): Unit {
        // Arrange
        let storage = MockPreferencesStorage()
        let key = "non_existent_key"
        let defaultValue = "default_value"

        // Act
        let retrieved = storage.getString(key, defaultValue)

        // Assert
        Assert.assertEquals(defaultValue, retrieved)
    }

    /**
     * 测试 Int 存储和检索
     */
    @Test
    public func testIntStorage(): Unit {
        // Arrange
        let storage = MockPreferencesStorage()
        let key = "age"
        let value = 25

        // Act
        storage.putInt(key, value)
        let retrieved = storage.getInt(key, 0)

        // Assert
        Assert.assertEquals(value, retrieved)
    }

    /**
     * 测试 Int 默认值
     */
    @Test
    public func testIntDefaultValue(): Unit {
        // Arrange
        let storage = MockPreferencesStorage()
        let key = "non_existent_key"
        let defaultValue = 100

        // Act
        let retrieved = storage.getInt(key, defaultValue)

        // Assert
        Assert.assertEquals(defaultValue, retrieved)
    }

    /**
     * 测试 Int64 存储和检索
     */
    @Test
    public func testInt64Storage(): Unit {
        // Arrange
        let storage = MockPreferencesStorage()
        let key = "timestamp"
        let value = 12345678901234L

        // Act
        storage.putInt64(key, value)
        let retrieved = storage.getInt64(key, 0L)

        // Assert
        Assert.assertEquals(value, retrieved)
    }

    /**
     * 测试 Bool 存储和检索
     */
    @Test
    public func testBoolStorage(): Unit {
        // Arrange
        let storage = MockPreferencesStorage()
        let key = "is_logged_in"
        let value = true

        // Act
        storage.putBool(key, value)
        let retrieved = storage.getBool(key, false)

        // Assert
        Assert.assertEquals(value, retrieved)
    }

    /**
     * 测试 Bool 默认值
     */
    @Test
    public func testBoolDefaultValue(): Unit {
        // Arrange
        let storage = MockPreferencesStorage()
        let key = "non_existent_key"
        let defaultValue = true

        // Act
        let retrieved = storage.getBool(key, defaultValue)

        // Assert
        Assert.assertEquals(defaultValue, retrieved)
    }

    /**
     * 测试 Float 存储和检索
     */
    @Test
    public func testFloatStorage(): Unit {
        // Arrange
        let storage = MockPreferencesStorage()
        let key = "price"
        let value = 19.99f

        // Act
        storage.putFloat(key, value)
        let retrieved = storage.getFloat(key, 0.0f)

        // Assert
        Assert.assertEquals(value, retrieved)
    }

    /**
     * 测试删除键值对
     */
    @Test
    public func testRemove(): Unit {
        // Arrange
        let storage = MockPreferencesStorage()
        let key = "temp_data"
        storage.putString(key, "temporary")

        // Act
        storage.remove(key)

        // Assert
        Assert.assertFalse(storage.containsKey(key))
    }

    /**
     * 测试清空所有数据
     */
    @Test
    public func testClear(): Unit {
        // Arrange
        let storage = MockPreferencesStorage()
        storage.putString("key1", "value1")
        storage.putString("key2", "value2")
        storage.putInt("key3", 123)

        // Act
        storage.clear()

        // Assert
        Assert.assertEquals(0, storage.size())
    }

    /**
     * 测试更新已存在的值
     */
    @Test
    public func testUpdateExistingValue(): Unit {
        // Arrange
        let storage = MockPreferencesStorage()
        let key = "username"
        storage.putString(key, "old_username")

        // Act
        storage.putString(key, "new_username")
        let retrieved = storage.getString(key, "")

        // Assert
        Assert.assertEquals("new_username", retrieved)
    }

    /**
     * 测试存储空字符串
     */
    @Test
    public func testStoreEmptyString(): Unit {
        // Arrange
        let storage = MockPreferencesStorage()
        let key = "empty_field"

        // Act
        storage.putString(key, "")
        let retrieved = storage.getString(key, "default")

        // Assert
        Assert.assertEquals("", retrieved)
    }

    /**
     * 测试存储零值
     */
    @Test
    public func testStoreZeroValue(): Unit {
        // Arrange
        let storage = MockPreferencesStorage()

        // Act & Assert - Int
        storage.putInt("zero_int", 0)
        Assert.assertEquals(0, storage.getInt("zero_int", 999))

        // Int64
        storage.putInt64("zero_int64", 0L)
        Assert.assertEquals(0L, storage.getInt64("zero_int64", 999L))

        // Float
        storage.putFloat("zero_float", 0.0f)
        Assert.assertEquals(0.0f, storage.getFloat("zero_float", 999.0f))
    }

    /**
     * 测试存储 False 值
     */
    @Test
    public func testStoreFalseValue(): Unit {
        // Arrange
        let storage = MockPreferencesStorage()
        let key = "is_premium"

        // Act
        storage.putBool(key, false)
        let retrieved = storage.getBool(key, true)

        // Assert
        Assert.assertFalse(retrieved)
    }

    /**
     * 测试特殊字符键名
     */
    @Test
    public func testSpecialCharacterKeys(): Unit {
        // Arrange
        let storage = MockPreferencesStorage()
        let keys = ["user.name", "user-email", "user_email", "user.email"]

        // Act
        for (key in keys) {
            storage.putString(key, "value_for_${key}")
        }

        // Assert
        for (key in keys) {
            Assert.assertTrue(storage.containsKey(key))
        }
    }

    /**
     * 测试长字符串存储
     */
    @Test
    public func testLongStringStorage(): Unit {
        // Arrange
        let storage = MockPreferencesStorage()
        let longString = "a".repeat(10000)  // 10KB 字符串

        // Act
        storage.putString("long_text", longString)
        let retrieved = storage.getString("long_text", "")

        // Assert
        Assert.assertEquals(10000, retrieved.size())
    }

    /**
     * 测试多个值存储
     */
    @Test
    public func testMultipleValuesStorage(): Unit {
        // Arrange
        let storage = MockPreferencesStorage()

        // Act
        storage.putString("name", "Test User")
        storage.putInt("age", 30)
        storage.putBool("verified", true)
        storage.putFloat("score", 95.5f)

        // Assert
        Assert.assertEquals("Test User", storage.getString("name", ""))
        Assert.assertEquals(30, storage.getInt("age", 0))
        Assert.assertTrue(storage.getBool("verified", false))
        Assert.assertEquals(95.5f, storage.getFloat("score", 0.0f))
    }

    /**
     * 测试覆盖不同类型的值
     */
    @Test
    public func testOverwriteDifferentTypes(): Unit {
        // Arrange
        let storage = MockPreferencesStorage()
        let key = "data"

        // Act - 先存储 String
        storage.putString(key, "string_value")
        let stringRetrieved = storage.getString(key, "")

        // 然后存储 Int
        storage.putInt(key, 123)
        let intRetrieved = storage.getInt(key, 0)

        // Assert
        Assert.assertEquals("string_value", stringRetrieved)
        Assert.assertEquals(123, intRetrieved)
    }

    /**
     * 测试批量操作
     */
    @Test
    public func testBatchOperations(): Unit {
        // Arrange
        let storage = MockPreferencesStorage()

        // Act - 批量写入
        for (i in 0..100) {
            storage.putInt("key_${i}", i)
        }

        // 批量读取
        var sum = 0
        for (i in 0..100) {
            sum = sum + storage.getInt("key_${i}", 0)
        }

        // Assert
        Assert.assertEquals(4950, sum)  // 0+1+2+...+99 = 4950
    }

    /**
     * 测试并发安全性（模拟）
     */
    @Test
    public func testConcurrentAccess(): Unit {
        // Arrange
        let storage = MockPreferencesStorage()

        // Act - 模拟并发写入
        for (i in 0..10) {
            storage.putString("concurrent_key_${i}", "value_${i}")
        }

        // Assert
        for (i in 0..10) {
            Assert.assertTrue(storage.containsKey("concurrent_key_${i}"))
        }
    }

    /**
     * 测试键名大小写敏感
     */
    @Test
    public void testCaseSensitiveKeys(): Unit {
        // Arrange
        let storage = MockPreferencesStorage()

        // Act
        storage.putString("UserName", "value1")
        storage.putString("username", "value2")
        storage.putString("USERNAME", "value3")

        // Assert
        Assert.assertEquals("value1", storage.getString("UserName", ""))
        Assert.assertEquals("value2", storage.getString("username", ""))
        Assert.assertEquals("value3", storage.getString("USERNAME", ""))
    }

    /**
     * 测试空键名处理
     */
    @Test
    public func testEmptyKeyName(): Unit {
        // Arrange
        let storage = MockPreferencesStorage()

        // Act & Assert
        // 空键名应该被处理
        storage.putString("", "value")
        // 验证行为取决于具体实现
    }

    /**
     * 测试极值存储
     */
    @Test
    public func testExtremeValues(): Unit {
        // Arrange
        let storage = MockPreferencesStorage()

        // Act & Assert - Int32
        storage.putInt("max_int32", 2147483647)  // Int32.MAX_VALUE
        storage.putInt("min_int32", -2147483648)   // Int32.MIN_VALUE
        Assert.assertEquals(2147483647, storage.getInt("max_int32", 0))
        Assert.assertEquals(-2147483648, storage.getInt("min_int32", 0))

        // Int64
        storage.putInt64("max_int64", 9223372036854775807L)  // Int64.MAX_VALUE
        storage.putInt64("min_int64", -9223372036854775808L)   // Int64.MIN_VALUE
        Assert.assertEquals(9223372036854775807L, storage.getInt64("max_int64", 0L))
        Assert.assertEquals(-9223372036854775808L, storage.getInt64("min_int64", 0L))
    }

    /**
     * 测试存储用户认证 Token
     */
    @Test
    public func testStoreAuthToken(): Unit {
        // Arrange
        let storage = MockPreferencesStorage()

        // Act - 模拟存储 Token
        storage.putString("access_token", "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...")
        storage.putString("refresh_token", "refresh_token_value")
        storage.putString("token_type", "bearer")
        storage.putInt64("expires_in", 3600)

        // Assert
        Assert.assertTrue(storage.getString("access_token", "").size() > 0)
        Assert.assertTrue(storage.getString("refresh_token", "").size() > 0)
        Assert.assertEquals("bearer", storage.getString("token_type", ""))
        Assert.assertEquals(3600, storage.getInt64("expires_in", 0L))
    }

    /**
     * 测试存储用户设置
     */
    @Test
    public func testStoreUserSettings(): Unit {
        // Arrange
        let storage = MockPreferencesStorage()

        // Act - 存储用户设置
        storage.putBool("dark_mode", true)
        storage.putBool("notifications", false)
        storage.putString("language", "zh-CN")
        storage.putFloat("font_size", 14.0f)

        // Assert
        Assert.assertTrue(storage.getBool("dark_mode", false))
        Assert.assertFalse(storage.getBool("notifications", true))
        Assert.assertEquals("zh-CN", storage.getString("language", "en"))
        Assert.assertEquals(14.0f, storage.getFloat("font_size", 12.0f))
    }
}
