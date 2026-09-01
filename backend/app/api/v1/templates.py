"""
模板路由
"""

from typing import Optional
from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, func
from app.core.database import get_db
from app.core.security import get_current_user
from app.models.user import User
from app.models.template import Template, Favorite
from app.schemas.common import Response, PageResponse
from pydantic import BaseModel, ConfigDict

router = APIRouter(prefix="/templates", tags=["模板"])


class TemplateResponse(BaseModel):
    """模板响应"""

    id: int
    name: str
    description: Optional[str] = None
    category: Optional[str] = None
    sub_category: Optional[str] = None
    level: Optional[str] = None
    layout: str
    preview_url: Optional[str] = None
    thumbnail_url: Optional[str] = None
    is_premium: bool
    use_count: int

    model_config = ConfigDict(from_attributes=True)


@router.get("", response_model=PageResponse[TemplateResponse])
async def list_templates(
    page: int = Query(1, ge=1),
    page_size: int = Query(20, ge=1, le=100),
    category: Optional[str] = None,
    sub_category: Optional[str] = None,
    level: Optional[str] = None,
    is_premium: Optional[bool] = None,
    db: AsyncSession = Depends(get_db),
):
    """获取模板列表"""
    # 构建查询
    query = select(Template).where(Template.is_active.is_(True))
    count_query = select(func.count()).select_from(Template).where(Template.is_active.is_(True))

    if category:
        query = query.where(Template.category == category)
        count_query = count_query.where(Template.category == category)
    if sub_category:
        query = query.where(Template.sub_category == sub_category)
        count_query = count_query.where(Template.sub_category == sub_category)
    if level:
        query = query.where(Template.level == level)
        count_query = count_query.where(Template.level == level)
    if is_premium is not None:
        query = query.where(Template.is_premium == is_premium)
        count_query = count_query.where(Template.is_premium == is_premium)

    # 计算总数
    total_result = await db.execute(count_query)
    total = total_result.scalar()

    # 分页查询
    query = (
        query.order_by(Template.use_count.desc()).offset((page - 1) * page_size).limit(page_size)
    )
    result = await db.execute(query)
    templates = result.scalars().all()

    return PageResponse(
        data=[TemplateResponse.model_validate(t) for t in templates],
        total=total,
        page=page,
        page_size=page_size,
    )


@router.get("/categories", response_model=Response[list])
async def get_categories(db: AsyncSession = Depends(get_db)):
    """获取模板分类列表"""
    result = await db.execute(
        select(Template.category).where(Template.is_active.is_(True)).distinct()
    )
    categories = [row[0] for row in result.fetchall() if row[0]]

    return Response(data=categories, message="获取成功")


@router.get("/{template_id}", response_model=Response[TemplateResponse])
async def get_template(template_id: int, db: AsyncSession = Depends(get_db)):
    """获取模板详情"""
    result = await db.execute(
        select(Template).where(Template.id == template_id, Template.is_active.is_(True))
    )
    template = result.scalar_one_or_none()

    if not template:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="模板不存在")

    return Response(data=TemplateResponse.model_validate(template), message="获取成功")


@router.post("/{template_id}/use", response_model=Response)
async def use_template(
    template_id: int,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """使用模板（增加使用计数）"""
    result = await db.execute(
        select(Template).where(Template.id == template_id, Template.is_active.is_(True))
    )
    template = result.scalar_one_or_none()

    if not template:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="模板不存在")

    # 检查高级模板权限
    if template.is_premium and current_user.role == "user":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN, detail="需要高级会员权限使用此模板"
        )

    template.use_count += 1
    await db.commit()

    return Response(message="模板使用成功")


@router.post("/{template_id}/favorite", response_model=Response)
async def favorite_template(
    template_id: int,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """收藏模板"""
    # 检查模板是否存在
    result = await db.execute(
        select(Template).where(Template.id == template_id, Template.is_active.is_(True))
    )
    if not result.scalar_one_or_none():
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="模板不存在")

    # 检查是否已收藏
    result = await db.execute(
        select(Favorite).where(
            Favorite.user_id == current_user.id,
            Favorite.target_type == "template",
            Favorite.target_id == template_id,
        )
    )
    if result.scalar_one_or_none():
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="已收藏过该模板")

    # 创建收藏
    favorite = Favorite(user_id=current_user.id, target_type="template", target_id=template_id)
    db.add(favorite)
    await db.commit()

    return Response(message="收藏成功")


@router.delete("/{template_id}/favorite", response_model=Response)
async def unfavorite_template(
    template_id: int,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """取消收藏模板"""
    result = await db.execute(
        select(Favorite).where(
            Favorite.user_id == current_user.id,
            Favorite.target_type == "template",
            Favorite.target_id == template_id,
        )
    )
    favorite = result.scalar_one_or_none()

    if not favorite:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="未收藏该模板")

    await db.delete(favorite)
    await db.commit()

    return Response(message="取消收藏成功")


@router.get("/favorites/list", response_model=Response[list])
async def get_favorite_templates(
    current_user: User = Depends(get_current_user), db: AsyncSession = Depends(get_db)
):
    """获取收藏的模板列表"""
    result = await db.execute(
        select(Favorite.target_id).where(
            Favorite.user_id == current_user.id, Favorite.target_type == "template"
        )
    )
    template_ids = [row[0] for row in result.fetchall()]

    if not template_ids:
        return Response(data=[], message="获取成功")

    result = await db.execute(
        select(Template).where(Template.id.in_(template_ids), Template.is_active.is_(True))
    )
    templates = result.scalars().all()

    return Response(
        data=[TemplateResponse.model_validate(t) for t in templates], message="获取成功"
    )
