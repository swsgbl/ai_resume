// ResumeEditorPage.cj - 简历编辑页面
package views

import ohos.arkui.*
import ohos.arkui.state.*
import ohos.arkui.node.*
import services.*
import models.*
import std.collection.*

@Entry
@Component
public struct ResumeEditorPage {
    @State private var resume: Resume = Resume()
    @State private var resumeData: ResumeData = ResumeData()
    @State private var isLoading: Bool = true
    @State private var currentSection: String = "personal"
    @State private var showAIMenu: Bool = false

    private let resumeService: ResumeService
    private let aiService: AIService
    private var resumeId: Int64 = 0

    public init() {
        let httpClient = HttpClient(ApiConfig.BASE_URL + ApiConfig.API_VERSION)
        let authService = AuthService()
        let token = authService.getCurrentToken()
        if (token.accessToken != "") {
            httpClient.setAuthToken(token.accessToken)
        }
        this.resumeService = ResumeService(httpClient)
        this.aiService = AIService(httpClient)
    }

    public func aboutToAppear(): void {
        // 获取路由参数
        let params = Router.getParams()
        if (params.containsKey("resumeId")) {
            resumeId = params.getInt64("resumeId", 0)
            this.loadResume()
        }
    }

    public func build(): void {
        Column() {
            // 顶部栏
            this.buildHeader()

            // 编辑区域
            if (isLoading) {
                this.buildLoading()
            } else {
                this.buildEditor()
            }

            // AI菜单
            if (showAIMenu) {
                this.buildAIMenu()
            }
        }
        .width("100%")
        .height("100%")
        .backgroundColor("#f5f5f5")
    }

    @Builder
    private func buildHeader(): void {
        Row() {
            // 返回按钮
            Image($r("app.media.ic_back"))
                .width(24)
                .height(24)
                .onClick {
                    Router.back()
                }

            Text(resume.title)
                .fontSize(18)
                .fontWeight(FontWeight.Bold)
                .fontColor("#1e293b")
                .margin({ left: 16 })
                .layoutWeight(1)

            // AI按钮
            Image($r("app.media.ic_ai"))
                .width(24)
                .height(24)
                .margin({ right: 16 })
                .onClick {
                    showAIMenu = !showAIMenu
                }

            // 保存按钮
            Button("保存")
                .fontSize(14)
                .fontColor("#ffffff")
                .backgroundColor("#2563eb")
                .borderRadius(4)
                .padding({ left: 12, right: 12, top: 6, bottom: 6 })
                .onClick {
                    this.saveResume()
                }
        }
        .width("100%")
        .height(56)
        .padding({ left: 16, right: 16 })
        .backgroundColor("#ffffff")
        .shadow({ radius: 2, color: "#1e293b", offsetX: 0, offsetY: 2 })
    }

    @Builder
    private func buildLoading(): void {
        Column() {
            LoadingProgress()
                .width(48)
                .height(48)
                .color("#2563eb")

            Text("加载中...")
                .fontSize(14)
                .fontColor("#64748b")
                .margin({ top: 16 })
        }
        .width("100%")
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
    }

    @Builder
    private func buildEditor(): void {
        Column() {
            // 区块选择器
            this.buildSectionSelector()

            // 编辑内容
            Scroll() {
                Column() {
                    if (currentSection == "personal") {
                        this.buildPersonalSection()
                    } else if (currentSection == "education") {
                        this.buildEducationSection()
                    } else if (currentSection == "experience") {
                        this.buildExperienceSection()
                    } else if (currentSection == "skills") {
                        this.buildSkillsSection()
                    } else if (currentSection == "projects") {
                        this.buildProjectsSection()
                    }
                }
                .width("100%")
                .padding(16)
            }
            .width("100%")
            .layoutWeight(1)
        }
        .width("100%")
        .layoutWeight(1)
    }

    @Builder
    private func buildSectionSelector(): void {
        Scroll() {
            Row() {
                this.buildSectionTab("个人信息", "personal")
                this.buildSectionTab("教育经历", "education")
                this.buildSectionTab("工作经历", "experience")
                this.buildSectionTab("技能特长", "skills")
                this.buildSectionTab("项目经验", "projects")
            }
        }
        .scrollable(ScrollDirection.Horizontal)
        .width("100%")
        .height(48)
        .backgroundColor("#ffffff")
    }

    @Builder
    private func buildSectionTab(label: String, section: String): void {
        Text(label)
            .fontSize(14)
            .fontColor(currentSection == section ? "#2563eb" : "#64748b")
            .fontWeight(currentSection == section ? FontWeight.Bold : FontWeight.Normal)
            .padding({ left: 16, right: 16, top: 12, bottom: 12 })
            .onClick {
                currentSection = section
            }
    }

    @Builder
    private func buildPersonalSection(): void {
        Column() {
            this.buildInputField("姓名", resumeData.personalInfo.name, { value =>
                resumeData.personalInfo.name = value
            })

            this.buildInputField("邮箱", resumeData.personalInfo.email, { value =>
                resumeData.personalInfo.email = value
            })

            this.buildInputField("电话", resumeData.personalInfo.phone, { value =>
                resumeData.personalInfo.phone = value
            })

            this.buildInputField("所在地", resumeData.personalInfo.location, { value =>
                resumeData.personalInfo.location = value
            })

            this.buildInputField("个人网站", resumeData.personalInfo.website, { value =>
                resumeData.personalInfo.website = value
            })

            this.buildTextArea("个人简介", resumeData.personalInfo.summary, { value =>
                resumeData.personalInfo.summary = value
            })
        }
        .width("100%")
    }

    @Builder
    private func buildEducationSection(): void {
        Column() {
            ForEach(resumeData.education, { (edu: Education, index: Int32) =>
                this.buildEducationItem(edu, index)
            })

            Button("添加教育经历")
                .width("100%")
                .height(40)
                .fontSize(14)
                .fontColor("#2563eb")
                .backgroundColor("#ffffff")
                .border({ width: 1, color: "#2563eb", radius: 8 })
                .margin({ top: 16 })
                .onClick {
                    resumeData.education.add(Education())
                }
        }
        .width("100%")
    }

    @Builder
    private func buildEducationItem(edu: Education, index: Int32): void {
        Column() {
            Row() {
                Text("教育经历 ${index + 1}")
                    .fontSize(16)
                    .fontWeight(FontWeight.Bold)
                    .fontColor("#1e293b")

                Blank()

                Image($r("app.media.ic_delete"))
                    .width(20)
                    .height(20)
                    .onClick {
                        resumeData.education.removeAt(index)
                    }
            }
            .width("100%")

            this.buildInputField("学校", edu.school, { value => edu.school = value })
            this.buildInputField("学位", edu.degree, { value => edu.degree = value })
            this.buildInputField("专业", edu.field, { value => edu.field = value })
            this.buildInputField("开始时间", edu.startDate, { value => edu.startDate = value })
            this.buildInputField("结束时间", edu.endDate, { value => edu.endDate = value })
            this.buildTextArea("描述", edu.description, { value => edu.description = value })
        }
        .width("100%")
        .padding(16)
        .backgroundColor("#ffffff")
        .borderRadius(8)
        .margin({ top: 8 })
    }

    @Builder
    private func buildExperienceSection(): void {
        Column() {
            ForEach(resumeData.experience, { (exp: Experience, index: Int32) =>
                this.buildExperienceItem(exp, index)
            })

            Button("添加工作经历")
                .width("100%")
                .height(40)
                .fontSize(14)
                .fontColor("#2563eb")
                .backgroundColor("#ffffff")
                .border({ width: 1, color: "#2563eb", radius: 8 })
                .margin({ top: 16 })
                .onClick {
                    resumeData.experience.add(Experience())
                }
        }
        .width("100%")
    }

    @Builder
    private func buildExperienceItem(exp: Experience, index: Int32): void {
        Column() {
            Row() {
                Text("工作经历 ${index + 1}")
                    .fontSize(16)
                    .fontWeight(FontWeight.Bold)
                    .fontColor("#1e293b")

                Blank()

                Image($r("app.media.ic_delete"))
                    .width(20)
                    .height(20)
                    .onClick {
                        resumeData.experience.removeAt(index)
                    }
            }
            .width("100%")

            this.buildInputField("公司", exp.company, { value => exp.company = value })
            this.buildInputField("职位", exp.position, { value => exp.position = value })
            this.buildInputField("开始时间", exp.startDate, { value => exp.startDate = value })
            this.buildInputField("结束时间", exp.endDate, { value => exp.endDate = value })
            this.buildInputField("地点", exp.location, { value => exp.location = value })
            this.buildTextArea("描述", exp.description, { value => exp.description = value })
        }
        .width("100%")
        .padding(16)
        .backgroundColor("#ffffff")
        .borderRadius(8)
        .margin({ top: 8 })
    }

    @Builder
    private func buildSkillsSection(): void {
        Column() {
            ForEach(resumeData.skills, { (skill: Skill, index: Int32) =>
                this.buildSkillItem(skill, index)
            })

            Button("添加技能")
                .width("100%")
                .height(40)
                .fontSize(14)
                .fontColor("#2563eb")
                .backgroundColor("#ffffff")
                .border({ width: 1, color: "#2563eb", radius: 8 })
                .margin({ top: 16 })
                .onClick {
                    resumeData.skills.add(Skill())
                }
        }
        .width("100%")
    }

    @Builder
    private func buildSkillItem(skill: Skill, index: Int32): void {
        Row() {
            TextInput({ text: skill.name })
                .layoutWeight(1)
                .height(40)
                .onChange({ value => skill.name = value })

            TextInput({ text: skill.level })
                .width(80)
                .height(40)
                .margin({ left: 8 })
                .onChange({ value => skill.level = value })

            Image($r("app.media.ic_delete"))
                .width(20)
                .height(20)
                .margin({ left: 8 })
                .onClick {
                    resumeData.skills.removeAt(index)
                }
        }
        .width("100%")
        .margin({ top: 8 })
    }

    @Builder
    private func buildProjectsSection(): void {
        Column() {
            Text("项目经验")
                .fontSize(16)
                .fontColor("#1e293b")
        }
        .width("100%")
        .padding(16)
    }

    @Builder
    private func buildInputField(label: String, value: String, onChange: (String) -> void): void {
        Column() {
            Text(label)
                .fontSize(12)
                .fontColor("#64748b")
                .width("100%")

            TextInput({ text: value })
                .width("100%")
                .height(40)
                .margin({ top: 4 })
                .onChange(onChange)
        }
        .width("100%")
        .alignItems(HorizontalAlign.Start)
        .margin({ top: 12 })
    }

    @Builder
    private func buildTextArea(label: String, value: String, onChange: (String) -> void): void {
        Column() {
            Text(label)
                .fontSize(12)
                .fontColor("#64748b")
                .width("100%")

            TextArea({ text: value })
                .width("100%")
                .height(100)
                .margin({ top: 4 })
                .onChange(onChange)
        }
        .width("100%")
        .alignItems(HorizontalAlign.Start)
        .margin({ top: 12 })
    }

    @Builder
    private func buildAIMenu(): void {
        Column() {
            Text("AI 助手")
                .fontSize(16)
                .fontWeight(FontWeight.Bold)
                .fontColor("#1e293b")
                .width("100%")

            Button("生成个人简介")
                .width("100%")
                .margin({ top: 12 })
                .onClick {
                    this.generateWithAI("summary")
                }

            Button("优化当前内容")
                .width("100%")
                .margin({ top: 8 })
                .onClick {
                    this.optimizeWithAI()
                }

            Button("生成工作描述")
                .width("100%")
                .margin({ top: 8 })
                .onClick {
                    this.generateWithAI("experience")
                }
        }
        .width("80%")
        .padding(16)
        .backgroundColor("#ffffff")
        .borderRadius(12)
        .position({ x: "10%", y: "20%" })
        .shadow({ radius: 20, color: "#1e293b", offsetX: 0, offsetY: 4 })
    }

    private func loadResume(): void {
        isLoading = true
        let result = resumeService.getResume(resumeId)
        isLoading = false

        if (result.isSuccess()) {
            let value = result.getValue()
            if (value is Some<Resume>) {
                resume = value.get()
            }
        }
    }

    private func saveResume(): void {
        let result = resumeService.updateResume(resumeId, resume)
        if (result.isSuccess()) {
            // 显示保存成功提示
            println("Resume saved successfully")
        }
    }

    private func generateWithAI(section: String): void {
        showAIMenu = false
        let request = AIGenerateRequest()
        request.resumeId = resumeId
        request.section = section
        request.prompt = "请生成${section}内容"

        let result = aiService.generateContent(request)
        if (result.isSuccess()) {
            let value = result.getValue()
            if (value is Some<AIGenerateResponse>) {
                // 更新对应section的内容
                println("AI generated: ${value.get().content}")
            }
        }
    }

    private func optimizeWithAI(): void {
        showAIMenu = false
        // 实现优化逻辑
    }
}
