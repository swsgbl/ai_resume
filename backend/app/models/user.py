"""
用户数据模型
"""

from datetime import datetime, timezone
from sqlalchemy import Column, String, Boolean, Enum, DateTime, Integer
from sqlalchemy.orm import relationship
from app.core.database import Base
import enum


class UserRole(str, enum.Enum):
    """用户角色枚举"""

    USER = "user"
    PREMIUM = "premium"
    ENTERPRISE = "enterprise"
    ADMIN = "admin"


class User(Base):
    """用户表"""

    __tablename__ = "users"

    # SQLite的autoincrement需要使用Integer类型
    id = Column(Integer, primary_key=True, autoincrement=True)
    email = Column(String(255), unique=True, nullable=True, index=True)
    phone = Column(String(20), unique=True, nullable=True, index=True)
    password_hash = Column(String(255), nullable=True)

    # 用户信息
    username = Column(String(50), nullable=True)
    avatar_url = Column(String(500), nullable=True)

    # 微信登录相关
    wechat_openid = Column(String(100), unique=True, nullable=True, index=True)
    wechat_unionid = Column(String(100), unique=True, nullable=True, index=True)
    wechat_nickname = Column(String(100), nullable=True)
    wechat_avatar = Column(String(500), nullable=True)

    # Google OAuth 相关
    google_id = Column(String(100), unique=True, nullable=True, index=True)
    google_email = Column(String(255), nullable=True)
    google_verified_email = Column(Boolean, default=False, nullable=True)

    # GitHub OAuth 相关
    github_id = Column(Integer, unique=True, nullable=True, index=True)
    github_login = Column(String(100), nullable=True)
    github_email = Column(String(255), nullable=True)

    # Gitee OAuth 相关
    gitee_id = Column(Integer, unique=True, nullable=True, index=True)
    gitee_login = Column(String(100), nullable=True)
    gitee_email = Column(String(255), nullable=True)

    # Discord OAuth 相关
    discord_id = Column(String(50), unique=True, nullable=True, index=True)
    discord_username = Column(String(100), nullable=True)
    discord_email = Column(String(255), nullable=True)
    discord_avatar = Column(String(500), nullable=True)

    # 角色和状态
    role = Column(Enum(UserRole), default=UserRole.USER, nullable=False)
    is_active = Column(Boolean, default=True, nullable=False)
    is_verified = Column(Boolean, default=False, nullable=False)

    # 时间戳
    created_at = Column(
        DateTime(timezone=True), default=lambda: datetime.now(timezone.utc), nullable=False
    )
    updated_at = Column(
        DateTime(timezone=True),
        default=lambda: datetime.now(timezone.utc),
        onupdate=lambda: datetime.now(timezone.utc),
        nullable=False,
    )
    last_login_at = Column(DateTime(timezone=True), nullable=True)

    # 关系
    resumes = relationship("Resume", back_populates="user", lazy="dynamic")
    favorites = relationship("Favorite", back_populates="user", lazy="dynamic")
    ai_usage_limit = relationship(
        "AIUsageLimit", back_populates="user", uselist=False, cascade="all, delete-orphan"
    )
    ai_usage_records = relationship(
        "AIUsageRecord", back_populates="user", cascade="all, delete-orphan"
    )
    ai_billings = relationship("AIBilling", back_populates="user", cascade="all, delete-orphan")
    export_tasks = relationship("ExportTask", back_populates="user", cascade="all, delete-orphan")

    def __repr__(self):
        return f"<User(id={self.id}, email={self.email})>"
