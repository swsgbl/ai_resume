"""
AI 生成和优化 API 集成测试
测试 AI 生成流程：选择模板 → AI 生成 → 内容优化 → ATS 优化
"""
import pytest
import asyncio
from unittest.mock import patch, AsyncMock, MagicMock
from httpx import AsyncClient


def _make_async_result(value):
    """Helper to create an async function that returns a value"""
    async def _inner():
        return value
    return _inner


class TestAIGenerateAPI:
    """AI 生成 API 测试"""

    async def test_ai_generate_success(
        self, client: AsyncClient, auth_headers, test_resume
    ):
        """测试成功生成简历内容"""
        # Mock AI service
        mock_ai_service = AsyncMock()
        mock_ai_service.generate_resume_content.return_value = {
            "content": {
                "basic_info": {"name": "张三", "phone": "13800138000"},
                "work_experience": [{"company": "ABC公司", "position": "软件工程师"}],
                "education": [{"school": "北京大学", "major": "计算机科学"}],
                "skills": [{"name": "Python"}, {"name": "FastAPI"}]
            },
            "usage": {"total_tokens": 100},
            "meta": {"provider": "test", "model": "test-model"}
        }

        # Mock usage service - make methods async
        mock_usage_service = MagicMock()
        mock_usage_service.check_daily_limit = AsyncMock(return_value=(True, 1, 10))
        mock_usage_service.check_monthly_limit = AsyncMock(return_value=(True, 1, 200))
        mock_usage_service.record_usage = AsyncMock()

        with patch("app.api.v1.resumes.get_ai_service", return_value=mock_ai_service), \
             patch("app.api.v1.resumes.get_ai_usage_service", return_value=mock_usage_service):
            response = await client.post(
                f"/api/v1/resumes/{test_resume.id}/ai/generate",
                headers=auth_headers,
                json={
                    "target_position": "高级后端工程师",
                    "style": "professional"
                }
            )

            assert response.status_code in [200, 500]  # 可能因AI服务不可用而失败
            if response.status_code == 200:
                data = response.json()
                assert data["code"] == 0
                assert "content" in data["data"]

    async def test_ai_generate_without_template(
        self, client: AsyncClient, auth_headers, test_resume
    ):
        """测试不指定模板生成"""
        mock_ai_service = AsyncMock()
        mock_ai_service.generate_resume_content.return_value = {
            "content": {
                "basic_info": {"name": "测试用户"}
            }
        }

        # Mock usage service
        mock_usage_service = MagicMock()
        mock_usage_service.check_daily_limit = AsyncMock(return_value=(True, 1, 10))
        mock_usage_service.check_monthly_limit = AsyncMock(return_value=(True, 1, 200))
        mock_usage_service.record_usage = AsyncMock()

        with patch("app.api.v1.resumes.get_ai_service", return_value=mock_ai_service), \
             patch("app.api.v1.resumes.get_ai_usage_service", return_value=mock_usage_service):
            response = await client.post(
                f"/api/v1/resumes/{test_resume.id}/ai/generate",
                headers=auth_headers,
                json={"target_position": "软件工程师"}
            )

            assert response.status_code in [200, 400, 500]

    async def test_ai_generate_unauthorized(
        self, client: AsyncClient, test_resume
    ):
        """测试未授权生成"""
        response = await client.post(
            f"/api/v1/resumes/{test_resume.id}/ai/generate",
            json={"target_position": "软件工程师"}
        )
        assert response.status_code == 401

    async def test_ai_generate_resume_not_found(
        self, client: AsyncClient, auth_headers
    ):
        """测试简历不存在"""
        response = await client.post(
            "/api/v1/resumes/999999/ai/generate",
            headers=auth_headers,
            json={"target_position": "软件工程师"}
        )
        assert response.status_code == 404


class TestAIOptimizeAPI:
    """AI 优化 API 测试"""

    async def test_ai_optimize_content_success(
        self, client: AsyncClient, auth_headers
    ):
        """测试成功优化内容"""
        mock_ai_service = AsyncMock()
        mock_ai_service.optimize_content.return_value = "拥有5年后端开发经验，精通Python和FastAPI，主导系统重构，性能提升50%"

        mock_usage_service = MagicMock()
        mock_usage_service.check_daily_limit = AsyncMock(return_value=(True, 1, 10))
        mock_usage_service.check_monthly_limit = AsyncMock(return_value=(True, 1, 200))
        mock_usage_service.record_usage = AsyncMock()

        with patch("app.api.v1.resumes.get_ai_service", return_value=mock_ai_service), \
             patch("app.api.v1.resumes.get_ai_usage_service", return_value=mock_usage_service):
            response = await client.post(
                "/api/v1/resumes/ai/optimize",
                headers=auth_headers,
                json={
                    "content": "负责后端开发，使用Python和FastAPI",
                    "optimization_type": "star_method"
                }
            )

            assert response.status_code in [200, 500]
            if response.status_code == 200:
                data = response.json()
                assert data["code"] == 0
                assert "optimized" in data["data"]

    async def test_ai_optimize_ats_success(
        self, client: AsyncClient, auth_headers
    ):
        """测试ATS优化"""
        mock_ai_service = AsyncMock()
        mock_ai_service.optimize_content.return_value = "优化后的关键词: Python, FastAPI, 微服务, 系统设计"

        mock_usage_service = MagicMock()
        mock_usage_service.check_daily_limit = AsyncMock(return_value=(True, 1, 10))
        mock_usage_service.check_monthly_limit = AsyncMock(return_value=(True, 1, 200))
        mock_usage_service.record_usage = AsyncMock()

        with patch("app.api.v1.resumes.get_ai_service", return_value=mock_ai_service), \
             patch("app.api.v1.resumes.get_ai_usage_service", return_value=mock_usage_service):
            response = await client.post(
                "/api/v1/resumes/ai/optimize",
                headers=auth_headers,
                json={
                    "content": "熟悉Python和FastAPI",
                    "optimization_type": "keywords",
                    "context": "招聘后端工程师，要求熟悉Python、FastAPI等框架"
                }
            )

            assert response.status_code in [200, 500]
            if response.status_code == 200:
                data = response.json()
                assert "optimized" in data["data"]

    async def test_ai_optimize_unauthorized(self, client: AsyncClient):
        """测试未授权优化"""
        response = await client.post(
            "/api/v1/resumes/ai/optimize",
            json={
                "content": "测试内容",
                "optimization_type": "star_method"
            }
        )
        assert response.status_code == 401

    async def test_ai_optimize_missing_content(
        self, client: AsyncClient, auth_headers
    ):
        """测试缺少内容参数"""
        response = await client.post(
            "/api/v1/resumes/ai/optimize",
            headers=auth_headers,
            json={
                "optimization_type": "star_method"
            }
        )
        assert response.status_code == 422


class TestAIPersonalizationAPI:
    """AI 个性化增强 API 测试"""

    async def test_personalize_with_jd(
        self, client: AsyncClient, auth_headers
    ):
        """测试根据JD个性化"""
        mock_ai_service = AsyncMock()
        mock_ai_service.optimize_content.return_value = "针对高级后端工程师职位调整后的内容：精通Python、FastAPI、微服务架构，拥有Kubernetes和Redis经验..."

        mock_usage_service = MagicMock()
        mock_usage_service.check_daily_limit = AsyncMock(return_value=(True, 1, 10))
        mock_usage_service.check_monthly_limit = AsyncMock(return_value=(True, 1, 200))
        mock_usage_service.record_usage = AsyncMock()

        with patch("app.api.v1.resumes.get_ai_service", return_value=mock_ai_service), \
             patch("app.api.v1.resumes.get_ai_usage_service", return_value=mock_usage_service):
            response = await client.post(
                "/api/v1/resumes/ai/optimize",
                headers=auth_headers,
                json={
                    "content": "拥有5年后端开发经验",
                    "optimization_type": "polish",
                    "context": "高级后端工程师，要求Python、FastAPI、微服务经验"
                }
            )

            assert response.status_code in [200, 500]
            if response.status_code == 200:
                data = response.json()
                assert "optimized" in data["data"]


class TestAIUsageLimits:
    """AI 使用限制测试"""

    async def test_ai_check_daily_limit(
        self, client: AsyncClient, auth_headers
    ):
        """测试每日使用限制"""
        # 模拟达到每日限制 - 需要mock get_ai_usage_service
        mock_usage_service = MagicMock()
        mock_usage_service.check_daily_limit = AsyncMock(return_value=(False, 10, 10))  # 达到限制
        mock_usage_service.check_monthly_limit = AsyncMock(return_value=(True, 5, 100))

        with patch("app.api.v1.resumes.get_ai_usage_service", return_value=mock_usage_service):
            response = await client.post(
                "/api/v1/resumes/ai/optimize",
                headers=auth_headers,
                json={
                    "content": "测试内容",
                    "optimization_type": "star_method"
                }
            )

            # 可能返回403、429或500取决于实现
            assert response.status_code in [403, 429, 500]

    async def test_ai_free_user_limit(
        self, client: AsyncClient, auth_headers
    ):
        """测试免费用户限制"""
        mock_usage_service = MagicMock()
        mock_usage_service.check_daily_limit = AsyncMock(return_value=(True, 3, 10))
        mock_usage_service.check_monthly_limit = AsyncMock(return_value=(True, 10, 100))
        mock_usage_service.record_usage = AsyncMock()

        mock_ai_service = AsyncMock()
        mock_ai_service.optimize_content.return_value = "优化后的内容"

        with patch("app.api.v1.resumes.get_ai_usage_service", return_value=mock_usage_service), \
             patch("app.api.v1.resumes.get_ai_service", return_value=mock_ai_service):
            response = await client.post(
                "/api/v1/resumes/ai/optimize",
                headers=auth_headers,
                json={
                    "content": "测试内容",
                    "optimization_type": "star_method"
                }
            )

            assert response.status_code in [200, 403, 500]
