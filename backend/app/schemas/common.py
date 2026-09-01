"""
通用响应模式
"""

from typing import Optional, Generic, TypeVar, List, Any
from pydantic import BaseModel, Field
from pydantic.generics import GenericModel

T = TypeVar("T")


class ResponseBase(BaseModel):
    """基础响应 - 使用中文 API 惯例 (code=0 表示成功)"""

    code: int = Field(default=0, description="响应状态码: 0=成功, 非0=错误")
    message: str = Field(default="success", description="响应消息")


class Response(ResponseBase, GenericModel, Generic[T]):
    """通用响应 - 与 FastAPI 兼容的泛型实现"""

    data: Optional[T] = Field(default=None, description="响应数据")

    class Config:
        # JSON schema 编码时保留泛型信息
        json_schema_mode_override = "serialization"


class PageResponse(ResponseBase, Generic[T]):
    """分页响应"""

    data: Optional[List[T]] = None
    total: int = 0
    page: int = 1
    page_size: int = 10

    @property
    def total_pages(self) -> int:
        if self.page_size <= 0:
            return 0
        return (self.total + self.page_size - 1) // self.page_size


class ErrorResponse(BaseModel):
    """错误响应"""

    code: int
    message: str
    detail: Optional[Any] = None
