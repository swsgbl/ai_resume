package test.integration.flow

import std.unittest.*
import std.unittest.mock.*
import entry.src.services.*
import entry.src.models.*
import entry.src.viewmodels.*
import test.integration.data.TestDataFactory
import test.integration.mock.*

/// 简历编辑流程集成测试
/// 测试用户编辑现有简历的端到端流程
@TestCase
public class ResumeEditingFlowTest {
    private let apiServer: TestApiServer
    private let resumeService: ResumeService
    private let aiService: AIService
    private let resumeViewModel: ResumeViewModel
    private let mockTokenStorage: MockTokenStorageForEditFlow

    public init() {
        this.apiServer = TestApiServer()
        this.mockTokenStorage = MockTokenStorageForEditFlow()
        this.mockTokenStorage.setToken(TestDataFactory.createValidAuthToken())

        let mockHttpClient = MockHttpClientForEditFlow(this.apiServer)
        this.resumeService = ResumeService(
            httpClient: mockHttpClient,
            tokenStorage: this.mockTokenStorage
        )
        this.aiService = AIService(
            httpClient: mockHttpClient,
            tokenStorage: this.mockTokenStorage
        )

        this.resumeViewModel = ResumeViewModel(
            resumeService: this.resumeService,
            aiService: this.aiService
        )
    }

    // ============================================
    // 加载和编辑流程测试
    // ============================================

    @Test
    public func testLoadAndEditResume(): Unit {
        // 测试加载现有简历并进行编辑

        // Arrange
        let resumeId = "edit-resume-001"
        let existingResume = TestDataFactory.createCompleteResume()
        existingResume.id = resumeId

        this.apiServer.mockEndpoint(
            MockEndpoint("/api/resumes/${resumeId}", "GET")
                .respondWith(MockResponse.success(JsonObject.from([
                    "id": existingResume.id,
                    "title": existingResume.title,
                    "personalInfo": JsonObject.from([
                        "name": existingResume.personalInfo.name,
                        "email": existingResume.personalInfo.email
                    ])
                ])))
        )

        this.apiServer.mockEndpoint(
            MockEndpoint("/api/resumes/${resumeId}", "PUT")
                .respondWith(MockResponse.success(JsonObject.from([
                    "id": resumeId,
                    "title": "Updated Resume"
                ])))
        )

        // Act - 加载简历
        let loadResult = this.resumeViewModel.loadResume(resumeId)
        Assert.assertTrue(loadResult.isSuccess(), "Should load resume")

        // 编辑标题
        this.resumeViewModel.updateTitle("Updated Resume")

        // 保存更改
        let saveResult = this.resumeViewModel.saveCurrentResume()

        // Assert
        Assert.assertTrue(saveResult.isSuccess(), "Should save changes")
        Assert.assertEquals("Updated Resume", this.resumeViewModel.getCurrentResume().title)

        // 验证 API 请求
        Assert.assertTrue(this.apiServer.verifyRequest("/api/resumes/${resumeId}", "GET"))
        Assert.assertTrue(this.apiServer.verifyRequest("/api/resumes/${resumeId}", "PUT"))
    }

    // ============================================
    // 章节编辑测试
    // ============================================

    @Test
    public func testEditPersonalInfoSection(): Unit {
        // 测试编辑个人信息章节

        // Arrange
        let resumeId = "personal-edit-resume-001"
        let existingInfo = TestDataFactory.createCompletePersonalInfo()
        let updatedInfo = PersonalInfo(
            name = "Updated Name",
            email = "updated@example.com",
            phone = existingInfo.phone,
            location = existingInfo.location,
            summary = "Updated summary",
            linkedin = existingInfo.linkedin,
            github = existingInfo.github
        )

        this.apiServer.mockEndpoint(
            MockEndpoint("/api/resumes/${resumeId}/personal-info", "PUT")
                .respondWith(MockResponse.success(JsonObject.from([
                    "success": true
                ])))
        )

        // Act
        this.resumeViewModel.initializeWithResume(resumeId)
        this.resumeViewModel.updatePersonalInfo(updatedInfo)
        let result = this.resumeViewModel.savePersonalInfo()

        // Assert
        Assert.assertTrue(result.isSuccess())
        Assert.assertEquals(updatedInfo.name,
                          this.resumeViewModel.getCurrentResume().personalInfo.name)
        Assert.assertEquals(updatedInfo.email,
                          this.resumeViewModel.getCurrentResume().personalInfo.email)
    }

    @Test
    public func testEditEducationSection(): Unit {
        // 测试编辑教育章节

        // Arrange
        let resumeId = "edu-edit-resume-001"
        let existingEdu = TestDataFactory.createBachelorEducation()
        let updatedEdu = Education(
            id = existingEdu.id,
            school = "Updated University",
            degree = "Master of Science",
            major = "Data Science",
            startDate = "2020-09",
            endDate = "2022-05",
            gpa = "3.9"
        )

        this.apiServer.mockEndpoint(
            MockEndpoint("/api/resumes/${resumeId}/education/${updatedEdu.id}", "PUT")
                .respondWith(MockResponse.success(JsonObject.from([
                    "id": updatedEdu.id,
                    "school": updatedEdu.school
                ])))
        )

        // Act
        this.resumeViewModel.initializeWithResume(resumeId)
        this.resumeViewModel.updateEducation(updatedEdu)
        let result = this.resumeViewModel.saveEducation()

        // Assert
        Assert.assertTrue(result.isSuccess())
    }

    @Test
    public func testEditExperienceSection(): Unit {
        // 测试编辑工作经历章节

        // Arrange
        let resumeId = "exp-edit-resume-001"
        let existingExp = TestDataFactory.createSeniorExperience()
        let updatedExp = WorkExperience(
            id = existingExp.id,
            company = "Updated Tech Company",
            position = "Principal Software Engineer",
            startDate = existingExp.startDate,
            endDate = "",
            current = true,
            description = "Updated description",
            achievements = ArrayList<String>([
                "New achievement 1",
                "New achievement 2"
            ])
        )

        this.apiServer.mockEndpoint(
            MockEndpoint("/api/resumes/${resumeId}/experience/${updatedExp.id}", "PUT")
                .respondWith(MockResponse.success(JsonObject.from([
                    "id": updatedExp.id,
                    "company": updatedExp.company
                ])))
        )

        // Act
        this.resumeViewModel.initializeWithResume(resumeId)
        this.resumeViewModel.updateExperience(updatedExp)
        let result = this.resumeViewModel.saveExperience()

        // Assert
        Assert.assertTrue(result.isSuccess())
    }

    // ============================================
    // AI 辅助编辑测试
    // ============================================

    @Test
    public func testAIGenerateSummary(): Unit {
        // 测试 AI 生成个人简介

        // Arrange
        let resumeId = "ai-summary-resume-001"
        let resume = TestDataFactory.createCompleteResume()
        let aiGeneratedSummary = "Experienced software engineer with expertise in mobile development."

        this.apiServer.mockEndpoint(
            MockEndpoint("/api/ai/generate-summary", "POST")
                .respondWith(MockResponse.success(JsonObject.from([
                    "summary": aiGeneratedSummary
                ])))
        )

        this.apiServer.mockEndpoint(
            MockEndpoint("/api/resumes/${resumeId}/personal-info", "PUT")
                .respondWith(MockResponse.success(JsonObject.from([
                    "success": true
                ])))
        )

        // Act
        this.resumeViewModel.initializeWithResume(resumeId)
        let aiResult = this.resumeViewModel.generateAISummary()

        // Assert
        Assert.assertTrue(aiResult.isSuccess(), "Should generate AI summary")
        Assert.assertEquals(aiGeneratedSummary, aiResult.getData())

        // 验证 AI 生成的简介已应用到简历
        Assert.assertEquals(aiGeneratedSummary,
                          this.resumeViewModel.getCurrentResume().personalInfo.summary)
    }

    @Test
    public func testAIOptimizeExperience(): Unit {
        // 测试 AI 优化工作经历

        // Arrange
        let resumeId = "ai-optimize-resume-001"
        let experience = TestDataFactory.createSeniorExperience()
        let optimizedDescription = "Led mobile development, achieving 100K+ downloads and 4.8-star rating."

        this.apiServer.mockEndpoint(
            MockEndpoint("/api/ai/optimize-experience", "POST")
                .respondWith(MockResponse.success(JsonObject.from([
                    "optimizedDescription": optimizedDescription
                ])))
        )

        // Act
        this.resumeViewModel.initializeWithResume(resumeId)
        let aiResult = this.resumeViewModel.optimizeExperienceWithAI(experience)

        // Assert
        Assert.assertTrue(aiResult.isSuccess(), "Should optimize experience")
        Assert.assertEquals(optimizedDescription, aiResult.getData())
    }

    @Test
    public func testAIGenerateSkills(): Unit {
        // 测试 AI 生成技能建议

        // Arrange
        let resumeId = "ai-skills-resume-001"
        let resume = TestDataFactory.createCompleteResume()
        let suggestedSkills = ArrayList<String>([
            "Mobile Development",
            "Team Leadership",
            "Agile Methodology"
        ])

        this.apiServer.mockEndpoint(
            MockEndpoint("/api/ai/generate-skills", "POST")
                .respondWith(MockResponse.success(JsonObject.from([
                    "skills": JsonArray.from([
                        "Mobile Development",
                        "Team Leadership",
                        "Agile Methodology"
                    ])
                ])))
        )

        // Act
        this.resumeViewModel.initializeWithResume(resumeId)
        let aiResult = this.resumeViewModel.generateAISkills()

        // Assert
        Assert.assertTrue(aiResult.isSuccess(), "Should generate AI skills")
        let skills = aiResult.getData()
        Assert.assertEquals(suggestedSkills.size, skills.size)
    }

    // ============================================
    // 章节切换测试
    // ============================================

    @Test
    public func testSwitchBetweenSections(): Unit {
        // 测试在不同章节之间切换

        // Arrange
        let resumeId = "section-switch-resume-001"
        let sections = ["personal", "education", "experience", "skills", "projects"]

        // Act - 切换到各个章节
        for (section in sections) {
            this.resumeViewModel.switchToSection(section)
            Assert.assertEquals(section, this.resumeViewModel.getCurrentSection(),
                             "Should switch to ${section} section")
        }

        // Assert - 验证所有章节都可以访问
        for (section in sections) {
            let canAccess = this.resumeViewModel.canAccessSection(section)
            Assert.assertTrue(canAccess, "Should access ${section} section")
        }
    }

    @Test
    public func testEditProgressTracking(): Unit {
        // 测试编辑进度跟踪

        // Arrange
        let resumeId = "progress-resume-001"
        let resume = TestDataFactory.createCompleteResume()

        // Act
        this.resumeViewModel.initializeWithResume(resumeId)

        // 初始进度
        let initialProgress = this.resumeViewModel.getEditingProgress()
        Assert.assertTrue(initialProgress > 0, "Should have initial progress")

        // 编辑个人信息
        this.resumeViewModel.updatePersonalInfo(TestDataFactory.createCompletePersonalInfo())
        let progressAfterPersonal = this.resumeViewModel.getEditingProgress()

        // 编辑教育
        this.resumeViewModel.addEducation(TestDataFactory.createBachelorEducation())
        let progressAfterEducation = this.resumeViewModel.getEditingProgress()

        // 编辑工作经历
        this.resumeViewModel.addExperience(TestDataFactory.createSeniorExperience())
        let progressAfterExperience = this.resumeViewModel.getEditingProgress()

        // Assert
        Assert.assertTrue(progressAfterPersonal >= initialProgress,
                         "Progress should increase after editing personal info")
        Assert.assertTrue(progressAfterEducation >= progressAfterPersonal,
                         "Progress should increase after adding education")
        Assert.assertTrue(progressAfterExperience >= progressAfterEducation,
                         "Progress should increase after adding experience")
    }

    // ============================================
    // 批量编辑测试
    // ============================================

    @Test
    public func testBatchUpdateEducation(): Unit {
        // 测试批量更新教育经历

        // Arrange
        let resumeId = "batch-edu-resume-001"
        let educationList = TestDataFactory.createEducationList()

        this.apiServer.mockEndpoint(
            MockEndpoint("/api/resumes/${resumeId}/education", "PUT")
                .respondWith(MockResponse.success(JsonObject.from([
                    "success": true
                ])))
        )

        // Act
        this.resumeViewModel.initializeWithResume(resumeId)
        this.resumeViewModel.updateEducationList(educationList)
        let result = this.resumeViewModel.saveEducation()

        // Assert
        Assert.assertTrue(result.isSuccess())
        Assert.assertEquals(educationList.size,
                          this.resumeViewModel.getCurrentResume().education.size)
    }

    @Test
    public func testBatchUpdateExperience(): Unit {
        // 测试批量更新工作经历

        // Arrange
        let resumeId = "batch-exp-resume-001"
        let experienceList = TestDataFactory.createExperienceList()

        this.apiServer.mockEndpoint(
            MockEndpoint("/api/resumes/${resumeId}/experience", "PUT")
                .respondWith(MockResponse.success(JsonObject.from([
                    "success": true
                ])))
        )

        // Act
        this.resumeViewModel.initializeWithResume(resumeId)
        this.resumeViewModel.updateExperienceList(experienceList)
        let result = this.resumeViewModel.saveExperience()

        // Assert
        Assert.assertTrue(result.isSuccess())
        Assert.assertEquals(experienceList.size,
                          this.resumeViewModel.getCurrentResume().experience.size)
    }

    // ============================================
    // 删除操作测试
    // ============================================

    @Test
    public func testDeleteEducation(): Unit {
        // 测试删除教育经历

        // Arrange
        let resumeId = "delete-edu-resume-001"
        let education = TestDataFactory.createBachelorEducation()

        this.apiServer.mockEndpoint(
            MockEndpoint("/api/resumes/${resumeId}/education/${education.id}", "DELETE")
                .respondWith(MockResponse.success(JsonObject.from([
                    "success": true
                ])))
        )

        // Act
        this.resumeViewModel.initializeWithResume(resumeId)
        this.resumeViewModel.addEducation(education)
        Assert.assertEquals(1, this.resumeViewModel.getCurrentResume().education.size)

        let result = this.resumeViewModel.deleteEducation(education.id)

        // Assert
        Assert.assertTrue(result.isSuccess())
        Assert.assertEquals(0, this.resumeViewModel.getCurrentResume().education.size)
    }

    @Test
    public func testDeleteExperience(): Unit {
        // 测试删除工作经历

        // Arrange
        let resumeId = "delete-exp-resume-001"
        let experience = TestDataFactory.createSeniorExperience()

        this.apiServer.mockEndpoint(
            MockEndpoint("/api/resumes/${resumeId}/experience/${experience.id}", "DELETE")
                .respondWith(MockResponse.success(JsonObject.from([
                    "success": true
                ])))
        )

        // Act
        this.resumeViewModel.initializeWithResume(resumeId)
        this.resumeViewModel.addExperience(experience)
        Assert.assertEquals(1, this.resumeViewModel.getCurrentResume().experience.size)

        let result = this.resumeViewModel.deleteExperience(experience.id)

        // Assert
        Assert.assertTrue(result.isSuccess())
        Assert.assertEquals(0, this.resumeViewModel.getCurrentResume().experience.size)
    }

    // ============================================
    // 错误处理和恢复测试
    // ============================================

    @Test
    public func testHandleEditError(): Unit {
        // 测试编辑错误处理

        // Arrange
        let resumeId = "error-edit-resume-001"
        this.apiServer.mockEndpoint(
            MockEndpoint("/api/resumes/${resumeId}", "PUT")
                .respondWith(MockResponse.error(500, "Server error"))
        )

        // Act
        this.resumeViewModel.initializeWithResume(resumeId)
        this.resumeViewModel.updateTitle("Updated Title")
        let result = this.resumeViewModel.saveCurrentResume()

        // Assert
        Assert.assertTrue(result.isFailure(), "Should handle edit error")

        // 验证可以继续编辑（不受错误影响）
        this.resumeViewModel.updateTitle("Another Update")
        Assert.assertEquals("Another Update", this.resumeViewModel.getCurrentResume().title)
    }

    @Test
    public func testHandleAIServiceError(): Unit {
        // 测试 AI 服务错误处理

        // Arrange
        let resumeId = "ai-error-resume-001"
        this.apiServer.mockEndpoint(
            MockEndpoint("/api/ai/generate-summary", "POST")
                .respondWith(MockResponse.error(503, "AI service unavailable"))
        )

        // Act
        this.resumeViewModel.initializeWithResume(resumeId)
        let result = this.resumeViewModel.generateAISummary()

        // Assert
        Assert.assertTrue(result.isFailure(), "Should handle AI service error")

        // 验证可以继续手动编辑
        let manualSummary = "Manually written summary"
        let personalInfo = this.resumeViewModel.getCurrentResume().personalInfo
        personalInfo.summary = manualSummary
        this.resumeViewModel.updatePersonalInfo(personalInfo)

        Assert.assertEquals(manualSummary,
                          this.resumeViewModel.getCurrentResume().personalInfo.summary)
    }

    // ============================================
    // 保存和恢复测试
    // ============================================

    @Test
    public func testSaveAndRestoreDraft(): Unit {
        // 测试保存和恢复草稿

        // Arrange
        let resumeId = "draft-restore-resume-001"
        let draftTitle = "Draft Resume"

        this.apiServer.mockEndpoint(
            MockEndpoint("/api/resumes/${resumeId}/draft", "PUT")
                .respondWith(MockResponse.success(JsonObject.from([
                    "success": true
                ])))
        )

        this.apiServer.mockEndpoint(
            MockEndpoint("/api/resumes/${resumeId}/draft", "GET")
                .respondWith(MockResponse.success(JsonObject.from([
                    "id": resumeId,
                    "title": draftTitle
                ])))
        )

        // Act - 保存草稿
        this.resumeViewModel.initializeWithResume(resumeId)
        this.resumeViewModel.updateTitle(draftTitle)
        let saveResult = this.resumeViewModel.saveAsDraft()
        Assert.assertTrue(saveResult.isSuccess())

        // 恢复草稿
        let restoreResult = this.resumeViewModel.loadDraft(resumeId)

        // Assert
        Assert.assertTrue(restoreResult.isSuccess())
        Assert.assertEquals(draftTitle, this.resumeViewModel.getCurrentResume().title)
    }
}

// ============================================
// Mock 类定义
// ============================================

/// Mock HTTP Client for Edit Flow Tests
internal class MockHttpClientForEditFlow {
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

    public func put(url: String, body: String): MockResponse {
        return this.apiServer.getResponse("PUT", url, body)
    }

    public func delete(url: String): MockResponse {
        return this.apiServer.getResponse("DELETE", url)
    }
}

/// Mock Token Storage for Edit Flow Tests
internal class MockTokenStorageForEditFlow {
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
