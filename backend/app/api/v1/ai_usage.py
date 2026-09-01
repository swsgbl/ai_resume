"""
AI 使用统计和计费 API
"""

from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession
from pydantic import BaseModel

from app.core.database import get_db
from app.core.security import get_current_user
from app.models.user import User
from app.services.ai_usage_service import get_ai_usage_service
from app.schemas.common import Response

router = APIRouter(prefix="/ai", tags=["AI使用统计"])


class UsageStatsResponse(BaseModel):
    """使用统计响应"""

    period_days: int
    total_calls: int
    total_tokens: int
    total_cost: float
    by_provider: list
    by_operation: list


class LimitInfoResponse(BaseModel):
    """限制信息响应"""

    daily_used: int
    daily_limit: int
    daily_remaining: int
    monthly_used: int
    monthly_limit: int
    monthly_remaining: int
    tier: str


@router.get("/usage/stats", response_model=None)
async def get_usage_stats(
    days: int = 30,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """获取 AI 使用统计"""
    service = get_ai_usage_service()
    stats = await service.get_user_usage_stats(db, current_user.id, days)

    return Response(data=UsageStatsResponse(**stats), message="获取成功")


@router.get("/usage/limits", response_model=None)
async def get_limit_info(
    current_user: User = Depends(get_current_user), db: AsyncSession = Depends(get_db)
):
    """获取使用限制信息"""
    service = get_ai_usage_service()
    limit = await service.get_user_limit(db, current_user.id)

    # 获取使用量
    _, daily_used, daily_limit = await service.check_daily_limit(db, current_user.id)
    _, monthly_used, monthly_limit = await service.check_monthly_limit(db, current_user.id)

    return Response(
        data=LimitInfoResponse(
            daily_used=daily_used,
            daily_limit=daily_limit,
            daily_remaining=max(0, daily_limit - daily_used),
            monthly_used=monthly_used,
            monthly_limit=monthly_limit,
            monthly_remaining=max(0, monthly_limit - monthly_used),
            tier=limit.tier,
        ),
        message="获取成功",
    )


@router.get("/billing/current", response_model=None)
async def get_current_billing(
    current_user: User = Depends(get_current_user), db: AsyncSession = Depends(get_db)
):
    """获取当前计费周期"""
    service = get_ai_usage_service()
    billing = await service.ensure_billing_period(db, current_user.id)

    return Response(
        data={
            "period": billing.billing_period,
            "period_start": billing.period_start.isoformat(),
            "period_end": billing.period_end.isoformat(),
            "total_calls": billing.total_calls,
            "total_tokens": billing.total_tokens,
            "total_cost": float(billing.total_cost),
            "balance": float(billing.balance),
            "status": billing.status,
        },
        message="获取成功",
    )
