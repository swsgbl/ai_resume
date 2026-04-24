// HttpClient.cj - HTTP客户端封装（增强版，支持多种Content-Type）
package services

import std.net.*
import std.io.*
import std.collection.*
import ohos.hiviewdfx.*

public class HttpClient {
    private let baseUrl: String
    private var authToken: String = ""
    private let logger: HiLog

    public init(baseUrl: String) {
        this.baseUrl = baseUrl
        this.logger = HiLog()
    }

    public func setAuthToken(token: String): Unit {
        this.authToken = token
    }

    public func clearAuthToken(): Unit {
        this.authToken = ""
    }

    // GET请求
    public func get(endpoint: String): HttpResponse {
        return request("GET", endpoint, "", "application/json")
    }

    // POST请求（JSON）
    public func post(endpoint: String, body: String): HttpResponse {
        return request("POST", endpoint, body, "application/json")
    }

    // POST请求（自定义Content-Type）- 支持form-data等
    public func postWithContentType(endpoint: String, body: String, contentType: String): HttpResponse {
        return request("POST", endpoint, body, contentType)
    }

    // PUT请求
    public func put(endpoint: String, body: String): HttpResponse {
        return request("PUT", endpoint, body, "application/json")
    }

    // DELETE请求
    public func delete(endpoint: String): HttpResponse {
        return request("DELETE", endpoint, "", "application/json")
    }

    // 通用请求方法
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

            // 添加认证头
            if (authToken != "") {
                httpRequest.setHeader("Authorization", "Bearer ${authToken}")
            }

            // 设置请求体
            if (body != "") {
                httpRequest.setBody(body)
            }

            // 设置超时
            httpRequest.setConnectTimeout(ApiConfig.CONNECT_TIMEOUT)
            httpRequest.setReadTimeout(ApiConfig.READ_TIMEOUT)

            // 发送请求
            let rawResponse = httpRequest.execute()

            // 解析响应
            response.statusCode = rawResponse.getStatusCode()
            response.body = rawResponse.getBody()
            response.headers = rawResponse.getHeaders()

            logger.info("HttpClient", "${method} ${url} -> ${response.statusCode}")

        } catch (e: Exception) {
            response.statusCode = -1
            response.error = e.message
            logger.error("HttpClient", "Request failed: ${e.message}")
        }

        return response
    }
}

public class HttpResponse {
    public var statusCode: Int32 = 0
    public var body: String = ""
    public var error: String = ""
    public var headers: HashMap<String, String> = HashMap<String, String>()

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