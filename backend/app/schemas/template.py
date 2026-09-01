"""
模板相关Schema
"""

from datetime import datetime
from typing import Optional, List, Dict, Any
from pydantic import BaseModel, Field, ConfigDict


class TemplateBase(BaseModel):
    """模板基础Schema"""

    name: str = Field(..., min_length=1, max_length=100, description="模板名称")
    description: Optional[str] = Field(None, max_length=500, description="模板描述")
    category: Optional[str] = Field(None, max_length=50, description="分类")
    industry: Optional[str] = Field(None, max_length=50, description="行业")
    tags: Optional[str] = Field(None, description="标签，逗号分隔")
    is_premium: bool = Field(False, description="是否为付费模板")
    is_active: bool = Field(True, description="是否激活")
    preview_url: Optional[str] = Field(None, description="预览图URL")
    structure: Optional[Dict[str, Any]] = Field(None, description="模板结构")
    style_config: Optional[Dict[str, Any]] = Field(None, description="样式配置")


class TemplateCreate(TemplateBase):
    """创建模板Schema"""


class TemplateUpdate(BaseModel):
    """更新模板Schema"""

    name: Optional[str] = Field(None, min_length=1, max_length=100)
    description: Optional[str] = Field(None, max_length=500)
    category: Optional[str] = Field(None, max_length=50)
    industry: Optional[str] = Field(None, max_length=50)
    tags: Optional[str] = None
    is_premium: Optional[bool] = None
    is_active: Optional[bool] = None
    preview_url: Optional[str] = None
    structure: Optional[Dict[str, Any]] = None
    style_config: Optional[Dict[str, Any]] = None


class TemplateResponse(TemplateBase):
    """模板响应Schema"""

    id: int
    created_at: datetime
    updated_at: datetime

    model_config = ConfigDict(from_attributes=True)


class TemplateListResponse(BaseModel):
    """模板列表响应"""

    items: List[TemplateResponse]
    total: int
    page: int
    page_size: int


class TemplateCategoryResponse(BaseModel):
    """模板分类响应"""

    category: str
    count: int
    templates: List[TemplateResponse]
