// ForgotPasswordPage.cj - 忘记密码页面（同步自 Web 版 ForgotPasswordPage）
// 三步流程：输入邮箱 -> 验证码验证 -> 重置密码
package views

import ohos.arkui.*
import ohos.arkui.state.*
import ohos.arkui.node.*
import services.*
import utils.*

@Entry
@Component
public struct ForgotPasswordPage {
    @State private var step: Int32 = 0  // 0=email, 1=verify, 2=reset
    @State private var email: String = ""
    @State private var code: String = ""
    @State private var newPassword: String = ""
    @State private var confirmPassword: String = ""
    @State private var isLoading: Bool = false
    @State private var errorMessage: String = ""
    @State private var countdown: Int32 = 0

    private let authService: AuthService = AuthService()

    public func build(): void {
        Column() {
            // 返回按钮
            Row() {
                Image($r("app.media.ic_back"))
                    .width(24)
                    .height(24)
                    .onClick {
                        Router.back()
                    }

                Text("重置密码")
                    .fontSize(18)
                    .fontWeight(FontWeight.Bold)
                    .fontColor("#1e293b")
                    .margin({ left: 16 })
            }
            .width("100%")
            .height(56)
            .padding({ left: 16, right: 16 })
            .backgroundColor("#ffffff")

            // 进度条 - 同步自 Web 版 progress steps
            Row() {
                Row()
                    .width(60)
                    .height(4)
                    .borderRadius(2)
                    .backgroundColor(step >= 0 ? "#f59e0b" : "#334155")

                Row()
                    .width(60)
                    .height(4)
                    .borderRadius(2)
                    .margin({ left: 8 })
                    .backgroundColor(step >= 1 ? "#f59e0b" : "#334155")

                Row()
                    .width(60)
                    .height(4)
                    .borderRadius(2)
                    .margin({ left: 8 })
                    .backgroundColor(step >= 2 ? "#f59e0b" : "#334155")
            }
            .margin({ top: 24, bottom: 24 })

            // 提示文字
            Text(
                step == 0 ? "输入邮箱获取验证码" :
                step == 1 ? "输入验证码验证身份" :
                "设置新密码"
            )
                .fontSize(14)
                .fontColor("#64748b")
                .margin({ bottom: 24 })

            // 错误提示
            if (errorMessage != "") {
                Text(errorMessage)
                    .fontSize(12)
                    .fontColor("#f87171")
                    .margin({ bottom: 16 })
            }

            // 表单内容
            if (step == 0) {
                this.buildEmailStep()
            } else if (step == 1) {
                this.buildVerifyStep()
            } else {
                this.buildResetStep()
            }
        }
        .width("100%")
        .height("100%")
        .backgroundColor("#f5f5f5")
    }

    // ==================== Step 1: 输入邮箱 ====================
    @Builder
    private func buildEmailStep(): void {
        Column() {
            TextInput({ placeholder: "邮箱地址" })
                .width("80%")
                .height(48)
                .type(InputType.Email)
                .onChange({ value => email = value })
                .margin({ bottom: 24 })
                .borderRadius(8)
                .backgroundColor("#ffffff")

            Button(isLoading ? "发送中..." : "发送验证码")
                .width("80%")
                .height(48)
                .fontSize(16)
                .fontColor("#ffffff")
                .backgroundColor("#2563eb")
                .borderRadius(8)
                .enabled(!isLoading)
                .onClick {
                    this.handleSendCode()
                }
        }
    }

    // ==================== Step 2: 验证码验证 ====================
    @Builder
    private func buildVerifyStep(): void {
        Column() {
            // 邮箱提示
            Row() {
                Column() {
                    Text("验证码已发送至")
                        .fontSize(12)
                        .fontColor("#64748b")
                    Text(email)
                        .fontSize(14)
                        .fontWeight(FontWeight.Bold)
                        .fontColor("#1e293b")
                }
                .alignItems(HorizontalAlign.Start)
            }
            .width("80%")
            .padding(12)
            .backgroundColor("#ffffff")
            .borderRadius(8)
            .margin({ bottom: 24 })

            TextInput({ placeholder: "请输入6位验证码" })
                .width("80%")
                .height(48)
                .onChange({ value => code = value })
                .margin({ bottom: 16 })
                .borderRadius(8)
                .backgroundColor("#ffffff")

            // 重新发送按钮
            Text(countdown > 0 ? "${countdown}秒后重新发送" : "重新发送验证码")
                .fontSize(12)
                .fontColor(countdown > 0 ? "#94a3b8" : "#f59e0b")
                .margin({ bottom: 24 })
                .onClick {
                    if (countdown == 0) {
                        this.handleSendCode()
                    }
                }

            Button(isLoading ? "验证中..." : "下一步")
                .width("80%")
                .height(48)
                .fontSize(16)
                .fontColor("#ffffff")
                .backgroundColor("#2563eb")
                .borderRadius(8)
                .enabled(!isLoading)
                .onClick {
                    step = 2
                }

            Text("返回修改邮箱")
                .fontSize(12)
                .fontColor("#64748b")
                .margin({ top: 16 })
                .onClick {
                    step = 0
                }
        }
    }

    // ==================== Step 3: 重置密码 ====================
    @Builder
    private func buildResetStep(): void {
        Column() {
            TextInput({ placeholder: "新密码（至少6位）" })
                .width("80%")
                .height(48)
                .type(InputType.Password)
                .onChange({ value => newPassword = value })
                .margin({ bottom: 16 })
                .borderRadius(8)
                .backgroundColor("#ffffff")

            TextInput({ placeholder: "确认新密码" })
                .width("80%")
                .height(48)
                .type(InputType.Password)
                .onChange({ value => confirmPassword = value })
                .margin({ bottom: 24 })
                .borderRadius(8)
                .backgroundColor("#ffffff")

            Button(isLoading ? "重置中..." : "重置密码")
                .width("80%")
                .height(48)
                .fontSize(16)
                .fontColor("#ffffff")
                .backgroundColor("#2563eb")
                .borderRadius(8)
                .enabled(!isLoading)
                .onClick {
                    this.handleResetPassword()
                }

            Text("返回上一步")
                .fontSize(12)
                .fontColor("#64748b")
                .margin({ top: 16 })
                .onClick {
                    step = 1
                }
        }
    }

    // ==================== 事件处理 ====================

    private func handleSendCode(): void {
        errorMessage = ""
        isLoading = true

        let result = authService.requestPasswordReset(email)
        isLoading = false

        if (result.isSuccess()) {
            step = 1
            countdown = 60
        } else {
            errorMessage = result.getError()
        }
    }

    private func handleResetPassword(): void {
        errorMessage = ""

        if (newPassword != confirmPassword) {
            errorMessage = "两次输入的密码不一致"
            return
        }

        if (newPassword.size() < 6) {
            errorMessage = "密码长度至少6位"
            return
        }

        isLoading = true
        let result = authService.verifyPasswordReset(email, code, newPassword)
        isLoading = false

        if (result.isSuccess()) {
            Router.replace({ url: "pages/LoginPage" })
        } else {
            errorMessage = result.getError()
        }
    }
}
