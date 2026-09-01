"""
简历相关的 Pydantic 模式
"""

from datetime import datetime, date
from typing import Optional, List, Dict, Any
from pydantic import BaseModel, Field, ConfigDict

# ============ 简历内容子模块 ============


class BasicInfo(BaseModel):
    """基本信息"""

    name: str = Field(..., description="姓名")
    gender: Optional[str] = Field(None, description="性别")
    birth_date: Optional[date] = Field(None, description="出生日期")
    phone: Optional[str] = Field(None, description="手机号")
    email: Optional[str] = Field(None, description="邮箱")
    location: Optional[str] = Field(None, description="所在城市")
    avatar_url: Optional[str] = Field(None, description="头像URL")
    job_intention: Optional[str] = Field(None, description="求职意向")
    expected_salary: Optional[str] = Field(None, description="期望薪资")
    self_introduction: Optional[str] = Field(None, description="个人简介")


class Education(BaseModel):
    """教育经历"""

    school: str = Field(..., description="学校名称")
    major: Optional[str] = Field(None, description="专业")
    degree: Optional[str] = Field(None, description="学历")
    start_date: Optional[date] = Field(None, description="开始时间")
    end_date: Optional[date] = Field(None, description="结束时间")
    gpa: Optional[str] = Field(None, description="GPA")
    description: Optional[str] = Field(None, description="描述")


class WorkExperience(BaseModel):
    """工作经历"""

    company: str = Field(..., description="公司名称")
    position: str = Field(..., description="职位")
    department: Optional[str] = Field(None, description="部门")
    start_date: Optional[date] = Field(None, description="开始时间")
    end_date: Optional[date] = Field(None, description="结束时间")
    is_current: bool = Field(False, description="是否在职")
    description: Optional[str] = Field(None, description="工作描述")
    achievements: Optional[List[str]] = Field(None, description="工作成就")


class Project(BaseModel):
    """项目经历"""

    name: str = Field(..., description="项目名称")
    role: Optional[str] = Field(None, description="担任角色")
    start_date: Optional[date] = Field(None, description="开始时间")
    end_date: Optional[date] = Field(None, description="结束时间")
    description: Optional[str] = Field(None, description="项目描述")
    tech_stack: Optional[List[str]] = Field(None, description="技术栈")
    achievements: Optional[List[str]] = Field(None, description="项目成果")
    link: Optional[str] = Field(None, description="项目链接")


class Skill(BaseModel):
    """技能"""

    name: str = Field(..., description="技能名称")
    level: Optional[str] = Field(None, description="掌握程度")
    category: Optional[str] = Field(None, description="技能分类")


class Certification(BaseModel):
    """证书"""

    name: str = Field(..., description="证书名称")
    issuer: Optional[str] = Field(None, description="颁发机构")
    issue_date: Optional[date] = Field(None, description="获得时间")
    expiry_date: Optional[date] = Field(None, description="有效期")
    credential_id: Optional[str] = Field(None, description="证书编号")


class CustomSection(BaseModel):
    """自定义模块"""

    title: str = Field(..., description="模块标题")
    content: str = Field(..., description="模块内容")
    order: int = Field(0, description="排序")


# ============ 完整简历内容 ============


class ResumeContent(BaseModel):
    """简历结构化内容"""

    basic_info: Optional[BasicInfo] = None
    education: Optional[List[Education]] = Field(default_factory=list)
    work_experience: Optional[List[WorkExperience]] = Field(default_factory=list)
    projects: Optional[List[Project]] = Field(default_factory=list)
    skills: Optional[List[Skill]] = Field(default_factory=list)
    certifications: Optional[List[Certification]] = Field(default_factory=list)
    custom_sections: Optional[List[CustomSection]] = Field(default_factory=list)


class StyleConfig(BaseModel):
    """样式配置"""

    theme: str = Field("default", description="主题")
    primary_color: str = Field("#2B2B2B", description="主色调")
    secondary_color: str = Field("#666666", description="辅助色")
    font_family: str = Field("Microsoft YaHei", description="字体")
    font_size: int = Field(12, description="字号")
    line_height: float = Field(1.5, description="行高")
    margin: Dict[str, int] = Field(
        default_factory=lambda: {"top": 20, "right": 20, "bottom": 20, "left": 20}
    )
    layout: str = Field("single", description="布局: single/double")


# ============ API 请求/响应模式 ============


class ResumeCreate(BaseModel):
    """创建简历请求"""

    title: str = Field(..., min_length=1, max_length=255, description="简历标题")
    description: Optional[str] = None
    template_id: Optional[int] = None
    content: Optional[ResumeContent] = None
    style_config: Optional[StyleConfig] = None


class ResumeUpdate(BaseModel):
    """更新简历请求"""

    title: Optional[str] = Field(None, max_length=255)
    description: Optional[str] = None
    template_id: Optional[int] = None
    content: Optional[ResumeContent] = None
    style_config: Optional[StyleConfig] = None
    status: Optional[str] = None


class ResumeResponse(BaseModel):
    """简历响应"""

    id: int
    user_id: int
    title: str
    description: Optional[str] = None
    template_id: Optional[int] = None
    content: Optional[Dict[str, Any]] = None
    style_config: Optional[Dict[str, Any]] = None
    status: str
    version: int
    created_at: datetime
    updated_at: datetime

    model_config = ConfigDict(from_attributes=True)


class ResumeListResponse(BaseModel):
    """简历列表响应"""

    items: List[ResumeResponse]
    total: int
    page: int
    page_size: int


class ResumeVersionResponse(BaseModel):
    """简历版本响应"""

    id: int
    resume_id: int
    version_number: int
    content: Dict[str, Any]
    style_config: Optional[Dict[str, Any]] = None
    change_note: Optional[str] = None
    created_at: datetime

    model_config = ConfigDict(from_attributes=True)


# ============ AI 生成相关 ============


class AIGenerateRequest(BaseModel):
    """AI生成简历请求"""

    target_position: str = Field(..., description="目标岗位")
    user_background: Optional[str] = Field(None, description="用户背景描述")
    style: str = Field("professional", description="风格: professional/creative/academic")
    language: str = Field("zh", description="语言: zh/en")


class AIOptimizeRequest(BaseModel):
    """AI优化内容请求"""

    content: str = Field(..., description="需要优化的内容")
    optimization_type: str = Field(
        "star_method", description="优化类型: star_method/quantify/keywords/polish"
    )
    context: Optional[str] = Field(None, description="上下文信息")


class AIOptimizeResponse(BaseModel):
    """AI优化响应"""

    original: str
    optimized: str
    suggestions: Optional[List[str]] = None
