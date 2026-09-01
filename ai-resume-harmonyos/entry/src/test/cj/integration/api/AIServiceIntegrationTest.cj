package test.integration.api

import std.unittest.*
import std.unittest.mock.*
import entry.src.services.*
import entry.src.models.*
import test.integration.data.TestDataFactory
import test.integration.mock.*

/// AI 服务集成测试
/// 测试 AIService 与 Mock API 服务器的集成
@TestCase
public class AIServiceIntegrationTest {
    private let apiServer: TestApiServer
    private let aiService: AIService
    private let mockHttpClient: MockHttpClientForAI
    private let mockTokenStorage: MockTokenStorageForAI

    public init() {
        // 初始化 Mock API 服务器
        this.apiServer = TestApiServer()

        // 初始化 Mock Token Storage
        this.mockTokenStorage = MockTokenStorageForAI()
        this.mockTokenStorage.setToken(TestDataFactory.createValidAuthToken())

        // 初始化 Mock HTTP Client
        this.mockHttpClient = MockHttpClientForAI(this.apiServer)

        // 创建 AIService 实例
        this.aiService = AIService(
            httpClient: this.mockHttpClient,
            tokenStorage: this.mockTokenStorage
        )
    }

    // ============================================
    // 生成个人简介测试
    // ============================================

    @Test
    public func testGenerateSummarySuccess(): Unit {
        // Arrange
        let resume = TestDataFactory.createCompleteResume()
        let expectedSummary = "Experienced software engineer with expertise in mobile development and a passion for creating user-friendly applications."

        this.apiServer.mockEndpoint(
            MockEndpoint("/api/ai/generate-summary", "POST")
                .respondWith(MockResponse.success(JsonObject.from([
                    "summary": expectedSummary
                ])))
        )

        // Act
        let result = this.aiService.generateSummary(resume)

        // Assert
        Assert.assertTrue(result.isSuccess(), "Should generate summary successfully")
        let summary = result.getData()
        Assert.assertEquals(expectedSummary, summary)

        // 验证 API 请求
        Assert.assertTrue(
            this.apiServer.verifyRequest("/api/ai/generate-summary", "POST"),
            "Should call generate summary endpoint"
        )
    }

    @Test
    public func testGenerateSummaryWithMinimalResume(): Unit {
        // Arrange
        let minimalResume = TestDataFactory.createMinimalResume()

        this.apiServer.mockEndpoint(
            MockEndpoint("/api/ai/generate-summary", "POST")
                .respondWith(MockResponse.success(JsonObject.from([
                    "summary": "Professional with diverse experience."
                ])))
        )

        // Act
        let result = this.aiService.generateSummary(minimalResume)

        // Assert
        Assert.assertTrue(result.isSuccess())
        Assert.assertFalse(result.getData().isEmpty())
    }

    @Test
    public func testGenerateSummaryWithError(): Unit {
        // Arrange
        let resume = TestDataFactory.createCompleteResume()
        this.apiServer.mockEndpoint(
            MockEndpoint("/api/ai/generate-summary", "POST")
                .respondWith(MockResponse.error(500, "AI service unavailable"))
        )

        // Act
        let result = this.aiService.generateSummary(resume)

        // Assert
        Assert.assertTrue(result.isFailure(), "Should handle AI service error")
        let error = result.getError()
        Assert.assertEquals(500, error.getCode())
    }

    // ============================================
    // 优化工作经历测试
    // ============================================

    @Test
    public func testOptimizeExperienceSuccess(): Unit {
        // Arrange
        let experience = TestDataFactory.createSeniorExperience()
        let expectedOptimized = "Led the development of mobile applications, resulting in 100,000+ downloads and a 4.8-star rating. Mentored junior developers and implemented best practices that improved code quality by 40%."

        this.apiServer.mockEndpoint(
            MockEndpoint("/api/ai/optimize-experience", "POST")
                .respondWith(MockResponse.success(JsonObject.from([
                    "optimizedDescription": expectedOptimized
                ])))
        )

        // Act
        let result = this.aiService.optimizeExperience(experience)

        // Assert
        Assert.assertTrue(result.isSuccess(), "Should optimize experience successfully")
        let optimized = result.getData()
        Assert.assertEquals(expectedOptimized, optimized)

        // 验证 API 请求
        Assert.assertTrue(
            this.apiServer.verifyRequest("/api/ai/optimize-experience", "POST"),
            "Should call optimize experience endpoint"
        )
    }

    @Test
    public func testOptimizeExperienceWithJuniorExperience(): Unit {
        // Arrange
        let juniorExperience = TestDataFactory.createJuniorExperience()

        this.apiServer.mockEndpoint(
            MockEndpoint("/api/ai/optimize-experience", "POST")
                .respondWith(MockResponse.success(JsonObject.from([
                    "optimizedDescription": "Developed and maintained full-stack applications, serving over 1 million requests. Implemented CI/CD pipeline that reduced deployment time by 60%."
                ])))
        )

        // Act
        let result = this.aiService.optimizeExperience(juniorExperience)

        // Assert
        Assert.assertTrue(result.isSuccess())
        let optimized = result.getData()
        Assert.assertTrue(optimized.contains("CI/CD"))
    }

    @Test
    public func testOptimizeExperienceWithoutAuth(): Unit {
        // Arrange
        let experience = TestDataFactory.createSeniorExperience()
        this.mockTokenStorage.setToken(null)

        // Act
        let result = this.aiService.optimizeExperience(experience)

        // Assert
        Assert.assertTrue(result.isFailure(), "Should fail without authentication")
    }

    // ============================================
    // 生成技能建议测试
    // ============================================

    @Test
    public func testGenerateSkillsSuccess(): Unit {
        // Arrange
        let resume = TestDataFactory.createCompleteResume()
        let expectedSkills = ArrayList<String>([
            "Mobile Development",
            "Team Leadership",
            "Agile Methodology",
            "Code Review",
            "Performance Optimization"
        ])

        this.apiServer.mockEndpoint(
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

        // Act
        let result = this.aiService.generateSkills(resume)

        // Assert
        Assert.assertTrue(result.isSuccess(), "Should generate skills successfully")
        let skills = result.getData()
        Assert.assertEquals(expectedSkills.size, skills.size)
        for (i in 0..expectedSkills.size) {
            Assert.assertEquals(expectedSkills[i], skills[i])
        }
    }

    @Test
    public func testGenerateSkillsForSpecificRole(): Unit {
        // Arrange
        let resume = TestDataFactory.createCompleteResume()

        this.apiServer.mockEndpoint(
            MockEndpoint("/api/ai/generate-skills", "POST")
                .respondWith(MockResponse.success(JsonObject.from([
                    "skills": JsonArray.from([
                        "HarmonyOS Development",
                        "ArkUI Framework",
                        "Cangjie Language",
                        "Mobile UI Design",
                        "State Management"
                    ])
                ])))
        )

        // Act
        let result = this.aiService.generateSkills(resume)

        // Assert
        Assert.assertTrue(result.isSuccess())
        let skills = result.getData()
        Assert.assertTrue(skills.contains("HarmonyOS Development"))
    }

    // ============================================
    // 生成项目描述测试
    // ============================================

    @Test
    public func testGenerateProjectDescriptionSuccess(): Unit {
        // Arrange
        let project = TestDataFactory.createAIResumeProject()
        let expectedDescription = "Developed an AI-powered resume building application for HarmonyOS, implementing intelligent content generation and template customization features. Achieved 10,000+ active users with a 4.8-star rating."

        this.apiServer.mockEndpoint(
            MockEndpoint("/api/ai/generate-project-description", "POST")
                .respondWith(MockResponse.success(JsonObject.from([
                    "description": expectedDescription
                ])))
        )

        // Act
        let result = this.aiService.generateProjectDescription(project)

        // Assert
        Assert.assertTrue(result.isSuccess(), "Should generate project description successfully")
        let description = result.getData()
        Assert.assertEquals(expectedDescription, description)
    }

    @Test
    public func testGenerateProjectDescriptionWithMinimalInfo(): Unit {
        // Arrange
        let minimalProject = Project(
            id = "proj-minimal",
            name = "Simple Project",
            description = "",
            role = "Developer",
            startDate = "2024-01",
            endDate = "2024-02",
            technologies = ArrayList<String>(["TypeScript"]),
            achievements = ArrayList<String>()
        )

        this.apiServer.mockEndpoint(
            MockEndpoint("/api/ai/generate-project-description", "POST")
                .respondWith(MockResponse.success(JsonObject.from([
                    "description": "Developed Simple Project using TypeScript."
                ])))
        )

        // Act
        let result = this.aiService.generateProjectDescription(minimalProject)

        // Assert
        Assert.assertTrue(result.isSuccess())
    }

    // ============================================
    // 批量优化测试
    // ============================================

    @Test
    public func testBatchOptimizeExperiences(): Unit {
        // Arrange
        let experiences = TestDataFactory.createExperienceList()
        let expectedOptimized = ArrayList<String>()

        for (experience in experiences) {
            expectedOptimized.add("Optimized: ${experience.description}")
        }

        this.apiServer.mockEndpoint(
            MockEndpoint("/api/ai/optimize-experience", "POST")
                .respondWith(MockResponse.success(JsonObject.from([
                    "optimizedDescription": "Optimized description"
                ])))
        )

        // Act
        var results = ArrayList<Result<String, ApiError>>()
        for (experience in experiences) {
            results.append(this.aiService.optimizeExperience(experience))
        }

        // Assert
        for (result in results) {
            Assert.assertTrue(result.isSuccess(), "Each optimization should succeed")
        }

        // 验证 API 调用次数
        Assert.assertEquals(
            experiences.size,
            this.apiServer.getRequestCount("/api/ai/optimize-experience", "POST")
        )
    }

    // ============================================
    // 错误处理测试
    // ============================================

    @Test
    public func testHandleAIServiceTimeout(): Unit {
        // Arrange
        let resume = TestDataFactory.createCompleteResume()
        this.apiServer.mockEndpoint(
            MockEndpoint("/api/ai/generate-summary", "POST")
                .respondWith(MockResponse.timeout())
        )

        // Act
        let result = this.aiService.generateSummary(resume)

        // Assert
        Assert.assertTrue(result.isFailure(), "Should handle timeout")
    }

    @Test
    public func testHandleInvalidResumeData(): Unit {
        // Arrange
        let invalidResume = Resume(
            id = "",
            userId = "",
            title = "",
            personalInfo = PersonalInfo("", "", "", "", "", "", ""),
            education = ArrayList(),
            experience = ArrayList(),
            skills = ArrayList(),
            projects = ArrayList(),
            createdAt = DateTime.now(),
            updatedAt = DateTime.now()
        )

        this.apiServer.mockEndpoint(
            MockEndpoint("/api/ai/generate-summary", "POST")
                .respondWith(MockResponse.error(400, "Invalid resume data"))
        )

        // Act
        let result = this.aiService.generateSummary(invalidResume)

        // Assert
        Assert.assertTrue(result.isFailure(), "Should validate resume data")
    }

    @Test
    public func testHandleRateLimitError(): Unit {
        // Arrange
        let experience = TestDataFactory.createSeniorExperience()
        this.apiServer.mockEndpoint(
            MockEndpoint("/api/ai/optimize-experience", "POST")
                .respondWith(MockResponse.error(429, "Rate limit exceeded"))
        )

        // Act
        let result = this.aiService.optimizeExperience(experience)

        // Assert
        Assert.assertTrue(result.isFailure(), "Should handle rate limit")
        let error = result.getError()
        Assert.assertEquals(429, error.getCode())
    }

    // ============================================
    // AI 服务集成场景测试
    // ============================================

    @Test
    public func testCompleteAIEnhancementFlow(): Unit {
        // 测试完整的 AI 增强流程

        // 1. 生成个人简介
        let resume = TestDataFactory.createCompleteResume()

        this.apiServer.mockEndpoint(
            MockEndpoint("/api/ai/generate-summary", "POST")
                .respondWith(MockResponse.success(JsonObject.from([
                    "summary": "AI-generated professional summary"
                ])))
        )

        let summaryResult = this.aiService.generateSummary(resume)
        Assert.assertTrue(summaryResult.isSuccess())

        // 2. 优化工作经历
        this.apiServer.mockEndpoint(
            MockEndpoint("/api/ai/optimize-experience", "POST")
                .respondWith(MockResponse.success(JsonObject.from([
                    "optimizedDescription": "AI-optimized experience"
                ])))
        )

        let optimizeResult = this.aiService.optimizeExperience(resume.experience[0])
        Assert.assertTrue(optimizeResult.isSuccess())

        // 3. 生成技能建议
        this.apiServer.mockEndpoint(
            MockEndpoint("/api/ai/generate-skills", "POST")
                .respondWith(MockResponse.success(JsonObject.from([
                    "skills": JsonArray.from(["AI Suggested Skill 1", "AI Suggested Skill 2"])
                ])))
        )

        let skillsResult = this.aiService.generateSkills(resume)
        Assert.assertTrue(skillsResult.isSuccess())

        // 验证所有 AI 功能都已调用
        Assert.assertTrue(this.apiServer.verifyRequest("/api/ai/generate-summary", "POST"))
        Assert.assertTrue(this.apiServer.verifyRequest("/api/ai/optimize-experience", "POST"))
        Assert.assertTrue(this.apiServer.verifyRequest("/api/ai/generate-skills", "POST"))
    }
}

// ============================================
// Mock 类定义
// ============================================

/// Mock HTTP Client for AI Service
internal class MockHttpClientForAI {
    private let apiServer: TestApiServer

    public init(apiServer: TestApiServer) {
        this.apiServer = apiServer
    }

    public func post(url: String, body: String): MockResponse {
        return this.apiServer.getResponse("POST", url, body)
    }
}

/// Mock Token Storage for AI Service
internal class MockTokenStorageForAI {
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
