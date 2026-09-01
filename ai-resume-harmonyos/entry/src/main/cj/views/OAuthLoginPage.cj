package views

import services.TokenManager
import services.oauth.WeChatAuthService
import services.oauth.AlipayAuthService
import config.OAuthConfig
import utils.oauth.OAuthHelper

/**
 * 统一OAuth登录页面
 * 支持微信和支付宝第三方登录
 */
@Entry
@Component
struct OAuthLoginPage {
    @State private isLoading: Boolean = false
    @State private loadingText: String = ""
    @State private errorMessage: String = ""
    @State private showErrorDialog: Boolean = false
    @State private selectedProvider: String = ""

    private let tokenManager: TokenManager = TokenManager()
    private let oauthHelper: OAuthHelper = OAuthHelper()

    /**
     * 页面构建
     */
    build() {
        Column() {
            // 顶部标题区域
            this.buildHeader()

            // 中间登录按钮区域
            if (!this.isLoading) {
                this.buildLoginButtons()
            } else {
                this.buildLoadingIndicator()
            }

            // 底部说明区域
            this.buildFooter()

            // 错误对话框
            if (this.showErrorDialog) {
                this.buildErrorDialog()
            }
        }
        .width('100%')
        .height('100%')
        .backgroundColor('#F5F5F5')
        .padding(20)
    }

    /**
     * 构建顶部标题
     */
    @Builder
    private buildHeader() {
        Column() {
            // 应用图标
            Image($r('app.media.app_icon'))
                .width(80)
                .height(80)
                .margin({ top: 60, bottom: 20 })

            // 应用名称
            Text("AI Resume")
                .fontSize(28)
                .fontWeight(FontWeight.Bold)
                .fontColor('#333333')
                .margin({ bottom: 10 })

            // 欢迎文字
            Text("欢迎使用AI简历助手")
                .fontSize(16)
                .fontColor('#666666')
                .margin({ bottom: 40 })

            // 登录提示
            Text("选择您的登录方式")
                .fontSize(14)
                .fontColor('#999999')
        }
        .width('100%')
    }

    /**
     * 构建登录按钮
     */
    @Builder
    private buildLoginButtons() {
        Column() {
            // 微信登录按钮
            this.buildWeChatButton()

            // 支付宝登录按钮
            this.buildAlipayButton()

            // 分隔线
            this.buildDivider()

            // 用户协议提示
            this.buildAgreementText()
        }
        .width('100%')
        .margin({ top: 40 })
    }

    /**
     * 微信登录按钮
     */
    @Builder
    private buildWeChatButton() {
        Button() {
            Row() {
                // 微信图标
                Image($r('app.media.wechat_icon'))
                    .width(24)
                    .height(24)
                    .margin({ right: 12 })

                // 按钮文字
                Text("微信登录")
                    .fontSize(16)
                    .fontColor(Color.White)
                    .fontWeight(FontWeight.Medium)
            }
            .width('100%')
            .height(50)
            .justifyContent(FlexAlign.Center)
        }
        .width('100%')
        .height(50)
        .backgroundColor('#07C160')
        .borderRadius(8)
        .margin({ bottom: 16 })
        .onClick(() => {
            this.handleWeChatLogin()
        })
    }

    /**
     * 支付宝登录按钮
     */
    @Builder
    private buildAlipayButton() {
        Button() {
            Row() {
                // 支付宝图标
                Image($r('app.media.alipay_icon'))
                    .width(24)
                    .height(24)
                    .margin({ right: 12 })

                // 按钮文字
                Text("支付宝登录")
                    .fontSize(16)
                    .fontColor(Color.White)
                    .fontWeight(FontWeight.Medium)
            }
            .width('100%')
            .height(50)
            .justifyContent(FlexAlign.Center)
        }
        .width('100%')
        .height(50)
        .backgroundColor('#1677FF')
        .borderRadius(8)
        .margin({ bottom: 16 })
        .onClick(() => {
            this.handleAlipayLogin()
        })
    }

    /**
     * 分隔线
     */
    @Builder
    private buildDivider() {
        Row() {
            Line()
                .width('45%')
                .height(1)
                .backgroundColor('#E0E0E0')

            Text("或")
                .fontSize(12)
                .fontColor('#CCCCCC')
                .margin({ left: 10, right: 10 })

            Line()
                .width('45%')
                .height(1)
                .backgroundColor('#E0E0E0')
        }
        .width('100%')
        .margin({ top: 20, bottom: 20 })
    }

    /**
     * 用户协议文本
     */
    @Builder
    private buildAgreementText() {
        Text("登录即表示您同意《用户协议》和《隐私政策》")
            .fontSize(12)
            .fontColor('#999999')
            .textAlign(TextAlign.Center)
            .width('100%')
    }

    /**
     * 加载指示器
     */
    @Builder
    private buildLoadingIndicator() {
        Column() {
            LoadingProgress()
                .width(40)
                .height(40)
                .color('#007DFF')
                .margin({ bottom: 20 })

            Text(this.loadingText)
                .fontSize(14)
                .fontColor('#666666')
        }
        .width('100%')
        .margin({ top: 40 })
    }

    /**
     * 底部信息
     */
    @Builder
    private buildFooter() {
        Column() {
            Text("AI Resume v1.0")
                .fontSize(12)
                .fontColor('#CCCCCC')
                .margin({ bottom: 8 })

            Text("© 2026 AI Resume Platform")
                .fontSize(12)
                .fontColor('#CCCCCC')
        }
        .width('100%')
        .margin({ top: 'auto' })
    }

    /**
     * 错误对话框
     */
    @Builder
    private buildErrorDialog() {
        AlertDialog.show({
            title: '登录失败',
            message: this.errorMessage,
            primaryButton: {
                Button('重试')
                    .onClick(() => {
                        this.showErrorDialog = false
                        this.errorMessage = ""
                        if (this.selectedProvider == "wechat") {
                            this.handleWeChatLogin()
                        } else if (this.selectedProvider == "alipay") {
                            this.handleAlipayLogin()
                        }
                    })
            },
            secondaryButton: {
                Button('取消')
                    .onClick(() => {
                        this.showErrorDialog = false
                        this.errorMessage = ""
                        this.selectedProvider = ""
                    })
            },
            onCancel: () => {
                this.showErrorDialog = false
                this.errorMessage = ""
            }
        })
    }

    /**
     * 处理微信登录
     */
    private func handleWeChatLogin() {
        this.selectedProvider = "wechat"
        this.isLoading = true
        this.loadingText = "正在跳转到微信..."

        try {
            // 生成state参数
            let state = this.oauthHelper.generateState()

            // 创建微信登录服务
            let wechatService = WeChatAuthService(
                appId: OAuthConfig.getWeChatAppId(),
                appSecret: OAuthConfig.WECHAT_APP_SECRET,
                redirectUri: OAuthConfig.WECHAT_REDIRECT_URI
            )

            // 获取授权URL
            let authUrl = wechatService.getAuthorizationUrl(state)

            // 跳转到微信授权页面
            // 这里需要调用微信SDK或系统浏览器
            this.openAuthorizationUrl(authUrl)

        } catch (e: Exception) {
            this.isLoading = false
            this.errorMessage = "微信登录失败：${e.message}"
            this.showErrorDialog = true
        }
    }

    /**
     * 处理支付宝登录
     */
    private func handleAlipayLogin() {
        this.selectedProvider = "alipay"
        this.isLoading = true
        this.loadingText = "正在跳转到支付宝..."

        try {
            // 生成state参数
            let state = this.oauthHelper.generateState()

            // 创建支付宝登录服务
            let alipayService = AlipayAuthService(
                appId: OAuthConfig.getAlipayAppId(),
                appSecret: OAuthConfig.ALIPAY_APP_SECRET,
                redirectUri: OAuthConfig.ALIPAY_REDIRECT_URI
            )

            // 获取授权URL
            let authUrl = alipayService.getAuthorizationUrl(state)

            // 跳转到支付宝授权页面
            // 这里需要调用支付宝SDK或系统浏览器
            this.openAuthorizationUrl(authUrl)

        } catch (e: Exception) {
            this.isLoading = false
            this.errorMessage = "支付宝登录失败：${e.message}"
            this.showErrorDialog = true
        }
    }

    /**
     * 打开授权URL
     * @param url 授权URL
     */
    private func openAuthorizationUrl(url: String) {
        // TODO: 调用微信/支付宝SDK或系统浏览器
        // 这里需要根据实际SDK文档实现
        console.log("Opening authorization URL: ${url}")
    }

    /**
     * 处理授权回调
     * @param code 授权码
     * @param state state参数
     * @param provider 提供商（wechat或alipay）
     */
    public func handleAuthorizationCallback(code: String, state: String, provider: String) {
        this.isLoading = true
        this.loadingText = "正在登录..."

        try {
            let oauthUser: OAuthUser

            if (provider == "wechat") {
                let wechatService = WeChatAuthService(
                    appId: OAuthConfig.getWeChatAppId(),
                    appSecret: OAuthConfig.WECHAT_APP_SECRET,
                    redirectUri: OAuthConfig.WECHAT_REDIRECT_URI
                )
                oauthUser = wechatService.handleAuthorizationCallback(code, state)
            } else if (provider == "alipay") {
                let alipayService = AlipayAuthService(
                    appId: OAuthConfig.getAlipayAppId(),
                    appSecret: OAuthConfig.ALIPAY_APP_SECRET,
                    redirectUri: OAuthConfig.ALIPAY_REDIRECT_URI
                )
                oauthUser = alipayService.handleAuthorizationCallback(code, state)
            } else {
                throw Exception("不支持的登录提供商")
            }

            // 调用后端接口完成登录
            this.completeLogin(oauthUser)

        } catch (e: Exception) {
            this.isLoading = false
            this.errorMessage = "登录失败：${e.message}"
            this.showErrorDialog = true
        }
    }

    /**
     * 完成登录流程
     * @param oauthUser OAuth用户信息
     */
    private func completeLogin(oauthUser: OAuthUser) {
        this.loadingText = "正在验证信息..."

        // TODO: 调用后端接口 /api/auth/wechat/login 或 /api/auth/alipay/login
        // 这里需要根据后端API文档实现HTTP请求

        // 登录成功，跳转到主页
        this.navigateToHome()
    }

    /**
     * 跳转到主页
     */
    private func navigateToHome() {
        // TODO: 跳转到应用主页
        console.log("Login successful, navigating to home")
    }
}
