// ResumeListPage.cj - 简历列表页（同步自 Web 版 ResumeListPage）
package views

import ohos.arkui.*
import ohos.arkui.state.*
import ohos.arkui.node.*
import services.*
import models.*
import std.collection.*

@Entry
@Component
public struct ResumeListPage {
    @State private var resumes: ArrayList<Resume> = ArrayList<Resume>()
    @State private var isLoading: Bool = true
    @State private var errorMessage: String = ""
    @State private var searchQuery: String = ""
    @State private var filterStatus: String = ""  // "", "draft", "published"
    @State private var showCreateDialog: Bool = false
    @State private var newResumeTitle: String = ""
    @State private var selectedTemplateId: Int64 = 1

    private let resumeService: ResumeService
    private let authService: AuthService = AuthService()
    private let templateService: TemplateService

    public init() {
        let httpClient = HttpClient(ApiConfig.BASE_URL + ApiConfig.API_VERSION)
        let token = authService.getCurrentToken()
        if (token.accessToken != "") {
            httpClient.setAuthToken(token.accessToken)
        }
        this.resumeService = ResumeService(httpClient)
        this.templateService = TemplateService(httpClient)
    }

    public func aboutToAppear(): void {
        this.loadResumes()
    }

    public func build(): void {
        Column() {
            // 顶部导航栏
            this.buildNavBar()

            // 搜索栏和筛选
            this.buildSearchBar()

            // 内容区域
            if (isLoading) {
                this.buildLoading()
            } else if (errorMessage != "") {
                this.buildError()
            } else if (resumes.size() == 0) {
                this.buildEmpty()
            } else {
                this.buildResumeList()
            }

            // 创建简历浮动按钮
            this.buildFab()
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
                    Router.back()
                }

            Text("我的简历")
                .fontSize(18)
                .fontWeight(FontWeight.Bold)
                .fontColor("#1e293b")
                .margin({ left: 12 })

            Blank()

            Text("共 ${resumes.size()} 份")
                .fontSize(14)
                .fontColor("#64748b")
        }
        .width("100%")
        .height(56)
        .padding({ left: 16, right: 16 })
        .backgroundColor("#ffffff")
        .shadow({ radius: 2, color: "#1e293b", offsetX: 0, offsetY: 2 })
    }

    // ==================== 搜索栏 ====================
    @Builder
    private func buildSearchBar(): void {
        Column() {
            // 搜索输入框
            Row() {
                Text("🔍")
                    .fontSize(16)
                    .margin({ right: 8 })

                TextInput(placeholder: "搜索简历...", text: searchQuery)
                    .layoutWeight(1)
                    .height(40)
                    .backgroundColor("#f1f5f9")
                    .borderRadius(20)
                    .onChange({ (value: String) =>
                        searchQuery = value
                        this.loadResumes()
                    })
            }
            .width("100%")
            .padding({ left: 16, right: 16 })
            .margin({ top: 12 })

            // 筛选标签
            Row() {
                this.buildFilterChip("全部", "")
                this.buildFilterChip("草稿", "draft")
                this.buildFilterChip("已发布", "published")
            }
            .width("100%")
            .padding({ left: 16, right: 16, top: 8, bottom: 8 })
            .justifyContent(FlexAlign.Start)
        }
        .width("100%")
        .backgroundColor("#ffffff")
        .padding({ bottom: 8 })
    }

    @Builder
    private func buildFilterChip(label: String, status: String): void {
        Text(label)
            .fontSize(13)
            .fontColor(filterStatus == status ? "#ffffff" : "#64748b")
            .backgroundColor(filterStatus == status ? "#2563eb" : "#f1f5f9")
            .borderRadius(16)
            .padding({ left: 16, right: 16, top: 6, bottom: 6 })
            .margin({ right: 8 })
            .onClick {
                filterStatus = status
                this.loadResumes()
            }
    }

    // ==================== 加载中 ====================
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
                .margin({ top: 12 })
        }
        .width("100%")
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
    }

    // ==================== 错误提示 ====================
    @Builder
    private func buildError(): void {
        Column() {
            Text("😕")
                .fontSize(48)

            Text(errorMessage)
                .fontSize(14)
                .fontColor("#ef4444")
                .margin({ top: 12 })
                .textAlign(TextAlign.Center)
                .padding({ left: 32, right: 32 })

            Text("重试")
                .fontSize(14)
                .fontColor("#2563eb")
                .margin({ top: 16 })
                .padding({ left: 24, right: 24, top: 8, bottom: 8 })
                .borderRadius(20)
                .border({ width: 1, color: "#2563eb" })
                .onClick {
                    this.loadResumes()
                }
        }
        .width("100%")
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
    }

    // ==================== 空状态 ====================
    @Builder
    private func buildEmpty(): void {
        Column() {
            Image($r("app.media.empty_resume"))
                .width(120)
                .height(120)

            Text("还没有简历")
                .fontSize(18)
                .fontWeight(FontWeight.Bold)
                .fontColor("#1e293b")
                .margin({ top: 16 })

            Text("点击下方按钮创建你的第一份AI简历")
                .fontSize(14)
                .fontColor("#64748b")
                .margin({ top: 8 })

            Text("创建简历")
                .fontSize(16)
                .fontColor("#ffffff")
                .backgroundColor("#2563eb")
                .borderRadius(24)
                .padding({ left: 32, right: 32, top: 12, bottom: 12 })
                .margin({ top: 24 })
                .onClick {
                    showCreateDialog = true
                }
        }
        .width("100%")
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
    }

    // ==================== 简历列表 ====================
    @Builder
    private func buildResumeList(): void {
        Scroll() {
            Column() {
                ForEach(this.getFilteredResumes(), { (resume: Resume, index: Int32) =>
                    this.buildResumeCard(resume)
                })
            }
            .width("100%")
            .padding({ left: 16, right: 16, top: 8, bottom: 80 })
        }
        .width("100%")
        .layoutWeight(1)
    }

    @Builder
    private func buildResumeCard(resume: Resume): void {
        Column() {
            // 标题行
            Row() {
                Text(resume.title != "" ? resume.title : "未命名简历")
                    .fontSize(16)
                    .fontWeight(FontWeight.Bold)
                    .fontColor("#1e293b")
                    .maxLines(1)
                    .textOverflow(TextOverflow.Ellipsis)
                    .layoutWeight(1)

                // 状态标签
                Text(resume.status == "draft" ? "草稿" : "已发布")
                    .fontSize(11)
                    .fontColor(resume.status == "draft" ? "#f59e0b" : "#10b981")
                    .backgroundColor(resume.status == "draft" ? "#fef3c7" : "#d1fae5")
                    .borderRadius(10)
                    .padding({ left: 8, right: 8, top: 2, bottom: 2 })
            }
            .width("100%")

            // 描述
            if (resume.description != "") {
                Text(resume.description)
                    .fontSize(13)
                    .fontColor("#64748b")
                    .margin({ top: 6 })
                    .maxLines(2)
                    .textOverflow(TextOverflow.Ellipsis)
            }

            // 模板和时间
            Row() {
                if (resume.templateName != "") {
                    Row() {
                        Text("📄")
                            .fontSize(12)
                        Text(resume.templateName)
                            .fontSize(12)
                            .fontColor("#64748b")
                            .margin({ left: 4 })
                    }
                }

                Blank()

                Text(resume.updatedAt != "" ? resume.updatedAt.substring(0, 10) : "")
                    .fontSize(12)
                    .fontColor("#94a3b8")
            }
            .width("100%")
            .margin({ top: 12 })

            // 操作按钮
            Row() {
                Text("编辑")
                    .fontSize(13)
                    .fontColor("#2563eb")
                    .padding({ left: 12, right: 12, top: 6, bottom: 6 })
                    .borderRadius(16)
                    .backgroundColor("#eff6ff")
                    .onClick {
                        Router.push({ url: "pages/ResumeEditorPage", params: { "resumeId": resume.id } })
                    }

                Text("复制")
                    .fontSize(13)
                    .fontColor("#64748b")
                    .padding({ left: 12, right: 12, top: 6, bottom: 6 })
                    .borderRadius(16)
                    .backgroundColor("#f1f5f9")
                    .margin({ left: 8 })
                    .onClick {
                        this.copyResume(resume.id)
                    }

                Text("删除")
                    .fontSize(13)
                    .fontColor("#ef4444")
                    .padding({ left: 12, right: 12, top: 6, bottom: 6 })
                    .borderRadius(16)
                    .backgroundColor("#fef2f2")
                    .margin({ left: 8 })
                    .onClick {
                        this.deleteResume(resume.id)
                    }

                Blank()

                // AI优化按钮
                Text("AI优化")
                    .fontSize(13)
                    .fontColor("#8b5cf6")
                    .padding({ left: 12, right: 12, top: 6, bottom: 6 })
                    .borderRadius(16)
                    .backgroundColor("#f5f3ff")
                    .onClick {
                        Router.push({ url: "pages/AIGeneratePage", params: { "resumeId": resume.id } })
                    }
            }
            .width("100%")
            .margin({ top: 12 })
        }
        .width("100%")
        .padding(16)
        .backgroundColor("#ffffff")
        .borderRadius(12)
        .margin({ top: 8 })
        .shadow({ radius: 4, color: "#0f172a", offsetX: 0, offsetY: 2 })
        .onClick {
            Router.push({ url: "pages/ResumeEditorPage", params: { "resumeId": resume.id } })
        }
    }

    // ==================== 浮动按钮 ====================
    @Builder
    private func buildFab(): void {
        Row() {
            Text("+ 新建简历")
                .fontSize(16)
                .fontColor("#ffffff")
                .fontWeight(FontWeight.Bold)
        }
        .width("100%")
        .height(52)
        .backgroundColor("#2563eb")
        .justifyContent(FlexAlign.Center)
        .alignItems(VerticalAlign.Center)
        .onClick {
            showCreateDialog = true
        }
    }

    // ==================== 数据操作 ====================

    private func loadResumes(): void {
        isLoading = true
        errorMessage = ""

        let filter = ResumeFilter()
        filter.search = searchQuery
        filter.status = filterStatus

        let result = resumeService.getResumes(filter)
        isLoading = false

        if (result.isSuccess()) {
            let value = result.getValue()
            if (value is Some<PaginatedResponse<Resume>>) {
                resumes = value.get().data
            }
        } else {
            // 降级：尝试简单列表
            let simpleResult = resumeService.getResumes()
            if (simpleResult.isSuccess()) {
                let value = simpleResult.getValue()
                if (value is Some<ArrayList<Resume>>) {
                    resumes = value.get()
                }
            } else {
                errorMessage = "加载简历失败，请重试"
            }
        }
    }

    private func getFilteredResumes(): ArrayList<Resume> {
        var filtered = ArrayList<Resume>()
        for (i in 0..resumes.size()) {
            let resume = resumes.get(i)
            // 状态筛选
            if (filterStatus != "" && resume.status != filterStatus) {
                continue
            }
            // 搜索筛选
            if (searchQuery != "") {
                let query = searchQuery.toLowerCase()
                let titleMatch = resume.title.toLowerCase().contains(query)
                let descMatch = resume.description.toLowerCase().contains(query)
                if (!titleMatch && !descMatch) {
                    continue
                }
            }
            filtered.add(resume)
        }
        return filtered
    }

    private func createResume(): void {
        if (newResumeTitle == "") {
            newResumeTitle = "未命名简历"
        }

        let result = resumeService.createResume(newResumeTitle, selectedTemplateId)
        if (result.isSuccess()) {
            let value = result.getValue()
            if (value is Some<Resume>) {
                showCreateDialog = false
                newResumeTitle = ""
                // 跳转到编辑页
                Router.push({ url: "pages/ResumeEditorPage", params: { "resumeId": value.get().id } })
            }
        } else {
            errorMessage = "创建简历失败"
        }
    }

    private func copyResume(id: Int64): void {
        let result = resumeService.copyResume(id)
        if (result.isSuccess()) {
            this.loadResumes()
        }
    }

    private func deleteResume(id: Int64): void {
        let result = resumeService.deleteResume(id)
        if (result.isSuccess()) {
            this.loadResumes()
        }
    }
}
