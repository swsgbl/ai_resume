// TemplateService.cj - 模板服务
package services

import models.*
import std.collection.*
import std.json.*

public class TemplateService {
    private let httpClient: HttpClient

    public init(httpClient: HttpClient) {
        this.httpClient = httpClient
    }

    // 获取所有模板
    public func getTemplates(): Result<ArrayList<Template>> {
        let response = httpClient.get(ApiConfig.TEMPLATES)

        if (response.isSuccess()) {
            let templates = parseTemplateList(response.body)
            return Result<ArrayList<Template>>.success(templates)
        }

        return Result<ArrayList<Template>>.failure(response.error)
    }

    // 获取模板分类
    public func getCategories(): Result<ArrayList<TemplateCategory>> {
        let response = httpClient.get(ApiConfig.TEMPLATES + "/categories")

        if (response.isSuccess()) {
            let categories = parseCategoryList(response.body)
            return Result<ArrayList<TemplateCategory>>.success(categories)
        }

        return Result<ArrayList<TemplateCategory>>.failure(response.error)
    }

    // 获取单个模板
    public func getTemplate(id: Int64): Result<Template> {
        let endpoint = ApiConfig.TEMPLATE_BY_ID.replace("{id}", id.toString())
        let response = httpClient.get(endpoint)

        if (response.isSuccess()) {
            let template = parseTemplate(response.body)
            return Result<Template>.success(template)
        }

        return Result<Template>.failure(response.error)
    }

    // 按分类获取模板
    public func getTemplatesByCategory(category: String): Result<ArrayList<Template>> {
        let endpoint = "${ApiConfig.TEMPLATES}?category=${category}"
        let response = httpClient.get(endpoint)

        if (response.isSuccess()) {
            let templates = parseTemplateList(response.body)
            return Result<ArrayList<Template>>.success(templates)
        }

        return Result<ArrayList<Template>>.failure(response.error)
    }

    // 解析模板列表
    private func parseTemplateList(json: String): ArrayList<Template> {
        let templates = ArrayList<Template>()
        try {
            let arr = JsonParser.parseArray(json)
            for (i in 0..arr.size()) {
                let obj = arr.getObject(i)
                templates.add(parseTemplateFromObject(obj))
            }
        } catch (e: Exception) {
            println("Failed to parse template list: ${e.message}")
        }
        return templates
    }

    // 解析单个模板
    private func parseTemplate(json: String): Template {
        try {
            let obj = JsonParser.parse(json)
            return parseTemplateFromObject(obj)
        } catch (e: Exception) {
            println("Failed to parse template: ${e.message}")
            return Template()
        }
    }

    // 从JSON对象解析模板
    private func parseTemplateFromObject(obj: JsonObject): Template {
        let template = Template()
        template.id = obj.getInt64("id", 0)
        template.name = obj.getString("name", "")
        template.description = obj.getString("description", "")
        template.category = obj.getString("category", "")
        template.preview = obj.getString("preview", "")
        template.isPremium = obj.getBool("is_premium", false)
        template.isActive = obj.getBool("is_active", true)
        template.usageCount = obj.getInt64("usage_count", 0)
        template.createdAt = obj.getString("created_at", "")

        // 解析样式
        let styleObj = obj.getObject("style")
        template.style = parseStyleFromObject(styleObj)

        return template
    }

    // 解析样式
    private func parseStyleFromObject(obj: JsonObject): TemplateStyle {
        let style = TemplateStyle()
        style.primaryColor = obj.getString("primary_color", "#2563eb")
        style.secondaryColor = obj.getString("secondary_color", "#64748b")
        style.backgroundColor = obj.getString("background_color", "#ffffff")
        style.textColor = obj.getString("text_color", "#1e293b")
        style.fontFamily = obj.getString("font_family", "HarmonyOS Sans")
        style.fontSize = obj.getInt32("font_size", 12)
        style.lineHeight = obj.getFloat32("line_height", 1.5f)
        style.margin = obj.getInt32("margin", 20)
        style.padding = obj.getInt32("padding", 15)
        return style
    }

    // 解析分类列表
    private func parseCategoryList(json: String): ArrayList<TemplateCategory> {
        let categories = ArrayList<TemplateCategory>()
        try {
            let arr = JsonParser.parseArray(json)
            for (i in 0..arr.size()) {
                let obj = arr.getObject(i)
                let category = TemplateCategory()
                category.id = obj.getString("id", "")
                category.name = obj.getString("name", "")
                category.icon = obj.getString("icon", "")
                category.count = obj.getInt32("count", 0)
                categories.add(category)
            }
        } catch (e: Exception) {
            println("Failed to parse category list: ${e.message}")
        }
        return categories
    }
}
