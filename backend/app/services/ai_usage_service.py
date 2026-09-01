"""
AI 使用限制和计费服务
"""

from datetime import datetime, timezone, timedelta
from typing import Optional, Dict, Any
from decimal import Decimal
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, func
import redis.asyncio as redis

from app.models.ai_usage import AIUsageLimit, AIUsageRecord, AIBilling
from app.models.user import User, UserRole
from app.core.config import settings

# Token 定价 (每1000 tokens的价格, 单位: USD)
TOKEN_PRICING = {
    "openai": {
        "gpt-4": Decimal("0.03"),  # $0.03 per 1K tokens
        "gpt-4-turbo": Decimal("0.01"),
        "gpt-3.5-turbo": Decimal("0.002"),
    },
    "deepseek": {
        "deepseek-chat": Decimal("0.0014"),
    },
    "xiaomi": {
        "MiMo-V2-Flash": Decimal("0.001"),
        "MiMo-V2": Decimal("0.003"),
    },
}


class AIUsageService:
    """AI 使用限制和计费服务"""

    def __init__(self):
        self.redis_url = settings.REDIS_URL
        self._redis: Optional[redis.Redis] = None

    async def get_redis(self):
        """获取 Redis 连接"""
        if self._redis is None:
            self._redis = redis.from_url(self.redis_url, encoding="utf-8", decode_responses=True)
        return self._redis

    async def close_redis(self):
        """关闭 Redis 连接"""
        if self._redis:
            await self._redis.close()
            self._redis = None

    async def get_user_limit(self, db: AsyncSession, user_id: int) -> AIUsageLimit:
        """获取用户限制配置，不存在则创建"""
        result = await db.execute(select(AIUsageLimit).where(AIUsageLimit.user_id == user_id))
        limit = result.scalar_one_or_none()

        if not limit:
            # 获取用户信息以确定等级
            user_result = await db.execute(select(User).where(User.id == user_id))
            user = user_result.scalar_one_or_none()

            # 根据角色确定等级
            tier = "free"
            if user and user.role == UserRole.PREMIUM:
                tier = "pro"
            elif user and user.role == UserRole.ENTERPRISE:
                tier = "enterprise"

            # 创建默认限制
            limit = AIUsageLimit(
                user_id=user_id,
                tier=tier,
                daily_limit=10 if tier == "free" else 100,
                monthly_limit=200 if tier == "free" else 2000,
            )
            db.add(limit)
            await db.commit()
            await db.refresh(limit)

        return limit

    async def check_daily_limit(self, db: AsyncSession, user_id: int) -> tuple[bool, int, int]:
        """
        检查每日使用限制

        Returns:
            (is_allowed, used_count, limit_count)
        """
        limit = await self.get_user_limit(db, user_id)

        # 检查是否需要重置
        now = datetime.now(timezone.utc)
        today_start = now.replace(hour=0, minute=0, second=0, microsecond=0)

        # 确保 last_daily_reset 是 timezone-aware
        last_reset = limit.last_daily_reset
        if last_reset.tzinfo is None:
            last_reset = last_reset.replace(tzinfo=timezone.utc)

        if last_reset < today_start:
            # 重置计数
            limit.last_daily_reset = now
            await db.commit()

        # 从 Redis 获取今日使用次数 (快速)
        redis_key = f"ai_usage:daily:{user_id}:{now.strftime('%Y%m%d')}"
        redis_client = await self.get_redis()

        try:
            used = await redis_client.get(redis_key)
            used_count = int(used) if used else 0
        except (redis.RedisError, ValueError, TypeError):
            # Redis 失败，从数据库查询
            today_end = today_start + timedelta(days=1)
            result = await db.execute(
                select(func.count(AIUsageRecord.id))
                .where(AIUsageRecord.user_id == user_id)
                .where(AIUsageRecord.created_at >= today_start)
                .where(AIUsageRecord.created_at < today_end)
            )
            used_count = result.scalar() or 0

        # 根据用户等级获取限制
        if limit.tier in ("pro", "enterprise"):
            limit_count = limit.vip_daily_limit
        else:
            limit_count = limit.daily_limit

        is_allowed = used_count < limit_count
        return is_allowed, used_count, limit_count

    async def check_monthly_limit(self, db: AsyncSession, user_id: int) -> tuple[bool, int, int]:
        """检查每月使用限制"""
        limit = await self.get_user_limit(db, user_id)

        # 检查是否需要重置
        now = datetime.now(timezone.utc)
        month_start = now.replace(day=1, hour=0, minute=0, second=0, microsecond=0)

        # 确保 last_monthly_reset 是 timezone-aware
        last_reset = limit.last_monthly_reset
        if last_reset.tzinfo is None:
            last_reset = last_reset.replace(tzinfo=timezone.utc)

        if last_reset < month_start:
            limit.last_monthly_reset = now
            await db.commit()

        # 从 Redis 获取本月使用次数
        redis_key = f"ai_usage:monthly:{user_id}:{now.strftime('%Y%m')}"
        redis_client = await self.get_redis()

        try:
            used = await redis_client.get(redis_key)
            used_count = int(used) if used else 0
        except (redis.RedisError, ValueError, TypeError):
            # Redis 失败，从数据库查询
            month_end = month_start + timedelta(days=32)
            month_end = month_end.replace(day=1)
            result = await db.execute(
                select(func.count(AIUsageRecord.id))
                .where(AIUsageRecord.user_id == user_id)
                .where(AIUsageRecord.created_at >= month_start)
                .where(AIUsageRecord.created_at < month_end)
            )
            used_count = result.scalar() or 0

        # 根据用户等级获取限制
        if limit.tier in ("pro", "enterprise"):
            limit_count = limit.vip_monthly_limit
        else:
            limit_count = limit.monthly_limit

        is_allowed = used_count < limit_count
        return is_allowed, used_count, limit_count

    async def record_usage(
        self,
        db: AsyncSession,
        user_id: int,
        provider: str,
        model: str,
        operation: str,
        prompt_tokens: int = 0,
        completion_tokens: int = 0,
        total_tokens: int = 0,
    ) -> AIUsageRecord:
        """记录 AI 使用"""
        # 计算成本
        provider_pricing = TOKEN_PRICING.get(provider, {})
        model_pricing = provider_pricing.get(model, Decimal("0.001"))
        estimated_cost = Decimal(total_tokens) / 1000 * model_pricing

        # 创建使用记录
        record = AIUsageRecord(
            user_id=user_id,
            provider=provider,
            model=model,
            operation=operation,
            prompt_tokens=prompt_tokens,
            completion_tokens=completion_tokens,
            total_tokens=total_tokens,
            estimated_cost=estimated_cost,
        )
        db.add(record)
        await db.commit()
        await db.refresh(record)

        # 更新 Redis 计数器
        redis_client = await self.get_redis()
        now = datetime.now(timezone.utc)

        # 每日计数器
        daily_key = f"ai_usage:daily:{user_id}:{now.strftime('%Y%m%d')}"
        await redis_client.incr(daily_key)
        await redis_client.expire(daily_key, 86400 * 2)  # 保留2天

        # 每月计数器
        monthly_key = f"ai_usage:monthly:{user_id}:{now.strftime('%Y%m')}"
        await redis_client.incr(monthly_key)
        await redis_client.expire(monthly_key, 86400 * 35)  # 保留35天

        return record

    async def get_user_usage_stats(
        self, db: AsyncSession, user_id: int, days: int = 30
    ) -> Dict[str, Any]:
        """获取用户使用统计"""
        since_date = datetime.now(timezone.utc) - timedelta(days=days)

        # 总体统计
        result = await db.execute(
            select(
                func.count(AIUsageRecord.id).label("total_calls"),
                func.sum(AIUsageRecord.total_tokens).label("total_tokens"),
                func.sum(AIUsageRecord.estimated_cost).label("total_cost"),
            )
            .where(AIUsageRecord.user_id == user_id)
            .where(AIUsageRecord.created_at >= since_date)
        )
        stats = result.one()

        # 按提供商分组
        provider_result = await db.execute(
            select(
                AIUsageRecord.provider,
                func.count(AIUsageRecord.id).label("calls"),
                func.sum(AIUsageRecord.total_tokens).label("tokens"),
                func.sum(AIUsageRecord.estimated_cost).label("cost"),
            )
            .where(AIUsageRecord.user_id == user_id)
            .where(AIUsageRecord.created_at >= since_date)
            .group_by(AIUsageRecord.provider)
        )
        provider_stats = provider_result.all()

        # 按操作类型分组
        operation_result = await db.execute(
            select(
                AIUsageRecord.operation,
                func.count(AIUsageRecord.id).label("calls"),
            )
            .where(AIUsageRecord.user_id == user_id)
            .where(AIUsageRecord.created_at >= since_date)
            .group_by(AIUsageRecord.operation)
        )
        operation_stats = operation_result.all()

        return {
            "period_days": days,
            "total_calls": stats.total_calls or 0,
            "total_tokens": stats.total_tokens or 0,
            "total_cost": float(stats.total_cost or 0),
            "by_provider": [
                {
                    "provider": p.provider,
                    "calls": p.calls,
                    "tokens": p.tokens,
                    "cost": float(p.cost),
                }
                for p in provider_stats
            ],
            "by_operation": [
                {
                    "operation": o.operation,
                    "calls": o.calls,
                }
                for o in operation_stats
            ],
        }

    async def ensure_billing_period(self, db: AsyncSession, user_id: int) -> AIBilling:
        """确保当前计费周期存在"""
        now = datetime.now(timezone.utc)
        current_period = now.strftime("%Y-%m")
        month_start = now.replace(day=1, hour=0, minute=0, second=0, microsecond=0)
        month_end = month_start + timedelta(days=32)
        month_end = month_end.replace(day=1) - timedelta(seconds=1)

        # 查找或创建计费记录
        result = await db.execute(
            select(AIBilling)
            .where(AIBilling.user_id == user_id)
            .where(AIBilling.billing_period == current_period)
        )
        billing = result.scalar_one_or_none()

        if not billing:
            # 统计本月使用情况
            stats_result = await db.execute(
                select(
                    func.count(AIUsageRecord.id).label("calls"),
                    func.sum(AIUsageRecord.total_tokens).label("tokens"),
                    func.sum(AIUsageRecord.estimated_cost).label("cost"),
                )
                .where(AIUsageRecord.user_id == user_id)
                .where(AIUsageRecord.created_at >= month_start)
                .where(AIUsageRecord.created_at <= month_end)
            )
            stats = stats_result.one()

            billing = AIBilling(
                user_id=user_id,
                billing_period=current_period,
                period_start=month_start,
                period_end=month_end,
                total_calls=stats.calls or 0,
                total_tokens=stats.tokens or 0,
                total_cost=stats.cost or Decimal("0"),
            )
            db.add(billing)
            await db.commit()
            await db.refresh(billing)

        return billing


# 全局单例
_ai_usage_service: Optional[AIUsageService] = None


def get_ai_usage_service() -> AIUsageService:
    """获取 AI 使用服务单例"""
    global _ai_usage_service
    if _ai_usage_service is None:
        _ai_usage_service = AIUsageService()
    return _ai_usage_service
