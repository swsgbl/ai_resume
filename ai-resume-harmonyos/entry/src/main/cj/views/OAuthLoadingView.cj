package views

/**
 * OAuth登录加载视图
 * 显示不同加载状态的动画和提示文字
 */
@Component
export struct OAuthLoadingView {
    @Prop private loadingState: LoadingState = LoadingState.CONNECTING
    @Prop private message: String = "正在连接..."

    /**
     * 加载状态枚举
     */
    enum LoadingState {
        case CONNECTING        // 连接中
        case AUTHORIZING       // 授权中
        case VERIFYING         // 验证中
        case SUCCESS           // 成功
        case ERROR             // 错误
    }

    build() {
        Column() {
            // 动画图标
            this.buildAnimatedIcon()

            // 提示文字
            Text(this.message)
                .fontSize(16)
                .fontColor('#666666')
                .margin({ top: 20 })

            // 进度提示
            this.buildProgressHint()
        }
        .width('100%')
        .height('100%')
        .justifyContent(FlexAlign.Center)
        .backgroundColor('#FFFFFF')
    }

    /**
     * 构建动画图标
     */
    @Builder
    private buildAnimatedIcon() {
        if (this.loadingState == LoadingState.CONNECTING) {
            this.buildConnectingAnimation()
        } else if (this.loadingState == LoadingState.AUTHORIZING) {
            this.buildAuthorizingAnimation()
        } else if (this.loadingState == LoadingState.VERIFYING) {
            this.buildVerifyingAnimation()
        } else if (this.loadingState == LoadingState.SUCCESS) {
            this.buildSuccessIcon()
        } else if (this.loadingState == LoadingState.ERROR) {
            this.buildErrorIcon()
        }
    }

    /**
     * 连接中动画
     */
    @Builder
    private buildConnectingAnimation() {
        LoadingProgress()
            .width(60)
            .height(60)
            .color('#007DFF')
    }

    /**
     * 授权中动画
     */
    @Builder
    private buildAuthorizingAnimation() {
        Column() {
            Image($r('app.media.wechat_icon'))
                .width(50)
                .height(50)
                .opacity(0.6)

            LoadingProgress()
                .width(40)
                .height(40)
                .color('#07C160')
                .margin({ top: 10 })
        }
    }

    /**
     * 验证中动画
     */
    @Builder
    private buildVerifyingAnimation() {
        LoadingProgress()
            .width(60)
            .height(60)
            .color('#FF6B00')
    }

    /**
     * 成功图标
     */
    @Builder
    private buildSuccessIcon() {
        Image($r('app.media.success_icon'))
            .width(60)
            .height(60)
            .objectFit(ImageFit.Contain)
    }

    /**
     * 错误图标
     */
    @Builder
    private buildErrorIcon() {
        Image($r('app.media.error_icon'))
            .width(60)
            .height(60)
            .objectFit(ImageFit.Contain)
    }

    /**
     * 构建进度提示
     */
    @Builder
    private buildProgressHint() {
        if (this.loadingState == LoadingState.CONNECTING) {
            Text("正在建立安全连接...")
                .fontSize(14)
                .fontColor('#999999')
                .margin({ top: 8 })
        } else if (this.loadingState == LoadingState.AUTHORIZING) {
            Text("正在跳转到授权页面...")
                .fontSize(14)
                .fontColor('#999999')
                .margin({ top: 8 })
        } else if (this.loadingState == LoadingState.VERIFYING) {
            Text("正在验证您的信息...")
                .fontSize(14)
                .fontColor('#999999')
                .margin({ top: 8 })
        }
    }
}
