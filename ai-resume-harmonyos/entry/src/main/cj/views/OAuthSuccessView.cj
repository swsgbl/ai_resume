package views

import models.oauth.OAuthUser

/**
 * OAuth登录成功视图
 * 显示登录成功的动画和用户信息
 */
@Component
export struct OAuthSuccessView {
    @Prop private oauthUser: OAuthUser? = null
    @Prop private displayName: String = "用户"

    build() {
        Column() {
            // 成功动画
            this.buildSuccessAnimation()

            // 成功标题
            Text("登录成功")
                .fontSize(24)
                .fontWeight(FontWeight.Bold)
                .fontColor('#333333')
                .margin({ bottom: 8 })

            // 欢迎文字
            Text("欢迎回来，${this.displayName}")
                .fontSize(16)
                .fontColor('#666666')
                .margin({ bottom: 40 })

            // 用户信息卡片
            if (this.oauthUser != null) {
                this.buildUserInfoCard()
            }

            // 进入按钮
            this.buildEnterButton()
        }
        .width('100%')
        .height('100%')
        .justifyContent(FlexAlign.Start)
        .backgroundColor('#FFFFFF')
        .padding(20)
    }

    /**
     * 构建成功动画
     */
    @Builder
    private buildSuccessAnimation() {
        Column() {
            Image($r('app.media.success_icon'))
                .width(100)
                .height(100)
                .objectFit(ImageFit.Contain)
                .margin({ top: 80, bottom: 24 })

            // 成功动画效果
            Image($r('app.media.success_check'))
                .width(60)
                .height(60)
                .objectFit(ImageFit.Contain)
                .opacity(0.8)
        }
    }

    /**
     * 构建用户信息卡片
     */
    @Builder
    private buildUserInfoCard() {
        Column() {
            // 头像
            if (this.oauthUser.avatarUrl != null && !this.oauthUser.avatarUrl.isEmpty()) {
                Image(this.oauthUser.avatarUrl)
                    .width(80)
                    .height(80)
                    .borderRadius(40)
                    .margin({ bottom: 16 })
            } else {
                Image($r('app.media.default_avatar'))
                    .width(80)
                    .height(80)
                    .borderRadius(40)
                    .margin({ bottom: 16 })
            }

            // 昵称
            if (this.oauthUser.nickname != null && !this.oauthUser.nickname.isEmpty()) {
                Text(this.oauthUser.nickname)
                    .fontSize(20)
                    .fontWeight(FontWeight.Medium)
                    .fontColor('#333333')
                    .margin({ bottom: 8 })
            }

            // 登录方式
            Text("通过${this.getProviderName()}登录")
                .fontSize(14)
                .fontColor('#999999')
                .margin({ bottom: 20 })
        }
        .width('100%')
        .padding(20)
        .backgroundColor('#F5F5F5')
        .borderRadius(12)
        .margin({ bottom: 40 })
    }

    /**
     * 构建进入按钮
     */
    @Builder
    private buildEnterButton() {
        Button() {
            Text("进入应用")
                .fontSize(16)
                .fontColor(Color.White)
                .fontWeight(FontWeight.Medium)
        }
        .width('100%')
        .height(50)
        .backgroundColor('#007DFF')
        .borderRadius(8)
        .onClick(() => {
            this.handleEnter()
        })
    }

    /**
     * 获取提供商名称
     */
    private func getProviderName(): String {
        if (this.oauthUser.provider == OAuthProvider.WECHAT) {
            return "微信"
        } else if (this.oauthUser.provider == OAuthProvider.ALIPAY) {
            return "支付宝"
        } else {
            return "第三方"
        }
    }

    /**
     * 处理进入应用
     */
    private func handleEnter() {
        // TODO: 跳转到应用主页
        console.log("Navigate to home")
    }
}
