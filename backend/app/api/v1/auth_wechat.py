"""
微信登录路由
"""

from datetime import datetime, timezone
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
import httpx
import random

from app.core.database import get_db
from app.core.security import (
    get_password_hash,
    create_access_token,
    create_refresh_token,
    get_current_user,
)
from app.core.config import settings
from app.core.rate_limit import limiter, RateLimit
from app.models.user import User
from app.schemas.user import TokenResponse, WechatLoginRequest, WechatUserInfo
from app.schemas.common import Response

router = APIRouter(prefix="/auth/wechat", tags=["微信登录"])


async def _get_wechat_access_token(code: str) -> dict:
    """
    通过微信授权码获取access_token
    文档: https://developers.weixin.qq.com/miniprogram/dev/api-backend/open-api/login.html
    """
    appid = getattr(settings, "WECHAT_APP_ID", "")
    secret = getattr(settings, "WECHAT_APP_SECRET", "")

    if not appid or not secret:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail="微信登录未配置，请联系管理员"
        )

    async with httpx.AsyncClient() as client:
        url = "https://api.weixin.qq.com/sns/jscode2session"
        params = {
            "appid": appid,
            "secret": secret,
            "js_code": code,
            "grant_type": "authorization_code",
        }
        response = await client.get(url, params=params)
        data = response.json()

        if "errcode" in data and data["errcode"] != 0:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"微信授权失败: {data.get('errmsg', '未知错误')}",
            )

        return data


def _create_token_response(user: User) -> TokenResponse:
    """创建令牌响应"""
    access_token = create_access_token(data={"sub": str(user.id)})
    refresh_token = create_refresh_token(data={"sub": str(user.id)})

    return TokenResponse(
        access_token=access_token,
        refresh_token=refresh_token,
        expires_in=settings.ACCESS_TOKEN_EXPIRE_MINUTES * 60,
    )


@router.post("/login", response_model=None)
@limiter.limit(RateLimit.AUTH_LOGIN)
async def wechat_login(request: WechatLoginRequest, db: AsyncSession = Depends(get_db)):
    """
    微信小程序登录

    流程:
    1. 小程序调用 wx.login 获取 code
    2. 前端将 code 发送到后端
    3. 后端通过 code 向微信服务器获取 session_key 和 openid
    4. 根据 openid 查找或创建用户
    5. 返回 JWT token
    """
    # 获取微信用户信息
    wechat_data = await _get_wechat_access_token(request.code)
    openid = wechat_data.get("openid")
    unionid = wechat_data.get("unionid")  # 只有开放平台绑定的账号才有

    if not openid:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="获取微信用户信息失败")

    # 查找是否已有该openid的用户
    result = await db.execute(select(User).where(User.wechat_openid == openid))
    user = result.scalar_one_or_none()

    if user:
        # 用户已存在，更新登录时间
        if not user.is_active:
            raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="账户已被禁用")
        user.last_login_at = datetime.now(timezone.utc)
        await db.commit()
    else:
        # 新用户，创建账号
        # 使用一个临时邮箱（基于openid生成）
        temp_email = f"wx_{openid}@wechat.local"

        # 检查邮箱是否已被占用（理论上不太可能）
        existing = await db.execute(select(User).where(User.email == temp_email))
        if existing.scalar_one_or_none():
            # 极端情况，使用随机数
            temp_email = f"wx_{random.randint(1000000, 9999999)}@wechat.local"

        user = User(
            email=temp_email,
            username=f"微信用户_{openid[:8]}",
            password_hash=get_password_hash(str(openid)),  # 临时密码
            wechat_openid=openid,
            wechat_unionid=unionid,
            is_verified=True,  # 微信用户默认已验证
        )
        db.add(user)
        await db.commit()
        await db.refresh(user)

    return Response(data=_create_token_response(user), message="登录成功")


@router.post("/bind", response_model=None)
async def wechat_bind_account(
    request_data: WechatLoginRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """
    绑定微信账号

    允许已注册用户绑定微信，之后可以使用微信登录
    """
    # 获取微信用户信息
    wechat_data = await _get_wechat_access_token(request_data.code)
    openid = wechat_data.get("openid")
    unionid = wechat_data.get("unionid")

    if not openid:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="获取微信用户信息失败")

    # 检查该微信号是否已被其他用户绑定
    existing = await db.execute(select(User).where(User.wechat_openid == openid))
    if existing.scalar_one_or_none():
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST, detail="该微信账号已被其他用户绑定"
        )

    # 绑定当前用户
    current_user.wechat_openid = openid
    if unionid:
        current_user.wechat_unionid = unionid
    await db.commit()

    return Response(
        data=WechatUserInfo(openid=openid, unionid=unionid, bind_time=datetime.now(timezone.utc)),
        message="微信账号绑定成功",
    )


@router.post("/unbind")
async def wechat_unbind_account(
    current_user: User = Depends(get_current_user), db: AsyncSession = Depends(get_db)
):
    """
    解绑微信账号

    解绑后无法使用微信登录，但仍可使用邮箱密码登录
    """
    if not current_user.wechat_openid:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="当前账号未绑定微信")

    current_user.wechat_openid = None
    current_user.wechat_unionid = None
    await db.commit()

    return Response(message="微信账号解绑成功")
