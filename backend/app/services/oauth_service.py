"""
OAuth 认证服务

支持 Google 和 GitHub OAuth 2.0 登录
"""

import secrets
import time
import httpx
from typing import Optional, Dict, Any
from fastapi import HTTPException, status
from app.core.config import settings


class OAuthProvider:
    """OAuth 提供商基类"""

    def __init__(self, name: str):
        self.name = name

    async def get_authorization_url(self, state: str, redirect_uri: Optional[str] = None) -> str:
        """获取授权URL"""
        raise NotImplementedError

    async def exchange_code_for_token(self, code: str, redirect_uri: str) -> Dict[str, Any]:
        """用授权码换取访问令牌"""
        raise NotImplementedError

    async def get_user_info(self, access_token: str) -> Dict[str, Any]:
        """获取用户信息"""
        raise NotImplementedError

    def normalize_user_info(self, raw_info: Dict[str, Any]) -> Dict[str, Any]:
        """标准化用户信息"""
        raise NotImplementedError


class GoogleOAuthProvider(OAuthProvider):
    """Google OAuth 提供商

    文档: https://developers.google.com/identity/protocols/oauth2
    """

    AUTH_URL = "https://accounts.google.com/o/oauth2/v2/auth"
    TOKEN_URL = "https://oauth2.googleapis.com/token"
    USER_INFO_URL = "https://www.googleapis.com/oauth2/v2/userinfo"

    def __init__(self):
        super().__init__("google")
        self.client_id = getattr(settings, "GOOGLE_CLIENT_ID", "")
        self.client_secret = getattr(settings, "GOOGLE_CLIENT_SECRET", "")
        self.default_redirect_uri = getattr(
            settings, "GOOGLE_REDIRECT_URI", "http://localhost:8000/api/v1/auth/google/callback"
        )

        if not self.client_id:
            raise ValueError("GOOGLE_CLIENT_ID 未配置")

    async def get_authorization_url(self, state: str, redirect_uri: Optional[str] = None) -> str:
        """获取 Google OAuth 授权 URL"""
        from urllib.parse import urlencode

        params = {
            "client_id": self.client_id,
            "redirect_uri": redirect_uri or self.default_redirect_uri,
            "response_type": "code",
            "scope": "openid email profile",
            "state": state,
            "access_type": "offline",
            "prompt": "consent",
        }
        return f"{self.AUTH_URL}?{urlencode(params)}"

    async def exchange_code_for_token(self, code: str, redirect_uri: str) -> Dict[str, Any]:
        """用授权码换取访问令牌"""
        if not self.client_secret:
            raise ValueError("GOOGLE_CLIENT_SECRET 未配置")

        async with httpx.AsyncClient() as client:
            response = await client.post(
                self.TOKEN_URL,
                data={
                    "code": code,
                    "client_id": self.client_id,
                    "client_secret": self.client_secret,
                    "redirect_uri": redirect_uri,
                    "grant_type": "authorization_code",
                },
                headers={"Accept": "application/json"},
            )
            data = response.json()

            if "error" in data:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail=f"Google OAuth 错误: {data.get('error_description', data.get('error'))}",
                )

            return data

    async def get_user_info(self, access_token: str) -> Dict[str, Any]:
        """获取 Google 用户信息"""
        async with httpx.AsyncClient() as client:
            response = await client.get(
                self.USER_INFO_URL, headers={"Authorization": f"Bearer {access_token}"}
            )
            if response.status_code != 200:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST, detail="获取 Google 用户信息失败"
                )
            return response.json()

    def normalize_user_info(self, raw_info: Dict[str, Any]) -> Dict[str, Any]:
        """标准化 Google 用户信息"""
        return {
            "provider": "google",
            "provider_id": raw_info.get("id"),
            "email": raw_info.get("email"),
            "verified_email": raw_info.get("verified_email", False),
            "name": raw_info.get("name"),
            "avatar_url": raw_info.get("picture"),
            "locale": raw_info.get("locale"),
        }


class GitHubOAuthProvider(OAuthProvider):
    """GitHub OAuth 提供商

    文档: https://docs.github.com/en/apps/oauth-apps/building-oauth-apps/authorizing-oauth-apps
    """

    AUTH_URL = "https://github.com/login/oauth/authorize"
    TOKEN_URL = "https://github.com/login/oauth/access_token"
    USER_INFO_URL = "https://api.github.com/user"
    USER_EMAIL_URL = "https://api.github.com/user/emails"

    def __init__(self):
        super().__init__("github")
        self.client_id = getattr(settings, "GITHUB_CLIENT_ID", "")
        self.client_secret = getattr(settings, "GITHUB_CLIENT_SECRET", "")
        self.default_redirect_uri = getattr(
            settings, "GITHUB_REDIRECT_URI", "http://localhost:8000/api/v1/auth/github/callback"
        )

        if not self.client_id:
            raise ValueError("GITHUB_CLIENT_ID 未配置")

    async def get_authorization_url(self, state: str, redirect_uri: Optional[str] = None) -> str:
        """获取 GitHub OAuth 授权 URL"""
        from urllib.parse import urlencode

        params = {
            "client_id": self.client_id,
            "redirect_uri": redirect_uri or self.default_redirect_uri,
            "response_type": "code",
            "scope": "read:user user:email",
            "state": state,
        }
        return f"{self.AUTH_URL}?{urlencode(params)}"

    async def exchange_code_for_token(self, code: str, redirect_uri: str) -> Dict[str, Any]:
        """用授权码换取访问令牌"""
        if not self.client_secret:
            raise ValueError("GITHUB_CLIENT_SECRET 未配置")

        async with httpx.AsyncClient() as client:
            response = await client.post(
                self.TOKEN_URL,
                data={
                    "code": code,
                    "client_id": self.client_id,
                    "client_secret": self.client_secret,
                    "redirect_uri": redirect_uri,
                },
                headers={"Accept": "application/json"},
            )
            data = response.json()

            if "error" in data:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail=f"GitHub OAuth 错误: {data.get('error_description', data.get('error'))}",
                )

            return data

    async def get_user_info(self, access_token: str) -> Dict[str, Any]:
        """获取 GitHub 用户信息（包含邮箱）"""
        async with httpx.AsyncClient() as client:
            headers = {"Authorization": f"Bearer {access_token}", "Accept": "application/json"}

            # 获取用户基本信息
            user_response = await client.get(self.USER_INFO_URL, headers=headers)
            if user_response.status_code != 200:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST, detail="获取 GitHub 用户信息失败"
                )
            user_data = user_response.json()

            # 获取用户邮箱（因为公开邮箱可能为空）
            email_response = await client.get(self.USER_EMAIL_URL, headers=headers)
            emails = email_response.json() if email_response.status_code == 200 else []

            # 找到主邮箱
            primary_email = next(
                (e.get("email") for e in emails if e.get("primary") and e.get("verified")), None
            )
            verified_email = any(
                e.get("verified", False) for e in emails if e.get("email") == primary_email
            )

            user_data["primary_email"] = primary_email
            user_data["verified_email"] = verified_email

            return user_data

    def normalize_user_info(self, raw_info: Dict[str, Any]) -> Dict[str, Any]:
        """标准化 GitHub 用户信息"""
        return {
            "provider": "github",
            "provider_id": str(raw_info.get("id")),
            "email": raw_info.get("primary_email") or raw_info.get("email"),
            "verified_email": raw_info.get("verified_email", False),
            "name": raw_info.get("name") or raw_info.get("login"),
            "avatar_url": raw_info.get("avatar_url"),
            "login": raw_info.get("login"),
            "bio": raw_info.get("bio"),
        }


class GiteeOAuthProvider(OAuthProvider):
    """Gitee OAuth 提供商

    文档: https://gitee.com/api/v5/oauth_doc
    """

    AUTH_URL = "https://gitee.com/oauth/authorize"
    TOKEN_URL = "https://gitee.com/oauth/token"
    USER_INFO_URL = "https://gitee.com/api/v5/user"
    USER_EMAIL_URL = "https://gitee.com/api/v5/emails"

    def __init__(self):
        super().__init__("gitee")
        self.client_id = getattr(settings, "GITEE_CLIENT_ID", "")
        self.client_secret = getattr(settings, "GITEE_CLIENT_SECRET", "")
        self.default_redirect_uri = getattr(
            settings, "GITEE_REDIRECT_URI", "http://localhost:8000/api/v1/auth/oauth/gitee/callback"
        )

        if not self.client_id:
            raise ValueError("GITEE_CLIENT_ID 未配置")

    async def get_authorization_url(self, state: str, redirect_uri: Optional[str] = None) -> str:
        from urllib.parse import urlencode

        params = {
            "client_id": self.client_id,
            "redirect_uri": redirect_uri or self.default_redirect_uri,
            "response_type": "code",
            "scope": "user_info emails",
            "state": state,
        }
        return f"{self.AUTH_URL}?{urlencode(params)}"

    async def exchange_code_for_token(self, code: str, redirect_uri: str) -> Dict[str, Any]:
        if not self.client_secret:
            raise ValueError("GITEE_CLIENT_SECRET 未配置")

        async with httpx.AsyncClient() as client:
            response = await client.post(
                self.TOKEN_URL,
                data={
                    "code": code,
                    "client_id": self.client_id,
                    "client_secret": self.client_secret,
                    "redirect_uri": redirect_uri,
                    "grant_type": "authorization_code",
                },
                headers={"Accept": "application/json"},
            )
            data = response.json()

            if "error" in data:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail=f"Gitee OAuth 错误: {data.get('error_description', data.get('error'))}",
                )

            return data

    async def get_user_info(self, access_token: str) -> Dict[str, Any]:
        async with httpx.AsyncClient() as client:
            headers = {"Authorization": f"Bearer {access_token}"}

            user_response = await client.get(self.USER_INFO_URL, headers=headers)
            if user_response.status_code != 200:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST, detail="获取 Gitee 用户信息失败"
                )
            user_data = user_response.json()

            # 获取邮箱列表
            email_response = await client.get(self.USER_EMAIL_URL, headers=headers)
            emails = email_response.json() if email_response.status_code == 200 else []

            # 优先取已验证的主邮箱，否则取 Gitee 公开邮箱
            primary_email = None
            for e in emails:
                if isinstance(e, dict) and e.get("primary") and e.get("verified"):
                    primary_email = e.get("email")
                    break
            if not primary_email:
                primary_email = user_data.get("email")

            user_data["primary_email"] = primary_email
            user_data["verified_email"] = bool(primary_email)

            return user_data

    def normalize_user_info(self, raw_info: Dict[str, Any]) -> Dict[str, Any]:
        return {
            "provider": "gitee",
            "provider_id": str(raw_info.get("id")),
            "email": raw_info.get("primary_email") or raw_info.get("email"),
            "verified_email": raw_info.get("verified_email", False),
            "name": raw_info.get("name") or raw_info.get("login"),
            "avatar_url": raw_info.get("avatar_url"),
            "login": raw_info.get("login"),
            "bio": raw_info.get("bio"),
        }


class DiscordOAuthProvider(OAuthProvider):
    """Discord OAuth 提供商

    文档: https://discord.com/developers/docs/topics/oauth2
    """

    AUTH_URL = "https://discord.com/api/oauth2/authorize"
    TOKEN_URL = "https://discord.com/api/oauth2/token"
    USER_INFO_URL = "https://discord.com/api/v10/users/@me"

    def __init__(self):
        super().__init__("discord")
        self.client_id = getattr(settings, "DISCORD_CLIENT_ID", "")
        self.client_secret = getattr(settings, "DISCORD_CLIENT_SECRET", "")
        self.default_redirect_uri = getattr(
            settings,
            "DISCORD_REDIRECT_URI",
            "http://localhost:8000/api/v1/auth/oauth/discord/callback",
        )

        if not self.client_id:
            raise ValueError("DISCORD_CLIENT_ID 未配置")

    async def get_authorization_url(self, state: str, redirect_uri: Optional[str] = None) -> str:
        from urllib.parse import urlencode

        params = {
            "client_id": self.client_id,
            "redirect_uri": redirect_uri or self.default_redirect_uri,
            "response_type": "code",
            "scope": "identify email",
            "state": state,
        }
        return f"{self.AUTH_URL}?{urlencode(params)}"

    async def exchange_code_for_token(self, code: str, redirect_uri: str) -> Dict[str, Any]:
        if not self.client_secret:
            raise ValueError("DISCORD_CLIENT_SECRET 未配置")

        async with httpx.AsyncClient() as client:
            response = await client.post(
                self.TOKEN_URL,
                data={
                    "code": code,
                    "client_id": self.client_id,
                    "client_secret": self.client_secret,
                    "redirect_uri": redirect_uri,
                    "grant_type": "authorization_code",
                },
                headers={"Content-Type": "application/x-www-form-urlencoded"},
            )
            data = response.json()

            if "error" in data:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail=f"Discord OAuth 错误: {data.get('error_description', data.get('error'))}",
                )

            return data

    async def get_user_info(self, access_token: str) -> Dict[str, Any]:
        async with httpx.AsyncClient() as client:
            response = await client.get(
                self.USER_INFO_URL, headers={"Authorization": f"Bearer {access_token}"}
            )
            if response.status_code != 200:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST, detail="获取 Discord 用户信息失败"
                )
            return response.json()

    def normalize_user_info(self, raw_info: Dict[str, Any]) -> Dict[str, Any]:
        # Discord avatar CDN
        avatar_hash = raw_info.get("avatar")
        user_id = raw_info.get("id")
        avatar_url = None
        if avatar_hash and user_id:
            avatar_url = f"https://cdn.discordapp.com/avatars/{user_id}/{avatar_hash}.png"

        return {
            "provider": "discord",
            "provider_id": str(raw_info.get("id")),
            "email": raw_info.get("email"),
            "verified_email": raw_info.get("verified", False),
            "name": raw_info.get("global_name") or raw_info.get("username"),
            "avatar_url": avatar_url,
            "username": raw_info.get("username"),
            "discriminator": raw_info.get("discriminator"),
        }


class QQOAuthProvider(OAuthProvider):
    """QQ 互联 OAuth 提供商(国内个人备案可申请)

    文档: https://wiki.connect.qq.com/
    配置: QQ_CONNECT_APP_ID / QQ_CONNECT_APP_SECRET (QQ互联后台的 AppID/AppKey)
    """

    AUTH_URL = "https://graph.qq.com/oauth2.0/authorize"
    TOKEN_URL = "https://graph.qq.com/oauth2.0/token"
    OPENID_URL = "https://graph.qq.com/oauth2.0/me"
    USER_INFO_URL = "https://graph.qq.com/user/get_user_info"

    def __init__(self):
        super().__init__("qq")
        self.client_id = getattr(settings, "QQ_CONNECT_APP_ID", "")
        self.client_secret = getattr(settings, "QQ_CONNECT_APP_SECRET", "")
        self.default_redirect_uri = getattr(
            settings,
            "QQ_REDIRECT_URI",
            "http://localhost:8000/api/v1/auth/oauth/qq/callback",
        )

        if not self.client_id:
            raise ValueError("QQ_CONNECT_APP_ID 未配置")

    async def get_authorization_url(self, state: str, redirect_uri: Optional[str] = None) -> str:
        from urllib.parse import urlencode

        params = {
            "client_id": self.client_id,
            "redirect_uri": redirect_uri or self.default_redirect_uri,
            "response_type": "code",
            "state": state,
        }
        return f"{self.AUTH_URL}?{urlencode(params)}"

    async def exchange_code_for_token(self, code: str, redirect_uri: str) -> Dict[str, Any]:
        if not self.client_secret:
            raise ValueError("QQ_CONNECT_APP_SECRET 未配置")

        async with httpx.AsyncClient() as client:
            response = await client.get(
                self.TOKEN_URL,
                params={
                    "grant_type": "authorization_code",
                    "client_id": self.client_id,
                    "client_secret": self.client_secret,
                    "code": code,
                    "redirect_uri": redirect_uri,
                    "fmt": "json",
                },
            )
            data = response.json()
            if "error" in data or "error_description" in data:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail=f"QQ OAuth 错误: {data.get('error_description', data.get('error'))}",
                )
            return data

    async def get_user_info(self, access_token: str) -> Dict[str, Any]:
        """QQ 特有两步:先取 openid,再取用户资料"""
        async with httpx.AsyncClient() as client:
            # fmt=json 免剥 callback(...) 包裹
            openid_resp = await client.get(
                self.OPENID_URL, params={"access_token": access_token, "fmt": "json"}
            )
            if openid_resp.status_code != 200:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST, detail="获取 QQ openid 失败"
                )
            openid_data = openid_resp.json()
            openid = openid_data.get("openid")
            if not openid:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST, detail="QQ 返回数据缺少 openid"
                )

            info_resp = await client.get(
                self.USER_INFO_URL,
                params={
                    "access_token": access_token,
                    "oauth_consumer_key": self.client_id,
                    "openid": openid,
                },
            )
            if info_resp.status_code != 200:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST, detail="获取 QQ 用户信息失败"
                )
            info = info_resp.json()
            if info.get("ret") not in (0, "0"):
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail=f"QQ 用户信息错误: {info.get('msg', info.get('ret'))}",
                )
            info["openid"] = openid
            return info

    def normalize_user_info(self, raw_info: Dict[str, Any]) -> Dict[str, Any]:
        return {
            "provider": "qq",
            "provider_id": raw_info.get("openid"),
            "email": None,  # QQ 互联不返回邮箱
            "verified_email": False,
            "name": raw_info.get("nickname") or "QQ用户",
            "avatar_url": raw_info.get("figureurl_qq_2") or raw_info.get("figureurl_qq_1"),
        }


class OAuthStateManager:
    """OAuth State 管理器 - 用于 CSRF 保护

    开发环境使用内存存储，生产环境建议使用 Redis
    """

    def __init__(self):
        self._states: Dict[str, float] = {}  # state -> timestamp
        self.ttl = getattr(settings, "OAUTH_STATE_TTL_SECONDS", 600)

    def generate_state(self) -> str:
        """生成随机 state 参数"""
        state = secrets.token_urlsafe(32)
        self._states[state] = time.time()
        return state

    def validate_and_consume(self, state: str) -> bool:
        """验证并消费 state 参数（一次性使用）"""
        if state not in self._states:
            return False

        timestamp = self._states.pop(state)
        current_time = time.time()

        # 检查是否过期
        if current_time - timestamp > self.ttl:
            return False

        return True

    def cleanup_expired(self):
        """清理过期的 state"""
        current_time = time.time()
        expired = [s for s, t in self._states.items() if current_time - t > self.ttl]
        for state in expired:
            del self._states[state]


# 全局实例
_oauth_state_manager = OAuthStateManager()
_google_provider: Optional[GoogleOAuthProvider] = None
_github_provider: Optional[GitHubOAuthProvider] = None
_gitee_provider: Optional[GiteeOAuthProvider] = None
_discord_provider: Optional[DiscordOAuthProvider] = None
_qq_provider: Optional[QQOAuthProvider] = None


def get_google_provider() -> Optional[GoogleOAuthProvider]:
    global _google_provider
    if _google_provider is None:
        try:
            _google_provider = GoogleOAuthProvider()
        except ValueError:
            return None
    return _google_provider


def get_github_provider() -> Optional[GitHubOAuthProvider]:
    global _github_provider
    if _github_provider is None:
        try:
            _github_provider = GitHubOAuthProvider()
        except ValueError:
            return None
    return _github_provider


def get_gitee_provider() -> Optional[GiteeOAuthProvider]:
    global _gitee_provider
    if _gitee_provider is None:
        try:
            _gitee_provider = GiteeOAuthProvider()
        except ValueError:
            return None
    return _gitee_provider


def get_discord_provider() -> Optional[DiscordOAuthProvider]:
    global _discord_provider
    if _discord_provider is None:
        try:
            _discord_provider = DiscordOAuthProvider()
        except ValueError:
            return None
    return _discord_provider


def get_qq_provider() -> Optional[QQOAuthProvider]:
    global _qq_provider
    if _qq_provider is None:
        try:
            _qq_provider = QQOAuthProvider()
        except ValueError:
            return None
    return _qq_provider


def get_state_manager() -> OAuthStateManager:
    """获取 State 管理器实例"""
    return _oauth_state_manager


async def oauth_login(
    provider: str, code: str, state: str, redirect_uri: Optional[str] = None
) -> Dict[str, Any]:
    """
    通用 OAuth 登录流程

    Returns:
        包含标准化用户信息的字典
    """
    # 验证 state
    state_manager = get_state_manager()
    if not state_manager.validate_and_consume(state):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST, detail="无效或过期的 state 参数"
        )

    # 选择提供商
    if provider == "google":
        provider_instance = get_google_provider()
        if not provider_instance:
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail="Google OAuth 未配置"
            )
        provider_redirect_uri = redirect_uri or provider_instance.default_redirect_uri
    elif provider == "github":
        provider_instance = get_github_provider()
        if not provider_instance:
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail="GitHub OAuth 未配置"
            )
        provider_redirect_uri = redirect_uri or provider_instance.default_redirect_uri
    elif provider == "gitee":
        provider_instance = get_gitee_provider()
        if not provider_instance:
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail="Gitee OAuth 未配置"
            )
        provider_redirect_uri = redirect_uri or provider_instance.default_redirect_uri
    elif provider == "discord":
        provider_instance = get_discord_provider()
        if not provider_instance:
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail="Discord OAuth 未配置"
            )
        provider_redirect_uri = redirect_uri or provider_instance.default_redirect_uri
    elif provider == "qq":
        provider_instance = get_qq_provider()
        if not provider_instance:
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="QQ 登录未配置(需在 QQ 互联创建应用并配置 AppID)",
            )
        provider_redirect_uri = redirect_uri or provider_instance.default_redirect_uri
    else:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST, detail=f"不支持的 OAuth 提供商: {provider}"
        )

    # 交换授权码获取 token
    token_data = await provider_instance.exchange_code_for_token(code, provider_redirect_uri)
    access_token = token_data.get("access_token")

    # 获取用户信息
    user_info = await provider_instance.get_user_info(access_token)

    # 标准化用户信息
    normalized_info = provider_instance.normalize_user_info(user_info)

    return normalized_info
