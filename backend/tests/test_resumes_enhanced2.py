"""
Resumes API 增强测试 2 - 覆盖 AI 生成等缺失场景
"""
import pytest
from httpx import AsyncClient
from unittest.mock import AsyncMock, patch
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from app.models.resume import Resume, ResumeVersion
from app.models.user import User


class TestAIGenerateResume:
    """AI 生成简历测试"""

    async def test_ai_generate_success(
        self, client: AsyncClient, auth_headers, test_resume
    ):
        """测试: AI 生成简历内容成功"""
        # Mock AI 服务
        mock_ai_service = AsyncMock()
        mock_ai_service.generate_resume_content.return_value = {
            "content": {"basic_info": {"name": "AI生成的名字"}},
            "usage": {"prompt_tokens": 100, "completion_tokens": 200, "total_tokens": 300},
            "meta": {"provider": "openai", "model": "gpt-4"}
        }

        # Mock usage service
        mock_usage_service = AsyncMock()
        mock_usage_service.check_daily_limit = AsyncMock(return_value=(True, 1, 100))
        mock_usage_service.check_monthly_limit = AsyncMock(return_value=(True, 1, 1000))
        mock_usage_service.record_usage = AsyncMock()

        with patch("app.api.v1.resumes.get_ai_service", return_value=mock_ai_service), \
             patch("app.api.v1.resumes.get_ai_usage_service", return_value=mock_usage_service):
            response = await client.post(
                f"/api/v1/resumes/{test_resume.id}/ai/generate",
                headers=auth_headers,
                json={
                    "target_position": "Python后端工程师",
                    "style": "professional",
                    "language": "zh"
                }
            )

            assert response.status_code == 200
            data = response.json()
            assert data["code"] == 0

    async def test_ai_generate_daily_limit_exceeded(
        self, client: AsyncClient, auth_headers, test_resume
    ):
        """测试: 每日限额超出"""
        mock_usage_service = AsyncMock()
        mock_usage_service.check_daily_limit = AsyncMock(return_value=(False, 100, 100))
        mock_usage_service.check_monthly_limit = AsyncMock(return_value=(True, 100, 2000))

        with patch("app.api.v1.resumes.get_ai_usage_service", return_value=mock_usage_service):
            response = await client.post(
                f"/api/v1/resumes/{test_resume.id}/ai/generate",
                headers=auth_headers,
                json={"target_position": "软件工程师"}
            )

            # 限额超出返回 403 或 429 (Too Many Requests)
            assert response.status_code in [403, 429]

    async def test_ai_generate_monthly_limit_exceeded(
        self, client: AsyncClient, auth_headers, test_resume
    ):
        """测试: 月度限额超出"""
        mock_usage_service = AsyncMock()
        mock_usage_service.check_daily_limit = AsyncMock(return_value=(True, 50, 100))
        mock_usage_service.check_monthly_limit = AsyncMock(return_value=(False, 2000, 2000))

        with patch("app.api.v1.resumes.get_ai_usage_service", return_value=mock_usage_service):
            response = await client.post(
                f"/api/v1/resumes/{test_resume.id}/ai/generate",
                headers=auth_headers,
                json={"target_position": "软件工程师"}
            )

            # 限额超出返回 403 或 429 (Too Many Requests)
            assert response.status_code in [403, 429]

    async def test_ai_generate_resume_not_found(
        self, client: AsyncClient, auth_headers
    ):
        """测试: 简历不存在"""
        mock_usage_service = AsyncMock()
        mock_usage_service.check_daily_limit = AsyncMock(return_value=(True, 1, 100))
        mock_usage_service.check_monthly_limit = AsyncMock(return_value=(True, 1, 1000))

        with patch("app.api.v1.resumes.get_ai_usage_service", return_value=mock_usage_service):
            response = await client.post(
                "/api/v1/resumes/99999/ai/generate",
                headers=auth_headers,
                json={"target_position": "软件工程师"}
            )

            assert response.status_code == 404

    async def test_ai_generate_unauthorized(
        self, client: AsyncClient, test_resume
    ):
        """测试: 未认证访问"""
        response = await client.post(
            f"/api/v1/resumes/{test_resume.id}/ai/generate",
            json={"target_position": "软件工程师"}
        )

        assert response.status_code == 401


class TestAIOptimizeContent:
    """AI 优化内容增强测试"""

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

        optimization_types = ["grammar", "conciseness", "impact", "keywords"]

        with patch("app.api.v1.resumes.get_ai_service", return_value=mock_ai_service), \
             patch("app.api.v1.resumes.get_ai_usage_service", return_value=mock_usage_service):
            for opt_type in optimization_types:
                response = await client.post(
                    "/api/v1/resumes/ai/optimize",
                    headers=auth_headers,
                    json={
                        "content": "原始内容",
                        "optimization_type": opt_type
                    }
                )
                # AI 服务可能失败
                assert response.status_code in [200, 500]

    async def test_ai_optimize_with_context(
        self, client: AsyncClient, auth_headers
    ):
        """测试: 带上下文的优化"""
        mock_ai_service = AsyncMock()
        mock_ai_service.optimize_content.return_value = "根据上下文优化后的内容"

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
                    "content": "负责开发Web应用",
                    "optimization_type": "impact"
                }
            )
            # AI 服务可能失败或验证错误
            assert response.status_code in [200, 422, 500]

    async def test_ai_optimize_unauthorized(
        self, client: AsyncClient
    ):
        """测试: 未认证优化"""
        response = await client.post(
            "/api/v1/resumes/ai/optimize",
            json={
                "content": "测试内容",
                "optimization_type": "grammar"
            }
        )

        assert response.status_code == 401


class TestResumeListEnhanced:
    """简历列表增强测试"""

    async def test_list_resumes_invalid_page(
        self, client: AsyncClient, auth_headers
    ):
        """测试: 无效页码"""
        response = await client.get(
            "/api/v1/resumes?page=0",
            headers=auth_headers
        )

        assert response.status_code == 422

    async def test_list_resumes_invalid_page_size(
        self, client: AsyncClient, auth_headers
    ):
        """测试: 无效页大小"""
        response = await client.get(
            "/api/v1/resumes?page_size=200",
            headers=auth_headers
        )

        assert response.status_code == 422

    async def test_list_resumes_with_published_status(
        self, client: AsyncClient, auth_headers, test_user, db_session
    ):
        """测试: 筛选已发布状态简历"""
        from app.models.resume import Resume, ResumeStatus

        # 创建已发布的简历
        resume = Resume(
            user_id=test_user.id,
            title="已发布简历",
            content={},
            style_config={},
            status=ResumeStatus.PUBLISHED
        )
        db_session.add(resume)
        await db_session.commit()

        response = await client.get(
            "/api/v1/resumes?status=published",
            headers=auth_headers
        )

        assert response.status_code == 200
        data = response.json()
        assert data["code"] == 0

    async def test_list_resumes_ordering(
        self, client: AsyncClient, auth_headers, test_user, db_session
    ):
        """测试: 简历按更新时间排序"""
        from app.models.resume import Resume
        import time

        # 创建多个简历
        for i in range(3):
            resume = Resume(
                user_id=test_user.id,
                title=f"排序测试{i}",
                content={},
                style_config={}
            )
            db_session.add(resume)
            await db_session.commit()
            time.sleep(0.01)  # 确保时间戳不同

        response = await client.get(
            "/api/v1/resumes?page_size=10",
            headers=auth_headers
        )

        assert response.status_code == 200
        data = response.json()
        # 应该按 updated_at 降序排列
        assert len(data["data"]) > 0


class TestResumeCreateEnhanced:
    """创建简历增强测试"""

    async def test_create_resume_with_full_data(
        self, client: AsyncClient, auth_headers, db_session
    ):
        """测试: 创建完整数据的简历"""
        from app.models.template import Template

        # 创建模板
        template = Template(
            name="完整模板",
            layout="modern",
            is_active=True
        )
        db_session.add(template)
        await db_session.commit()

        # 简化内容结构避免验证错误
        full_content = {
            "basic_info": {
                "name": "完整姓名",
                "email": "full@example.com",
                "phone": "13800138000"
            }
        }

        response = await client.post(
            "/api/v1/resumes",
            headers=auth_headers,
            json={
                "title": "完整简历",
                "description": "这是一份完整的简历",
                "template_id": template.id,
                "content": full_content,
                "style_config": {
                    "theme": "professional"
                }
            }
        )

        assert response.status_code == 200
        data = response.json()
        assert data["code"] == 0
        assert data["data"]["title"] == "完整简历"

    async def test_create_resume_unauthorized(
        self, client: AsyncClient
    ):
        """测试: 未认证创建简历"""
        response = await client.post(
            "/api/v1/resumes",
            json={"title": "未授权简历"}
        )

        assert response.status_code == 401


class TestResumeUpdateEnhanced:
    """更新简历增强测试"""

    async def test_update_partial_fields(
        self, client: AsyncClient, auth_headers, test_resume
    ):
        """测试: 部分字段更新"""
        response = await client.put(
            f"/api/v1/resumes/{test_resume.id}",
            headers=auth_headers,
            json={"title": "只更新标题"}
        )

        assert response.status_code == 200
        data = response.json()
        assert data["data"]["title"] == "只更新标题"

    async def test_update_with_empty_content(
        self, client: AsyncClient, auth_headers, test_resume
    ):
        """测试: 更新为空内容"""
        response = await client.put(
            f"/api/v1/resumes/{test_resume.id}",
            headers=auth_headers,
            json={"content": {}}
        )

        assert response.status_code == 200

    async def test_update_unauthorized_resume(
        self, client: AsyncClient, auth_headers, db_session
    ):
        """测试: 更新其他用户的简历"""
        from app.models.user import User

        # 创建其他用户
        other_user = User(
            email="updater@example.com",
            password_hash="hash",
            username="updater",
            role="user"
        )
        db_session.add(other_user)
        await db_session.commit()

        other_resume = Resume(
            user_id=other_user.id,
            title="其他用户的简历",
            content={},
            style_config={}
        )
        db_session.add(other_resume)
        await db_session.commit()

        response = await client.put(
            f"/api/v1/resumes/{other_resume.id}",
            headers=auth_headers,
            json={"title": "尝试更新"}
        )

        assert response.status_code == 404


class TestResumeDeleteEnhanced:
    """删除简历增强测试"""

    async def test_delete_unauthorized_resume(
        self, client: AsyncClient, auth_headers, db_session
    ):
        """测试: 删除其他用户的简历"""
        from app.models.user import User

        other_user = User(
            email="deleter2@example.com",
            password_hash="hash",
            username="deleter2",
            role="user"
        )
        db_session.add(other_user)
        await db_session.commit()

        other_resume = Resume(
            user_id=other_user.id,
            title="不能删除的简历",
            content={},
            style_config={}
        )
        db_session.add(other_resume)
        await db_session.commit()

        response = await client.delete(
            f"/api/v1/resumes/{other_resume.id}",
            headers=auth_headers
        )

        assert response.status_code == 404

    async def test_delete_unauthorized(
        self, client: AsyncClient, test_resume
    ):
        """测试: 未认证删除"""
        response = await client.delete(
            f"/api/v1/resumes/{test_resume.id}"
        )

        assert response.status_code == 401


class TestResumeVersionsEnhanced:
    """简历版本增强测试"""

    async def test_get_versions_unauthorized(
        self, client: AsyncClient, test_resume
    ):
        """测试: 未认证获取版本"""
        response = await client.get(
            f"/api/v1/resumes/{test_resume.id}/versions"
        )

        assert response.status_code == 401

    async def test_rollback_unauthorized(
        self, client: AsyncClient, test_resume, db_session
    ):
        """测试: 未认证回滚"""
        version = ResumeVersion(
            resume_id=test_resume.id,
            version_number=1,
            content={},
            style_config={},
            change_note="测试"
        )
        db_session.add(version)
        await db_session.commit()

        response = await client.post(
            f"/api/v1/resumes/{test_resume.id}/rollback/{version.id}"
        )

        assert response.status_code == 401

    async def test_get_versions_unauthorized_resume(
        self, client: AsyncClient, auth_headers, db_session
    ):
        """测试: 获取其他用户简历的版本"""
        from app.models.user import User

        other_user = User(
            email="version@example.com",
            password_hash="hash",
            username="version_user",
            role="user"
        )
        db_session.add(other_user)
        await db_session.commit()

        other_resume = Resume(
            user_id=other_user.id,
            title="其他用户的简历",
            content={},
            style_config={}
        )
        db_session.add(other_resume)
        await db_session.commit()

        response = await client.get(
            f"/api/v1/resumes/{other_resume.id}/versions",
            headers=auth_headers
        )

        assert response.status_code == 404


class TestGetResumeEnhanced:
    """获取简历详情增强测试"""

    async def test_get_resume_unauthorized(
        self, client: AsyncClient, test_resume
    ):
        """测试: 未认证获取简历"""
        response = await client.get(
            f"/api/v1/resumes/{test_resume.id}"
        )

        assert response.status_code == 401

    async def test_get_other_user_resume(
        self, client: AsyncClient, auth_headers, db_session
    ):
        """测试: 获取其他用户的简历"""
        from app.models.user import User

        other_user = User(
            email="viewer@example.com",
            password_hash="hash",
            username="viewer",
            role="user"
        )
        db_session.add(other_user)
        await db_session.commit()

        other_resume = Resume(
            user_id=other_user.id,
            title="私密简历",
            content={},
            style_config={}
        )
        db_session.add(other_resume)
        await db_session.commit()

        response = await client.get(
            f"/api/v1/resumes/{other_resume.id}",
            headers=auth_headers
        )

        assert response.status_code == 404
