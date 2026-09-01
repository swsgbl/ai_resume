// ProfilePage.cj - 个人中心页面
package views

import ohos.arkui.*
import ohos.arkui.state.*
import ohos.arkui.node.*
import services.*
import models.*

@Entry
@Component
public struct ProfilePage {
    @State private var user: User = User()
    @State private var isLoading: Bool = false

    private let authService: AuthService = AuthService()

    public func aboutToAppear(): void {
        this.loadUserInfo()
    }

    public func build(): void {
        Column() {
            // 顶部栏
            this.buildHeader()

            // 用户信息
            this.buildUserInfo()

            // 菜单列表
            this.buildMenuList()

            // 退出按钮
            this.buildLogoutButton()
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

            Text("个人中心")
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
    private func buildUserInfo(): void {
        Column() {
            // 头像
            Image(user.avatar != "" ? user.avatar : $r("app.media.avatar_default"))
                .width(80)
                .height(80)
                .borderRadius(40)
                .margin({ bottom: 16 })

            // 用户名
            Text(user.fullName != "" ? user.fullName : user.username)
                .fontSize(20)
                .fontWeight(FontWeight.Bold)
                .fontColor("#1e293b")

            // 邮箱
            Text(user.email)
                .fontSize(14)
                .fontColor("#64748b")
                .margin({ top: 4 })

            // 验证状态
            Row() {
                if (user.isVerified) {
                    Image($r("app.media.ic_verified"))
                        .width(16)
                        .height(16)
                        .margin({ right: 4 })

                    Text("已验证")
                        .fontSize(12)
                        .fontColor("#10b981")
                } else {
                    Text("未验证")
                        .fontSize(12)
                        .fontColor("#f59e0b")
                }
            }
            .margin({ top: 8 })
        }
        .width("100%")
        .padding(32)
        .backgroundColor("#ffffff")
        .margin({ top: 8 })
    }

    @Builder
    private func buildMenuList(): void {
        Column() {
            this.buildMenuItem("我的简历", $r("app.media.ic_resume"), {
                Router.push({ url: "pages/HomePage" })
            })

            this.buildMenuDivider()

            this.buildMenuItem("AI使用统计", $r("app.media.ic_chart"), {
                Router.push({ url: "pages/AIUsagePage" })
            })

            this.buildMenuDivider()

            this.buildMenuItem("设置", $r("app.media.ic_settings"), {
                Router.push({ url: "pages/SettingsPage" })
            })

            this.buildMenuDivider()

            this.buildMenuItem("帮助与反馈", $r("app.media.ic_help"), {
                Router.push({ url: "pages/HelpPage" })
            })

            this.buildMenuDivider()

            this.buildMenuItem("关于", $r("app.media.ic_info"), {
                Router.push({ url: "pages/AboutPage" })
            })
        }
        .width("100%")
        .backgroundColor("#ffffff")
        .margin({ top: 16 })
        .borderRadius(8)
    }

    @Builder
    private func buildMenuItem(label: String, icon: Resource, onClick: () -> void): void {
        Row() {
            Image(icon)
                .width(24)
                .height(24)
                .color("#64748b")

            Text(label)
                .fontSize(16)
                .fontColor("#1e293b")
                .margin({ left: 16 })
                .layoutWeight(1)

            Image($r("app.media.ic_arrow_right"))
                .width(20)
                .height(20)
                .color("#94a3b8")
        }
        .width("100%")
        .height(56)
        .padding({ left: 16, right: 16 })
        .onClick(onClick)
    }

    @Builder
    private func buildMenuDivider(): void {
        Divider()
            .width("100%")
            .height(1)
            .color("#f1f5f9")
            .margin({ left: 56 })
    }

    @Builder
    private func buildLogoutButton(): void {
        Button("退出登录")
            .width("90%")
            .height(48)
            .fontSize(16)
            .fontColor("#ef4444")
            .backgroundColor("#ffffff")
            .borderRadius(8)
            .margin({ top: 32 })
            .onClick {
                this.handleLogout()
            }
    }

    private func loadUserInfo(): void {
        // 从本地存储加载用户信息
        // 实际应用中应该从API获取
    }

    private func handleLogout(): void {
        authService.logout()
        Router.replace({ url: "pages/LoginPage" })
    }
}
