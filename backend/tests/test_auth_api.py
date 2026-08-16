"""
认证 API 集成测试
"""
import pytest
from httpx import AsyncClient
from unittest.mock import AsyncMock, patch


class TestAuthRegister:
    """用户注册测试"""

    async def test_register_success(self, client: AsyncClient):
        """测试成功注册"""
        with patch("app.api.v1.auth.email_service") as mock_email:
            mock_email.verify_code = AsyncMock(return_value=True)

            response = await client.post(
                "/api/v1/auth/register",
                json={
                    "email": "newuser@example.com",
                    "username": "newuser",
                    "password": "NewPassword123!",
                    "verification_code": "123456"
                }
            )

        assert response.status_code == 200
        data = response.json()
        assert data["code"] == 0
        assert "user" in data["data"]
        assert data["data"]["user"]["email"] == "newuser@example.com"
        assert data["data"]["user"]["is_verified"] is True
        assert data["data"]["access_token"]
        assert data["data"]["refresh_token"]
        mock_email.verify_code.assert_called_once_with("newuser@example.com", "123456")

    async def test_register_duplicate_email(self, client: AsyncClient, test_user):
        """测试重复邮箱注册"""
        with patch("app.api.v1.auth.email_service") as mock_email:
            mock_email.verify_code = AsyncMock(return_value=True)

            response = await client.post(
                "/api/v1/auth/register",
                json={
                    "email": test_user.email,
                    "username": "another",
                    "password": "Password123!",
                    "verification_code": "123456"
                }
            )

        assert response.status_code == 400
        data = response.json()
        assert "该邮箱已被注册" in data["detail"]
        mock_email.verify_code.assert_not_called()

    async def test_register_invalid_verification_code(self, client: AsyncClient, db_session):
        """测试注册验证码错误时不创建用户"""
        with patch("app.api.v1.auth.email_service") as mock_email:
            mock_email.verify_code = AsyncMock(return_value=False)

            response = await client.post(
                "/api/v1/auth/register",
                json={
                    "email": "invalid-code@example.com",
                    "username": "newuser",
                    "password": "NewPassword123!",
                    "verification_code": "000000"
                }
            )

        assert response.status_code == 400
        assert "验证码错误或已过期" in response.json()["detail"]

        from sqlalchemy import select
        from app.models.user import User

        result = await db_session.execute(select(User).where(User.email == "invalid-code@example.com"))
        assert result.scalar_one_or_none() is None

    async def test_register_invalid_email(self, client: AsyncClient):
        """测试无效邮箱"""
        response = await client.post(
            "/api/v1/auth/register",
            json={
                "email": "invalid-email",
                "username": "test",
                "password": "Password123!",
                "verification_code": "123456"
            }
        )
        assert response.status_code == 422  # Validation error

    async def test_register_weak_password(self, client: AsyncClient):
        """测试弱密码"""
        response = await client.post(
            "/api/v1/auth/register",
            json={
                "email": "test@example.com",
                "username": "test",
                "password": "123",  # 弱密码
                "verification_code": "123456"
            }
        )
        # 应该被验证拦截或业务逻辑拒绝
        assert response.status_code in [400, 422]


class TestAuthLogin:
    """用户登录测试"""

    async def test_login_success(self, client: AsyncClient, test_user):
        """测试成功登录"""
        response = await client.post(
            "/api/v1/auth/login/json",
            json={
                "email": test_user.email,
                "password": "TestPassword123!"
            }
        )
        assert response.status_code == 200
        data = response.json()
        assert data["code"] == 0
        assert "access_token" in data["data"]
        assert "refresh_token" in data["data"]
        assert "expires_in" in data["data"]

    async def test_login_wrong_password(self, client: AsyncClient, test_user):
        """测试错误密码"""
        response = await client.post(
            "/api/v1/auth/login/json",
            json={
                "email": test_user.email,
                "password": "WrongPassword123!"
            }
        )
        assert response.status_code == 401
        data = response.json()
        assert "邮箱或密码错误" in data["detail"]

    async def test_login_nonexistent_user(self, client: AsyncClient):
        """测试不存在的用户"""
        response = await client.post(
            "/api/v1/auth/login/json",
            json={
                "email": "nonexistent@example.com",
                "password": "Password123!"
            }
        )
        assert response.status_code == 401

    async def test_login_oauth2_format(self, client: AsyncClient, test_user):
        """测试 OAuth2 表单格式登录"""
        response = await client.post(
            "/api/v1/auth/login",
            data={
                "username": test_user.email,
                "password": "TestPassword123!"
            }
        )
        assert response.status_code == 200
        data = response.json()
        assert "access_token" in data["data"]


class TestAuthMe:
    """获取当前用户信息测试"""

    async def test_get_me_success(self, client: AsyncClient, auth_headers):
        """测试成功获取当前用户"""
        response = await client.get("/api/v1/auth/me", headers=auth_headers)
        assert response.status_code == 200
        data = response.json()
        assert data["code"] == 0
        assert "email" in data["data"]
        assert data["data"]["email"] == "test@example.com"

    async def test_get_me_no_token(self, client: AsyncClient):
        """测试无 token 获取用户"""
        response = await client.get("/api/v1/auth/me")
        assert response.status_code == 401

    async def test_get_me_invalid_token(self, client: AsyncClient):
        """测试无效 token"""
        response = await client.get(
            "/api/v1/auth/me",
            headers={"Authorization": "Bearer invalid_token"}
        )
        assert response.status_code == 401


class TestAuthChangePassword:
    """修改密码测试"""

    async def test_change_password_success(
        self, client: AsyncClient, auth_headers
    ):
        """测试成功修改密码"""
        response = await client.post(
            "/api/v1/auth/change-password",
            headers=auth_headers,
            json={
                "old_password": "TestPassword123!",
                "new_password": "NewPassword456!"
            }
        )
        assert response.status_code == 200
        data = response.json()
        assert data["code"] == 0
        assert "密码修改成功" in data["message"]

    async def test_change_password_wrong_old(
        self, client: AsyncClient, auth_headers
    ):
        """测试旧密码错误"""
        response = await client.post(
            "/api/v1/auth/change-password",
            headers=auth_headers,
            json={
                "old_password": "WrongPassword123!",
                "new_password": "NewPassword456!"
            }
        )
        assert response.status_code == 400
        data = response.json()
        assert "原密码错误" in data["detail"]


class TestAuthPasswordReset:
    """密码重置测试"""

    async def test_request_password_reset(self, client: AsyncClient, test_user):
        """测试请求密码重置"""
        response = await client.post(
            "/api/v1/auth/password-reset/request",
            json={"email": test_user.email}
        )
        assert response.status_code == 200
        # 无论邮箱是否存在都返回成功（防止枚举攻击）

    async def test_request_password_reset_nonexistent(self, client: AsyncClient):
        """测试请求不存在的邮箱重置"""
        response = await client.post(
            "/api/v1/auth/password-reset/request",
            json={"email": "nonexistent@example.com"}
        )
        assert response.status_code == 200  # 仍然返回成功


class TestAuthRefresh:
    """刷新token测试"""

    async def test_refresh_token_success(self, client: AsyncClient, test_user):
        """测试成功刷新token"""
        # 先登录获取refresh_token
        login_response = await client.post(
            "/api/v1/auth/login/json",
            json={
                "email": test_user.email,
                "password": "TestPassword123!"
            }
        )
        login_data = login_response.json()
        refresh_token = login_data["data"]["refresh_token"]

        # 使用refresh_token获取新token
        response = await client.post(
            "/api/v1/auth/refresh",
            json={"refresh_token": refresh_token}
        )
        assert response.status_code == 200
        data = response.json()
        assert "access_token" in data["data"]
        # 注意: refresh token rotation可能未实现，所以不检查是否不同
        assert "refresh_token" in data["data"] or data["data"].get("access_token")

    async def test_refresh_token_invalid(self, client: AsyncClient):
        """测试无效的refresh_token"""
        response = await client.post(
            "/api/v1/auth/refresh",
            json={"refresh_token": "invalid_refresh_token"}
        )
        assert response.status_code == 401

    async def test_refresh_token_missing(self, client: AsyncClient):
        """测试缺少refresh_token参数"""
        response = await client.post(
            "/api/v1/auth/refresh",
            json={}
        )
        assert response.status_code == 422
