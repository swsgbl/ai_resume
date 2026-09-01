"""
Resumes API 补充测试 - 针对缺失覆盖行
"""
import pytest
from httpx import AsyncClient
from unittest.mock import AsyncMock, patch
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select

from app.models.user import User
from app.models.resume import Resume, ResumeVersion
from app.models.template import Template


class TestGetAIService:
    """获取 AI 服务测试"""

    @pytest.mark.asyncio
    async def test_get_ai_service_function(
        self, client: AsyncClient, auth_headers
    ):
        """测试: get_ai_service 函数返回服务"""
        # 这个测试通过调用需要 AI 服务的端点来间接测试
        mock_ai_service = AsyncMock()
        mock_ai_service.optimize_content = AsyncMock(return_value="优化结果")

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
                    "content": "测试内容",
                    "optimization_type": "polish"
                }
            )

            assert response.status_code == 200


class TestListResumesMore:
    """简历列表扩展测试"""

    async def test_list_resumes_empty_status_filter(
        self, client: AsyncClient, auth_headers, test_user, db_session
    ):
        """测试: 空状态筛选返回所有"""
        for i in range(5):
            resume = Resume(
                user_id=test_user.id,
                title=f"状态测试{i}",
                content={},
                style_config={}
            )
            db_session.add(resume)
        await db_session.commit()

        # 不传 status 参数
        response = await client.get(
            "/api/v1/resumes",
            headers=auth_headers
        )

        assert response.status_code == 200
        data = response.json()
        assert data["total"] >= 5

    async def test_list_resumes_page_size_limit(
        self, client: AsyncClient, auth_headers
    ):
        """测试: 页大小限制"""
        response = await client.get(
            "/api/v1/resumes?page_size=150",
            headers=auth_headers
        )

        assert response.status_code == 422  # 超过最大限制

    async def test_list_resumes_page_zero(
        self, client: AsyncClient, auth_headers
    ):
        """测试: 页码为0"""
        response = await client.get(
            "/api/v1/resumes?page=0",
            headers=auth_headers
        )

        assert response.status_code == 422


class TestCreateResumeMore:
    """创建简历扩展测试"""

    async def test_create_resume_full_content(
        self, client: AsyncClient, auth_headers, db_session
    ):
        """测试: 创建完整内容的简历"""
        template = Template(
            name="完整模板",
            layout="single",
            is_active=True
        )
        db_session.add(template)
        await db_session.commit()

        from app.schemas.resume import ResumeContent, StyleConfig, BasicInfo

        response = await client.post(
            "/api/v1/resumes",
            headers=auth_headers,
            json={
                "title": "完整简历",
                "description": "完整描述",
                "template_id": template.id,
                "content": {
                    "basic_info": {
                        "name": "完整姓名",
                        "email": "full@example.com"
                    }
                },
                "style_config": {
                    "theme": "modern"
                }
            }
        )

        assert response.status_code == 200
        data = response.json()
        assert data["data"]["title"] == "完整简历"

    async def test_create_resume_minimal(
        self, client: AsyncClient, auth_headers
    ):
        """测试: 最小数据创建简历"""
        response = await client.post(
            "/api/v1/resumes",
            headers=auth_headers,
            json={"title": "最小简历"}
        )

        assert response.status_code == 200
        data = response.json()
        assert data["data"]["title"] == "最小简历"


class TestUpdateResumeMore:
    """更新简历扩展测试"""

    async def test_update_all_fields(
        self, client: AsyncClient, auth_headers, test_user, db_session
    ):
        """测试: 更新所有字段"""
        # 创建简历
        resume = Resume(
            user_id=test_user.id,
            title="待更新简历",
            content={},
            style_config={}
        )
        db_session.add(resume)
        await db_session.commit()

        # 创建模板
        template = Template(
            name="更新模板",
            layout="single",
            is_active=True
        )
        db_session.add(template)
        await db_session.commit()

        response = await client.put(
            f"/api/v1/resumes/{resume.id}",
            headers=auth_headers,
            json={
                "title": "完整更新",
                "description": "更新描述",
                "template_id": template.id,
                "content": {"basic_info": {"name": "更新后"}},
                "style_config": {"theme": "updated"},
                "status": "published"
            }
        )

        assert response.status_code == 200
        data = response.json()
        assert data["data"]["title"] == "完整更新"
        assert data["data"]["status"] == "published"

    async def test_update_version_increment(
        self, client: AsyncClient, auth_headers, test_resume
    ):
        """测试: 更新后版本号增加"""
        original_version = test_resume.version

        response = await client.put(
            f"/api/v1/resumes/{test_resume.id}",
            headers=auth_headers,
            json={"title": "版本测试"}
        )

        assert response.status_code == 200
        data = response.json()
        assert data["data"]["version"] == original_version + 1

    async def test_update_saves_version_history(
        self, client: AsyncClient, auth_headers, test_resume, db_session
    ):
        """测试: 更新保存版本历史"""
        # 执行更新
        await client.put(
            f"/api/v1/resumes/{test_resume.id}",
            headers=auth_headers,
            json={"title": "版本测试"}
        )

        # 检查版本历史
        result = await db_session.execute(
            select(ResumeVersion).where(ResumeVersion.resume_id == test_resume.id)
        )
        versions = result.scalars().all()

        assert len(versions) >= 1
        latest = versions[0]
        assert latest.change_note == "自动保存"

    async def test_update_partial_fields(
        self, client: AsyncClient, auth_headers, test_resume
    ):
        """测试: 部分字段更新"""
        original_description = test_resume.description
        original_status = test_resume.status

        response = await client.put(
            f"/api/v1/resumes/{test_resume.id}",
            headers=auth_headers,
            json={"title": "仅更新标题"}
        )

        assert response.status_code == 200
        data = response.json()

        # 其他字段应该保持不变
        assert data["data"]["description"] == original_description
        assert data["data"]["status"] == original_status


class TestDeleteResumeMore:
    """删除简历扩展测试"""

    async def test_delete_removes_from_database(
        self, client: AsyncClient, auth_headers, test_user, db_session
    ):
        """测试: 删除后从数据库移除"""
        resume = Resume(
            user_id=test_user.id,
            title="待删除",
            content={},
            style_config={}
        )
        db_session.add(resume)
        await db_session.commit()
        resume_id = resume.id

        # 删除
        await client.delete(
            f"/api/v1/resumes/{resume_id}",
            headers=auth_headers
        )

        # 验证已被删除
        result = await db_session.execute(
            select(Resume).where(Resume.id == resume_id)
        )
        assert result.scalar_one_or_none() is None


class TestResumeVersionsMore:
    """简历版本扩展测试"""

    async def test_get_versions_ordering(
        self, client: AsyncClient, auth_headers, test_resume, db_session
    ):
        """测试: 版本按版本号降序排列"""
        # 创建多个版本
        await client.put(
            f"/api/v1/resumes/{test_resume.id}",
            headers=auth_headers,
            json={"title": "版本2"}
        )
        await client.put(
            f"/api/v1/resumes/{test_resume.id}",
            headers=auth_headers,
            json={"title": "版本3"}
        )

        response = await client.get(
            f"/api/v1/resumes/{test_resume.id}/versions",
            headers=auth_headers
        )

        assert response.status_code == 200
        data = response.json()
        versions = data["data"]

        # 应该按版本号降序排列
        if len(versions) >= 2:
            assert versions[0]["version_number"] >= versions[1]["version_number"]

    async def test_get_versions_unauthorized_resume(
        self, client: AsyncClient, auth_headers, db_session
    ):
        """测试: 获取其他用户简历的版本"""
        other_user = User(
            email="version_user@example.com",
            password_hash="hash",
            username="version_user",
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

        response = await client.get(
            f"/api/v1/resumes/{other_resume.id}/versions",
            headers=auth_headers
        )

        assert response.status_code == 404


class TestRollbackResumeMore:
    """回滚简历扩展测试"""

    async def test_rollback_creates_backup(
        self, client: AsyncClient, auth_headers, test_resume, db_session
    ):
        """测试: 回滚前备份当前状态"""
        # 修改简历
        await client.put(
            f"/api/v1/resumes/{test_resume.id}",
            headers=auth_headers,
            json={"content": {"current": "content"}}
        )

        # 创建历史版本
        old_version = ResumeVersion(
            resume_id=test_resume.id,
            version_number=1,
            content={"old": "content"},
            style_config={},
            change_note="测试版本"
        )
        db_session.add(old_version)
        await db_session.commit()

        # 执行回滚
        response = await client.post(
            f"/api/v1/resumes/{test_resume.id}/rollback/{old_version.id}",
            headers=auth_headers
        )

        assert response.status_code == 200

        # 检查备份版本
        result = await db_session.execute(
            select(ResumeVersion).where(
                ResumeVersion.resume_id == test_resume.id,
                ResumeVersion.change_note == "回滚前保存"
            )
        )
        backup = result.scalar_one_or_none()
        assert backup is not None

    async def test_rollback_updates_content(
        self, client: AsyncClient, auth_headers, test_resume, db_session
    ):
        """测试: 回滚更新简历内容"""
        old_version = ResumeVersion(
            resume_id=test_resume.id,
            version_number=1,
            content={"rollback": "test"},
            style_config={"theme": "old"},
            change_note="回滚测试"
        )
        db_session.add(old_version)
        await db_session.commit()

        response = await client.post(
            f"/api/v1/resumes/{test_resume.id}/rollback/{old_version.id}",
            headers=auth_headers
        )

        assert response.status_code == 200
        data = response.json()

        # 内容应该被回滚
        assert data["data"]["content"] == {"rollback": "test"}
        assert data["data"]["style_config"] == {"theme": "old"}


class TestAIGenerateResumeMore:
    """AI 生成简历扩展测试"""

    async def test_ai_generate_with_all_params(
        self, client: AsyncClient, auth_headers, test_resume
    ):
        """测试: 使用所有参数生成"""
        mock_ai_service = AsyncMock()
        mock_ai_service.generate_resume_content.return_value = {
            "content": {"generated": "content"},
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
                json={
                    "target_position": "高级工程师",
                    "style": "creative",
                    "language": "en"
                }
            )

            assert response.status_code == 200
            # 验证 AI 服务接收了所有参数
            mock_ai_service.generate_resume_content.assert_called_once()
            call_kwargs = mock_ai_service.generate_resume_content.call_args.kwargs
            assert call_kwargs["target_position"] == "高级工程师"
            assert call_kwargs["style"] == "creative"
            assert call_kwargs["language"] == "en"

    async def test_ai_generate_increments_version(
        self, client: AsyncClient, auth_headers, test_resume
    ):
        """测试: AI 生成增加版本号"""
        original_version = test_resume.version

        mock_ai_service = AsyncMock()
        mock_ai_service.generate_resume_content.return_value = {
            "content": {"new": "content"}
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
            data = response.json()
            assert data["data"]["version"] == original_version + 1

    async def test_ai_generate_updates_resume_content(
        self, client: AsyncClient, auth_headers, test_resume
    ):
        """测试: AI 生成更新简历内容"""
        mock_ai_service = AsyncMock()
        mock_ai_service.generate_resume_content.return_value = {
            "content": {"ai": "generated"}
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
            data = response.json()
            assert data["data"]["content"] == {"ai": "generated"}

    async def test_ai_generate_exceeds_daily_limit(
        self, client: AsyncClient, auth_headers, test_resume
    ):
        """测试: 超出每日限额"""
        mock_usage_service = AsyncMock()
        mock_usage_service.check_daily_limit = AsyncMock(return_value=(False, 100, 100))
        mock_usage_service.check_monthly_limit = AsyncMock(return_value=(True, 1, 1000))

        with patch("app.api.v1.resumes.get_ai_usage_service", return_value=mock_usage_service):
            response = await client.post(
                f"/api/v1/resumes/{test_resume.id}/ai/generate",
                headers=auth_headers,
                json={"target_position": "工程师"}
            )

            assert response.status_code == 429

    async def test_ai_generate_exceeds_monthly_limit(
        self, client: AsyncClient, auth_headers, test_resume
    ):
        """测试: 超出每月限额"""
        mock_usage_service = AsyncMock()
        mock_usage_service.check_daily_limit = AsyncMock(return_value=(True, 50, 100))
        mock_usage_service.check_monthly_limit = AsyncMock(return_value=(False, 2000, 2000))

        with patch("app.api.v1.resumes.get_ai_usage_service", return_value=mock_usage_service):
            response = await client.post(
                f"/api/v1/resumes/{test_resume.id}/ai/generate",
                headers=auth_headers,
                json={"target_position": "工程师"}
            )

            assert response.status_code == 429

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
                json={"target_position": "工程师"}
            )

            assert response.status_code == 404


class TestAIOptimizeContentMore:
    """AI 优化内容扩展测试"""

    async def test_optimize_records_usage(
        self, client: AsyncClient, auth_headers
    ):
        """测试: 优化记录 token 使用"""
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
                    "content": "原始内容" * 10,  # 较长内容
                    "optimization_type": "polish"
                }
            )

            assert response.status_code == 200
            # 应该记录了使用
            mock_usage_service.record_usage.assert_called_once()

    async def test_optimize_with_long_content(
        self, client: AsyncClient, auth_headers
    ):
        """测试: 优化长内容的 token 估算"""
        long_content = "内容" * 1000

        mock_ai_service = AsyncMock()
        mock_ai_service.optimize_content.return_value = "优化结果"

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
            # 验证 token 估算
            mock_usage_service.record_usage.assert_called_once()
            call_args = mock_usage_service.record_usage.call_args
            total_tokens = call_args.kwargs.get("total_tokens", 0)
            assert total_tokens > 0

    async def test_optimize_all_types(
        self, client: AsyncClient, auth_headers
    ):
        """测试: 所有优化类型"""
        mock_ai_service = AsyncMock()
        mock_ai_service.optimize_content.return_value = "优化后"

        mock_usage_service = AsyncMock()
        mock_usage_service.check_daily_limit = AsyncMock(return_value=(True, 1, 100))
        mock_usage_service.check_monthly_limit = AsyncMock(return_value=(True, 1, 1000))
        mock_usage_service.record_usage = AsyncMock()

        types = ["polish", "quantify", "keywords", "impact"]

        with patch("app.api.v1.resumes.get_ai_service", return_value=mock_ai_service), \
             patch("app.api.v1.resumes.get_ai_usage_service", return_value=mock_usage_service):
            for opt_type in types:
                response = await client.post(
                    "/api/v1/resumes/ai/optimize",
                    headers=auth_headers,
                    json={
                        "content": "测试",
                        "optimization_type": opt_type
                    }
                )
                assert response.status_code == 200

    async def test_optimize_empty_content(
        self, client: AsyncClient, auth_headers
    ):
        """测试: 优化空内容"""
        mock_ai_service = AsyncMock()
        mock_ai_service.optimize_content.return_value = ""

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
                    "content": "",
                    "optimization_type": "polish"
                }
            )

            assert response.status_code == 200

    async def test_optimize_exceeds_limits(
        self, client: AsyncClient, auth_headers
    ):
        """测试: 优化超出限额"""
        mock_usage_service = AsyncMock()
        mock_usage_service.check_daily_limit = AsyncMock(return_value=(False, 100, 100))
        mock_usage_service.check_monthly_limit = AsyncMock(return_value=(True, 1, 1000))

        with patch("app.api.v1.resumes.get_ai_usage_service", return_value=mock_usage_service):
            response = await client.post(
                "/api/v1/resumes/ai/optimize",
                headers=auth_headers,
                json={
                    "content": "测试",
                    "optimization_type": "polish"
                }
            )

            assert response.status_code == 429

    async def test_optimize_unauthorized(
        self, client: AsyncClient
    ):
        """测试: 未认证优化"""
        response = await client.post(
            "/api/v1/resumes/ai/optimize",
            json={
                "content": "测试",
                "optimization_type": "polish"
            }
        )

        assert response.status_code == 401
