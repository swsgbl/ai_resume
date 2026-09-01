 // AIService.cj - AI服务
package services

import models.*
import std.collection.*
import std.json.*

public class AIService {
    private let httpClient: HttpClient

    public init(httpClient: HttpClient) {
        this.httpClient = httpClient
    }

    // 生成简历内容
    public func generateContent(request: AIGenerateRequest): Result<AIGenerateResponse> {
        let body = serializeGenerateRequest(request)
        let response = httpClient.post(ApiConfig.AI_GENERATE, body)

        if (response.isSuccess()) {
            let aiResponse = parseAIGenerateResponse(response.body)
            return Result<AIGenerateResponse>.success(aiResponse)
        }

        return Result<AIGenerateResponse>.failure(response.error)
    }

    // 生成个人简介
    public func generateSummary(personalInfo: PersonalInfo): Result<String> {
        let prompt = "请根据以下信息生成一段专业的个人简介：\n姓名：${personalInfo.name}\n职位：${personalInfo.summary}"
        let request = AIGenerateRequest()
        request.prompt = prompt
        request.section = "summary"

        let result = generateContent(request)
        if (result.isSuccess()) {
            let value = result.getValue()
            if (value is Some<AIGenerateResponse>) {
                return Result<String>.success(value.get().content)
            }
        }
        return Result<String>.failure(result.getError())
    }

    // 生成工作经历描述
    public func generateExperienceDescription(experience: Experience): Result<String> {
        let prompt = "请为以下工作经历生成专业的描述和成就：\n公司：${experience.company}\n职位：${experience.position}"
        let request = AIGenerateRequest()
        request.prompt = prompt
        request.section = "experience"

        let result = generateContent(request)
        if (result.isSuccess()) {
            let value = result.getValue()
            if (value is Some<AIGenerateResponse>) {
                return Result<String>.success(value.get().content)
            }
        }
        return Result<String>.failure(result.getError())
    }

    // 优化简历内容
    public func optimizeContent(content: String, section: String): Result<String> {
        let prompt = "请优化以下${section}内容，使其更加专业和有吸引力：\n${content}"
        let request = AIGenerateRequest()
        request.prompt = prompt
        request.section = section

        let result = generateContent(request)
        if (result.isSuccess()) {
            let value = result.getValue()
            if (value is Some<AIGenerateResponse>) {
                return Result<String>.success(value.get().content)
            }
        }
        return Result<String>.failure(result.getError())
    }

    // 获取AI使用统计
    public func getUsageStats(): Result<ArrayList<AIUsage>> {
        let response = httpClient.get(ApiConfig.AI_USAGE)

        if (response.isSuccess()) {
            let usageList = parseUsageList(response.body)
            return Result<ArrayList<AIUsage>>.success(usageList)
        }

        return Result<ArrayList<AIUsage>>.failure(response.error)
    }

    // 序列化生成请求
    private func serializeGenerateRequest(request: AIGenerateRequest): String {
        let sb = StringBuilder()
        sb.append("{")
        sb.append("\"resume_id\": ${request.resumeId}, ")
        sb.append("\"section\": \"${request.section}\", ")
        sb.append("\"prompt\": \"${escapeJson(request.prompt)}\", ")
        sb.append("\"context\": \"${escapeJson(request.context)}\", ")
        sb.append("\"template_id\": ${request.templateId}")
        sb.append("}")
        return sb.toString()
    }

    // 解析AI生成响应
    private func parseAIGenerateResponse(json: String): AIGenerateResponse {
        let response = AIGenerateResponse()
        try {
            let obj = JsonParser.parse(json)
            response.content = obj.getString("content", "")
            response.tokens = obj.getInt64("tokens", 0)
            response.provider = obj.getString("provider", "")
            response.model = obj.getString("model", "")
        } catch (e: Exception) {
            println("Failed to parse AI response: ${e.message}")
        }
        return response
    }

    // 解析使用统计列表
    private func parseUsageList(json: String): ArrayList<AIUsage> {
        let usageList = ArrayList<AIUsage>()
        try {
            let arr = JsonParser.parseArray(json)
            for (i in 0..arr.size()) {
                let obj = arr.getObject(i)
                let usage = AIUsage()
                usage.id = obj.getInt64("id", 0)
                usage.userId = obj.getInt64("user_id", 0)
                usage.provider = obj.getString("provider", "")
                usage.model = obj.getString("model", "")
                usage.promptTokens = obj.getInt64("prompt_tokens", 0)
                usage.completionTokens = obj.getInt64("completion_tokens", 0)
                usage.totalTokens = obj.getInt64("total_tokens", 0)
                usage.cost = obj.getFloat64("cost", 0.0)
                usage.createdAt = obj.getString("created_at", "")
                usageList.add(usage)
            }
        } catch (e: Exception) {
            println("Failed to parse usage list: ${e.message}")
        }
        return usageList
    }

    // JSON字符串转义
    private func escapeJson(s: String): String {
        return s.replace("\\", "\\\\")
                .replace("\"", "\\\"")
                .replace("\n", "\\n")
                .replace("\r", "\\r")
                .replace("\t", "\\t")
    }
}
