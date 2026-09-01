"""
简历路由
"""

from typing import Optional
from fastapi import APIRouter, Depends, HTTPException, status, Query, Request
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, func
from app.core.database import get_db
from app.core.security import get_current_user
from app.core.rate_limit import limiter, RateLimit
from app.models.user import User
from app.models.resume import Resume, ResumeVersion
from app.schemas.resume import (
    ResumeCreate,
    ResumeUpdate,
    ResumeResponse,
    ResumeVersionResponse,
    AIGenerateRequest,
    AIOptimizeRequest,
    AIOptimizeResponse,
)
from app.schemas.common import Response, PageResponse
from app.services.ai.ai_service_factory import get_ai_provider
from app.services.ai_usage_service import get_ai_usage_service
from app.services.ai_limit_decorator import AIUsageLimitExceeded

router = APIRouter(prefix="/resumes", tags=["简历"])


async def get_ai_service():
    """获取当前配置的AI服务"""
    return get_ai_provider()


@router.get("", response_model=PageResponse[ResumeResponse])
async def list_resumes(
    page: int = Query(1, ge=1),
    page_size: int = Query(10, ge=1, le=100),
    status: Optional[str] = None,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """获取简历列表"""
    # 构建查询
    query = select(Resume).where(Resume.user_id == current_user.id)

    if status:
        query = query.where(Resume.status == status)

    # 计算总数
    count_query = select(func.count()).select_from(Resume).where(Resume.user_id == current_user.id)
    if status:
        count_query = count_query.where(Resume.status == status)
    total_result = await db.execute(count_query)
    total = total_result.scalar()

    # 分页查询
    query = query.order_by(Resume.updated_at.desc()).offset((page - 1) * page_size).limit(page_size)
    result = await db.execute(query)
    resumes = result.scalars().all()

    return PageResponse(
        data=[ResumeResponse.model_validate(r) for r in resumes],
        total=total,
        page=page,
        page_size=page_size,
    )


@router.post("", response_model=Response[ResumeResponse])
@limiter.limit(RateLimit.RESUME_CREATE)
async def create_resume(
    request: Request,
    resume_data: ResumeCreate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """创建简历"""
    resume = Resume(
        user_id=current_user.id,
        title=resume_data.title,
        description=resume_data.description,
        template_id=resume_data.template_id,
        content=resume_data.content.model_dump() if resume_data.content else {},
        style_config=resume_data.style_config.model_dump() if resume_data.style_config else {},
    )
    db.add(resume)
    await db.commit()
    await db.refresh(resume)

    return Response(data=ResumeResponse.model_validate(resume), message="简历创建成功")


@router.get("/{resume_id}", response_model=Response[ResumeResponse])
async def get_resume(
    resume_id: int,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """获取简历详情"""
    result = await db.execute(
        select(Resume).where(Resume.id == resume_id, Resume.user_id == current_user.id)
    )
    resume = result.scalar_one_or_none()

    if not resume:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="简历不存在")

    return Response(data=ResumeResponse.model_validate(resume), message="获取成功")


@router.put("/{resume_id}", response_model=Response[ResumeResponse])
@limiter.limit(RateLimit.RESUME_UPDATE)
async def update_resume(
    request: Request,
    resume_id: int,
    resume_data: ResumeUpdate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """更新简历"""
    result = await db.execute(
        select(Resume).where(Resume.id == resume_id, Resume.user_id == current_user.id)
    )
    resume = result.scalar_one_or_none()

    if not resume:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="简历不存在")

    # 保存版本历史
    version = ResumeVersion(
        resume_id=resume.id,
        version_number=resume.version,
        content=resume.content,
        style_config=resume.style_config,
        change_note="自动保存",
    )
    db.add(version)

    # 更新简历
    if resume_data.title is not None:
        resume.title = resume_data.title
    if resume_data.description is not None:
        resume.description = resume_data.description
    if resume_data.template_id is not None:
        resume.template_id = resume_data.template_id
    if resume_data.content is not None:
        resume.content = resume_data.content.model_dump()
    if resume_data.style_config is not None:
        resume.style_config = resume_data.style_config.model_dump()
    if resume_data.status is not None:
        resume.status = resume_data.status

    resume.version += 1
    await db.commit()
    await db.refresh(resume)

    return Response(data=ResumeResponse.model_validate(resume), message="简历更新成功")


@router.delete("/{resume_id}", response_model=Response)
@limiter.limit(RateLimit.RESUME_DELETE)
async def delete_resume(
    request: Request,
    resume_id: int,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """删除简历"""
    result = await db.execute(
        select(Resume).where(Resume.id == resume_id, Resume.user_id == current_user.id)
    )
    resume = result.scalar_one_or_none()

    if not resume:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="简历不存在")

    await db.delete(resume)
    await db.commit()

    return Response(message="简历删除成功")


@router.get("/{resume_id}/versions", response_model=Response[list])
async def get_resume_versions(
    resume_id: int,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """获取简历版本历史"""
    # 验证简历所属
    result = await db.execute(
        select(Resume).where(Resume.id == resume_id, Resume.user_id == current_user.id)
    )
    if not result.scalar_one_or_none():
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="简历不存在")

    # 获取版本列表
    result = await db.execute(
        select(ResumeVersion)
        .where(ResumeVersion.resume_id == resume_id)
        .order_by(ResumeVersion.version_number.desc())
    )
    versions = result.scalars().all()

    return Response(
        data=[ResumeVersionResponse.model_validate(v) for v in versions], message="获取成功"
    )


@router.post("/{resume_id}/rollback/{version_id}", response_model=Response[ResumeResponse])
async def rollback_resume(
    resume_id: int,
    version_id: int,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """回滚到指定版本"""
    # 获取简历
    result = await db.execute(
        select(Resume).where(Resume.id == resume_id, Resume.user_id == current_user.id)
    )
    resume = result.scalar_one_or_none()

    if not resume:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="简历不存在")

    # 获取版本
    result = await db.execute(
        select(ResumeVersion).where(
            ResumeVersion.id == version_id, ResumeVersion.resume_id == resume_id
        )
    )
    version = result.scalar_one_or_none()

    if not version:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="版本不存在")

    # 保存当前版本
    current_version = ResumeVersion(
        resume_id=resume.id,
        version_number=resume.version,
        content=resume.content,
        style_config=resume.style_config,
        change_note="回滚前保存",
    )
    db.add(current_version)

    # 回滚
    resume.content = version.content
    resume.style_config = version.style_config
    resume.version += 1

    await db.commit()
    await db.refresh(resume)

    return Response(data=ResumeResponse.model_validate(resume), message="回滚成功")


# ============ AI 功能 ============


@router.post("/{resume_id}/ai/generate", response_model=Response)
@limiter.limit(RateLimit.AI_GENERATE)
async def ai_generate_resume(
    http_request: Request,
    resume_id: int,
    request: AIGenerateRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """AI生成简历内容"""
    # 检查 AI 使用限制
    usage_service = get_ai_usage_service()
    daily_allowed, daily_used, daily_limit = await usage_service.check_daily_limit(
        db, current_user.id
    )
    if not daily_allowed:
        raise AIUsageLimitExceeded(daily_used, daily_limit, "day")

    monthly_allowed, monthly_used, monthly_limit = await usage_service.check_monthly_limit(
        db, current_user.id
    )
    if not monthly_allowed:
        raise AIUsageLimitExceeded(monthly_used, monthly_limit, "month")

    # 获取简历
    result = await db.execute(
        select(Resume).where(Resume.id == resume_id, Resume.user_id == current_user.id)
    )
    resume = result.scalar_one_or_none()

    if not resume:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="简历不存在")

    # 调用AI服务
    ai_service = await get_ai_service()
    ai_response = await ai_service.generate_resume_content(
        user_info=resume.content,
        target_position=request.target_position,
        style=request.style,
        language=request.language,
    )

    # 提取内容和 token 使用信息
    if isinstance(ai_response, dict) and "content" in ai_response:
        generated_content = ai_response["content"]
        usage_info = ai_response.get("usage", {})
        meta_info = ai_response.get("meta", {})
    else:
        generated_content = ai_response
        usage_info = {}
        meta_info = {}

    # 更新简历
    resume.content = generated_content
    resume.version += 1
    await db.commit()
    await db.refresh(resume)

    # 记录 AI 使用
    try:
        await usage_service.record_usage(
            db=db,
            user_id=current_user.id,
            provider=meta_info.get("provider", "unknown"),
            model=meta_info.get("model", "unknown"),
            operation="generate",
            prompt_tokens=usage_info.get("prompt_tokens", 0),
            completion_tokens=usage_info.get("completion_tokens", 0),
            total_tokens=usage_info.get("total_tokens", 0),
        )
    except Exception as e:
        # 记录失败不影响主流程
        print(f"[WARN] Failed to record AI usage: {e}")

    return Response(data=ResumeResponse.model_validate(resume), message="AI生成成功")


@router.post("/ai/optimize", response_model=Response[AIOptimizeResponse])
@limiter.limit(RateLimit.AI_OPTIMIZE)
async def ai_optimize_content(
    http_request: Request,
    request: AIOptimizeRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """AI优化内容"""
    # 检查 AI 使用限制
    usage_service = get_ai_usage_service()
    daily_allowed, daily_used, daily_limit = await usage_service.check_daily_limit(
        db, current_user.id
    )
    if not daily_allowed:
        raise AIUsageLimitExceeded(daily_used, daily_limit, "day")

    monthly_allowed, monthly_used, monthly_limit = await usage_service.check_monthly_limit(
        db, current_user.id
    )
    if not monthly_allowed:
        raise AIUsageLimitExceeded(monthly_used, monthly_limit, "month")

    ai_service = await get_ai_service()
    optimized = await ai_service.optimize_content(
        original=request.content,
        optimization_type=request.optimization_type,
        context=request.context,
    )

    # 记录 AI 使用（估算 token）
    try:
        estimated_tokens = (
            len(request.content) + len(optimized) if optimized else len(request.content)
        )
        await usage_service.record_usage(
            db=db,
            user_id=current_user.id,
            provider="unknown",
            model="unknown",
            operation="optimize",
            total_tokens=estimated_tokens,
        )
    except Exception as e:
        print(f"[WARN] Failed to record AI usage: {e}")

    return Response(
        data=AIOptimizeResponse(original=request.content, optimized=optimized, suggestions=[]),
        message="优化成功",
    )
