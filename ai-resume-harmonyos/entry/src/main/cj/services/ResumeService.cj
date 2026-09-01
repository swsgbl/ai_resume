// ResumeService.cj - 简历服务（同步自 Web 版 ResumeApi）
package services

import models.*
import std.collection.*
import std.json.*

public class ResumeService {
    private let httpClient: HttpClient

    public init(httpClient: HttpClient) {
        this.httpClient = httpClient
    }

    // ==================== 获取简历列表 ====================
    // 同步自 Web 版 ResumeApi.getResumes
    public func getResumes(filter: ResumeFilter): Result<PaginatedResponse<Resume>> {
        var params = HashMap<String, String>()
        if (filter.status != "") { params.put("status", filter.status) }
        if (filter.search != "") { params.put("search", filter.search) }
        params.put("page", filter.page.toString())
        params.put("page_size", filter.pageSize.toString())

        let response = httpClient.get(ApiConfig.RESUMES)

        if (response.isSuccess()) {
            let result = parsePaginatedResumes(response.body)
            return result
        }

        return Result<PaginatedResponse<Resume>>.failure(response.error)
    }

    // 获取所有简历（简化版）
    public func getResumes(): Result<ArrayList<Resume>> {
        let response = httpClient.get(ApiConfig.RESUMES)

        if (response.isSuccess()) {
            let resumes = parseResumeList(response.body)
            return Result<ArrayList<Resume>>.success(resumes)
        }

        return Result<ArrayList<Resume>>.failure(response.error)
    }

    // ==================== 获取单个简历 ====================
    // 同步自 Web 版 ResumeApi.getResume
    public func getResume(id: Int64): Result<Resume> {
        let endpoint = ApiConfig.RESUME_BY_ID.replace("{id}", id.toString())
        let response = httpClient.get(endpoint)

        if (response.isSuccess()) {
            let resume = parseResume(response.body)
            return Result<Resume>.success(resume)
        }

        return Result<Resume>.failure(response.error)
    }

    // ==================== 创建简历 ====================
    // 同步自 Web 版 ResumeApi.createResume
    public func createResume(title: String, templateId: Int64): Result<Resume> {
        let obj = JsonObject()
        obj.put("title", title)
        obj.put("template_id", templateId)
        let response = httpClient.post(ApiConfig.RESUMES, obj.toJson())

        if (response.isSuccess()) {
            let resume = parseResume(response.body)
            return Result<Resume>.success(resume)
        }

        return Result<Resume>.failure(response.error)
    }

    // ==================== 更新简历 ====================
    // 同步自 Web 版 ResumeApi.updateResume
    public func updateResume(id: Int64, resume: Resume): Result<Resume> {
        let endpoint = ApiConfig.RESUME_BY_ID.replace("{id}", id.toString())
        let body = serializeResume(resume)
        let response = httpClient.put(endpoint, body)

        if (response.isSuccess()) {
            let updated = parseResume(response.body)
            return Result<Resume>.success(updated)
        }

        return Result<Resume>.failure(response.error)
    }

    // ==================== 删除简历 ====================
    // 同步自 Web 版 ResumeApi.deleteResume
    public func deleteResume(id: Int64): Result<Bool> {
        let endpoint = ApiConfig.RESUME_BY_ID.replace("{id}", id.toString())
        let response = httpClient.delete(endpoint)

        if (response.isSuccess()) {
            return Result<Bool>.success(true)
        }

        return Result<Bool>.failure(response.error)
    }

    // ==================== 复制简历 ====================
    // 新增：同步自 Web 版 ResumeApi.copyResume
    public func copyResume(id: Int64): Result<Resume> {
        let endpoint = ApiConfig.RESUME_COPY.replace("{id}", id.toString())
        let response = httpClient.post(endpoint, "{}")

        if (response.isSuccess()) {
            let resume = parseResume(response.body)
            return Result<Resume>.success(resume)
        }

        return Result<Resume>.failure(response.error)
    }

    // ==================== AI 生成简历 ====================
    // 同步自 Web 版 ResumeApi.aiGenerateResume
    public func aiGenerateResume(id: Int64, request: AIGenerateRequest): Result<Resume> {
        let endpoint = ApiConfig.RESUME_AI_GENERATE.replace("{id}", id.toString())
        let obj = JsonObject()
        obj.put("target_position", request.targetPosition)
        obj.put("user_background", request.userBackground)
        obj.put("style", request.style)
        obj.put("language", request.language)
        let response = httpClient.post(endpoint, obj.toJson())

        if (response.isSuccess()) {
            let resume = parseResume(response.body)
            return Result<Resume>.success(resume)
        }

        return Result<Resume>.failure(response.error)
    }

    // ==================== AI 优化内容 ====================
    // 同步自 Web 版 ResumeApi.aiOptimizeContent
    public func aiOptimizeContent(request: AIOptimizeRequest): Result<String> {
        let obj = JsonObject()
        obj.put("content", request.content)
        obj.put("optimization_type", request.optimizationType)
        obj.put("context", request.context)
        let response = httpClient.post(ApiConfig.RESUME_AI_OPTIMIZE, obj.toJson())

        if (response.isSuccess()) {
            try {
                let jsonObj = JsonParser.parse(response.body)
                let optimized = jsonObj.getString("optimized", "")
                return Result<String>.success(optimized)
            } catch (e: Exception) {
                return Result<String>.failure("解析优化结果失败")
            }
        }

        return Result<String>.failure(response.error)
    }

    // ==================== 解析方法 ====================

    private func parsePaginatedResumes(json: String): Result<PaginatedResponse<Resume>> {
        try {
            let obj = JsonParser.parse(json)
            var dataObj = obj
            if (obj.containsKey("data")) {
                dataObj = obj.getObject("data")
            }

            let result = PaginatedResponse<Resume>()
            result.total = dataObj.getInt64("total", 0)
            result.page = dataObj.getInt32("page", 1)
            result.pageSize = dataObj.getInt32("page_size", 20)
            result.totalPages = dataObj.getInt32("total_pages", 0)

            let arr = dataObj.getArray("data")
            for (i in 0..arr.size()) {
                let itemObj = arr.getObject(i)
                result.data.add(parseResumeFromObject(itemObj))
            }

            return Result<PaginatedResponse<Resume>>.success(result)
        } catch (e: Exception) {
            // 降级：尝试作为数组解析
            let resumes = parseResumeList(json)
            let result = PaginatedResponse<Resume>()
            result.data = resumes
            result.total = Int64(resumes.size())
            return Result<PaginatedResponse<Resume>>.success(result)
        }
    }

    private func parseResumeList(json: String): ArrayList<Resume> {
        let resumes = ArrayList<Resume>()
        try {
            let arr = JsonParser.parseArray(json)
            for (i in 0..arr.size()) {
                let obj = arr.getObject(i)
                resumes.add(parseResumeFromObject(obj))
            }
        } catch (e: Exception) {
            println("Failed to parse resume list: ${e.message}")
        }
        return resumes
    }

    private func parseResume(json: String): Resume {
        try {
            let obj = JsonParser.parse(json)
            // 处理嵌套的 data 字段
            if (obj.containsKey("data")) {
                let dataObj = obj.getObject("data")
                return parseResumeFromObject(dataObj)
            }
            return parseResumeFromObject(obj)
        } catch (e: Exception) {
            println("Failed to parse resume: ${e.message}")
            return Resume()
        }
    }

    private func parseResumeFromObject(obj: JsonObject): Resume {
        let resume = Resume()
        resume.id = obj.getInt64("id", 0)
        resume.userId = obj.getInt64("user_id", 0)
        resume.title = obj.getString("title", "")
        resume.contentRaw = obj.getString("content", "")
        resume.templateId = obj.getInt64("template_id", 0)
        resume.templateName = obj.getString("template_name", "")
        resume.status = obj.getString("status", "draft")
        resume.description = obj.getString("description", "")
        resume.version = obj.getInt32("version", 1)
        resume.createdAt = obj.getString("created_at", "")
        resume.updatedAt = obj.getString("updated_at", "")

        // 解析标签
        try {
            let tagsArr = obj.getArray("tags")
            for (i in 0..tagsArr.size()) {
                resume.tags.add(tagsArr.getString(i))
            }
        } catch (_: Exception) {}

        return resume
    }

    private func serializeResume(resume: Resume): String {
        let obj = JsonObject()
        obj.put("title", resume.title)
        if (resume.contentRaw != "") {
            obj.put("content", resume.contentRaw)
        }
        obj.put("template_id", resume.templateId)
        obj.put("status", resume.status)
        if (resume.description != "") {
            obj.put("description", resume.description)
        }
        return obj.toJson()
    }
}