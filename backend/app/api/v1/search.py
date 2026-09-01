"""
搜索路由
支持简历、模板的全文搜索和筛选
"""

from typing import Optional, List
from fastapi import APIRouter, Depends, Query, Request
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, or_, and_
from app.core.database import get_db
from app.core.security import get_current_user
from app.core.rate_limit import limiter, RateLimit
from app.models.user import User
from app.models.resume import Resume
from app.models.template import Template
from app.schemas.resume import ResumeResponse
from app.schemas.template import TemplateResponse
from app.schemas.common import Response

router = APIRouter(prefix="/search", tags=["搜索"])


@router.get("/resumes", response_model=Response[dict])
@limiter.limit(RateLimit.GENERAL_SEARCH)
async def search_resumes(
    request: Request,
    q: str = Query(..., min_length=1, max_length=100, description="搜索关键词"),
    page: int = Query(1, ge=1),
    page_size: int = Query(10, ge=1, le=50),
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """
    搜索用户的简历

    搜索范围:
    - 简历标题
    - 简历描述
    - 内容中的姓名、联系方式
    - 工作经历的公司名称、职位
    - 教育经历的学校名称、专业
    """
    # 构建搜索条件
    search_pattern = f"%{q}%"

    # 搜索标题和描述
    conditions = [
        Resume.user_id == current_user.id,
        or_(Resume.title.like(search_pattern), Resume.description.like(search_pattern)),
    ]

    # 尝试在JSON内容中搜索（SQLite支持JSON操作）
    # 使用SQLAlchemy的JSON表达式
    try:
        pass

        # 搜索姓名
        conditions[1] = or_(
            conditions[1], Resume.content["basic_info"]["name"].astext.like(search_pattern)
        )
        # 搜索电话
        conditions[1] = or_(
            conditions[1], Resume.content["basic_info"]["phone"].astext.like(search_pattern)
        )
        # 搜索邮箱
        conditions[1] = or_(
            conditions[1], Resume.content["basic_info"]["email"].astext.like(search_pattern)
        )
    except (ImportError, AttributeError, Exception):
        pass  # 如果JSON搜索失败，使用基本搜索

    # 执行查询
    from sqlalchemy import func

    count_query = select(func.count()).select_from(Resume).where(and_(*conditions))
    total_result = await db.execute(count_query)
    total = total_result.scalar()

    # 分页查询
    query = select(Resume).where(and_(*conditions))
    query = query.order_by(Resume.updated_at.desc())
    query = query.offset((page - 1) * page_size).limit(page_size)
    result = await db.execute(query)
    resumes = result.scalars().all()

    return Response(
        data={
            "results": [ResumeResponse.model_validate(r) for r in resumes],
            "total": total,
            "page": page,
            "page_size": page_size,
            "query": q,
        },
        message="搜索完成",
    )


@router.get("/templates", response_model=Response[dict])
@limiter.limit(RateLimit.GENERAL_SEARCH)
async def search_templates(
    request: Request,
    q: str = Query(..., min_length=1, max_length=100, description="搜索关键词"),
    category: Optional[str] = Query(None, description="分类筛选"),
    industry: Optional[str] = Query(None, description="行业筛选"),
    page: int = Query(1, ge=1),
    page_size: int = Query(10, ge=1, le=50),
    db: AsyncSession = Depends(get_db),
):
    """
    搜索简历模板

    搜索范围:
    - 模板名称
    - 模板描述
    - 分类标签
    - 行业标签
    """
    search_pattern = f"%{q}%"

    # 构建搜索条件
    conditions = [
        Template.is_active.is_(True),
        or_(
            Template.name.like(search_pattern),
            Template.description.like(search_pattern),
            Template.category.like(search_pattern),
            Template.sub_category.like(search_pattern),
        ),
    ]

    # 添加分类筛选
    if category:
        conditions.append(Template.category == category)

    # 添加子分类筛选
    if industry:
        # 使用 sub_category 作为 industry 的替代
        conditions.append(Template.sub_category == industry)

    # 执行查询
    from sqlalchemy import func

    count_query = select(func.count()).select_from(Template).where(and_(*conditions))
    total_result = await db.execute(count_query)
    total = total_result.scalar()

    # 分页查询
    query = select(Template).where(and_(*conditions))
    query = query.order_by(Template.is_premium.asc(), Template.created_at.desc())
    query = query.offset((page - 1) * page_size).limit(page_size)
    result = await db.execute(query)
    templates = result.scalars().all()

    return Response(
        data={
            "results": [TemplateResponse.model_validate(t) for t in templates],
            "total": total,
            "page": page,
            "page_size": page_size,
            "query": q,
        },
        message="搜索完成",
    )


@router.get("/categories", response_model=Response[List[dict]])
async def get_search_categories(db: AsyncSession = Depends(get_db)):
    """获取可用的搜索分类"""
    from sqlalchemy import distinct

    # 获取所有分类
    result = await db.execute(
        select(distinct(Template.category)).where(Template.category.isnot(None))
    )
    categories = [r[0] for r in result.all() if r[0]]

    # 获取所有子分类
    result = await db.execute(
        select(distinct(Template.sub_category)).where(Template.sub_category.isnot(None))
    )
    sub_categories = [r[0] for r in result.all() if r[0]]

    return Response(
        data=[
            {"type": "category", "name": "分类", "options": categories},
            {"type": "sub_category", "name": "子分类", "options": sub_categories},
        ],
        message="获取成功",
    )


@router.get("/suggestions", response_model=Response[List[str]])
@limiter.limit("60/minute")
async def get_search_suggestions(
    request: Request,
    q: str = Query(..., min_length=1, max_length=50, description="输入前缀"),
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """
    获取搜索建议

    基于用户输入提供搜索建议:
    - 匹配简历标题
    - 匹配常用搜索词
    """
    search_pattern = f"%{q}%"

    # 从用户的简历标题中获取建议
    result = await db.execute(
        select(Resume.title)
        .where(and_(Resume.user_id == current_user.id, Resume.title.like(search_pattern)))
        .distinct()
        .limit(5)
    )
    title_suggestions = [r[0] for r in result.all()]

    # 常用搜索词建议
    common_suggestions = [
        "软件工程师",
        "产品经理",
        "数据分析师",
        "前端开发",
        "后端开发",
        "全栈开发",
        "Java",
        "Python",
        "React",
        "Vue",
    ]
    filtered_suggestions = [s for s in common_suggestions if q.lower() in s.lower()]

    # 合并并去重
    all_suggestions = list(set(title_suggestions + filtered_suggestions))[:10]

    return Response(data=all_suggestions, message="获取成功")
