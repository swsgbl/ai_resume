// HttpClientOptimized.cj - HTTP客户端优化版（性能优化 - Phase 7）
package services

import std.net.*
import std.io.*
import std.collection.*
import ohos.hiviewdfx.*
import utils.*

/**
 * HTTP客户端优化版
 *
 * 性能优化措施：
 * 1. 添加请求缓存机制
 * 2. 优化连接超时配置
 * 3. 添加请求去重
 * 4. 改进错误处理和重试机制
 */
public class HttpClientOptimized {
    private let baseUrl: String
    private var authToken: String = ""
    private let logger: HiLog
    private let cache: RequestCache
    private let pendingRequests: HashMap<String, Bool> = HashMap<String, Bool>()

    // 单例实例
    private static var instance: ?HttpClientOptimized = None

    public init(baseUrl: String) {
        this.baseUrl = baseUrl
        this.logger = HiLog()
        this.cache = RequestCache()
    }

    /**
     * 获取单例实例
     */
    public static func getInstance(baseUrl: String): HttpClientOptimized {
        if (instance is None) {
            instance = Some(HttpClientOptimized(baseUrl))
        }
        return instance.get()
    }

    public func setAuthToken(token: String): Unit {
        this.authToken = token
    }

    public func clearAuthToken(): Unit {
        this.authToken = ""
    }

    /**
     * 清除请求缓存
     */
    public func clearCache(): Unit {
        cache.clear()
    }

    /**
     * GET请求（支持缓存）
     */
    public func get(endpoint: String, useCache: Bool = true): HttpResponse {
        let url = baseUrl + endpoint

        // 检查缓存
        if (useCache) {
            let cachedData = cache.get(url)
            if (cachedData is Some<String>) {
                logger.info("HttpClient", "Cache HIT: ${url}")
                let response = HttpResponse()
                response.statusCode = 200
                response.body = cachedData.get()
                response.fromCache = true
                return response
            }
        }

        // 检查是否有相同的请求正在进行
        if (pendingRequests.containsKey(url)) {
            logger.info("HttpClient", "Request deduplication: ${url}")
            // 等待现有请求完成（简化实现）
            return HttpResponse()
        }

        pendingRequests.put(url, true)
        let response = request("GET", endpoint, "", "application/json")
        pendingRequests.remove(url)

        // 缓存成功的GET请求
        if (response.isSuccess() && useCache) {
            cache.put(url, response.body)
        }

        return response
    }

    /**
     * POST请求（带重试机制）
     */
    public func post(endpoint: String, body: String, maxRetries: Int32 = 0): HttpResponse {
        var response = request("POST", endpoint, body, "application/json")
        var retryCount: Int32 = 0

        // 如果是网络错误，尝试重试
        while (response.statusCode == -1 && retryCount < maxRetries) {
            logger.warn("HttpClient", "Retrying POST request (${retryCount + 1}/${maxRetries})")
            retryCount++
            response = request("POST", endpoint, body, "application/json")
        }

        return response
    }

    /**
     * POST请求（自定义Content-Type）
     */
    public func postWithContentType(endpoint: String, body: String, contentType: String): HttpResponse {
        return request("POST", endpoint, body, contentType)
    }

    /**
     * PUT请求
     */
    public func put(endpoint: String, body: String): HttpResponse {
        return request("PUT", endpoint, body, "application/json")
    }

    /**
     * DELETE请求
     */
    public func delete(endpoint: String): HttpResponse {
        return request("DELETE", endpoint, "", "application/json")
    }

    /**
     * 通用请求方法（优化版）
     */
    private func request(method: String, endpoint: String, body: String, contentType: String): HttpResponse {
        let url = baseUrl + endpoint
        var response = HttpResponse()

        try {
            // 构建HTTP请求
            let httpRequest = HttpRequest()
            httpRequest.setMethod(method)
            httpRequest.setUrl(url)
            httpRequest.setHeader("Content-Type", contentType)
            httpRequest.setHeader("Accept", "application/json")
            httpRequest.setHeader("User-Agent", "AIResume-HarmonyOS/1.0")

            // 添加认证头
            if (authToken != "") {
                httpRequest.setHeader("Authorization", "Bearer ${authToken}")
            }

            // 设置请求体
            if (body != "") {
                httpRequest.setBody(body)
            }

            // 优化超时配置（减少等待时间）
            httpRequest.setConnectTimeout(ApiConfig.CONNECT_TIMEOUT)
            httpRequest.setReadTimeout(ApiConfig.READ_TIMEOUT)

            let startTime = System.currentTimeMillis()

            // 发送请求
            let rawResponse = httpRequest.execute()

            let elapsed = System.currentTimeMillis() - startTime
            logger.info("HttpClient", "${method} ${url} -> ${rawResponse.getStatusCode()} (${elapsed}ms)")

            // 解析响应
            response.statusCode = rawResponse.getStatusCode()
            response.body = rawResponse.getBody()
            response.headers = rawResponse.getHeaders()

        } catch (e: Exception) {
            response.statusCode = -1
            response.error = e.message
            logger.error("HttpClient", "Request failed: ${e.message}")
        }

        return response
    }

    /**
     * 获取缓存统计信息
     */
    public func getCacheStats(): ?CacheStats {
        return Some(cache.getStats())
    }
}

public class HttpResponse {
    public var statusCode: Int32 = 0
    public var body: String = ""
    public var error: String = ""
    public var headers: HashMap<String, String> = HashMap<String, String>()
    public var fromCache: Bool = false  // 新增：标识是否来自缓存

    public init() {}

    public func isSuccess(): Bool {
        return statusCode >= 200 && statusCode < 300
    }

    public func isUnauthorized(): Bool {
        return statusCode == 401
    }

    public func isForbidden(): Bool {
        return statusCode == 403
    }

    public func isNotFound(): Bool {
        return statusCode == 404
    }

    public func isServerError(): Bool {
        return statusCode >= 500
    }
}
