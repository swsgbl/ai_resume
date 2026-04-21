"""
账号管理 API
支持账号绑定、解绑、切换主账号
"""
import re
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from pydantic import BaseModel, EmailStr, Field, field_validator

from app.core.database import get_db
from app.core.security import (
    get_current_user, verify_password
)
from app.models.user import User
from app.schemas.common import Response

router = APIRouter(prefix="/account", tags=["账号管理"])


class BindEmailRequest(BaseModel):
    """绑定邮箱请求"""
    email: EmailStr
    password: str
    verification_code: str


class BindPhoneRequest(BaseModel):
    """绑定手机号请求（纯前端校验，无需短信验证码）"""
    phone: str = Field(..., description="中国大陆11位手机号")

    @field_validator('phone')
    @classmethod
    def validate_phone(cls, v: str) -> str:
        if not re.match(r'^1[3-9]\d{9}$', v):
            raise ValueError('请输入正确的11位手机号（中国大陆）')
        return v


class UnbindAccountRequest(BaseModel):
    """解绑账号请求"""
    account_type: str  # 'email', 'phone', 'wechat', 'google', 'github', 'gitee', 'discord'
    password: str  # 安全验证


@router.get("/bindings")
async def get_account_bindings(
    current_user: User = Depends(get_current_user)
):
    """获取所有已绑定的账号"""
    bindings = {
        "email": {
            "bound": bool(current_user.email),
            "value": current_user.email,
            "is_primary": True,
            "verified": current_user.is_verified
        },
        "phone": {
            "bound": bool(current_user.phone),
            "value": current_user.phone,
            "is_primary": False,
            "verified": True
        },
        "wechat": {
            "bound": bool(current_user.wechat_openid),
            "value": current_user.wechat_nickname,
            "is_primary": False,
            "verified": True
        },
        "google": {
            "bound": bool(current_user.google_id),
            "value": current_user.google_email,
            "is_primary": False,
            "verified": current_user.google_verified_email or False
        },
        "github": {
            "bound": bool(current_user.github_id),
            "value": current_user.github_login,
            "is_primary": False,
            "verified": True
        },
        "gitee": {
            "bound": bool(current_user.gitee_id),
            "value": current_user.gitee_login,
            "is_primary": False,
            "verified": True
        },
        "discord": {
            "bound": bool(current_user.discord_id),
            "value": current_user.discord_username,
            "is_primary": False,
            "verified": True
        }
    }

    return Response(data=bindings, message="获取成功")


@router.post("/bind/email")
async def bind_email(
    request: BindEmailRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """绑定邮箱"""
    # 验证密码
    if not verify_password(request.password, current_user.password_hash):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="密码错误"
        )

    # 检查邮箱是否已被绑定
    result = await db.execute(
        select(User).where(User.email == request.email)
    )
    if result.scalar_one_or_none():
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="该邮箱已被其他账号使用"
        )

    # 验证邮箱验证码
    from app.services.email_service import email_service
    if not await email_service.verify_code(request.email, request.verification_code):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="验证码错误或已过期"
        )

    # 绑定邮箱
    current_user.email = request.email
    current_user.is_verified = True
    await db.commit()

    return Response(message="邮箱绑定成功")


@router.post("/bind/phone")
async def bind_phone(
    request: BindPhoneRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """绑定手机号（纯前端校验，无需短信验证码）"""
    # 检查手机号是否已被绑定
    result = await db.execute(
        select(User).where(User.phone == request.phone)
    )
    if result.scalar_one_or_none():
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="该手机号已被其他账号使用"
        )

    # 绑定手机号
    current_user.phone = request.phone
    await db.commit()

    return Response(message="手机号绑定成功")


@router.post("/unbind")
async def unbind_account(
    request: UnbindAccountRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """解绑账号"""
    # 验证密码
    if not verify_password(request.password, current_user.password_hash):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="密码错误"
        )

    # 检查是否至少保留一种登录方式
    bound_count = sum([
        bool(current_user.email),
        bool(current_user.phone),
        bool(current_user.wechat_openid),
        bool(current_user.google_id),
        bool(current_user.github_id),
        bool(current_user.gitee_id),
        bool(current_user.discord_id)
    ])

    if bound_count <= 1:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="至少需要保留一种登录方式"
        )

    # 解绑对应账号
    if request.account_type == "email":
        if not current_user.email:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="邮箱未绑定"
            )
        current_user.email = None
        current_user.is_verified = False

    elif request.account_type == "phone":
        if not current_user.phone:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="手机号未绑定"
            )
        current_user.phone = None

    elif request.account_type == "wechat":
        if not current_user.wechat_openid:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="微信未绑定"
            )
        current_user.wechat_openid = None
        current_user.wechat_unionid = None
        current_user.wechat_nickname = None
        current_user.wechat_avatar = None

    elif request.account_type == "google":
        if not current_user.google_id:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Google未绑定"
            )
        current_user.google_id = None
        current_user.google_email = None
        current_user.google_verified_email = None

    elif request.account_type == "github":
        if not current_user.github_id:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="GitHub未绑定"
            )
        current_user.github_id = None
        current_user.github_login = None
        current_user.github_email = None

    elif request.account_type == "gitee":
        if not current_user.gitee_id:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Gitee未绑定"
            )
        current_user.gitee_id = None
        current_user.gitee_login = None
        current_user.gitee_email = None

    elif request.account_type == "discord":
        if not current_user.discord_id:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Discord未绑定"
            )
        current_user.discord_id = None
        current_user.discord_username = None
        current_user.discord_email = None
        current_user.discord_avatar = None

    else:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="不支持的账号类型"
        )

    await db.commit()
    return Response(message="解绑成功")
