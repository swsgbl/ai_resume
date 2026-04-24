// Template.cj - 简历模板数据模型（同步自 Web 版 @ai-resume/shared/types Template）
package models

import std.collection.*

/**
 * 模板模型 - 同步自 Web 版 Template
 */
public class Template {
    public var id: Int64 = 0
    public var name: String = ""
    public var description: String = ""
    public var category: String = ""
    public var subCategory: String = ""
    public var level: String = ""
    public var layout: String = "single"  // 'single' | 'double'
    public var thumbnailUrl: String = ""
    public var previewUrl: String = ""
    public var preview: String = ""
    public var isPremium: Bool = false
    public var isFavorited: Bool = false
    public var isActive: Bool = true
    public var useCount: Int64 = 0
    public var styleConfig: String = ""  // JSON字符串
    public var style: TemplateStyle = TemplateStyle()
    public var createdAt: String = ""

    public init() {}

    public init(
        id: Int64,
        name: String,
        description: String,
        category: String,
        preview: String,
        style: TemplateStyle,
        isPremium: Bool,
        isActive: Bool,
        useCount: Int64,
        createdAt: String
    ) {
        this.id = id
        this.name = name
        this.description = description
        this.category = category
        this.preview = preview
        this.style = style
        this.isPremium = isPremium
        this.isActive = isActive
        this.useCount = useCount
        this.createdAt = createdAt
    }
}

/**
 * 模板样式 - 同步自 Web 版 style_config
 */
public class TemplateStyle {
    public var primaryColor: String = "#2563eb"
    public var secondaryColor: String = "#64748b"
    public var backgroundColor: String = "#ffffff"
    public var textColor: String = "#1e293b"
    public var fontFamily: String = "HarmonyOS Sans"
    public var fontSize: Int32 = 12
    public var lineHeight: Float32 = 1.5f
    public var margin: Int32 = 20
    public var padding: Int32 = 15

    public init() {}

    public init(
        primaryColor: String,
        secondaryColor: String,
        backgroundColor: String,
        textColor: String,
        fontFamily: String,
        fontSize: Int32,
        lineHeight: Float32,
        margin: Int32,
        padding: Int32
    ) {
        this.primaryColor = primaryColor
        this.secondaryColor = secondaryColor
        this.backgroundColor = backgroundColor
        this.textColor = textColor
        this.fontFamily = fontFamily
        this.fontSize = fontSize
        this.lineHeight = lineHeight
        this.margin = margin
        this.padding = padding
    }
}

/**
 * 模板分类 - 同步自 Web 版
 */
public class TemplateCategory {
    public var id: String = ""
    public var name: String = ""
    public var icon: String = ""
    public var count: Int32 = 0

    public init() {}

    public init(id: String, name: String, icon: String, count: Int32) {
        this.id = id
        this.name = name
        this.icon = icon
        this.count = count
    }
}

/**
 * 模板筛选条件 - 同步自 Web 版 TemplateFilter
 */
public class TemplateFilter {
    public var category: String = ""
    public var subCategory: String = ""
    public var level: String = ""
    public var isPremium: Bool = false
    public var search: String = ""
    public var sortBy: String = ""
    public var page: Int32 = 1
    public var pageSize: Int32 = 20

    public init() {}
}
