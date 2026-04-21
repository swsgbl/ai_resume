"""
API限流配置
使用slowapi实现请求频率限制,防止恶意刷接口
"""
from slowapi import Limiter
from slowapi.util import get_remote_address
from slowapi.errors import RateLimitExceeded
from fastapi import Request
from app.core.config import settings


def get_user_id(request: Request) -> str:
    """
    获取用户ID用于限流
    优先使用认证用户ID,否则使用IP地址
    """
    # 尝试从请求中获取用户ID
    try:
        # 检查是否有认证用户
        if hasattr(request.state, 'user') and request.state.user:
            return f"user:{request.state.user.id}"
    except (AttributeError, KeyError):
        # request.state 访问异常时降级到 IP
        pass

    # 降级到IP地址限流
    return get_remote_address(request)


# 动态选择存储后端
# 生产环境使用Redis，开发环境使用内存
_storage_uri = settings.REDIS_URL if settings.REDIS_URL else "memory://"

# 创建限流器
# 生产环境使用 Redis，开发环境使用内存存储
limiter = Limiter(
    key_func=get_user_id,
    storage_uri=_storage_uri,
    default_limits=["200/hour"],  # 默认限流
)


# 限流策略定义
class RateLimit:
    """限流策略类"""

    # 认证相关 - 严格限制
    AUTH_REGISTER = "5/hour"        # 注册:每小时5次
    AUTH_LOGIN = "20/minute"        # 登录:每分钟20次
    AUTH_PASSWORD_RESET = "3/hour"  # 密码重置:每小时3次
    AUTH_CODE_SEND = "10/hour"      # 验证码发送:每小时10次
    AUTH_CODE_VERIFY = "5/5minutes" # 验证码验证:每5分钟5次（防暴力破解）

    # 简历操作 - 中等限制
    RESUME_CREATE = "30/hour"       # 创建简历:每小时30次
    RESUME_UPDATE = "100/hour"      # 更新简历:每小时100次
    RESUME_DELETE = "20/hour"       # 删除简历:每小时20次
    RESUME_EXPORT = "50/hour"       # 导出简历:每小时50次

    # AI功能 - 严格限制(消耗资源)
    AI_GENERATE = "10/hour"         # AI生成:每小时10次（降低，防止API成本过高）
    AI_OPTIMIZE = "30/hour"         # AI优化:每小时30次
    AI_ANALYZE = "20/hour"          # AI分析:每小时20次

    # 通用查询 - 宽松限制
    GENERAL_GET = "300/hour"        # GET请求:每小时300次
    GENERAL_SEARCH = "100/hour"     # 搜索:每小时100次


# 自定义错误处理
async def rate_limit_exceeded_handler(request: Request, exc: RateLimitExceeded):
    """自定义限流错误响应"""
    from fastapi import JSONResponse

    return JSONResponse(
        status_code=429,
        content={
            "code": 429,
            "message": "请求过于频繁,请稍后再试",
            "detail": f"限流规则: {exc.detail}",
            "data": None
        }
    )
