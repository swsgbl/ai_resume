"""
AI 使用限制和计费模型
"""

from datetime import datetime, timezone
from sqlalchemy import Column, Integer, String, DateTime, Numeric, ForeignKey, Index
from sqlalchemy.orm import relationship
from app.core.database import Base


class AIUsageLimit(Base):
    """AI 使用限制配置"""

    __tablename__ = "ai_usage_limits"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(
        Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False, unique=True, index=True
    )

    # 限制配置
    daily_limit = Column(Integer, default=10, nullable=False)  # 每日限制
    monthly_limit = Column(Integer, default=200, nullable=False)  # 每月限制
    vip_daily_limit = Column(Integer, default=100, nullable=False)  # VIP每日限制
    vip_monthly_limit = Column(Integer, default=2000, nullable=False)  # VIP每月限制

    # 用户等级
    tier = Column(String(20), default="free", nullable=False)  # free, basic, pro, enterprise

    # 重置追踪
    last_daily_reset = Column(DateTime, default=lambda: datetime.now(timezone.utc))
    last_monthly_reset = Column(DateTime, default=lambda: datetime.now(timezone.utc))

    created_at = Column(DateTime, default=lambda: datetime.now(timezone.utc))
    updated_at = Column(
        DateTime,
        default=lambda: datetime.now(timezone.utc),
        onupdate=lambda: datetime.now(timezone.utc),
    )

    # 关系
    user = relationship("User", back_populates="ai_usage_limit")


class AIUsageRecord(Base):
    """AI 使用记录 - 每次调用的详细记录"""

    __tablename__ = "ai_usage_records"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(
        Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True
    )

    # 调用信息
    provider = Column(String(50), nullable=False)  # openai, deepseek, xiaomi
    model = Column(String(100), nullable=False)  # gpt-4, deepseek-chat, etc.
    operation = Column(String(50), nullable=False)  # generate, optimize, analyze, etc.

    # Token 消耗
    prompt_tokens = Column(Integer, default=0)
    completion_tokens = Column(Integer, default=0)
    total_tokens = Column(Integer, default=0)

    # 成本估算 (USD)
    estimated_cost = Column(Numeric(precision=10, scale=6, asdecimal=False), default=0)

    # 时间戳
    created_at = Column(DateTime, default=lambda: datetime.now(timezone.utc), index=True)

    # 关系
    user = relationship("User", back_populates="ai_usage_records")

    # 索引
    __table_args__ = (
        Index("ix_ai_usage_records_user_created", "user_id", "created_at"),
        Index("ix_ai_usage_records_provider", "provider"),
    )


class AIBilling(Base):
    """AI 计费记录 - 用户账单"""

    __tablename__ = "ai_billings"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(
        Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True
    )

    # 计费周期
    billing_period = Column(String(7), nullable=False, index=True)  # YYYY-MM
    period_start = Column(DateTime, nullable=False)
    period_end = Column(DateTime, nullable=False)

    # 使用统计
    total_calls = Column(Integer, default=0)
    total_tokens = Column(Integer, default=0)
    total_cost = Column(Numeric(precision=10, scale=4, asdecimal=False), default=0)

    # 余额
    balance = Column(Numeric(precision=10, scale=4, asdecimal=False), default=0)
    credit_used = Column(Numeric(precision=10, scale=4, asdecimal=False), default=0)

    # 状态
    status = Column(String(20), default="pending", nullable=False)  # pending, paid, overdue

    # 时间戳
    created_at = Column(DateTime, default=lambda: datetime.now(timezone.utc))
    updated_at = Column(
        DateTime,
        default=lambda: datetime.now(timezone.utc),
        onupdate=lambda: datetime.now(timezone.utc),
    )

    # 关系
    user = relationship("User", back_populates="ai_billings")
