"""
测试 resumes.py 未覆盖的代码行
针对 lines: 185-196, 210-224, 242-283, 315-364
"""
import pytest
from httpx import AsyncClient
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select

from app.models.user import User
from app.models.resume import Resume, ResumeVersion
from app.models.template import Template


@pytest.mark.usefixtures("db_session")
class TestResumesMissingCoverage:
    """测试未覆盖的 resume API 代码"""

    async def test_delete_resume_not_found(
        self, client: AsyncClient, auth_headers
    ):
        """测试: 删除不存在的简历 (covers 185-191)"""
        response = await client.delete(
            "/api/v1/resumes/99999",
            headers=auth_headers
        )

        assert response.status_code == 404
        assert "不存在" in response.json()["detail"]

    async def test_delete_resume_success(
        self, client: AsyncClient, auth_headers, test_user, db_session: AsyncSession
    ):
        """测试: 成功删除简历 (covers 192-196)"""
        # 创建简历
        resume = Resume(
            user_id=test_user.id,
            title="待删除",
            content={}
        )
        db_session.add(resume)
        await db_session.commit()
        await db_session.refresh(resume)

        response = await client.delete(
            f"/api/v1/resumes/{resume.id}",
            headers=auth_headers
        )

        assert response.status_code == 200
        assert "删除成功" in response.json()["message"]

        # 验证已删除
        result = await db_session.execute(
            select(Resume).where(Resume.id == resume.id)
        )
        assert result.scalar_one_or_none() is None

    async def test_get_versions_resume_not_found(
        self, client: AsyncClient, auth_headers
    ):
        """测试: 获取不存在简历的版本 (covers 210-214)"""
        response = await client.get(
            "/api/v1/resumes/99999/versions",
            headers=auth_headers
        )

        assert response.status_code == 404
        assert "不存在" in response.json()["detail"]

    async def test_get_versions_success(
        self, client: AsyncClient, auth_headers, test_user, db_session: AsyncSession
    ):
        """测试: 成功获取版本列表 (covers 217-227)"""
        # 创建简历
        resume = Resume(
            user_id=test_user.id,
            title="有版本",
            content={},
            version=2
        )
        db_session.add(resume)
        await db_session.commit()
        await db_session.refresh(resume)

        # 创建版本历史
        version1 = ResumeVersion(
            resume_id=resume.id,
            version_number=1,
            content={"old": "content"},
            change_note="初始版本"
        )
        version2 = ResumeVersion(
            resume_id=resume.id,
            version_number=2,
            content={"new": "content"},
            change_note="更新版本"
        )
        db_session.add(version1)
        db_session.add(version2)
        await db_session.commit()

        response = await client.get(
            f"/api/v1/resumes/{resume.id}/versions",
            headers=auth_headers
        )

        assert response.status_code == 200
        data = response.json()
        assert len(data["data"]) == 2

    async def test_rollback_resume_not_found(
        self, client: AsyncClient, auth_headers
    ):
        """测试: 回滚不存在的简历 (covers 242-248)"""
        response = await client.post(
            "/api/v1/resumes/99999/rollback/1",
            headers=auth_headers
        )

        assert response.status_code == 404
        assert "不存在" in response.json()["detail"]

    async def test_rollback_version_not_found(
        self, client: AsyncClient, auth_headers, test_user, db_session: AsyncSession
    ):
        """测试: 回滚不存在的版本 (covers 251-263)"""
        # 创建简历
        resume = Resume(
            user_id=test_user.id,
            title="测试简历",
            content={"current": "data"},
            version=2
        )
        db_session.add(resume)
        await db_session.commit()
        await db_session.refresh(resume)

        response = await client.post(
            f"/api/v1/resumes/{resume.id}/rollback/99999",
            headers=auth_headers
        )

        assert response.status_code == 404
        assert "版本不存在" in response.json()["detail"]

    async def test_rollback_success(
        self, client: AsyncClient, auth_headers, test_user, db_session: AsyncSession
    ):
        """测试: 成功回滚 (covers 265-285)"""
        # 创建简历
        resume = Resume(
            user_id=test_user.id,
            title="测试简历",
            content={"current": "data"},
            style_config={"theme": "blue"},
            version=2
        )
        db_session.add(resume)
        await db_session.commit()
        await db_session.refresh(resume)

        # 创建历史版本
        old_version = ResumeVersion(
            resume_id=resume.id,
            version_number=1,
            content={"old": "content"},
            style_config={"theme": "red"},
            change_note="旧版本"
        )
        db_session.add(old_version)
        await db_session.commit()
        await db_session.refresh(old_version)

        response = await client.post(
            f"/api/v1/resumes/{resume.id}/rollback/{old_version.id}",
            headers=auth_headers
        )

        assert response.status_code == 200
        data = response.json()
        assert data["data"]["content"] == {"old": "content"}

        # 验证版本号增加
        await db_session.refresh(resume)
        assert resume.version == 3

        # 验证创建了回滚前版本
        result = await db_session.execute(
            select(ResumeVersion).where(
                ResumeVersion.resume_id == resume.id,
                ResumeVersion.change_note == "回滚前保存"
            )
        )
        assert result.scalar_one_or_none() is not None

    async def test_ai_generate_resume_not_found(
        self, client: AsyncClient, auth_headers
    ):
        """测试: AI 生成时简历不存在 (covers 315-321)"""
        from unittest.mock import patch, AsyncMock

        mock_usage_service = AsyncMock()
        mock_usage_service.check_daily_limit = AsyncMock(return_value=(True, 1, 100))
        mock_usage_service.check_monthly_limit = AsyncMock(return_value=(True, 1, 1000))

        with patch("app.api.v1.resumes.get_ai_usage_service", return_value=mock_usage_service):
            response = await client.post(
                "/api/v1/resumes/99999/ai/generate",
                headers=auth_headers,
                json={"target_position": "工程师"}
            )

        assert response.status_code == 404
        assert "不存在" in response.json()["detail"]

    async def test_ai_generate_success_with_dict_response(
        self, client: AsyncClient, auth_headers, test_user, db_session: AsyncSession
    ):
        """测试: AI 生成成功 - 字典响应 (covers 323-346, 349-362)"""
        from unittest.mock import patch, AsyncMock

        # 创建简历
        resume = Resume(
            user_id=test_user.id,
            title="待生成",
            content={},
            version=1
        )
        db_session.add(resume)
        await db_session.commit()
        await db_session.refresh(resume)

        mock_ai_service = AsyncMock()
        mock_ai_service.generate_resume_content = AsyncMock(
            return_value={
                "content": {"generated": "content"},
                "usage": {"prompt_tokens": 100, "completion_tokens": 200},
                "meta": {"provider": "deepseek", "model": "test"}
            }
        )

        mock_usage_service = AsyncMock()
        mock_usage_service.check_daily_limit = AsyncMock(return_value=(True, 1, 100))
        mock_usage_service.check_monthly_limit = AsyncMock(return_value=(True, 1, 1000))
        mock_usage_service.record_usage = AsyncMock()

        with patch("app.api.v1.resumes.get_ai_service", return_value=mock_ai_service), \
             patch("app.api.v1.resumes.get_ai_usage_service", return_value=mock_usage_service):
            response = await client.post(
                f"/api/v1/resumes/{resume.id}/ai/generate",
                headers=auth_headers,
                json={"target_position": "工程师"}
            )

        assert response.status_code == 200
        data = response.json()
        assert data["data"]["content"] == {"generated": "content"}

        # 验证版本号增加
        await db_session.refresh(resume)
        assert resume.version == 2

        # 验证调用了 record_usage
        mock_usage_service.record_usage.assert_called_once()

    async def test_ai_generate_with_simple_response(
        self, client: AsyncClient, auth_headers, test_user, db_session: AsyncSession
    ):
        """测试: AI 生成成功 - 简单响应 (covers 337-340)"""
        from unittest.mock import patch, AsyncMock

        # 创建简历
        resume = Resume(
            user_id=test_user.id,
            title="待生成",
            content={},
            version=1
        )
        db_session.add(resume)
        await db_session.commit()
        await db_session.refresh(resume)

        mock_ai_service = AsyncMock()
        # 直接返回字典（无 usage/meta）
        mock_ai_service.generate_resume_content = AsyncMock(
            return_value={"simple": "content"}
        )

        mock_usage_service = AsyncMock()
        mock_usage_service.check_daily_limit = AsyncMock(return_value=(True, 1, 100))
        mock_usage_service.check_monthly_limit = AsyncMock(return_value=(True, 1, 1000))

        with patch("app.api.v1.resumes.get_ai_service", return_value=mock_ai_service), \
             patch("app.api.v1.resumes.get_ai_usage_service", return_value=mock_usage_service):
            response = await client.post(
                f"/api/v1/resumes/{resume.id}/ai/generate",
                headers=auth_headers,
                json={"target_position": "工程师"}
            )

        assert response.status_code == 200

    async def test_ai_generate_usage_record_failure(
        self, client: AsyncClient, auth_headers, test_user, db_session: AsyncSession
    ):
        """测试: AI 使用记录失败不影响主流程 (covers 360-362)"""
        from unittest.mock import patch, AsyncMock

        # 创建简历
        resume = Resume(
            user_id=test_user.id,
            title="待生成",
            content={},
            version=1
        )
        db_session.add(resume)
        await db_session.commit()
        await db_session.refresh(resume)

        mock_ai_service = AsyncMock()
        mock_ai_service.generate_resume_content = AsyncMock(
            return_value={"content": {"generated": "content"}}
        )

        mock_usage_service = AsyncMock()
        mock_usage_service.check_daily_limit = AsyncMock(return_value=(True, 1, 100))
        mock_usage_service.check_monthly_limit = AsyncMock(return_value=(True, 1, 1000))
        # record_usage 抛出异常
        mock_usage_service.record_usage = AsyncMock(side_effect=Exception("DB error"))

        with patch("app.api.v1.resumes.get_ai_service", return_value=mock_ai_service), \
             patch("app.api.v1.resumes.get_ai_usage_service", return_value=mock_usage_service):
            response = await client.post(
                f"/api/v1/resumes/{resume.id}/ai/generate",
                headers=auth_headers,
                json={"target_position": "工程师"}
            )

        # 主流程应该成功
        assert response.status_code == 200
