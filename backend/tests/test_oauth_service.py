"""
OAuth 服务单元测试
"""
import pytest
from unittest.mock import AsyncMock, patch, MagicMock
from datetime import datetime
import time

from app.services.oauth_service import (
    GoogleOAuthProvider,
    GitHubOAuthProvider,
    OAuthStateManager,
    get_google_provider,
    get_github_provider,
    get_state_manager,
    oauth_login
)
from fastapi import HTTPException


class TestGoogleOAuthProvider:
    """Google OAuth 提供商测试"""

    @pytest.fixture
    def mock_settings(self):
        """Mock settings for Google OAuth"""
        with patch("app.services.oauth_service.settings") as mock:
            mock.GOOGLE_CLIENT_ID = "test_google_client_id"
            mock.GOOGLE_CLIENT_SECRET = "test_google_secret"
            mock.GOOGLE_REDIRECT_URI = "http://localhost:8000/api/v1/auth/google/callback"
            yield mock

    def test_init_with_client_id(self, mock_settings):
        """测试: 使用 client_id 初始化"""
        provider = GoogleOAuthProvider()
        assert provider.name == "google"
        assert provider.client_id == "test_google_client_id"

    def test_init_without_client_id_raises_error(self):
        """测试: 没有 client_id 抛出错误"""
        with patch("app.services.oauth_service.settings") as mock:
            mock.GOOGLE_CLIENT_ID = ""
            with pytest.raises(ValueError, match="GOOGLE_CLIENT_ID 未配置"):
                GoogleOAuthProvider()

    def test_get_authorization_url_default_redirect(self, mock_settings):
        """测试: 获取授权 URL 使用默认回调"""
        provider = GoogleOAuthProvider()
        import asyncio
        url = asyncio.run(provider.get_authorization_url("test_state"))

        assert "accounts.google.com/o/oauth2/v2/auth" in url
        assert "test_state" in url
        assert "test_google_client_id" in url
        # URL 编码后的 scope
        assert "scope=openid+email+profile" in url

    def test_get_authorization_url_custom_redirect(self, mock_settings):
        """测试: 获取授权 URL 使用自定义回调"""
        provider = GoogleOAuthProvider()
        import asyncio
        custom_uri = "http://custom.example.com/callback"
        url = asyncio.run(provider.get_authorization_url("test_state", custom_uri))

        # URL 编码后的回调地址
        assert "custom.example.com" in url

    @pytest.mark.asyncio
    async def test_exchange_code_for_token_success(self, mock_settings):
        """测试: 成功交换授权码获取 token"""
        mock_response = MagicMock()
        mock_response.json.return_value = {
            "access_token": "test_access_token",
            "refresh_token": "test_refresh_token",
            "expires_in": 3600
        }

        with patch("httpx.AsyncClient") as mock_client:
            mock_client.return_value.__aenter__.return_value.post.return_value = mock_response

            provider = GoogleOAuthProvider()
            result = await provider.exchange_code_for_token("test_code", "http://localhost:8000/callback")

            assert result["access_token"] == "test_access_token"

    @pytest.mark.asyncio
    async def test_exchange_code_for_token_error_response(self, mock_settings):
        """测试: 交换授权码时返回错误"""
        mock_response = MagicMock()
        mock_response.json.return_value = {
            "error": "invalid_grant",
            "error_description": "The code has expired"
        }

        with patch("httpx.AsyncClient") as mock_client:
            mock_client.return_value.__aenter__.return_value.post.return_value = mock_response

            provider = GoogleOAuthProvider()
            with pytest.raises(HTTPException, match="Google OAuth 错误"):
                await provider.exchange_code_for_token("invalid_code", "http://localhost:8000/callback")

    @pytest.mark.asyncio
    async def test_exchange_code_without_secret_raises_error(self, mock_settings):
        """测试: 没有 client_secret 抛出错误"""
        mock_settings.GOOGLE_CLIENT_SECRET = ""

        provider = GoogleOAuthProvider()
        with pytest.raises(ValueError, match="GOOGLE_CLIENT_SECRET 未配置"):
            await provider.exchange_code_for_token("test_code", "http://localhost:8000/callback")

    @pytest.mark.asyncio
    async def test_get_user_info_success(self, mock_settings):
        """测试: 成功获取用户信息"""
        mock_response = MagicMock()
        mock_response.status_code = 200
        mock_response.json.return_value = {
            "id": "123456789",
            "email": "test@example.com",
            "verified_email": True,
            "name": "Test User",
            "picture": "http://example.com/avatar.jpg"
        }

        with patch("httpx.AsyncClient") as mock_client:
            mock_client.return_value.__aenter__.return_value.get.return_value = mock_response

            provider = GoogleOAuthProvider()
            result = await provider.get_user_info("test_token")

            assert result["email"] == "test@example.com"
            assert result["verified_email"] is True

    @pytest.mark.asyncio
    async def test_get_user_info_http_error(self, mock_settings):
        """测试: 获取用户信息时 HTTP 错误"""
        mock_response = MagicMock()
        mock_response.status_code = 401

        with patch("httpx.AsyncClient") as mock_client:
            mock_client.return_value.__aenter__.return_value.get.return_value = mock_response

            provider = GoogleOAuthProvider()
            with pytest.raises(HTTPException, match="获取 Google 用户信息失败"):
                await provider.get_user_info("invalid_token")

    def test_normalize_user_info(self, mock_settings):
        """测试: 标准化用户信息"""
        provider = GoogleOAuthProvider()
        raw_info = {
            "id": "google_123",
            "email": "user@example.com",
            "verified_email": True,
            "name": "Google User",
            "picture": "http://example.com/pic.jpg",
            "locale": "zh-CN"
        }

        result = provider.normalize_user_info(raw_info)

        assert result["provider"] == "google"
        assert result["provider_id"] == "google_123"
        assert result["email"] == "user@example.com"
        assert result["verified_email"] is True
        assert result["name"] == "Google User"
        assert result["avatar_url"] == "http://example.com/pic.jpg"
        assert result["locale"] == "zh-CN"


class TestGitHubOAuthProvider:
    """GitHub OAuth 提供商测试"""

    @pytest.fixture
    def mock_settings(self):
        """Mock settings for GitHub OAuth"""
        with patch("app.services.oauth_service.settings") as mock:
            mock.GITHUB_CLIENT_ID = "test_github_client_id"
            mock.GITHUB_CLIENT_SECRET = "test_github_secret"
            mock.GITHUB_REDIRECT_URI = "http://localhost:8000/api/v1/auth/github/callback"
            yield mock

    def test_init_with_client_id(self, mock_settings):
        """测试: 使用 client_id 初始化"""
        provider = GitHubOAuthProvider()
        assert provider.name == "github"
        assert provider.client_id == "test_github_client_id"

    def test_init_without_client_id_raises_error(self):
        """测试: 没有 client_id 抛出错误"""
        with patch("app.services.oauth_service.settings") as mock:
            mock.GITHUB_CLIENT_ID = ""
            with pytest.raises(ValueError, match="GITHUB_CLIENT_ID 未配置"):
                GitHubOAuthProvider()

    def test_get_authorization_url(self, mock_settings):
        """测试: 获取 GitHub 授权 URL"""
        provider = GitHubOAuthProvider()
        import asyncio
        url = asyncio.run(provider.get_authorization_url("test_state"))

        assert "github.com/login/oauth/authorize" in url
        assert "test_state" in url
        assert "test_github_client_id" in url
        # URL 编码后的 scope
        assert "scope=read%3Auser+user%3Aemail" in url or "scope=read:user+user:email" in url

    @pytest.mark.asyncio
    async def test_exchange_code_for_token_success(self, mock_settings):
        """测试: 成功交换授权码获取 token"""
        mock_response = MagicMock()
        mock_response.json.return_value = {
            "access_token": "github_access_token",
            "token_type": "bearer",
            "scope": "read:user user:email"
        }

        with patch("httpx.AsyncClient") as mock_client:
            mock_client.return_value.__aenter__.return_value.post.return_value = mock_response

            provider = GitHubOAuthProvider()
            result = await provider.exchange_code_for_token("test_code", "http://localhost:8000/callback")

            assert result["access_token"] == "github_access_token"

    @pytest.mark.asyncio
    async def test_get_user_info_with_emails(self, mock_settings):
        """测试: 获取用户信息包含邮箱"""
        user_response = MagicMock()
        user_response.status_code = 200
        user_response.json.return_value = {
            "id": 12345,
            "login": "githubuser",
            "name": "GitHub User",
            "email": None,  # 公开邮箱为空
            "avatar_url": "http://github.com/avatar.png"
        }

        email_response = MagicMock()
        email_response.status_code = 200
        email_response.json.return_value = [
            {
                "email": "private@example.com",
                "primary": True,
                "verified": True
            },
            {
                "email": "other@example.com",
                "primary": False,
                "verified": True
            }
        ]

        async def mock_get(url, headers):
            if "user" in url and "emails" not in url:
                return user_response
            else:
                return email_response

        with patch("httpx.AsyncClient") as mock_client:
            mock_client.return_value.__aenter__.return_value.get.side_effect = mock_get

            provider = GitHubOAuthProvider()
            result = await provider.get_user_info("test_token")

            assert result["primary_email"] == "private@example.com"
            assert result["verified_email"] is True

    @pytest.mark.asyncio
    async def test_get_user_info_with_public_email(self, mock_settings):
        """测试: 使用公开邮箱"""
        user_response = MagicMock()
        user_response.status_code = 200
        user_response.json.return_value = {
            "id": 12345,
            "login": "githubuser",
            "name": "GitHub User",
            "email": "public@example.com",
            "avatar_url": "http://github.com/avatar.png"
        }

        email_response = MagicMock()
        email_response.status_code = 200
        email_response.json.return_value = []

        async def mock_get(url, headers):
            if "emails" in url:
                return email_response
            else:
                return user_response

        with patch("httpx.AsyncClient") as mock_client:
            mock_client.return_value.__aenter__.return_value.get.side_effect = mock_get

            provider = GitHubOAuthProvider()
            result = await provider.get_user_info("test_token")

            assert result["primary_email"] is None  # 没有 primary 邮箱

    def test_normalize_user_info(self, mock_settings):
        """测试: 标准化 GitHub 用户信息"""
        provider = GitHubOAuthProvider()
        raw_info = {
            "id": 12345,
            "login": "githubuser",
            "name": "GitHub Name",
            "email": "github@example.com",
            "avatar_url": "http://github.com/pic.png",
            "bio": "Developer",
            "primary_email": "primary@example.com",
            "verified_email": True
        }

        result = provider.normalize_user_info(raw_info)

        assert result["provider"] == "github"
        assert result["provider_id"] == "12345"
        assert result["email"] == "primary@example.com"
        assert result["verified_email"] is True
        assert result["name"] == "GitHub Name"
        assert result["avatar_url"] == "http://github.com/pic.png"
        assert result["login"] == "githubuser"
        assert result["bio"] == "Developer"

    def test_normalize_user_info_fallback_to_login(self, mock_settings):
        """测试: 标准化时 fallback 到 login 作为名字"""
        provider = GitHubOAuthProvider()
        raw_info = {
            "id": 12345,
            "login": "githubuser",
            "name": None,
            "email": "github@example.com"
        }

        result = provider.normalize_user_info(raw_info)

        assert result["name"] == "githubuser"


class TestOAuthStateManager:
    """OAuth State 管理器测试"""

    @pytest.fixture
    def state_manager(self):
        """创建 state 管理器实例"""
        return OAuthStateManager()

    def test_generate_state(self, state_manager):
        """测试: 生成 state"""
        state = state_manager.generate_state()

        assert isinstance(state, str)
        assert len(state) > 0
        assert state in state_manager._states

    def test_validate_and_consume_valid_state(self, state_manager):
        """测试: 验证并消费有效的 state"""
        state = state_manager.generate_state()

        result = state_manager.validate_and_consume(state)

        assert result is True
        assert state not in state_manager._states  # 应该被消费（删除）

    def test_validate_and_consume_invalid_state(self, state_manager):
        """测试: 验证无效的 state"""
        result = state_manager.validate_and_consume("invalid_state")

        assert result is False

    def test_validate_and_consume_expired_state(self):
        """测试: 验证过期的 state"""
        # 创建一个短 TTL 的管理器
        with patch("app.services.oauth_service.settings") as mock:
            mock.OAUTH_STATE_TTL_SECONDS = 0.1  # 100ms
            manager = OAuthStateManager()
            state = manager.generate_state()

            # 等待过期
            time.sleep(0.15)

            result = manager.validate_and_consume(state)

            assert result is False

    def test_validate_and_consume_twice_fails(self, state_manager):
        """测试: state 只能使用一次"""
        state = state_manager.generate_state()

        # 第一次成功
        result1 = state_manager.validate_and_consume(state)
        assert result1 is True

        # 第二次失败
        result2 = state_manager.validate_and_consume(state)
        assert result2 is False

    def test_cleanup_expired(self):
        """测试: 清理过期的 state"""
        with patch("app.services.oauth_service.settings") as mock:
            mock.OAUTH_STATE_TTL_SECONDS = 0.1
            manager = OAuthStateManager()

            # 生成一些 state
            state1 = manager.generate_state()
            state2 = manager.generate_state()

            # 等待过期
            time.sleep(0.15)

            # 生成新的 state
            state3 = manager.generate_state()

            # 清理
            manager.cleanup_expired()

            # 过期的应该被删除
            assert state1 not in manager._states
            assert state2 not in manager._states
            # 新的应该还在
            assert state3 in manager._states


class TestGetProviderFunctions:
    """获取提供商函数测试"""

    def test_get_google_provider_with_config(self):
        """测试: 获取配置好的 Google 提供商"""
        with patch("app.services.oauth_service.settings") as mock:
            mock.GOOGLE_CLIENT_ID = "test_id"
            mock.GOOGLE_CLIENT_SECRET = "test_secret"
            mock.GOOGLE_REDIRECT_URI = "http://localhost:8000/callback"

            # 重置全局变量
            import app.services.oauth_service as oauth_module
            oauth_module._google_provider = None

            provider = get_google_provider()

            assert provider is not None
            assert provider.name == "google"

    def test_get_google_provider_without_config(self):
        """测试: 没有配置时返回 None"""
        with patch("app.services.oauth_service.settings") as mock:
            mock.GOOGLE_CLIENT_ID = ""

            # 重置全局变量
            import app.services.oauth_service as oauth_module
            oauth_module._google_provider = None

            provider = get_google_provider()

            assert provider is None

    def test_get_github_provider_with_config(self):
        """测试: 获取配置好的 GitHub 提供商"""
        with patch("app.services.oauth_service.settings") as mock:
            mock.GITHUB_CLIENT_ID = "test_id"
            mock.GITHUB_CLIENT_SECRET = "test_secret"
            mock.GITHUB_REDIRECT_URI = "http://localhost:8000/callback"

            # 重置全局变量
            import app.services.oauth_service as oauth_module
            oauth_module._github_provider = None

            provider = get_github_provider()

            assert provider is not None
            assert provider.name == "github"

    def test_get_github_provider_without_config(self):
        """测试: 没有配置时返回 None"""
        with patch("app.services.oauth_service.settings") as mock:
            mock.GITHUB_CLIENT_ID = ""

            # 重置全局变量
            import app.services.oauth_service as oauth_module
            oauth_module._github_provider = None

            provider = get_github_provider()

            assert provider is None

    def test_get_state_manager(self):
        """测试: 获取 state 管理器"""
        manager = get_state_manager()

        assert isinstance(manager, OAuthStateManager)
        assert manager is get_state_manager()  # 应该是同一个实例


class TestOauthLogin:
    """OAuth 登录流程测试"""

    @pytest.mark.asyncio
    async def test_oauth_login_google_success(self):
        """测试: Google OAuth 登录成功"""
        mock_provider = MagicMock()
        mock_provider.exchange_code_for_token = AsyncMock(return_value={
            "access_token": "test_token"
        })
        mock_provider.get_user_info = AsyncMock(return_value={
            "id": "google_123",
            "email": "test@example.com",
            "verified_email": True,
            "name": "Test User"
        })
        mock_provider.normalize_user_info = MagicMock(return_value={
            "provider": "google",
            "email": "test@example.com"
        })
        mock_provider.default_redirect_uri = "http://localhost:8000/callback"

        mock_state_manager = MagicMock()
        mock_state_manager.validate_and_consume.return_value = True

        with patch("app.services.oauth_service.get_google_provider", return_value=mock_provider), \
             patch("app.services.oauth_service.get_state_manager", return_value=mock_state_manager):

            result = await oauth_login("google", "test_code", "valid_state")

            assert result["provider"] == "google"
            mock_provider.exchange_code_for_token.assert_called_once()
            mock_provider.get_user_info.assert_called_once()

    @pytest.mark.asyncio
    async def test_oauth_login_invalid_state(self):
        """测试: 无效的 state 参数"""
        mock_state_manager = MagicMock()
        mock_state_manager.validate_and_consume.return_value = False

        with patch("app.services.oauth_service.get_state_manager", return_value=mock_state_manager):
            with pytest.raises(HTTPException, match="无效或过期的 state 参数"):
                await oauth_login("google", "test_code", "invalid_state")

    @pytest.mark.asyncio
    async def test_oauth_login_unsupported_provider(self):
        """测试: 不支持的提供商"""
        mock_state_manager = MagicMock()
        mock_state_manager.validate_and_consume.return_value = True

        with patch("app.services.oauth_service.get_state_manager", return_value=mock_state_manager):
            with pytest.raises(HTTPException, match="不支持的 OAuth 提供商"):
                await oauth_login("unsupported", "test_code", "valid_state")

    @pytest.mark.asyncio
    async def test_oauth_login_google_not_configured(self):
        """测试: Google 未配置"""
        mock_state_manager = MagicMock()
        mock_state_manager.validate_and_consume.return_value = True

        with patch("app.services.oauth_service.get_google_provider", return_value=None), \
             patch("app.services.oauth_service.get_state_manager", return_value=mock_state_manager):

            with pytest.raises(HTTPException, match="Google OAuth 未配置"):
                await oauth_login("google", "test_code", "valid_state")

    @pytest.mark.asyncio
    async def test_oauth_login_custom_redirect_uri(self):
        """测试: 使用自定义回调 URI"""
        mock_provider = MagicMock()
        mock_provider.exchange_code_for_token = AsyncMock(return_value={
            "access_token": "test_token"
        })
        mock_provider.get_user_info = AsyncMock(return_value={})
        mock_provider.normalize_user_info = MagicMock(return_value={})
        mock_provider.default_redirect_uri = "http://default.com/callback"

        mock_state_manager = MagicMock()
        mock_state_manager.validate_and_consume.return_value = True

        with patch("app.services.oauth_service.get_google_provider", return_value=mock_provider), \
             patch("app.services.oauth_service.get_state_manager", return_value=mock_state_manager):

            await oauth_login(
                "google",
                "test_code",
                "valid_state",
                redirect_uri="http://custom.com/callback"
            )

            # 验证使用了自定义 URI
            mock_provider.exchange_code_for_token.assert_called_once()
            call_args = mock_provider.exchange_code_for_token.call_args
            assert call_args[0][1] == "http://custom.com/callback"
