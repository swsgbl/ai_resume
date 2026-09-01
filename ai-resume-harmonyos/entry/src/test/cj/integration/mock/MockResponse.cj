package test.integration.mock

import std.json.*
import entry.src.models.*

/// Mock HTTP 响应
public class MockResponse {
    private var statusCode: Int = 200
    private var body: String = ""
    private var headers: HashMap<String, String> = HashMap()
    private var delayMs: Int = 0

    public init() {}

    /// 创建成功响应
    public static func success(data: JsonValue): MockResponse {
        let response = MockResponse()
        response.statusCode = 200
        response.body = """
        {
            "success": true,
            "data": ${data.toString()}
        }
        """
        return response
    }

    /// 创建成功响应（带对象）
    public static func successObj(obj: TokenType): MockResponse {
        // 需要根据实际类型实现序列化
        let response = MockResponse()
        response.statusCode = 200
        response.body = """{"success": true}"""
        return response
    }

    /// 创建错误响应
    public static func error(code: Int, message: String): MockResponse {
        let response = MockResponse()
        response.statusCode = code
        response.body = """
        {
            "success": false,
            "error": {
                "code": ${code},
                "message": "${message}"
            }
        }
        """
        return response
    }

    /// 创建网络错误响应
    public static func networkError(): MockResponse {
        let response = MockResponse()
        response.statusCode = 0
        response.body = """{"success": false, "error": "Network error"}"""
        return response
    }

    /// 创建超时响应
    public static func timeout(): MockResponse {
        let response = MockResponse()
        response.statusCode = 408
        response.delayMs = 6000  // 超过默认超时时间
        return response
    }

    /// 获取状态码
    public func getStatusCode(): Int {
        return this.statusCode
    }

    /// 获取响应体
    public func getBody(): String {
        return this.body
    }

    /// 获取响应头
    public func getHeaders(): HashMap<String, String> {
        return this.headers
    }

    /// 获取延迟时间
    public func getDelayMs(): Int {
        return this.delayMs
    }

    /// 添加响应头
    public func addHeader(key: String, value: MockResponse) {
        this.headers[key] = value.toString()
    }

    /// 设置延迟
    public func setDelayMs(delay: Int) {
        this.delayMs = delay
    }

    /// 是否成功
    public func isSuccess(): Bool {
        return this.statusCode >= 200 && this.statusCode < 300
    }

    /// 是否客户端错误
    public func isClientError(): Bool {
        return this.statusCode >= 400 && this.statusCode < 500
    }

    /// 是否服务器错误
    public func isServerError(): Bool {
        return this.statusCode >= 500
    }
}

/// HTTP 请求记录
public class HttpRequestRecord {
    public var method: String = ""
    public var url: String = ""
    public var headers: HashMap<String, String> = HashMap()
    public var body: String = ""
    public var timestamp: DateTime = DateTime.now()

    public init() {}

    public func toString(): String {
        return "[${this.method}] ${this.url} at ${this.timestamp.toString()}"
    }
}

/// Mock API 端点配置
public class MockEndpoint {
    public var path: String = ""
    public var method: String = "GET"
    public var response: MockResponse = MockResponse()
    public var requestValidator: (String) -> Bool = { _ => true }

    public init(path: String, method: String = "GET") {
        this.path = path
        this.method = method
    }

    /// 设置响应
    public func respondWith(response: MockResponse): MockEndpoint {
        this.response = response
        return this
    }

    /// 设置请求验证器
    public func validate(validator: (String) -> Bool): MockEndpoint {
        this.requestValidator = validator
        return this
    }

    /// 验证请求
    public func validateRequest(body: String): Bool {
        return this.requestValidator(body)
    }
}
