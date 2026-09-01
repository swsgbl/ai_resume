"""
邮箱验证 API 集成测试
"""
import pytest
from httpx import AsyncClient
from sqlalchemy.ext.asyncio import AsyncSession
from unittest.mock import AsyncMock, patch


@pytest.mark.asyncio
class TestSendVerificationCode:
    """发送验证码测试"""

    async def test_send_code_success(self, client: AsyncClient):
        """测试成功发送验证码"""
        delivery_events = []

        with patch("app.api.v1.email_verification.email_service") as mock_service:
            mock_service.generate_code = lambda length: "123456"
            mock_service.save_code = AsyncMock(side_effect=lambda *args, **kwargs: delivery_events.append("save"))
            mock_service.send_verification_email = AsyncMock(
                side_effect=lambda *args, **kwargs: delivery_events.append("send") or "sent",
            )

            response = await client.post(
                "/api/v1/email/send-code",
                json={"email": "test@example.com"}
            )

        assert response.status_code == 200
        data = response.json()
        assert data["code"] == 200
        assert "验证码已发送" in data["message"]
        assert data["data"]["expire_in"] == 300
        assert delivery_events == ["send", "save"]

    async def test_send_code_email_service_failure(self, client: AsyncClient):
        """测试邮件发送失败"""
        with patch("app.api.v1.email_verification.email_service") as mock_service:
            mock_service.generate_code = lambda length: "123456"
            mock_service.save_code = AsyncMock()
            mock_service.send_verification_email = AsyncMock(return_value=False)

            response = await client.post(
                "/api/v1/email/send-code",
                json={"email": "test@example.com"}
            )

        assert response.status_code == 500
        assert "发送验证码失败" in response.json()["detail"]
        mock_service.save_code.assert_not_called()

    async def test_send_code_invalid_email(self, client: AsyncClient):
        """测试无效邮箱格式"""
        response = await client.post(
            "/api/v1/email/send-code",
            json={"email": "not-an-email"}
        )

        assert response.status_code == 422  # Validation error


@pytest.mark.asyncio
class TestVerifyCode:
    """验证验证码测试"""

    async def test_verify_code_success(
        self, client: AsyncClient, db_session: AsyncSession
    ):
        """测试成功验证验证码"""
        from app.models.user import User
        from app.core.security import get_password_hash

        user = User(
            username="verify_test",
            email="verify@example.com",
            password_hash=get_password_hash("Pass123!"),
            is_verified=False
        )
        db_session.add(user)
        await db_session.commit()

        with patch("app.api.v1.email_verification.email_service") as mock_service:
            mock_service.verify_code = AsyncMock(return_value=True)

            response = await client.post(
                "/api/v1/email/verify-code",
                json={"email": "verify@example.com", "code": "123456"}
            )

        assert response.status_code == 200
        data = response.json()
        assert data["code"] == 200
        assert data["data"]["verified"] is True

        # 验证数据库状态已更新
        await db_session.refresh(user)
        assert user.is_verified is True

    async def test_verify_code_invalid(self, client: AsyncClient):
        """测试无效验证码"""
        with patch("app.api.v1.email_verification.email_service") as mock_service:
            mock_service.verify_code = AsyncMock(return_value=False)

            response = await client.post(
                "/api/v1/email/verify-code",
                json={"email": "test@example.com", "code": "000000"}
            )

        assert response.status_code == 400
        assert "验证码错误或已过期" in response.json()["detail"]

    async def test_verify_code_expired(self, client: AsyncClient):
        """测试过期验证码"""
        with patch("app.api.v1.email_verification.email_service") as mock_service:
            mock_service.verify_code = AsyncMock(return_value=False)

            response = await client.post(
                "/api/v1/email/verify-code",
                json={"email": "test@example.com", "code": "999999"}
            )

        assert response.status_code == 400

    async def test_verify_code_nonexistent_user(
        self, client: AsyncClient, db_session: AsyncSession
    ):
        """测试验证不存在的用户邮箱"""
        with patch("app.api.v1.email_verification.email_service") as mock_service:
            mock_service.verify_code = AsyncMock(return_value=True)

            response = await client.post(
                "/api/v1/email/verify-code",
                json={"email": "nonexistent@example.com", "code": "123456"}
            )

        # 应该返回成功，但不影响任何用户
        assert response.status_code == 200
        data = response.json()
        assert data["data"]["verified"] is True

    async def test_verify_code_invalid_email_format(self, client: AsyncClient):
        """测试验证码请求邮箱格式无效"""
        response = await client.post(
            "/api/v1/email/verify-code",
            json={"email": "invalid-email", "code": "123456"}
        )

        assert response.status_code == 422


@pytest.mark.asyncio
class TestEmailVerificationIntegration:
    """邮箱验证完整流程测试"""

    async def test_full_verification_flow(
        self, client: AsyncClient, db_session: AsyncSession
    ):
        """测试完整的验证流程：发送 -> 验证"""
        from app.models.user import User
        from app.core.security import get_password_hash

        email = "fullflow@example.com"

        # 创建未验证用户
        user = User(
            username="fullflow",
            email=email,
            password_hash=get_password_hash("Pass123!"),
            is_verified=False
        )
        db_session.add(user)
        await db_session.commit()

        sent_code = "654321"

        # 步骤1: 发送验证码
        with patch("app.api.v1.email_verification.email_service") as mock_service:
            mock_service.generate_code = lambda length: sent_code
            mock_service.save_code = AsyncMock()
            mock_service.send_verification_email = AsyncMock(return_value=True)
            mock_service.verify_code = AsyncMock(return_value=True)

            send_response = await client.post(
                "/api/v1/email/send-code",
                json={"email": email}
            )

        assert send_response.status_code == 200

        # 步骤2: 验证验证码
        with patch("app.api.v1.email_verification.email_service") as mock_service:
            mock_service.verify_code = AsyncMock(return_value=True)

            verify_response = await client.post(
                "/api/v1/email/verify-code",
                json={"email": email, "code": sent_code}
            )

        assert verify_response.status_code == 200

        # 验证用户状态
        await db_session.refresh(user)
        assert user.is_verified is True

    async def test_resend_code_multiple_times(self, client: AsyncClient):
        """测试多次重新发送验证码"""
        with patch("app.api.v1.email_verification.email_service") as mock_service:
            mock_service.generate_code = lambda length: "111111"
            mock_service.save_code = AsyncMock()
            mock_service.send_verification_email = AsyncMock(return_value=True)

            # 第一次发送
            response1 = await client.post(
                "/api/v1/email/send-code",
                json={"email": "resend@example.com"}
            )
            assert response1.status_code == 200

            # 第二次发送（覆盖之前的验证码）
            mock_service.generate_code = lambda length: "222222"
            response2 = await client.post(
                "/api/v1/email/send-code",
                json={"email": "resend@example.com"}
            )
            assert response2.status_code == 200
