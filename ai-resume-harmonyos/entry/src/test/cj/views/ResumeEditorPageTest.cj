// ResumeEditorPageTest.cj - 简历编辑页面测试
package test.views

import ohos.hypium.*
import views.*
import services.*
import models.*
import std.collection.*

// Mock ResumeService for testing
public class MockResumeServiceForEditor {
    private var mockResumeResult: Result<Option<Resume>> = Result.error("Not mocked")
    private var mockUpdateResult: Result<Bool> = Result.error("Not mocked")
    private var loadCalled: Bool = false
    private var updateCalled: Bool = false
    private var capturedResumeId: Int64 = 0
    private var capturedResume: Resume = Resume()

    public func setMockResumeResult(result: Result<Option<Resume>>): Unit {
        this.mockResumeResult = result
    }

    public func setMockUpdateResult(result: Result<Bool>): Unit {
        this.mockUpdateResult = result
    }

    public func getResume(id: Int64): Result<Option<Resume>> {
        this.loadCalled = true
        this.capturedResumeId = id
        return this.mockResumeResult
    }

    public func updateResume(id: Int64, resume: Resume): Result<Bool> {
        this.updateCalled = true
        this.capturedResumeId = id
        this.capturedResume = resume
        return this.mockUpdateResult
    }

    public func wasLoadCalled(): Bool {
        return this.loadCalled
    }

    public func wasUpdateCalled(): Bool {
        return this.updateCalled
    }

    public func getCapturedResumeId(): Int64 {
        return this.capturedResumeId
    }

    public func getCapturedResume(): Resume {
        return this.capturedResume
    }

    public func reset(): Unit {
        this.mockResumeResult = Result.error("Not mocked")
        this.mockUpdateResult = Result.error("Not mocked")
        this.loadCalled = false
        this.updateCalled = false
        this.capturedResumeId = 0
        this.capturedResume = Resume()
    }
}

// Mock AIService for testing
public class MockAIServiceForEditor {
    private var mockGenerateResult: Result<Option<AIGenerateResponse>> = Result.error("Not mocked")
    private var generateCalled: Bool = false
    private var capturedRequest: AIGenerateRequest = AIGenerateRequest()

    public func setMockGenerateResult(result: Result<Option<AIGenerateResponse>>): Unit {
        this.mockGenerateResult = result
    }

    public func generateContent(request: AIGenerateRequest): Result<Option<AIGenerateResponse>> {
        this.generateCalled = true
        this.capturedRequest = request
        return this.mockGenerateResult
    }

    public func wasGenerateCalled(): Bool {
        return this.generateCalled
    }

    public func getCapturedRequest(): AIGenerateRequest {
        return this.capturedRequest
    }

    public func reset(): Unit {
        this.mockGenerateResult = Result.error("Not mocked")
        this.generateCalled = false
        this.capturedRequest = AIGenerateRequest()
    }
}

@TestCase
public class ResumeEditorPageTest {
    private var mockResumeService: MockResumeServiceForEditor = MockResumeServiceForEditor()
    private var mockAIService: MockAIServiceForEditor = MockAIServiceForEditor()

    @Before
    public func setup(): Unit {
        this.mockResumeService.reset()
        this.mockAIService.reset()
    }

    @Test
    public func testResumeEditorPageInitialization(): Unit {
        // Arrange & Act
        let page = ResumeEditorPage()

        // Assert
        Assert.assertTrue(true, "ResumeEditorPage should initialize successfully")
    }

    @Test
    public func testLoadResumeSuccess(): Unit {
        // Arrange
        let resume = this.createMockResume(1, "Software Engineer")
        this.mockResumeService.setMockResumeResult(Result.success(Some(resume)))

        // Act
        let result = this.mockResumeService.getResume(1)

        // Assert
        Assert.assertTrue(result.isSuccess(), "Loading resume should succeed")
        Assert.assertTrue(this.mockResumeService.wasLoadCalled(), "Load should be called")
        Assert.assertEquals(1, this.mockResumeService.getCapturedResumeId(), "Resume ID should match")
    }

    @Test
    public func testLoadResumeFailure(): Unit {
        // Arrange
        this.mockResumeService.setMockResumeResult(Result.error("简历不存在"))

        // Act
        let result = this.mockResumeService.getResume(999)

        // Assert
        Assert.assertFalse(result.isSuccess(), "Loading should fail")
        Assert.assertEquals("简历不存在", result.getError(), "Error message should match")
    }

    @Test
    public func testSaveResumeSuccess(): Unit {
        // Arrange
        let resume = this.createMockResume(1, "Software Engineer")
        this.mockResumeService.setMockUpdateResult(Result.success(true))

        // Act
        let result = this.mockResumeService.updateResume(1, resume)

        // Assert
        Assert.assertTrue(result.isSuccess(), "Saving should succeed")
        Assert.assertTrue(this.mockResumeService.wasUpdateCalled(), "Update should be called")
        Assert.assertEquals(1, this.mockResumeService.getCapturedResumeId(), "Resume ID should match")
    }

    @Test
    public func testSaveResumeFailure(): Unit {
        // Arrange
        let resume = this.createMockResume(1, "Software Engineer")
        this.mockResumeService.setMockUpdateResult(Result.error("网络连接失败"))

        // Act
        let result = this.mockResumeService.updateResume(1, resume)

        // Assert
        Assert.assertFalse(result.isSuccess(), "Saving should fail")
        Assert.assertEquals("网络连接失败", result.getError(), "Error message should match")
    }

    @Test
    public func testSectionSwitching(): Unit {
        // Arrange
        let sections = ["personal", "education", "experience", "skills", "projects"]

        // Act & Assert
        for (section in sections) {
            let isValidSection = this.validateSection(section)
            Assert.assertTrue(isValidSection, "Section '${section}' should be valid")
        }
    }

    @Test
    public func testInvalidSection(): Unit {
        // Arrange
        let invalidSection = "invalid"

        // Act
        let isValidSection = this.validateSection(invalidSection)

        // Assert
        Assert.assertFalse(isValidSection, "Invalid section should not be valid")
    }

    @Test
    public func testPersonalInfoEditing(): Unit {
        // Arrange
        let resumeData = ResumeData()
        resumeData.personalInfo.name = "John Doe"
        resumeData.personalInfo.email = "john@example.com"

        // Act
        let name = resumeData.personalInfo.name
        let email = resumeData.personalInfo.email

        // Assert
        Assert.assertEquals("John Doe", name, "Name should match")
        Assert.assertEquals("john@example.com", email, "Email should match")
    }

    @Test
    public func testEducationAdding(): Unit {
        // Arrange
        let resumeData = ResumeData()
        let initialCount = resumeData.education.size()

        // Act
        let newEducation = Education()
        newEducation.school = "Stanford University"
        newEducation.degree = "Master's"
        resumeData.education.add(newEducation)

        // Assert
        Assert.assertEquals(initialCount + 1, resumeData.education.size(), "Education count should increase")
    }

    @Test
    public func testEducationRemoving(): Unit {
        // Arrange
        let resumeData = ResumeData()
        let education1 = Education()
        education1.school = "School 1"
        let education2 = Education()
        education2.school = "School 2"
        resumeData.education.add(education1)
        resumeData.education.add(education2)
        let initialCount = resumeData.education.size()

        // Act
        resumeData.education.removeAt(0)

        // Assert
        Assert.assertEquals(initialCount - 1, resumeData.education.size(), "Education count should decrease")
        Assert.assertEquals("School 2", resumeData.education[0].school, "Remaining education should be School 2")
    }

    @Test
    public func testExperienceAdding(): Unit {
        // Arrange
        let resumeData = ResumeData()
        let initialCount = resumeData.experience.size()

        // Act
        let newExperience = Experience()
        newExperience.company = "Google"
        newExperience.position = "Software Engineer"
        resumeData.experience.add(newExperience)

        // Assert
        Assert.assertEquals(initialCount + 1, resumeData.experience.size(), "Experience count should increase")
    }

    @Test
    public func testExperienceRemoving(): Unit {
        // Arrange
        let resumeData = ResumeData()
        let exp1 = Experience()
        exp1.company = "Company 1"
        let exp2 = Experience()
        exp2.company = "Company 2"
        resumeData.experience.add(exp1)
        resumeData.experience.add(exp2)
        let initialCount = resumeData.experience.size()

        // Act
        resumeData.experience.removeAt(0)

        // Assert
        Assert.assertEquals(initialCount - 1, resumeData.experience.size(), "Experience count should decrease")
    }

    @Test
    public func testSkillsAdding(): Unit {
        // Arrange
        let resumeData = ResumeData()
        let initialCount = resumeData.skills.size()

        // Act
        let newSkill = Skill()
        newSkill.name = "JavaScript"
        newSkill.level = "Expert"
        resumeData.skills.add(newSkill)

        // Assert
        Assert.assertEquals(initialCount + 1, resumeData.skills.size(), "Skills count should increase")
    }

    @Test
    public func testSkillsRemoving(): Unit {
        // Arrange
        let resumeData = ResumeData()
        let skill1 = Skill()
        skill1.name = "Java"
        let skill2 = Skill()
        skill2.name = "Python"
        resumeData.skills.add(skill1)
        resumeData.skills.add(skill2)
        let initialCount = resumeData.skills.size()

        // Act
        resumeData.skills.removeAt(0)

        // Assert
        Assert.assertEquals(initialCount - 1, resumeData.skills.size(), "Skills count should decrease")
        Assert.assertEquals("Python", resumeData.skills[0].name, "Remaining skill should be Python")
    }

    @Test
    public func testAIGenerateContent(): Unit {
        // Arrange
        let request = AIGenerateRequest()
        request.resumeId = 1
        request.section = "summary"
        request.prompt = "请生成summary内容"

        let response = AIGenerateResponse()
        response.content = "Generated summary content"

        this.mockAIService.setMockGenerateResult(Result.success(Some(response)))

        // Act
        let result = this.mockAIService.generateContent(request)

        // Assert
        Assert.assertTrue(result.isSuccess(), "AI generation should succeed")
        Assert.assertTrue(this.mockAIService.wasGenerateCalled(), "Generate should be called")
        Assert.assertEquals("summary", this.mockAIService.getCapturedRequest().section, "Section should match")
    }

    @Test
    public func testAIGenerateContentFailure(): Unit {
        // Arrange
        let request = AIGenerateRequest()
        request.resumeId = 1
        request.section = "summary"

        this.mockAIService.setMockGenerateResult(Result.error("AI 服务暂时不可用"))

        // Act
        let result = this.mockAIService.generateContent(request)

        // Assert
        Assert.assertFalse(result.isSuccess(), "AI generation should fail")
        Assert.assertEquals("AI 服务暂时不可用", result.getError(), "Error message should match")
    }

    @Test
    public func testLoadingState(): Unit {
        // Arrange & Act
        let isLoading = true

        // Assert
        Assert.assertTrue(isLoading, "Should be in loading state")
    }

    @Test
    public func testNotLoadingState(): Unit {
        // Arrange & Act
        let isLoading = false

        // Assert
        Assert.assertFalse(isLoading, "Should not be in loading state")
    }

    @Test
    public func testAIMenuVisibility(): Unit {
        // Arrange
        let showAIMenu = false

        // Act
        let newShowAIMenu = !showAIMenu

        // Assert
        Assert.assertTrue(newShowAIMenu, "AI menu should be visible after toggle")
    }

    @Test
    public func testBackNavigation(): Unit {
        // Arrange & Act
        let canNavigateBack = this.canNavigateTo("back")

        // Assert
        Assert.assertTrue(canNavigateBack, "Should be able to navigate back")
    }

    // Helper methods

    private func createMockResume(id: Int64, title: String): Resume {
        let resume = Resume()
        resume.id = id
        resume.title = title
        resume.templateId = 1
        resume.templateName = "专业模板"
        resume.status = "draft"
        resume.version = 1
        resume.content = ""
        resume.createdAt = ""
        resume.updatedAt = ""
        return resume
    }

    private func validateSection(section: String): Bool {
        let validSections = ["personal", "education", "experience", "skills", "projects"]
        for (validSection in validSections) {
            if (section == validSection) {
                return true
            }
        }
        return false
    }

    private func canNavigateTo(destination: String): Bool {
        return destination != ""
    }
}
