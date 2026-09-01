// HomePage.cj - 主页（增强版 - 对齐其他版本的开发进度）
package views

import ohos.arkui.*
import ohos.arkui.state.*
import ohos.arkui.node.*
import services.*
import models.*
import std.collection.*

@Entry
@Component
public struct HomePage {
    @State private var resumes: ArrayList<Resume> = ArrayList<Resume>()
    @State private var isLoading: Bool = true
    @State private var currentTab: Int32 = 0

    private let resumeService: ResumeService
    private let authService: AuthService = AuthService()

    public init() {
        let httpClient = HttpClient(ApiConfig.BASE_URL + ApiConfig.API_VERSION)
        let token = authService.getCurrentToken()
        if (token.accessToken != "") {
            httpClient.setAuthToken(token.accessToken)
        }
        this.resumeService = ResumeService(httpClient)
    }

    public func aboutToAppear(): void {
        this.loadResumes()
    }

    public func build(): void {
        Column() {
            // 顶部栏
            this.buildHeader()

            // 标签页
            this.buildTabs()

            // 内容区域
            if (isLoading) {
                this.buildLoading()
            } else {
                this.buildContent()
            }

            // 底部导航
            this.buildBottomNav()
        }
        .width("100%")
        .height("100%")
        .backgroundColor("#f5f5f5")
    }

    @Builder
    private func buildHeader(): void {
        Row() {
            Text("AI 简历")
                .fontSize(20)
                .fontWeight(FontWeight.Bold)
                .fontColor("#1e293b")

            Blank()

            // 用户头像
            Image($r("app.media.avatar_default"))
                .width(36)
                .height(36)
                .borderRadius(18)
                .onClick {
                    Router.push({ url: "pages/ProfilePage" })
                }
        }
        .width("100%")
        .height(56)
        .padding({ left: 16, right: 16 })
        .backgroundColor("#ffffff")
        .shadow({ radius: 2, color: "#1e293b", offsetX: 0, offsetY: 2 })
    }

    @Builder
    private func buildTabs(): void {
        Row() {
            ForEach(["我的简历", "模板", "AI助手", "我的"], { (item: String, index: Int32) =>
                Text(item)
                    .fontSize(14)
                    .fontColor(currentTab == index ? "#2563eb" : "#64748b")
                    .fontWeight(currentTab == index ? FontWeight.Bold : FontWeight.Normal)
                    .padding({ left: 16, right: 16, top: 12, bottom: 12 })
                    .onClick {
                        currentTab = index
                    }
            })
        }
        .width("100%")
        .backgroundColor("#ffffff")
        .justifyContent(FlexAlign.SpaceAround)
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
        .height("100%")
        .justifyContent(FlexAlign.Center)
    }

    @Builder
    private func buildContent(): void {
        if (currentTab == 0) {
            this.buildResumeTab()
        } else if (currentTab == 1) {
            this.buildTemplateTab()
        } else if (currentTab == 2) {
            this.buildAITab()
        } else {
            this.buildProfileTab()
        }
    }

    // ==================== 简历标签页 ====================
    @Builder
    private func buildResumeTab(): void {
        Column() {
            if (resumes.size() == 0) {
                this.buildEmptyState()
            } else {
                // 查看全部入口
                Row() {
                    Text("最近简历")
                        .fontSize(16)
                        .fontWeight(FontWeight.Bold)
                        .fontColor("#1e293b")

                    Blank()

                    Row() {
                        Text("查看全部")
                            .fontSize(13)
                            .fontColor("#2563eb")
                        Image($r("app.media.ic_arrow_right"))
                            .width(14)
                            .height(14)
                            .margin({ left: 2 })
                    }
                    .onClick {
                        Router.push({ url: "pages/ResumeListPage" })
                    }
                }
                .width("100%")
                .padding({ left: 16, right: 16, top: 12 })

                List() {
                    ForEach(resumes, { (resume: Resume) =>
                        ListItem() {
                            this.buildResumeItem(resume)
                        }
                    })
                }
                .width("100%")
                .layoutWeight(1)
            }

            // 创建按钮
            this.buildCreateButton()
        }
        .width("100%")
        .layoutWeight(1)
    }

    @Builder
    private func buildEmptyState(): void {
        Column() {
            Image($r("app.media.empty_resume"))
                .width(120)
                .height(120)

            Text("还没有简历")
                .fontSize(16)
                .fontColor("#1e293b")
                .margin({ top: 16 })

            Text("点击下方按钮创建第一份简历")
                .fontSize(14)
                .fontColor("#64748b")
                .margin({ top: 8 })
        }
        .width("100%")
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
    }

    @Builder
    private func buildResumeItem(resume: Resume): void {
        Row() {
            Column() {
                Text(resume.title)
                    .fontSize(16)
                    .fontWeight(FontWeight.Bold)
                    .fontColor("#1e293b")

                Text(resume.templateName)
                    .fontSize(12)
                    .fontColor("#64748b")
                    .margin({ top: 4 })

                Row() {
                    Text(resume.status == "draft" ? "草稿" : "已完成")
                        .fontSize(10)
                        .fontColor("#ffffff")
                        .backgroundColor(resume.status == "draft" ? "#f59e0b" : "#10b981")
                        .borderRadius(4)
                        .padding({ left: 6, right: 6, top: 2, bottom: 2 })

                    Text("版本 ${resume.version}")
                        .fontSize(10)
                        .fontColor("#64748b")
                        .margin({ left: 8 })
                }
                .margin({ top: 8 })
            }
            .alignItems(HorizontalAlign.Start)
            .layoutWeight(1)

            Image($r("app.media.ic_arrow_right"))
                .width(24)
                .height(24)
        }
        .width("100%")
        .padding(16)
        .backgroundColor("#ffffff")
        .margin({ top: 8 })
        .borderRadius(8)
        .onClick {
            Router.push({ url: "pages/ResumeEditorPage", params: { "resumeId": resume.id } })
        }
    }

    @Builder
    private func buildCreateButton(): void {
        Button("创建新简历")
            .width("90%")
            .height(48)
            .fontSize(16)
            .fontColor("#ffffff")
            .backgroundColor("#2563eb")
            .borderRadius(8)
            .margin({ top: 16, bottom: 16 })
            .onClick {
                Router.push({ url: "pages/TemplateSelectPage" })
            }
    }

    // ==================== 模板标签页 ====================
    @Builder
    private func buildTemplateTab(): void {
        Column() {
            // 快速操作卡片
            Row() {
                this.buildQuickAction("浏览模板", $r("app.media.ic_template"), "#2563eb")
                this.buildQuickAction("从模板创建", $r("app.media.ic_resume"), "#8b5cf6")
            }
            .width("100%")
            .padding({ left: 16, right: 16, top: 16 })
            .justifyContent(FlexAlign.SpaceBetween)

            // 分类入口
            Column() {
                Text("模板分类")
                    .fontSize(16)
                    .fontWeight(FontWeight.Bold)
                    .fontColor("#1e293b")
                    .width("100%")
                    .padding({ left: 16, top: 16 })

                Row() {
                    this.buildCategoryCard("专业", "💼")
                    this.buildCategoryCard("创意", "🎨")
                    this.buildCategoryCard("简约", "✨")
                    this.buildCategoryCard("学术", "🎓")
                }
                .width("100%")
                .padding({ left: 16, right: 16, top: 12 })
                .justifyContent(FlexAlign.SpaceBetween)

                Text("查看全部模板 →")
                    .fontSize(14)
                    .fontColor("#2563eb")
                    .margin({ top: 16 })
                    .onClick {
                        Router.push({ url: "pages/TemplateSelectPage" })
                    }
            }
            .width("100%")
            .layoutWeight(1)
        }
        .width("100%")
        .layoutWeight(1)
    }

    @Builder
    private func buildQuickAction(label: String, icon: Resource, color: String): void {
        Column() {
            Image(icon)
                .width(32)
                .height(32)
                .color(color)
            Text(label)
                .fontSize(13)
                .fontColor("#1e293b")
                .margin({ top: 8 })
        }
        .width("48%")
        .height(90)
        .backgroundColor("#ffffff")
        .borderRadius(12)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
        .shadow({ radius: 4, color: "#1e293b", offsetX: 0, offsetY: 2 })
        .onClick {
            Router.push({ url: "pages/TemplateSelectPage" })
        }
    }

    @Builder
    private func buildCategoryCard(name: String, icon: String): void {
        Column() {
            Text(icon)
                .fontSize(28)
            Text(name)
                .fontSize(12)
                .fontColor("#64748b")
                .margin({ top: 4 })
        }
        .width(76)
        .height(80)
        .backgroundColor("#ffffff")
        .borderRadius(12)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
        .shadow({ radius: 2, color: "#1e293b", offsetX: 0, offsetY: 1 })
        .onClick {
            Router.push({ url: "pages/TemplateSelectPage" })
        }
    }

    // ==================== AI助手标签页 ====================
    @Builder
    private func buildAITab(): void {
        Scroll() {
            Column() {
                // AI生成入口卡片
                Column() {
                    Row() {
                        Text("🤖")
                            .fontSize(32)
                        Column() {
                            Text("AI 智能生成简历")
                                .fontSize(16)
                                .fontWeight(FontWeight.Bold)
                                .fontColor("#1e293b")
                            Text("输入目标职位，AI自动生成专业简历")
                                .fontSize(12)
                                .fontColor("#64748b")
                                .margin({ top: 4 })
                        }
                        .margin({ left: 12 })
                        .alignItems(HorizontalAlign.Start)
                        .layoutWeight(1)
                    }
                    .width("100%")

                    Text("立即体验")
                        .fontSize(14)
                        .fontColor("#ffffff")
                        .backgroundColor("#8b5cf6")
                        .borderRadius(20)
                        .padding({ left: 24, right: 24, top: 10, bottom: 10 })
                        .margin({ top: 16 })
                        .onClick {
                            Router.push({ url: "pages/AIGeneratePage" })
                        }
                }
                .width("100%")
                .padding(20)
                .backgroundColor("#ffffff")
                .borderRadius(12)
                .margin({ top: 16, left: 16, right: 16 })
                .shadow({ radius: 4, color: "#1e293b", offsetX: 0, offsetY: 2 })

                // AI功能列表
                Column() {
                    this.buildAIFeatureRow("✨", "AI内容生成", "根据背景信息生成简历各模块内容")
                    this.buildAIFeatureRow("🎯", "AI目标优化", "针对特定职位优化简历内容")
                    this.buildAIFeatureRow("📊", "AI量化成果", "将工作描述转化为量化成果")
                    this.buildAIFeatureRow("💎", "AI润色表达", "让简历语言更加专业精炼")
                }
                .width("100%")
                .padding(16)
                .margin({ top: 12, left: 16, right: 16 })

                // 使用统计
                Column() {
                    Text("AI 使用统计")
                        .fontSize(14)
                        .fontWeight(FontWeight.Bold)
                        .fontColor("#1e293b")
                        .margin({ bottom: 12 })

                    Row() {
                        Column() {
                            Text("--")
                                .fontSize(20)
                                .fontWeight(FontWeight.Bold)
                                .fontColor("#2563eb")
                            Text("已生成")
                                .fontSize(11)
                                .fontColor("#64748b")
                                .margin({ top: 4 })
                        }
                        .layoutWeight(1)

                        Column() {
                            Text("--")
                                .fontSize(20)
                                .fontWeight(FontWeight.Bold)
                                .fontColor("#8b5cf6")
                            Text("已优化")
                                .fontSize(11)
                                .fontColor("#64748b")
                                .margin({ top: 4 })
                        }
                        .layoutWeight(1)

                        Column() {
                            Text("--")
                                .fontSize(20)
                                .fontWeight(FontWeight.Bold)
                                .fontColor("#10b981")
                            Text("已导出")
                                .fontSize(11)
                                .fontColor("#64748b")
                                .margin({ top: 4 })
                        }
                        .layoutWeight(1)
                    }
                    .width("100%")
                }
                .width("100%")
                .padding(16)
                .backgroundColor("#ffffff")
                .borderRadius(12)
                .margin({ top: 12, left: 16, right: 16, bottom: 16 })
            }
        }
        .width("100%")
        .layoutWeight(1)
    }

    @Builder
    private func buildAIFeatureRow(icon: String, title: String, desc: String): void {
        Row() {
            Text(icon)
                .fontSize(24)
            Column() {
                Text(title)
                    .fontSize(14)
                    .fontWeight(FontWeight.Medium)
                    .fontColor("#1e293b")
                Text(desc)
                    .fontSize(12)
                    .fontColor("#64748b")
                    .margin({ top: 2 })
            }
            .margin({ left: 12 })
            .alignItems(HorizontalAlign.Start)
            .layoutWeight(1)

            Image($r("app.media.ic_arrow_right"))
                .width(16)
                .height(16)
        }
        .width("100%")
        .padding({ top: 12, bottom: 12 })
        .onClick {
            Router.push({ url: "pages/AIGeneratePage" })
        }
    }

    // ==================== 个人中心标签页 ====================
    @Builder
    private func buildProfileTab(): void {
        Scroll() {
            Column() {
                // 用户信息卡片
                Column() {
                    Image($r("app.media.avatar_default"))
                        .width(64)
                        .height(64)
                        .borderRadius(32)

                    Text("AI简历用户")
                        .fontSize(18)
                        .fontWeight(FontWeight.Bold)
                        .fontColor("#1e293b")
                        .margin({ top: 12 })

                    Text("点击查看个人资料")
                        .fontSize(13)
                        .fontColor("#64748b")
                        .margin({ top: 4 })
                }
                .width("100%")
                .padding(24)
                .backgroundColor("#ffffff")
                .borderRadius(12)
                .margin({ top: 16, left: 16, right: 16 })
                .alignItems(HorizontalAlign.Center)
                .shadow({ radius: 4, color: "#1e293b", offsetX: 0, offsetY: 2 })
                .onClick {
                    Router.push({ url: "pages/ProfilePage" })
                }

                // 功能菜单
                Column() {
                    this.buildMenuItem("个人资料", $r("app.media.ic_profile"), "pages/ProfilePage")
                    this.buildMenuItem("账号设置", $r("app.media.ic_settings"), "pages/AccountSettingsPage")
                    this.buildMenuItem("应用设置", $r("app.media.ic_settings"), "pages/SettingsPage")
                    this.buildMenuItem("我的简历", $r("app.media.ic_resume"), "pages/ResumeListPage")
                    this.buildMenuItem("AI生成", $r("app.media.ic_ai"), "pages/AIGeneratePage")
                }
                .width("100%")
                .padding({ left: 16, right: 16, top: 8 })
            }
        }
        .width("100%")
        .layoutWeight(1)
    }

    @Builder
    private func buildMenuItem(label: String, icon: Resource, targetPage: String): void {
        Row() {
            Image(icon)
                .width(20)
                .height(20)
                .color("#64748b")
            Text(label)
                .fontSize(15)
                .fontColor("#1e293b")
                .margin({ left: 12 })
                .layoutWeight(1)
            Image($r("app.media.ic_arrow_right"))
                .width(16)
                .height(16)
                .color("#94a3b8")
        }
        .width("100%")
        .height(52)
        .padding({ left: 16, right: 16 })
        .backgroundColor("#ffffff")
        .margin({ top: 1 })
        .onClick {
            Router.push({ url: targetPage })
        }
    }

    // ==================== 底部导航 ====================
    @Builder
    private func buildBottomNav(): void {
        Row() {
            this.buildNavItem("首页", $r("app.media.ic_home"), 0)
            this.buildNavItem("模板", $r("app.media.ic_template"), 1)
            this.buildNavItem("AI", $r("app.media.ic_ai"), 2)
            this.buildNavItem("我的", $r("app.media.ic_profile"), 3)
        }
        .width("100%")
        .height(56)
        .backgroundColor("#ffffff")
        .justifyContent(FlexAlign.SpaceAround)
        .shadow({ radius: 4, color: "#1e293b", offsetX: 0, offsetY: -2 })
    }

    @Builder
    private func buildNavItem(label: String, icon: Resource, index: Int32): void {
        Column() {
            Image(icon)
                .width(24)
                .height(24)
                .color(currentTab == index ? "#2563eb" : "#64748b")

            Text(label)
                .fontSize(10)
                .fontColor(currentTab == index ? "#2563eb" : "#64748b")
                .margin({ top: 4 })
        }
        .onClick {
            currentTab = index
        }
    }

    private func loadResumes(): void {
        isLoading = true
        let result = resumeService.getResumes()
        isLoading = false

        if (result.isSuccess()) {
            let value = result.getValue()
            if (value is Some<ArrayList<Resume>>) {
                resumes = value.get()
            }
        }
    }
}
