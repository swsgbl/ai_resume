package views

/**
 * OAuth登录错误视图
 * 显示登录失败的错误信息和操作选项
 */
@Component
export struct OAuthErrorView {
    @Prop private errorCode: String = "UNKNOWN_ERROR"
    @Prop private errorMessage: String = "登录失败，请重试"
    @Prop private provider: String = "微信"

    build() {
        Column() {
            // 错误图标
            Image($r('app.media.error_icon'))
                .width(80)
                .height(80)
                .objectFit(ImageFit.Contain)
                .margin({ top: 80, bottom: 24 })

            // 错误标题
            Text("登录失败")
                .fontSize(24)
                .fontWeight(FontWeight.Bold)
                .fontColor('#333333')
                .margin({ bottom: 12 })

            // 错误描述
            Text(this.getErrorMessage())
                .fontSize(14)
                .fontColor('#666666')
                .textAlign(TextAlign.Center)
                .width('80%')
                .margin({ bottom: 40 })

            // 操作按钮
            this.buildActionButtons()

            // 帮助信息
            this.buildHelpText()
        }
        .width('100%')
        .height('100%')
        .justifyContent(FlexAlign.Start)
        .backgroundColor('#FFFFFF')
        .padding(20)
    }

    /**
     * 构建操作按钮
     */
    @Builder
    private buildActionButtons() {
        Column() {
            // 重试按钮
            Button() {
                Text("重新登录")
                    .fontSize(16)
                    .fontColor(Color.White)
                    .fontWeight(FontWeight.Medium)
            }
            .width('100%')
            .height(50)
            .backgroundColor('#007DFF')
            .borderRadius(8)
            .margin({ bottom: 12 })
            .onClick(() => {
                this.handleRetry()
            })

            // 返回按钮
            Button() {
                Text("返回")
                    .fontSize(16)
                    .fontColor('#007DFF')
                    .fontWeight(FontWeight.Medium)
            }
            .width('100%')
            .height(50)
            .backgroundColor('#F5F5F5')
            .borderRadius(8)
            .onClick(() => {
                this.handleBack()
            })
        }
        .width('100%')
        .margin({ bottom: 40 })
    }

    /**
     * 构建帮助文本
     */
    @Builder
    private buildHelpText() {
        Column() {
            Text("如果问题持续，请联系客服")
                .fontSize(12)
                .fontColor('#999999')
                .margin({ bottom: 8 })

            Text("客服邮箱：support@airesume.com")
                .fontSize(12)
                .fontColor('#007DFF')
        }
        .width('100%')
        .margin({ top: 'auto' })
    }

    /**
     * 获取错误消息
     */
    private func getErrorMessage(): String {
        if (this.errorCode == "NETWORK_ERROR") {
            return "网络连接失败，请检查您的网络设置"
        } else if (this.errorCode == "AUTH_DENIED") {
            return "您取消了${this.provider}授权"
        } else if (this.errorCode == "AUTH_EXPIRED") {
            return "授权已过期，请重新登录"
        } else if (this.errorCode == "INVALID_CODE") {
            return "授权码无效，请重新登录"
        } else if (this.errorCode == "USER_CANCELLED") {
            return "您已取消登录"
        } else {
            return this.errorMessage
        }
    }

    /**
     * 处理重试
     */
    private func handleRetry() {
        // TODO: 重新触发登录流程
        console.log("Retry login")
    }

    /**
     * 处理返回
     */
    private func handleBack() {
        // TODO: 返回登录页面
        console.log("Back to login")
    }
}
