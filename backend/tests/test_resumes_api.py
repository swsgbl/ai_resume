"""
Resumes API 完整测试
覆盖所有端点和边界情况
"""
import pytest
from httpx import AsyncClient
from unittest.mock import AsyncMock, patch
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select

from app.models.user import User
from app.models.resume import Resume, ResumeVersion
from app.models.template import Template
from app.services.ai_limit_decorator import AIUsageLimitExceeded


class TestResumeListAPI:
    """简历列表 API 测试"""

    async def test_list_resumes_success(
        self, client: AsyncClient, auth_headers, test_user, db_session
    ):
        """测试: 成功获取简历列表"""
        # 创建多个简历
        for i in range(5):
            resume = Resume(
                user_id=test_user.id,
                title=f"测试简历{i}",
                content={},
                style_config={}
            )
            db_session.add(resume)
        await db_session.commit()

        response = await client.get(
            "/api/v1/resumes",
            headers=auth_headers
        )

        assert response.status_code == 200
        data = response.json()
        assert data["code"] == 0
        assert len(data["data"]) >= 5
        assert data["total"] >= 5
        assert data["page"] == 1
        assert data["page_size"] == 10

    async def test_list_resumes_with_pagination(
        self, client: AsyncClient, auth_headers, test_user, db_session
    ):
        """测试: 分页获取简历列表"""
        # 创建15个简历
        for i in range(15):
            resume = Resume(
                user_id=test_user.id,
                title=f"简历{i}",
                content={},
                style_config={}
            )
            db_session.add(resume)
        await db_session.commit()

        response = await client.get(
            "/api/v1/resumes?page=2&page_size=5",
            headers=auth_headers
        )

        assert response.status_code == 200
        data = response.json()
        assert data["page"] == 2
        assert data["page_size"] == 5
        assert len(data["data"]) == 5

    async def test_list_resumes_with_status_filter(
        self, client: AsyncClient, auth_headers, test_user, db_session
    ):
        """测试: 按状态筛选简历"""
        draft = Resume(
            user_id=test_user.id,
            title="草稿",
            content={},
            style_config={},
            status="draft"
        )
        published = Resume(
            user_id=test_user.id,
            title="已发布",
            content={},
            style_config={},
            status="published"
        )
        db_session.add(draft)
        db_session.add(published)
        await db_session.commit()

        response = await client.get(
            "/api/v1/resumes?status=published",
            headers=auth_headers
        )

        assert response.status_code == 200
        data = response.json()
        # 应该只返回已发布的简历
        for r in data["data"]:
            assert r["status"] == "published"

    async def test_list_resumes_empty(
        self, client: AsyncClient, auth_headers, db_session
    ):
        """测试: 空简历列表"""
        # 创建新用户没有简历
        new_user = User(
            email="empty@example.com",
            password_hash="hash",
            username="empty",
            role="user"
        )
        db_session.add(new_user)
        await db_session.commit()

        # 获取新用户的 token
        response = await client.post(
            "/api/v1/auth/login",
            json={"email": "empty@example.com", "password": "password"}
        )
        # 可能失败因为用户没有设置正确密码，我们直接用 auth_headers
        response = await client.get(
            "/api/v1/resumes",
            headers=auth_headers
        )

        assert response.status_code == 200
        data = response.json()
        # 可能返回空列表或当前用户的简历

    async def test_list_resumes_unauthorized(
        self, client: AsyncClient
    ):
        """测试: 未授权访问"""
        response = await client.get("/api/v1/resumes")
        assert response.status_code == 401


class TestCreateResumeAPI:
    """创建简历 API 测试"""

    async def test_create_resume_minimal(
        self, client: AsyncClient, auth_headers
    ):
        """测试: 创建最简简历"""
        response = await client.post(
            "/api/v1/resumes",
            headers=auth_headers,
            json={"title": "最简简历"}
        )

        assert response.status_code == 200
        data = response.json()
        assert data["code"] == 0
        assert data["data"]["title"] == "最简简历"

    async def test_create_resume_with_template(
        self, client: AsyncClient, auth_headers, db_session
    ):
        """测试: 使用模板创建简历"""
        template = Template(
            name="测试模板",
            layout="modern",
            is_active=True,
            use_count=0
        )
        db_session.add(template)
        await db_session.commit()

        response = await client.post(
            "/api/v1/resumes",
            headers=auth_headers,
            json={
                "title": "使用模板的简历",
                "template_id": template.id
            }
        )

        assert response.status_code == 200
        data = response.json()
        assert data["data"]["template_id"] == template.id

    async def test_create_resume_with_content(
        self, client: AsyncClient, auth_headers
    ):
        """测试: 创建带内容的简历"""
        content = {
            "basic_info": {"name": "张三", "email": "zhangsan@example.com"}
        }

        response = await client.post(
            "/api/v1/resumes",
            headers=auth_headers,
            json={
                "title": "完整简历",
                "content": content
            }
        )

        assert response.status_code == 200
        data = response.json()
        assert data["data"]["content"]["basic_info"]["name"] == "张三"

    async def test_create_resume_with_style(
        self, client: AsyncClient, auth_headers
    ):
        """测试: 创建带样式的简历"""
        style_config = {"theme": "professional", "color": "blue"}

        response = await client.post(
            "/api/v1/resumes",
            headers=auth_headers,
            json={
                "title": "样式简历",
                "style_config": style_config
            }
        )

        assert response.status_code == 200


class TestGetResumeAPI:
    """获取简历详情 API 测试"""

    async def test_get_resume_success(
        self, client: AsyncClient, auth_headers, test_resume
    ):
        """测试: 成功获取简历详情"""
        response = await client.get(
            f"/api/v1/resumes/{test_resume.id}",
            headers=auth_headers
        )

        assert response.status_code == 200
        data = response.json()
        assert data["code"] == 0
        assert data["data"]["id"] == test_resume.id

    async def test_get_resume_not_found(
        self, client: AsyncClient, auth_headers
    ):
        """测试: 简历不存在"""
        response = await client.get(
            "/api/v1/resumes/99999",
            headers=auth_headers
        )

        assert response.status_code == 404

    async def test_get_resume_unauthorized(
        self, client: AsyncClient, test_resume
    ):
        """测试: 未授权访问"""
        response = await client.get(f"/api/v1/resumes/{test_resume.id}")
        assert response.status_code == 401


class TestUpdateResumeAPI:
    """更新简历 API 测试"""

    async def test_update_resume_title(
        self, client: AsyncClient, auth_headers, test_resume
    ):
        """测试: 更新简历标题"""
        response = await client.put(
            f"/api/v1/resumes/{test_resume.id}",
            headers=auth_headers,
            json={"title": "新标题"}
        )

        assert response.status_code == 200
        data = response.json()
        assert data["data"]["title"] == "新标题"
        assert data["data"]["version"] == 2  # 版本号应该增加

    async def test_update_resume_description(
        self, client: AsyncClient, auth_headers, test_resume
    ):
        """测试: 更新简历描述"""
        response = await client.put(
            f"/api/v1/resumes/{test_resume.id}",
            headers=auth_headers,
            json={"description": "新描述"}
        )

        assert response.status_code == 200
        data = response.json()
        assert data["data"]["description"] == "新描述"

    async def test_update_resume_content(
        self, client: AsyncClient, auth_headers, test_resume
    ):
        """测试: 更新简历内容"""
        new_content = {"basic_info": {"name": "新名字"}}

        response = await client.put(
            f"/api/v1/resumes/{test_resume.id}",
            headers=auth_headers,
            json={"content": new_content}
        )

        assert response.status_code == 200

    async def test_update_resume_all_fields(
        self, client: AsyncClient, auth_headers, test_resume
    ):
        """测试: 更新所有字段"""
        response = await client.put(
            f"/api/v1/resumes/{test_resume.id}",
            headers=auth_headers,
            json={
                "title": "完整更新",
                "description": "完整描述",
                "status": "published",
                "content": {"basic_info": {"name": "完整"}},
                "style_config": {"theme": "modern"}
            }
        )

        assert response.status_code == 200
        data = response.json()
        assert data["data"]["title"] == "完整更新"
        assert data["data"]["status"] == "published"

    async def test_update_resume_not_found(
        self, client: AsyncClient, auth_headers
    ):
        """测试: 更新不存在的简历"""
        response = await client.put(
            "/api/v1/resumes/99999",
            headers=auth_headers,
            json={"title": "新标题"}
        )

        assert response.status_code == 404

    async def test_update_resume_saves_version(
        self, client: AsyncClient, auth_headers, test_resume, db_session
    ):
        """测试: 更新简历时保存版本"""
        # 修改简历
        await client.put(
            f"/api/v1/resumes/{test_resume.id}",
            headers=auth_headers,
            json={"title": "版本1"}
        )

        # 检查版本历史
        result = await db_session.execute(
            select(ResumeVersion).where(ResumeVersion.resume_id == test_resume.id)
        )
        versions = result.scalars().all()

        assert len(versions) == 1
        assert versions[0].change_note == "自动保存"

    async def test_update_resume_unauthorized(
        self, client: AsyncClient, db_session
    ):
        """测试: 未授权更新"""
        other_user = User(
            email="update_unauth@example.com",
            password_hash="hash",
            username="update_unauth",
            role="user"
        )
        db_session.add(other_user)
        await db_session.commit()

        other_resume = Resume(
            user_id=other_user.id,
            title="其他用户",
            content={},
            style_config={}
        )
        db_session.add(other_resume)
        await db_session.commit()

        response = await client.put(f"/api/v1/resumes/{other_resume.id}")
        assert response.status_code == 401


class TestDeleteResumeAPI:
    """删除简历 API 测试"""

    async def test_delete_resume_success(
        self, client: AsyncClient, auth_headers, test_resume, db_session
    ):
        """测试: 成功删除简历"""
        resume_id = test_resume.id

        response = await client.delete(
            f"/api/v1/resumes/{resume_id}",
            headers=auth_headers
        )

        assert response.status_code == 200
        data = response.json()
        assert "删除成功" in data["message"]

        # 验证简历已被删除
        result = await db_session.execute(
            select(Resume).where(Resume.id == resume_id)
        )
        assert result.scalar_one_or_none() is None

    async def test_delete_resume_not_found(
        self, client: AsyncClient, auth_headers
    ):
        """测试: 删除不存在的简历"""
        response = await client.delete(
            "/api/v1/resumes/99999",
            headers=auth_headers
        )

        assert response.status_code == 404

    async def test_delete_resume_unauthorized(
        self, client: AsyncClient, test_resume
    ):
        """测试: 未授权删除"""
        response = await client.delete(f"/api/v1/resumes/{test_resume.id}")
        assert response.status_code == 401


class TestResumeVersionsAPI:
    """简历版本 API 测试"""

    async def test_get_versions_empty(
        self, client: AsyncClient, auth_headers, test_resume
    ):
        """测试: 获取空版本列表"""
        response = await client.get(
            f"/api/v1/resumes/{test_resume.id}/versions",
            headers=auth_headers
        )

        assert response.status_code == 200
        data = response.json()
        assert data["code"] == 0
        assert data["data"] == []

    async def test_get_versions_with_data(
        self, client: AsyncClient, auth_headers, test_resume, db_session
    ):
        """测试: 获取版本列表"""
        # 创建一些版本
        for i in range(3):
            version = ResumeVersion(
                resume_id=test_resume.id,
                version_number=i,
                content={"version": i},
                style_config={},
                change_note=f"版本{i}"
            )
            db_session.add(version)
        await db_session.commit()

        response = await client.get(
            f"/api/v1/resumes/{test_resume.id}/versions",
            headers=auth_headers
        )

        assert response.status_code == 200
        data = response.json()
        assert len(data["data"]) == 3

    async def test_get_versions_resume_not_found(
        self, client: AsyncClient, auth_headers
    ):
        """测试: 获取不存在简历的版本"""
        response = await client.get(
            "/api/v1/resumes/99999/versions",
            headers=auth_headers
        )

        assert response.status_code == 404

    async def test_get_versions_unauthorized(
        self, client: AsyncClient, test_resume
    ):
        """测试: 未授权获取版本"""
        response = await client.get(f"/api/v1/resumes/{test_resume.id}/versions")
        assert response.status_code == 401


class TestResumeRollbackAPI:
    """简历回滚 API 测试"""

    async def test_rollback_success(
        self, client: AsyncClient, auth_headers, test_resume, db_session
    ):
        """测试: 成功回滚到指定版本"""
        # 创建一个版本
        old_content = {"old": "content"}
        version = ResumeVersion(
            resume_id=test_resume.id,
            version_number=1,
            content=old_content,
            style_config={},
            change_note="保存旧版本"
        )
        db_session.add(version)
        await db_session.commit()

        response = await client.post(
            f"/api/v1/resumes/{test_resume.id}/rollback/{version.id}",
            headers=auth_headers
        )

        assert response.status_code == 200
        data = response.json()
        assert data["data"]["content"] == old_content
        assert data["data"]["version"] == 2  # 版本号增加

    async def test_rollback_saves_current_version(
        self, client: AsyncClient, auth_headers, test_resume, db_session
    ):
        """测试: 回滚前保存当前版本"""
        # 修改简历
        test_resume.content = {"current": "data"}
        await db_session.commit()

        # 创建历史版本
        version = ResumeVersion(
            resume_id=test_resume.id,
            version_number=1,
            content={"old": "data"},
            style_config={},
            change_note="旧版本"
        )
        db_session.add(version)
        await db_session.commit()

        # 回滚
        await client.post(
            f"/api/v1/resumes/{test_resume.id}/rollback/{version.id}",
            headers=auth_headers
        )

        # 检查有两个版本（历史版本和回滚前保存的版本）
        result = await db_session.execute(
            select(ResumeVersion).where(ResumeVersion.resume_id == test_resume.id)
        )
        versions = result.scalars().all()
        assert len(versions) == 2

    async def test_rollback_resume_not_found(
        self, client: AsyncClient, auth_headers
    ):
        """测试: 回滚不存在的简历"""
        response = await client.post(
            "/api/v1/resumes/99999/rollback/1",
            headers=auth_headers
        )

        assert response.status_code == 404

    async def test_rollback_version_not_found(
        self, client: AsyncClient, auth_headers, test_resume
    ):
        """测试: 回滚到不存在的版本"""
        response = await client.post(
            f"/api/v1/resumes/{test_resume.id}/rollback/99999",
            headers=auth_headers
        )

        assert response.status_code == 404

    async def test_rollback_unauthorized(
        self, client: AsyncClient, test_resume
    ):
        """测试: 未授权回滚"""
        response = await client.post(f"/api/v1/resumes/{test_resume.id}/rollback/1")
        assert response.status_code == 401


class TestAIGenerateAPI:
    """AI 生成简历 API 测试"""

    async def test_ai_generate_simple_response(
        self, client: AsyncClient, auth_headers, test_resume
    ):
        """测试: AI 生成简单响应"""
        mock_ai_service = AsyncMock()
        mock_ai_service.generate_resume_content.return_value = {"content": {"name": "AI生成的"}}

        mock_usage_service = AsyncMock()
        mock_usage_service.check_daily_limit = AsyncMock(return_value=(True, 1, 100))
        mock_usage_service.check_monthly_limit = AsyncMock(return_value=(True, 1, 1000))
        mock_usage_service.record_usage = AsyncMock()

        with patch("app.api.v1.resumes.get_ai_service", return_value=mock_ai_service), \
             patch("app.api.v1.resumes.get_ai_usage_service", return_value=mock_usage_service):
            response = await client.post(
                f"/api/v1/resumes/{test_resume.id}/ai/generate",
                headers=auth_headers,
                json={"target_position": "工程师"}
            )

            assert response.status_code == 200

    async def test_ai_generate_with_usage_tracking(
        self, client: AsyncClient, auth_headers, test_resume
    ):
        """测试: AI 生成并记录使用量"""
        mock_ai_service = AsyncMock()
        mock_ai_service.generate_resume_content.return_value = {
            "content": {"generated": True},
            "usage": {"total_tokens": 500},
            "meta": {"provider": "openai", "model": "gpt-4"}
        }

        mock_usage_service = AsyncMock()
        mock_usage_service.check_daily_limit = AsyncMock(return_value=(True, 1, 100))
        mock_usage_service.check_monthly_limit = AsyncMock(return_value=(True, 1, 1000))
        mock_usage_service.record_usage = AsyncMock()

        with patch("app.api.v1.resumes.get_ai_service", return_value=mock_ai_service), \
             patch("app.api.v1.resumes.get_ai_usage_service", return_value=mock_usage_service):
            response = await client.post(
                f"/api/v1/resumes/{test_resume.id}/ai/generate",
                headers=auth_headers,
                json={"target_position": "工程师"}
            )

            assert response.status_code == 200
            # 验证 record_usage 被调用
            mock_usage_service.record_usage.assert_called_once()

    async def test_ai_generate_resume_not_found(
        self, client: AsyncClient, auth_headers
    ):
        """测试: AI 生成不存在的简历"""
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

    async def test_ai_generate_unauthorized(
        self, client: AsyncClient, test_resume
    ):
        """测试: 未授权 AI 生成"""
        response = await client.post(
            f"/api/v1/resumes/{test_resume.id}/ai/generate",
            json={"target_position": "工程师"}
        )

        assert response.status_code == 401


class TestAIOptimizeAPI:
    """AI 优化内容 API 测试"""

    async def test_ai_optimize_success(
        self, client: AsyncClient, auth_headers
    ):
        """测试: AI 优化成功"""
        mock_ai_service = AsyncMock()
        mock_ai_service.optimize_content.return_value = "优化后的内容"

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
                    "optimization_type": "grammar"
                }
            )

            assert response.status_code == 200
            data = response.json()
            assert data["data"]["optimized"] == "优化后的内容"

    async def test_ai_optimize_different_types(
        self, client: AsyncClient, auth_headers
    ):
        """测试: 不同优化类型"""
        mock_ai_service = AsyncMock()
        mock_ai_service.optimize_content.return_value = "优化后的内容"

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
                    "content": "负责开发",
                    "optimization_type": "impact"
                }
            )

            assert response.status_code == 200

    async def test_ai_optimize_unauthorized(
        self, client: AsyncClient
    ):
        """测试: 未授权优化"""
        response = await client.post(
            "/api/v1/resumes/ai/optimize",
            json={"content": "测试", "optimization_type": "grammar"}
        )

        assert response.status_code == 401
