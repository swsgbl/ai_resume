"""
导出路由
"""

from fastapi import APIRouter, Depends, HTTPException, status, Request
from fastapi.responses import StreamingResponse
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
import io
from urllib.parse import quote
from app.core.database import get_db
from app.core.security import get_current_user
from app.core.rate_limit import limiter, RateLimit
from app.models.user import User
from app.models.resume import Resume
from app.models.template import Template
from app.services.export.export_service import ExportService
from app.schemas.common import Response

router = APIRouter(prefix="/export", tags=["导出"])
export_service = ExportService()


@router.get("/{resume_id}/pdf")
@limiter.limit(RateLimit.RESUME_EXPORT)
async def export_to_pdf(
    request: Request,
    resume_id: int,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """导出简历为PDF"""
    # 获取简历
    result = await db.execute(
        select(Resume).where(Resume.id == resume_id, Resume.user_id == current_user.id)
    )
    resume = result.scalar_one_or_none()

    if not resume:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="简历不存在")

    # 获取模板HTML（如果有）
    template_html = None
    if resume.template_id:
        result = await db.execute(select(Template).where(Template.id == resume.template_id))
        template = result.scalar_one_or_none()
        if template and template.html_content:
            template_html = template.html_content

    try:
        pdf_bytes = await export_service.to_pdf(
            resume_content=resume.content or {},
            style_config=resume.style_config,
            template_html=template_html,
        )

        filename = f"{resume.title}.pdf"
        encoded_filename = quote(filename.encode("utf-8"))
        return StreamingResponse(
            io.BytesIO(pdf_bytes),
            media_type="application/pdf",
            headers={"Content-Disposition": f"attachment; filename*=UTF-8''{encoded_filename}"},
        )
    except Exception as e:
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail=str(e))


@router.get("/{resume_id}/word")
@limiter.limit(RateLimit.RESUME_EXPORT)
async def export_to_word(
    request: Request,
    resume_id: int,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """导出简历为Word文档"""
    # 获取简历
    result = await db.execute(
        select(Resume).where(Resume.id == resume_id, Resume.user_id == current_user.id)
    )
    resume = result.scalar_one_or_none()

    if not resume:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="简历不存在")

    word_bytes = await export_service.to_word(
        resume_content=resume.content or {}, style_config=resume.style_config
    )

    filename = f"{resume.title}.docx"
    encoded_filename = quote(filename.encode("utf-8"))
    return StreamingResponse(
        io.BytesIO(word_bytes),
        media_type="application/vnd.openxmlformats-officedocument.wordprocessingml.document",
        headers={"Content-Disposition": f"attachment; filename*=UTF-8''{encoded_filename}"},
    )


@router.get("/{resume_id}/html")
async def export_to_html(
    resume_id: int,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """导出简历为HTML"""
    # 获取简历
    result = await db.execute(
        select(Resume).where(Resume.id == resume_id, Resume.user_id == current_user.id)
    )
    resume = result.scalar_one_or_none()

    if not resume:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="简历不存在")

    # 获取模板HTML（如果有）
    template_html = None
    if resume.template_id:
        result = await db.execute(select(Template).where(Template.id == resume.template_id))
        template = result.scalar_one_or_none()
        if template and template.html_content:
            template_html = template.html_content

    html_content = await export_service.to_html(
        resume_content=resume.content or {},
        style_config=resume.style_config,
        template_html=template_html,
    )

    filename = f"{resume.title}.html"
    encoded_filename = quote(filename.encode("utf-8"))
    return StreamingResponse(
        io.BytesIO(html_content.encode("utf-8")),
        media_type="text/html; charset=utf-8",
        headers={"Content-Disposition": f"attachment; filename*=UTF-8''{encoded_filename}"},
    )


@router.get("/{resume_id}/preview")
async def preview_resume(
    resume_id: int,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """预览简历HTML"""
    # 获取简历
    result = await db.execute(
        select(Resume).where(Resume.id == resume_id, Resume.user_id == current_user.id)
    )
    resume = result.scalar_one_or_none()

    if not resume:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="简历不存在")

    # 获取模板HTML（如果有）
    template_html = None
    if resume.template_id:
        result = await db.execute(select(Template).where(Template.id == resume.template_id))
        template = result.scalar_one_or_none()
        if template and template.html_content:
            template_html = template.html_content

    html_content = await export_service.to_html(
        resume_content=resume.content or {},
        style_config=resume.style_config,
        template_html=template_html,
    )

    return StreamingResponse(
        io.BytesIO(html_content.encode("utf-8")), media_type="text/html; charset=utf-8"
    )


@router.get("/styles")
async def get_export_styles():
    """获取可用的导出样式"""
    styles = export_service.get_available_styles()

    # 样式描述映射
    style_descriptions = {
        "modern": "适合大多数行业的现代简约风格，蓝色主调",
        "professional": "适合传统行业和商务职位的经典风格",
        "creative": "适合设计、艺术类创意职位的活力风格",
        "minimal": "简洁黑白配色，突出内容本身",
        "executive": "适合高管和管理职位的庄重风格",
        "tech": "适合程序员和技术职位的代码风格",
        "academic": "适合教育和研究职位的学术风格",
        "startup": "适合互联网创业公司的活力风格",
        "elegant": "优雅棕色系，适合需要展现品味的职位",
        "fresh": "清新绿色系，充满活力和朝气",
    }

    # 转换为更友好的格式
    style_list = []
    for style_id, style_config in styles.items():
        style_list.append(
            {
                "id": style_id,
                "name": style_config["name"],
                "description": style_descriptions.get(
                    style_id, f"{style_config['name']}风格，{style_config['layout']}布局"
                ),
                "primary_color": style_config["primary_color"],
                "secondary_color": style_config["secondary_color"],
                "font_family": style_config["font_family"],
                "layout": style_config["layout"],
            }
        )

    return Response(data=style_list, message="获取成功")
