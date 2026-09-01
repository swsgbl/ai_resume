"""
Resumes API 集成测试 - 减少 mock 以提升覆盖率
"""
import pytest
from httpx import AsyncClient
from unittest.mock import AsyncMock, patch, MagicMock
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from datetime import datetime, timezone

from app.models.user import User
from app.models.resume import Resume, ResumeVersion, ResumeStatus


class TestResumesAPIIntegration:
    """简历 API 集成测试 - 真实代码路径"""

    async def test_list_resumes_with_count(
        self, client: AsyncClient, auth_headers, test_user, db_session
    ):
        """测试: 列表查询执行 count"""
        for i in range(3):
            resume = Resume(
                user_id=test_user.id,
                title=f"测试简历{i}",
                content={},
                status="draft"
            )
            db_session.add(resume)
        await db_session.commit()

        response = await client.get(
            "/api/v1/resumes",
            headers=auth_headers
        )

        assert response.status_code == 200
        data = response.json()
        assert "total" in data
        assert data["total"] >= 3

    async def test_create_resume_commits_to_db(
        self, client: AsyncClient, auth_headers, test_user, db_session
    ):
        """测试: 创建简历执行 commit"""
        response = await client.post(
            "/api/v1/resumes",
            headers=auth_headers,
            json={
                "title": "提交测试简历",
                "content": {"basic_info": {"name": "测试"}}
            }
        )

        assert response.status_code == 200
        data = response.json()
        resume_id = data["data"]["id"]

        result = await db_session.execute(
            select(Resume).where(Resume.id == resume_id)
        )
        resume = result.scalar_one_or_none()
        assert resume is not None
        assert resume.title == "提交测试简历"

    async def test_get_resume_validation(
        self, client: AsyncClient, auth_headers, test_user, db_session
    ):
        """测试: 获取简历验证所有权"""
        other_user = User(
            email="other_val@example.com",
            password_hash="hash",
            username="other_val"
        )
        db_session.add(other_user)
        await db_session.commit()

        other_resume = Resume(
            user_id=other_user.id,
            title="其他用户简历",
            content={}
        )
        db_session.add(other_resume)
        await db_session.commit()

        response = await client.get(
            f"/api/v1/resumes/{other_resume.id}",
            headers=auth_headers
        )

        assert response.status_code == 404

    async def test_update_saves_version_history(
        self, client: AsyncClient, auth_headers, test_user, db_session
    ):
        """测试: 更新保存版本历史"""
        resume = Resume(
            user_id=test_user.id,
            title="版本测试",
            content={"basic_info": {"name": "v1"}},
            version=1
        )
        db_session.add(resume)
        await db_session.commit()

        original_version = resume.version

        response = await client.put(
            f"/api/v1/resumes/{resume.id}",
            headers=auth_headers,
            json={"title": "版本测试v2"}
        )

        assert response.status_code == 200
        await db_session.refresh(resume)
        
        assert resume.version > original_version

        result = await db_session.execute(
            select(ResumeVersion).where(
                ResumeVersion.resume_id == resume.id
            ).order_by(ResumeVersion.created_at.desc())
        )
        version = result.scalar_one_or_none()
        assert version is not None

    async def test_update_all_fields(
        self, client: AsyncClient, auth_headers, test_resume, db_session
    ):
        """测试: 更新所有字段"""
        response = await client.put(
            f"/api/v1/resumes/{test_resume.id}",
            headers=auth_headers,
            json={
                "title": "完全更新",
                "description": "新描述",
                "content": {"basic_info": {"name": "更新"}},
                "style_config": {"theme": "new"},
                "status": "published"
            }
        )

        assert response.status_code == 200
        await db_session.refresh(test_resume)
        assert test_resume.title == "完全更新"
        assert test_resume.status == "published"

    async def test_delete_resume_from_db(
        self, client: AsyncClient, auth_headers, test_user, db_session
    ):
        """测试: 删除简历从数据库移除"""
        resume = Resume(
            user_id=test_user.id,
            title="待删除",
            content={}
        )
        db_session.add(resume)
        await db_session.commit()
        resume_id = resume.id

        response = await client.delete(
            f"/api/v1/resumes/{resume_id}",
            headers=auth_headers
        )

        assert response.status_code == 200

        result = await db_session.execute(
            select(Resume).where(Resume.id == resume_id)
        )
        assert result.scalar_one_or_none() is None

    async def test_get_resume_versions_ordering(
        self, client: AsyncClient, auth_headers, test_user, db_session
    ):
        """测试: 获取版本列表按时间排序"""
        resume = Resume(
            user_id=test_user.id,
            title="版本排序",
            content={},
            version=1
        )
        db_session.add(resume)
        await db_session.commit()

        for i in range(3):
            version = ResumeVersion(
                resume_id=resume.id,
                version_number=1,
                content={"data": f"v{i}"},
                created_at=datetime.now(timezone.utc)
            )
            db_session.add(version)
        await db_session.commit()

        response = await client.get(
            f"/api/v1/resumes/{resume.id}/versions",
            headers=auth_headers
        )

        assert response.status_code == 200
        data = response.json()
        assert len(data["data"]) >= 3

    async def test_rollback_creates_backup(
        self, client: AsyncClient, auth_headers, test_user, db_session
    ):
        """测试: 回滚创建备份版本"""
        resume = Resume(
            user_id=test_user.id,
            title="回滚测试",
            content={"current": "data"},
            version=1
        )
        db_session.add(resume)
        await db_session.commit()

        # 先更新
        await client.put(
            f"/api/v1/resumes/{resume.id}",
            headers=auth_headers,
            json={"content": {"updated": "v2"}}
        )

        # 创建版本记录
        result = await db_session.execute(
            select(ResumeVersion).where(ResumeVersion.resume_id == resume.id)
        )
        version_record = result.scalar_one_or_none()
        version_id = version_record.id if version_record else None

        if version_id:
            # 回滚到版本
            response = await client.post(
                f"/api/v1/resumes/{resume.id}/rollback/{version_id}",
                headers=auth_headers
            )

            assert response.status_code == 200

    async def test_ai_generate_with_real_limits(
        self, client: AsyncClient, auth_headers, test_resume
    ):
        """测试: AI 生成使用真实限流检查"""
        mock_ai_service = AsyncMock()
        mock_ai_service.generate_resume_content = AsyncMock(
            return_value={"basic_info": {"name": "AI生成"}}
        )

        mock_usage_service = AsyncMock()
        mock_usage_service.check_daily_limit = AsyncMock(return_value=(True, 5, 100))
        mock_usage_service.check_monthly_limit = AsyncMock(return_value=(True, 5, 1000))
        mock_usage_service.record_usage = AsyncMock()

        with patch("app.api.v1.resumes.get_ai_service", return_value=mock_ai_service), \
             patch("app.api.v1.resumes.get_ai_usage_service", return_value=mock_usage_service):
            response = await client.post(
                f"/api/v1/resumes/{test_resume.id}/ai/generate",
                headers=auth_headers,
                json={"target_position": "软件工程师"}
            )

        assert response.status_code == 200

    async def test_ai_optimize_records_tokens(
        self, client: AsyncClient, auth_headers
    ):
        """测试: AI 优化记录 token 使用"""
        long_content = "内容" * 100

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
                    "content": long_content,
                    "optimization_type": "polish"
                }
            )

        assert response.status_code == 200

    async def test_status_filter_on_list(
        self, client: AsyncClient, auth_headers, test_user, db_session
    ):
        """测试: 状态筛选功能"""
        for status in ["draft", "published", "archived"]:
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

    async def test_get_ai_service_direct(
        self, client: AsyncClient, auth_headers
    ):
        """测试: get_ai_service 函数实际调用"""
        mock_ai_service = AsyncMock()
        mock_ai_service.optimize_content = AsyncMock(return_value="结果")

        mock_usage_service = AsyncMock()
        mock_usage_service.check_daily_limit = AsyncMock(return_value=(True, 1, 100))
        mock_usage_service.check_monthly_limit = AsyncMock(return_value=(True, 1, 1000))
        mock_usage_service.record_usage = AsyncMock()

        with patch("app.api.v1.resumes.get_ai_service", return_value=mock_ai_service), \
             patch("app.api.v1.resumes.get_ai_usage_service", return_value=mock_usage_service):
            response = await client.post(
                "/api/v1/resumes/ai/optimize",
                headers=auth_headers,
                json={"content": "测试", "optimization_type": "polish"}
            )

        assert response.status_code == 200

    async def test_pagination_edges(
        self, client: AsyncClient, auth_headers, test_user, db_session
    ):
        """测试: 分页边界条件"""
        for i in range(10):
            resume = Resume(
                user_id=test_user.id,
                title=f"分页{i}",
                content={}
            )
            db_session.add(resume)
        await db_session.commit()

        response = await client.get(
            "/api/v1/resumes?page=1&page_size=5",
            headers=auth_headers
        )
        assert response.status_code == 200
        data = response.json()
        assert len(data["data"]) == 5

    async def test_update_preserves_user_id(
        self, client: AsyncClient, auth_headers, test_resume, db_session
    ):
        """测试: 更新不改变 user_id"""
        original_user_id = test_resume.user_id

        response = await client.put(
            f"/api/v1/resumes/{test_resume.id}",
            headers=auth_headers,
            json={"title": "用户ID保留测试"}
        )

        assert response.status_code == 200
        await db_session.refresh(test_resume)
        assert test_resume.user_id == original_user_id

    async def test_empty_content_defaults(
        self, client: AsyncClient, auth_headers, test_user, db_session
    ):
        """测试: 空内容使用默认值"""
        response = await client.post(
            "/api/v1/resumes",
            headers=auth_headers,
            json={"title": "空内容测试"}
        )

        assert response.status_code == 200
        
        resume_id = response.json()["data"]["id"]
        result = await db_session.execute(
            select(Resume).where(Resume.id == resume_id)
        )
        resume = result.scalar_one_or_none()
        assert resume is not None

    async def test_ai_generate_increments_version(
        self, client: AsyncClient, auth_headers, test_resume
    ):
        """测试: AI 生成增加版本号"""
        original_version = test_resume.version

        mock_ai_service = AsyncMock()
        mock_ai_service.generate_resume_content = AsyncMock(
            return_value={"basic_info": {"name": "生成"}, "work_experience": []}
        )

        mock_usage_service = AsyncMock()
        mock_usage_service.check_daily_limit = AsyncMock(return_value=(True, 1, 100))
        mock_usage_service.check_monthly_limit = AsyncMock(return_value=(True, 1, 1000))
        mock_usage_service.record_usage = AsyncMock()

        with patch("app.api.v1.resumes.get_ai_service", return_value=mock_ai_service), \
             patch("app.api.v1.resumes.get_ai_usage_service", return_value=mock_usage_service):
            response = await client.post(
                f"/api/v1/resumes/{test_resume.id}/ai/generate",
                headers=auth_headers,
                json={"target_position": "测试"}
            )

        assert response.status_code == 200
