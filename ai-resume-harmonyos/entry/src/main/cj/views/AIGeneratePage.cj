// AIGeneratePage.cj - AI生成简历页面（同步自 Flutter 版 ai_generate_page + Web 版 AI功能）
package views

import ohos.arkui.*
import ohos.arkui.state.*
import ohos.arkui.node.*
import services.*
import models.*
import std.collection.*

@Entry
@Component
public struct AIGeneratePage {
    @State private var targetPosition: String = ""
    @State private var userBackground: String = ""
    @State private var selectedStyle: String = "professional"
    @State private var selectedLanguage: String = "zh"
    @State private var generatedContent: String = ""
    @State private var isGenerating: Bool = false
    @State private var errorMessage: String = ""
    @State private var resumeId: Int64 = 0
    @State private var currentStep: Int32 = 0  // 0: 输入, 1: 生成中, 2: 结果
    @State private var optimizationType: String = ""
    @State private var showOptimizePanel: Bool = false

    private let aiService: AIService
    private let resumeService: ResumeService
    private let authService: AuthService = AuthService()

    public init() {
        let httpClient = HttpClient(ApiConfig.BASE_URL + ApiConfig.API_VERSION)
        let token = authService.getCurrentToken()
        if (token.accessToken != "") {
            httpClient.setAuthToken(token.accessToken)
        }
        this.aiService = AIService(httpClient)
        this.resumeService = ResumeService(httpClient)
    }

    public func build(): void {
        Column() {
            // 顶部导航栏
            this.buildNavBar()

            // 步骤指示器
            this.buildStepIndicator()

            // 内容区域
            if (currentStep == 0) {
                this.buildInputForm()
            } else if (currentStep == 1) {
                this.buildGenerating()
            } else {
                this.buildResult()
            }
        }
        .width("100%")
        .height("100%")
        .backgroundColor("#f5f5f5")
    }

    // ==================== 导航栏 ====================
    @Builder
    private func buildNavBar(): void {
        Row() {
            Image($r("app.media.ic_back"))
                .width(24)
                .height(24)
                .onClick {
                    if (currentStep > 0) {
                        currentStep = currentStep - 1
                    } else {
                        Router.back()
                    }
                }

            Text("AI 简历生成")
                .fontSize(18)
                .fontWeight(FontWeight.Bold)
                .fontColor("#1e293b")
                .margin({ left: 12 })

            Blank()

            if (currentStep == 2) {
                Text("保存")
                    .fontSize(14)
                    .fontColor("#2563eb")
                    .fontWeight(FontWeight.Bold)
                    .onClick {
                        this.saveGeneratedContent()
                    }
            }
        }
        .width("100%")
        .height(56)
        .padding({ left: 16, right: 16 })
        .backgroundColor("#ffffff")
        .shadow({ radius: 2, color: "#1e293b", offsetX: 0, offsetY: 2 })
    }

    // ==================== 步骤指示器 ====================
    @Builder
    private func buildStepIndicator(): void {
        Row() {
            ForEach(["填写信息", "AI生成", "查看结果"], { (item: String, index: Int32) =>
                Column() {
                    // 圆点
                    Row() {
                        if (currentStep > index) {
                            Text("✓")
                                .fontSize(14)
                                .fontColor("#ffffff")
                        } else {
                            Text("${index + 1}")
                                .fontSize(14)
                                .fontColor(currentStep == index ? "#ffffff" : "#64748b")
                        }
                    }
                    .width(28)
                    .height(28)
                    .borderRadius(14)
                    .backgroundColor(currentStep >= index ? "#2563eb" : "#e2e8f0")
                    .justifyContent(FlexAlign.Center)
                    .alignItems(VerticalAlign.Center)

                    Text(item)
                        .fontSize(11)
                        .fontColor(currentStep >= index ? "#2563eb" : "#94a3b8")
                        .margin({ top: 4 })
                }
                .alignItems(HorizontalAlign.Center)
                .layoutWeight(1)
            })
        }
        .width("100%")
        .padding({ left: 24, right: 24, top: 16, bottom: 16 })
        .backgroundColor("#ffffff")
    }

    // ==================== 输入表单 ====================
    @Builder
    private func buildInputForm(): void {
        Scroll() {
            Column() {
                // 目标职位
                Column() {
                    Text("目标职位")
                        .fontSize(14)
                        .fontColor("#1e293b")
                        .fontWeight(FontWeight.Bold)
                        .margin({ bottom: 8 })

                    TextInput(placeholder: "例如：前端工程师、产品经理...", text: targetPosition)
                        .width("100%")
                        .height(44)
                        .backgroundColor("#f8fafc")
                        .borderRadius(8)
                        .padding({ left: 12, right: 12 })
                        .onChange({ (value: String) =>
                            targetPosition = value
                        })
                }
                .width("100%")
                .padding(16)
                .backgroundColor("#ffffff")
                .borderRadius(12)
                .margin({ top: 12 })

                // 个人背景
                Column() {
                    Text("个人背景")
                        .fontSize(14)
                        .fontColor("#1e293b")
                        .fontWeight(FontWeight.Bold)
                        .margin({ bottom: 8 })

                    TextArea(placeholder: "描述你的教育背景、工作经历、技能特长等...\n\n例如：\n- 5年前端开发经验\n- 精通React、Vue、TypeScript\n- 参与过多个大型项目...", text: userBackground)
                        .width("100%")
                        .height(160)
                        .backgroundColor("#f8fafc")
                        .borderRadius(8)
                        .padding(12)
                        .onChange({ (value: String) =>
                            userBackground = value
                        })
                }
                .width("100%")
                .padding(16)
                .backgroundColor("#ffffff")
                .borderRadius(12)
                .margin({ top: 12 })

                // 风格选择
                Column() {
                    Text("简历风格")
                        .fontSize(14)
                        .fontColor("#1e293b")
                        .fontWeight(FontWeight.Bold)
                        .margin({ bottom: 8 })

                    Row() {
                        this.buildStyleChip("专业", "professional", "💼")
                        this.buildStyleChip("创意", "creative", "🎨")
                        this.buildStyleChip("简约", "minimal", "✨")
                        this.buildStyleChip("学术", "academic", "🎓")
                    }
                    .width("100%")
                    .justifyContent(FlexAlign.SpaceBetween)
                }
                .width("100%")
                .padding(16)
                .backgroundColor("#ffffff")
                .borderRadius(12)
                .margin({ top: 12 })

                // 语言选择
                Column() {
                    Text("输出语言")
                        .fontSize(14)
                        .fontColor("#1e293b")
                        .fontWeight(FontWeight.Bold)
                        .margin({ bottom: 8 })

                    Row() {
                        this.buildLanguageChip("中文", "zh")
                        this.buildLanguageChip("English", "en")
                        this.buildLanguageChip("中英双语", "zh-en")
                    }
                    .width("100%")
                }
                .width("100%")
                .padding(16)
                .backgroundColor("#ffffff")
                .borderRadius(12)
                .margin({ top: 12 })

                // AI优化面板（可选）
                if (resumeId > 0) {
                    Column() {
                        Row() {
                            Text("AI内容优化")
                                .fontSize(14)
                                .fontColor("#1e293b")
                                .fontWeight(FontWeight.Bold)

                            Blank()

                            Text(showOptimizePanel ? "收起 ▲" : "展开 ▼")
                                .fontSize(12)
                                .fontColor("#2563eb")
                                .onClick {
                                    showOptimizePanel = !showOptimizePanel
                                }
                        }
                        .width("100%")

                        if (showOptimizePanel) {
                            Column() {
                                Row() {
                                    this.buildOptimizeChip("润色表达", "polish")
                                    this.buildOptimizeChip("增强效果", "enhance")
                                    this.buildOptimizeChip("精简内容", "condense")
                                    this.buildOptimizeChip("量化成果", "quantify")
                                }
                                .width("100%")
                                .justifyContent(FlexAlign.SpaceBetween)
                                .margin({ top: 8 })

                                Text("选择优化类型，AI将根据你的简历内容进行针对性优化")
                                    .fontSize(12)
                                    .fontColor("#94a3b8")
                                    .margin({ top: 8 })
                            }
                            .margin({ top: 8 })
                        }
                    }
                    .width("100%")
                    .padding(16)
                    .backgroundColor("#ffffff")
                    .borderRadius(12)
                    .margin({ top: 12 })
                }

                // 生成按钮
                Text("✨ 开始AI生成")
                    .fontSize(18)
                    .fontColor("#ffffff")
                    .fontWeight(FontWeight.Bold)
                    .backgroundColor(targetPosition != "" ? "#2563eb" : "#94a3b8")
                    .borderRadius(24)
                    .width("100%")
                    .height(52)
                    .textAlign(TextAlign.Center)
                    .margin({ top: 24, bottom: 24 })
                    .onClick {
                        if (targetPosition != "") {
                            this.startGenerate()
                        }
                    }
            }
            .padding({ left: 16, right: 16 })
        }
        .width("100%")
        .layoutWeight(1)
    }

    @Builder
    private func buildStyleChip(label: String, style: String, icon: String): void {
        Column() {
            Text(icon)
                .fontSize(24)
            Text(label)
                .fontSize(12)
                .fontColor(selectedStyle == style ? "#2563eb" : "#64748b")
                .margin({ top: 4 })
        }
        .width(72)
        .height(72)
        .borderRadius(12)
        .backgroundColor(selectedStyle == style ? "#eff6ff" : "#f8fafc")
        .border({
            width: selectedStyle == style ? 2 : 1,
            color: selectedStyle == style ? "#2563eb" : "#e2e8f0"
        })
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
        .onClick {
            selectedStyle = style
        }
    }

    @Builder
    private func buildLanguageChip(label: String, lang: String): void {
        Text(label)
            .fontSize(13)
            .fontColor(selectedLanguage == lang ? "#2563eb" : "#64748b")
            .backgroundColor(selectedLanguage == lang ? "#eff6ff" : "#f8fafc")
            .borderRadius(16)
            .padding({ left: 16, right: 16, top: 8, bottom: 8 })
            .margin({ right: 8 })
            .border({
                width: selectedLanguage == lang ? 1 : 0,
                color: "#2563eb"
            })
            .onClick {
                selectedLanguage = lang
            }
    }

    @Builder
    private func buildOptimizeChip(label: String, optType: String): void {
        Text(label)
            .fontSize(12)
            .fontColor(optimizationType == optType ? "#8b5cf6" : "#64748b")
            .backgroundColor(optimizationType == optType ? "#f5f3ff" : "#f8fafc")
            .borderRadius(12)
            .padding({ left: 10, right: 10, top: 6, bottom: 6 })
            .onClick {
                optimizationType = optType
            }
    }

    // ==================== 生成中 ====================
    @Builder
    private func buildGenerating(): void {
        Column() {
            // 动画效果
            Column() {
                Text("🤖")
                    .fontSize(64)
                    .margin({ bottom: 24 })

                LoadingProgress()
                    .width(40)
                    .height(40)
                    .color("#2563eb")

                Text("AI 正在为你生成简历...")
                    .fontSize(16)
                    .fontColor("#1e293b")
                    .fontWeight(FontWeight.Bold)
                    .margin({ top: 24 })

                Text("目标职位：${targetPosition}")
                    .fontSize(14)
                    .fontColor("#64748b")
                    .margin({ top: 8 })

                Text("预计需要 10-30 秒")
                    .fontSize(13)
                    .fontColor("#94a3b8")
                    .margin({ top: 8 })

                // 进度提示
                Column() {
                    Text("✓ 正在分析你的背景信息...")
                        .fontSize(13)
                        .fontColor("#10b981")
                        .margin({ top: 16 })
                    Text("✓ 正在匹配最佳模板结构...")
                        .fontSize(13)
                        .fontColor("#10b981")
                        .margin({ top: 8 })
                    Text("◉ 正在生成简历内容...")
                        .fontSize(13)
                        .fontColor("#2563eb")
                        .margin({ top: 8 })
                }
                .margin({ top: 24 })
            }
            .width("100%")
            .layoutWeight(1)
            .justifyContent(FlexAlign.Center)
            .alignItems(HorizontalAlign.Center)
        }
        .width("100%")
        .layoutWeight(1)
    }

    // ==================== 生成结果 ====================
    @Builder
    private func buildResult(): void {
        Scroll() {
            Column() {
                // 成功提示
                Row() {
                    Text("✅")
                        .fontSize(20)
                    Text("简历生成完成！")
                        .fontSize(16)
                        .fontWeight(FontWeight.Bold)
                        .fontColor("#10b981")
                        .margin({ left: 8 })
                }
                .width("100%")
                .padding(16)
                .backgroundColor("#f0fdf4")
                .borderRadius(12)
                .margin({ top: 12 })

                // 生成的内容
                Column() {
                    Text("生成内容预览")
                        .fontSize(14)
                        .fontColor("#1e293b")
                        .fontWeight(FontWeight.Bold)
                        .margin({ bottom: 12 })

                    Scroll() {
                        Text(generatedContent)
                            .fontSize(14)
                            .fontColor("#334155")
                            .lineHeight(22)
                            .width("100%")
                    }
                    .width("100%")
                    .height(300)
                    .backgroundColor("#f8fafc")
                    .borderRadius(8)
                    .padding(12)
                }
                .width("100%")
                .padding(16)
                .backgroundColor("#ffffff")
                .borderRadius(12)
                .margin({ top: 12 })

                // 操作按钮
                Row() {
                    Text("重新生成")
                        .fontSize(14)
                        .fontColor("#64748b")
                        .padding({ left: 20, right: 20, top: 12, bottom: 12 })
                        .borderRadius(24)
                        .border({ width: 1, color: "#e2e8f0" })
                        .onClick {
                            currentStep = 0
                            generatedContent = ""
                        }

                    Text("保存到简历")
                        .fontSize(14)
                        .fontColor("#ffffff")
                        .backgroundColor("#2563eb")
                        .padding({ left: 20, right: 20, top: 12, bottom: 12 })
                        .borderRadius(24)
                        .margin({ left: 12 })
                        .layoutWeight(1)
                        .textAlign(TextAlign.Center)
                        .onClick {
                            this.saveGeneratedContent()
                        }
                }
                .width("100%")
                .margin({ top: 16, bottom: 24 })

                // AI优化选项
                Column() {
                    Text("继续优化")
                        .fontSize(14)
                        .fontColor("#1e293b")
                        .fontWeight(FontWeight.Bold)
                        .margin({ bottom: 8 })

                    Row() {
                        this.buildQuickOptimizeButton("润色表达", "polish")
                        this.buildQuickOptimizeButton("量化成果", "quantify")
                        this.buildQuickOptimizeButton("增强吸引力", "enhance")
                    }
                    .width("100%")
                    .justifyContent(FlexAlign.SpaceBetween)
                }
                .width("100%")
                .padding(16)
                .backgroundColor("#ffffff")
                .borderRadius(12)
                .margin({ top: 8, bottom: 24 })
            }
            .padding({ left: 16, right: 16 })
        }
        .width("100%")
        .layoutWeight(1)
    }

    @Builder
    private func buildQuickOptimizeButton(label: String, optType: String): void {
        Text(label)
            .fontSize(12)
            .fontColor("#8b5cf6")
            .backgroundColor("#f5f3ff")
            .borderRadius(16)
            .padding({ left: 12, right: 12, top: 8, bottom: 8 })
            .onClick {
                this.optimizeContent(optType)
            }
    }

    // ==================== 业务逻辑 ====================

    private func startGenerate(): void {
        if (targetPosition == "") {
            errorMessage = "请输入目标职位"
            return
        }

        currentStep = 1
        isGenerating = true
        errorMessage = ""

        if (resumeId > 0) {
            // 已有简历：AI生成
            let request = AIGenerateRequest()
            request.targetPosition = targetPosition
            request.userBackground = userBackground
            request.style = selectedStyle
            request.language = selectedLanguage

            let result = resumeService.aiGenerateResume(resumeId, request)
            isGenerating = false

            if (result.isSuccess()) {
                let value = result.getValue()
                if (value is Some<Resume>) {
                    generatedContent = this.formatResumeContent(value.get())
                    currentStep = 2
                }
            } else {
                // 降级：使用 AIService
                let aiRequest = AIGenerateRequest()
                aiRequest.targetPosition = targetPosition
                aiRequest.userBackground = userBackground
                let aiResult = aiService.generateContent(aiRequest)
                if (aiResult.isSuccess()) {
                    let aiValue = aiResult.getValue()
                    if (aiValue is Some<AIGenerateResponse>) {
                        generatedContent = aiValue.get().content
                        currentStep = 2
                    }
                } else {
                    errorMessage = "AI生成失败，请重试"
                    currentStep = 0
                }
            }
        } else {
            // 无简历ID：直接使用AI服务生成
            let request = AIGenerateRequest()
            request.targetPosition = targetPosition
            request.userBackground = userBackground

            let result = aiService.generateContent(request)
            isGenerating = false

            if (result.isSuccess()) {
                let value = result.getValue()
                if (value is Some<AIGenerateResponse>) {
                    generatedContent = value.get().content
                    currentStep = 2
                }
            } else {
                errorMessage = "AI生成失败，请重试"
                currentStep = 0
            }
        }
    }

    private func optimizeContent(optType: String): void {
        if (generatedContent == "") {
            return
        }

        isGenerating = true
        let request = AIOptimizeRequest()
        request.content = generatedContent
        request.optimizationType = optType
        request.context = "目标职位：${targetPosition}"

        let result = resumeService.aiOptimizeContent(request)
        isGenerating = false

        if (result.isSuccess()) {
            let value = result.getValue()
            if (value is Some<String>) {
                generatedContent = value.get()
            }
        }
    }

    private func saveGeneratedContent(): void {
        if (resumeId > 0) {
            // 更新已有简历
            let result = resumeService.getResume(resumeId)
            if (result.isSuccess()) {
                let value = result.getValue()
                if (value is Some<Resume>) {
                    let resume = value.get()
                    resume.contentRaw = generatedContent
                    resumeService.updateResume(resumeId, resume)
                    Router.back()
                }
            }
        } else {
            // 创建新简历
            let result = resumeService.createResume("AI生成-${targetPosition}", 1)
            if (result.isSuccess()) {
                let value = result.getValue()
                if (value is Some<Resume>) {
                    Router.push({ url: "pages/ResumeEditorPage", params: { "resumeId": value.get().id } })
                }
            }
        }
    }

    private func formatResumeContent(resume: Resume): String {
        let sb = StringBuilder()
        let content = resume.content

        // 基本信息
        if (content.basicInfo.name != "") {
            sb.append("【基本信息】\n")
            sb.append("姓名：${content.basicInfo.name}\n")
            if (content.basicInfo.title != "") { sb.append("职位：${content.basicInfo.title}\n") }
            if (content.basicInfo.email != "") { sb.append("邮箱：${content.basicInfo.email}\n") }
            if (content.basicInfo.phone != "") { sb.append("电话：${content.basicInfo.phone}\n") }
            sb.append("\n")
        }

        // 工作经历
        if (content.workExperience.size() > 0) {
            sb.append("【工作经历】\n")
            for (i in 0..content.workExperience.size()) {
                let exp = content.workExperience.get(i)
                sb.append("• ${exp.company} - ${exp.position}\n")
                sb.append("  ${exp.startDate} ~ ${exp.endDate}\n")
                if (exp.description != "") { sb.append("  ${exp.description}\n") }
                sb.append("\n")
            }
        }

        // 教育经历
        if (content.education.size() > 0) {
            sb.append("【教育经历】\n")
            for (i in 0..content.education.size()) {
                let edu = content.education.get(i)
                sb.append("• ${edu.school} - ${edu.major} (${edu.degree})\n")
                sb.append("\n")
            }
        }

        // 技能
        if (content.skills.size() > 0) {
            sb.append("【技能】\n")
            for (i in 0..content.skills.size()) {
                let skill = content.skills.get(i)
                sb.append("• ${skill.name}")
                if (skill.category != "") { sb.append(" (${skill.category})") }
                sb.append("\n")
            }
        }

        return sb.toString()
    }
}
