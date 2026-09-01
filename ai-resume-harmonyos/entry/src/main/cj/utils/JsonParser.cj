// JsonParser.cj - JSON解析工具
package utils

import std.json.*
import std.collection.*

public class JsonParser {
    // 解析JSON对象
    public static func parse(json: String): JsonObject {
        return JsonObject.parse(json)
    }

    // 解析JSON数组
    public static func parseArray(json: String): JsonArray {
        return JsonArray.parse(json)
    }

    // 安全获取字符串
    public static func getString(obj: JsonObject, key: String, defaultValue: String = ""): String {
        if (obj.containsKey(key)) {
            return obj.getString(key)
        }
        return defaultValue
    }

    // 安全获取整数
    public static func getInt(obj: JsonObject, key: String, defaultValue: Int32 = 0): Int32 {
        if (obj.containsKey(key)) {
            return obj.getInt(key)
        }
        return defaultValue
    }

    // 安全获取长整数
    public static func getInt64(obj: JsonObject, key: String, defaultValue: Int64 = 0): Int64 {
        if (obj.containsKey(key)) {
            return obj.getInt64(key)
        }
        return defaultValue
    }

    // 安全获取布尔值
    public static func getBool(obj: JsonObject, key: String, defaultValue: Bool = false): Bool {
        if (obj.containsKey(key)) {
            return obj.getBool(key)
        }
        return defaultValue
    }

    // 安全获取浮点数
    public static func getFloat32(obj: JsonObject, key: String, defaultValue: Float32 = 0.0f): Float32 {
        if (obj.containsKey(key)) {
            return obj.getFloat32(key)
        }
        return defaultValue
    }

    public static func getFloat64(obj: JsonObject, key: String, defaultValue: Float64 = 0.0): Float64 {
        if (obj.containsKey(key)) {
            return obj.getFloat64(key)
        }
        return defaultValue
    }
}

// StringBuilder工具类
public class StringBuilder {
    private var buffer: String = ""

    public init() {}

    public func append(s: String): StringBuilder {
        buffer = buffer + s
        return this
    }

    public func toString(): String {
        return buffer
    }
}
