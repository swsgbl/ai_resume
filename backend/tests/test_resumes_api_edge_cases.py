"""
Resumes API 边界情况测试 - 针对缺失覆盖行
"""
import pytest
from httpx import AsyncClient
from unittest.mock import AsyncMock, patch, MagicMock
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select

from app.models.user import User
from app.models.resume import Resume, ResumeVersion
from app.models.template import Template
from app.services.ai_limit_decorator import AIUsageLimitExceeded


class TestAIGenerateEdgeCases:
    """AI 生成边界情况测试"""

    async def test_ai_generate_dict_without_meta(
        self, client: AsyncClient, auth_headers, test_resume
    ):
        """测试: AI 返回字典但没有 meta 信息"""
        mock_ai_service = AsyncMock()
        mock_ai_service.generate_resume_content.return_value = {
            "content": {"basic_info": {"name": "测试"}}
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
                json={"target_position": "软件工程师"}
            )

            assert response.status_code == 200

    async def test_ai_generate_dict_without_content(
        self, client: AsyncClient, auth_headers, test_resume
    ):
        """测试: AI 返回字典但没有 content 字段"""
        mock_ai_service = AsyncMock()
        mock_ai_service.generate_resume_content.return_value = {"other": "data"}

        mock_usage_service = AsyncMock()
        mock_usage_service.check_daily_limit = AsyncMock(return_value=(True, 1, 100))
        mock_usage_service.check_monthly_limit = AsyncMock(return_value=(True, 1, 1000))
        mock_usage_service.record_usage = AsyncMock()

        with patch("app.api.v1.resumes.get_ai_service", return_value=mock_ai_service), \
             patch("app.api.v1.resumes.get_ai_usage_service", return_value=mock_usage_service):
            response = await client.post(
                f"/api/v1/resumes/{test_resume.id}/ai/generate",
                headers=auth_headers,
                json={"target_position": "软件工程师"}
            )

            # 应该处理这种情况
            assert response.status_code == 200

    async def test_ai_generate_with_usage_info(
        self, client: AsyncClient, auth_headers, test_resume
    ):
        """测试: AI 返回包含 usage 信息"""
        mock_ai_service = AsyncMock()
        mock_ai_service.generate_resume_content.return_value = {
            "content": {"basic_info": {"name": "测试"}},
            "usage": {
                "prompt_tokens": 150,
                "completion_tokens": 250,
                "total_tokens": 400
            },
            "meta": {
                "provider": "deepseek",
                "model": "deepseek-chat"
            }
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
                json={"target_position": "软件工程师"}
            )

            assert response.status_code == 200
            # 验证 record_usage 被调用
            mock_usage_service.record_usage.assert_called_once()

    async def test_ai_generate_record_usage_failure(
        self, client: AsyncClient, auth_headers, test_resume
    ):
        """测试: 记录 AI 使用失败不影响主流程"""
        mock_ai_service = AsyncMock()
        mock_ai_service.generate_resume_content.return_value = {
            "content": {"basic_info": {"name": "测试"}}
        }

        mock_usage_service = AsyncMock()
        mock_usage_service.check_daily_limit = AsyncMock(return_value=(True, 1, 100))
        mock_usage_service.check_monthly_limit = AsyncMock(return_value=(True, 1, 1000))
        # 记录使用时抛出异常
        mock_usage_service.record_usage = AsyncMock(side_effect=Exception("记录失败"))

        with patch("app.api.v1.resumes.get_ai_service", return_value=mock_ai_service), \
             patch("app.api.v1.resumes.get_ai_usage_service", return_value=mock_usage_service):
            response = await client.post(
                f"/api/v1/resumes/{test_resume.id}/ai/generate",
                headers=auth_headers,
                json={"target_position": "软件工程师"}
            )

            # 应该仍然成功，只是记录失败
            assert response.status_code == 200

    async def test_ai_generate_with_style_and_language(
        self, client: AsyncClient, auth_headers, test_resume
    ):
        """测试: 指定风格和语言"""
        mock_ai_service = AsyncMock()
        mock_ai_service.generate_resume_content.return_value = {
            "content": {"basic_info": {"name": "专业"}}
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
                    "target_position": "前端工程师",
                    "style": "creative",
                    "language": "en"
                }
            )

            assert response.status_code == 200
            # 验证 AI 服务接收到了正确的参数
            mock_ai_service.generate_resume_content.assert_called_once()
            call_kwargs = mock_ai_service.generate_resume_content.call_args.kwargs
            assert call_kwargs["style"] == "creative"
            assert call_kwargs["language"] == "en"


class TestAIOptimizeEdgeCases:
    """AI 优化边界情况测试"""

    async def test_ai_optimize_with_context(
        self, client: AsyncClient, auth_headers
    ):
        """测试: 带上下文的优化"""
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
                    "content": "负责开发应用",
                    "optimization_type": "impact",
                    "context": "需要后端开发经验"
                }
            )

            assert response.status_code == 200
            data = response.json()
            assert data["data"]["optimized"] == "优化后的内容"
            assert data["data"]["original"] == "负责开发应用"

    async def test_ai_optimize_empty_content(
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

    async def test_ai_optimize_long_content(
        self, client: AsyncClient, auth_headers
    ):
        """测试: 优化长内容（token 估算）"""
        long_content = "内容" * 1000  # 模拟较长内容

        mock_ai_service = AsyncMock()
        mock_ai_service.optimize_content.return_value = "优化后的结果"

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
                    "optimization_type": "conciseness"
                }
            )

            assert response.status_code == 200
            # 验证记录使用了估算的 token
            mock_usage_service.record_usage.assert_called_once()

    async def test_ai_optimize_record_usage_failure(
        self, client: AsyncClient, auth_headers
    ):
        """测试: 优化记录使用失败"""
        mock_ai_service = AsyncMock()
        mock_ai_service.optimize_content.return_value = "优化内容"

        mock_usage_service = AsyncMock()
        mock_usage_service.check_daily_limit = AsyncMock(return_value=(True, 1, 100))
        mock_usage_service.check_monthly_limit = AsyncMock(return_value=(True, 1, 1000))
        mock_usage_service.record_usage = AsyncMock(side_effect=Exception("记录失败"))

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

            # 应该仍然成功
            assert response.status_code == 200

    async def test_ai_optimize_different_types(
        self, client: AsyncClient, auth_headers
    ):
        """测试: 不同优化类型"""
        mock_ai_service = AsyncMock()
        mock_ai_service.optimize_content.return_value = "优化结果"

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
                        "content": "测试内容",
                        "optimization_type": opt_type
                    }
                )

                assert response.status_code == 200


class TestUpdateResumeEdgeCases:
    """更新简历边界情况测试"""

    async def test_update_all_fields_including_template(
        self, client: AsyncClient, auth_headers, test_resume, db_session
    ):
        """测试: 更新所有字段包括模板"""
        # 创建模板
        template = Template(
            name="新模板",
            layout="modern",
            is_active=True
        )
        db_session.add(template)
        await db_session.commit()

        response = await client.put(
            f"/api/v1/resumes/{test_resume.id}",
            headers=auth_headers,
            json={
                "title": "完整更新",
                "description": "完整描述",
                "template_id": template.id,
                "content": {"basic_info": {"name": "完整更新"}},
                "style_config": {"theme": "updated"},
                "status": "published"
            }
        )

        assert response.status_code == 200
        data = response.json()
        assert data["data"]["title"] == "完整更新"
        assert data["data"]["template_id"] == template.id
        assert data["data"]["status"] == "published"

    async def test_update_preserves_old_version(
        self, client: AsyncClient, auth_headers, test_resume, db_session
    ):
        """测试: 更新时保留旧版本内容"""
        # 设置原始内容
        test_resume.content = {"original": "content"}
        test_resume.style_config = {"original": "style"}
        await db_session.commit()

        # 更新
        await client.put(
            f"/api/v1/resumes/{test_resume.id}",
            headers=auth_headers,
            json={
                "content": {"new": "content"},
                "style_config": {"new": "style"}
            }
        )

        # 检查版本历史
        result = await db_session.execute(
            select(ResumeVersion).where(
                ResumeVersion.resume_id == test_resume.id
            ).order_by(ResumeVersion.version_number.desc())
        )
        versions = result.scalars().all()

        assert len(versions) >= 1
        # 验证版本保存了原始内容
        latest_version = versions[0]
        assert latest_version.content == {"original": "content"}
        assert latest_version.style_config == {"original": "style"}
        assert latest_version.change_note == "自动保存"

    async def test_update_increments_version(
        self, client: AsyncClient, auth_headers, test_resume
    ):
        """测试: 更新增加版本号"""
        original_version = test_resume.version

        response = await client.put(
            f"/api/v1/resumes/{test_resume.id}",
            headers=auth_headers,
            json={"title": "新版本"}
        )

        assert response.status_code == 200
        data = response.json()
        assert data["data"]["version"] == original_version + 1


class TestRollbackResumeEdgeCases:
    """回滚简历边界情况测试"""

    async def test_rollback_creates_current_version_backup(
        self, client: AsyncClient, auth_headers, test_resume, db_session
    ):
        """测试: 回滚前保存当前版本"""
        # 设置当前状态
        test_resume.content = {"current": "data"}
        test_resume.style_config = {"current": "style"}
        test_resume.version = 5
        await db_session.commit()

        # 创建历史版本
        old_version = ResumeVersion(
            resume_id=test_resume.id,
            version_number=3,
            content={"old": "data"},
            style_config={"old": "style"},
            change_note="旧版本"
        )
        db_session.add(old_version)
        await db_session.commit()

        # 执行回滚
        response = await client.post(
            f"/api/v1/resumes/{test_resume.id}/rollback/{old_version.id}",
            headers=auth_headers
        )

        assert response.status_code == 200
        data = response.json()
        assert data["data"]["content"] == {"old": "data"}

        # 检查是否创建了当前版本的备份
        result = await db_session.execute(
            select(ResumeVersion).where(
                ResumeVersion.resume_id == test_resume.id,
                ResumeVersion.change_note == "回滚前保存"
            )
        )
        backup_version = result.scalar_one_or_none()
        assert backup_version is not None
        assert backup_version.content == {"current": "data"}

    async def test_rollback_increments_version(
        self, client: AsyncClient, auth_headers, test_resume, db_session
    ):
        """测试: 回滚增加版本号"""
        original_version = test_resume.version

        old_version = ResumeVersion(
            resume_id=test_resume.id,
            version_number=1,
            content={},
            style_config={},
            change_note="测试"
        )
        db_session.add(old_version)
        await db_session.commit()

        response = await client.post(
            f"/api/v1/resumes/{test_resume.id}/rollback/{old_version.id}",
            headers=auth_headers
        )

        assert response.status_code == 200
        data = response.json()
        assert data["data"]["version"] == original_version + 1

    async def test_rollback_version_not_found(
        self, client: AsyncClient, auth_headers, test_resume
    ):
        """测试: 回滚不存在的版本"""
        response = await client.post(
            f"/api/v1/resumes/{test_resume.id}/rollback/99999",
            headers=auth_headers
        )

        assert response.status_code == 404

    async def test_rollback_other_resume_version(
        self, client: AsyncClient, auth_headers, test_resume, db_session
    ):
        """测试: 尝试回滚到其他简历的版本"""
        other_resume = Resume(
            user_id=test_resume.user_id,
            title="其他简历",
            content={},
            style_config={}
        )
        db_session.add(other_resume)
        await db_session.commit()

        other_version = ResumeVersion(
            resume_id=other_resume.id,
            version_number=1,
            content={},
            style_config={},
            change_note="其他"
        )
        db_session.add(other_version)
        await db_session.commit()

        response = await client.post(
            f"/api/v1/resumes/{test_resume.id}/rollback/{other_version.id}",
            headers=auth_headers
        )

        assert response.status_code == 404


class TestListResumeEdgeCases:
    """简历列表边界情况测试"""

    async def test_list_resumes_status_filter_with_count(
        self, client: AsyncClient, auth_headers, test_user, db_session
    ):
        """测试: 状态筛选时正确计数"""
        from app.models.resume import Resume

        # 创建不同状态的简历
        for i in range(3):
            draft = Resume(
                user_id=test_user.id,
                title=f"草稿{i}",
                content={},
                style_config={},
                status="draft"
            )
            db_session.add(draft)

        for i in range(5):
            published = Resume(
                user_id=test_user.id,
                title=f"已发布{i}",
                content={},
                style_config={},
                status="published"
            )
            db_session.add(published)

        await db_session.commit()

        # 查询草稿
        response = await client.get(
            "/api/v1/resumes?status=draft",
            headers=auth_headers
        )

        assert response.status_code == 200
        data = response.json()
        assert data["total"] >= 3

    async def test_list_resumes_defaults_ordering(
        self, client: AsyncClient, auth_headers, test_user, db_session
    ):
        """测试: 默认按更新时间降序排列"""
        import time
        from app.models.resume import Resume

        resume_ids = []
        for i in range(3):
            resume = Resume(
                user_id=test_user.id,
                title=f"排序{i}",
                content={},
                style_config={}
            )
            db_session.add(resume)
            await db_session.commit()
            resume_ids.append(resume.id)
            time.sleep(0.01)

        response = await client.get(
            "/api/v1/resumes?page_size=10",
            headers=auth_headers
        )

        assert response.status_code == 200
        data = response.json()

        # 找到我们创建的简历
        created_resumes = [r for r in data["data"] if r["id"] in resume_ids]
        if len(created_resumes) >= 2:
            # 最新的应该在前面
            assert created_resumes[0]["updated_at"] >= created_resumes[1]["updated_at"]


class TestAIServiceErrorHandling:
    """AI 服务错误处理测试"""

    async def test_ai_service_unavailable(
        self, client: AsyncClient, auth_headers, test_resume
    ):
        """测试: AI 服务返回 None"""
        mock_ai_service = AsyncMock()
        # 返回 None 模拟服务没有返回内容
        mock_ai_service.generate_resume_content.return_value = None

        mock_usage_service = AsyncMock()
        mock_usage_service.check_daily_limit = AsyncMock(return_value=(True, 1, 100))
        mock_usage_service.check_monthly_limit = AsyncMock(return_value=(True, 1, 1000))

        with patch("app.api.v1.resumes.get_ai_service", return_value=mock_ai_service), \
             patch("app.api.v1.resumes.get_ai_usage_service", return_value=mock_usage_service):
            response = await client.post(
                f"/api/v1/resumes/{test_resume.id}/ai/generate",
                headers=auth_headers,
                json={"target_position": "软件工程师"}
            )

            # None 值会被直接设置到 content，所以返回 200
            assert response.status_code == 200

    async def test_ai_optimize_returns_empty(
        self, client: AsyncClient, auth_headers
    ):
        """测试: AI 优化服务返回空字符串"""
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
                    "content": "测试",
                    "optimization_type": "polish"
                }
            )

            # 空字符串是有效响应
            assert response.status_code == 200
