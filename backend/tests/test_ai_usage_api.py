"""
AI 使用统计和计费 API 集成测试
"""
import pytest
from httpx import AsyncClient
from sqlalchemy.ext.asyncio import AsyncSession
from unittest.mock import AsyncMock, patch, MagicMock
from datetime import datetime, timedelta


@pytest.mark.asyncio
class TestAIUsageStats:
    """AI 使用统计测试"""

    async def test_get_usage_stats_default_period(
        self, client: AsyncClient, test_user, auth_headers: dict
    ):
        """测试获取默认30天的使用统计"""
        mock_stats = {
            "period_days": 30,
            "total_calls": 100,
            "total_tokens": 50000,
            "total_cost": 0.5,
            "by_provider": [
                {"provider": "openai", "calls": 60, "tokens": 30000, "cost": 0.4},
                {"provider": "deepseek", "calls": 40, "tokens": 20000, "cost": 0.1}
            ],
            "by_operation": [
                {"operation": "generate_resume", "calls": 50, "tokens": 25000, "cost": 0.25},
                {"operation": "optimize_resume", "calls": 30, "tokens": 15000, "cost": 0.15},
                {"operation": "generate_cover_letter", "calls": 20, "tokens": 10000, "cost": 0.1}
            ]
        }

        with patch("app.api.v1.ai_usage.get_ai_usage_service") as mock_get_service:
            mock_service = AsyncMock()
            mock_service.get_user_usage_stats = AsyncMock(return_value=mock_stats)
            mock_get_service.return_value = mock_service

            response = await client.get(
                "/api/v1/ai/usage/stats",
                headers=auth_headers
            )

        assert response.status_code == 200
        data = response.json()
        assert data["code"] == 200
        assert data["data"]["period_days"] == 30
        assert data["data"]["total_calls"] == 100
        assert data["data"]["total_cost"] == 0.5

    async def test_get_usage_stats_custom_period(
        self, client: AsyncClient, test_user, auth_headers: dict
    ):
        """测试获取自定义周期的使用统计"""
        mock_stats = {
            "period_days": 7,
            "total_calls": 20,
            "total_tokens": 10000,
            "total_cost": 0.1,
            "by_provider": [],
            "by_operation": []
        }

        with patch("app.api.v1.ai_usage.get_ai_usage_service") as mock_get_service:
            mock_service = AsyncMock()
            mock_service.get_user_usage_stats = AsyncMock(return_value=mock_stats)
            mock_get_service.return_value = mock_service

            response = await client.get(
                "/api/v1/ai/usage/stats?days=7",
                headers=auth_headers
            )

        assert response.status_code == 200
        assert response.json()["data"]["period_days"] == 7

    async def test_get_usage_stats_unauthorized(self, client: AsyncClient):
        """测试未授权访问统计"""
        response = await client.get("/api/v1/ai/usage/stats")
        assert response.status_code == 401


@pytest.mark.asyncio
class TestAIUsageLimits:
    """AI 使用限制测试"""

    async def test_get_limit_info_free_tier(
        self, client: AsyncClient, test_user, auth_headers: dict
    ):
        """测试获取免费用户限制信息"""
        mock_limit = MagicMock()
        mock_limit.tier = "free"

        with patch("app.api.v1.ai_usage.get_ai_usage_service") as mock_get_service:
            mock_service = AsyncMock()
            mock_service.get_user_limit = AsyncMock(return_value=mock_limit)
            mock_service.check_daily_limit = AsyncMock(return_value=(True, 10, 100))
            mock_service.check_monthly_limit = AsyncMock(return_value=(True, 50, 1000))
            mock_get_service.return_value = mock_service

            response = await client.get(
                "/api/v1/ai/usage/limits",
                headers=auth_headers
            )

        assert response.status_code == 200
        data = response.json()["data"]
        assert data["tier"] == "free"
        assert data["daily_used"] == 10
        assert data["daily_limit"] == 100
        assert data["daily_remaining"] == 90
        assert data["monthly_used"] == 50
        assert data["monthly_limit"] == 1000
        assert data["monthly_remaining"] == 950

    async def test_get_limit_info_pro_tier(
        self, client: AsyncClient, test_user, auth_headers: dict
    ):
        """测试获取 Pro 用户限制信息"""
        mock_limit = MagicMock()
        mock_limit.tier = "pro"

        with patch("app.api.v1.ai_usage.get_ai_usage_service") as mock_get_service:
            mock_service = AsyncMock()
            mock_service.get_user_limit = AsyncMock(return_value=mock_limit)
            mock_service.check_daily_limit = AsyncMock(return_value=(True, 500, 1000))
            mock_service.check_monthly_limit = AsyncMock(return_value=(True, 5000, 10000))
            mock_get_service.return_value = mock_service

            response = await client.get(
                "/api/v1/ai/usage/limits",
                headers=auth_headers
            )

        assert response.status_code == 200
        data = response.json()["data"]
        assert data["tier"] == "pro"
        assert data["daily_limit"] == 1000
        assert data["monthly_limit"] == 10000

    async def test_get_limit_info_when_exceeded(
        self, client: AsyncClient, test_user, auth_headers: dict
    ):
        """测试获取限制信息时已超出限额"""
        mock_limit = MagicMock()
        mock_limit.tier = "free"

        with patch("app.api.v1.ai_usage.get_ai_usage_service") as mock_get_service:
            mock_service = AsyncMock()
            mock_service.get_user_limit = AsyncMock(return_value=mock_limit)
            mock_service.check_daily_limit = AsyncMock(return_value=(False, 100, 100))
            mock_service.check_monthly_limit = AsyncMock(return_value=(False, 1000, 1000))
            mock_get_service.return_value = mock_service

            response = await client.get(
                "/api/v1/ai/usage/limits",
                headers=auth_headers
            )

        assert response.status_code == 200
        data = response.json()["data"]
        assert data["daily_remaining"] == 0
        assert data["monthly_remaining"] == 0

    async def test_get_limit_info_unauthorized(self, client: AsyncClient):
        """测试未授权访问限制信息"""
        response = await client.get("/api/v1/ai/usage/limits")
        assert response.status_code == 401


@pytest.mark.asyncio
class TestBillingCurrent:
    """当前计费周期测试"""

    async def test_get_current_billing(
        self, client: AsyncClient, test_user, auth_headers: dict
    ):
        """测试获取当前计费周期"""
        mock_billing = MagicMock()
        mock_billing.billing_period = "2026-05"
        mock_billing.period_start = datetime(2026, 5, 1)
        mock_billing.period_end = datetime(2026, 5, 31)
        mock_billing.total_calls = 50
        mock_billing.total_tokens = 25000
        mock_billing.total_cost = 0.25
        mock_billing.balance = 9.75
        mock_billing.status = "active"

        with patch("app.api.v1.ai_usage.get_ai_usage_service") as mock_get_service:
            mock_service = AsyncMock()
            mock_service.ensure_billing_period = AsyncMock(return_value=mock_billing)
            mock_get_service.return_value = mock_service

            response = await client.get(
                "/api/v1/ai/billing/current",
                headers=auth_headers
            )

        assert response.status_code == 200
        data = response.json()["data"]
        assert data["period"] == "2026-05"
        assert "2026-05-01" in data["period_start"]
        assert "2026-05-31" in data["period_end"]
        assert data["total_calls"] == 50
        assert data["total_tokens"] == 25000
        assert data["total_cost"] == 0.25
        assert data["balance"] == 9.75
        assert data["status"] == "active"

    async def test_get_current_billing_new_user(
        self, client: AsyncClient, test_user, auth_headers: dict
    ):
        """测试新用户的计费周期（无使用记录）"""
        mock_billing = MagicMock()
        mock_billing.billing_period = "2026-05"
        mock_billing.period_start = datetime.now().replace(day=1)
        mock_billing.period_end = (datetime.now().replace(day=1) + timedelta(days=32)).replace(day=1) - timedelta(days=1)
        mock_billing.total_calls = 0
        mock_billing.total_tokens = 0
        mock_billing.total_cost = 0
        mock_billing.balance = 10.0
        mock_billing.status = "active"

        with patch("app.api.v1.ai_usage.get_ai_usage_service") as mock_get_service:
            mock_service = AsyncMock()
            mock_service.ensure_billing_period = AsyncMock(return_value=mock_billing)
            mock_get_service.return_value = mock_service

            response = await client.get(
                "/api/v1/ai/billing/current",
                headers=auth_headers
            )

        assert response.status_code == 200
        data = response.json()["data"]
        assert data["total_calls"] == 0
        assert data["total_cost"] == 0
        assert data["balance"] == 10.0

    async def test_get_current_billing_unauthorized(self, client: AsyncClient):
        """测试未授权访问计费信息"""
        response = await client.get("/api/v1/ai/billing/current")
        assert response.status_code == 401


@pytest.mark.asyncio
class TestAIUsageIntegration:
    """AI 使用统计集成测试"""

    async def test_full_usage_workflow(
        self, client: AsyncClient, test_user, auth_headers: dict
    ):
        """测试完整的使用统计工作流"""
        # Mock setup
        mock_limit = MagicMock()
        mock_limit.tier = "free"

        mock_billing = MagicMock()
        mock_billing.billing_period = "2026-05"
        mock_billing.period_start = datetime(2026, 5, 1)
        mock_billing.period_end = datetime(2026, 5, 31)
        mock_billing.total_calls = 75
        mock_billing.total_tokens = 37500
        mock_billing.total_cost = 0.375
        mock_billing.balance = 9.625
        mock_billing.status = "active"

        mock_stats = {
            "period_days": 30,
            "total_calls": 75,
            "total_tokens": 37500,
            "total_cost": 0.375,
            "by_provider": [{"provider": "openai", "calls": 75, "tokens": 37500, "cost": 0.375}],
            "by_operation": [{"operation": "generate_resume", "calls": 75, "tokens": 37500, "cost": 0.375}]
        }

        with patch("app.api.v1.ai_usage.get_ai_usage_service") as mock_get_service:
            mock_service = AsyncMock()
            mock_service.get_user_limit = AsyncMock(return_value=mock_limit)
            mock_service.check_daily_limit = AsyncMock(return_value=(True, 75, 100))
            mock_service.check_monthly_limit = AsyncMock(return_value=(True, 750, 1000))
            mock_service.ensure_billing_period = AsyncMock(return_value=mock_billing)
            mock_service.get_user_usage_stats = AsyncMock(return_value=mock_stats)
            mock_get_service.return_value = mock_service

            # 获取限制信息
            limits_response = await client.get(
                "/api/v1/ai/usage/limits",
                headers=auth_headers
            )
            assert limits_response.status_code == 200

            # 获取计费信息
            billing_response = await client.get(
                "/api/v1/ai/billing/current",
                headers=auth_headers
            )
            assert billing_response.status_code == 200

            # 获取使用统计
            stats_response = await client.get(
                "/api/v1/ai/usage/stats",
                headers=auth_headers
            )
            assert stats_response.status_code == 200
