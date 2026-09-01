"""
模板数据模型
"""

from datetime import datetime, timezone
from sqlalchemy import (
    Column,
    BigInteger,
    String,
    Text,
    Boolean,
    DateTime,
    JSON,
    Integer,
    ForeignKey,
)
from sqlalchemy.orm import relationship
from app.core.database import Base


class Template(Base):
    """模板表"""

    __tablename__ = "templates"

    id = Column(Integer, primary_key=True, autoincrement=True)

    # 模板基本信息
    name = Column(String(255), nullable=False)
    description = Column(Text, nullable=True)

    # 分类信息
    category = Column(String(50), nullable=True, index=True)  # 行业分类
    sub_category = Column(String(50), nullable=True)  # 岗位分类
    level = Column(String(20), nullable=True)  # 职级: entry/mid/senior

    # 样式配置
    style = Column(JSON, nullable=True, default=dict)
    layout = Column(String(20), default="single")  # single/double

    # 预览
    preview_url = Column(String(500), nullable=True)
    thumbnail_url = Column(String(500), nullable=True)

    # HTML模板内容
    html_content = Column(Text, nullable=True)
    css_content = Column(Text, nullable=True)

    # 权限和状态
    is_premium = Column(Boolean, default=False, nullable=False)
    is_active = Column(Boolean, default=True, nullable=False)

    # 统计
    use_count = Column(Integer, default=0, nullable=False)

    # 时间戳
    created_at = Column(DateTime, default=lambda: datetime.now(timezone.utc), nullable=False)
    updated_at = Column(
        DateTime,
        default=lambda: datetime.now(timezone.utc),
        onupdate=lambda: datetime.now(timezone.utc),
        nullable=False,
    )

    # 关系
    resumes = relationship("Resume", back_populates="template", lazy="dynamic")

    def __repr__(self):
        return f"<Template(id={self.id}, name={self.name})>"


class Favorite(Base):
    """收藏表"""

    __tablename__ = "favorites"

    id = Column(Integer, primary_key=True, autoincrement=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False, index=True)

    # 收藏类型和目标
    target_type = Column(String(20), nullable=False)  # template/resume
    target_id = Column(BigInteger, nullable=False)

    # 时间戳
    created_at = Column(DateTime, default=lambda: datetime.now(timezone.utc), nullable=False)

    # 关系
    user = relationship("User", back_populates="favorites")

    def __repr__(self):
        return f"<Favorite(user_id={self.user_id}, target_type={self.target_type})>"


class OperationLog(Base):
    """操作日志表"""

    __tablename__ = "operation_logs"

    id = Column(Integer, primary_key=True, autoincrement=True)
    user_id = Column(Integer, nullable=True, index=True)

    # 操作信息
    action = Column(String(50), nullable=False)  # create/update/delete/export/login
    resource_type = Column(String(50), nullable=True)  # resume/template/user
    resource_id = Column(BigInteger, nullable=True)

    # 详情
    details = Column(JSON, nullable=True)
    ip_address = Column(String(50), nullable=True)
    user_agent = Column(String(500), nullable=True)

    # 时间戳
    created_at = Column(DateTime, default=lambda: datetime.now(timezone.utc), nullable=False)

    def __repr__(self):
        return f"<OperationLog(id={self.id}, action={self.action})>"
