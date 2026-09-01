// RegisterPage.cj - 注册页面
package views

import ohos.arkui.*
import ohos.arkui.state.*
import ohos.arkui.node.*
import services.*
import models.*

@Entry
@Component
public struct RegisterPage {
    @State private var email: String = ""
    @State private var username: String = ""
    @State private var password: String = ""
    @State private var confirmPassword: String = ""
    @State private var fullName: String = ""
    @State private var isLoading: Bool = false
    @State private var errorMessage: String = ""

    private let authService: AuthService = AuthService()

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

            // 注册按钮
            this.buildRegisterButton()

            // 登录链接
            this.buildLoginLink()
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

            Text("创建账号")
                .fontSize(24)
                .fontWeight(FontWeight.Bold)
                .fontColor("#1e293b")

            Text("开始创建专业简历")
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
                .margin({ bottom: 12 })
                .borderRadius(8)
                .backgroundColor("#ffffff")
                .padding({ left: 16, right: 16 })

            // 用户名输入
            TextInput({ placeholder: "请输入用户名" })
                .width("80%")
                .height(48)
                .onChange({ value => username = value })
                .margin({ bottom: 12 })
                .borderRadius(8)
                .backgroundColor("#ffffff")
                .padding({ left: 16, right: 16 })

            // 姓名输入
            TextInput({ placeholder: "请输入姓名" })
                .width("80%")
                .height(48)
                .onChange({ value => fullName = value })
                .margin({ bottom: 12 })
                .borderRadius(8)
                .backgroundColor("#ffffff")
                .padding({ left: 16, right: 16 })

            // 密码输入
            TextInput({ placeholder: "请输入密码" })
                .width("80%")
                .height(48)
                .type(InputType.Password)
                .onChange({ value => password = value })
                .margin({ bottom: 12 })
                .borderRadius(8)
                .backgroundColor("#ffffff")
                .padding({ left: 16, right: 16 })

            // 确认密码输入
            TextInput({ placeholder: "请确认密码" })
                .width("80%")
                .height(48)
                .type(InputType.Password)
                .onChange({ value => confirmPassword = value })
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
    private func buildRegisterButton(): void {
        Button(isLoading ? "注册中..." : "注册")
            .width("80%")
            .height(48)
            .fontSize(16)
            .fontColor("#ffffff")
            .backgroundColor("#2563eb")
            .borderRadius(8)
            .enabled(!isLoading)
            .margin({ top: 24 })
            .onClick {
                this.handleRegister()
            }
    }

    @Builder
    private func buildLoginLink(): void {
        Row() {
            Text("已有账号？")
                .fontSize(14)
                .fontColor("#64748b")

            Text("立即登录")
                .fontSize(14)
                .fontColor("#2563eb")
                .onClick {
                    Router.back()
                }
        }
        .margin({ top: 24 })
    }

    private func handleRegister(): void {
        // 验证输入
        if (email == "" || username == "" || password == "" || fullName == "") {
            errorMessage = "请填写所有字段"
            return
        }

        if (password != confirmPassword) {
            errorMessage = "两次输入的密码不一致"
            return
        }

        if (password.length() < 6) {
            errorMessage = "密码长度至少6位"
            return
        }

        isLoading = true
        errorMessage = ""

        // 调用注册服务
        let result = authService.register(email, username, password, fullName)

        isLoading = false

        if (result.isSuccess()) {
            // 注册成功，导航到登录页
            Router.back()
        } else {
            errorMessage = result.getError()
        }
    }
}
