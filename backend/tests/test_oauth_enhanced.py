"""
OAuth API 增强测试 - 提高覆盖率
"""
import pytest
from unittest.mock import AsyncMock, patch, MagicMock
from httpx import AsyncClient
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from app.models.user import User


class TestGoogleOAuthAuthorize:
    """Google OAuth 授权测试"""

    async def test_google_authorize_success(
        self, client: AsyncClient
    ):
        """测试: 成功获取 Google 授权 URL"""
        mock_provider = AsyncMock()
        mock_provider.get_authorization_url = AsyncMock(
            return_value="https://accounts.google.com/o/oauth2/v2/auth?code=test"
        )

        mock_state_manager = AsyncMock()
        mock_state_manager.generate_state = MagicMock(return_value="test_state_123")

        with patch("app.api.v1.auth_oauth.get_google_provider", return_value=mock_provider), \
             patch("app.api.v1.auth_oauth.get_state_manager", return_value=mock_state_manager):
            response = await client.get("/api/v1/auth/oauth/google/authorize")

            assert response.status_code == 200
            data = response.json()
            assert data["code"] == 0
            assert data["data"]["auth_url"]
            assert data["data"]["state"] == "test_state_123"
            assert data["data"]["provider"] == "google"

    async def test_google_authorize_not_configured(
        self, client: AsyncClient
    ):
        """测试: Google OAuth 未配置"""
        with patch("app.api.v1.auth_oauth.get_google_provider", return_value=None):
            response = await client.get("/api/v1/auth/oauth/google/authorize")

            assert response.status_code == 500
            data = response.json()
            assert "Google OAuth 未配置" in data["detail"]


class TestGoogleOAuthCallback:
    """Google OAuth 回调测试"""

    async def test_google_callback_new_user(
        self, client: AsyncClient, db_session
    ):
        """测试: Google 回调创建新用户"""
        mock_provider_info = {
            "provider_id": "google_12345",
            "email": "googleuser@example.com",
            "name": "Google User",
            "avatar_url": "https://example.com/avatar.jpg",
            "verified_email": True
        }

        mock_oauth_service = AsyncMock()
        mock_oauth_service.oauth_login = AsyncMock(return_value=mock_provider_info)

        with patch("app.api.v1.auth_oauth.oauth_login", new=lambda *args, **kwargs: mock_oauth_service.oauth_login()):
            response = await client.post(
                "/api/v1/auth/oauth/google/callback",
                json={
                    "code": "test_code",
                    "state": "test_state",
                    "redirect_uri": "http://localhost:8080/callback"
                }
            )

            assert response.status_code == 200
            data = response.json()
            assert data["code"] == 0
            assert "access_token" in data["data"]

    async def test_google_callback_existing_user(
        self, client: AsyncClient, test_user, db_session
    ):
        """测试: Google 回调登录已有用户"""
        # 为测试用户设置 google_id
        test_user.google_id = "google_existing_123"
        await db_session.commit()

        mock_provider_info = {
            "provider_id": "google_existing_123",
            "email": test_user.email,
            "name": test_user.username,
            "verified_email": True
        }

        with patch("app.api.v1.auth_oauth.oauth_login", return_value=mock_provider_info):
            response = await client.post(
                "/api/v1/auth/oauth/google/callback",
                json={
                    "code": "test_code",
                    "state": "test_state"
                }
            )

            assert response.status_code == 200

    async def test_google_callback_email_already_registered(
        self, client: AsyncClient, test_user, db_session
    ):
        """测试: Google 邮箱已被注册"""
        mock_provider_info = {
            "provider_id": "google_new_123",
            "email": test_user.email,  # 使用已有用户的邮箱
            "name": "New User",
            "verified_email": True
        }

        with patch("app.api.v1.auth_oauth.oauth_login", return_value=mock_provider_info):
            response = await client.post(
                "/api/v1/auth/oauth/google/callback",
                json={
                    "code": "test_code",
                    "state": "test_state"
                }
            )

            assert response.status_code == 400
            data = response.json()
            assert "该邮箱已被注册" in data["detail"]


class TestGoogleBindUnbind:
    """Google 绑定/解绑测试"""

    async def test_google_bind_success(
        self, client: AsyncClient, auth_headers, test_user
    ):
        """测试: 成功绑定 Google 账号"""
        mock_provider_info = {
            "provider_id": "google_bind_123",
            "email": "bind@example.com",
            "avatar_url": "https://example.com/avatar.jpg"
        }

        with patch("app.api.v1.auth_oauth.oauth_login", return_value=mock_provider_info):
            response = await client.post(
                "/api/v1/auth/oauth/google/bind",
                headers=auth_headers,
                json={
                    "code": "test_code",
                    "state": "test_state"
                }
            )

            assert response.status_code == 200
            data = response.json()
            assert data["code"] == 0

    async def test_google_bind_already_bound_to_others(
        self, client: AsyncClient, auth_headers, db_session
    ):
        """测试: Google 账号已被其他用户绑定"""
        from app.models.user import User

        # 创建另一个已绑定 Google 的用户
        other_user = User(
            email="other@example.com",
            password_hash="hash",
            username="other",
            google_id="google_taken_123"
        )
        db_session.add(other_user)
        await db_session.commit()

        mock_provider_info = {
            "provider_id": "google_taken_123",
            "email": "taken@example.com"
        }

        with patch("app.api.v1.auth_oauth.oauth_login", return_value=mock_provider_info):
            response = await client.post(
                "/api/v1/auth/oauth/google/bind",
                headers=auth_headers,
                json={
                    "code": "test_code",
                    "state": "test_state"
                }
            )

            assert response.status_code == 400

    async def test_google_unbind_success(
        self, client: AsyncClient, auth_headers, test_user, db_session
    ):
        """测试: 成功解绑 Google 账号"""
        # 先绑定 Google
        test_user.google_id = "google_unbind_123"
        test_user.google_email = "unbind@example.com"
        await db_session.commit()

        response = await client.post(
            "/api/v1/auth/oauth/google/unbind",
            headers=auth_headers
        )

        assert response.status_code == 200
        data = response.json()
        assert "解绑成功" in data["message"]

    async def test_google_unbind_not_bound(
        self, client: AsyncClient, auth_headers
    ):
        """测试: 解绑未绑定的 Google 账号"""
        response = await client.post(
            "/api/v1/auth/oauth/google/unbind",
            headers=auth_headers
        )

        assert response.status_code == 400
        data = response.json()
        assert "未绑定" in data["detail"]

    async def test_google_bind_unauthorized(
        self, client: AsyncClient
    ):
        """测试: 未认证绑定"""
        response = await client.post(
            "/api/v1/auth/oauth/google/bind",
            json={"code": "test", "state": "test"}
        )

        assert response.status_code == 401


class TestGitHubOAuthAuthorize:
    """GitHub OAuth 授权测试"""

    async def test_github_authorize_success(
        self, client: AsyncClient
    ):
        """测试: 成功获取 GitHub 授权 URL"""
        mock_provider = AsyncMock()
        mock_provider.get_authorization_url = AsyncMock(
            return_value="https://github.com/login/oauth/authorize?code=test"
        )

        mock_state_manager = AsyncMock()
        mock_state_manager.generate_state = MagicMock(return_value="github_state_123")

        with patch("app.api.v1.auth_oauth.get_github_provider", return_value=mock_provider), \
             patch("app.api.v1.auth_oauth.get_state_manager", return_value=mock_state_manager):
            response = await client.get("/api/v1/auth/oauth/github/authorize")

            assert response.status_code == 200
            data = response.json()
            assert data["code"] == 0
            assert data["data"]["provider"] == "github"

    async def test_github_authorize_not_configured(
        self, client: AsyncClient
    ):
        """测试: GitHub OAuth 未配置"""
        with patch("app.api.v1.auth_oauth.get_github_provider", return_value=None):
            response = await client.get("/api/v1/auth/oauth/github/authorize")

            assert response.status_code == 500
            data = response.json()
            assert "GitHub OAuth 未配置" in data["detail"]


class TestGitHubOAuthCallback:
    """GitHub OAuth 回调测试"""

    async def test_github_callback_new_user(
        self, client: AsyncClient
    ):
        """测试: GitHub 回调创建新用户"""
        mock_provider_info = {
            "provider_id": "12345",
            "email": "githubuser@example.com",
            "name": "GitHub User",
            "login": "githubuser",
            "avatar_url": "https://github.com/avatar.png",
            "verified_email": True
        }

        with patch("app.api.v1.auth_oauth.oauth_login", return_value=mock_provider_info):
            response = await client.post(
                "/api/v1/auth/oauth/github/callback",
                json={
                    "code": "test_code",
                    "state": "test_state"
                }
            )

            assert response.status_code == 200
            data = response.json()
            assert "access_token" in data["data"]

    async def test_github_callback_existing_user(
        self, client: AsyncClient, test_user, db_session
    ):
        """测试: GitHub 回调登录已有用户"""
        test_user.github_id = 99999
        await db_session.commit()

        mock_provider_info = {
            "provider_id": "99999",
            "email": test_user.email,
            "login": "testuser"
        }

        with patch("app.api.v1.auth_oauth.oauth_login", return_value=mock_provider_info):
            response = await client.post(
                "/api/v1/auth/oauth/github/callback",
                json={
                    "code": "test_code",
                    "state": "test_state"
                }
            )

            assert response.status_code == 200

    async def test_github_callback_email_conflict(
        self, client: AsyncClient, test_user
    ):
        """测试: GitHub 邮箱已被注册"""
        mock_provider_info = {
            "provider_id": "54321",
            "email": test_user.email,
            "login": "newuser"
        }

        with patch("app.api.v1.auth_oauth.oauth_login", return_value=mock_provider_info):
            response = await client.post(
                "/api/v1/auth/oauth/github/callback",
                json={
                    "code": "test_code",
                    "state": "test_state"
                }
            )

            assert response.status_code == 400


class TestGitHubBindUnbind:
    """GitHub 绑定/解绑测试"""

    async def test_github_bind_success(
        self, client: AsyncClient, auth_headers
    ):
        """测试: 成功绑定 GitHub 账号"""
        mock_provider_info = {
            "provider_id": "11111",
            "login": "testbind",
            "email": "bind@example.com",
            "avatar_url": "https://example.com/avatar.jpg"
        }

        with patch("app.api.v1.auth_oauth.oauth_login", return_value=mock_provider_info):
            response = await client.post(
                "/api/v1/auth/oauth/github/bind",
                headers=auth_headers,
                json={
                    "code": "test_code",
                    "state": "test_state"
                }
            )

            assert response.status_code == 200

    async def test_github_bind_already_bound(
        self, client: AsyncClient, auth_headers, db_session
    ):
        """测试: GitHub 账号已被其他用户绑定"""
        from app.models.user import User

        other_user = User(
            email="githubother@example.com",
            password_hash="hash",
            username="githubother",
            github_id=22222
        )
        db_session.add(other_user)
        await db_session.commit()

        mock_provider_info = {
            "provider_id": "22222",
            "login": "taken"
        }

        with patch("app.api.v1.auth_oauth.oauth_login", return_value=mock_provider_info):
            response = await client.post(
                "/api/v1/auth/oauth/github/bind",
                headers=auth_headers,
                json={
                    "code": "test_code",
                    "state": "test_state"
                }
            )

            assert response.status_code == 400

    async def test_github_unbind_success(
        self, client: AsyncClient, auth_headers, test_user, db_session
    ):
        """测试: 成功解绑 GitHub 账号"""
        test_user.github_id = 33333
        test_user.github_login = "testuser"
        await db_session.commit()

        response = await client.post(
            "/api/v1/auth/oauth/github/unbind",
            headers=auth_headers
        )

        assert response.status_code == 200

    async def test_github_unbind_not_bound(
        self, client: AsyncClient, auth_headers
    ):
        """测试: 解绑未绑定的 GitHub 账号"""
        response = await client.post(
            "/api/v1/auth/oauth/github/unbind",
            headers=auth_headers
        )

        assert response.status_code == 400

    async def test_github_bind_unauthorized(
        self, client: AsyncClient
    ):
        """测试: 未认证绑定 GitHub"""
        response = await client.post(
            "/api/v1/auth/oauth/github/bind",
            json={"code": "test", "state": "test"}
        )

        assert response.status_code == 401


class TestOAuthCommon:
    """OAuth 通用测试"""

    async def test_unauthorized_unbind_google(
        self, client: AsyncClient
    ):
        """测试: 未认证解绑 Google"""
        response = await client.post("/api/v1/auth/oauth/google/unbind")

        assert response.status_code == 401

    async def test_unauthorized_unbind_github(
        self, client: AsyncClient
    ):
        """测试: 未认证解绑 GitHub"""
        response = await client.post("/api/v1/auth/oauth/github/unbind")

        assert response.status_code == 401
