// AccountSettingsPage.cj - 账号设置页面（同步自 Web 版 AccountSettingsPage）
// 管理邮箱、手机号、第三方账号绑定
package views

import ohos.arkui.*
import ohos.arkui.state.*
import ohos.arkui.node.*
import services.*
import models.*
import utils.*

@Entry
@Component
public struct AccountSettingsPage {
    @State private var bindings: ?AccountBindings = None
    @State private var isLoading: Bool = true
    @State private var errorMessage: String = ""
    @State private var bindEmail: String = ""
    @State private var bindCode: String = ""
    @State private var bindPassword: String = ""
    @State private var showBindEmailForm: Bool = false
    @State private var bindPhone: String = ""
    @State private var unbindPassword: String = ""

    private let authService: AuthService = AuthService()

    public func aboutToAppear(): void {
        this.loadBindings()
    }

    public func build(): void {
        Column() {
            // 顶部栏
            this.buildHeader()

            if (isLoading) {
                this.buildLoading()
            } else {
                Scroll() {
                    Column() {
                        // 错误提示
                        if (errorMessage != "") {
                            Text(errorMessage)
                                .fontSize(12)
                                .fontColor("#f87171")
                                .backgroundColor("rgba(248,113,113,0.1)")
                                .borderRadius(8)
                                .padding(12)
                                .width("100%")
                                .margin({ bottom: 16 })
                        }

                        // 邮箱账号绑定 - 同步自 Web 版
                        this.buildEmailBinding()

                        // 手机号绑定 - 同步自 Web 版
                        this.buildPhoneBinding()

                        // OAuth 账号列表 - 同步自 Web 版
                        this.buildOAuthBindings()

                        // 安全提示 - 同步自 Web 版
                        this.buildSecurityNotice()

                        // 解绑验证密码 - 同步自 Web 版
                        this.buildUnbindPasswordSection()
                    }
                    .padding(16)
                }
                .layoutWeight(1)
            }
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

            Text("账号设置")
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

    // ==================== 邮箱绑定 ====================
    @Builder
    private func buildEmailBinding(): void {
        Column() {
            Row() {
                Column() {
                    Row() {
                        Text("邮箱")
                            .fontSize(16)
                            .fontWeight(FontWeight.Bold)
                            .fontColor("#1e293b")

                        // 主账号标签
                        if (bindings is Some<AccountBindings>) {
                            let b = (bindings as Some<AccountBindings>).get()
                            if (b.email.isPrimary) {
                                Text("主账号")
                                    .fontSize(10)
                                    .fontColor("#d97706")
                                    .backgroundColor("#fffbeb")
                                    .borderRadius(4)
                                    .padding({ left: 6, right: 6, top: 2, bottom: 2 })
                                    .margin({ left: 8 })
                            }
                            if (b.email.verified) {
                                Text("已验证")
                                    .fontSize(10)
                                    .fontColor("#10b981")
                                    .backgroundColor("#ecfdf5")
                                    .borderRadius(4)
                                    .padding({ left: 6, right: 6, top: 2, bottom: 2 })
                                    .margin({ left: 4 })
                            }
                        }
                    }

                    if (bindings is Some<AccountBindings>) {
                        let b = (bindings as Some<AccountBindings>).get()
                        Text(b.email.bound ? b.email.value : "未绑定")
                            .fontSize(14)
                            .fontColor("#64748b")
                            .margin({ top: 4 })
                    }
                }
                .alignItems(HorizontalAlign.Start)
                .layoutWeight(1)

                // 绑定/解绑按钮
                if (bindings is Some<AccountBindings>) {
                    let b = (bindings as Some<AccountBindings>).get()
                    if (b.email.bound) {
                        Button("解绑")
                            .fontSize(12)
                            .fontColor("#64748b")
                            .backgroundColor("#f1f5f9")
                            .borderRadius(4)
                            .padding({ left: 12, right: 12, top: 6, bottom: 6 })
                            .onClick {
                                this.handleUnbind("email")
                            }
                    } else {
                        Button("绑定")
                            .fontSize(12)
                            .fontColor("#ffffff")
                            .backgroundColor("#2563eb")
                            .borderRadius(4)
                            .padding({ left: 12, right: 12, top: 6, bottom: 6 })
                            .onClick {
                                showBindEmailForm = !showBindEmailForm
                            }
                    }
                }
            }
            .width("100%")

            // 绑定邮箱表单
            if (showBindEmailForm) {
                Column() {
                    TextInput({ placeholder: "邮箱地址" })
                        .width("100%")
                        .height(40)
                        .margin({ top: 12 })
                        .onChange({ value => bindEmail = value })

                    TextInput({ placeholder: "验证码" })
                        .width("100%")
                        .height(40)
                        .margin({ top: 8 })
                        .onChange({ value => bindCode = value })

                    TextInput({ placeholder: "当前密码" })
                        .width("100%")
                        .height(40)
                        .type(InputType.Password)
                        .margin({ top: 8 })
                        .onChange({ value => bindPassword = value })

                    Row() {
                        Button("确认绑定")
                            .fontSize(12)
                            .fontColor("#ffffff")
                            .backgroundColor("#2563eb")
                            .borderRadius(4)
                            .margin({ right: 8 })
                            .onClick {
                                this.handleBindEmail()
                            }

                        Button("取消")
                            .fontSize(12)
                            .fontColor("#64748b")
                            .backgroundColor("#f1f5f9")
                            .borderRadius(4)
                            .onClick {
                                showBindEmailForm = false
                            }
                    }
                    .margin({ top: 8 })
                }
            }
        }
        .width("100%")
        .padding(16)
        .backgroundColor("#ffffff")
        .borderRadius(8)
        .margin({ bottom: 12 })
    }

    // ==================== 手机号绑定 ====================
    @Builder
    private func buildPhoneBinding(): void {
        Column() {
            Row() {
                Column() {
                    Text("手机号")
                        .fontSize(16)
                        .fontWeight(FontWeight.Bold)
                        .fontColor("#1e293b")

                    if (bindings is Some<AccountBindings>) {
                        let b = (bindings as Some<AccountBindings>).get()
                        Text(b.phone.bound ? "已绑定: ${b.phone.value}" : "未绑定")
                            .fontSize(14)
                            .fontColor("#64748b")
                            .margin({ top: 4 })
                    }
                }
                .alignItems(HorizontalAlign.Start)
                .layoutWeight(1)
            }
            .width("100%")

            // 手机号绑定表单 - 同步自 Web 版 PhoneBindingForm
            Row() {
                TextInput({ placeholder: "请输入11位手机号" })
                    .layoutWeight(1)
                    .height(40)
                    .margin({ top: 12 })
                    .onChange({ value => bindPhone = value })

                if (bindings is Some<AccountBindings>) {
                    let b = (bindings as Some<AccountBindings>).get()
                    if (b.phone.bound) {
                        Button("解绑")
                            .fontSize(12)
                            .fontColor("#64748b")
                            .backgroundColor("#f1f5f9")
                            .borderRadius(4)
                            .margin({ left: 8, top: 12 })
                            .onClick {
                                this.handleUnbind("phone")
                            }
                    }
                }
            }

            Button(bindings is Some<AccountBindings> && (bindings as Some<AccountBindings>).get().phone.bound ? "修改手机号" : "绑定手机号")
                .width("100%")
                .height(40)
                .fontSize(14)
                .fontColor("#ffffff")
                .backgroundColor("#2563eb")
                .borderRadius(8)
                .margin({ top: 12 })
                .onClick {
                    this.handleBindPhone()
                }
        }
        .width("100%")
        .padding(16)
        .backgroundColor("#ffffff")
        .borderRadius(8)
        .margin({ bottom: 12 })
    }

    // ==================== OAuth 绑定 ====================
    @Builder
    private func buildOAuthBindings(): void {
        Column() {
            this.buildOAuthItem("Google", "google")
            Divider().width("100%").height(1).color("#f1f5f9")
            this.buildOAuthItem("GitHub", "github")
            Divider().width("100%").height(1).color("#f1f5f9")
            this.buildOAuthItem("Gitee", "gitee")
            Divider().width("100%").height(1).color("#f1f5f9")
            this.buildOAuthItem("Discord", "discord")
        }
        .width("100%")
        .backgroundColor("#ffffff")
        .borderRadius(8)
        .margin({ bottom: 12 })
    }

    @Builder
    private func buildOAuthItem(name: String, key: String): void {
        Row() {
            Text(name)
                .fontSize(16)
                .fontColor("#1e293b")
                .layoutWeight(1)

            if (bindings is Some<AccountBindings>) {
                let b = (bindings as Some<AccountBindings>).get()
                let bindingMap = HashMap<String, AccountBinding>()
                // 获取对应绑定状态
                var isBound = false
                match (key) {
                    case "google" => isBound = b.google.bound
                    case "github" => isBound = b.github.bound
                    case "gitee" => isBound = b.gitee.bound
                    case "discord" => isBound = b.discord.bound
                    case _ => {}
                }

                if (isBound) {
                    Text("已绑定")
                        .fontSize(12)
                        .fontColor("#10b981")
                        .margin({ right: 8 })

                    Button("解绑")
                        .fontSize(12)
                        .fontColor("#64748b")
                        .backgroundColor("#f1f5f9")
                        .borderRadius(4)
                        .padding({ left: 12, right: 12, top: 6, bottom: 6 })
                        .onClick {
                            this.handleUnbind(key)
                        }
                } else {
                    Button("绑定")
                        .fontSize(12)
                        .fontColor("#ffffff")
                        .backgroundColor("#2563eb")
                        .borderRadius(4)
                        .padding({ left: 12, right: 12, top: 6, bottom: 6 })
                        .onClick {
                            this.handleOAuthBind(key)
                        }
                }
            }
        }
        .width("100%")
        .height(56)
        .padding({ left: 16, right: 16 })
    }

    // ==================== 安全提示 ====================
    @Builder
    private func buildSecurityNotice(): void {
        Row() {
            Column() {
                Text("⚠️ 安全提示")
                    .fontSize(14)
                    .fontWeight(FontWeight.Bold)
                    .fontColor("#d97706")
                    .margin({ bottom: 4 })

                Text("解绑账号前请确保至少保留一种登录方式。建议保留邮箱登录作为主账号。")
                    .fontSize(12)
                    .fontColor("#64748b")
            }
            .alignItems(HorizontalAlign.Start)
        }
        .width("100%")
        .padding(16)
        .backgroundColor("#fffbeb")
        .borderRadius(8)
        .margin({ bottom: 12 })
    }

    // ==================== 解绑密码 ====================
    @Builder
    private func buildUnbindPasswordSection(): void {
        Column() {
            Text("解绑验证")
                .fontSize(16)
                .fontWeight(FontWeight.Bold)
                .fontColor("#1e293b")
                .margin({ bottom: 12 })

            Text("当前密码")
                .fontSize(12)
                .fontColor("#64748b")
                .width("100%")

            TextInput({ placeholder: "解绑操作需要验证密码" })
                .width("100%")
                .height(40)
                .margin({ top: 4 })
                .type(InputType.Password)
                .onChange({ value => unbindPassword = value })
        }
        .width("100%")
        .padding(16)
        .backgroundColor("#ffffff")
        .borderRadius(8)
        .alignItems(HorizontalAlign.Start)
    }

    // ==================== 事件处理 ====================

    private func loadBindings(): void {
        isLoading = true
        let result = authService.getAccountBindings()
        isLoading = false

        if (result.isSuccess()) {
            let value = result.getValue()
            if (value is Some<AccountBindings>) {
                bindings = Some(value.get())
            }
        } else {
            errorMessage = result.getError()
        }
    }

    private func handleBindEmail(): void {
        let result = authService.bindEmail(bindEmail, bindPassword, bindCode)
        if (result.isSuccess()) {
            showBindEmailForm = false
            this.loadBindings()
        } else {
            errorMessage = result.getError()
        }
    }

    private func handleBindPhone(): void {
        let result = authService.bindPhone(bindPhone)
        if (result.isSuccess()) {
            this.loadBindings()
        } else {
            errorMessage = result.getError()
        }
    }

    private func handleUnbind(accountType: String): void {
        if (unbindPassword == "") {
            errorMessage = "请先输入密码以确认解绑"
            return
        }

        let result = authService.unbind(accountType, unbindPassword)
        if (result.isSuccess()) {
            unbindPassword = ""
            this.loadBindings()
        } else {
            errorMessage = result.getError()
        }
    }

    private func handleOAuthBind(provider: String): void {
        let result = authService.getOAuthAuthorizeUrl(provider)
        if (!result.isSuccess()) {
            errorMessage = "获取授权地址失败"
        }
    }
}
