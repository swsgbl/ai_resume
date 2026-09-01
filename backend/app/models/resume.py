"""
简历数据模型
"""

from datetime import datetime, timezone
from sqlalchemy import Column, String, Text, Enum, DateTime, ForeignKey, JSON, Integer
from sqlalchemy.orm import relationship
from app.core.database import Base
import enum


class ResumeStatus(str, enum.Enum):
    """简历状态枚举"""

    DRAFT = "draft"
    PUBLISHED = "published"
    ARCHIVED = "archived"


class Resume(Base):
    """简历表"""

    __tablename__ = "resumes"

    id = Column(Integer, primary_key=True, autoincrement=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False, index=True)
    template_id = Column(Integer, ForeignKey("templates.id"), nullable=True)

    # 简历基本信息
    title = Column(String(255), nullable=False, default="我的简历")
    description = Column(Text, nullable=True)

    # 结构化简历内容 (JSON格式)
    content = Column(JSON, nullable=True, default=dict)

    # 样式配置
    style_config = Column(JSON, nullable=True, default=dict)

    # 状态
    status = Column(Enum(ResumeStatus), default=ResumeStatus.DRAFT, nullable=False)

    # 版本号
    version = Column(Integer, default=1, nullable=False)

    # 时间戳
    created_at = Column(DateTime, default=lambda: datetime.now(timezone.utc), nullable=False)
    updated_at = Column(
        DateTime,
        default=lambda: datetime.now(timezone.utc),
        onupdate=lambda: datetime.now(timezone.utc),
        nullable=False,
    )

    # 关系
    user = relationship("User", back_populates="resumes")
    template = relationship("Template", back_populates="resumes")
    versions = relationship("ResumeVersion", back_populates="resume", lazy="dynamic")

    def __repr__(self):
        return f"<Resume(id={self.id}, title={self.title})>"


class ResumeVersion(Base):
    """简历版本历史表"""

    __tablename__ = "resume_versions"

    id = Column(Integer, primary_key=True, autoincrement=True)
    resume_id = Column(Integer, ForeignKey("resumes.id"), nullable=False, index=True)

    # 版本信息
    version_number = Column(Integer, nullable=False)
    content = Column(JSON, nullable=False)
    style_config = Column(JSON, nullable=True)

    # 变更说明
    change_note = Column(String(500), nullable=True)

    # 时间戳
    created_at = Column(DateTime, default=lambda: datetime.now(timezone.utc), nullable=False)

    # 关系
    resume = relationship("Resume", back_populates="versions")

    def __repr__(self):
        return f"<ResumeVersion(resume_id={self.resume_id}, version={self.version_number})>"
