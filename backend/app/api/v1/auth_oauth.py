"""
OAuth 认证路由 (Google, GitHub)
"""

from datetime import datetime, timezone
from typing import Optional
import secrets
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select

from app.core.database import get_db
from app.core.security import (
    create_access_token,
    create_refresh_token,
    get_current_user,
    get_password_hash,
)
from app.core.config import settings
from app.models.user import User
from app.schemas.user import TokenResponse, UserResponse, OAuthLoginRequest, OAuthBindRequest
from app.schemas.common import Response
from app.services.oauth_service import (
    get_google_provider,
    get_github_provider,
    get_gitee_provider,
    get_discord_provider,
    get_state_manager,
    oauth_login,
)

router = APIRouter(prefix="/auth/oauth", tags=["OAuth认证"])


def _create_token_response(user: User) -> TokenResponse:
    """创建令牌响应"""
    access_token = create_access_token(data={"sub": str(user.id)})
    refresh_token = create_refresh_token(data={"sub": str(user.id)})

    return TokenResponse(
        access_token=access_token,
        refresh_token=refresh_token,
        expires_in=settings.ACCESS_TOKEN_EXPIRE_MINUTES * 60,
    )


# ==================== Google OAuth ====================


@router.get("/google/authorize")
async def google_authorize(
    redirect_uri: Optional[str] = None,
):
    """
    获取 Google OAuth 授权 URL

    前端调用此接口获取授权URL，然后重定向用户到该URL
    """
    provider = get_google_provider()
    if not provider:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail="Google OAuth 未配置"
        )

    # 生成 state 参数
    state_manager = get_state_manager()
    state = state_manager.generate_state()

    # 获取授权 URL
    auth_url = await provider.get_authorization_url(state, redirect_uri)

    return Response(
        data={"auth_url": auth_url, "state": state, "provider": "google"}, message="获取授权URL成功"
    )


@router.post("/google/callback")
async def google_callback(request_data: OAuthLoginRequest, db: AsyncSession = Depends(get_db)):
    """
    处理 Google OAuth 回调

    前端获取到 code 后调用此接口完成登录
    """
    provider_info = await oauth_login(
        "google", request_data.code, request_data.state, request_data.redirect_uri
    )

    # 查找是否已有该 Google ID 的用户
    result = await db.execute(select(User).where(User.google_id == provider_info["provider_id"]))
    user = result.scalar_one_or_none()

    if user:
        # 用户已存在，更新登录时间
        if not user.is_active:
            raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="账户已被禁用")
        user.last_login_at = datetime.now(timezone.utc)
        await db.commit()
    else:
        # 新用户，创建账号
        # 如果有邮箱，检查是否已被注册
        email = provider_info.get("email")
        if email:
            existing = await db.execute(select(User).where(User.email == email))
            if existing.scalar_one_or_none():
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST, detail="该邮箱已被注册"
                )

        # 创建新用户
        user = User(
            email=email or f"google_{provider_info['provider_id']}@google.local",
            username=provider_info.get("name", "Google用户"),
            avatar_url=provider_info.get("avatar_url"),
            google_id=provider_info["provider_id"],
            google_email=email,
            google_verified_email=provider_info.get("verified_email", False),
            is_verified=provider_info.get("verified_email", False),
            is_active=True,
            password_hash=get_password_hash(secrets.token_urlsafe(32)),
        )
        db.add(user)
        await db.commit()
        await db.refresh(user)

    return Response(data=_create_token_response(user), message="Google 登录成功")


@router.post("/google/bind")
async def google_bind_account(
    request_data: OAuthBindRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """
    绑定 Google 账号到当前用户
    """
    provider_info = await oauth_login("google", request_data.code, request_data.state)

    # 检查该 Google ID 是否已被其他用户绑定
    existing = await db.execute(
        select(User)
        .where(User.google_id == provider_info["provider_id"])
        .where(User.id != current_user.id)
    )
    if existing.scalar_one_or_none():
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST, detail="该 Google 账号已被其他用户绑定"
        )

    # 绑定 Google 信息到当前用户
    current_user.google_id = provider_info["provider_id"]
    current_user.google_email = provider_info.get("email")
    current_user.google_verified_email = provider_info.get("verified_email", False)
    if not current_user.avatar_url and provider_info.get("avatar_url"):
        current_user.avatar_url = provider_info["avatar_url"]
    await db.commit()

    return Response(data=UserResponse.model_validate(current_user), message="Google 账号绑定成功")


@router.post("/google/unbind")
async def google_unbind_account(
    current_user: User = Depends(get_current_user), db: AsyncSession = Depends(get_db)
):
    """
    解绑 Google 账号
    """
    if not current_user.google_id:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="未绑定 Google 账号")

    current_user.google_id = None
    current_user.google_email = None
    current_user.google_verified_email = False
    await db.commit()

    return Response(message="Google 账号解绑成功")


# ==================== GitHub OAuth ====================


@router.get("/github/authorize")
async def github_authorize(
    redirect_uri: Optional[str] = None,
):
    """
    获取 GitHub OAuth 授权 URL

    前端调用此接口获取授权URL，然后重定向用户到该URL
    """
    provider = get_github_provider()
    if not provider:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail="GitHub OAuth 未配置"
        )

    # 生成 state 参数
    state_manager = get_state_manager()
    state = state_manager.generate_state()

    # 获取授权 URL
    auth_url = await provider.get_authorization_url(state, redirect_uri)

    return Response(
        data={"auth_url": auth_url, "state": state, "provider": "github"}, message="获取授权URL成功"
    )


@router.post("/github/callback")
async def github_callback(request_data: OAuthLoginRequest, db: AsyncSession = Depends(get_db)):
    """
    处理 GitHub OAuth 回调

    前端获取到 code 后调用此接口完成登录
    """
    provider_info = await oauth_login(
        "github", request_data.code, request_data.state, request_data.redirect_uri
    )

    # GitHub ID 是数字
    github_id = int(provider_info["provider_id"])

    # 查找是否已有该 GitHub ID 的用户
    result = await db.execute(select(User).where(User.github_id == github_id))
    user = result.scalar_one_or_none()

    if user:
        # 用户已存在，更新登录时间
        if not user.is_active:
            raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="账户已被禁用")
        user.last_login_at = datetime.now(timezone.utc)
        await db.commit()
    else:
        # 新用户，创建账号
        # 如果有邮箱，检查是否已被注册
        email = provider_info.get("email")
        if email:
            existing = await db.execute(select(User).where(User.email == email))
            if existing.scalar_one_or_none():
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST, detail="该邮箱已被注册"
                )

        # 创建新用户
        user = User(
            email=email or f"github_{github_id}@github.local",
            username=provider_info.get("name", f"GitHub用户_{provider_info.get('login', '')}"),
            avatar_url=provider_info.get("avatar_url"),
            github_id=github_id,
            github_login=provider_info.get("login"),
            github_email=email,
            is_verified=provider_info.get("verified_email", False),
            is_active=True,
            password_hash=get_password_hash(secrets.token_urlsafe(32)),
        )
        db.add(user)
        await db.commit()
        await db.refresh(user)

    return Response(data=_create_token_response(user), message="GitHub 登录成功")


@router.post("/github/bind")
async def github_bind_account(
    request_data: OAuthBindRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """
    绑定 GitHub 账号到当前用户
    """
    provider_info = await oauth_login("github", request_data.code, request_data.state)
    github_id = int(provider_info["provider_id"])

    # 检查该 GitHub ID 是否已被其他用户绑定
    existing = await db.execute(
        select(User).where(User.github_id == github_id).where(User.id != current_user.id)
    )
    if existing.scalar_one_or_none():
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST, detail="该 GitHub 账号已被其他用户绑定"
        )

    # 绑定 GitHub 信息到当前用户
    current_user.github_id = github_id
    current_user.github_login = provider_info.get("login")
    current_user.github_email = provider_info.get("email")
    if not current_user.avatar_url and provider_info.get("avatar_url"):
        current_user.avatar_url = provider_info["avatar_url"]
    await db.commit()

    return Response(data=UserResponse.model_validate(current_user), message="GitHub 账号绑定成功")


@router.post("/github/unbind")
async def github_unbind_account(
    current_user: User = Depends(get_current_user), db: AsyncSession = Depends(get_db)
):
    """
    解绑 GitHub 账号
    """
    if current_user.github_id is None:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="未绑定 GitHub 账号")

    current_user.github_id = None
    current_user.github_login = None
    current_user.github_email = None
    await db.commit()

    return Response(message="GitHub 账号解绑成功")


# ==================== Gitee OAuth ====================


@router.get("/gitee/authorize")
async def gitee_authorize(redirect_uri: Optional[str] = None):
    """获取 Gitee OAuth 授权 URL"""
    provider = get_gitee_provider()
    if not provider:
        raise HTTPException(status_code=500, detail="Gitee OAuth 未配置")

    state_manager = get_state_manager()
    state = state_manager.generate_state()
    auth_url = await provider.get_authorization_url(state, redirect_uri)

    return Response(
        data={"auth_url": auth_url, "state": state, "provider": "gitee"}, message="获取授权URL成功"
    )


@router.post("/gitee/callback")
async def gitee_callback(request_data: OAuthLoginRequest, db: AsyncSession = Depends(get_db)):
    """处理 Gitee OAuth 回调"""
    provider_info = await oauth_login(
        "gitee", request_data.code, request_data.state, request_data.redirect_uri
    )
    gitee_id = int(provider_info["provider_id"])

    result = await db.execute(select(User).where(User.gitee_id == gitee_id))
    user = result.scalar_one_or_none()

    if user:
        if not user.is_active:
            raise HTTPException(status_code=403, detail="账户已被禁用")
        user.last_login_at = datetime.now(timezone.utc)
        await db.commit()
    else:
        email = provider_info.get("email")
        if email:
            existing = await db.execute(select(User).where(User.email == email))
            if existing.scalar_one_or_none():
                raise HTTPException(status_code=400, detail="该邮箱已被注册")

        user = User(
            email=email or f"gitee_{gitee_id}@gitee.local",
            username=provider_info.get("name", f"Gitee用户_{provider_info.get('login', '')}"),
            avatar_url=provider_info.get("avatar_url"),
            gitee_id=gitee_id,
            gitee_login=provider_info.get("login"),
            gitee_email=email,
            is_verified=provider_info.get("verified_email", False),
            is_active=True,
            password_hash=get_password_hash(secrets.token_urlsafe(32)),
        )
        db.add(user)
        await db.commit()
        await db.refresh(user)

    return Response(data=_create_token_response(user), message="Gitee 登录成功")


@router.post("/gitee/bind")
async def gitee_bind_account(
    request_data: OAuthBindRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """绑定 Gitee 账号"""
    provider_info = await oauth_login("gitee", request_data.code, request_data.state)
    gitee_id = int(provider_info["provider_id"])

    existing = await db.execute(
        select(User).where(User.gitee_id == gitee_id).where(User.id != current_user.id)
    )
    if existing.scalar_one_or_none():
        raise HTTPException(status_code=400, detail="该 Gitee 账号已被其他用户绑定")

    current_user.gitee_id = gitee_id
    current_user.gitee_login = provider_info.get("login")
    current_user.gitee_email = provider_info.get("email")
    if not current_user.avatar_url and provider_info.get("avatar_url"):
        current_user.avatar_url = provider_info["avatar_url"]
    await db.commit()

    return Response(data=UserResponse.model_validate(current_user), message="Gitee 账号绑定成功")


@router.post("/gitee/unbind")
async def gitee_unbind_account(
    current_user: User = Depends(get_current_user), db: AsyncSession = Depends(get_db)
):
    """解绑 Gitee 账号"""
    if current_user.gitee_id is None:
        raise HTTPException(status_code=400, detail="未绑定 Gitee 账号")

    current_user.gitee_id = None
    current_user.gitee_login = None
    current_user.gitee_email = None
    await db.commit()

    return Response(message="Gitee 账号解绑成功")


# ==================== Discord OAuth ====================


@router.get("/discord/authorize")
async def discord_authorize(redirect_uri: Optional[str] = None):
    """获取 Discord OAuth 授权 URL"""
    provider = get_discord_provider()
    if not provider:
        raise HTTPException(status_code=500, detail="Discord OAuth 未配置")

    state_manager = get_state_manager()
    state = state_manager.generate_state()
    auth_url = await provider.get_authorization_url(state, redirect_uri)

    return Response(
        data={"auth_url": auth_url, "state": state, "provider": "discord"},
        message="获取授权URL成功",
    )


@router.post("/discord/callback")
async def discord_callback(request_data: OAuthLoginRequest, db: AsyncSession = Depends(get_db)):
    """处理 Discord OAuth 回调"""
    provider_info = await oauth_login(
        "discord", request_data.code, request_data.state, request_data.redirect_uri
    )
    discord_id = provider_info["provider_id"]

    result = await db.execute(select(User).where(User.discord_id == discord_id))
    user = result.scalar_one_or_none()

    if user:
        if not user.is_active:
            raise HTTPException(status_code=403, detail="账户已被禁用")
        user.last_login_at = datetime.now(timezone.utc)
        await db.commit()
    else:
        email = provider_info.get("email")
        if email:
            existing = await db.execute(select(User).where(User.email == email))
            if existing.scalar_one_or_none():
                raise HTTPException(status_code=400, detail="该邮箱已被注册")

        user = User(
            email=email or f"discord_{discord_id}@discord.local",
            username=provider_info.get("name", f"Discord用户_{provider_info.get('username', '')}"),
            avatar_url=provider_info.get("avatar_url"),
            discord_id=discord_id,
            discord_username=provider_info.get("username"),
            discord_email=email,
            discord_avatar=provider_info.get("avatar_url"),
            is_verified=provider_info.get("verified_email", False),
            is_active=True,
            password_hash=get_password_hash(secrets.token_urlsafe(32)),
        )
        db.add(user)
        await db.commit()
        await db.refresh(user)

    return Response(data=_create_token_response(user), message="Discord 登录成功")


@router.post("/discord/bind")
async def discord_bind_account(
    request_data: OAuthBindRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """绑定 Discord 账号"""
    provider_info = await oauth_login("discord", request_data.code, request_data.state)
    discord_id = provider_info["provider_id"]

    existing = await db.execute(
        select(User).where(User.discord_id == discord_id).where(User.id != current_user.id)
    )
    if existing.scalar_one_or_none():
        raise HTTPException(status_code=400, detail="该 Discord 账号已被其他用户绑定")

    current_user.discord_id = discord_id
    current_user.discord_username = provider_info.get("username")
    current_user.discord_email = provider_info.get("email")
    current_user.discord_avatar = provider_info.get("avatar_url")
    if not current_user.avatar_url and provider_info.get("avatar_url"):
        current_user.avatar_url = provider_info["avatar_url"]
    await db.commit()

    return Response(data=UserResponse.model_validate(current_user), message="Discord 账号绑定成功")


@router.post("/discord/unbind")
async def discord_unbind_account(
    current_user: User = Depends(get_current_user), db: AsyncSession = Depends(get_db)
):
    """解绑 Discord 账号"""
    if not current_user.discord_id:
        raise HTTPException(status_code=400, detail="未绑定 Discord 账号")

    current_user.discord_id = None
    current_user.discord_username = None
    current_user.discord_email = None
    current_user.discord_avatar = None
    await db.commit()

    return Response(message="Discord 账号解绑成功")


# ==================== 统一授权入口 ====================


@router.get("/authorize")
async def unified_authorize(provider: str, redirect_uri: Optional[str] = None):
    """统一获取授权 URL 入口"""
    provider_map = {
        "google": get_google_provider,
        "github": get_github_provider,
        "gitee": get_gitee_provider,
        "discord": get_discord_provider,
    }

    get_fn = provider_map.get(provider)
    if not get_fn:
        raise HTTPException(status_code=400, detail=f"不支持的提供商: {provider}")

    p = get_fn()
    if not p:
        raise HTTPException(status_code=500, detail=f"{provider} OAuth 未配置")

    state_manager = get_state_manager()
    state = state_manager.generate_state()
    auth_url = await p.get_authorization_url(state, redirect_uri)

    return Response(
        data={"auth_url": auth_url, "state": state, "provider": provider}, message="获取授权URL成功"
    )
