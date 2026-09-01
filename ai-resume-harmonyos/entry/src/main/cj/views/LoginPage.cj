// LoginPage.cj - 登录页面
package views

import ohos.arkui.*
import ohos.arkui.state.*
import ohos.arkui.node.*
import services.*
import models.*
import utils.*

@Entry
@Component
public struct LoginPage {
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var isLoading: Bool = false
    @State private var errorMessage: String = ""

    private let authService: AuthService = AuthService()
    private static let logger = Logger("LoginPage")

    public func build(): void {
        Column() {
            // Logo区域
            this.buildLogo()

            // 表单区域
            this.buildForm()

            // 错误提示
            if (errorMessage != "") {
                this.buildError()
            }

            // 登录按钮
            this.buildLoginButton()

            // 注册链接
            this.buildRegisterLink()
        }
        .width("100%")
        .height("100%")
        .backgroundColor("#f5f5f5")
        .justifyContent(FlexAlign.Center)
    }

    @Builder
    private func buildLogo(): void {
        Column() {
            Image($r("app.media.logo"))
                .width(80)
                .height(80)
                .margin({ bottom: 16 })

            Text("AI 简历生成")
                .fontSize(24)
                .fontWeight(FontWeight.Bold)
                .fontColor("#1e293b")

            Text("智能创建专业简历")
                .fontSize(14)
                .fontColor("#64748b")
                .margin({ top: 8 })
        }
        .margin({ bottom: 32 })
    }

    @Builder
    private func buildForm(): void {
        Column() {
            // 邮箱输入
            TextInput({ placeholder: "请输入邮箱" })
                .width("80%")
                .height(48)
                .type(InputType.Email)
                .onChange({ value => email = value })
                .margin({ bottom: 16 })
                .borderRadius(8)
                .backgroundColor("#ffffff")
                .padding({ left: 16, right: 16 })

            // 密码输入
            TextInput({ placeholder: "请输入密码" })
                .width("80%")
                .height(48)
                .type(InputType.Password)
                .onChange({ value => password = value })
                .borderRadius(8)
                .backgroundColor("#ffffff")
                .padding({ left: 16, right: 16 })
        }
    }

    @Builder
    private func buildError(): void {
        Text(errorMessage)
            .fontSize(12)
            .fontColor("#ef4444")
            .margin({ top: 16 })
    }

    @Builder
    private func buildLoginButton(): void {
        Button(isLoading ? "登录中..." : "登录")
            .width("80%")
            .height(48)
            .fontSize(16)
            .fontColor("#ffffff")
            .backgroundColor("#2563eb")
            .borderRadius(8)
            .enabled(!isLoading)
            .margin({ top: 24 })
            .onClick {
                this.handleLogin()
            }
    }

    @Builder
    private func buildRegisterLink(): void {
        Row() {
            Text("还没有账号？")
                .fontSize(14)
                .fontColor("#64748b")

            Text("立即注册")
                .fontSize(14)
                .fontColor("#2563eb")
                .onClick {
                    // 导航到注册页面
                    Router.push({ url: "pages/RegisterPage" })
                }
        }
        .margin({ top: 24 })
    }

    private func handleLogin(): void {
        // 清空错误信息
        errorMessage = ""

        // 使用 Validator 验证输入
        let validationResult = Validator.validateLogin(email, password)

        if (!validationResult.isSuccess()) {
            errorMessage = validationResult.getError()
            logger.debug("Login validation failed: ${errorMessage}")
            return
        }

        isLoading = true

        // 调用登录服务
        let result = authService.login(email, password)

        isLoading = false

        if (result.isSuccess()) {
            logger.info("Login successful for user: ${email}")
            // 登录成功，导航到主页
            Router.replace({ url: "pages/HomePage" })
        } else {
            errorMessage = result.getError()
            logger.error("Login failed: ${errorMessage}")
        }
    }
}
