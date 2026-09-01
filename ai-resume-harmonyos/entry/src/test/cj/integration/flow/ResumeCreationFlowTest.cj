package test.integration.flow

import std.unittest.*
import std.unittest.mock.*
import entry.src.services.*
import entry.src.models.*
import entry.src.viewmodels.*
import test.integration.data.TestDataFactory
import test.integration.mock.*

/// 简历创建流程集成测试
/// 测试用户创建完整简历的端到端流程
@TestCase
public class ResumeCreationFlowTest {
    private let apiServer: TestApiServer
    private let resumeService: ResumeService
    private let resumeViewModel: ResumeViewModel
    private let mockTokenStorage: MockTokenStorageForResumeFlow

    public init() {
        this.apiServer = TestApiServer()
        this.mockTokenStorage = MockTokenStorageForResumeFlow()
        this.mockTokenStorage.setToken(TestDataFactory.createValidAuthToken())

        let mockHttpClient = MockHttpClientForResumeFlow(this.apiServer)
        this.resumeService = ResumeService(
            httpClient: mockHttpClient,
            tokenStorage: this.mockTokenStorage
        )

        this.resumeViewModel = ResumeViewModel(
            resumeService: this.resumeService
        )
    }

    // ============================================
    // 完整简历创建流程测试
    // ============================================

    @Test
    public func testCompleteResumeCreationFlow(): Unit {
        // 测试完整流程：创建简历 → 填写信息 → 添加教育 → 添加工作经历 → 添加技能 → 保存

        // Arrange
        let personalInfo = TestDataFactory.createCompletePersonalInfo()
        let education = TestDataFactory.createBachelorEducation()
        let experience = TestDataFactory.createSeniorExperience()
        let skills = TestDataFactory.createSkillsList()
        let newResumeId = "new-resume-001"

        // Mock 创建简历响应
        this.apiServer.mockEndpoint(
            MockEndpoint("/api/resumes", "POST")
                .respondWith(MockResponse.success(JsonObject.from([
                    "id": newResumeId,
                    "title": "New Resume",
                    "createdAt": "2024-03-30T10:00:00Z"
                ])))
        )

        // Mock 更新个人信息响应
        this.apiServer.mockEndpoint(
            MockEndpoint("/api/resumes/${newResumeId}/personal-info", "PUT")
                .respondWith(MockResponse.success(JsonObject.from([
                    "success": true
                ])))
        )

        // Mock 添加教育经历响应
        this.apiServer.mockEndpoint(
            MockEndpoint("/api/resumes/${newResumeId}/education", "POST")
                .respondWith(MockResponse.success(JsonObject.from([
                    "id": "edu-added-001",
                    "school": education.school
                ])))
        )

        // Mock 添加工作经历响应
        this.apiServer.mockEndpoint(
            MockEndpoint("/api/resumes/${newResumeId}/experience", "POST")
                .respondWith(MockResponse.success(JsonObject.from([
                    "id": "exp-added-001",
                    "company": experience.company
                ])))
        )

        // Mock 添加技能响应
        this.apiServer.mockEndpoint(
            MockEndpoint("/api/resumes/${newResumeId}/skills", "PUT")
                .respondWith(MockResponse.success(JsonObject.from([
                    "success": true
                ])))
        )

        // Act - 模拟用户操作流程

        // 1. 创建新简历
        let createResult = this.resumeViewModel.createNewResume("New Resume")
        Assert.assertTrue(createResult.isSuccess(), "Should create resume")
        Assert.assertEquals(newResumeId, createResult.getData().id)

        // 2. 填写个人信息
        this.resumeViewModel.updatePersonalInfo(personalInfo)
        let personalInfoResult = this.resumeViewModel.savePersonalInfo()
        Assert.assertTrue(personalInfoResult.isSuccess(), "Should save personal info")

        // 3. 添加教育经历
        this.resumeViewModel.addEducation(education)
        Assert.assertTrue(this.resumeViewModel.getCurrentResume().education.size > 0,
                          "Education should be added")

        // 4. 添加工作经历
        this.resumeViewModel.addExperience(experience)
        Assert.assertTrue(this.resumeViewModel.getCurrentResume().experience.size > 0,
                          "Experience should be added")

        // 5. 添加技能
        this.resumeViewModel.updateSkills(skills)
        let skillsResult = this.resumeViewModel.saveSkills()
        Assert.assertTrue(skillsResult.isSuccess(), "Should save skills")

        // 6. 保存完整简历
        let saveResult = this.resumeViewModel.saveCurrentResume()
        Assert.assertTrue(saveResult.isSuccess(), "Should save complete resume")

        // Assert - 验证完整流程
        Assert.assertTrue(
            this.apiServer.verifyRequest("/api/resumes", "POST"),
            "Should call create endpoint"
        )
        Assert.assertTrue(
            this.apiServer.verifyRequest("/api/resumes/${newResumeId}/personal-info", "PUT"),
            "Should update personal info"
        )
        Assert.assertTrue(
            this.apiServer.verifyRequest("/api/resumes/${newResumeId}/education", "POST"),
            "Should add education"
        )
        Assert.assertTrue(
            this.apiServer.verifyRequest("/api/resumes/${newResumeId}/experience", "POST"),
            "Should add experience"
        )
        Assert.assertTrue(
            this.apiServer.verifyRequest("/api/resumes/${newResumeId}/skills", "PUT"),
            "Should update skills"
        )
    }

    @Test
    public func testMinimalResumeCreation(): Unit {
        // 测试创建最小简历（仅含必需信息）

        // Arrange
        let minimalInfo = TestDataFactory.createMinimalPersonalInfo()
        let resumeId = "minimal-resume-001"

        this.apiServer.mockEndpoint(
            MockEndpoint("/api/resumes", "POST")
                .respondWith(MockResponse.success(JsonObject.from([
                    "id": resumeId,
                    "title": "Minimal Resume"
                ])))
        )

        this.apiServer.mockEndpoint(
            MockEndpoint("/api/resumes/${resumeId}/personal-info", "PUT")
                .respondWith(MockResponse.success(JsonObject.from([
                    "success": true
                ])))
        )

        // Act
        let createResult = this.resumeViewModel.createNewResume("Minimal Resume")
        this.resumeViewModel.updatePersonalInfo(minimalInfo)
        let saveResult = this.resumeViewModel.saveCurrentResume()

        // Assert
        Assert.assertTrue(createResult.isSuccess())
        Assert.assertTrue(saveResult.isSuccess())

        let currentResume = this.resumeViewModel.getCurrentResume()
        Assert.assertEquals(minimalInfo.name, currentResume.personalInfo.name)
        Assert.assertEquals(minimalInfo.email, currentResume.personalInfo.email)
    }

    // ============================================
    // 分步创建流程测试
    // ============================================

    @Test
    public func testStepByStepResumeCreation(): Unit {
        // 测试分步创建流程

        // 1. 初始化
        this.resumeViewModel.initializeNewResume()
        Assert.assertNotNull(this.resumeViewModel.getCurrentResume())

        // 2. 第一步：个人信息
        let personalInfo = TestDataFactory.createCompletePersonalInfo()
        this.resumeViewModel.updatePersonalInfo(personalInfo)
        Assert.assertEquals(personalInfo.name,
                          this.resumeViewModel.getCurrentResume().personalInfo.name)

        // 3. 第二步：教育经历
        let education = TestDataFactory.createBachelorEducation()
        this.resumeViewModel.addEducation(education)
        Assert.assertEquals(1, this.resumeViewModel.getCurrentResume().education.size)

        // 4. 第三步：工作经历
        let experience = TestDataFactory.createSeniorExperience()
        this.resumeViewModel.addExperience(experience)
        Assert.assertEquals(1, this.resumeViewModel.getCurrentResume().experience.size)

        // 5. 第四步：技能
        let skills = TestDataFactory.createSkillsList()
        this.resumeViewModel.updateSkills(skills)
        Assert.assertTrue(this.resumeViewModel.getCurrentResume().skills.size > 0)

        // 6. 第五步：预览
        let isComplete = this.resumeViewModel.isCurrentResumeComplete()
        Assert.assertTrue(isComplete, "Resume should be complete")
    }

    // ============================================
    // 数据验证测试
    // ============================================

    @Test
    public func testResumeValidation(): Unit {
        // 测试简历数据验证

        // Arrange & Act
        this.resumeViewModel.initializeNewResume()

        // 空简历应该不完整
        Assert.assertFalse(this.resumeViewModel.isCurrentResumeComplete(),
                          "Empty resume should not be complete")

        // 添加个人信息
        let personalInfo = TestDataFactory.createCompletePersonalInfo()
        this.resumeViewModel.updatePersonalInfo(personalInfo)

        // 仍然不完整（缺少其他必需部分）
        let isCompleteAfterInfo = this.resumeViewModel.isCurrentResumeComplete()

        // 添加教育
        this.resumeViewModel.addEducation(TestDataFactory.createBachelorEducation())

        // 添加工作经历
        this.resumeViewModel.addExperience(TestDataFactory.createSeniorExperience())

        // 添加技能
        this.resumeViewModel.updateSkills(TestDataFactory.createSkillsList())

        // 现在应该完整
        Assert.assertTrue(this.resumeViewModel.isCurrentResumeComplete(),
                         "Resume with all sections should be complete")
    }

    @Test
    public func testInvalidPersonalInfoValidation(): Unit {
        // 测试无效个人信息验证

        // Arrange
        let invalidInfo = PersonalInfo(
            name = "",
            email = "invalid-email",
            phone = "",
            location = "",
            summary = "",
            linkedin = "",
            github = ""
        )

        // Act
        this.resumeViewModel.initializeNewResume()
        this.resumeViewModel.updatePersonalInfo(invalidInfo)

        let isValid = this.resumeViewModel.validatePersonalInfo()

        // Assert
        Assert.assertFalse(isValid, "Should reject invalid personal info")
    }

    // ============================================
    // 错误处理测试
    // ============================================

    @Test
    public func testHandleCreationError(): Unit {
        // 测试创建简历错误处理

        // Arrange
        this.apiServer.mockEndpoint(
            MockEndpoint("/api/resumes", "POST")
                .respondWith(MockResponse.error(400, "Invalid resume data"))
        )

        // Act
        let result = this.resumeViewModel.createNewResume("Invalid Resume")

        // Assert
        Assert.assertTrue(result.isFailure(), "Should fail with invalid data")
        let error = result.getError()
        Assert.assertEquals(400, error.getCode())
    }

    @Test
    public func testHandleSaveError(): Unit {
        // 测试保存错误处理

        // Arrange
        let resumeId = "error-resume-001"
        this.apiServer.mockEndpoint(
            MockEndpoint("/api/resumes", "POST")
                .respondWith(MockResponse.success(JsonObject.from([
                    "id": resumeId,
                    "title": "Error Resume"
                ])))
        )

        this.apiServer.mockEndpoint(
            MockEndpoint("/api/resumes/${resumeId}", "PUT")
                .respondWith(MockResponse.error(500, "Server error"))
        )

        // Act
        this.resumeViewModel.createNewResume("Error Resume")
        let result = this.resumeViewModel.saveCurrentResume()

        // Assert
        Assert.assertTrue(result.isFailure(), "Should handle save error")
    }

    // ============================================
    // 状态管理测试
    // ============================================

    @Test
    public func testResumeCreationLoadingStates(): Unit {
        // 测试创建过程中的加载状态

        // Arrange
        let resumeId = "loading-resume-001"

        let delayedResponse = MockResponse.success(JsonObject.from([
            "id": resumeId,
            "title": "Loading Resume"
        ]))
        delayedResponse.setDelayMs(100)

        this.apiServer.mockEndpoint(
            MockEndpoint("/api/resumes", "POST")
                .respondWith(delayedResponse)
        )

        // Act
        Assert.assertFalse(this.resumeViewModel.isLoading(),
                          "Should not be loading before creation")

        let createFuture = this.resumeViewModel.createNewResumeAsync("Loading Resume")

        Assert.assertTrue(this.resumeViewModel.isLoading(),
                         "Should be loading during creation")

        let result = createFuture.get()

        Assert.assertFalse(this.resumeViewModel.isLoading(),
                          "Should not be loading after creation")
        Assert.assertTrue(result.isSuccess())
    }

    @Test
    public func testAutoSaveBehavior(): Unit {
        // 测试自动保存行为

        // Arrange
        let resumeId = "autosave-resume-001"
        this.apiServer.mockEndpoint(
            MockEndpoint("/api/resumes", "POST")
                .respondWith(MockResponse.success(JsonObject.from([
                    "id": resumeId,
                    "title": "AutoSave Resume"
                ])))
        )

        // Act
        this.resumeViewModel.enableAutoSave()
        this.resumeViewModel.createNewResume("AutoSave Resume")

        // 修改个人信息
        let personalInfo = TestDataFactory.createCompletePersonalInfo()
        this.resumeViewModel.updatePersonalInfo(personalInfo)

        // 等待自动保存
        Thread.sleep(200)

        // Assert
        Assert.assertTrue(this.resumeViewModel.hasUnsavedChanges() == false ||
                       this.apiServer.getRequestCount("/api/resumes/${resumeId}", "PUT") > 0,
                       "Should auto-save changes")
    }

    // ============================================
    // 多简历管理测试
    // ============================================

    @Test
    public func testCreateMultipleResumes(): Unit {
        // 测试创建多个简历

        // Arrange
        this.apiServer.mockEndpoint(
            MockEndpoint("/api/resumes", "POST")
                .respondWith(MockResponse.success(JsonObject.from([
                    "id": "multi-resume-001",
                    "title": "First Resume"
                ])))
        )

        // Act - 创建第一个简历
        let firstResult = this.resumeViewModel.createNewResume("First Resume")
        Assert.assertTrue(firstResult.isSuccess())

        // 创建第二个简历
        this.apiServer.mockEndpoint(
            MockEndpoint("/api/resumes", "POST")
                .respondWith(MockResponse.success(JsonObject.from([
                    "id": "multi-resume-002",
                    "title": "Second Resume"
                ])))
        )

        let secondResult = this.resumeViewModel.createNewResume("Second Resume")
        Assert.assertTrue(secondResult.isSuccess())

        // Assert
        Assert.assertEquals(2, this.apiServer.getRequestCount("/api/resumes", "POST"))
    }

    // ============================================
    // 撤销/重做测试
    // ============================================

    @Test
    public func testUndoRedoDuringCreation(): Unit {
        // 测试创建过程中的撤销/重做

        // Arrange
        this.resumeViewModel.initializeNewResume()

        // Act - 添加个人信息
        let personalInfo1 = TestDataFactory.createCompletePersonalInfo()
        this.resumeViewModel.updatePersonalInfo(personalInfo1)

        // 添加教育经历
        let education = TestDataFactory.createBachelorEducation()
        this.resumeViewModel.addEducation(education)

        // 撤销
        this.resumeViewModel.undo()
        Assert.assertEquals(0, this.resumeViewModel.getCurrentResume().education.size,
                          "Education should be removed after undo")

        // 重做
        this.resumeViewModel.redo()
        Assert.assertEquals(1, this.resumeViewModel.getCurrentResume().education.size,
                          "Education should be restored after redo")
    }

    // ============================================
    // 草稿保存测试
    // ============================================

    @Test
    public func testSaveAsDraft(): Unit {
        // 测试保存为草稿

        // Arrange
        let resumeId = "draft-resume-001"
        this.apiServer.mockEndpoint(
            MockEndpoint("/api/resumes", "POST")
                .respondWith(MockResponse.success(JsonObject.from([
                    "id": resumeId,
                    "title": "Draft Resume"
                ])))
        )

        this.apiServer.mockEndpoint(
            MockEndpoint("/api/resumes/${resumeId}/draft", "PUT")
                .respondWith(MockResponse.success(JsonObject.from([
                    "success": true,
                    "status": "draft"
                ])))
        )

        // Act
        this.resumeViewModel.createNewResume("Draft Resume")
        let draftResult = this.resumeViewModel.saveAsDraft()

        // Assert
        Assert.assertTrue(draftResult.isSuccess(), "Should save as draft")
        Assert.assertTrue(
            this.apiServer.verifyRequest("/api/resumes/${resumeId}/draft", "PUT"),
            "Should call draft endpoint"
        )
    }
}

// ============================================
// Mock 类定义
// ============================================

/// Mock HTTP Client for Resume Flow Tests
internal class MockHttpClientForResumeFlow {
    private let apiServer: TestApiServer

    public init(apiServer: TestApiServer) {
        this.apiServer = apiServer
    }

    public func post(url: String, body: String): MockResponse {
        return this.apiServer.getResponse("POST", url, body)
    }

    public func put(url: String, body: String): MockResponse {
        return this.apiServer.getResponse("PUT", url, body)
    }

    public func get(url: String): MockResponse {
        return this.apiServer.getResponse("GET", url)
    }
}

/// Mock Token Storage for Resume Flow Tests
internal class MockTokenStorageForResumeFlow {
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
