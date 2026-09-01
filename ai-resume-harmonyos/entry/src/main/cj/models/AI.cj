// AI.cj - AI相关数据模型
package models

import std.collection.*

public class AIConfig {
    public var id: Int64 = 0
    public var provider: String = "openai"
    public var model: String = "gpt-4"
    public var apiKey: String = ""
    public var baseUrl: String = ""
    public var maxTokens: Int32 = 4096
    public var temperature: Float32 = 0.7f
    public var isActive: Bool = true

    public init() {}

    public init(
        id: Int64,
        provider: String,
        model: String,
        apiKey: String,
        baseUrl: String,
        maxTokens: Int32,
        temperature: Float32,
        isActive: Bool
    ) {
        this.id = id
        this.provider = provider
        this.model = model
        this.apiKey = apiKey
        this.baseUrl = baseUrl
        this.maxTokens = maxTokens
        this.temperature = temperature
        this.isActive = isActive
    }
}

public class AIUsage {
    public var id: Int64 = 0
    public var userId: Int64 = 0
    public var provider: String = ""
    public var model: String = ""
    public var promptTokens: Int64 = 0
    public var completionTokens: Int64 = 0
    public var totalTokens: Int64 = 0
    public var cost: Float64 = 0.0
    public var createdAt: String = ""

    public init() {}

    public init(
        id: Int64,
        userId: Int64,
        provider: String,
        model: String,
        promptTokens: Int64,
        completionTokens: Int64,
        totalTokens: Int64,
        cost: Float64,
        createdAt: String
    ) {
        this.id = id
        this.userId = userId
        this.provider = provider
        this.model = model
        this.promptTokens = promptTokens
        this.completionTokens = completionTokens
        this.totalTokens = totalTokens
        this.cost = cost
        this.createdAt = createdAt
    }
}

public class AIGenerateRequest {
    public var resumeId: Int64 = 0
    public var section: String = ""
    public var prompt: String = ""
    public var context: String = ""
    public var templateId: Int64 = 0

    public init() {}

    public init(resumeId: Int64, section: String, prompt: String, context: String, templateId: Int64) {
        this.resumeId = resumeId
        this.section = section
        this.prompt = prompt
        this.context = context
        this.templateId = templateId
    }
}

public class AIGenerateResponse {
    public var content: String = ""
    public var tokens: Int64 = 0
    public var provider: String = ""
    public var model: String = ""

    public init() {}

    public init(content: String, tokens: Int64, provider: String, model: String) {
        this.content = content
        this.tokens = tokens
        this.provider = provider
        this.model = model
    }
}

public class AIProvider {
    public static let OPENAI: String = "openai"
    public static let DEEPSEEK: String = "deepseek"
    public static let XIAOMI_MIMO: String = "mimo"

    public func getName(provider: String): String {
        match (provider) {
            case AIProvider.OPENAI => "OpenAI GPT"
            case AIProvider.DEEPSEEK => "DeepSeek"
            case AIProvider.XIAOMI_MIMO => "Xiaomi MiMo"
            case _ => "Unknown"
        }
    }
}
