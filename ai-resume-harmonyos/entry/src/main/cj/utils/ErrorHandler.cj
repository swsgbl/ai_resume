// ErrorHandler.cj - 统一错误处理
package utils

import std.collection.*
import ohos.hiviewdfx.*

/**
 * 错误类型枚举
 */
public enum ErrorType {
    NETWORK_ERROR       // 网络错误
    AUTH_ERROR          // 认证错误
    VALIDATION_ERROR    // 验证错误
    SERVER_ERROR        // 服务器错误
    UNKNOWN_ERROR       // 未知错误
}

/**
 * 应用错误类
 */
public class AppError {
    public var type: ErrorType = ErrorType.UNKNOWN_ERROR
    public var code: String = ""
    public var message: String = ""
    public var details: String = ""
    public var timestamp: String = ""

    public init(type: ErrorType, code: String, message: String, details: String = "") {
        this.type = type
        this.code = code
        this.message = message
        this.details = details
        this.timestamp = getCurrentTimestamp()
    }

    private func getCurrentTimestamp(): String {
        return System.currentTimeMillis().toString()
    }

    public func toString(): String {
        return "Error(${code}): ${message}"
    }
}

/**
 * 统一错误处理器
 *
 * 提供错误分类、格式化和日志记录功能
 */
public class ErrorHandler {
    private static let logger = Logger("ErrorHandler")

    /**
     * 处理HTTP错误响应
     */
    public static func handleHttpError(statusCode: Int32, body: String): AppError {
        let message = parseErrorMessage(body)

        if (statusCode == 401) {
            return AppError(
                type: ErrorType.AUTH_ERROR,
                code: "AUTH_001",
                message: "认证失败，请重新登录",
                details: message
            )
        } else if (statusCode == 403) {
            return AppError(
                type: ErrorType.AUTH_ERROR,
                code: "AUTH_002",
                message: "没有权限访问",
                details: message
            )
        } else if (statusCode == 404) {
            return AppError(
                type: ErrorType.VALIDATION_ERROR,
                code: "VAL_001",
                message: "请求的资源不存在",
                details: message
            )
        } else if (statusCode >= 500) {
            return AppError(
                type: ErrorType.SERVER_ERROR,
                code: "SRV_${statusCode}",
                message: "服务器错误，请稍后重试",
                details: message
            )
        } else {
            return AppError(
                type: ErrorType.UNKNOWN_ERROR,
                code: "HTTP_${statusCode}",
                message: "请求失败",
                details: message
            )
        }
    }

    /**
     * 处理网络异常
     */
    public static func handleNetworkException(exception: Exception): AppError {
        logger.error("Network exception: ${exception.message}")

        return AppError(
            type: ErrorType.NETWORK_ERROR,
            code: "NET_001",
            message: "网络连接失败，请检查网络设置",
            details: exception.message
        )
    }

    /**
     * 处理JSON解析异常
     */
    public static func handleParseException(exception: Exception, context: String): AppError {
        logger.error("Parse exception in ${context}: ${exception.message}")

        return AppError(
            type: ErrorType.UNKNOWN_ERROR,
            code: "PARSE_001",
            message: "数据解析失败",
            details: "${context}: ${exception.message}"
        )
    }

    /**
     * 处理验证错误
     */
    public static func handleValidationError(field: String, message: String): AppError {
        return AppError(
            type: ErrorType.VALIDATION_ERROR,
            code: "VAL_002",
            message: message,
            details: "Field: ${field}"
        )
    }

    /**
     * 解析错误消息
     */
    private static func parseErrorMessage(body: String): String {
        // 尝试从响应体中提取错误信息
        try {
            let obj = JsonParser.parse(body)
            if (obj.containsKey("message")) {
                return obj.getString("message")
            } else if (obj.containsKey("error")) {
                return obj.getString("error")
            } else if (obj.containsKey("detail")) {
                return obj.getString("detail")
            }
        } catch (e: Exception) {
            // 解析失败，返回原始内容
        }

        // 如果无法解析，返回前100个字符
        if (body.size() > 100) {
            return body.substring(0, 100)
        }
        return body
    }

    /**
     * 记录错误到日志
     */
    public static func logError(error: AppError): Unit {
        logger.error("Error [${error.code}]: ${error.message}")
        if (error.details != "") {
            logger.error("Details: ${error.details}")
        }
    }

    /**
     * 显示用户友好的错误提示
     */
    public static func getUserMessage(error: AppError): String {
        return error.message
    }

    /**
     * 是否为可重试的错误
     */
    public static func isRetryable(error: AppError): Bool {
        return error.type == ErrorType.NETWORK_ERROR ||
               error.type == ErrorType.SERVER_ERROR
    }
}
