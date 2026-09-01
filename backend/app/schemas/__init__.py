"""
Pydantic 模式汇总
"""

from app.schemas.user import (
    UserCreate,
    UserLogin,
    UserUpdate,
    UserResponse,
    TokenResponse,
    TokenRefresh,
    PasswordChange,
)
from app.schemas.resume import (
    ResumeContent,
    BasicInfo,
    Education,
    WorkExperience,
    Project,
    Skill,
    Certification,
    CustomSection,
    StyleConfig,
    ResumeCreate,
    ResumeUpdate,
    ResumeResponse,
    ResumeListResponse,
    ResumeVersionResponse,
    AIGenerateRequest,
    AIOptimizeRequest,
    AIOptimizeResponse,
)
from app.schemas.export import (
    ExportTaskCreate,
    ExportTaskResponse,
    ExportTaskListResponse,
    ExportDownloadResponse,
    ExportFormat,
    ExportStatus,
)
from app.schemas.common import Response, PageResponse, ErrorResponse

__all__ = [
    # User
    "UserCreate",
    "UserLogin",
    "UserUpdate",
    "UserResponse",
    "TokenResponse",
    "TokenRefresh",
    "PasswordChange",
    # Resume
    "ResumeContent",
    "BasicInfo",
    "Education",
    "WorkExperience",
    "Project",
    "Skill",
    "Certification",
    "CustomSection",
    "StyleConfig",
    "ResumeCreate",
    "ResumeUpdate",
    "ResumeResponse",
    "ResumeListResponse",
    "ResumeVersionResponse",
    "AIGenerateRequest",
    "AIOptimizeRequest",
    "AIOptimizeResponse",
    # Export
    "ExportTaskCreate",
    "ExportTaskResponse",
    "ExportTaskListResponse",
    "ExportDownloadResponse",
    "ExportFormat",
    "ExportStatus",
    # Common
    "Response",
    "PageResponse",
    "ErrorResponse",
]
