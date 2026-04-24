// SettingsPage.cj - 设置页面（同步自 Web 版 SettingsPage）
// 包含服务器配置、AI模型配置、关于、帮助、隐私等
package views

import ohos.arkui.*
import ohos.arkui.state.*
import ohos.arkui.node.*
import services.*
import models.*
import utils.*

@Entry
@Component
public struct SettingsPage {
    @State private var provider: Int32 = 0  // 0=openai, 1=deepseek, 2=xiaomi
    @State private var baseUrl: String = "http://127.0.0.1:8000/api/v1"
    @State private var openaiKey: String = ""
    @State private var openaiModel: String = "gpt-4"
    @State private var deepseekKey: String = ""
    @State private var deepseekModel: String = "deepseek-chat"
    @State private var xiaomiKey: String = ""
    @State private var xiaomiModel: String = "MiMo-V2-Flash"
    @State private var isSaving: Bool = false
    @State private var message: String = ""

    private let prefs: Preferences = Preferences.get("settings_prefs")

    public func aboutToAppear(): void {
        // 加载配置 - 同步自 Web 版 SettingsPage useEffect
        baseUrl = prefs.getString("base_url", "http://127.0.0.1:8000/api/v1")
        provider = prefs.getInt("ai_provider", 0)
        openaiKey = prefs.getString("openai_key", "")
        openaiModel = prefs.getString("openai_model", "gpt-4")
        deepseekKey = prefs.getString("deepseek_key", "")
        deepseekModel = prefs.getString("deepseek_model", "deepseek-chat")
        xiaomiKey = prefs.getString("xiaomi_key", "")
        xiaomiModel = prefs.getString("xiaomi_model", "MiMo-V2-Flash")
    }

    public func build(): void {
        Column() {
            // 顶部栏
            this.buildHeader()

            Scroll() {
                Column() {
                    // 配置说明
                    this.buildNotice()

                    // 服务器配置
                    this.buildServerConfig()

                    // AI 提供商配置 - 同步自 Web 版 AI 模型配置
                    this.buildAIProviderConfig()

                    // 操作按钮
                    this.buildActions()

                    // 其他设置
                    this.buildOtherSettings()
                }
                .padding(16)
            }
            .layoutWeight(1)
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

            Text("设置")
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
    private func buildNotice(): void {
        Row() {
            Text("ℹ️ 配置后端服务器地址和 AI 提供商。所有配置仅保存在本地设备。")
                .fontSize(12)
                .fontColor("#d97706")
        }
        .width("100%")
        .padding(12)
        .backgroundColor("#fffbeb")
        .borderRadius(8)
        .margin({ bottom: 16 })
    }

    @Builder
    private func buildServerConfig(): void {
        Column() {
            Text("🌐 服务器配置")
                .fontSize(16)
                .fontWeight(FontWeight.Bold)
                .fontColor("#1e293b")
                .margin({ bottom: 12 })

            Text("后端服务器地址")
                .fontSize(12)
                .fontColor("#64748b")
                .width("100%")

            TextInput({ text: baseUrl })
                .width("100%")
                .height(40)
                .margin({ top: 4 })
                .onChange({ value => baseUrl = value })
                .borderRadius(8)
                .backgroundColor("#ffffff")
        }
        .width("100%")
        .padding(16)
        .backgroundColor("#ffffff")
        .borderRadius(8)
        .margin({ bottom: 16 })
        .alignItems(HorizontalAlign.Start)
    }

    @Builder
    private func buildAIProviderConfig(): void {
        Column() {
            Text("🤖 AI 模型配置")
                .fontSize(16)
                .fontWeight(FontWeight.Bold)
                .fontColor("#1e293b")
                .margin({ bottom: 12 })

            Text("选择 AI 提供商")
                .fontSize(12)
                .fontColor("#64748b")
                .width("100%")
                .margin({ bottom: 8 })

            // 提供商选择按钮 - 同步自 Web 版 provider选择
            Row() {
                this.buildProviderButton("🌟 OpenAI", 0)
                this.buildProviderButton("🧠 DeepSeek", 1)
                this.buildProviderButton("📱 小米AI", 2)
            }
            .width("100%")
            .justifyContent(FlexAlign.SpaceBetween)

            // 对应提供商的配置
            if (provider == 0) {
                this.buildOpenAIConfig()
            } else if (provider == 1) {
                this.buildDeepSeekConfig()
            } else {
                this.buildXiaomiConfig()
            }
        }
        .width("100%")
        .padding(16)
        .backgroundColor("#ffffff")
        .borderRadius(8)
        .margin({ bottom: 16 })
        .alignItems(HorizontalAlign.Start)
    }

    @Builder
    private func buildProviderButton(label: String, index: Int32): void {
        Text(label)
            .fontSize(12)
            .fontColor(provider == index ? "#ffffff" : "#64748b")
            .backgroundColor(provider == index ? "#f59e0b" : "#f1f5f9")
            .borderRadius(8)
            .padding({ left: 12, right: 12, top: 8, bottom: 8 })
            .onClick {
                provider = index
            }
    }

    @Builder
    private func buildOpenAIConfig(): void {
        Column() {
            Text("OpenAI 配置")
                .fontSize(14)
                .fontWeight(FontWeight.Bold)
                .fontColor("#f59e0b")
                .margin({ top: 12, bottom: 8 })

            Text("API 密钥")
                .fontSize(12)
                .fontColor("#64748b")
                .width("100%")

            TextInput({ text: openaiKey, placeholder: "sk-..." })
                .width("100%")
                .height(40)
                .margin({ top: 4 })
                .type(InputType.Normal)
                .onChange({ value => openaiKey = value })
                .borderRadius(8)
                .backgroundColor("#f8fafc")

            Text("模型")
                .fontSize(12)
                .fontColor("#64748b")
                .width("100%")
                .margin({ top: 12 })

            TextInput({ text: openaiModel, placeholder: "gpt-4" })
                .width("100%")
                .height(40)
                .margin({ top: 4 })
                .onChange({ value => openaiModel = value })
                .borderRadius(8)
                .backgroundColor("#f8fafc")
        }
    }

    @Builder
    private func buildDeepSeekConfig(): void {
        Column() {
            Text("DeepSeek 配置")
                .fontSize(14)
                .fontWeight(FontWeight.Bold)
                .fontColor("#f59e0b")
                .margin({ top: 12, bottom: 8 })

            Text("API 密钥")
                .fontSize(12)
                .fontColor("#64748b")
                .width("100%")

            TextInput({ text: deepseekKey, placeholder: "sk-..." })
                .width("100%")
                .height(40)
                .margin({ top: 4 })
                .onChange({ value => deepseekKey = value })
                .borderRadius(8)
                .backgroundColor("#f8fafc")

            Text("模型")
                .fontSize(12)
                .fontColor("#64748b")
                .width("100%")
                .margin({ top: 12 })

            TextInput({ text: deepseekModel, placeholder: "deepseek-chat" })
                .width("100%")
                .height(40)
                .margin({ top: 4 })
                .onChange({ value => deepseekModel = value })
                .borderRadius(8)
                .backgroundColor("#f8fafc")
        }
    }

    @Builder
    private func buildXiaomiConfig(): void {
        Column() {
            Text("小米 AI 配置")
                .fontSize(14)
                .fontWeight(FontWeight.Bold)
                .fontColor("#f59e0b")
                .margin({ top: 12, bottom: 8 })

            Text("API 密钥")
                .fontSize(12)
                .fontColor("#64748b")
                .width("100%")

            TextInput({ text: xiaomiKey, placeholder: "您的 API 密钥" })
                .width("100%")
                .height(40)
                .margin({ top: 4 })
                .onChange({ value => xiaomiKey = value })
                .borderRadius(8)
                .backgroundColor("#f8fafc")

            Text("模型")
                .fontSize(12)
                .fontColor("#64748b")
                .width("100%")
                .margin({ top: 12 })

            TextInput({ text: xiaomiModel, placeholder: "MiMo-V2-Flash" })
                .width("100%")
                .height(40)
                .margin({ top: 4 })
                .onChange({ value => xiaomiModel = value })
                .borderRadius(8)
                .backgroundColor("#f8fafc")
        }
    }

    @Builder
    private func buildActions(): void {
        Column() {
            if (message != "") {
                Text(message)
                    .fontSize(14)
                    .fontColor(message.contains("成功") ? "#10b981" : "#ef4444")
                    .margin({ bottom: 12 })
            }

            Button(isSaving ? "保存中..." : "保存配置")
                .width("100%")
                .height(48)
                .fontSize(16)
                .fontColor("#ffffff")
                .backgroundColor("#2563eb")
                .borderRadius(8)
                .enabled(!isSaving)
                .margin({ bottom: 8 })
                .onClick {
                    this.handleSave()
                }

            Button("清除配置")
                .width("100%")
                .height(48)
                .fontSize(16)
                .fontColor("#ef4444")
                .backgroundColor("#ffffff")
                .borderRadius(8)
                .onClick {
                    prefs.clear()
                    prefs.flush()
                    message = "配置已清除"
                }
        }
        .margin({ bottom: 16 })
    }

    @Builder
    private func buildOtherSettings(): void {
        Column() {
            // 关于
            this.buildMenuItem("关于", "版本 1.0.0", {
                Router.push({ url: "pages/AboutPage" })
            })

            Divider().width("100%").height(1).color("#f1f5f9").margin({ left: 56 })

            // 帮助
            this.buildMenuItem("帮助", "", {
                Router.push({ url: "pages/HelpPage" })
            })

            Divider().width("100%").height(1).color("#f1f5f9").margin({ left: 56 })

            // 隐私政策
            this.buildMenuItem("隐私政策", "", {
                Router.push({ url: "pages/PrivacyPage" })
            })

            Divider().width("100%").height(1).color("#f1f5f9").margin({ left: 56 })

            // 用户协议
            this.buildMenuItem("用户协议", "", {
                Router.push({ url: "pages/TermsPage" })
            })
        }
        .width("100%")
        .backgroundColor("#ffffff")
        .borderRadius(8)
    }

    @Builder
    private func buildMenuItem(label: String, subtitle: String, onClick: () -> void): void {
        Row() {
            Text(label)
                .fontSize(16)
                .fontColor("#1e293b")
                .layoutWeight(1)

            if (subtitle != "") {
                Text(subtitle)
                    .fontSize(12)
                    .fontColor("#94a3b8")
            }

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

    // ==================== 保存配置 ====================
    private func handleSave(): void {
        isSaving = true
        message = ""

        prefs.putString("base_url", baseUrl)
        prefs.putInt("ai_provider", provider)
        prefs.putString("openai_key", openaiKey)
        prefs.putString("openai_model", openaiModel)
        prefs.putString("deepseek_key", deepseekKey)
        prefs.putString("deepseek_model", deepseekModel)
        prefs.putString("xiaomi_key", xiaomiKey)
        prefs.putString("xiaomi_model", xiaomiModel)
        prefs.flush()

        isSaving = false
        message = "配置已保存"
    }
}
