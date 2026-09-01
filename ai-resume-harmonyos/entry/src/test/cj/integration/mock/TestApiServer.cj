package test.integration.mock

import std.json.*
import std.concurrent.*
import entry.src.services.*
import entry.src.models.*

/// 测试用 Mock API 服务器
/// 模拟真实的 HTTP API 响应，用于集成测试
public class TestApiServer {
    private var endpoints: HashMap<String, MockEndpoint> = HashMap()
    private var requestLog: ArrayList<HttpRequestRecord> = ArrayList()
    private var defaultResponse: MockResponse = MockResponse()
    private var enabled: Bool = true

    public init() {
        setupDefaultResponses()
    }

    // ============================================
    // 初始化和配置
    // ============================================

    /// 设置默认响应
    private func setupDefaultResponses() {
        // 认证端点
        setupAuthEndpoints()

        // 简历端点
        setupResumeEndpoints()

        // AI 服务端点
        setupAIEndpoints()

        // 模板端点
        setupTemplateEndpoints()
    }

    /// 设置认证相关端点
    private func setupAuthEndpoints() {
        // POST /api/auth/register
        this.mockEndpoint(
            MockEndpoint("/api/auth/register", "POST")
                .respondWith(MockResponse.success(JsonObject.from([
                    "user": JsonObject.from([
                        "id": "new-user-001",
                        "email": "newuser@example.com",
                        "name": "New User",
                        "verified": false
                    ]),
                    "token": JsonObject.from([
                        "accessToken": "new-access-token",
                        "refreshToken": "new-refresh-token",
                        "expiresIn": 3600
                    ])
                ])))
        )

        // POST /api/auth/login
        this.mockEndpoint(
            MockEndpoint("/api/auth/login", "POST")
                .respondWith(MockResponse.success(JsonObject.from([
                    "token": JsonObject.from([
                        "accessToken": "test-access-token",
                        "refreshToken": "test-refresh-token",
                        "expiresIn": 3600
                    ]),
                    "user": JsonObject.from([
                        "id": "test-user-001",
                        "email": "test@example.com",
                        "name": "Test User",
                        "verified": true
                    ])
                ])))
        )

        // POST /api/auth/refresh
        this.mockEndpoint(
            MockEndpoint("/api/auth/refresh", "POST")
                .respondWith(MockResponse.success(JsonObject.from([
                    "accessToken": "refreshed-access-token",
                    "expiresIn": 3600
                ])))
        )

        // POST /api/auth/logout
        this.mockEndpoint(
            MockEndpoint("/api/auth/logout", "POST")
                .respondWith(MockResponse.success(JsonObject.from([
                    "message": "Logged out successfully"
                ])))
        )
    }

    /// 设置简历相关端点
    private func setupResumeEndpoints() {
        // GET /api/resumes
        this.mockEndpoint(
            MockEndpoint("/api/resumes", "GET")
                .respondWith(MockResponse.success(JsonObject.from([
                    "resumes": JsonArray.from([
                        JsonObject.from([
                            "id": "resume-001",
                            "title": "Software Engineer Resume",
                            "updatedAt": "2024-03-30T10:00:00Z"
                        ]),
                        JsonObject.from([
                            "id": "resume-002",
                            "title": "Product Manager Resume",
                            "updatedAt": "2024-03-29T15:30:00Z"
                        ])
                    ])
                ])))
        )

        // GET /api/resumes/:id
        this.mockEndpoint(
            MockEndpoint("/api/resumes/:id", "GET")
                .respondWith(MockResponse.success(JsonObject.from([
                    "id": "resume-001",
                    "title": "Software Engineer Resume",
                    "personalInfo": JsonObject.from([
                        "name": "John Doe",
                        "email": "john@example.com"
                    ]),
                    "education": JsonArray.from([]),
                    "experience": JsonArray.from([]),
                    "skills": JsonArray.from([]),
                    "projects": JsonArray.from([])
                ])))
        )

        // POST /api/resumes
        this.mockEndpoint(
            MockEndpoint("/api/resumes", "POST")
                .respondWith(MockResponse.success(JsonObject.from([
                    "id": "new-resume-001",
                    "title": "New Resume",
                    "createdAt": "2024-03-30T10:00:00Z"
                ])))
        )

        // PUT /api/resumes/:id
        this.mockEndpoint(
            MockEndpoint("/api/resumes/:id", "PUT")
                .respondWith(MockResponse.success(JsonObject.from([
                    "id": "resume-001",
                    "title": "Updated Resume Title",
                    "updatedAt": "2024-03-30T11:00:00Z"
                ])))
        )

        // DELETE /api/resumes/:id
        this.mockEndpoint(
            MockEndpoint("/api/resumes/:id", "DELETE")
                .respondWith(MockResponse.success(JsonObject.from([
                    "message": "Resume deleted successfully"
                ])))
        )
    }

    /// 设置 AI 服务相关端点
    private func setupAIEndpoints() {
        // POST /api/ai/generate-summary
        this.mockEndpoint(
            MockEndpoint("/api/ai/generate-summary", "POST")
                .respondWith(MockResponse.success(JsonObject.from([
                    "summary": "Experienced software engineer with a strong background in mobile development and a passion for creating user-friendly applications."
                ])))
        )

        // POST /api/ai/optimize-experience
        this.mockEndpoint(
            MockEndpoint("/api/ai/optimize-experience", "POST")
                .respondWith(MockResponse.success(JsonObject.from([
                    "optimizedDescription": "Led the development of mobile applications, resulting in 100,000+ downloads and a 4.8-star rating. Mentored junior developers and implemented best practices that improved code quality by 40%."
                ])))
        )

        // POST /api/ai/generate-skills
        this.mockEndpoint(
            MockEndpoint("/api/ai/generate-skills", "POST")
                .respondWith(MockResponse.success(JsonObject.from([
                    "skills": JsonArray.from([
                        "Mobile Development",
                        "Team Leadership",
                        "Agile Methodology",
                        "Code Review",
                        "Performance Optimization"
                    ])
                ])))
        )
    }

    /// 设置模板相关端点
    private func setupTemplateEndpoints() {
        // GET /api/templates
        this.mockEndpoint(
            MockEndpoint("/api/templates", "GET")
                .respondWith(MockResponse.success(JsonObject.from([
                    "templates": JsonArray.from([
                        JsonObject.from([
                            "id": "template-modern-001",
                            "name": "Modern Professional",
                            "category": "professional",
                            "isPremium": false
                        ]),
                        JsonObject.from([
                            "id": "template-classic-001",
                            "name": "Classic Elegant",
                            "category": "professional",
                            "isPremium": false
                        ]),
                        JsonObject.from([
                            "id": "template-creative-001",
                            "name": "Creative Designer",
                            "category": "creative",
                            "isPremium": true
                        ])
                    ])
                ])))
        )

        // GET /api/templates/:id
        this.mockEndpoint(
            MockEndpoint("/api/templates/:id", "GET")
                .respondWith(MockResponse.success(JsonObject.from([
                    "id": "template-modern-001",
                    "name": "Modern Professional",
                    "category": "professional",
                    "description": "Clean and modern design",
                    "thumbnail": "templates/modern_thumbnail.png",
                    "isPremium": false
                ])))
        )
    }

    // ============================================
    // Mock 配置方法
    // ============================================

    /// Mock 一个端点
    public func mockEndpoint(endpoint: MockEndpoint): TestApiServer {
        let key = "${endpoint.method}:${endpoint.path}"
        this.endpoints[key] = endpoint
        return this
    }

    /// 设置默认响应
    public func setDefaultResponse(response: MockResponse): TestApiServer {
        this.defaultResponse = response
        return this
    }

    /// 启用/禁用服务器
    public func setEnabled(enabled: Bool): TestApiServer {
        this.enabled = enabled
        return this
    }

    /// 重置所有配置
    public func reset(): TestApiServer {
        this.endpoints.clear()
        this.requestLog.clear()
        setupDefaultResponses()
        return this
    }

    /// 清空请求日志
    public func clearRequestLog(): TestApiServer {
        this.requestLog.clear()
        return this
    }

    // ============================================
    // 请求验证方法
    // ============================================

    /// 验证特定路径的请求是否被调用
    public func verifyRequest(path: String, method: String): Bool {
        for (record in this.requestLog) {
            if (record.url.contains(path) && record.method == method) {
                return true
            }
        }
        return false
    }

    /// 获取特定路径的请求次数
    public func getRequestCount(path: String, method: String): Int {
        var count = 0
        for (record in this.requestLog) {
            if (record.url.contains(path) && record.method == method) {
                count++
            }
        }
        return count
    }

    /// 获取最后一次请求
    public func getLastRequest(): HttpRequestRecord? {
        if (this.requestLog.size > 0) {
            return this.requestLog[this.requestLog.size - 1]
        }
        return null
    }

    /// 获取所有请求记录
    public func getAllRequests(): ArrayList<HttpRequestRecord> {
        return this.requestLog
    }

    /// 打印请求日志（调试用）
    public func printRequestLog(): String {
        var output = "=== API Server Request Log ===\n"
        for (record in this.requestLog) {
            output += "${record.toString()}\n"
        }
        return output
    }

    // ============================================
    // 响应生成方法
    // ============================================

    /// 获取端点的 Mock 响应
    public func getResponse(method: String, path: String, body: String = ""): MockResponse {
        // 记录请求
        let record = HttpRequestRecord()
        record.method = method
        record.url = path
        record.body = body
        record.timestamp = DateTime.now()
        this.requestLog.append(record)

        // 查找匹配的端点
        let key = "${method}:${path}"
        if (this.endpoints.contains(key)) {
            let endpoint = this.endpoints[key]
            if (endpoint.validateRequest(body)) {
                return endpoint.response
            }
        }

        // 尝试匹配带参数的路径
        for ((_, endpoint) in this.endpoints) {
            if (this.matchPath(endpoint.path, path) && endpoint.method == method) {
                if (endpoint.validateRequest(body)) {
                    return endpoint.response
                }
            }
        }

        // 返回默认响应
        return this.defaultResponse
    }

    /// 路径匹配（支持 :id 参数）
    private func matchPath(pattern: String, path: String): Bool {
        if (pattern == path) {
            return true
        }

        let patternParts = pattern.split("/")
        let pathParts = path.split("/")

        if (patternParts.size != pathParts.size) {
            return false
        }

        for (i in 0..patternParts.size) {
            let patternPart = patternParts[i]
            if (!patternPart.startsWith(":") && patternPart != pathParts[i]) {
                return false
            }
        }

        return true
    }

    // ============================================
    // 错误场景模拟
    // ============================================

    /// 模拟网络错误
    public func simulateNetworkError(): MockResponse {
        return MockResponse.networkError()
    }

    /// 模拟超时
    public func simulateTimeout(): MockResponse {
        return MockResponse.timeout()
    }

    /// 模拟服务器错误
    public func simulateServerError(code: Int = 500, message: String = "Internal Server Error"): MockResponse {
        return MockResponse.error(code, message)
    }

    /// 模拟客户端错误
    public func simulateClientError(code: Int = 400, message: String = "Bad Request"): MockResponse {
        return MockResponse.error(code, message)
    }

    // ============================================
    // 预设场景
    // ============================================

    /// 设置登录成功场景
    public func scenarioLoginSuccess(): TestApiServer {
        this.mockEndpoint(
            MockEndpoint("/api/auth/login", "POST")
                .respondWith(MockResponse.success(JsonObject.from([
                    "token": JsonObject.from([
                        "accessToken": "success-token",
                        "refreshToken": "success-refresh",
                        "expiresIn": 3600
                    ]),
                    "user": JsonObject.from([
                        "id": "user-success",
                        "email": "success@test.com",
                        "name": "Success User",
                        "verified": true
                    ])
                ])))
        )
        return this
    }

    /// 设置登录失败场景
    public func scenarioLoginFailure(): TestApiServer {
        this.mockEndpoint(
            MockEndpoint("/api/auth/login", "POST")
                .respondWith(MockResponse.error(401, "Invalid credentials"))
        )
        return this
    }

    /// 设置网络错误场景
    public func scenarioNetworkError(): TestApiServer {
        this.setEnabled(false)
        return this
    }
}
