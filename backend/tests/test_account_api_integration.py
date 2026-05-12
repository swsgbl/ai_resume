"""
账号管理 API 集成测试
测试账号绑定、解绑、查询功能
"""
import pytest
from httpx import AsyncClient
from sqlalchemy.ext.asyncio import AsyncSession
from unittest.mock import AsyncMock, patch

from app.models.user import User
from app.core.security import get_password_hash


@pytest.mark.asyncio
class TestAccountBindings:
    """账号绑定查询测试"""

    async def test_get_account_bindings_all_empty(
        self, client: AsyncClient, db_session: AsyncSession
    ):
        """测试获取空绑定列表"""
        from app.core.security import create_access_token

        user = User(
            username="minimal_user",
            email="minimal@test.com",
            password_hash=get_password_hash("Pass123!"),
            is_verified=True
        )
        db_session.add(user)
        await db_session.commit()
        await db_session.refresh(user)

        token = create_access_token(data={"sub": str(user.id)})
        response = await client.get(
            "/api/v1/account/bindings",
            headers={"Authorization": f"Bearer {token}"}
        )

        assert response.status_code == 200
        data = response.json()
        # Account bindings returns Response schema with no code field
        assert "data" in data
        assert "email" in data["data"]
        assert data["data"]["email"]["bound"] is True
        assert data["data"]["phone"]["bound"] is False
        assert data["data"]["wechat"]["bound"] is False

    async def test_get_account_bindings_with_oauth(
        self, client: AsyncClient, db_session: AsyncSession
    ):
        """测试获取包含 OAuth 绑定的列表"""
        from app.core.security import create_access_token

        user = User(
            username="oauth_user",
            email="oauth@test.com",
            password_hash=get_password_hash("Pass123!"),
            is_verified=True,
            google_id="google_123",
            google_email="google@gmail.com",
            github_id="github_456",
            github_login="gh_user"
        )
        db_session.add(user)
        await db_session.commit()
        await db_session.refresh(user)

        token = create_access_token(data={"sub": str(user.id)})
        response = await client.get(
            "/api/v1/account/bindings",
            headers={"Authorization": f"Bearer {token}"}
        )

        assert response.status_code == 200
        data = response.json()
        bindings = data["data"]
        assert bindings["google"]["bound"] is True
        assert bindings["google"]["value"] == "google@gmail.com"
        assert bindings["github"]["bound"] is True
        assert bindings["github"]["value"] == "gh_user"


@pytest.mark.asyncio
class TestEmailBinding:
    """邮箱绑定测试"""

    async def test_bind_email_wrong_password(
        self, client: AsyncClient, test_user: User, auth_headers: dict
    ):
        """测试绑定邮箱 - 密码错误"""
        with patch("app.services.email_service.email_service") as mock_email:
            mock_email.verify_code = AsyncMock(return_value=True)

            response = await client.post(
                "/api/v1/account/bind/email",
                headers=auth_headers,
                json={
                    "email": "new@example.com",
                    "password": "WrongPassword123!",
                    "verification_code": "123456"
                }
            )

        assert response.status_code == 400
        assert "密码错误" in response.json()["detail"]

    async def test_bind_email_duplicate(
        self, client: AsyncClient, test_user: User, auth_headers: dict, db_session: AsyncSession
    ):
        """测试绑定已被使用的邮箱"""
        from app.core.security import create_access_token

        # 创建另一个用户占用目标邮箱
        other_user = User(
            username="other",
            email="occupied@example.com",
            password_hash=get_password_hash("Pass123!"),
            is_verified=True
        )
        db_session.add(other_user)
        await db_session.commit()

        with patch("app.services.email_service.email_service") as mock_email:
            mock_email.verify_code = AsyncMock(return_value=True)

            response = await client.post(
                "/api/v1/account/bind/email",
                headers=auth_headers,
                json={
                    "email": "occupied@example.com",
                    "password": "TestPassword123!",
                    "verification_code": "123456"
                }
            )

        assert response.status_code == 400
        assert "已被其他账号使用" in response.json()["detail"]

    async def test_bind_email_invalid_code(
        self, client: AsyncClient, test_user: User, auth_headers: dict
    ):
        """测试绑定邮箱 - 验证码无效"""
        with patch("app.services.email_service.email_service") as mock_email:
            mock_email.verify_code = AsyncMock(return_value=False)

            response = await client.post(
                "/api/v1/account/bind/email",
                headers=auth_headers,
                json={
                    "email": "new@example.com",
                    "password": "TestPassword123!",
                    "verification_code": "000000"
                }
            )

        assert response.status_code == 400
        assert "验证码错误" in response.json()["detail"]

    async def test_bind_email_success(
        self, client: AsyncClient, test_user: User, auth_headers: dict, db_session: AsyncSession
    ):
        """测试成功绑定新邮箱"""
        new_email = "newbound@example.com"

        with patch("app.services.email_service.email_service") as mock_email:
            mock_email.verify_code = AsyncMock(return_value=True)

            response = await client.post(
                "/api/v1/account/bind/email",
                headers=auth_headers,
                json={
                    "email": new_email,
                    "password": "TestPassword123!",
                    "verification_code": "123456"
                }
            )

        assert response.status_code == 200
        assert response.json()["message"] == "邮箱绑定成功"

        # 验证数据库已更新
        await db_session.refresh(test_user)
        assert test_user.email == new_email
        assert test_user.is_verified is True


@pytest.mark.asyncio
class TestPhoneBinding:
    """手机号绑定测试"""

    async def test_bind_phone_invalid_format(
        self, client: AsyncClient, test_user: User, auth_headers: dict
    ):
        """测试绑定无效格式的手机号"""
        response = await client.post(
            "/api/v1/account/bind/phone",
            headers=auth_headers,
            json={"phone": "12345"}  # 格式错误
        )

        assert response.status_code == 422  # Validation error

    async def test_bind_phone_duplicate(
        self, client: AsyncClient, test_user: User, auth_headers: dict, db_session: AsyncSession
    ):
        """测试绑定已被使用的手机号"""
        from app.core.security import create_access_token

        # 创建另一个用户
        other_user = User(
            username="phone_owner",
            email="phone@example.com",
            phone="13800138000",
            password_hash=get_password_hash("Pass123!"),
            is_verified=True
        )
        db_session.add(other_user)
        await db_session.commit()

        response = await client.post(
            "/api/v1/account/bind/phone",
            headers=auth_headers,
            json={"phone": "13800138000"}
        )

        assert response.status_code == 400
        assert "已被其他账号使用" in response.json()["detail"]

    async def test_bind_phone_success(
        self, client: AsyncClient, test_user: User, auth_headers: dict, db_session: AsyncSession
    ):
        """测试成功绑定手机号"""
        phone = "13912345678"

        response = await client.post(
            "/api/v1/account/bind/phone",
            headers=auth_headers,
            json={"phone": phone}
        )

        assert response.status_code == 200
        assert response.json()["message"] == "手机号绑定成功"

        await db_session.refresh(test_user)
        assert test_user.phone == phone


@pytest.mark.asyncio
class TestAccountUnbinding:
    """账号解绑测试"""

    async def test_unbind_wrong_password(
        self, client: AsyncClient, test_user: User, auth_headers: dict
    ):
        """测试解绑 - 密码错误"""
        response = await client.post(
            "/api/v1/account/unbind",
            headers=auth_headers,
            json={
                "account_type": "email",
                "password": "WrongPassword!"
            }
        )

        assert response.status_code == 400
        assert "密码错误" in response.json()["detail"]

    async def test_unbind_not_bound(
        self, client: AsyncClient, db_session: AsyncSession
    ):
        """测试解绑未绑定的账号类型"""
        from app.core.security import create_access_token, get_password_hash

        # 创建有邮箱和手机号的用户
        user = User(
            username="multi_bind",
            email="multi@test.com",
            phone="13900000000",
            password_hash=get_password_hash("Pass123!"),
            is_verified=True
        )
        db_session.add(user)
        await db_session.commit()
        await db_session.refresh(user)

        token = create_access_token(data={"sub": str(user.id)})
        response = await client.post(
            "/api/v1/account/unbind",
            headers={"Authorization": f"Bearer {token}"},
            json={
                "account_type": "wechat",
                "password": "Pass123!"
            }
        )

        assert response.status_code == 400
        assert "微信未绑定" in response.json()["detail"]

    async def test_unbind_last_account(
        self, client: AsyncClient, db_session: AsyncSession
    ):
        """测试解绑最后一种登录方式应被禁止"""
        from app.core.security import create_access_token, get_password_hash

        user = User(
            username="single_login",
            email="single@test.com",
            password_hash=get_password_hash("Pass123!"),
            is_verified=True
        )
        db_session.add(user)
        await db_session.commit()
        await db_session.refresh(user)

        token = create_access_token(data={"sub": str(user.id)})
        response = await client.post(
            "/api/v1/account/unbind",
            headers={"Authorization": f"Bearer {token}"},
            json={
                "account_type": "email",
                "password": "Pass123!"
            }
        )

        assert response.status_code == 400
        assert "至少需要保留一种登录方式" in response.json()["detail"]

    async def test_unbind_email_success(
        self, client: AsyncClient, test_user: User, auth_headers: dict, db_session: AsyncSession
    ):
        """测试成功解绑邮箱"""
        # 先绑定手机号，确保有其他登录方式
        test_user.phone = "13900000000"
        await db_session.commit()

        response = await client.post(
            "/api/v1/account/unbind",
            headers=auth_headers,
            json={
                "account_type": "email",
                "password": "TestPassword123!"
            }
        )

        assert response.status_code == 200
        assert response.json()["message"] == "解绑成功"

        await db_session.refresh(test_user)
        assert test_user.email is None
        assert test_user.is_verified is False

    async def test_unbind_oauth_account(
        self, client: AsyncClient, db_session: AsyncSession
    ):
        """测试解绑 OAuth 账号"""
        from app.core.security import create_access_token, get_password_hash

        user = User(
            username="oauth_to_unbind",
            email="oauth_unbind@test.com",
            password_hash=get_password_hash("Pass123!"),
            is_verified=True,
            google_id="google_999",
            google_email="unbind@gmail.com"
        )
        db_session.add(user)
        await db_session.commit()
        await db_session.refresh(user)

        token = create_access_token(data={"sub": str(user.id)})
        response = await client.post(
            "/api/v1/account/unbind",
            headers={"Authorization": f"Bearer {token}"},
            json={
                "account_type": "google",
                "password": "Pass123!"
            }
        )

        assert response.status_code == 200

        await db_session.refresh(user)
        assert user.google_id is None
        assert user.google_email is None

    async def test_unbind_unsupported_type(
        self, client: AsyncClient, db_session: AsyncSession
    ):
        """测试解绑不支持的账号类型"""
        from app.core.security import create_access_token, get_password_hash

        # 创建有邮箱和手机号的用户
        user = User(
            username="unsupported_test",
            email="unsupported@test.com",
            phone="13900000001",
            password_hash=get_password_hash("Pass123!"),
            is_verified=True
        )
        db_session.add(user)
        await db_session.commit()
        await db_session.refresh(user)

        token = create_access_token(data={"sub": str(user.id)})
        response = await client.post(
            "/api/v1/account/unbind",
            headers={"Authorization": f"Bearer {token}"},
            json={
                "account_type": "unsupported",
                "password": "Pass123!"
            }
        )

        assert response.status_code == 400
        assert "不支持的账号类型" in response.json()["detail"]
