"""
高级功能路由 - JD匹配分析、隐私脱敏、面试问题预测
"""

import re
import logging
from typing import List, Optional
from fastapi import APIRouter, Depends, HTTPException, status, UploadFile, File
from pydantic import BaseModel, Field
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from app.core.database import get_db
from app.core.security import get_current_user
from app.models.user import User
from app.models.resume import Resume
from app.schemas.common import Response
from app.services.ai.openai_client import OpenAIService

logger = logging.getLogger(__name__)
router = APIRouter(prefix="/advanced", tags=["高级功能"])
ai_service = OpenAIService()


# ============ 请求/响应模型 ============


class JDMatchRequest(BaseModel):
    """JD匹配请求"""

    resume_id: int = Field(..., description="简历ID")
    job_description: str = Field(..., min_length=50, description="职位描述")


class JDMatchResult(BaseModel):
    """JD匹配结果"""

    match_score: float = Field(..., description="匹配分数(0-100)")
    matched_keywords: List[str] = Field(default_factory=list, description="匹配的关键词")
    missing_keywords: List[str] = Field(default_factory=list, description="缺失的关键词")
    suggestions: List[str] = Field(default_factory=list, description="改进建议")
    strengths: List[str] = Field(default_factory=list, description="简历优势")
    weaknesses: List[str] = Field(default_factory=list, description="待改进项")


class PrivacyMaskRequest(BaseModel):
    """隐私脱敏请求"""

    content: str = Field(..., description="需要脱敏的内容")
    mask_types: List[str] = Field(
        default=["phone", "email", "id_card", "bank_card", "address"], description="脱敏类型"
    )


class PrivacyMaskResult(BaseModel):
    """隐私脱敏结果"""

    original: str = Field(..., description="原始内容")
    masked: str = Field(..., description="脱敏后内容")
    masked_items: List[dict] = Field(default_factory=list, description="被脱敏的项目")


class InterviewQuestion(BaseModel):
    """面试问题"""

    question: str = Field(..., description="问题")
    category: str = Field(..., description="分类")
    difficulty: str = Field(..., description="难度")
    suggested_answer: Optional[str] = Field(None, description="建议回答思路")


class InterviewPredictRequest(BaseModel):
    """面试问题预测请求"""

    resume_id: int = Field(..., description="简历ID")
    target_position: str = Field(..., description="目标职位")
    company_type: Optional[str] = Field(None, description="公司类型(互联网/金融/制造等)")


class ResumeParseResult(BaseModel):
    """简历解析结果"""

    basic_info: dict = Field(default_factory=dict, description="基本信息")
    education: List[dict] = Field(default_factory=list, description="教育经历")
    work_experience: List[dict] = Field(default_factory=list, description="工作经历")
    projects: List[dict] = Field(default_factory=list, description="项目经历")
    skills: List[str] = Field(default_factory=list, description="技能")
    raw_text: str = Field(..., description="原始文本")


# ============ JD匹配分析 ============


@router.post("/jd-match", response_model=Response[JDMatchResult])
async def analyze_jd_match(
    request: JDMatchRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """
    JD匹配分析 - 分析简历与职位描述的匹配度

    功能：
    - 提取JD关键词并与简历匹配
    - 计算综合匹配分数
    - 给出改进建议
    """
    # 获取简历
    result = await db.execute(
        select(Resume).where(Resume.id == request.resume_id, Resume.user_id == current_user.id)
    )
    resume = result.scalar_one_or_none()

    if not resume:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="简历不存在")

    # 提取JD关键词
    jd_keywords = _extract_keywords(request.job_description)

    # 获取简历文本
    resume_text = _resume_to_text(resume.content)
    resume_keywords = _extract_keywords(resume_text)

    # 计算匹配
    matched = set(jd_keywords) & set(resume_keywords)
    missing = set(jd_keywords) - set(resume_keywords)

    # 计算匹配分数
    if len(jd_keywords) > 0:
        match_score = (len(matched) / len(jd_keywords)) * 100
    else:
        match_score = 0

    # 生成建议
    suggestions = []
    if missing:
        suggestions.append(f"建议在简历中添加以下关键词: {', '.join(list(missing)[:5])}")
    if match_score < 60:
        suggestions.append("匹配度较低，建议重新审视目标岗位的核心要求")
    if match_score >= 80:
        suggestions.append("匹配度较高，可以考虑投递该职位")

    # 使用AI进行深度分析
    try:
        ai_analysis = await ai_service.analyze_jd_match(
            resume_content=resume.content, job_description=request.job_description
        )
        if ai_analysis.get("suggestions"):
            suggestions.extend(ai_analysis["suggestions"])
    except Exception:
        pass  # AI分析失败时使用基础分析

    return Response(
        data=JDMatchResult(
            match_score=round(match_score, 1),
            matched_keywords=list(matched)[:20],
            missing_keywords=list(missing)[:10],
            suggestions=suggestions[:5],
            strengths=["关键词匹配度高"] if match_score >= 70 else [],
            weaknesses=["部分核心技能未体现"] if match_score < 60 else [],
        ),
        message="分析完成",
    )


# ============ 隐私脱敏 ============


@router.post("/privacy-mask", response_model=Response[PrivacyMaskResult])
async def mask_privacy(request: PrivacyMaskRequest, current_user: User = Depends(get_current_user)):
    """
    一键隐私脱敏 - 自动识别并隐藏敏感信息

    支持的脱敏类型：
    - phone: 手机号
    - email: 邮箱
    - id_card: 身份证号
    - bank_card: 银行卡号
    - address: 详细地址
    """
    masked_content = request.content
    masked_items = []

    # 手机号脱敏
    if "phone" in request.mask_types:
        phone_pattern = r"1[3-9]\d{9}"
        phones = re.findall(phone_pattern, masked_content)
        for phone in phones:
            masked_phone = phone[:3] + "****" + phone[7:]
            masked_content = masked_content.replace(phone, masked_phone)
            masked_items.append({"type": "phone", "original": phone, "masked": masked_phone})

    # 邮箱脱敏。逐个检查分隔出的 token，避免嵌套量词正则造成回溯放大。
    if "email" in request.mask_types:
        emails = []
        for token in masked_content.split():
            local_part, separator, domain = token.partition("@")
            if separator and local_part and "." in domain and not domain.startswith("."):
                emails.append(token)
        for email in emails:
            parts = email.split("@")
            if len(parts[0]) > 2:
                masked_email = parts[0][:2] + "***@" + parts[1]
            else:
                masked_email = "***@" + parts[1]
            masked_content = masked_content.replace(email, masked_email)
            masked_items.append({"type": "email", "original": email, "masked": masked_email})

    # 身份证号脱敏
    if "id_card" in request.mask_types:
        id_pattern = r"\d{17}[\dXx]|\d{15}"
        ids = re.findall(id_pattern, masked_content)
        for id_card in ids:
            if len(id_card) == 18:
                masked_id = id_card[:6] + "********" + id_card[14:]
            else:
                masked_id = id_card[:6] + "******" + id_card[12:]
            masked_content = masked_content.replace(id_card, masked_id)
            masked_items.append({"type": "id_card", "original": id_card, "masked": masked_id})

    # 银行卡号脱敏
    if "bank_card" in request.mask_types:
        bank_pattern = r"\d{16,19}"
        cards = re.findall(bank_pattern, masked_content)
        for card in cards:
            if len(card) >= 16:
                masked_card = card[:4] + " **** **** " + card[-4:]
                masked_content = masked_content.replace(card, masked_card)
                masked_items.append({"type": "bank_card", "original": card, "masked": masked_card})

    # 地址脱敏（简单处理）
    if "address" in request.mask_types:
        # 匹配门牌号
        addr_pattern = r"(\d{1,6}(?:号楼|栋)(?:\d{1,5}单元?)?(?:\d{1,5}[室户])?)"
        addresses = re.findall(addr_pattern, masked_content)
        for addr in addresses:
            masked_addr = "***"
            masked_content = masked_content.replace(addr, masked_addr)
            masked_items.append({"type": "address", "original": addr, "masked": masked_addr})

    return Response(
        data=PrivacyMaskResult(
            original=request.content, masked=masked_content, masked_items=masked_items
        ),
        message=f"已脱敏 {len(masked_items)} 项敏感信息",
    )


# ============ 面试问题预测 ============


@router.post("/interview-predict", response_model=Response[List[InterviewQuestion]])
async def predict_interview_questions(
    request: InterviewPredictRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """
    面试问题预测 - 基于简历生成可能的面试问题

    功能：
    - 分析简历内容生成相关问题
    - 根据目标职位定制问题
    - 提供回答建议
    """
    # 获取简历
    result = await db.execute(
        select(Resume).where(Resume.id == request.resume_id, Resume.user_id == current_user.id)
    )
    resume = result.scalar_one_or_none()

    if not resume:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="简历不存在")

    try:
        # 生成面试问题
        questions = await ai_service.predict_interview_questions(
            resume_content=resume.content,
            target_position=request.target_position,
            company_type=request.company_type,
        )

        # 转换为响应格式
        interview_questions = [
            InterviewQuestion(
                question=q.get("question", ""),
                category=q.get("category", "综合"),
                difficulty=q.get("difficulty", "中等"),
                suggested_answer=q.get("suggested_answer"),
            )
            for q in questions
        ]

        return Response(
            data=interview_questions, message=f"生成了 {len(interview_questions)} 个预测问题"
        )
    except Exception as e:
        logger.error(f"面试问题预测失败: {e}")
        # 返回默认问题而不是抛出异常
        default_questions = [
            InterviewQuestion(
                question="请简单介绍一下你自己",
                category="自我介绍",
                difficulty="简单",
                suggested_answer="简要说明您的教育背景、工作经验和核心技能",
            ),
            InterviewQuestion(
                question=f"您为什么申请{request.target_position}这个职位？",
                category="动机",
                difficulty="简单",
                suggested_answer="结合您的职业规划和岗位匹配度来回答",
            ),
        ]
        return Response(data=default_questions, message="AI 服务暂时不可用，返回默认面试问题")


# ============ 简历解析（导入） ============


@router.post("/parse-resume", response_model=Response[ResumeParseResult])
async def parse_resume_file(
    file: UploadFile = File(..., description="简历文件(PDF/Word)"),
    current_user: User = Depends(get_current_user),
):
    """
    简历解析 - 上传现有简历自动提取信息

    支持格式：
    - PDF (.pdf)
    - Word (.doc, .docx)
    """
    # 验证文件类型
    allowed_types = [
        "application/pdf",
        "application/msword",
        "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
    ]

    if file.content_type not in allowed_types:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST, detail="不支持的文件格式，请上传PDF或Word文档"
        )

    # 读取文件内容
    content = await file.read()

    # 根据类型解析
    try:
        if file.content_type == "application/pdf":
            text = await _parse_pdf(content)
        else:
            text = await _parse_word(content)
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail=f"文件解析失败: {str(e)}"
        )

    # 使用AI提取结构化信息
    parsed_data = await ai_service.parse_resume_text(text)

    return Response(
        data=ResumeParseResult(
            basic_info=parsed_data.get("basic_info", {}),
            education=parsed_data.get("education", []),
            work_experience=parsed_data.get("work_experience", []),
            projects=parsed_data.get("projects", []),
            skills=parsed_data.get("skills", []),
            raw_text=text[:2000],  # 限制返回长度
        ),
        message="简历解析成功",
    )


# ============ 辅助函数 ============


def _extract_keywords(text: str) -> List[str]:
    """提取关键词"""
    # 常见技能和关键词列表
    tech_keywords = [
        "python",
        "java",
        "javascript",
        "typescript",
        "go",
        "rust",
        "c++",
        "c#",
        "react",
        "vue",
        "angular",
        "node.js",
        "django",
        "flask",
        "spring",
        "mysql",
        "postgresql",
        "mongodb",
        "redis",
        "elasticsearch",
        "docker",
        "kubernetes",
        "aws",
        "azure",
        "gcp",
        "机器学习",
        "深度学习",
        "人工智能",
        "数据分析",
        "大数据",
        "项目管理",
        "团队管理",
        "敏捷开发",
        "scrum",
        "产品设计",
        "用户体验",
        "ui设计",
        "交互设计",
        "市场营销",
        "品牌运营",
        "内容运营",
        "用户增长",
        "财务分析",
        "风险管理",
        "投资",
        "审计",
    ]

    text_lower = text.lower()
    found_keywords = []

    for keyword in tech_keywords:
        if keyword in text_lower:
            found_keywords.append(keyword)

    return found_keywords


def _resume_to_text(content: dict) -> str:
    """将简历内容转换为文本"""
    text_parts = []

    # 基本信息
    if basic := content.get("basic_info"):
        text_parts.append(f"{basic.get('name', '')} {basic.get('title', '')}")
        text_parts.append(basic.get("summary", ""))

    # 工作经历
    for exp in content.get("work_experience", []):
        text_parts.append(f"{exp.get('company', '')} {exp.get('position', '')}")
        text_parts.append(exp.get("description", ""))
        text_parts.extend(exp.get("highlights", []))

    # 项目经历
    for proj in content.get("projects", []):
        text_parts.append(f"{proj.get('name', '')} {proj.get('role', '')}")
        text_parts.append(proj.get("description", ""))
        text_parts.extend(proj.get("technologies", []))

    # 技能
    for skill in content.get("skills", []):
        text_parts.append(skill.get("name", ""))
        text_parts.extend(skill.get("keywords", []) or [])

    return " ".join(filter(None, text_parts))


async def _parse_pdf(content: bytes) -> str:
    """解析PDF文件"""
    try:
        import io
        from PyPDF2 import PdfReader

        reader = PdfReader(io.BytesIO(content))
        text = ""
        for page in reader.pages:
            text += page.extract_text() or ""
        return text
    except ImportError:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail="PDF解析库未安装"
        )


async def _parse_word(content: bytes) -> str:
    """解析Word文件"""
    try:
        import io
        from docx import Document

        doc = Document(io.BytesIO(content))
        text = "\n".join([para.text for para in doc.paragraphs])
        return text
    except ImportError:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail="Word解析库未安装"
        )
