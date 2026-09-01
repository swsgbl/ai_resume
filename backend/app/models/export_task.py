"""
Export Task Model
"""

from datetime import datetime, timezone
from sqlalchemy import Column, String, Text, Enum, DateTime, JSON, Integer, ForeignKey, Float
from sqlalchemy.orm import relationship
from app.core.database import Base
import enum


class ExportFormat(str, enum.Enum):
    PDF = "pdf"
    DOCX = "docx"
    HTML = "html"


class ExportStatus(str, enum.Enum):
    PENDING = "pending"
    PROCESSING = "processing"
    COMPLETED = "completed"
    FAILED = "failed"


class ExportTask(Base):
    __tablename__ = "export_tasks"
    id = Column(Integer, primary_key=True, autoincrement=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False, index=True)
    resume_ids = Column(JSON, nullable=False)
    export_format = Column(Enum(ExportFormat), nullable=False)
    status = Column(Enum(ExportStatus), default=ExportStatus.PENDING, nullable=False)
    file_path = Column(String(500), nullable=True)
    file_size = Column(Integer, nullable=True)
    error_message = Column(Text, nullable=True)
    progress = Column(Float, default=0.0, nullable=False)
    options = Column(JSON, nullable=True, default=dict)
    created_at = Column(DateTime, default=lambda: datetime.now(timezone.utc), nullable=False)
    started_at = Column(DateTime, nullable=True)
    completed_at = Column(DateTime, nullable=True)
    user = relationship("User", back_populates="export_tasks")

    def __repr__(self):
        return f"<ExportTask(id={self.id}, format={self.export_format}, status={self.status}>"
