package test.integration.api

import std.unittest.*
import std.unittest.mock.*
import entry.src.services.*
import entry.src.models.*
import test.integration.data.TestDataFactory
import test.integration.mock.*

/// 简历服务集成测试
/// 测试 ResumeService 与 Mock API 服务器的集成
@TestCase
public class ResumeServiceIntegrationTest {
    private let apiServer: TestApiServer
    private let resumeService: ResumeService
    private let mockHttpClient: MockHttpClientForResume
    private let mockTokenStorage: MockTokenStorageForResume

    public init() {
        // 初始化 Mock API 服务器
        this.apiServer = TestApiServer()

        // 初始化 Mock Token Storage（模拟已登录状态）
        this.mockTokenStorage = MockTokenStorageForResume()
        this.mockTokenStorage.setToken(TestDataFactory.createValidAuthToken())

        // 初始化 Mock HTTP Client
        this.mockHttpClient = MockHttpClientForResume(this.apiServer)

        // 创建 ResumeService 实例
        this.resumeService = ResumeService(
            httpClient: this.mockHttpClient,
            tokenStorage: this.mockTokenStorage
        )
    }

    // ============================================
    // 获取简历列表测试
    // ============================================

    @Test
    public func testGetResumeListSuccess(): Unit {
        // Arrange
        let expectedResumes = ArrayList<Resume>()
        expectedResumes.append(TestDataFactory.createCompleteResume())
        expectedResumes.append(TestDataFactory.createMinimalResume())

        this.apiServer.mockEndpoint(
            MockEndpoint("/api/resumes", "GET")
                .respondWith(MockResponse.success(JsonObject.from([
                    "resumes": JsonArray.from([
                        JsonObject.from([
                            "id": expectedResumes[0].id,
                            "title": expectedResumes[0].title,
                            "updatedAt": "2024-03-30T10:00:00Z"
                        ]),
                        JsonObject.from([
                            "id": expectedResumes[1].id,
                            "title": expectedResumes[1].title,
                            "updatedAt": "2024-03-29T15:30:00Z"
                        ])
                    ])
                ])))
        )

        // Act
        let result = this.resumeService.getResumeList()

        // Assert
        Assert.assertTrue(result.isSuccess(), "Should get resume list successfully")
        let resumes = result.getData()
        Assert.assertEquals(2, resumes.size)
        Assert.assertEquals(expectedResumes[0].id, resumes[0].id)
        Assert.assertEquals(expectedResumes[1].id, resumes[1].id)

        // 验证 API 请求
        Assert.assertTrue(
            this.apiServer.verifyRequest("/api/resumes", "GET"),
            "Should call resumes list endpoint"
        )
    }

    @Test
    public func testGetEmptyResumeList(): Unit {
        // Arrange
        this.apiServer.mockEndpoint(
            MockEndpoint("/api/resumes", "GET")
                .respondWith(MockResponse.success(JsonObject.from([
                    "resumes": JsonArray.from([])
                ])))
        )

        // Act
        let result = this.resumeService.getResumeList()

        // Assert
        Assert.assertTrue(result.isSuccess())
        let resumes = result.getData()
        Assert.assertEquals(0, resumes.size)
    }

    @Test
    public func testGetResumeListWithoutAuth(): Unit {
        // Arrange
        this.mockTokenStorage.setToken(null)

        // Act
        let result = this.resumeService.getResumeList()

        // Assert
        Assert.assertTrue(result.isFailure(), "Should fail without authentication")
    }

    // ============================================
    // 获取单个简历测试
    // ============================================

    @Test
    public func testGetResumeByIdSuccess(): Unit {
        // Arrange
        let expectedResume = TestDataFactory.createCompleteResume()
        let resumeId = expectedResume.id

        this.apiServer.mockEndpoint(
            MockEndpoint("/api/resumes/${resumeId}", "GET")
                .respondWith(MockResponse.success(JsonObject.from([
                    "id": expectedResume.id,
                    "title": expectedResume.title,
                    "personalInfo": JsonObject.from([
                        "name": expectedResume.personalInfo.name,
                        "email": expectedResume.personalInfo.email
                    ]),
                    "education": JsonArray.from([]),
                    "experience": JsonArray.from([]),
                    "skills": JsonArray.from([]),
                    "projects": JsonArray.from([])
                ])))
        )

        // Act
        let result = this.resumeService.getResumeById(resumeId)

        // Assert
        Assert.assertTrue(result.isSuccess(), "Should get resume by id")
        let resume = result.getData()
        Assert.assertEquals(resumeId, resume.id)
        Assert.assertEquals(expectedResume.title, resume.title)
    }

    @Test
    public func testGetResumeByIdNotFound(): Unit {
        // Arrange
        let nonExistentId = "resume-999"
        this.apiServer.mockEndpoint(
            MockEndpoint("/api/resumes/${nonExistentId}", "GET")
                .respondWith(MockResponse.error(404, "Resume not found"))
        )

        // Act
        let result = this.resumeService.getResumeById(nonExistentId)

        // Assert
        Assert.assertTrue(result.isFailure(), "Should fail with 404")
        let error = result.getError()
        Assert.assertEquals(404, error.getCode())
    }

    // ============================================
    // 创建简历测试
    // ============================================

    @Test
    public func testCreateResumeSuccess(): Unit {
        // Arrange
        let newResume = TestDataFactory.createMinimalResume()
        let expectedId = "newly-created-resume-001"

        this.apiServer.mockEndpoint(
            MockEndpoint("/api/resumes", "POST")
                .respondWith(MockResponse.success(JsonObject.from([
                    "id": expectedId,
                    "title": newResume.title,
                    "createdAt": "2024-03-30T10:00:00Z"
                ])))
        )

        // Act
        let result = this.resumeService.createResume(newResume)

        // Assert
        Assert.assertTrue(result.isSuccess(), "Should create resume successfully")
        let createdResume = result.getData()
        Assert.assertEquals(expectedId, createdResume.id)
        Assert.assertEquals(newResume.title, createdResume.title)

        // 验证 API 请求
        Assert.assertTrue(
            this.apiServer.verifyRequest("/api/resumes", "POST"),
            "Should call create endpoint"
        )
    }

    @Test
    public func testCreateResumeWithInvalidData(): Unit {
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
            MockEndpoint("/api/resumes", "POST")
                .respondWith(MockResponse.error(400, "Invalid resume data"))
        )

        // Act
        let result = this.resumeService.createResume(invalidResume)

        // Assert
        Assert.assertTrue(result.isFailure(), "Should fail with invalid data")
    }

    @Test
    public func testCreateResumeWithoutAuth(): Unit {
        // Arrange
        let resume = TestDataFactory.createMinimalResume()
        this.mockTokenStorage.setToken(null)

        // Act
        let result = this.resumeService.createResume(resume)

        // Assert
        Assert.assertTrue(result.isFailure(), "Should fail without authentication")
    }

    // ============================================
    // 更新简历测试
    // ============================================

    @Test
    public func testUpdateResumeSuccess(): Unit {
        // Arrange
        let existingResume = TestDataFactory.createCompleteResume()
        let updatedResume = existingResume.copy()
        updatedResume.title = "Updated Software Engineer Resume"

        this.apiServer.mockEndpoint(
            MockEndpoint("/api/resumes/${existingResume.id}", "PUT")
                .respondWith(MockResponse.success(JsonObject.from([
                    "id": existingResume.id,
                    "title": updatedResume.title,
                    "updatedAt": "2024-03-30T11:00:00Z"
                ])))
        )

        // Act
        let result = this.resumeService.updateResume(updatedResume)

        // Assert
        Assert.assertTrue(result.isSuccess(), "Should update resume successfully")
        let resume = result.getData()
        Assert.assertEquals(updatedResume.title, resume.title)

        // 验证 API 请求
        Assert.assertTrue(
            this.apiServer.verifyRequest("/api/resumes/${existingResume.id}", "PUT"),
            "Should call update endpoint"
        )
    }

    @Test
    public func testUpdateResumeNotFound(): Unit {
        // Arrange
        let nonExistentResume = TestDataFactory.createMinimalResume()
        nonExistentResume.id = "resume-999"

        this.apiServer.mockEndpoint(
            MockEndpoint("/api/resumes/${nonExistentResume.id}", "PUT")
                .respondWith(MockResponse.error(404, "Resume not found"))
        )

        // Act
        let result = this.resumeService.updateResume(nonExistentResume)

        // Assert
        Assert.assertTrue(result.isFailure(), "Should fail with 404")
    }

    @Test
    public func testUpdateResumeSection(): Unit {
        // Arrange
        let resume = TestDataFactory.createCompleteResume()
        let newEducation = TestDataFactory.createMasterEducation()

        this.apiServer.mockEndpoint(
            MockEndpoint("/api/resumes/${resume.id}/education", "PUT")
                .respondWith(MockResponse.success(JsonObject.from([
                    "success": true,
                    "education": JsonObject.from([
                        "id": newEducation.id,
                        "school": newEducation.school,
                        "degree": newEducation.degree
                    ])
                ])))
        )

        // Act
        let result = this.resumeService.addEducation(resume.id, newEducation)

        // Assert
        Assert.assertTrue(result.isSuccess(), "Should add education successfully")
    }

    // ============================================
    // 删除简历测试
    // ============================================

    @Test
    public func testDeleteResumeSuccess(): Unit {
        // Arrange
        let resumeId = "resume-to-delete-001"

        this.apiServer.mockEndpoint(
            MockEndpoint("/api/resumes/${resumeId}", "DELETE")
                .respondWith(MockResponse.success(JsonObject.from([
                    "message": "Resume deleted successfully"
                ])))
        )

        // Act
        let result = this.resumeService.deleteResume(resumeId)

        // Assert
        Assert.assertTrue(result.isSuccess(), "Should delete resume successfully")

        // 验证 API 请求
        Assert.assertTrue(
            this.apiServer.verifyRequest("/api/resumes/${resumeId}", "DELETE"),
            "Should call delete endpoint"
        )
    }

    @Test
    public func testDeleteResumeNotFound(): Unit {
        // Arrange
        let nonExistentId = "resume-999"
        this.apiServer.mockEndpoint(
            MockEndpoint("/api/resumes/${nonExistentId}", "DELETE")
                .respondWith(MockResponse.error(404, "Resume not found"))
        )

        // Act
        let result = this.resumeService.deleteResume(nonExistentId)

        // Assert
        Assert.assertTrue(result.isFailure(), "Should fail with 404")
    }

    @Test
    public func testDeleteResumeWithoutAuth(): Unit {
        // Arrange
        this.mockTokenStorage.setToken(null)

        // Act
        let result = this.resumeService.deleteResume("resume-001")

        // Assert
        Assert.assertTrue(result.isFailure(), "Should fail without authentication")
    }

    // ============================================
    // CRUD 集成场景测试
    // ============================================

    @Test
    public func testCompleteResumeCRUDFlow(): Unit {
        // 测试完整的 CRUD 流程：创建 → 读取 → 更新 → 删除

        // 1. 创建简历
        let newResume = TestDataFactory.createMinimalResume()
        let createdId = "crud-resume-001"

        this.apiServer.mockEndpoint(
            MockEndpoint("/api/resumes", "POST")
                .respondWith(MockResponse.success(JsonObject.from([
                    "id": createdId,
                    "title": newResume.title
                ])))
        )

        let createResult = this.resumeService.createResume(newResume)
        Assert.assertTrue(createResult.isSuccess(), "Create should succeed")

        // 2. 读取简历
        this.apiServer.mockEndpoint(
            MockEndpoint("/api/resumes/${createdId}", "GET")
                .respondWith(MockResponse.success(JsonObject.from([
                    "id": createdId,
                    "title": newResume.title
                ])))
        )

        let getResult = this.resumeService.getResumeById(createdId)
        Assert.assertTrue(getResult.isSuccess(), "Get should succeed")
        Assert.assertEquals(createdId, getResult.getData().id)

        // 3. 更新简历
        let updatedResume = newResume.copy()
        updatedResume.id = createdId
        updatedResume.title = "Updated Title"

        this.apiServer.mockEndpoint(
            MockEndpoint("/api/resumes/${createdId}", "PUT")
                .respondWith(MockResponse.success(JsonObject.from([
                    "id": createdId,
                    "title": updatedResume.title
                ])))
        )

        let updateResult = this.resumeService.updateResume(updatedResume)
        Assert.assertTrue(updateResult.isSuccess(), "Update should succeed")
        Assert.assertEquals(updatedResume.title, updateResult.getData().title)

        // 4. 删除简历
        this.apiServer.mockEndpoint(
            MockEndpoint("/api/resumes/${createdId}", "DELETE")
                .respondWith(MockResponse.success(JsonObject.from([
                    "message": "Deleted"
                ])))
        )

        let deleteResult = this.resumeService.deleteResume(createdId)
        Assert.assertTrue(deleteResult.isSuccess(), "Delete should succeed")

        // 验证完整的请求序列
        Assert.assertTrue(this.apiServer.verifyRequest("/api/resumes", "POST"))
        Assert.assertTrue(this.apiServer.verifyRequest("/api/resumes/${createdId}", "GET"))
        Assert.assertTrue(this.apiServer.verifyRequest("/api/resumes/${createdId}", "PUT"))
        Assert.assertTrue(this.apiServer.verifyRequest("/api/resumes/${createdId}", "DELETE"))
    }

    // ============================================
    // 并发操作测试
    // ============================================

    @Test
    public func testConcurrentResumeUpdates(): Unit {
        // Arrange
        let resumeId = "concurrent-resume-001"
        let resume = TestDataFactory.createCompleteResume()
        resume.id = resumeId

        this.apiServer.mockEndpoint(
            MockEndpoint("/api/resumes/${resumeId}", "PUT")
                .respondWith(MockResponse.success(JsonObject.from([
                    "id": resumeId,
                    "title": "Concurrently Updated"
                ])))
        )

        // Act - 模拟多次更新
        var results = ArrayList<Result<Resume, ApiError>>()
        for (i in 0..3) {
            let updatedResume = resume.copy()
            updatedResume.title = "Update ${i}"
            results.append(this.resumeService.updateResume(updatedResume))
        }

        // Assert
        for (result in results) {
            Assert.assertTrue(result.isSuccess(), "Each update should succeed")
        }
    }

    // ============================================
    // 错误处理测试
    // ============================================

    @Test
    public func testHandleNetworkError(): Unit {
        // Arrange
        this.apiServer.setEnabled(false)

        // Act
        let result = this.resumeService.getResumeList()

        // Assert
        Assert.assertTrue(result.isFailure(), "Should handle network error")
    }

    @Test
    public func testHandleServerError(): Unit {
        // Arrange
        this.apiServer.mockEndpoint(
            MockEndpoint("/api/resumes", "GET")
                .respondWith(MockResponse.error(500, "Internal Server Error"))
        )

        // Act
        let result = this.resumeService.getResumeList()

        // Assert
        Assert.assertTrue(result.isFailure(), "Should handle server error")
        let error = result.getError()
        Assert.assertEquals(500, error.getCode())
    }

    @Test
    public func testHandleMalformedResponse(): Unit {
        // Arrange
        this.apiServer.mockEndpoint(
            MockEndpoint("/api/resumes", "GET")
                .respondWith(MockResponse.success(JsonObject.from([
                    "invalid": "response structure"
                ])))
        )

        // Act
        let result = this.resumeService.getResumeList()

        // Assert
        Assert.assertTrue(result.isFailure(), "Should handle malformed response")
    }
}

// ============================================
// Mock 类定义
// ============================================

/// Mock HTTP Client for Resume Service
internal class MockHttpClientForResume {
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

/// Mock Token Storage for Resume Service
internal class MockTokenStorageForResume {
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
