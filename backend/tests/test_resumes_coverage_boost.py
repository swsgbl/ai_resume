"""
提高 resumes.py 覆盖率的补充测试
"""
import pytest
from httpx import AsyncClient
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from unittest.mock import patch, AsyncMock

from app.models.user import User
from app.models.resume import Resume, ResumeVersion
from app.models.template import Template
from app.services.ai_limit_decorator import AIUsageLimitExceeded


@pytest.mark.usefixtures("db_session")
class TestResumesCoverageBoost:
    """提高 resumes.py 覆盖率"""

    async def test_get_resume_success(
        self, client: AsyncClient, auth_headers, test_resume
    ):
        """测试: 获取简历详情成功"""
        response = await client.get(
            f"/api/v1/resumes/{test_resume.id}",
            headers=auth_headers
        )

        assert response.status_code == 200
        data = response.json()
        assert data["data"]["id"] == test_resume.id

    async def test_get_resume_not_found(
        self, client: AsyncClient, auth_headers
    ):
        """测试: 获取不存在的简历"""
        response = await client.get(
            "/api/v1/resumes/99999",
            headers=auth_headers
        )

        assert response.status_code == 404

    async def test_list_resumes_with_status(
        self, client: AsyncClient, auth_headers, test_user, db_session: AsyncSession
    ):
        """测试: 带状态筛选的简历列表"""
        # 创建不同状态的简历
        for status in ["draft", "published"]:
            resume = Resume(
                user_id=test_user.id,
                title=f"{status}简历",
                content={},
                status=status
            )
            db_session.add(resume)
        await db_session.commit()

        response = await client.get(
            "/api/v1/resumes?status=draft",
            headers=auth_headers
        )

        assert response.status_code == 200
        data = response.json()
        for item in data["data"]:
            assert item["status"] == "draft"

    async def test_list_resumes_pagination(
        self, client: AsyncClient, auth_headers, test_user, db_session: AsyncSession
    ):
        """测试: 分页功能"""
        # 创建多个简历
        for i in range(5):
            resume = Resume(
                user_id=test_user.id,
                title=f"简历{i}",
                content={}
            )
            db_session.add(resume)
        await db_session.commit()

        response = await client.get(
            "/api/v1/resumes?page=1&page_size=3",
            headers=auth_headers
        )

        assert response.status_code == 200
        data = response.json()
        assert len(data["data"]) == 3
        assert data["page"] == 1
        assert data["page_size"] == 3

    async def test_create_resume_full(
        self, client: AsyncClient, auth_headers, test_user, db_session: AsyncSession
    ):
        """测试: 创建完整简历"""
        # 先创建模板
        template = Template(
            name="测试模板",
            category="技术",
            layout="modern",
            is_active=True
        )
        db_session.add(template)
        await db_session.commit()
        await db_session.refresh(template)

        response = await client.post(
            "/api/v1/resumes",
            headers=auth_headers,
            json={
                "title": "完整简历",
                "description": "完整描述",
                "template_id": template.id,
                "content": {"basic_info": {"name": "测试"}},
                "style_config": {"theme": "blue"}
            }
        )

        assert response.status_code == 200
        data = response.json()
        assert data["data"]["title"] == "完整简历"
        assert data["data"]["description"] == "完整描述"
        assert data["data"]["template_id"] == template.id

    async def test_update_resume_full(
        self, client: AsyncClient, auth_headers, test_resume, db_session: AsyncSession
    ):
        """测试: 完整更新简历"""
        original_version = test_resume.version

        response = await client.put(
            f"/api/v1/resumes/{test_resume.id}",
            headers=auth_headers,
            json={
                "title": "更新标题",
                "description": "更新描述",
                "content": {"updated": "content"},
                "style_config": {"theme": "red"},
                "status": "published"
            }
        )

        assert response.status_code == 200
        data = response.json()
        assert data["data"]["title"] == "更新标题"
        assert data["data"]["version"] == original_version + 1

    async def test_ai_optimize_monthly_limit_exceeded(
        self, client: AsyncClient, auth_headers
    ):
        """测试: 超出每月限额"""
        mock_usage_service = AsyncMock()
        mock_usage_service.check_daily_limit = AsyncMock(return_value=(True, 1, 100))
        # 超出每月限额
        mock_usage_service.check_monthly_limit = AsyncMock(return_value=(False, 1000, 1000))

        with patch("app.api.v1.resumes.get_ai_usage_service", return_value=mock_usage_service):
            response = await client.post(
                "/api/v1/resumes/ai/optimize",
                headers=auth_headers,
                json={
                    "content": "测试内容",
                    "optimization_type": "polish"
                }
            )

        # 可能是 413 (usage exceeded) 或 429 (rate limit)
        assert response.status_code in [413, 429]

    async def test_ai_optimize_success(
        self, client: AsyncClient, auth_headers
    ):
        """测试: AI 优化成功"""
        mock_ai_service = AsyncMock()
        mock_ai_service.optimize_content = AsyncMock(return_value="优化后内容")

        mock_usage_service = AsyncMock()
        mock_usage_service.check_daily_limit = AsyncMock(return_value=(True, 1, 100))
        mock_usage_service.check_monthly_limit = AsyncMock(return_value=(True, 1, 1000))
        mock_usage_service.record_usage = AsyncMock()

        with patch("app.api.v1.resumes.get_ai_service", return_value=mock_ai_service), \
             patch("app.api.v1.resumes.get_ai_usage_service", return_value=mock_usage_service):
            response = await client.post(
                "/api/v1/resumes/ai/optimize",
                headers=auth_headers,
                json={
                    "content": "原始内容",
                    "optimization_type": "polish"
                }
            )

        assert response.status_code == 200
        data = response.json()
        # 响应包含 original, optimized, suggestions
        assert data["data"]["optimized"] == "优化后内容"

    async def test_ai_optimize_with_context(
        self, client: AsyncClient, auth_headers
    ):
        """测试: 带上下文的 AI 优化"""
        mock_ai_service = AsyncMock()
        mock_ai_service.optimize_content = AsyncMock(return_value="针对目标职位优化后")

        mock_usage_service = AsyncMock()
        mock_usage_service.check_daily_limit = AsyncMock(return_value=(True, 1, 100))
        mock_usage_service.check_monthly_limit = AsyncMock(return_value=(True, 1, 1000))

        with patch("app.api.v1.resumes.get_ai_service", return_value=mock_ai_service), \
             patch("app.api.v1.resumes.get_ai_usage_service", return_value=mock_usage_service):
            response = await client.post(
                "/api/v1/resumes/ai/optimize",
                headers=auth_headers,
                json={
                    "content": "原始内容",
                    "optimization_type": "polish",
                    "context": "软件工程师"  # 简化为字符串
                }
            )

        assert response.status_code == 200

    async def test_ai_generate_daily_limit_exceeded(
        self, client: AsyncClient, auth_headers, test_user, db_session: AsyncSession
    ):
        """测试: 超出每日限额"""
        # 需要先创建简历
        resume = Resume(
            user_id=test_user.id,
            title="测试",
            content={},
            version=1
        )
        db_session.add(resume)
        await db_session.commit()
        await db_session.refresh(resume)

        mock_usage_service = AsyncMock()
        # 超出每日限额
        mock_usage_service.check_daily_limit = AsyncMock(return_value=(False, 100, 100))
        mock_usage_service.check_monthly_limit = AsyncMock(return_value=(True, 1, 1000))

        with patch("app.api.v1.resumes.get_ai_usage_service", return_value=mock_usage_service):
            response = await client.post(
                f"/api/v1/resumes/{resume.id}/ai/generate",
                headers=auth_headers,
                json={"target_position": "工程师"}
            )

        # 可能是 413 (usage exceeded) 或 429 (rate limit)
        assert response.status_code in [413, 429]

    async def test_get_ai_service_called(
        self, client: AsyncClient, auth_headers, test_user, db_session: AsyncSession
    ):
        """测试: get_ai_service 被调用"""
        resume = Resume(
            user_id=test_user.id,
            title="测试",
            content={},
            version=1
        )
        db_session.add(resume)
        await db_session.commit()
        await db_session.refresh(resume)

        mock_ai_service = AsyncMock()
        mock_ai_service.generate_resume_content = AsyncMock(return_value={"generated": "content"})

        mock_usage_service = AsyncMock()
        mock_usage_service.check_daily_limit = AsyncMock(return_value=(True, 1, 100))
        mock_usage_service.check_monthly_limit = AsyncMock(return_value=(True, 1, 1000))

        with patch("app.api.v1.resumes.get_ai_service") as mock_get_ai, \
             patch("app.api.v1.resumes.get_ai_usage_service", return_value=mock_usage_service):
            mock_get_ai.return_value = mock_ai_service

            response = await client.post(
                f"/api/v1/resumes/{resume.id}/ai/generate",
                headers=auth_headers,
                json={"target_position": "工程师"}
            )

        # 验证 get_ai_service 被调用
        assert mock_get_ai.called
        assert response.status_code == 200
