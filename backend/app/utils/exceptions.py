"""
异常处理模块 - 自定义异常和错误处理
"""

from typing import Any, Optional
from fastapi import HTTPException, status
from fastapi.responses import JSONResponse
from loguru import logger


class AppException(Exception):
    """应用基础异常"""

    def __init__(
        self,
        code: int = 500,
        message: str = "服务器内部错误",
        detail: Any = None,
        headers: Optional[dict] = None,
    ):
        self.code = code
        self.message = message
        self.detail = detail
        self.headers = headers
        super().__init__(message)


class AuthenticationError(AppException):
    """认证错误"""

    def __init__(self, message: str = "认证失败", detail: Any = None):
        super().__init__(
            code=status.HTTP_401_UNAUTHORIZED,
            message=message,
            detail=detail,
            headers={"WWW-Authenticate": "Bearer"},
        )


class AuthorizationError(AppException):
    """授权错误"""

    def __init__(self, message: str = "权限不足", detail: Any = None):
        super().__init__(code=status.HTTP_403_FORBIDDEN, message=message, detail=detail)


class NotFoundError(AppException):
    """资源不存在"""

    def __init__(self, resource: str = "资源", detail: Any = None):
        super().__init__(code=status.HTTP_404_NOT_FOUND, message=f"{resource}不存在", detail=detail)


class ValidationError(AppException):
    """验证错误"""

    def __init__(self, message: str = "参数验证失败", detail: Any = None):
        super().__init__(code=status.HTTP_422_UNPROCESSABLE_ENTITY, message=message, detail=detail)


class ConflictError(AppException):
    """冲突错误（如重复注册）"""

    def __init__(self, message: str = "资源冲突", detail: Any = None):
        super().__init__(code=status.HTTP_409_CONFLICT, message=message, detail=detail)


class RateLimitError(AppException):
    """速率限制错误"""

    def __init__(self, message: str = "请求过于频繁，请稍后再试", detail: Any = None):
        super().__init__(code=status.HTTP_429_TOO_MANY_REQUESTS, message=message, detail=detail)


class ExternalServiceError(AppException):
    """外部服务错误"""

    def __init__(self, service: str = "外部服务", detail: Any = None):
        super().__init__(
            code=status.HTTP_502_BAD_GATEWAY, message=f"{service}暂时不可用", detail=detail
        )


class AIServiceError(AppException):
    """AI服务错误"""

    def __init__(self, message: str = "AI服务暂时不可用", detail: Any = None):
        super().__init__(code=status.HTTP_503_SERVICE_UNAVAILABLE, message=message, detail=detail)


class DatabaseError(AppException):
    """数据库错误"""

    def __init__(self, message: str = "数据库操作失败", detail: Any = None):
        super().__init__(code=status.HTTP_500_INTERNAL_SERVER_ERROR, message=message, detail=detail)


# 错误响应格式化
def format_error_response(exc: AppException, debug: bool = False) -> JSONResponse:
    """格式化错误响应"""
    content = {"code": exc.code, "message": exc.message, "success": False}

    if debug and exc.detail:
        content["detail"] = exc.detail

    return JSONResponse(status_code=exc.code, content=content, headers=exc.headers)


# 异常处理装饰器
def handle_exceptions(func):
    """异常处理装饰器"""

    async def wrapper(*args, **kwargs):
        try:
            return await func(*args, **kwargs)
        except AppException as e:
            logger.error(f"应用异常: {e.message} - {e.detail}")
            raise HTTPException(status_code=e.code, detail=e.message, headers=e.headers)
        except HTTPException:
            raise
        except Exception as e:
            logger.exception(f"未处理异常: {str(e)}")
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail="服务器内部错误"
            )

    return wrapper


# 错误码常量
class ErrorCode:
    """错误码定义"""

    # 通用错误 (1000-1999)
    SUCCESS = 0
    UNKNOWN_ERROR = 1000
    INVALID_PARAMS = 1001
    RATE_LIMIT = 1002

    # 认证错误 (2000-2999)
    AUTH_FAILED = 2000
    TOKEN_EXPIRED = 2001
    TOKEN_INVALID = 2002
    USER_NOT_FOUND = 2003
    WRONG_PASSWORD = 2004
    USER_DISABLED = 2005

    # 授权错误 (3000-3999)
    PERMISSION_DENIED = 3000
    SUBSCRIPTION_REQUIRED = 3001
    QUOTA_EXCEEDED = 3002

    # 业务错误 (4000-4999)
    RESUME_NOT_FOUND = 4000
    TEMPLATE_NOT_FOUND = 4001
    EXPORT_FAILED = 4002
    FILE_TOO_LARGE = 4003
    INVALID_FILE_TYPE = 4004

    # AI服务错误 (5000-5999)
    AI_SERVICE_UNAVAILABLE = 5000
    AI_GENERATION_FAILED = 5001
    AI_QUOTA_EXCEEDED = 5002
    AI_CONTENT_POLICY = 5003

    # 数据库错误 (6000-6999)
    DB_CONNECTION_ERROR = 6000
    DB_QUERY_ERROR = 6001
    DB_CONSTRAINT_ERROR = 6002


# 错误消息映射
ERROR_MESSAGES = {
    ErrorCode.SUCCESS: "操作成功",
    ErrorCode.UNKNOWN_ERROR: "未知错误",
    ErrorCode.INVALID_PARAMS: "参数验证失败",
    ErrorCode.RATE_LIMIT: "请求过于频繁",
    ErrorCode.AUTH_FAILED: "认证失败",
    ErrorCode.TOKEN_EXPIRED: "登录已过期，请重新登录",
    ErrorCode.TOKEN_INVALID: "无效的访问令牌",
    ErrorCode.USER_NOT_FOUND: "用户不存在",
    ErrorCode.WRONG_PASSWORD: "密码错误",
    ErrorCode.USER_DISABLED: "账户已被禁用",
    ErrorCode.PERMISSION_DENIED: "权限不足",
    ErrorCode.SUBSCRIPTION_REQUIRED: "需要订阅高级会员",
    ErrorCode.QUOTA_EXCEEDED: "使用配额已用完",
    ErrorCode.RESUME_NOT_FOUND: "简历不存在",
    ErrorCode.TEMPLATE_NOT_FOUND: "模板不存在",
    ErrorCode.EXPORT_FAILED: "导出失败",
    ErrorCode.FILE_TOO_LARGE: "文件大小超过限制",
    ErrorCode.INVALID_FILE_TYPE: "不支持的文件类型",
    ErrorCode.AI_SERVICE_UNAVAILABLE: "AI服务暂时不可用",
    ErrorCode.AI_GENERATION_FAILED: "AI生成失败",
    ErrorCode.AI_QUOTA_EXCEEDED: "AI使用次数已用完",
    ErrorCode.AI_CONTENT_POLICY: "内容不符合政策",
    ErrorCode.DB_CONNECTION_ERROR: "数据库连接失败",
    ErrorCode.DB_QUERY_ERROR: "数据库查询失败",
    ErrorCode.DB_CONSTRAINT_ERROR: "数据约束冲突",
}


def get_error_message(code: int) -> str:
    """根据错误码获取错误消息"""
    return ERROR_MESSAGES.get(code, "未知错误")
