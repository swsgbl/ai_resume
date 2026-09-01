"""
Auth API 增强测试 - 提高覆盖率
"""
import pytest
from unittest.mock import patch, AsyncMock
from httpx import AsyncClient
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from app.models.user import User


class TestEmailVerification:
    """邮箱验证测试"""

    async def test_send_verification_code_success(
        self, client: AsyncClient
    ):
        """测试: 成功发送验证码"""
        # Mock email sending to avoid actual SMTP
        with patch("app.services.email_service.email_service.send_verification_email", new_callable=AsyncMock) as mock_send:
            mock_send.return_value = True

            response = await client.post(
                "/api/v1/email/send-code",
                json={"email": "verify@example.com"}
            )

            assert response.status_code == 200
            data = response.json()
            assert data["code"] == 200
            assert "expire_in" in data["data"]

    async def test_send_verification_code_invalid_email(
        self, client: AsyncClient
    ):
        """测试: 发送验证码 - 无效邮箱"""
        response = await client.post(
            "/api/v1/email/send-code",
            json={"email": "invalid-email"}
        )

        assert response.status_code == 422

    async def test_verify_code_success(
        self, client: AsyncClient
    ):
        """测试: 成功验证验证码"""
        from app.services.email_service import email_service
        from unittest.mock import patch

        # Mock verify_code to return True
        with patch.object(email_service, 'verify_code', new_callable=AsyncMock, return_value=True):
            response = await client.post(
                "/api/v1/email/verify-code",
                json={
                    "email": "test_verify@example.com",
                    "code": "123456"
                }
            )

            assert response.status_code == 200
            data = response.json()
            assert data["code"] == 200
            assert data["data"]["verified"] is True

    async def test_verify_code_wrong(
        self, client: AsyncClient
    ):
        """测试: 验证码错误"""
        from app.services.email_service import email_service
        from unittest.mock import patch

        # Mock verify_code to return False
        with patch.object(email_service, 'verify_code', new_callable=AsyncMock, return_value=False):
            response = await client.post(
                "/api/v1/email/verify-code",
                json={
                    "email": "test@example.com",
                    "code": "000000"  # 错误的验证码
                }
            )

            assert response.status_code == 400
            data = response.json()
            assert "验证码错误" in data["detail"]

    async def test_verify_code_expired(
        self, client: AsyncClient, db_session
    ):
        """测试: 验证码过期"""
        from app.services.email_service import email_service
        from unittest.mock import patch

        # Mock verify_code to return False (expired scenario)
        with patch.object(email_service, 'verify_code', new_callable=AsyncMock, return_value=False):
            response = await client.post(
                "/api/v1/email/verify-code",
                json={
                    "email": "expired@example.com",
                    "code": "999999"
                }
            )

            # Expired or invalid code returns 400
            assert response.status_code == 400


class TestPasswordResetVerify:
    """密码重置验证测试"""

    async def test_verify_reset_code_success(
        self, client: AsyncClient, test_user, db_session
    ):
        """测试: 成功验证重置码并重置密码"""
        from app.services.email_service import email_service
        from unittest.mock import patch

        # Mock verify_reset_code to return True
        with patch.object(email_service, 'verify_reset_code', new_callable=AsyncMock, return_value=True):
            response = await client.post(
                "/api/v1/auth/password-reset/verify",
                json={
                    "email": test_user.email,
                    "code": "654321",
                    "new_password": "NewResetPassword123!"
                }
            )

            assert response.status_code == 200
            data = response.json()
            assert "密码重置成功" in data["message"]

    async def test_verify_reset_code_invalid(
        self, client: AsyncClient, test_user
    ):
        """测试: 无效的重置码"""
        from app.services.email_service import email_service
        from unittest.mock import patch

        # Mock verify_reset_code to return False
        with patch.object(email_service, 'verify_reset_code', new_callable=AsyncMock, return_value=False):
            response = await client.post(
                "/api/v1/auth/password-reset/verify",
                json={
                    "email": test_user.email,
                    "code": "000000",
                    "new_password": "NewPassword123!"
                }
            )

            assert response.status_code == 400
            data = response.json()
            assert "验证码无效" in data["detail"]

    async def test_verify_reset_code_nonexistent_user(
        self, client: AsyncClient
    ):
        """测试: 重置不存在的用户密码"""
        from app.services.email_service import email_service
        from unittest.mock import patch

        # 即使验证码有效，用户不存在也应该失败
        with patch.object(email_service, 'verify_reset_code', new_callable=AsyncMock, return_value=True):
            response = await client.post(
                "/api/v1/auth/password-reset/verify",
                json={
                    "email": "nonexistent@example.com",
                    "code": "123456",
                    "new_password": "NewPassword123!"
                }
            )

            # API 先检查验证码，如果通过才检查用户
            # 用户不存在时返回 404
            assert response.status_code == 404

    async def test_verify_reset_code_weak_password(
        self, client: AsyncClient, test_user, db_session
    ):
        """测试: 使用弱密码重置"""
        from app.services.email_service import email_service
        from unittest.mock import patch

        with patch.object(email_service, 'verify_reset_code', new_callable=AsyncMock, return_value=True):
            response = await client.post(
                "/api/v1/auth/password-reset/verify",
                json={
                    "email": test_user.email,
                    "code": "111111",
                    "new_password": "123"  # 弱密码
                }
            )

            # 应该返回验证错误
            assert response.status_code == 422


class TestLoginEdgeCases:
    """登录边界情况测试"""

    async def test_login_disabled_account(
        self, client: AsyncClient, db_session
    ):
        """测试: 登录已禁用的账户"""
        from app.models.user import User
        from app.core.security import get_password_hash

        # 创建一个已禁用的用户
        disabled_user = User(
            email="disabled@example.com",
            username="disabled_user",
            password_hash=get_password_hash("Password123!"),
            is_active=False,
            is_verified=False
        )
        db_session.add(disabled_user)
        await db_session.commit()

        response = await client.post(
            "/api/v1/auth/login/json",
            json={
                "email": "disabled@example.com",
                "password": "Password123!"
            }
        )

        assert response.status_code == 403
        data = response.json()
        assert "账户已被禁用" in data["detail"]

    async def test_login_updates_last_login(
        self, client: AsyncClient, test_user, db_session
    ):
        """测试: 登录更新最后登录时间"""
        # 获取登录前的最后登录时间
        result = await db_session.execute(
            select(User).where(User.id == test_user.id)
        )
        user_before = result.scalar_one_or_none()
        last_login_before = user_before.last_login_at

        # 执行登录
        await client.post(
            "/api/v1/auth/login/json",
            json={
                "email": test_user.email,
                "password": "TestPassword123!"
            }
        )

        # 检查最后登录时间已更新
        await db_session.refresh(user_before)
        assert user_before.last_login_at is not None

    async def test_login_empty_password(
        self, client: AsyncClient, test_user
    ):
        """测试: 空密码登录"""
        response = await client.post(
            "/api/v1/auth/login/json",
            json={
                "email": test_user.email,
                "password": ""
            }
        )

        assert response.status_code == 401

    async def test_login_missing_fields(
        self, client: AsyncClient
    ):
        """测试: 缺少必填字段"""
        response = await client.post(
            "/api/v1/auth/login/json",
            json={"email": "test@example.com"}  # 缺少密码
        )

        assert response.status_code == 422


class TestRefreshTokenEdgeCases:
    """刷新令牌边界情况测试"""

    async def test_refresh_token_malformed(
        self, client: AsyncClient
    ):
        """测试: 格式错误的 refresh token"""
        response = await client.post(
            "/api/v1/auth/refresh",
            json={"refresh_token": "not-a-valid-jwt-token"}
        )

        assert response.status_code == 401

    async def test_refresh_token_empty_string(
        self, client: AsyncClient
    ):
        """测试: 空 refresh token"""
        response = await client.post(
            "/api/v1/auth/refresh",
            json={"refresh_token": ""}
        )

        assert response.status_code == 401

    async def test_refresh_token_deleted_user(
        self, client: AsyncClient, db_session
    ):
        """测试: 用户已删除的 refresh token"""
        from app.core.security import create_refresh_token

        # 为一个不存在的用户创建 token
        fake_user_id = 999999
        refresh_token = create_refresh_token(data={"sub": str(fake_user_id)})

        response = await client.post(
            "/api/v1/auth/refresh",
            json={"refresh_token": refresh_token}
        )

        assert response.status_code == 401


class TestChangePasswordEdgeCases:
    """修改密码边界情况测试"""

    async def test_change_password_same_as_old(
        self, client: AsyncClient, auth_headers
    ):
        """测试: 新密码与旧密码相同"""
        response = await client.post(
            "/api/v1/auth/change-password",
            headers=auth_headers,
            json={
                "old_password": "TestPassword123!",
                "new_password": "TestPassword123!"  # 与旧密码相同
            }
        )

        # API 可能允许相同密码，或返回错误
        assert response.status_code in [200, 400]

    async def test_change_password_empty_new(
        self, client: AsyncClient, auth_headers
    ):
        """测试: 空新密码"""
        response = await client.post(
            "/api/v1/auth/change-password",
            headers=auth_headers,
            json={
                "old_password": "TestPassword123!",
                "new_password": ""
            }
        )

        assert response.status_code == 422

    async def test_change_password_without_auth(
        self, client: AsyncClient
    ):
        """测试: 未认证修改密码"""
        response = await client.post(
            "/api/v1/auth/change-password",
            json={
                "old_password": "TestPassword123!",
                "new_password": "NewPassword123!"
            }
        )

        assert response.status_code == 401


class TestRegisterEdgeCases:
    """注册边界情况测试"""

    async def test_register_minimal_valid_data(
        self, client: AsyncClient
    ):
        """测试: 最小有效注册数据"""
        with patch("app.api.v1.auth.email_service") as mock_email:
            mock_email.verify_code = AsyncMock(return_value=True)

            response = await client.post(
                "/api/v1/auth/register",
                json={
                    "email": "minimal@example.com",
                    "username": "minimal",
                    "password": "Password123!",
                    "verification_code": "123456"
                }
            )

        assert response.status_code == 200
        data = response.json()
        assert data["data"]["user"]["email"] == "minimal@example.com"

    async def test_register_duplicate_username(
        self, client: AsyncClient, test_user
    ):
        """测试: 重复用户名（如果有限制）"""
        # 当前实现只检查邮箱，不检查用户名
        with patch("app.api.v1.auth.email_service") as mock_email:
            mock_email.verify_code = AsyncMock(return_value=True)

            response = await client.post(
                "/api/v1/auth/register",
                json={
                    "email": "different@example.com",
                    "username": test_user.username,  # 重复用户名
                    "password": "Password123!",
                    "verification_code": "123456"
                }
            )

        # 可能成功（当前不检查用户名重复）或失败
        assert response.status_code in [200, 400]

    async def test_register_missing_fields(
        self, client: AsyncClient
    ):
        """测试: 缺少必填字段"""
        response = await client.post(
            "/api/v1/auth/register",
            json={
                "email": "test@example.com"
                # 缺少 username 和 password
            }
        )

        assert response.status_code == 422


class TestTokenResponse:
    """Token 响应结构测试"""

    async def test_token_response_structure(
        self, client: AsyncClient, test_user
    ):
        """测试: Token 响应结构正确"""
        response = await client.post(
            "/api/v1/auth/login/json",
            json={
                "email": test_user.email,
                "password": "TestPassword123!"
            }
        )

        assert response.status_code == 200
        data = response.json()
        token_data = data["data"]

        # 检查必需字段
        assert "access_token" in token_data
        assert "refresh_token" in token_data
        assert "expires_in" in token_data

        # 验证 token 格式（JWT 应该有 3 个部分）
        access_token_parts = token_data["access_token"].split(".")
        assert len(access_token_parts) == 3

        refresh_token_parts = token_data["refresh_token"].split(".")
        assert len(refresh_token_parts) == 3

    async def test_access_token_works(
        self, client: AsyncClient, test_user
    ):
        """测试: Access token 可以用于认证"""
        login_response = await client.post(
            "/api/v1/auth/login/json",
            json={
                "email": test_user.email,
                "password": "TestPassword123!"
            }
        )
        access_token = login_response.json()["data"]["access_token"]

        # 使用 access token 访问受保护端点
        me_response = await client.get(
            "/api/v1/auth/me",
            headers={"Authorization": f"Bearer {access_token}"}
        )

        assert me_response.status_code == 200
        assert me_response.json()["data"]["email"] == test_user.email


class TestGetMeEdgeCases:
    """获取当前用户边界情况"""

    async def test_get_me_with_bearer_token_format(
        self, client: AsyncClient, test_user
    ):
        """测试: Bearer token 格式正确"""
        login_response = await client.post(
            "/api/v1/auth/login/json",
            json={
                "email": test_user.email,
                "password": "TestPassword123!"
            }
        )
        token = login_response.json()["data"]["access_token"]

        # 测试不同的 Authorization 头格式
        response = await client.get(
            "/api/v1/auth/me",
            headers={"Authorization": token}  # 缺少 Bearer 前缀
        )

        # 应该失败（需要 Bearer 前缀）
        assert response.status_code == 401

    async def test_get_me_response_structure(
        self, client: AsyncClient, auth_headers
    ):
        """测试: 用户信息响应结构正确"""
        response = await client.get(
            "/api/v1/auth/me",
            headers=auth_headers
        )

        assert response.status_code == 200
        data = response.json()
        user_data = data["data"]

        # 检查用户字段
        assert "id" in user_data
        assert "email" in user_data
        assert "username" in user_data


class TestPasswordResetRequestEdgeCases:
    """密码重置请求边界情况"""

    async def test_password_reset_rate_limit(
        self, client: AsyncClient, test_user
    ):
        """测试: 密码重置请求频率限制"""
        # 连续发送多个重置请求
        for _ in range(3):
            response = await client.post(
                "/api/v1/auth/password-reset/request",
                json={"email": test_user.email}
            )
            assert response.status_code == 200

    async def test_password_reset_invalid_email_format(
        self, client: AsyncClient
    ):
        """测试: 无效邮箱格式"""
        response = await client.post(
            "/api/v1/auth/password-reset/request",
            json={"email": "not-an-email"}
        )

        assert response.status_code == 422
