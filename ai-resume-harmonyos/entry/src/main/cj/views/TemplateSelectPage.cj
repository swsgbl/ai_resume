// TemplateSelectPage.cj - 模板选择页面
package views

import ohos.arkui.*
import ohos.arkui.state.*
import ohos.arkui.node.*
import services.*
import models.*
import std.collection.*

@Entry
@Component
public struct TemplateSelectPage {
    @State private var templates: ArrayList<Template> = ArrayList<Template>()
    @State private var categories: ArrayList<TemplateCategory> = ArrayList<TemplateCategory>()
    @State private var selectedCategory: String = "all"
    @State private var isLoading: Bool = true
    @State private var selectedTemplate: ?Template = None

    private let templateService: TemplateService

    public init() {
        let httpClient = HttpClient(ApiConfig.BASE_URL + ApiConfig.API_VERSION)
        let authService = AuthService()
        let token = authService.getCurrentToken()
        if (token.accessToken != "") {
            httpClient.setAuthToken(token.accessToken)
        }
        this.templateService = TemplateService(httpClient)
    }

    public func aboutToAppear(): void {
        this.loadTemplates()
        this.loadCategories()
    }

    public func build(): void {
        Column() {
            // 顶部栏
            this.buildHeader()

            // 分类选择
            this.buildCategorySelector()

            // 模板列表
            if (isLoading) {
                this.buildLoading()
            } else {
                this.buildTemplateGrid()
            }

            // 底部按钮
            this.buildBottomBar()
        }
        .width("100%")
        .height("100%")
        .backgroundColor("#f5f5f5")
    }

    @Builder
    private func buildHeader(): void {
        Row() {
            Image($r("app.media.ic_back"))
                .width(24)
                .height(24)
                .onClick {
                    Router.back()
                }

            Text("选择模板")
                .fontSize(18)
                .fontWeight(FontWeight.Bold)
                .fontColor("#1e293b")
                .margin({ left: 16 })
                .layoutWeight(1)
        }
        .width("100%")
        .height(56)
        .padding({ left: 16, right: 16 })
        .backgroundColor("#ffffff")
        .shadow({ radius: 2, color: "#1e293b", offsetX: 0, offsetY: 2 })
    }

    @Builder
    private func buildCategorySelector(): void {
        Scroll() {
            Row() {
                this.buildCategoryTab("全部", "all")

                ForEach(categories, { (category: TemplateCategory) =>
                    this.buildCategoryTab(category.name, category.id)
                })
            }
            .padding({ left: 16, right: 16 })
        }
        .scrollable(ScrollDirection.Horizontal)
        .width("100%")
        .height(48)
        .backgroundColor("#ffffff")
    }

    @Builder
    private func buildCategoryTab(label: String, categoryId: String): void {
        Text(label)
            .fontSize(14)
            .fontColor(selectedCategory == categoryId ? "#ffffff" : "#64748b")
            .backgroundColor(selectedCategory == categoryId ? "#2563eb" : "#f1f5f9")
            .borderRadius(16)
            .padding({ left: 16, right: 16, top: 8, bottom: 8 })
            .margin({ right: 8 })
            .onClick {
                selectedCategory = categoryId
                this.loadTemplatesByCategory(categoryId)
            }
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
    private func buildTemplateGrid(): void {
        Grid() {
            ForEach(templates, { (template: Template) =>
                GridItem() {
                    this.buildTemplateCard(template)
                }
            })
        }
        .columnsTemplate("1fr 1fr")
        .rowsGap(16)
        .columnsGap(16)
        .width("100%")
        .layoutWeight(1)
        .padding(16)
    }

    @Builder
    private func buildTemplateCard(template: Template): void {
        Column() {
            // 模板预览图
            Image(template.preview)
                .width("100%")
                .height(120)
                .objectFit(ImageFit.Cover)
                .borderRadius({ topLeft: 8, topRight: 8 })

            // 模板信息
            Column() {
                Row() {
                    Text(template.name)
                        .fontSize(14)
                        .fontWeight(FontWeight.Bold)
                        .fontColor("#1e293b")
                        .layoutWeight(1)

                    if (template.isPremium) {
                        Text("PRO")
                            .fontSize(10)
                            .fontColor("#ffffff")
                            .backgroundColor("#f59e0b")
                            .borderRadius(4)
                            .padding({ left: 4, right: 4, top: 2, bottom: 2 })
                    }
                }
                .width("100%")

                Text(template.description)
                    .fontSize(12)
                    .fontColor("#64748b")
                    .margin({ top: 4 })
                    .maxLines(2)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })
            }
            .width("100%")
            .padding(8)
            .alignItems(HorizontalAlign.Start)

            // 选中状态
            let isSelected = this.isTemplateSelected(template)
            if (isSelected) {
                Row() {
                    Image($r("app.media.ic_check"))
                        .width(16)
                        .height(16)
                        .color("#ffffff")
                }
                .width("100%")
                .height(32)
                .backgroundColor("#2563eb")
                .justifyContent(FlexAlign.Center)
            }
        }
        .width("100%")
        .backgroundColor("#ffffff")
        .borderRadius(8)
        .border({
            width: isSelected ? 2 : 1,
            color: isSelected ? "#2563eb" : "#e2e8f0"
        })
        .onClick {
            selectedTemplate = Some(template)
        }
    }

    @Builder
    private func buildBottomBar(): void {
        Row() {
            Column() {
                Text("已选择")
                    .fontSize(12)
                    .fontColor("#64748b")

                Text(this.getSelectedTemplateName())
                    .fontSize(14)
                    .fontWeight(FontWeight.Bold)
                    .fontColor("#1e293b")
            }
            .alignItems(HorizontalAlign.Start)
            .layoutWeight(1)

            Button("下一步")
                .width(120)
                .height(40)
                .fontSize(16)
                .fontColor("#ffffff")
                .backgroundColor("#2563eb")
                .borderRadius(8)
                .enabled(selectedTemplate is Some<Template>)
                .onClick {
                    this.createResumeWithTemplate()
                }
        }
        .width("100%")
        .height(72)
        .padding({ left: 16, right: 16 })
        .backgroundColor("#ffffff")
        .shadow({ radius: 4, color: "#1e293b", offsetX: 0, offsetY: -2 })
    }

    private func loadTemplates(): void {
        isLoading = true
        let result = templateService.getTemplates()
        isLoading = false

        if (result.isSuccess()) {
            let value = result.getValue()
            if (value is Some<ArrayList<Template>>) {
                templates = value.get()
            }
        }
    }

    private func loadCategories(): void {
        let result = templateService.getCategories()
        if (result.isSuccess()) {
            let value = result.getValue()
            if (value is Some<ArrayList<TemplateCategory>>) {
                categories = value.get()
            }
        }
    }

    private func loadTemplatesByCategory(categoryId: String): void {
        if (categoryId == "all") {
            loadTemplates()
            return
        }

        isLoading = true
        let result = templateService.getTemplatesByCategory(categoryId)
        isLoading = false

        if (result.isSuccess()) {
            let value = result.getValue()
            if (value is Some<ArrayList<Template>>) {
                templates = value.get()
            }
        }
    }

    private func isTemplateSelected(template: Template): Bool {
        if (selectedTemplate is Some<Template>) {
            return (selectedTemplate as Some<Template>).get().id == template.id
        }
        return false
    }

    private func getSelectedTemplateName(): String {
        if (selectedTemplate is Some<Template>) {
            return (selectedTemplate as Some<Template>).get().name
        }
        return "请选择模板"
    }

    private func createResumeWithTemplate(): void {
        if (selectedTemplate is Some<Template>) {
            let template = (selectedTemplate as Some<Template>).get()
            Router.push({
                url: "pages/ResumeEditorPage",
                params: {
                    "templateId": template.id,
                    "templateName": template.name
                }
            })
        }
    }
}
