// Logger.cj - 统一日志工具
package utils

import ohos.hiviewdfx.*

/**
 * 统一日志管理工具
 *
 * 提供分级日志功能，便于调试和问题追踪
 */
public class Logger {
    private let logger: HiLog
    private let tag: String

    public init(tag: String) {
        this.tag = tag
        this.logger = HiLog()
    }

    /**
     * 调试级别日志
     */
    public func debug(message: String): Unit {
        logger.debug(formatLog("DEBUG", message))
    }

    /**
     * 信息级别日志
     */
    public func info(message: String): Unit {
        logger.info(formatLog("INFO", message))
    }

    /**
     * 警告级别日志
     */
    public func warn(message: String): Unit {
        logger.warn(formatLog("WARN", message))
    }

    /**
     * 错误级别日志
     */
    public func error(message: String): Unit {
        logger.error(formatLog("ERROR", message))
    }

    /**
     * 格式化日志消息
     */
    private func formatLog(level: String, message: String): String {
        let timestamp = getCurrentTime()
        return "[${timestamp}] [${level}] [${tag}] ${message}"
    }

    /**
     * 获取当前时间戳
     */
    private func getCurrentTime(): String {
        // 实现时间戳格式化
        return System.currentTimeMillis().toString()
    }
}
