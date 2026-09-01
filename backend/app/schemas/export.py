"""
导出任务相关 Schema
"""

from pydantic import BaseModel, Field
from typing import Optional, Dict, Any, List
from datetime import datetime
from enum import Enum


class ExportFormat(str, Enum):
    """导出格式"""

    PDF = "pdf"
    DOCX = "docx"
    HTML = "html"


class ExportStatus(str, Enum):
    """导出状态"""

    PENDING = "pending"
    PROCESSING = "processing"
    COMPLETED = "completed"
    FAILED = "failed"


class ExportTaskCreate(BaseModel):
    """创建导出任务请求"""

    resume_ids: List[int] = Field(..., description="要导出的简历ID列表")
    export_format: ExportFormat = Field(..., description="导出格式")
    options: Optional[Dict[str, Any]] = Field(default_factory=dict, description="导出选项")


class ExportTaskResponse(BaseModel):
    """导出任务响应"""

    id: int
    user_id: int
    resume_ids: List[int]
    export_format: ExportFormat
    status: ExportStatus
    file_path: Optional[str] = None
    file_size: Optional[int] = None
    error_message: Optional[str] = None
    progress: float = 0.0
    options: Dict[str, Any]
    created_at: datetime
    started_at: Optional[datetime] = None
    completed_at: Optional[datetime] = None

    class Config:
        from_attributes = True


class ExportTaskListResponse(BaseModel):
    """导出任务列表响应"""

    total: int
    items: List[ExportTaskResponse]


class ExportDownloadResponse(BaseModel):
    """导出下载响应"""

    file_url: str
    file_name: str
    file_size: Optional[int] = None
