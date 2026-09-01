package test.integration.data

import entry.src.models.*
import std.time.DateTime

/// 测试数据工厂 - 生成标准化的测试数据
public class TestDataFactory {
    // ============================================
    // 用户数据生成器
    // ============================================

    /// 创建有效用户数据
    public static func createValidUser(): User {
        return User(
            id = "test-user-001",
            email = "test@example.com",
            name = "Test User",
            verified = true,
            createdAt = DateTime.now()
        )
    }

    /// 创建未验证用户
    public static func createUnverifiedUser(): User {
        return User(
            id = "test-user-002",
            email = "unverified@example.com",
            name = "Unverified User",
            verified = false,
            createdAt = DateTime.now()
        )
    }

    /// 创建无效用户数据（用于测试验证）
    public static func createInvalidEmailUser(): User {
        return User(
            id = "test-user-003",
            email = "invalid-email",
            name = "Invalid Email User",
            verified = false,
            createdAt = DateTime.now()
        )
    }

    // ============================================
    // 认证请求数据生成器
    // ============================================

    /// 创建有效的登录请求
    public static func createValidLoginRequest(): LoginRequest {
        return LoginRequest(
            email = "test@example.com",
            password = "SecurePassword123!"
        )
    }

    /// 创建无效的登录请求
    public static func createInvalidLoginRequest(): LoginRequest {
        return LoginRequest(
            email = "wrong@example.com",
            password = "WrongPassword123!"
        )
    }

    /// 创建有效的注册请求
    public static func createValidRegisterRequest(): RegisterRequest {
        return RegisterRequest(
            email = "newuser@example.com",
            password = "NewPassword123!",
            name = "New User",
            confirmPassword = "NewPassword123!"
        )
    }

    /// 创建密码不匹配的注册请求
    public static func createMismatchPasswordRegisterRequest(): RegisterRequest {
        return RegisterRequest(
            email = "newuser@example.com",
            password = "Password123!",
            name = "New User",
            confirmPassword = "DifferentPassword123!"
        )
    }

    // ============================================
    // Token 数据生成器
    // ============================================

    /// 创建有效的认证令牌
    public static func createValidAuthToken(): AuthToken {
        return AuthToken(
            accessToken = "test-access-token-" + DateTime.now().toString(),
            refreshToken = "test-refresh-token-" + DateTime.now().toString(),
            expiresIn = 3600
        )
    }

    /// 创建过期的认证令牌
    public static func createExpiredAuthToken(): AuthToken {
        return AuthToken(
            accessToken = "expired-access-token",
            refreshToken = "expired-refresh-token",
            expiresIn = 0
        )
    }

    // ============================================
    // 简历数据生成器
    // ============================================

    /// 创建完整的简历数据
    public static func createCompleteResume(): Resume {
        return Resume(
            id = "resume-001",
            userId = "test-user-001",
            title = "Software Engineer Resume",
            personalInfo = createCompletePersonalInfo(),
            education = createEducationList(),
            experience = createExperienceList(),
            skills = createSkillsList(),
            projects = createProjectsList(),
            createdAt = DateTime.now(),
            updatedAt = DateTime.now()
        )
    }

    /// 创建最小简历数据（仅含基本信息）
    public static func createMinimalResume(): Resume {
        return Resume(
            id = "resume-minimal-001",
            userId = "test-user-001",
            title = "Minimal Resume",
            personalInfo = createMinimalPersonalInfo(),
            education = ArrayList(),
            experience = ArrayList(),
            skills = ArrayList(),
            projects = ArrayList(),
            createdAt = DateTime.now(),
            updatedAt = DateTime.now()
        )
    }

    // ============================================
    // 个人信息数据生成器
    // ============================================

    /// 创建完整的个人信息
    public static func createCompletePersonalInfo(): PersonalInfo {
        return PersonalInfo(
            name = "John Doe",
            email = "john.doe@example.com",
            phone = "+1-555-0123",
            location = "San Francisco, CA",
            summary = "Experienced software engineer with expertise in mobile development",
            linkedin = "linkedin.com/in/johndoe",
            github = "github.com/johndoe"
        )
    }

    /// 创建最小的个人信息
    public static func createMinimalPersonalInfo(): PersonalInfo {
        return PersonalInfo(
            name = "Jane Doe",
            email = "jane.doe@example.com",
            phone = "",
            location = "",
            summary = "",
            linkedin = "",
            github = ""
        )
    }

    // ============================================
    // 教育经历数据生成器
    // ============================================

    /// 创建教育经历列表
    public static func createEducationList(): ArrayList<Education> {
        let list = ArrayList<Education>()
        list.append(createBachelorEducation())
        list.append(createMasterEducation())
        return list
    }

    /// 创建本科学历
    public static func createBachelorEducation(): Education {
        return Education(
            id = "edu-001",
            school = "University of California, Berkeley",
            degree = "Bachelor of Science",
            major = "Computer Science",
            startDate = "2015-09",
            endDate = "2019-05",
            gpa = "3.8"
        )
    }

    /// 创建硕士学历
    public static func createMasterEducation(): Education {
        return Education(
            id = "edu-002",
            school = "Stanford University",
            degree = "Master of Science",
            major = "Computer Science",
            startDate = "2019-09",
            endDate = "2021-05",
            gpa = "3.9"
        )
    }

    // ============================================
    // 工作经历数据生成器
    // ============================================

    /// 创建工作经历列表
    public static func createExperienceList(): ArrayList<WorkExperience> {
        let list = ArrayList<WorkExperience>()
        list.append(createSeniorExperience())
        list.append(createJuniorExperience())
        return list
    }

    /// 创建高级工程师经历
    public static func createSeniorExperience(): WorkExperience {
        return WorkExperience(
            id = "exp-001",
            company = "Tech Company Inc.",
            position = "Senior Software Engineer",
            startDate = "2021-06",
            endDate = "",
            current = true,
            description = "Lead developer for mobile applications",
            achievements = ArrayList<String>([
                "Developed 3 mobile apps with 100K+ downloads",
                "Mentored 5 junior developers",
                "Improved app performance by 40%"
            ])
        )
    }

    /// 创建初级工程师经历
    public static func createJuniorExperience(): WorkExperience {
        return WorkExperience(
            id = "exp-002",
            company = "Startup Corp",
            position = "Software Engineer",
            startDate = "2019-06",
            endDate = "2021-05",
            current = false,
            description = "Full-stack developer",
            achievements = ArrayList<String>([
                "Built REST APIs serving 1M+ requests",
                "Implemented CI/CD pipeline"
            ])
        )
    }

    // ============================================
    // 技能数据生成器
    // ============================================

    /// 创建技能列表
    public static func createSkillsList(): ArrayList<Skill> {
        let list = ArrayList<Skill>()
        list.append(Skill("HarmonyOS", "Expert", 5))
        list.append(Skill("ArkUI", "Advanced", 4))
        list.append(Skill("Cangjie", "Advanced", 4))
        list.append(Skill("TypeScript", "Intermediate", 3))
        list.append(Skill("Git", "Intermediate", 3))
        return list
    }

    // ============================================
    // 项目经历数据生成器
    // ============================================

    /// 创建项目经历列表
    public static func createProjectsList(): ArrayList<Project> {
        let list = ArrayList<Project>()
        list.append(createAIResumeProject())
        list.append(createEcommerceProject())
        return list
    }

    /// 创建 AI Resume 项目
    public static func createAIResumeProject(): Project {
        return Project(
            id = "proj-001",
            name = "AI Resume Builder",
            description = "AI-powered resume building application for HarmonyOS",
            role = "Lead Developer",
            startDate = "2024-01",
            endDate = "2024-03",
            technologies = ArrayList<String>([
                "HarmonyOS",
                "ArkUI",
                "Cangjie",
                "AI/ML"
            ]),
            achievements = ArrayList<String>([
                "Implemented AI-powered content generation",
                "Reached 10,000+ active users",
                "4.8 star rating"
            ])
        )
    }

    /// 创建电商项目
    public static func createEcommerceProject(): Project {
        return Project(
            id = "proj-002",
            name = "E-commerce Platform",
            description = "Mobile shopping application",
            role = "Full-stack Developer",
            startDate = "2023-06",
            endDate = "2023-12",
            technologies = ArrayList<String>([
                "React Native",
                "Node.js",
                "MongoDB"
            ]),
            achievements = ArrayList<String>([
                "Reduced checkout time by 50%",
                "Integrated payment gateways"
            ])
        )
    }

    // ============================================
    // 模板数据生成器
    // ============================================

    /// 创建模板列表
    public static func createTemplateList(): ArrayList<ResumeTemplate> {
        let list = ArrayList<ResumeTemplate>()
        list.append(createModernTemplate())
        list.append(createClassicTemplate())
        list.append(createCreativeTemplate())
        return list
    }

    /// 创建现代风格模板
    public static func createModernTemplate(): ResumeTemplate {
        return ResumeTemplate(
            id = "template-modern-001",
            name = "Modern Professional",
            category = "professional",
            description = "Clean and modern design for professionals",
            thumbnail = "templates/modern_thumbnail.png",
            preview = "templates/modern_preview.png",
            isPremium = false,
            features = ArrayList<String>([
                "AI optimization ready",
                "Customizable sections",
                "PDF export"
            ])
        )
    }

    /// 创建经典风格模板
    public static func createClassicTemplate(): ResumeTemplate {
        return ResumeTemplate(
            id = "template-classic-001",
            name = "Classic Elegant",
            category = "professional",
            description = "Timeless classic design",
            thumbnail = "templates/classic_thumbnail.png",
            preview = "templates/classic_preview.png",
            isPremium = false,
            features = ArrayList<String>([
                "Traditional layout",
                "ATS friendly",
                "Print ready"
            ])
        )
    }

    /// 创建创意风格模板
    public static func createCreativeTemplate(): ResumeTemplate {
        return ResumeTemplate(
            id = "template-creative-001",
            name = "Creative Designer",
            category = "creative",
            description = "Stand out with creative design",
            thumbnail = "templates/creative_thumbnail.png",
            preview = "templates/creative_preview.png",
            isPremium = true,
            features = ArrayList<String>([
                "Unique layout",
                "Color customization",
                "Social media integration"
            ])
        )
    }
}
