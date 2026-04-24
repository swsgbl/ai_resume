// UnifiedLoginPage.cj - 统一登录页面（同步自 Web 版 UnifiedLoginPage）
// 支持邮箱登录、手机号登录、第三方OAuth登录
package views

import ohos.arkui.*
import ohos.arkui.state.*
import ohos.arkui.node.*
import services.*
import models.*
import utils.*

@Entry
@Component
public struct UnifiedLoginPage {
    @State private var activeTab: Int32 = 0  // 0=email, 1=phone, 2=oauth
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var phone: String = ""
    @State private var smsCode: String = ""
    @State private var isLoading: Bool = false
    @State private var errorMessage: String = ""
    @State private var countdown: Int32 = 0

    private let authService: AuthService = AuthService()

    // OAuth 提供商列表 - 同步自 Web 版 oauth.config
    private let oauthProviders: ArrayList<OAuthProviderConfig> = getOAuthProviders()

    public func build(): void {
        Column() {
            // Logo区域
            this.buildLogo()

            // Tab 切换 - 同步自 Web 版 UnifiedLoginPage tab切换
            this.buildTabs()

            // 错误提示
            if (errorMessage != "") {
                this.buildError()
            }

            // 表单内容
            this.buildFormContent()

            // 注册链接
            this.buildRegisterLink()
        }
        .width("100%")
        .height("100%")
        .backgroundColor("#0f172a")
        .justifyContent(FlexAlign.Center)
    }

    @Builder
    private func buildLogo(): void {
        Column() {
            Image($r("app.media.logo"))
                .width(80)
                .height(80)
                .margin({ bottom: 16 })

            Text("欢迎回来")
                .fontSize(24)
                .fontWeight(FontWeight.Bold)
                .fontColor("#fbbf24")

            Text("选择你的登录方式")
                .fontSize(14)
                .fontColor("#94a3b8")
                .margin({ top: 8 })
        }
        .margin({ bottom: 32 })
    }

    @Builder
    private func buildTabs(): void {
        Row() {
            ForEach(["邮箱登录", "手机登录", "第三方"], { (item: String, index: Int32) =>
                Text(item)
                    .fontSize(14)
                    .fontColor(activeTab == index ? "#ffffff" : "#94a3b8")
                    .backgroundColor(activeTab == index ? "#f59e0b" : "#1e293b")
                    .borderRadius(8)
                    .padding({ left: 16, right: 16, top: 8, bottom: 8 })
                    .margin({ left: 4, right: 4 })
                    .onClick {
                        activeTab = index
                    }
            })
        }
        .width("80%")
        .justifyContent(FlexAlign.SpaceAround)
        .margin({ bottom: 24 })
    }

    @Builder
    private func buildError(): void {
        Text(errorMessage)
            .fontSize(12)
            .fontColor("#f87171")
            .backgroundColor("rgba(248,113,113,0.1)")
            .borderRadius(8)
            .padding(12)
            .width("80%")
            .margin({ bottom: 16 })
    }

    @Builder
    private func buildFormContent(): void {
        if (activeTab == 0) {
            this.buildEmailForm()
        } else if (activeTab == 1) {
            this.buildPhoneForm()
        } else {
            this.buildOAuthForm()
        }
    }

    // ==================== 邮箱登录表单 ====================
    // 同步自 Web 版 UnifiedLoginPage handleEmailLogin
    @Builder
    private func buildEmailForm(): void {
        Column() {
            TextInput({ placeholder: "邮箱地址" })
                .width("80%")
                .height(48)
                .type(InputType.Email)
                .onChange({ value => email = value })
                .margin({ bottom: 16 })
                .borderRadius(8)
                .backgroundColor("#1e293b")
                .fontColor("#ffffff")
                .padding({ left: 16, right: 16 })

            TextInput({ placeholder: "密码" })
                .width("80%")
                .height(48)
                .type(InputType.Password)
                .onChange({ value => password = value })
                .borderRadius(8)
                .backgroundColor("#1e293b")
                .fontColor("#ffffff")
                .padding({ left: 16, right: 16 })

            // 忘记密码链接
            Text("忘记密码？")
                .fontSize(12)
                .fontColor("#fbbf24")
                .margin({ top: 12 })
                .alignSelf(HorizontalAlign.End)
                .width("80%")
                .textAlign(TextAlign.End)
                .onClick {
                    Router.push({ url: "pages/ForgotPasswordPage" })
                }

            Button(isLoading ? "登录中..." : "登录")
                .width("80%")
                .height(48)
                .fontSize(16)
                .fontColor("#0f172a")
                .backgroundColor("#f59e0b")
                .borderRadius(8)
                .enabled(!isLoading)
                .margin({ top: 24 })
                .onClick {
                    this.handleEmailLogin()
                }
        }
    }

    // ==================== 手机号登录表单 ====================
    // 同步自 Web 版 UnifiedLoginPage handleSMSLogin
    @Builder
    private func buildPhoneForm(): void {
        Column() {
            TextInput({ placeholder: "请输入11位手机号" })
                .width("80%")
                .height(48)
                .type(InputType.PhoneNumber)
                .onChange({ value =>
                    // 只保留数字，限制11位 - 同步自 Web 版
                    phone = value
                })
                .margin({ bottom: 16 })
                .borderRadius(8)
                .backgroundColor("#1e293b")
                .fontColor("#ffffff")
                .padding({ left: 16, right: 16 })

            // 验证码输入 + 发送按钮
            Row() {
                TextInput({ placeholder: "6位数字验证码" })
                    .layoutWeight(1)
                    .height(48)
                    .onChange({ value => smsCode = value })
                    .borderRadius(8)
                    .backgroundColor("#1e293b")
                    .fontColor("#ffffff")
                    .padding({ left: 16, right: 16 })

                Button(countdown > 0 ? "${countdown}s" : "获取验证码")
                    .width(120)
                    .height(48)
                    .fontSize(12)
                    .fontColor(countdown > 0 ? "#94a3b8" : "#fbbf24")
                    .backgroundColor("#1e293b")
                    .borderRadius(8)
                    .margin({ left: 8 })
                    .enabled(countdown == 0)
                    .onClick {
                        this.handleSendSmsCode()
                    }
            }
            .width("80%")

            Button(isLoading ? "登录中..." : "验证码登录")
                .width("80%")
                .height(48)
                .fontSize(16)
                .fontColor("#0f172a")
                .backgroundColor("#f59e0b")
                .borderRadius(8)
                .enabled(!isLoading)
                .margin({ top: 24 })
                .onClick {
                    this.handleSmsLogin()
                }

            Text("未注册手机号将自动创建账号")
                .fontSize(12)
                .fontColor("#64748b")
                .margin({ top: 12 })
        }
    }

    // ==================== 第三方 OAuth 登录 ====================
    // 同步自 Web 版 UnifiedLoginPage handleOAuthLogin
    @Builder
    private func buildOAuthForm(): void {
        Column() {
            Text("选择第三方账号一键登录")
                .fontSize(14)
                .fontColor("#94a3b8")
                .margin({ bottom: 24 })

            ForEach(oauthProviders, { (provider: OAuthProviderConfig) =>
                Button("使用 ${provider.name} 登录")
                    .width("80%")
                    .height(48)
                    .fontSize(16)
                    .fontColor("#ffffff")
                    .backgroundColor("#1e293b")
                    .borderRadius(8)
                    .margin({ top: 8 })
                    .onClick {
                        this.handleOAuthLogin(provider.key)
                    }
            })
        }
    }

    @Builder
    private func buildRegisterLink(): void {
        Row() {
            Text("还没有账号？")
                .fontSize(14)
                .fontColor("#94a3b8")

            Text("立即注册")
                .fontSize(14)
                .fontColor("#fbbf24")
                .margin({ left: 4 })
                .onClick {
                    Router.push({ url: "pages/RegisterPage" })
                }
        }
        .margin({ top: 24 })
    }

    // ==================== 事件处理 ====================

    private func handleEmailLogin(): void {
        errorMessage = ""

        let validationResult = Validator.validateLogin(email, password)
        if (!validationResult.isSuccess()) {
            errorMessage = validationResult.getError()
            return
        }

        isLoading = true
        let result = authService.login(email, password)
        isLoading = false

        if (result.isSuccess()) {
            Router.replace({ url: "pages/HomePage" })
        } else {
            errorMessage = result.getError()
        }
    }

    private func handleSendSmsCode(): void {
        if (!Validator.isValidPhone(phone).isSuccess()) {
            errorMessage = "请输入正确的11位手机号"
            return
        }

        let result = authService.sendSmsCode(phone)
        if (result.isSuccess()) {
            let cooldown = result.getValue()
            var cd: Int32 = 60
            if (cooldown is Some<Int64>) {
                cd = Int32(cooldown.get())
            }
            countdown = cd
        } else {
            errorMessage = result.getError()
        }
    }

    private func handleSmsLogin(): void {
        errorMessage = ""

        if (!Validator.isValidPhone(phone).isSuccess()) {
            errorMessage = "请输入正确的11位手机号"
            return
        }
        if (smsCode.size() < 4) {
            errorMessage = "请输入验证码"
            return
        }

        isLoading = true
        let result = authService.loginWithSms(phone, smsCode)
        isLoading = false

        if (result.isSuccess()) {
            Router.replace({ url: "pages/HomePage" })
        } else {
            errorMessage = result.getError()
        }
    }

    private func handleOAuthLogin(providerKey: String): void {
        // OAuth 登录 - 在鸿蒙上使用系统浏览器打开授权页
        let result = authService.getOAuthAuthorizeUrl(providerKey)
        if (result.isSuccess()) {
            let url = result.getValue()
            if (url is Some<String>) {
                // 使用系统浏览器打开 OAuth 授权页
                // 实际实现中需要使用鸿蒙的 Ability 框架处理回调
                println("Opening OAuth URL: ${url.get()}")
            }
        } else {
            errorMessage = "获取授权地址失败"
        }
    }

    // 获取 OAuth 提供商配置 - 同步自 Web 版 OAUTH_PROVIDERS
    private static func getOAuthProviders(): ArrayList<OAuthProviderConfig> {
        let providers = ArrayList<OAuthProviderConfig>()
        providers.add(OAuthProviderConfig("google", "Google", true, "#4285F4", "rgba(66,133,244,0.15)", "google"))
        providers.add(OAuthProviderConfig("github", "GitHub", true, "#ffffff", "rgba(255,255,255,0.1)", "github"))
        providers.add(OAuthProviderConfig("gitee", "Gitee", true, "#C71D23", "rgba(199,29,35,0.15)", "gitee"))
        providers.add(OAuthProviderConfig("discord", "Discord", true, "#5865F2", "rgba(88,101,242,0.15)", "discord"))
        return providers
    }
}
