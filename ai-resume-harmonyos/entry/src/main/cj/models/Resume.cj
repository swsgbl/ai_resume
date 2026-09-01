// Resume.cj - 简历数据模型（同步自 Web 版 @ai-resume/shared/types ResumeContent）
package models

import std.collection.*

/**
 * 基本信息 - 同步自 Web 版 BasicInfo
 */
public class BasicInfo {
    public var name: String = ""
    public var email: String = ""
    public var phone: String = ""
    public var location: String = ""
    public var title: String = ""
    public var summary: String = ""
    public var avatar: String = ""
    public var linkedin: String = ""
    public var github: String = ""
    public var website: String = ""
    public var jobIntention: String = ""
    public var selfIntroduction: String = ""

    public init() {}
}

/**
 * 教育经历 - 同步自 Web 版 Education
 */
public class Education {
    public var id: String = ""
    public var school: String = ""
    public var degree: String = ""
    public var major: String = ""
    public var startDate: String = ""
    public var endDate: String = ""
    public var gpa: String = ""
    public var description: String = ""

    public init() {}
}

/**
 * 工作经历 - 同步自 Web 版 WorkExperience
 */
public class WorkExperience {
    public var id: String = ""
    public var company: String = ""
    public var position: String = ""
    public var startDate: String = ""
    public var endDate: String = ""
    public var isCurrent: Bool = false
    public var location: String = ""
    public var description: String = ""
    public var achievements: ArrayList<String> = ArrayList<String>()

    public init() {}
}

/**
 * 项目经历 - 同步自 Web 版 Project
 */
public class Project {
    public var id: String = ""
    public var name: String = ""
    public var role: String = ""
    public var startDate: String = ""
    public var endDate: String = ""
    public var description: String = ""
    public var techStack: ArrayList<String> = ArrayList<String>()
    public var highlights: ArrayList<String> = ArrayList<String>()
    public var link: String = ""

    public init() {}
}

/**
 * 技能 - 同步自 Web 版 Skill
 */
public class Skill {
    public var id: String = ""
    public var name: String = ""
    public var category: String = ""
    public var level: Int32 = 0
    public var keywords: ArrayList<String> = ArrayList<String>()

    public init() {}
}

/**
 * 证书荣誉 - 同步自 Web 版 Certification
 */
public class Certification {
    public var id: String = ""
    public var name: String = ""
    public var issuer: String = ""
    public var issueDate: String = ""
    public var expiryDate: String = ""
    public var credentialId: String = ""
    public var url: String = ""

    public init() {}
}

/**
 * 自定义条目 - 同步自 Web 版 CustomItem
 */
public class CustomItem {
    public var title: String = ""
    public var subtitle: String = ""
    public var description: String = ""
    public var date: String = ""

    public init() {}
}

/**
 * 自定义模块 - 同步自 Web 版 CustomSection
 */
public class CustomSection {
    public var id: String = ""
    public var title: String = ""
    public var content: String = ""
    public var items: ArrayList<CustomItem> = ArrayList<CustomItem>()
    public var order: Int32 = 0

    public init() {}
}

/**
 * 简历内容 - 同步自 Web 版 ResumeContent
 * 使用结构化数据代替简单的字符串content
 */
public class ResumeContent {
    public var basicInfo: BasicInfo = BasicInfo()
    public var education: ArrayList<Education> = ArrayList<Education>()
    public var workExperience: ArrayList<WorkExperience> = ArrayList<WorkExperience>()
    public var projects: ArrayList<Project> = ArrayList<Project>()
    public var skills: ArrayList<Skill> = ArrayList<Skill>()
    public var certifications: ArrayList<Certification> = ArrayList<Certification>()
    public var customSections: ArrayList<CustomSection> = ArrayList<CustomSection>()

    public init() {}
}

/**
 * 简历模型 - 同步自 Web 版 Resume
 */
public class Resume {
    public var id: Int64 = 0
    public var userId: Int64 = 0
    public var title: String = ""
    public var content: ResumeContent = ResumeContent()
    public var contentRaw: String = ""  // 原始JSON字符串，用于兼容
    public var templateId: Int64 = 0
    public var templateName: String = ""
    public var status: String = "draft"
    public var description: String = ""
    public var version: Int32 = 1
    public var tags: ArrayList<String> = ArrayList<String>()
    public var createdAt: String = ""
    public var updatedAt: String = ""

    public init() {}

    public init(
        id: Int64,
        userId: Int64,
        title: String,
        templateId: Int64,
        templateName: String,
        status: String,
        version: Int32,
        tags: ArrayList<String>,
        createdAt: String,
        updatedAt: String
    ) {
        this.id = id
        this.userId = userId
        this.title = title
        this.templateId = templateId
        this.templateName = templateName
        this.status = status
        this.version = version
        this.tags = tags
        this.createdAt = createdAt
        this.updatedAt = updatedAt
    }
}

/**
 * 简历筛选条件 - 同步自 Web 版 ResumeFilter
 */
public class ResumeFilter {
    public var status: String = ""
    public var search: String = ""
    public var page: Int32 = 1
    public var pageSize: Int32 = 20

    public init() {}
}

/**
 * 创建简历请求 - 同步自 Web 版 CreateResumeRequest
 */
public class CreateResumeRequest {
    public var title: String = ""
    public var description: String = ""
    public var templateId: Int64 = 0

    public init() {}
}

/**
 * 更新简历请求 - 同步自 Web 版 UpdateResumeRequest
 */
public class UpdateResumeRequest {
    public var title: String = ""
    public var description: String = ""
    public var templateId: Int64 = 0
    public var content: String = ""  // JSON字符串
    public var styleConfig: String = ""  // JSON字符串

    public init() {}
}

/**
 * AI 生成简历请求 - 同步自 Web 版 AIGenerateRequest
 */
public class AIGenerateRequest {
    public var targetPosition: String = ""
    public var userBackground: String = ""
    public var style: String = ""
    public var language: String = ""

    public init() {}
}

/**
 * AI 优化内容请求 - 同步自 Web 版 AIOptimizeRequest
 */
public class AIOptimizeRequest {
    public var content: String = ""
    public var optimizationType: String = ""
    public var context: String = ""

    public init() {}
}

/**
 * 分页响应 - 同步自 Web 版 PaginatedResponse
 */
public class PaginatedResponse<T> {
    public var data: ArrayList<T> = ArrayList<T>()
    public var total: Int64 = 0
    public var page: Int32 = 1
    public var pageSize: Int32 = 20
    public var totalPages: Int32 = 0

    public init() {}
}
