package views

/**
 * OAuth登录按钮样式库
 * 提供统一的按钮样式定义
 */
export object OAuthButtonStyles {
    /**
     * 微信按钮样式
     */
    public static func weChatButtonStyle(): ButtonStyle {
        return ButtonStyle({
            Text("微信登录")
                .fontSize(16)
                .fontColor(Color.White)
                .fontWeight(FontWeight.Medium)
        })
        .backgroundColor('#07C160')
        .borderRadius(8)
        .height(50)
        .width('100%')
    }

    /**
     * 支付宝按钮样式
     */
    public static func alipayButtonStyle(): ButtonStyle {
        return ButtonStyle({
            Text("支付宝登录")
                .fontSize(16)
                .fontColor(Color.White)
                .fontWeight(FontWeight.Medium)
        })
        .backgroundColor('#1677FF')
        .borderRadius(8)
        .height(50)
        .width('100%')
    }

    /**
     * 主按钮样式
     */
    public static func primaryButtonStyle(text: String): ButtonStyle {
        return ButtonStyle({
            Text(text)
                .fontSize(16)
                .fontColor(Color.White)
                .fontWeight(FontWeight.Medium)
        })
        .backgroundColor('#007DFF')
        .borderRadius(8)
        .height(50)
        .width('100%')
    }

    /**
     * 次要按钮样式
     */
    public static func secondaryButtonStyle(text: String): ButtonStyle {
        return ButtonStyle({
            Text(text)
                .fontSize(16)
                .fontColor('#007DFF')
                .fontWeight(FontWeight.Medium)
        })
        .backgroundColor('#F5F5F5')
        .borderRadius(8)
        .height(50)
        .width('100%')
    }

    /**
     * 禁用按钮样式
     */
    public static func disabledButtonStyle(text: String): ButtonStyle {
        return ButtonStyle({
            Text(text)
                .fontSize(16)
                .fontColor('#CCCCCC')
                .fontWeight(FontWeight.Medium)
        })
        .backgroundColor('#F0F0F0')
        .borderRadius(8)
        .height(50)
        .width('100%')
        .enabled(false)
    }
}

/**
 * OAuth颜色主题
 */
export object OAuthColors {
    public static let WECHAT_GREEN: String = '#07C160'
    public static let ALIPAY_BLUE: String = '#1677FF'
    public static let PRIMARY_BLUE: String = '#007DFF'
    public static let BACKGROUND_GRAY: String = '#F5F5F5'
    public static let TEXT_PRIMARY: String = '#333333'
    public static let TEXT_SECONDARY: String = '#666666'
    public static let TEXT_HINT: String = '#999999'
    public static let BORDER_COLOR: String = '#E0E0E0'
    public static let ERROR_RED: String = '#FF4444'
    public static let SUCCESS_GREEN: String = '#52C41A'
}

/**
 * OAuth文字样式
 */
export object OAuthTextStyles {
    public static func titleStyle(): TextStyle {
        return TextStyle({
            Text()
                .fontSize(24)
                .fontWeight(FontWeight.Bold)
                .fontColor(OAuthColors.TEXT_PRIMARY)
        })
    }

    public static func subtitleStyle(): TextStyle {
        return TextStyle({
            Text()
                .fontSize(16)
                .fontColor(OAuthColors.TEXT_SECONDARY)
        })
    }

    public static func hintStyle(): TextStyle {
        return TextStyle({
            Text()
                .fontSize(14)
                .fontColor(OAuthColors.TEXT_HINT)
        })
    }

    public static func buttonTextStyle(): TextStyle {
        return TextStyle({
            Text()
                .fontSize(16)
                .fontWeight(FontWeight.Medium)
                .fontColor(Color.White)
        })
    }
}
