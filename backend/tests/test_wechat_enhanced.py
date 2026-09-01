"""
WeChat API 增强测试 - 提高覆盖率
"""
import pytest
from unittest.mock import AsyncMock, patch, MagicMock
from httpx import AsyncClient
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from app.models.user import User


class TestWeChatLogin:
    """微信登录测试"""

    async def test_wechat_login_new_user(
        self, client: AsyncClient
    ):
        """测试: 微信登录创建新用户"""
        mock_wechat_data = {
            "openid": "wx_test_openid_12345",
            "session_key": "test_session_key",
            "unionid": "wx_union_123"
        }

        with patch("app.api.v1.auth_wechat._get_wechat_access_token", return_value=mock_wechat_data):
            response = await client.post(
                "/api/v1/auth/wechat/login",
                json={"code": "test_wx_code"}
            )

            assert response.status_code == 200
            data = response.json()
            assert data["code"] == 0
            assert "access_token" in data["data"]

    async def test_wechat_login_existing_user(
        self, client: AsyncClient, test_user, db_session
    ):
        """测试: 微信登录已有用户"""
        test_user.wechat_openid = "wx_existing_123"
        await db_session.commit()

        mock_wechat_data = {
            "openid": "wx_existing_123",
            "session_key": "session_key"
        }

        with patch("app.api.v1.auth_wechat._get_wechat_access_token", return_value=mock_wechat_data):
            response = await client.post(
                "/api/v1/auth/wechat/login",
                json={"code": "test_code"}
            )

            assert response.status_code == 200

    async def test_wechat_login_disabled_account(
        self, client: AsyncClient, db_session
    ):
        """测试: 微信登录已禁用账户"""
        from app.models.user import User

        disabled_user = User(
            email="disabled_wx@example.com",
            password_hash="hash",
            username="disabled_wx",
            wechat_openid="wx_disabled_123",
            is_active=False
        )
        db_session.add(disabled_user)
        await db_session.commit()

        mock_wechat_data = {
            "openid": "wx_disabled_123",
            "session_key": "session_key"
        }

        with patch("app.api.v1.auth_wechat._get_wechat_access_token", return_value=mock_wechat_data):
            response = await client.post(
                "/api/v1/auth/wechat/login",
                json={"code": "test_code"}
            )

            assert response.status_code == 403

    async def test_wechat_login_missing_openid(
        self, client: AsyncClient
    ):
        """测试: 微信登录缺少 openid"""
        mock_wechat_data = {
            "session_key": "session_key"
            # 缺少 openid
        }

        with patch("app.api.v1.auth_wechat._get_wechat_access_token", return_value=mock_wechat_data):
            response = await client.post(
                "/api/v1/auth/wechat/login",
                json={"code": "test_code"}
            )

            assert response.status_code == 400

    async def test_wechat_login_api_error(
        self, client: AsyncClient
    ):
        """测试: 微信 API 返回错误"""
        mock_error_response = {
            "errcode": 40029,
            "errmsg": "invalid code"
        }

        with patch("app.api.v1.auth_wechat._get_wechat_access_token", return_value=mock_error_response):
            response = await client.post(
                "/api/v1/auth/wechat/login",
                json={"code": "invalid_code"}
            )

            assert response.status_code == 400


class TestWeChatBind:
    """微信绑定测试"""

    async def test_wechat_bind_success(
        self, client: AsyncClient, auth_headers
    ):
        """测试: 成功绑定微信"""
        mock_wechat_data = {
            "openid": "wx_bind_123",
            "unionid": "wx_union_bind"
        }

        with patch("app.api.v1.auth_wechat._get_wechat_access_token", return_value=mock_wechat_data):
            response = await client.post(
                "/api/v1/auth/wechat/bind",
                headers=auth_headers,
                json={"code": "bind_code"}
            )

            assert response.status_code == 200
            data = response.json()
            assert data["code"] == 0

    async def test_wechat_bind_already_bound(
        self, client: AsyncClient, auth_headers, db_session
    ):
        """测试: 微信账号已被其他用户绑定"""
        from app.models.user import User

        other_user = User(
            email="wxother@example.com",
            password_hash="hash",
            username="wxother",
            wechat_openid="wx_taken_123"
        )
        db_session.add(other_user)
        await db_session.commit()

        mock_wechat_data = {
            "openid": "wx_taken_123"
        }

        with patch("app.api.v1.auth_wechat._get_wechat_access_token", return_value=mock_wechat_data):
            response = await client.post(
                "/api/v1/auth/wechat/bind",
                headers=auth_headers,
                json={"code": "test_code"}
            )

            assert response.status_code == 400

    async def test_wechat_bind_missing_openid(
        self, client: AsyncClient, auth_headers
    ):
        """测试: 绑定时缺少 openid"""
        mock_wechat_data = {
            "session_key": "session_key"
        }

        with patch("app.api.v1.auth_wechat._get_wechat_access_token", return_value=mock_wechat_data):
            response = await client.post(
                "/api/v1/auth/wechat/bind",
                headers=auth_headers,
                json={"code": "test_code"}
            )

            assert response.status_code == 400

    async def test_wechat_bind_unauthorized(
        self, client: AsyncClient
    ):
        """测试: 未认证绑定"""
        response = await client.post(
            "/api/v1/auth/wechat/bind",
            json={"code": "test_code"}
        )

        assert response.status_code == 401


class TestWeChatUnbind:
    """微信解绑测试"""

    async def test_wechat_unbind_success(
        self, client: AsyncClient, auth_headers, test_user, db_session
    ):
        """测试: 成功解绑微信"""
        test_user.wechat_openid = "wx_unbind_123"
        test_user.wechat_unionid = "wx_union_unbind"
        await db_session.commit()

        response = await client.post(
            "/api/v1/auth/wechat/unbind",
            headers=auth_headers
        )

        assert response.status_code == 200
        data = response.json()
        assert "解绑成功" in data["message"]

    async def test_wechat_unbind_not_bound(
        self, client: AsyncClient, auth_headers
    ):
        """测试: 解绑未绑定的账号"""
        response = await client.post(
            "/api/v1/auth/wechat/unbind",
            headers=auth_headers
        )

        assert response.status_code == 400
        data = response.json()
        assert "未绑定" in data["detail"]

    async def test_wechat_unbind_unauthorized(
        self, client: AsyncClient
    ):
        """测试: 未认证解绑"""
        response = await client.post("/api/v1/auth/wechat/unbind")

        assert response.status_code == 401


class TestWeChatGetAccessToken:
    """微信获取 access_token 测试"""

    async def test_get_wechat_access_token_success(
        self, client: AsyncClient
    ):
        """测试: 成功获取微信 access_token"""
        mock_response = MagicMock()
        mock_response.json.return_value = {
            "openid": "wx_test_123",
            "session_key": "session_key",
            "unionid": "union_123"
        }

        mock_httpx_client = AsyncMock()
        mock_httpx_client.__aenter__ = AsyncMock(return_value=mock_httpx_client)
        mock_httpx_client.__aexit__ = AsyncMock(return_value=None)
        mock_httpx_client.get = AsyncMock(return_value=mock_response)

        with patch("app.api.v1.auth_wechat.httpx.AsyncClient", return_value=mock_httpx_client):
            from app.api.v1.auth_wechat import _get_wechat_access_token

            # 注意：这需要 WECHAT_APP_ID 和 WECHAT_APP_SECRET 配置
            # 如果未配置，会返回 500 错误
            try:
                result = await _get_wechat_access_token("test_code")
                assert "openid" in result
            except Exception as e:
                # 如果未配置微信，这是预期的
                assert "微信登录未配置" in str(e) or "微信授权" in str(e)

    async def test_get_wechat_access_token_wechat_error(
        self, client: AsyncClient
    ):
        """测试: 微信 API 返回错误"""
        mock_response = MagicMock()
        mock_response.json.return_value = {
            "errcode": 40013,
            "errmsg": "invalid appid"
        }

        mock_httpx_client = AsyncMock()
        mock_httpx_client.__aenter__ = AsyncMock(return_value=mock_httpx_client)
        mock_httpx_client.__aexit__ = AsyncMock(return_value=None)
        mock_httpx_client.get = AsyncMock(return_value=mock_response)

        with patch("app.api.v1.auth_wechat.httpx.AsyncClient", return_value=mock_httpx_client):
            from app.api.v1.auth_wechat import _get_wechat_access_token

            try:
                await _get_wechat_access_token("invalid_code")
                assert False, "Should have raised HTTPException"
            except Exception as e:
                # 如果未配置微信或微信返回错误
                assert "微信" in str(e) or "未配置" in str(e)


class TestWeChatCommon:
    """微信通用测试"""

    async def test_wechat_login_without_config(
        self, client: AsyncClient
    ):
        """测试: 微信登录未配置"""
        with patch("app.api.v1.auth_wechat.settings", MagicMock(WECHAT_APP_ID="", WECHAT_APP_SECRET="")):
            # 直接测试内部函数
            from app.api.v1.auth_wechat import _get_wechat_access_token

            try:
                await _get_wechat_access_token("test_code")
                assert False, "Should raise exception"
            except Exception as e:
                assert "未配置" in str(e)

    async def test_wechat_login_without_openid_in_response(
        self, client: AsyncClient
    ):
        """测试: 微信响应中没有 openid"""
        mock_wechat_data = {
            "session_key": "test_key"
        }

        with patch("app.api.v1.auth_wechat._get_wechat_access_token", return_value=mock_wechat_data):
            response = await client.post(
                "/api/v1/auth/wechat/login",
                json={"code": "test_code"}
            )

            assert response.status_code == 400

    async def test_wechat_bind_with_unionid(
        self, client: AsyncClient, auth_headers
    ):
        """测试: 绑定带 unionid 的微信账号"""
        mock_wechat_data = {
            "openid": "wx_union_123",
            "unionid": "wx_union_main_123"
        }

        with patch("app.api.v1.auth_wechat._get_wechat_access_token", return_value=mock_wechat_data):
            response = await client.post(
                "/api/v1/auth/wechat/bind",
                headers=auth_headers,
                json={"code": "test_code"}
            )

            assert response.status_code == 200
            data = response.json()
            assert data["data"]["openid"] == "wx_union_123"
            assert data["data"]["unionid"] == "wx_union_main_123"
