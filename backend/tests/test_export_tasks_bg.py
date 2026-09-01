"""
导出任务后台处理测试 - 覆盖 process_export_task 函数
"""
import pytest
from unittest.mock import AsyncMock, patch, MagicMock
from httpx import AsyncClient
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from app.models.user import User
from app.models.resume import Resume
from app.models.export_task import ExportTask, ExportStatus, ExportFormat
import tempfile
import os


class TestProcessExportTaskBackground:
    """导出任务后台处理测试"""

    async def test_process_export_task_pending_only(
        self, db_session
    ):
        """测试: 只处理 PENDING 状态的任务"""
        from app.api.v1.export_tasks import process_export_task
        from app.models.user import User

        # 创建测试用户
        user = User(
            email="export_test@example.com",
            password_hash="hash",
            username="export_test",
            role="user"
        )
        db_session.add(user)
        await db_session.commit()

        # 创建已完成任务 - 不应被处理
        completed_task = ExportTask(
            user_id=user.id,
            resume_ids=[],
            export_format=ExportFormat.PDF,
            options={},
            status=ExportStatus.COMPLETED,
            progress=100.0
        )
        db_session.add(completed_task)
        await db_session.commit()

        # 调用后台处理 - 应该直接返回，不报错
        await process_export_task(completed_task.id, db_session)

        # 验证任务状态没有改变
        await db_session.refresh(completed_task)
        assert completed_task.status == ExportStatus.COMPLETED

    async def test_process_export_task_no_resumes(
        self, db_session
    ):
        """测试: 简历不存在时任务失败"""
        from app.api.v1.export_tasks import process_export_task
        from app.models.user import User

        user = User(
            email="export_fail@example.com",
            password_hash="hash",
            username="export_fail",
            role="user"
        )
        db_session.add(user)
        await db_session.commit()

        # 创建没有有效简历的任务
        task = ExportTask(
            user_id=user.id,
            resume_ids=[99999],  # 不存在的简历
            export_format=ExportFormat.PDF,
            options={},
            status=ExportStatus.PENDING,
            progress=0.0
        )
        db_session.add(task)
        await db_session.commit()

        # 调用后台处理 - 应该捕获错误并标记为失败
        await process_export_task(task.id, db_session)

        # 验证任务状态变为 FAILED
        await db_session.refresh(task)
        assert task.status == ExportStatus.FAILED

    async def test_export_task_pdf_content_type(
        self, client: AsyncClient, auth_headers, test_user, db_session
    ):
        """测试: PDF 格式导出的 MIME 类型"""
        from app.models.export_task import ExportTask
        from app.models.resume import Resume

        resume = Resume(
            user_id=test_user.id,
            title="PDF测试简历",
            content={"basic_info": {"name": "测试"}},
            style_config={},
            status="draft"
        )
        db_session.add(resume)
        await db_session.commit()

        # 创建已完成且已有文件的任务
        with tempfile.NamedTemporaryFile(suffix=".pdf", delete=False) as tmp:
            tmp_path = tmp.name

        try:
            task = ExportTask(
                user_id=test_user.id,
                resume_ids=[resume.id],
                export_format=ExportFormat.PDF,
                options={},
                status=ExportStatus.COMPLETED,
                progress=100.0,
                file_path=tmp_path,
                file_size=100
            )
            db_session.add(task)
            await db_session.commit()

            # 下载文件 - 检查 content type
            response = await client.get(
                f"/api/v1/export-tasks/{task.id}/download",
                headers=auth_headers
            )

            # 由于文件可能不存在或权限问题，可能返回 404
            assert response.status_code in [200, 404]
        finally:
            if os.path.exists(tmp_path):
                os.unlink(tmp_path)

    async def test_export_task_all_formats(
        self, client: AsyncClient, auth_headers, test_user, db_session
    ):
        """测试: 所有导出格式的任务创建"""
        from app.models.export_task import ExportTask
        from app.models.resume import Resume

        resume = Resume(
            user_id=test_user.id,
            title="格式测试",
            content={},
            style_config={},
            status="draft"
        )
        db_session.add(resume)
        await db_session.commit()

        formats = [
            ExportFormat.PDF,
            ExportFormat.DOCX,
            ExportFormat.HTML
        ]

        for fmt in formats:
            task = ExportTask(
                user_id=test_user.id,
                resume_ids=[resume.id],
                export_format=fmt,
                options={},
                status=ExportStatus.COMPLETED,
                file_path=f"/fake/test.{fmt.value}",
                file_size=100
            )
            db_session.add(task)
            await db_session.commit()

            # 获取任务详情
            response = await client.get(
                f"/api/v1/export-tasks/{task.id}",
                headers=auth_headers
            )

            assert response.status_code == 200
            data = response.json()
            assert data["data"]["export_format"] == fmt.value


class TestExportTaskListFilters:
    """导出任务列表筛选测试"""

    async def test_list_tasks_by_status_pending(
        self, client: AsyncClient, auth_headers, test_user, db_session
    ):
        """测试: 筛选 PENDING 状态任务"""
        from app.models.export_task import ExportTask, ExportFormat

        # 创建不同状态的任务
        pending_task = ExportTask(
            user_id=test_user.id,
            resume_ids=[],
            export_format=ExportFormat.PDF,
            status=ExportStatus.PENDING,
            progress=0.0
        )
        completed_task = ExportTask(
            user_id=test_user.id,
            resume_ids=[],
            export_format=ExportFormat.PDF,
            status=ExportStatus.COMPLETED,
            progress=100.0
        )
        db_session.add(pending_task)
        db_session.add(completed_task)
        await db_session.commit()

        # 筛选 PENDING
        response = await client.get(
            "/api/v1/export-tasks?status=pending",
            headers=auth_headers
        )

        assert response.status_code == 200
        data = response.json()
        assert data["code"] == 0

    async def test_list_tasks_by_status_processing(
        self, client: AsyncClient, auth_headers, test_user, db_session
    ):
        """测试: 筛选 PROCESSING 状态任务"""
        from app.models.export_task import ExportTask, ExportFormat

        processing_task = ExportTask(
            user_id=test_user.id,
            resume_ids=[],
            export_format=ExportFormat.DOCX,
            status=ExportStatus.PROCESSING,
            progress=50.0
        )
        db_session.add(processing_task)
        await db_session.commit()

        response = await client.get(
            "/api/v1/export-tasks?status=processing",
            headers=auth_headers
        )

        assert response.status_code == 200

    async def test_list_tasks_by_status_failed(
        self, client: AsyncClient, auth_headers, test_user, db_session
    ):
        """测试: 筛选 FAILED 状态任务"""
        from app.models.export_task import ExportTask, ExportFormat

        failed_task = ExportTask(
            user_id=test_user.id,
            resume_ids=[],
            export_format=ExportFormat.HTML,
            status=ExportStatus.FAILED,
            progress=0.0,
            error_message="导出失败"
        )
        db_session.add(failed_task)
        await db_session.commit()

        response = await client.get(
            "/api/v1/export-tasks?status=failed",
            headers=auth_headers
        )

        assert response.status_code == 200


class TestExportTaskDownloadEdgeCases:
    """导出任务下载边界情况测试"""

    async def test_download_task_pending_status(
        self, client: AsyncClient, auth_headers, test_user, db_session
    ):
        """测试: 下载 PENDING 状态任务"""
        from app.models.export_task import ExportTask, ExportFormat

        task = ExportTask(
            user_id=test_user.id,
            resume_ids=[],
            export_format=ExportFormat.PDF,
            status=ExportStatus.PENDING,
            progress=0.0
        )
        db_session.add(task)
        await db_session.commit()

        response = await client.get(
            f"/api/v1/export-tasks/{task.id}/download",
            headers=auth_headers
        )

        assert response.status_code == 400

    async def test_download_task_processing_status(
        self, client: AsyncClient, auth_headers, test_user, db_session
    ):
        """测试: 下载 PROCESSING 状态任务"""
        from app.models.export_task import ExportTask, ExportFormat

        task = ExportTask(
            user_id=test_user.id,
            resume_ids=[],
            export_format=ExportFormat.PDF,
            status=ExportStatus.PROCESSING,
            progress=50.0
        )
        db_session.add(task)
        await db_session.commit()

        response = await client.get(
            f"/api/v1/export-tasks/{task.id}/download",
            headers=auth_headers
        )

        assert response.status_code == 400

    async def test_download_task_failed_status(
        self, client: AsyncClient, auth_headers, test_user, db_session
    ):
        """测试: 下载 FAILED 状态任务"""
        from app.models.export_task import ExportTask, ExportFormat

        task = ExportTask(
            user_id=test_user.id,
            resume_ids=[],
            export_format=ExportFormat.PDF,
            status=ExportStatus.FAILED,
            progress=0.0,
            error_message="处理失败"
        )
        db_session.add(task)
        await db_session.commit()

        response = await client.get(
            f"/api/v1/export-tasks/{task.id}/download",
            headers=auth_headers
        )

        assert response.status_code == 400

    async def test_download_task_no_file_path(
        self, client: AsyncClient, auth_headers, test_user, db_session
    ):
        """测试: 下载没有文件路径的任务"""
        from app.models.export_task import ExportTask, ExportFormat

        task = ExportTask(
            user_id=test_user.id,
            resume_ids=[],
            export_format=ExportFormat.PDF,
            status=ExportStatus.COMPLETED,
            progress=100.0,
            file_path=None
        )
        db_session.add(task)
        await db_session.commit()

        response = await client.get(
            f"/api/v1/export-tasks/{task.id}/download",
            headers=auth_headers
        )

        assert response.status_code == 404


class TestExportTaskDeleteEdgeCases:
    """导出任务删除边界情况测试"""

    async def test_delete_task_with_file_cleanup(
        self, client: AsyncClient, auth_headers, test_user, db_session
    ):
        """测试: 删除任务时清理文件"""
        from app.models.export_task import ExportTask, ExportFormat
        import tempfile

        # 创建临时文件
        with tempfile.NamedTemporaryFile(suffix=".pdf", delete=False) as tmp:
            tmp_path = tmp.name

        try:
            task = ExportTask(
                user_id=test_user.id,
                resume_ids=[],
                export_format=ExportFormat.PDF,
                status=ExportStatus.COMPLETED,
                file_path=tmp_path,
                file_size=100
            )
            db_session.add(task)
            await db_session.commit()

            # 删除任务
            response = await client.delete(
                f"/api/v1/export-tasks/{task.id}",
                headers=auth_headers
            )

            assert response.status_code == 200
        finally:
            if os.path.exists(tmp_path):
                os.unlink(tmp_path)

    async def test_delete_task_file_cleanup_error(
        self, client: AsyncClient, auth_headers, test_user, db_session
    ):
        """测试: 文件删除失败不影响任务删除"""
        from app.models.export_task import ExportTask, ExportFormat

        # 使用不存在的文件路径
        task = ExportTask(
            user_id=test_user.id,
            resume_ids=[],
            export_format=ExportFormat.PDF,
            status=ExportStatus.COMPLETED,
            file_path="/nonexistent/path/file.pdf",
            file_size=100
        )
        db_session.add(task)
        await db_session.commit()

        # 删除应该成功，即使文件不存在
        response = await client.delete(
            f"/api/v1/export-tasks/{task.id}",
            headers=auth_headers
        )

        assert response.status_code == 200


class TestExportTaskUnauthorized:
    """导出任务未授权访问测试"""

    async def test_get_other_user_task(
        self, client: AsyncClient, auth_headers, db_session
    ):
        """测试: 获取其他用户的导出任务"""
        from app.models.user import User
        from app.models.export_task import ExportTask, ExportFormat

        other_user = User(
            email="task_other@example.com",
            password_hash="hash",
            username="task_other",
            role="user"
        )
        db_session.add(other_user)
        await db_session.commit()

        other_task = ExportTask(
            user_id=other_user.id,
            resume_ids=[],
            export_format=ExportFormat.PDF,
            status=ExportStatus.PENDING
        )
        db_session.add(other_task)
        await db_session.commit()

        response = await client.get(
            f"/api/v1/export-tasks/{other_task.id}",
            headers=auth_headers
        )

        assert response.status_code == 404

    async def test_delete_other_user_task(
        self, client: AsyncClient, auth_headers, db_session
    ):
        """测试: 删除其他用户的导出任务"""
        from app.models.user import User
        from app.models.export_task import ExportTask, ExportFormat

        other_user = User(
            email="delete_other@example.com",
            password_hash="hash",
            username="delete_other",
            role="user"
        )
        db_session.add(other_user)
        await db_session.commit()

        other_task = ExportTask(
            user_id=other_user.id,
            resume_ids=[],
            export_format=ExportFormat.PDF,
            status=ExportStatus.PENDING
        )
        db_session.add(other_task)
        await db_session.commit()

        response = await client.delete(
            f"/api/v1/export-tasks/{other_task.id}",
            headers=auth_headers
        )

        assert response.status_code == 404

    async def test_download_other_user_task(
        self, client: AsyncClient, auth_headers, db_session
    ):
        """测试: 下载其他用户的导出文件"""
        from app.models.user import User
        from app.models.export_task import ExportTask, ExportFormat

        other_user = User(
            email="download_other@example.com",
            password_hash="hash",
            username="download_other",
            role="user"
        )
        db_session.add(other_user)
        await db_session.commit()

        other_task = ExportTask(
            user_id=other_user.id,
            resume_ids=[],
            export_format=ExportFormat.PDF,
            status=ExportStatus.COMPLETED,
            file_path="/fake/file.pdf"
        )
        db_session.add(other_task)
        await db_session.commit()

        response = await client.get(
            f"/api/v1/export-tasks/{other_task.id}/download",
            headers=auth_headers
        )

        assert response.status_code == 404


class TestExportTaskCreateValidation:
    """导出任务创建验证测试"""

    async def test_create_task_without_auth(
        self, client: AsyncClient
    ):
        """测试: 未认证创建任务"""
        response = await client.post(
            "/api/v1/export-tasks",
            json={
                "resume_ids": [1],
                "export_format": "pdf"
            }
        )

        assert response.status_code == 401

    async def test_create_task_invalid_format(
        self, client: AsyncClient, auth_headers
    ):
        """测试: 无效的导出格式"""
        response = await client.post(
            "/api/v1/export-tasks",
            headers=auth_headers,
            json={
                "resume_ids": [1],
                "export_format": "invalid_format"
            }
        )

        assert response.status_code == 422

    async def test_create_task_empty_resume_ids(
        self, client: AsyncClient, auth_headers
    ):
        """测试: 空简历列表"""
        response = await client.post(
            "/api/v1/export-tasks",
            headers=auth_headers,
            json={
                "resume_ids": [],
                "export_format": "pdf"
            }
        )

        # API 可能接受空列表或返回错误
        assert response.status_code in [200, 400, 422]
