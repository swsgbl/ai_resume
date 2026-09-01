"""
AI 使用限制装饰器
"""

from functools import wraps
from typing import Callable, Optional
from fastapi import HTTPException, status, Depends
from sqlalchemy.ext.asyncio import AsyncSession

from app.services.ai_usage_service import get_ai_usage_service
from app.core.database import get_db


class AIUsageLimitExceeded(HTTPException):
    """AI 使用限制异常"""

    def __init__(self, used: int, limit: int, period: str = "day"):
        detail = f"AI 使用限制已超出 ({period}: {used}/{limit})。请升级账户或明天再试。"
        super().__init__(status_code=status.HTTP_429_TOO_MANY_REQUESTS, detail=detail)
        self.used = used
        self.limit = limit
        self.period = period


def check_ai_limit(operation: str = "generate"):
    """
    AI 使用限制检查装饰器

    Args:
        operation: 操作类型 (generate, optimize, analyze, etc.)

    Usage:
        @check_ai_limit("generate")
        async def ai_generate_resume(user_id: int, ...):
            ...
    """

    def decorator(func: Callable):
        @wraps(func)
        async def wrapper(*args, **kwargs):
            # 从参数中获取 db 和 user_id
            db: Optional[AsyncSession] = kwargs.get("db")
            user_id: Optional[int] = kwargs.get("user_id")

            # 如果没有从 kwargs 获取，尝试从位置参数获取
            if not db:
                for arg in args:
                    if isinstance(arg, AsyncSession):
                        db = arg
                        break

            if not user_id:
                for arg in args:
                    if isinstance(arg, int):
                        user_id = arg
                        break

            if not db or not user_id:
                # 如果无法获取，直接调用原函数
                return await func(*args, **kwargs)

            # 检查限制
            service = get_ai_usage_service()

            # 检查每日限制
            daily_allowed, daily_used, daily_limit = await service.check_daily_limit(db, user_id)
            if not daily_allowed:
                raise AIUsageLimitExceeded(daily_used, daily_limit, "day")

            # 检查每月限制
            monthly_allowed, monthly_used, monthly_limit = await service.check_monthly_limit(
                db, user_id
            )
            if not monthly_allowed:
                raise AIUsageLimitExceeded(monthly_used, monthly_limit, "month")

            # 执行原函数
            result = await func(*args, **kwargs)

            # 记录使用 (如果返回了 token 信息)
            if hasattr(result, "__dict__"):
                # 尝试从结果中提取 token 信息
                prompt_tokens = getattr(result, "prompt_tokens", 0)
                completion_tokens = getattr(result, "completion_tokens", 0)
                total_tokens = getattr(result, "total_tokens", 0)
                provider = getattr(result, "provider", "unknown")
                model = getattr(result, "model", "unknown")

                await service.record_usage(
                    db=db,
                    user_id=user_id,
                    provider=provider,
                    model=model,
                    operation=operation,
                    prompt_tokens=prompt_tokens,
                    completion_tokens=completion_tokens,
                    total_tokens=total_tokens,
                )

            return result

        return wrapper

    return decorator


async def require_ai_limit(
    user_id: int, operation: str = "generate", db: AsyncSession = Depends(get_db)
):
    """
    FastAPI 依赖注入形式的 AI 限制检查

    Usage:
        @router.post("/ai/generate")
        async def ai_generate(
            user_id: int,
            _limit: None = Depends(require_ai_limit(user_id, "generate")),
            db: AsyncSession = Depends(get_db)
        ):
            ...
    """
    service = get_ai_usage_service()

    # 检查每日限制
    daily_allowed, daily_used, daily_limit = await service.check_daily_limit(db, user_id)
    if not daily_allowed:
        raise AIUsageLimitExceeded(daily_used, daily_limit, "day")

    # 检查每月限制
    monthly_allowed, monthly_used, monthly_limit = await service.check_monthly_limit(db, user_id)
    if not monthly_allowed:
        raise AIUsageLimitExceeded(monthly_used, monthly_limit, "month")

    return None  # 返回值不重要，主要是检查
