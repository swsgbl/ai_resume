package test.integration.api

import std.unittest.*
import std.unittest.mock.*
import entry.src.services.*
import entry.src.models.*
import test.integration.data.TestDataFactory
import test.integration.mock.*

/// 模板服务集成测试
/// 测试 TemplateService 与 Mock API 服务器的集成
@TestCase
public class TemplateServiceIntegrationTest {
    private let apiServer: TestApiServer
    private let templateService: TemplateService
    private let mockHttpClient: MockHttpClientForTemplate
    private let mockTokenStorage: MockTokenStorageForTemplate

    public init() {
        // 初始化 Mock API 服务器
        this.apiServer = TestApiServer()

        // 初始化 Mock Token Storage
        this.mockTokenStorage = MockTokenStorageForTemplate()
        this.mockTokenStorage.setToken(TestDataFactory.createValidAuthToken())

        // 初始化 Mock HTTP Client
        this.mockHttpClient = MockHttpClientForTemplate(this.apiServer)

        // 创建 TemplateService 实例
        this.templateService = TemplateService(
            httpClient: this.mockHttpClient,
            tokenStorage: this.mockTokenStorage
        )
    }

    // ============================================
    // 获取模板列表测试
    // ============================================

    @Test
    public func testGetTemplateListSuccess(): Unit {
        // Arrange
        let expectedTemplates = TestDataFactory.createTemplateList()

        this.apiServer.mockEndpoint(
            MockEndpoint("/api/templates", "GET")
                .respondWith(MockResponse.success(JsonObject.from([
                    "templates": JsonArray.from([
                        JsonObject.from([
                            "id": expectedTemplates[0].id,
                            "name": expectedTemplates[0].name,
                            "category": expectedTemplates[0].category,
                            "isPremium": expectedTemplates[0].isPremium
                        ]),
                        JsonObject.from([
                            "id": expectedTemplates[1].id,
                            "name": expectedTemplates[1].name,
                            "category": expectedTemplates[1].category,
                            "isPremium": expectedTemplates[1].isPremium
                        ]),
                        JsonObject.from([
                            "id": expectedTemplates[2].id,
                            "name": expectedTemplates[2].name,
                            "category": expectedTemplates[2].category,
                            "isPremium": expectedTemplates[2].isPremium
                        ])
                    ])
                ])))
        )

        // Act
        let result = this.templateService.getTemplateList()

        // Assert
        Assert.assertTrue(result.isSuccess(), "Should get template list successfully")
        let templates = result.getData()
        Assert.assertEquals(expectedTemplates.size, templates.size)
        Assert.assertEquals(expectedTemplates[0].id, templates[0].id)
        Assert.assertEquals(expectedTemplates[1].name, templates[1].name)

        // 验证 API 请求
        Assert.assertTrue(
            this.apiServer.verifyRequest("/api/templates", "GET"),
            "Should call templates list endpoint"
        )
    }

    @Test
    public func testGetEmptyTemplateList(): Unit {
        // Arrange
        this.apiServer.mockEndpoint(
            MockEndpoint("/api/templates", "GET")
                .respondWith(MockResponse.success(JsonObject.from([
                    "templates": JsonArray.from([])
                ])))
        )

        // Act
        let result = this.templateService.getTemplateList()

        // Assert
        Assert.assertTrue(result.isSuccess())
        let templates = result.getData()
        Assert.assertEquals(0, templates.size)
    }

    @Test
    public func testGetTemplateListWithoutAuth(): Unit {
        // Arrange
        this.mockTokenStorage.setToken(null)

        // Act
        let result = this.templateService.getTemplateList()

        // Assert
        Assert.assertTrue(result.isFailure(), "Should fail without authentication")
    }

    // ============================================
    // 按分类获取模板测试
    // ============================================

    @Test
    public func testGetTemplatesByCategory(): Unit {
        // Arrange
        let category = "professional"

        this.apiServer.mockEndpoint(
            MockEndpoint("/api/templates?category=${category}", "GET")
                .respondWith(MockResponse.success(JsonObject.from([
                    "templates": JsonArray.from([
                        JsonObject.from([
                            "id": "template-modern-001",
                            "name": "Modern Professional",
                            "category": category,
                            "isPremium": false
                        ]),
                        JsonObject.from([
                            "id": "template-classic-001",
                            "name": "Classic Elegant",
                            "category": category,
                            "isPremium": false
                        ])
                    ])
                ])))
        )

        // Act
        let result = this.templateService.getTemplatesByCategory(category)

        // Assert
        Assert.assertTrue(result.isSuccess(), "Should get templates by category")
        let templates = result.getData()
        Assert.assertTrue(templates.size > 0)
        for (template in templates) {
            Assert.assertEquals(category, template.category)
        }
    }

    @Test
    public func testGetTemplatesByCreativeCategory(): Unit {
        // Arrange
        let category = "creative"

        this.apiServer.mockEndpoint(
            MockEndpoint("/api/templates?category=${category}", "GET")
                .respondWith(MockResponse.success(JsonObject.from([
                    "templates": JsonArray.from([
                        JsonObject.from([
                            "id": "template-creative-001",
                            "name": "Creative Designer",
                            "category": category,
                            "isPremium": true
                        ])
                    ])
                ])))
        )

        // Act
        let result = this.templateService.getTemplatesByCategory(category)

        // Assert
        Assert.assertTrue(result.isSuccess())
        let templates = result.getData()
        Assert.assertEquals(1, templates.size)
        Assert.assertEquals(category, templates[0].category)
    }

    @Test
    public func testGetTemplatesByInvalidCategory(): Unit {
        // Arrange
        let invalidCategory = "invalid-category"

        this.apiServer.mockEndpoint(
            MockEndpoint("/api/templates?category=${invalidCategory}", "GET")
                .respondWith(MockResponse.success(JsonObject.from([
                    "templates": JsonArray.from([])
                ])))
        )

        // Act
        let result = this.templateService.getTemplatesByCategory(invalidCategory)

        // Assert
        Assert.assertTrue(result.isSuccess())
        let templates = result.getData()
        Assert.assertEquals(0, templates.size)
    }

    // ============================================
    // 获取单个模板测试
    // ============================================

    @Test
    public func testGetTemplateByIdSuccess(): Unit {
        // Arrange
        let expectedTemplate = TestDataFactory.createModernTemplate()
        let templateId = expectedTemplate.id

        this.apiServer.mockEndpoint(
            MockEndpoint("/api/templates/${templateId}", "GET")
                .respondWith(MockResponse.success(JsonObject.from([
                    "id": expectedTemplate.id,
                    "name": expectedTemplate.name,
                    "category": expectedTemplate.category,
                    "description": expectedTemplate.description,
                    "thumbnail": expectedTemplate.thumbnail,
                    "preview": expectedTemplate.preview,
                    "isPremium": expectedTemplate.isPremium,
                    "features": JsonArray.from(expectedTemplate.features)
                ])))
        )

        // Act
        let result = this.templateService.getTemplateById(templateId)

        // Assert
        Assert.assertTrue(result.isSuccess(), "Should get template by id")
        let template = result.getData()
        Assert.assertEquals(templateId, template.id)
        Assert.assertEquals(expectedTemplate.name, template.name)
        Assert.assertEquals(expectedTemplate.category, template.category)
    }

    @Test
    public func testGetTemplateByIdNotFound(): Unit {
        // Arrange
        let nonExistentId = "template-999"
        this.apiServer.mockEndpoint(
            MockEndpoint("/api/templates/${nonExistentId}", "GET")
                .respondWith(MockResponse.error(404, "Template not found"))
        )

        // Act
        let result = this.templateService.getTemplateById(nonExistentId)

        // Assert
        Assert.assertTrue(result.isFailure(), "Should fail with 404")
        let error = result.getError()
        Assert.assertEquals(404, error.getCode())
    }

    // ============================================
    // 筛选免费模板测试
    // ============================================

    @Test
    public func testGetFreeTemplates(): Unit {
        // Arrange
        let allTemplates = TestDataFactory.createTemplateList()

        this.apiServer.mockEndpoint(
            MockEndpoint("/api/templates?premium=false", "GET")
                .respondWith(MockResponse.success(JsonObject.from([
                    "templates": JsonArray.from([
                        JsonObject.from([
                            "id": allTemplates[0].id,
                            "name": allTemplates[0].name,
                            "isPremium": false
                        ]),
                        JsonObject.from([
                            "id": allTemplates[1].id,
                            "name": allTemplates[1].name,
                            "isPremium": false
                        ])
                    ])
                ])))
        )

        // Act
        let result = this.templateService.getFreeTemplates()

        // Assert
        Assert.assertTrue(result.isSuccess(), "Should get free templates")
        let templates = result.getData()
        for (template in templates) {
            Assert.assertFalse(template.isPremium, "All templates should be free")
        }
    }

    @Test
    public func testGetPremiumTemplates(): Unit {
        // Arrange
        this.apiServer.mockEndpoint(
            MockEndpoint("/api/templates?premium=true", "GET")
                .respondWith(MockResponse.success(JsonObject.from([
                    "templates": JsonArray.from([
                        JsonObject.from([
                            "id": "template-creative-001",
                            "name": "Creative Designer",
                            "isPremium": true
                        ])
                    ])
                ])))
        )

        // Act
        let result = this.templateService.getPremiumTemplates()

        // Assert
        Assert.assertTrue(result.isSuccess(), "Should get premium templates")
        let templates = result.getData()
        for (template in templates) {
            Assert.assertTrue(template.isPremium, "All templates should be premium")
        }
    }

    // ============================================
    // 模板预览测试
    // ============================================

    @Test
    public func testGetTemplatePreview(): Unit {
        // Arrange
        let templateId = "template-modern-001"
        let expectedPreviewUrl = "templates/modern_preview.png"

        this.apiServer.mockEndpoint(
            MockEndpoint("/api/templates/${templateId}/preview", "GET")
                .respondWith(MockResponse.success(JsonObject.from([
                    "previewUrl": expectedPreviewUrl
                ])))
        )

        // Act
        let result = this.templateService.getTemplatePreview(templateId)

        // Assert
        Assert.assertTrue(result.isSuccess(), "Should get template preview")
        let previewUrl = result.getData()
        Assert.assertEquals(expectedPreviewUrl, previewUrl)
    }

    @Test
    public func testGetTemplatePreviewForNonExistentTemplate(): Unit {
        // Arrange
        let nonExistentId = "template-999"
        this.apiServer.mockEndpoint(
            MockEndpoint("/api/templates/${nonExistentId}/preview", "GET")
                .respondWith(MockResponse.error(404, "Template not found"))
        )

        // Act
        let result = this.templateService.getTemplatePreview(nonExistentId)

        // Assert
        Assert.assertTrue(result.isFailure(), "Should fail with 404")
    }

    // ============================================
    // 应用模板测试
    // ============================================

    @Test
    public func testApplyTemplateSuccess(): Unit {
        // Arrange
        let resumeId = "resume-001"
        let templateId = "template-modern-001"

        this.apiServer.mockEndpoint(
            MockEndpoint("/api/resumes/${resumeId}/apply-template", "POST")
                .respondWith(MockResponse.success(JsonObject.from([
                    "success": true,
                    "resumeId": resumeId,
                    "templateId": templateId,
                    "previewUrl": "previews/resume-001-modern.png"
                ])))
        )

        // Act
        let result = this.templateService.applyTemplate(resumeId, templateId)

        // Assert
        Assert.assertTrue(result.isSuccess(), "Should apply template successfully")
        let previewUrl = result.getData()
        Assert.assertTrue(previewUrl.contains(resumeId))

        // 验证 API 请求
        Assert.assertTrue(
            this.apiServer.verifyRequest("/api/resumes/${resumeId}/apply-template", "POST"),
            "Should call apply template endpoint"
        )
    }

    @Test
    public func testApplyPremiumTemplateWithoutSubscription(): Unit {
        // Arrange
        let resumeId = "resume-001"
        let premiumTemplateId = "template-creative-001"

        this.apiServer.mockEndpoint(
            MockEndpoint("/api/resumes/${resumeId}/apply-template", "POST")
                .respondWith(MockResponse.error(403, "Premium subscription required"))
        )

        // Act
        let result = this.templateService.applyTemplate(resumeId, premiumTemplateId)

        // Assert
        Assert.assertTrue(result.isFailure(), "Should fail without premium subscription")
        let error = result.getError()
        Assert.assertEquals(403, error.getCode())
    }

    @Test
    public func testApplyTemplateToNonExistentResume(): Unit {
        // Arrange
        let nonExistentResumeId = "resume-999"
        let templateId = "template-modern-001"

        this.apiServer.mockEndpoint(
            MockEndpoint("/api/resumes/${nonExistentResumeId}/apply-template", "POST")
                .respondWith(MockResponse.error(404, "Resume not found"))
        )

        // Act
        let result = this.templateService.applyTemplate(nonExistentResumeId, templateId)

        // Assert
        Assert.assertTrue(result.isFailure(), "Should fail with 404")
    }

    // ============================================
    // 模板搜索测试
    // ============================================

    @Test
    public func testSearchTemplates(): Unit {
        // Arrange
        let searchQuery = "modern"

        this.apiServer.mockEndpoint(
            MockEndpoint("/api/templates/search?q=${searchQuery}", "GET")
                .respondWith(MockResponse.success(JsonObject.from([
                    "templates": JsonArray.from([
                        JsonObject.from([
                            "id": "template-modern-001",
                            "name": "Modern Professional",
                            "category": "professional",
                            "isPremium": false
                        ])
                    ])
                ])))
        )

        // Act
        let result = this.templateService.searchTemplates(searchQuery)

        // Assert
        Assert.assertTrue(result.isSuccess(), "Should search templates")
        let templates = result.getData()
        Assert.assertTrue(templates.size > 0)
        Assert.assertTrue(templates[0].name.toLowerCase().contains(searchQuery))
    }

    @Test
    public func testSearchTemplatesWithNoResults(): Unit {
        // Arrange
        let searchQuery = "nonexistent"

        this.apiServer.mockEndpoint(
            MockEndpoint("/api/templates/search?q=${searchQuery}", "GET")
                .respondWith(MockResponse.success(JsonObject.from([
                    "templates": JsonArray.from([])
                ])))
        )

        // Act
        let result = this.templateService.searchTemplates(searchQuery)

        // Assert
        Assert.assertTrue(result.isSuccess())
        let templates = result.getData()
        Assert.assertEquals(0, templates.size)
    }

    // ============================================
    // 错误处理测试
    // ============================================

    @Test
    public func testHandleNetworkError(): Unit {
        // Arrange
        this.apiServer.setEnabled(false)

        // Act
        let result = this.templateService.getTemplateList()

        // Assert
        Assert.assertTrue(result.isFailure(), "Should handle network error")
    }

    @Test
    public func testHandleServerError(): Unit {
        // Arrange
        this.apiServer.mockEndpoint(
            MockEndpoint("/api/templates", "GET")
                .respondWith(MockResponse.error(500, "Internal Server Error"))
        )

        // Act
        let result = this.templateService.getTemplateList()

        // Assert
        Assert.assertTrue(result.isFailure(), "Should handle server error")
        let error = result.getError()
        Assert.assertEquals(500, error.getCode())
    }

    // ============================================
    // 模板服务集成场景测试
    // ============================================

    @Test
    public func testCompleteTemplateSelectionFlow(): Unit {
        // 测试完整的模板选择流程

        // 1. 获取模板列表
        this.apiServer.mockEndpoint(
            MockEndpoint("/api/templates", "GET")
                .respondWith(MockResponse.success(JsonObject.from([
                    "templates": JsonArray.from([
                        JsonObject.from([
                            "id": "template-modern-001",
                            "name": "Modern Professional",
                            "category": "professional",
                            "isPremium": false
                        ])
                    ])
                ])))
        )

        let listResult = this.templateService.getTemplateList()
        Assert.assertTrue(listResult.isSuccess(), "Should get template list")
        let templates = listResult.getData()
        Assert.assertTrue(templates.size > 0)

        // 2. 按分类筛选
        let category = "professional"
        this.apiServer.mockEndpoint(
            MockEndpoint("/api/templates?category=${category}", "GET")
                .respondWith(MockResponse.success(JsonObject.from([
                    "templates": JsonArray.from([
                        JsonObject.from([
                            "id": "template-modern-001",
                            "name": "Modern Professional",
                            "category": category,
                            "isPremium": false
                        ])
                    ])
                ])))
        )

        let categoryResult = this.templateService.getTemplatesByCategory(category)
        Assert.assertTrue(categoryResult.isSuccess())

        // 3. 获取模板详情
        let templateId = templates[0].id
        this.apiServer.mockEndpoint(
            MockEndpoint("/api/templates/${templateId}", "GET")
                .respondWith(MockResponse.success(JsonObject.from([
                    "id": templateId,
                    "name": "Modern Professional",
                    "category": category,
                    "description": "Clean and modern design",
                    "isPremium": false
                ])))
        )

        let detailResult = this.templateService.getTemplateById(templateId)
        Assert.assertTrue(detailResult.isSuccess())

        // 4. 应用模板
        let resumeId = "resume-001"
        this.apiServer.mockEndpoint(
            MockEndpoint("/api/resumes/${resumeId}/apply-template", "POST")
                .respondWith(MockResponse.success(JsonObject.from([
                    "success": true,
                    "previewUrl": "previews/resume-001.png"
                ])))
        )

        let applyResult = this.templateService.applyTemplate(resumeId, templateId)
        Assert.assertTrue(applyResult.isSuccess())

        // 验证完整的请求序列
        Assert.assertTrue(this.apiServer.verifyRequest("/api/templates", "GET"))
        Assert.assertTrue(this.apiServer.verifyRequest("/api/templates?category=${category}", "GET"))
        Assert.assertTrue(this.apiServer.verifyRequest("/api/templates/${templateId}", "GET"))
        Assert.assertTrue(this.apiServer.verifyRequest("/api/resumes/${resumeId}/apply-template", "POST"))
    }
}

// ============================================
// Mock 类定义
// ============================================

/// Mock HTTP Client for Template Service
internal class MockHttpClientForTemplate {
    private let apiServer: TestApiServer

    public init(apiServer: TestApiServer) {
        this.apiServer = apiServer
    }

    public func get(url: String): MockResponse {
        return this.apiServer.getResponse("GET", url)
    }

    public func post(url: String, body: String): MockResponse {
        return this.apiServer.getResponse("POST", url, body)
    }
}

/// Mock Token Storage for Template Service
internal class MockTokenStorageForTemplate {
    private var token: AuthToken? = null

    public func getToken(): AuthToken? {
        return this.token
    }

    public func setToken(token: AuthToken?): Unit {
        this.token = token
    }

    public func clearToken(): Unit {
        this.token = null
    }
}
