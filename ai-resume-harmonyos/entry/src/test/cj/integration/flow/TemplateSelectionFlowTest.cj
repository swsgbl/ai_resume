package test.integration.flow

import std.unittest.*
import std.unittest.mock.*
import entry.src.services.*
import entry.src.models.*
import entry.src.viewmodels.*
import test.integration.data.TestDataFactory
import test.integration.mock.*

/// 模板选择流程集成测试
/// 测试用户浏览、选择和应用模板的端到端流程
@TestCase
public class TemplateSelectionFlowTest {
    private let apiServer: TestApiServer
    private let templateService: TemplateService
    private let resumeService: ResumeService
    private let templateViewModel: TemplateViewModel
    private let mockTokenStorage: MockTokenStorageForTemplateFlow

    public init() {
        this.apiServer = TestApiServer()
        this.mockTokenStorage = MockTokenStorageForTemplateFlow()
        this.mockTokenStorage.setToken(TestDataFactory.createValidAuthToken())

        let mockHttpClient = MockHttpClientForTemplateFlow(this.apiServer)
        this.templateService = TemplateService(
            httpClient: mockHttpClient,
            tokenStorage: this.mockTokenStorage
        )
        this.resumeService = ResumeService(
            httpClient: mockHttpClient,
            tokenStorage: this.mockTokenStorage
        )

        this.templateViewModel = TemplateViewModel(
            templateService: this.templateService,
            resumeService: this.resumeService
        )
    }

    // ============================================
    // 完整模板选择流程测试
    // ============================================

    @Test
    public func testCompleteTemplateSelectionFlow(): Unit {
        // 测试完整流程：浏览模板列表 → 筛选分类 → 预览 → 应用

        // Arrange
        let resumeId = "template-flow-resume-001"
        let templates = TestDataFactory.createTemplateList()
        let selectedTemplate = templates[0]

        // Mock 获取模板列表
        this.apiServer.mockEndpoint(
            MockEndpoint("/api/templates", "GET")
                .respondWith(MockResponse.success(JsonObject.from([
                    "templates": JsonArray.from([
                        JsonObject.from([
                            "id": templates[0].id,
                            "name": templates[0].name,
                            "category": templates[0].category,
                            "isPremium": templates[0].isPremium
                        ]),
                        JsonObject.from([
                            "id": templates[1].id,
                            "name": templates[1].name,
                            "category": templates[1].category,
                            "isPremium": templates[1].isPremium
                        ]),
                        JsonObject.from([
                            "id": templates[2].id,
                            "name": templates[2].name,
                            "category": templates[2].category,
                            "isPremium": templates[2].isPremium
                        ])
                    ])
                ])))
        )

        // Mock 按分类筛选
        this.apiServer.mockEndpoint(
            MockEndpoint("/api/templates?category=professional", "GET")
                .respondWith(MockResponse.success(JsonObject.from([
                    "templates": JsonArray.from([
                        JsonObject.from([
                            "id": templates[0].id,
                            "name": templates[0].name,
                            "category": "professional",
                            "isPremium": false
                        ])
                    ])
                ])))
        )

        // Mock 获取模板详情
        this.apiServer.mockEndpoint(
            MockEndpoint("/api/templates/${selectedTemplate.id}", "GET")
                .respondWith(MockResponse.success(JsonObject.from([
                    "id": selectedTemplate.id,
                    "name": selectedTemplate.name,
                    "category": selectedTemplate.category,
                    "description": selectedTemplate.description,
                    "isPremium": selectedTemplate.isPremium
                ])))
        )

        // Mock 应用模板
        this.apiServer.mockEndpoint(
            MockEndpoint("/api/resumes/${resumeId}/apply-template", "POST")
                .respondWith(MockResponse.success(JsonObject.from([
                    "success": true,
                    "previewUrl": "previews/${resumeId}.png"
                ])))
        )

        // Act - 模拟用户操作流程

        // 1. 加载模板列表
        let loadResult = this.templateViewModel.loadTemplateList()
        Assert.assertTrue(loadResult.isSuccess(), "Should load template list")
        let loadedTemplates = loadResult.getData()
        Assert.assertTrue(loadedTemplates.size > 0, "Should have templates")

        // 2. 按分类筛选
        let filterResult = this.templateViewModel.filterByCategory("professional")
        Assert.assertTrue(filterResult.isSuccess(), "Should filter by category")
        let filteredTemplates = filterResult.getData()
        Assert.assertTrue(filteredTemplates.size > 0, "Should have filtered templates")

        // 3. 选择模板
        this.templateViewModel.selectTemplate(selectedTemplate)
        Assert.assertEquals(selectedTemplate.id, this.templateViewModel.getSelectedTemplate().id)

        // 4. 预览模板
        let previewResult = this.templateViewModel.previewTemplate(selectedTemplate.id)
        Assert.assertTrue(previewResult.isSuccess(), "Should preview template")

        // 5. 应用模板到简历
        let applyResult = this.templateViewModel.applyTemplateToResume(resumeId, selectedTemplate.id)
        Assert.assertTrue(applyResult.isSuccess(), "Should apply template")

        // Assert - 验证完整流程
        Assert.assertTrue(this.apiServer.verifyRequest("/api/templates", "GET"))
        Assert.assertTrue(this.apiServer.verifyRequest("/api/templates?category=professional", "GET"))
        Assert.assertTrue(this.apiServer.verifyRequest("/api/templates/${selectedTemplate.id}", "GET"))
        Assert.assertTrue(this.apiServer.verifyRequest("/api/resumes/${resumeId}/apply-template", "POST"))
    }

    // ============================================
    // 模板浏览和筛选测试
    // ============================================

    @Test
    public func testBrowseTemplateList(): Unit {
        // 测试浏览模板列表

        // Arrange
        let templates = TestDataFactory.createTemplateList()

        this.apiServer.mockEndpoint(
            MockEndpoint("/api/templates", "GET")
                .respondWith(MockResponse.success(JsonObject.from([
                    "templates": JsonArray.from([
                        JsonObject.from([
                            "id": templates[0].id,
                            "name": templates[0].name,
                            "category": templates[0].category,
                            "isPremium": templates[0].isPremium
                        ])
                    ])
                ])))
        )

        // Act
        let result = this.templateViewModel.loadTemplateList()

        // Assert
        Assert.assertTrue(result.isSuccess())
        let loadedTemplates = result.getData()
        Assert.assertTrue(loadedTemplates.size > 0)
    }

    @Test
    public func testFilterByFreeTemplates(): Unit {
        // 测试筛选免费模板

        // Arrange
        this.apiServer.mockEndpoint(
            MockEndpoint("/api/templates?premium=false", "GET")
                .respondWith(MockResponse.success(JsonObject.from([
                    "templates": JsonArray.from([
                        JsonObject.from([
                            "id": "free-template-001",
                            "name": "Free Template",
                            "isPremium": false
                        ])
                    ])
                ])))
        )

        // Act
        let result = this.templateViewModel.getFreeTemplates()

        // Assert
        Assert.assertTrue(result.isSuccess())
        let templates = result.getData()
        for (template in templates) {
            Assert.assertFalse(template.isPremium, "All should be free")
        }
    }

    @Test
    public func testFilterByPremiumTemplates(): Unit {
        // 测试筛选付费模板

        // Arrange
        this.apiServer.mockEndpoint(
            MockEndpoint("/api/templates?premium=true", "GET")
                .respondWith(MockResponse.success(JsonObject.from([
                    "templates": JsonArray.from([
                        JsonObject.from([
                            "id": "premium-template-001",
                            "name": "Premium Template",
                            "isPremium": true
                        ])
                    ])
                ])))
        )

        // Act
        let result = this.templateViewModel.getPremiumTemplates()

        // Assert
        Assert.assertTrue(result.isSuccess())
        let templates = result.getData()
        for (template in templates) {
            Assert.assertTrue(template.isPremium, "All should be premium")
        }
    }

    @Test
    public func testSearchTemplates(): Unit {
        // 测试搜索模板

        // Arrange
        let searchQuery = "modern"

        this.apiServer.mockEndpoint(
            MockEndpoint("/api/templates/search?q=${searchQuery}", "GET")
                .respondWith(MockResponse.success(JsonObject.from([
                    "templates": JsonArray.from([
                        JsonObject.from([
                            "id": "search-result-001",
                            "name": "Modern Professional",
                            "isPremium": false
                        ])
                    ])
                ])))
        )

        // Act
        let result = this.templateViewModel.searchTemplates(searchQuery)

        // Assert
        Assert.assertTrue(result.isSuccess())
        let templates = result.getData()
        Assert.assertTrue(templates.size > 0)
    }

    // ============================================
    // 模板预览测试
    // ============================================

    @Test
    public func testPreviewTemplate(): Unit {
        // 测试预览模板

        // Arrange
        let templateId = "preview-template-001"
        let expectedPreviewUrl = "templates/preview_${templateId}.png"

        this.apiServer.mockEndpoint(
            MockEndpoint("/api/templates/${templateId}/preview", "GET")
                .respondWith(MockResponse.success(JsonObject.from([
                    "previewUrl": expectedPreviewUrl
                ])))
        )

        // Act
        let result = this.templateViewModel.previewTemplate(templateId)

        // Assert
        Assert.assertTrue(result.isSuccess())
        let previewUrl = result.getData()
        Assert.assertEquals(expectedPreviewUrl, previewUrl)
    }

    @Test
    public func testPreviewMultipleTemplates(): Unit {
        // 测试预览多个模板

        // Arrange
        let templateIds = ["template-001", "template-002", "template-003"]

        for (templateId in templateIds) {
            this.apiServer.mockEndpoint(
                MockEndpoint("/api/templates/${templateId}/preview", "GET")
                    .respondWith(MockResponse.success(JsonObject.from([
                        "previewUrl": "templates/preview_${templateId}.png"
                    ])))
            )
        }

        // Act
        for (templateId in templateIds) {
            let result = this.templateViewModel.previewTemplate(templateId)
            Assert.assertTrue(result.isSuccess(), "Should preview ${templateId}")
        }

        // Assert
        Assert.assertEquals(templateIds.size,
                          this.apiServer.getRequestCount("/api/templates/", "GET"))
    }

    // ============================================
    // 模板应用测试
    // ============================================

    @Test
    public func testApplyFreeTemplate(): Unit {
        // 测试应用免费模板

        // Arrange
        let resumeId = "free-template-resume-001"
        let freeTemplateId = "free-template-001"

        this.apiServer.mockEndpoint(
            MockEndpoint("/api/resumes/${resumeId}/apply-template", "POST")
                .respondWith(MockResponse.success(JsonObject.from([
                    "success": true,
                    "previewUrl": "previews/${resumeId}_free.png"
                ])))
        )

        // Act
        let result = this.templateViewModel.applyTemplateToResume(resumeId, freeTemplateId)

        // Assert
        Assert.assertTrue(result.isSuccess(), "Should apply free template")
    }

    @Test
    public func testApplyPremiumTemplateWithoutSubscription(): Unit {
        // 测试在无订阅的情况下应用付费模板

        // Arrange
        let resumeId = "premium-no-sub-resume-001"
        let premiumTemplateId = "premium-template-001"

        this.apiServer.mockEndpoint(
            MockEndpoint("/api/resumes/${resumeId}/apply-template", "POST")
                .respondWith(MockResponse.error(403, "Premium subscription required"))
        )

        // Act
        let result = this.templateViewModel.applyTemplateToResume(resumeId, premiumTemplateId)

        // Assert
        Assert.assertTrue(result.isFailure(), "Should fail without subscription")
        let error = result.getError()
        Assert.assertEquals(403, error.getCode())
    }

    @Test
    public func testApplyTemplateToNonExistentResume(): Unit {
        // 测试将模板应用到不存在的简历

        // Arrange
        let nonExistentResumeId = "resume-999"
        let templateId = "template-001"

        this.apiServer.mockEndpoint(
            MockEndpoint("/api/resumes/${nonExistentResumeId}/apply-template", "POST")
                .respondWith(MockResponse.error(404, "Resume not found"))
        )

        // Act
        let result = this.templateViewModel.applyTemplateToResume(nonExistentResumeId, templateId)

        // Assert
        Assert.assertTrue(result.isFailure(), "Should fail with 404")
    }

    // ============================================
    // 模板比较测试
    // ============================================

    @Test
    public func testCompareTemplates(): Unit {
        // 测试比较多个模板

        // Arrange
        let templateIds = ["template-001", "template-002"]
        let templates = ArrayList<ResumeTemplate>()

        for (templateId in templateIds) {
            let template = ResumeTemplate(
                id = templateId,
                name = "Template ${templateId}",
                category = "professional",
                description = "Description",
                thumbnail = "",
                preview = "",
                isPremium = false,
                features = ArrayList<String>(["Feature 1", "Feature 2"])
            )
            templates.add(template)

            this.apiServer.mockEndpoint(
                MockEndpoint("/api/templates/${templateId}", "GET")
                    .respondWith(MockResponse.success(JsonObject.from([
                        "id": template.id,
                        "name": template.name,
                        "category": template.category
                    ])))
            )
        }

        // Act
        let comparisonResult = this.templateViewModel.compareTemplates(templateIds)

        // Assert
        Assert.assertTrue(comparisonResult.isSuccess())
        let comparison = comparisonResult.getData()
        Assert.assertEquals(templateIds.size, comparison.size)
    }

    // ============================================
    // 状态管理测试
    // ============================================

    @Test
    public func testTemplateSelectionState(): Unit {
        // 测试模板选择状态管理

        // Arrange
        let template = TestDataFactory.createModernTemplate()

        // Act - 选择模板
        this.templateViewModel.selectTemplate(template)

        // Assert
        Assert.assertEquals(template.id, this.templateViewModel.getSelectedTemplate().id)
        Assert.assertTrue(this.templateViewModel.hasSelectedTemplate())

        // 取消选择
        this.templateViewModel.clearSelection()
        Assert.assertFalse(this.templateViewModel.hasSelectedTemplate())
    }

    @Test
    public func testTemplateLoadingState(): Unit {
        // 测试模板加载状态

        // Arrange
        let delayedResponse = MockResponse.success(JsonObject.from([
            "templates": JsonArray.from([
                JsonObject.from([
                    "id": "delayed-template-001",
                    "name": "Delayed Template"
                ])
            ])
        ]))
        delayedResponse.setDelayMs(100)

        this.apiServer.mockEndpoint(
            MockEndpoint("/api/templates", "GET")
                .respondWith(delayedResponse)
        )

        // Act
        Assert.assertFalse(this.templateViewModel.isLoading(),
                          "Should not be loading before request")

        let loadFuture = this.templateViewModel.loadTemplateListAsync()

        Assert.assertTrue(this.templateViewModel.isLoading(),
                         "Should be loading during request")

        let result = loadFuture.get()

        Assert.assertFalse(this.templateViewModel.isLoading(),
                          "Should not be loading after request")
        Assert.assertTrue(result.isSuccess())
    }

    // ============================================
    // 收藏和最近使用测试
    // ============================================

    @Test
    public func testFavoriteTemplate(): Unit {
        // 测试收藏模板

        // Arrange
        let template = TestDataFactory.createModernTemplate()

        // Act
        this.templateViewModel.addFavoriteTemplate(template)
        let favorites = this.templateViewModel.getFavoriteTemplates()

        // Assert
        Assert.assertTrue(favorites.contains(template))
        Assert.assertEquals(1, favorites.size)
    }

    @Test
    public func testRemoveFavoriteTemplate(): Unit {
        // 测试取消收藏模板

        // Arrange
        let template = TestDataFactory.createModernTemplate()
        this.templateViewModel.addFavoriteTemplate(template)

        // Act
        this.templateViewModel.removeFavoriteTemplate(template.id)
        let favorites = this.templateViewModel.getFavoriteTemplates()

        // Assert
        Assert.assertFalse(favorites.contains(template))
    }

    @Test
    public func testRecentlyUsedTemplates(): Unit {
        // 测试最近使用的模板

        // Arrange
        let resumeId = "recent-resume-001"
        let templates = TestDataFactory.createTemplateList()

        this.apiServer.mockEndpoint(
            MockEndpoint("/api/resumes/${resumeId}/apply-template", "POST")
                .respondWith(MockResponse.success(JsonObject.from([
                    "success": true
                ])))
        )

        // Act - 应用多个模板
        for (template in templates) {
            this.templateViewModel.applyTemplateToResume(resumeId, template.id)
        }

        let recentlyUsed = this.templateViewModel.getRecentlyUsedTemplates()

        // Assert
        Assert.assertTrue(recentlyUsed.size > 0, "Should have recently used templates")
    }

    // ============================================
    // 错误处理测试
    // ============================================

    @Test
    public func testHandleTemplateLoadError(): Unit {
        // 测试模板加载错误处理

        // Arrange
        this.apiServer.mockEndpoint(
            MockEndpoint("/api/templates", "GET")
                .respondWith(MockResponse.error(500, "Server error"))
        )

        // Act
        let result = this.templateViewModel.loadTemplateList()

        // Assert
        Assert.assertTrue(result.isFailure(), "Should handle load error")
        let error = result.getError()
        Assert.assertEquals(500, error.getCode())
    }

    @Test
    public func testHandlePreviewError(): Unit {
        // 测试预览错误处理

        // Arrange
        let templateId = "error-preview-template-001"
        this.apiServer.mockEndpoint(
            MockEndpoint("/api/templates/${templateId}/preview", "GET")
                .respondWith(MockResponse.error(404, "Preview not found"))
        )

        // Act
        let result = this.templateViewModel.previewTemplate(templateId)

        // Assert
        Assert.assertTrue(result.isFailure(), "Should handle preview error")
    }

    // ============================================
    // 批量操作测试
    // ============================================

    @Test
    public func testBatchApplyTemplateToMultipleResumes(): Unit {
        // 测试批量应用模板到多个简历

        // Arrange
        let templateId = "batch-template-001"
        let resumeIds = ["resume-001", "resume-002", "resume-003"]

        for (resumeId in resumeIds) {
            this.apiServer.mockEndpoint(
                MockEndpoint("/api/resumes/${resumeId}/apply-template", "POST")
                    .respondWith(MockResponse.success(JsonObject.from([
                        "success": true
                    ])))
        }

        // Act
        let results = this.templateViewModel.batchApplyTemplate(resumeIds, templateId)

        // Assert
        Assert.assertEquals(resumeIds.size, results.size)
        for (result in results) {
            Assert.assertTrue(result.isSuccess(), "Each application should succeed")
        }

        Assert.assertEquals(resumeIds.size,
                          this.apiServer.getRequestCount("/api/resumes/", "POST"))
    }
}

// ============================================
// Mock 类定义
// ============================================

/// Mock HTTP Client for Template Flow Tests
internal class MockHttpClientForTemplateFlow {
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

/// Mock Token Storage for Template Flow Tests
internal class MockTokenStorageForTemplateFlow {
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
