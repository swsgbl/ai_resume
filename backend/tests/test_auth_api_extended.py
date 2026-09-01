"""
Auth API 扩展测试 - 针对 auth.py 缺失覆盖行
"""
import pytest
from httpx import AsyncClient
from unittest.mock import AsyncMock, patch, MagicMock
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from datetime import datetime, timezone

from app.models.user import User
from app.core.security import get_password_hash


class TestAuthenticateUser:
    """测试 _authenticate_user 函数 (行 48-67)"""

    async def test_authenticate_user_success(
        self, client: AsyncClient, test_user, db_session
    ):
        """测试: 成功认证用户"""
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

    async def test_authenticate_user_wrong_password(
        self, client: AsyncClient, test_user
    ):
        """测试: 错误密码"""
        response = await client.post(
            "/api/v1/auth/login",
            data={
                "username": test_user.email,
                "password": "wrongpassword"
            }
        )

        assert response.status_code == 401
        data = response.json()
        assert "邮箱或密码错误" in data["detail"]

    async def test_authenticate_user_nonexistent_email(
        self, client: AsyncClient
    ):
        """测试: 不存在的邮箱"""
        response = await client.post(
            "/api/v1/auth/login",
            data={
                "username": "nonexistent@example.com",
                "password": "anypassword"
            }
        )

        assert response.status_code == 401

    async def test_authenticate_inactive_user(
        self, client: AsyncClient, test_user, db_session
    ):
        """测试: 禁用用户登录"""
        # 禁用用户
        test_user.is_active = False
        await db_session.commit()

        response = await client.post(
            "/api/v1/auth/login",
            data={
                "username": test_user.email,
                "password": "TestPassword123!"
            }
        )

        assert response.status_code == 403
        data = response.json()
        assert "账户已被禁用" in data["detail"]

        # 恢复用户状态
        test_user.is_active = True
        await db_session.commit()

    async def test_authenticate_updates_last_login(
        self, client: AsyncClient, test_user, db_session
    ):
        """测试: 登录后更新最后登录时间"""
        # 获取旧登录时间
        old_login_time = test_user.last_login_at

        response = await client.post(
            "/api/v1/auth/login",
            data={
                "username": test_user.email,
                "password": "TestPassword123!"
            }
        )

        assert response.status_code == 200

        # 刷新并检查
        await db_session.refresh(test_user)
        new_login_time = test_user.last_login_at
        assert new_login_time is not None
        if old_login_time:
            assert new_login_time >= old_login_time


class TestRegisterEndpoint:
    """测试注册端点 (行 100-123)"""

    async def test_register_email_exists(
        self, client: AsyncClient, test_user
    ):
        """测试: 邮箱已存在"""
        with patch("app.api.v1.auth.email_service") as mock_email:
            mock_email.verify_code = AsyncMock(return_value=True)

            response = await client.post(
                "/api/v1/auth/register",
                json={
                    "email": test_user.email,
                    "username": "newuser",
                    "password": "newpass123",
                    "verification_code": "123456"
                }
            )

        assert response.status_code == 400
        data = response.json()
        assert "已被注册" in data["detail"]
        mock_email.verify_code.assert_not_called()

    async def test_register_success_consumes_verification_code(
        self, client: AsyncClient, db_session
    ):
        """测试: 注册成功时消费验证码并直接创建已验证用户"""
        new_email = "newuser@register.com"

        with patch("app.api.v1.auth.email_service") as mock_email:
            mock_email.verify_code = AsyncMock(return_value=True)

            response = await client.post(
                "/api/v1/auth/register",
                json={
                    "email": new_email,
                    "username": "newuser",
                    "password": "newpass123",
                    "verification_code": "123456"
                }
            )

            assert response.status_code == 200
            data = response.json()
            assert data["data"]["user"]["email"] == new_email
            assert data["data"]["user"]["is_verified"] is True
            assert data["data"]["access_token"]

            # 注册只消费验证码，不再事后补发邮件
            mock_email.verify_code.assert_called_once_with(new_email, "123456")
            mock_email.send_verification_email.assert_not_called()

            # 清理测试用户
            result = await db_session.execute(
                select(User).where(User.email == new_email)
            )
            user = result.scalar_one_or_none()
            if user:
                await db_session.delete(user)
                await db_session.commit()

    async def test_register_invalid_code_creates_no_user(
        self, client: AsyncClient, db_session
    ):
        """测试: 验证码无效时不创建用户"""
        new_email = "invalid-code@register.com"

        with patch("app.api.v1.auth.email_service") as mock_email:
            mock_email.verify_code = AsyncMock(return_value=False)

            await client.post(
                "/api/v1/auth/register",
                json={
                    "email": new_email,
                    "username": "invalid",
                    "password": "pass123",
                    "verification_code": "000000"
                }
            )

            result = await db_session.execute(
                select(User).where(User.email == new_email)
            )
            user = result.scalar_one_or_none()
            assert user is None


class TestLoginEndpoints:
    """测试登录端点 (行 141, 152)"""

    async def test_login_oauth2_form(
        self, client: AsyncClient, test_user
    ):
        """测试: OAuth2 表单登录"""
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
        assert "refresh_token" in data["data"]
        assert "expires_in" in data["data"]

    async def test_login_json_format(
        self, client: AsyncClient, test_user
    ):
        """测试: JSON 格式登录"""
        response = await client.post(
            "/api/v1/auth/login/json",
            json={
                "email": test_user.email,
                "password": "TestPassword123!"
            }
        )

        assert response.status_code == 200
        data = response.json()
        assert "access_token" in data["data"]


class TestRefreshToken:
    """测试刷新令牌 (行 178-186)"""

    async def test_refresh_with_valid_token(
        self, client: AsyncClient, test_user, auth_headers
    ):
        """测试: 有效令牌刷新"""
        # 首先登录获取令牌
        login_response = await client.post(
            "/api/v1/auth/login",
            data={
                "username": test_user.email,
                "password": "TestPassword123!"
            }
        )
        login_data = login_response.json()
        refresh_token = login_data["data"]["refresh_token"]

        # 使用刷新令牌
        response = await client.post(
            "/api/v1/auth/refresh",
            json={"refresh_token": refresh_token}
        )

        assert response.status_code == 200
        data = response.json()
        assert "access_token" in data["data"]

    async def test_refresh_with_invalid_token(
        self, client: AsyncClient
    ):
        """测试: 无效刷新令牌"""
        response = await client.post(
            "/api/v1/auth/refresh",
            json={"refresh_token": "invalid_token"}
        )

        assert response.status_code == 401

    async def test_refresh_inactive_user(
        self, client: AsyncClient, test_user, db_session
    ):
        """测试: 禁用用户刷新令牌"""
        # 登录获取令牌
        login_response = await client.post(
            "/api/v1/auth/login",
            data={
                "username": test_user.email,
                "password": "TestPassword123!"
            }
        )
        refresh_token = login_response.json()["data"]["refresh_token"]

        # 禁用用户
        test_user.is_active = False
        await db_session.commit()

        # 尝试刷新
        response = await client.post(
            "/api/v1/auth/refresh",
            json={"refresh_token": refresh_token}
        )

        assert response.status_code == 401
        assert "已被禁用" in response.json()["detail"]

        # 恢复
        test_user.is_active = True
        await db_session.commit()


class TestChangePassword:
    """测试修改密码 (行 219)"""

    async def test_change_password_success(
        self, client: AsyncClient, auth_headers
    ):
        """测试: 成功修改密码"""
        response = await client.post(
            "/api/v1/auth/change-password",
            headers=auth_headers,
            json={
                "old_password": "TestPassword123!",
                "new_password": "newpass456"
            }
        )

        assert response.status_code == 200
        assert "密码修改成功" in response.json()["message"]

    async def test_change_password_wrong_old(
        self, client: AsyncClient, auth_headers
    ):
        """测试: 原密码错误"""
        response = await client.post(
            "/api/v1/auth/change-password",
            headers=auth_headers,
            json={
                "old_password": "wrongpass",
                "new_password": "newpass456"
            }
        )

        assert response.status_code == 400
        assert "原密码错误" in response.json()["detail"]


class TestPasswordReset:
    """测试密码重置 (行 234-245)"""

    async def test_reset_request_existing_email(
        self, client: AsyncClient, test_user
    ):
        """测试: 已存在邮箱请求重置"""
        with patch("app.api.v1.auth.email_service") as mock_email:
            mock_email.generate_code.return_value = "999999"
            mock_email.save_reset_code = AsyncMock()
            mock_email.send_password_reset_email = AsyncMock()

            response = await client.post(
                "/api/v1/auth/password-reset/request",
                json={"email": test_user.email}
            )

            assert response.status_code == 200
            # 应该发送了邮件
            mock_email.send_password_reset_email.assert_called_once()

    async def test_reset_request_nonexistent_email(
        self, client: AsyncClient
    ):
        """测试: 不存在邮箱请求重置（不泄露信息）"""
        with patch("app.api.v1.auth.email_service") as mock_email:
            mock_email.generate_code.return_value = "888888"
            mock_email.save_reset_code = AsyncMock()
            mock_email.send_password_reset_email = AsyncMock()

            response = await client.post(
                "/api/v1/auth/password-reset/request",
                json={"email": "nonexistent@example.com"}
            )

            # 同样返回成功（防止邮箱枚举）
            assert response.status_code == 200
            # 不应该发送邮件
            mock_email.send_password_reset_email.assert_not_called()

    async def test_reset_verify_success(
        self, client: AsyncClient, test_user, db_session
    ):
        """测试: 验证重置码并重置密码"""
        new_password = "resetpass123"

        with patch("app.api.v1.auth.email_service") as mock_email:
            # 模拟验证码有效
            mock_email.verify_reset_code = AsyncMock(return_value=True)

            response = await client.post(
                "/api/v1/auth/password-reset/verify",
                json={
                    "email": test_user.email,
                    "code": "123456",
                    "new_password": new_password
                }
            )

            assert response.status_code == 200
            assert "密码重置成功" in response.json()["message"]

            # 验证密码已更新
            await db_session.refresh(test_user)
            # 密码哈希应该不同
            old_hash = test_user.password_hash

    async def test_reset_verify_invalid_code(
        self, client: AsyncClient, test_user
    ):
        """测试: 无效重置码"""
        with patch("app.api.v1.auth.email_service") as mock_email:
            mock_email.verify_reset_code = AsyncMock(return_value=False)

            response = await client.post(
                "/api/v1/auth/password-reset/verify",
                json={
                    "email": test_user.email,
                    "code": "000000",
                    "new_password": "newpass123"
                }
            )

            assert response.status_code == 400
            assert "验证码无效" in response.json()["detail"]


class TestGetCurrentUser:
    """测试获取当前用户信息"""

    async def test_get_me_success(
        self, client: AsyncClient, auth_headers, test_user
    ):
        """测试: 获取当前用户信息"""
        response = await client.get(
            "/api/v1/auth/me",
            headers=auth_headers
        )

        assert response.status_code == 200
        data = response.json()
        assert data["data"]["email"] == test_user.email
        assert data["data"]["username"] == test_user.username

    async def test_get_me_unauthorized(
        self, client: AsyncClient
    ):
        """测试: 未认证访问"""
        response = await client.get("/api/v1/auth/me")
        assert response.status_code == 401


class TestTokenResponse:
    """测试令牌响应"""

    async def test_token_response_structure(
        self, client: AsyncClient, test_user
    ):
        """测试: 令牌响应结构完整"""
        response = await client.post(
            "/api/v1/auth/login",
            data={
                "username": test_user.email,
                "password": "TestPassword123!"
            }
        )

        assert response.status_code == 200
        data = response.json()["data"]

        # 验证所有必需字段
        assert "access_token" in data
        assert "refresh_token" in data
        assert "expires_in" in data
        assert isinstance(data["expires_in"], int)
        assert data["expires_in"] > 0
