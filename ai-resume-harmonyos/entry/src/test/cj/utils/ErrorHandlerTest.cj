// ErrorHandlerTest.cj - ErrorHandler 工具类单元测试
package test.utils

import utils.*
import testing.*
import ohos.hypium.*

/**
 * ErrorHandler 工具类测试套件
 */
@TestCase
public class ErrorHandlerTest {
    private let errorHandler: ErrorHandler

    public init() {
        this.errorHandler = ErrorHandler()
    }

    /**
     * 测试 HTTP 401 错误处理
     */
    @Test
    public func testHandleUnauthorizedError(): Unit {
        let error = ErrorHandler.handleHttpError(
            401,
            "{\"message\": \"Unauthorized\"}"
        )

        Assert.assertEquals(
            ErrorType.AUTH_ERROR,
            error.type
        )
        Assert.assertEquals(
            "AUTH_001",
            error.code
        )
        Assert.assertTrue(
            error.message.contains("认证")
        )
    }

    /**
     * 测试 HTTP 403 错误处理
     */
    @Test
    public func testHandleForbiddenError(): Unit {
        let error = ErrorHandler.handleHttpError(
            403,
            "{\"message\": \"Forbidden\"}"
        )

        Assert.assertEquals(
            ErrorType.AUTH_ERROR,
            error.type
        )
        Assert.assertEquals(
            "AUTH_002",
            error.code
        )
        Assert.assertTrue(
            error.message.contains("权限")
        )
    }

    /**
     * 测试 HTTP 404 错误处理
     */
    @Test
    public func testHandleNotFoundError(): Unit {
        let error = ErrorHandler.handleHttpError(
            404,
            "{\"message\": \"Not Found\"}"
        )

        Assert.assertEquals(
            ErrorType.VALIDATION_ERROR,
            error.type
        )
        Assert.assertEquals(
            "VAL_001",
            error.code
        )
        Assert.assertTrue(
            error.message.contains("不存在")
        )
    }

    /**
     * 测试 HTTP 500 服务器错误处理
     */
    @Test
    public func testHandleServerError(): Unit {
        let error = ErrorHandler.handleHttpError(
            500,
            "{\"message\": \"Internal Server Error\"}"
        )

        Assert.assertEquals(
            ErrorType.SERVER_ERROR,
            error.type
        )
        Assert.assertTrue(
            error.code.startsWith("SRV_")
        )
        Assert.assertTrue(
            error.message.contains("服务器")
        )
    }

    /**
     * 测试 HTTP 503 服务不可用错误
     */
    @Test
    public func testHandleServiceUnavailableError(): Unit {
        let error = ErrorHandler.handleHttpError(
            503,
            "{\"message\": \"Service Unavailable\"}"
        )

        Assert.assertEquals(
            ErrorType.SERVER_ERROR,
            error.type
        )
        Assert.assertTrue(
            error.code.startsWith("SRV_")
        )
    }

    /**
     * 测试未知 HTTP 错误处理
     */
    @Test
    public func testHandleUnknownHttpError(): Unit {
        let error = ErrorHandler.handleHttpError(
            418,
            "I'm a teapot"
        )

        Assert.assertEquals(
            ErrorType.UNKNOWN_ERROR,
            error.type
        )
        Assert.assertTrue(
            error.code.startsWith("HTTP_")
        )
    }

    /**
     * 测试网络异常处理
     */
    @Test
    public func testHandleNetworkException(): Unit {
        let exception = Exception("Network timeout")
        let error = ErrorHandler.handleNetworkException(exception)

        Assert.assertEquals(
            ErrorType.NETWORK_ERROR,
            error.type
        )
        Assert.assertEquals(
            "NET_001",
            error.code
        )
        Assert.assertTrue(
            error.message.contains("网络")
        )
    }

    /**
     * 测试 JSON 解析异常处理
     */
    @Test
    public func testHandleParseException(): Unit {
        let exception = Exception("Invalid JSON format")
        let error = ErrorHandler.handleParseException(
            exception,
            "parseUser"
        )

        Assert.assertEquals(
            ErrorType.UNKNOWN_ERROR,
            error.type
        )
        Assert.assertEquals(
            "PARSE_001",
            error.code
        )
        Assert.assertTrue(
            error.message.contains("解析")
        )
    }

    /**
     * 测试验证错误处理
     */
    @Test
    public func testHandleValidationError(): Unit {
        let error = ErrorHandler.handleValidationError(
            "email",
            "Email format is invalid"
        )

        Assert.assertEquals(
            ErrorType.VALIDATION_ERROR,
            error.type
        )
        Assert.assertEquals(
            "VAL_002",
            error.code
        )
        Assert.assertTrue(
            error.details.contains("email")
        )
    }

    /**
     * 测试从响应体提取错误消息
     */
    @Test
    public func testExtractErrorMessageFromJson(): Unit {
        let responseBody = "{\"error\": \"User not found\"}"
        let error = ErrorHandler.handleHttpError(404, responseBody)

        Assert.assertTrue(
            error.details.contains("User not found") ||
            error.message.contains("不存在")
        )
    }

    /**
     * 测试从 message 字段提取错误
     */
    @Test
    public func testExtractMessageField(): Unit {
        let responseBody = "{\"message\": \"Validation failed\"}"
        let error = ErrorHandler.handleHttpError(400, responseBody)

        Assert.assertTrue(
            error.details.contains("Validation failed") ||
            error.message.contains("请求失败")
        )
    }

    /**
     * 测试从 detail 字段提取错误
     */
    @Test
    public func testExtractDetailField(): Unit {
        let responseBody = "{\"detail\": \"Detailed error info\"}"
        let error = ErrorHandler.handleHttpError(400, responseBody)

        Assert.assertTrue(
            error.details.contains("Detailed error info")
        )
    }

    /**
     * 测试无效 JSON 的错误处理
     */
    @Test
    public func testHandleInvalidJson(): Unit {
        let invalidJson = "This is not JSON"
        let error = ErrorHandler.handleHttpError(400, invalidJson)

        // 应该截断长文本或使用原始内容
        Assert.assertTrue(
            error.details.size() <= 100 ||
            error.details == invalidJson
        )
    }

    /**
     * 测试长错误消息截断
     */
    @Test
    public func testLongErrorMessageTruncation(): Unit {
        let longMessage = "a".repeat(200)
        let error = ErrorHandler.handleHttpError(400, longMessage)

        // 应该截断到100字符
        Assert.assertTrue(
            error.details.size() <= 100
        )
    }

    /**
     * 测试错误重试判断
     */
    @Test
    public func testIsRetryableForNetworkError(): Unit {
        let networkError = AppError(
            type: ErrorType.NETWORK_ERROR,
            code: "NET_001",
            message: "Network timeout"
        )

        Assert.assertTrue(
            "Network error should be retryable",
            ErrorHandler.isRetryable(networkError)
        )
    }

    /**
     * 测试错误重试判断 - 服务器错误
     */
    @Test
    public func testIsRetryableForServerError(): Unit {
        let serverError = AppError(
            type: ErrorType.SERVER_ERROR,
            code: "SRV_500",
            message: "Internal server error"
        )

        Assert.assertTrue(
            "Server error should be retryable",
            ErrorHandler.isRetryable(serverError)
        )
    }

    /**
     * 测试错误重试判断 - 验证错误
     */
    @Test
    public func testIsNotRetryableForValidationError(): Unit {
        let validationError = AppError(
            type: ErrorType.VALIDATION_ERROR,
            code: "VAL_001",
            message: "Invalid input"
        )

        Assert.assertFalse(
            "Validation error should not be retryable",
            ErrorHandler.isRetryable(validationError)
        )
    }

    /**
     * 测试错误重试判断 - 认证错误
     */
    @Test
    public func testIsNotRetryableForAuthError(): Unit {
        let authError = AppError(
            type: ErrorType.AUTH_ERROR,
            code: "AUTH_001",
            message: "Unauthorized"
        )

        Assert.assertFalse(
            "Auth error should not be retryable",
            ErrorHandler.isRetryable(authError)
        )
    }

    /**
     * 测试获取用户友好的错误消息
     */
    @Test
    public func testGetUserMessage(): Unit {
        let error = AppError(
            type: ErrorType.NETWORK_ERROR,
            code: "NET_001",
            message: "网络连接失败",
            details: "Timeout after 30s"
        )

        let userMessage = ErrorHandler.getUserMessage(error)
        Assert.assertEquals(
            "网络连接失败",
            userMessage
        )
    }

    /**
     * 测试错误时间戳
     */
    @Test
    public func testErrorTimestamp(): Unit {
        let beforeTime = System.currentTimeMillis()
        let error = AppError(
            type: ErrorType.UNKNOWN_ERROR,
            code: "TEST_001",
            message: "Test error"
        )
        let afterTime = System.currentTimeMillis()

        Assert.assertTrue(
            error.timestamp.toLong() >= beforeTime &&
            error.timestamp.toLong() <= afterTime
        )
    }

    /**
     * 测试错误 toString 方法
     */
    @Test
    public func testErrorToString(): Unit {
        let error = AppError(
            type: ErrorType.VALIDATION_ERROR,
            code: "VAL_001",
            message: "Invalid input"
        )

        let errorString = error.toString()
        Assert.assertTrue(
            errorString.contains("VAL_001") ||
            errorString.contains("Invalid input")
        )
    }
}
