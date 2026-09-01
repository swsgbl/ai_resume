"""
导出任务后台处理函数单元测试
覆盖 process_export_task 的所有分支
"""
import pytest
import tempfile
import os
from unittest.mock import AsyncMock, patch, MagicMock, mock_open
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select

from app.models.user import User
from app.models.resume import Resume
from app.models.export_task import ExportTask, ExportStatus, ExportFormat


class TestProcessExportTaskUnit:
    """process_export_task 函数单元测试"""

    async def test_process_pdf_export_success(
        self, db_session: AsyncSession
    ):
        """测试: PDF 格式导出成功"""
        from app.api.v1.export_tasks import process_export_task

        # 创建用户和简历
        user = User(
            email="pdf_export@example.com",
            password_hash="hash",
            username="pdf_export",
            role="user"
        )
        db_session.add(user)
        await db_session.commit()

        resume = Resume(
            user_id=user.id,
            title="PDF导出测试",
            content={"basic_info": {"name": "测试用户"}},
            style_config={"theme": "professional"},
            status="draft"
        )
        db_session.add(resume)
        await db_session.commit()

        # 创建待处理任务
        task = ExportTask(
            user_id=user.id,
            resume_ids=[resume.id],
            export_format=ExportFormat.PDF,
            options={"style_config": {"color": "blue"}},
            status=ExportStatus.PENDING,
            progress=0.0
        )
        db_session.add(task)
        await db_session.commit()

        # Mock ExportService
        mock_pdf_bytes = b"%PDF-1.4 fake pdf content"
        mock_export_service = AsyncMock()
        mock_export_service.to_pdf = AsyncMock(return_value=mock_pdf_bytes)

        with patch("app.services.export.export_service.ExportService", return_value=mock_export_service):
            with patch("os.makedirs"):
                with patch("builtins.open", mock_open()):
                    await process_export_task(task.id, db_session)

        # 验证任务状态
        await db_session.refresh(task)
        assert task.status == ExportStatus.COMPLETED
        assert task.progress == 100.0
        assert task.completed_at is not None

    async def test_process_docx_export_success(
        self, db_session: AsyncSession
    ):
        """测试: DOCX 格式导出成功"""
        from app.api.v1.export_tasks import process_export_task

        user = User(
            email="docx_export@example.com",
            password_hash="hash",
            username="docx_export",
            role="user"
        )
        db_session.add(user)
        await db_session.commit()

        resume = Resume(
            user_id=user.id,
            title="DOCX导出测试",
            content={"basic_info": {"name": "用户"}},
            style_config={},
            status="draft"
        )
        db_session.add(resume)
        await db_session.commit()

        task = ExportTask(
            user_id=user.id,
            resume_ids=[resume.id],
            export_format=ExportFormat.DOCX,
            options={},
            status=ExportStatus.PENDING,
            progress=0.0
        )
        db_session.add(task)
        await db_session.commit()

        # Mock ExportService
        mock_docx_bytes = b"PK\x03\x04 fake docx"
        mock_export_service = AsyncMock()
        mock_export_service.to_word = AsyncMock(return_value=mock_docx_bytes)

        with patch("app.services.export.export_service.ExportService", return_value=mock_export_service):
            with patch("os.makedirs"):
                with patch("builtins.open", mock_open()):
                    await process_export_task(task.id, db_session)

        await db_session.refresh(task)
        assert task.status == ExportStatus.COMPLETED
        assert task.progress == 100.0

    async def test_process_html_export_success(
        self, db_session: AsyncSession
    ):
        """测试: HTML 格式导出成功"""
        from app.api.v1.export_tasks import process_export_task

        user = User(
            email="html_export@example.com",
            password_hash="hash",
            username="html_export",
            role="user"
        )
        db_session.add(user)
        await db_session.commit()

        resume = Resume(
            user_id=user.id,
            title="HTML导出测试",
            content={"basic_info": {"name": "用户"}},
            style_config={},
            status="draft"
        )
        db_session.add(resume)
        await db_session.commit()

        task = ExportTask(
            user_id=user.id,
            resume_ids=[resume.id],
            export_format=ExportFormat.HTML,
            options={},
            status=ExportStatus.PENDING,
            progress=0.0
        )
        db_session.add(task)
        await db_session.commit()

        mock_html_content = "<html><body>简历内容</body></html>"
        mock_export_service = AsyncMock()
        mock_export_service.to_html = AsyncMock(return_value=mock_html_content)

        with patch("app.services.export.export_service.ExportService", return_value=mock_export_service):
            with patch("os.makedirs"):
                with patch("builtins.open", mock_open()):
                    await process_export_task(task.id, db_session)

        await db_session.refresh(task)
        assert task.status == ExportStatus.COMPLETED
        assert task.progress == 100.0

    async def test_process_export_multiple_resumes_merge(
        self, db_session: AsyncSession
    ):
        """测试: 多简历合并导出"""
        from app.api.v1.export_tasks import process_export_task

        user = User(
            email="multi_export@example.com",
            password_hash="hash",
            username="multi_export",
            role="user"
        )
        db_session.add(user)
        await db_session.commit()

        # 创建多个简历
        resume1 = Resume(
            user_id=user.id,
            title="简历1",
            content={"basic_info": {"name": "张三"}, "skills": ["Python"]},
            style_config={"theme": "modern"},
            status="draft"
        )
        resume2 = Resume(
            user_id=user.id,
            title="简历2",
            content={"education": [{"school": "清华"}]},
            style_config={"color": "blue"},
            status="draft"
        )
        db_session.add(resume1)
        db_session.add(resume2)
        await db_session.commit()

        task = ExportTask(
            user_id=user.id,
            resume_ids=[resume1.id, resume2.id],
            export_format=ExportFormat.PDF,
            options={},
            status=ExportStatus.PENDING,
            progress=0.0
        )
        db_session.add(task)
        await db_session.commit()

        mock_export_service = AsyncMock()
        mock_export_service.to_pdf = AsyncMock(return_value=b"pdf")

        with patch("app.services.export.export_service.ExportService", return_value=mock_export_service):
            with patch("os.makedirs"):
                with patch("builtins.open", mock_open()):
                    await process_export_task(task.id, db_session)

        await db_session.refresh(task)
        assert task.status == ExportStatus.COMPLETED

    async def test_process_export_no_resumes_found(
        self, db_session: AsyncSession
    ):
        """测试: 未找到有效简历时任务失败"""
        from app.api.v1.export_tasks import process_export_task

        user = User(
            email="no_resume@example.com",
            password_hash="hash",
            username="no_resume",
            role="user"
        )
        db_session.add(user)
        await db_session.commit()

        # 创建任务，但简历 ID 不存在
        task = ExportTask(
            user_id=user.id,
            resume_ids=[99999],
            export_format=ExportFormat.PDF,
            options={},
            status=ExportStatus.PENDING,
            progress=0.0
        )
        db_session.add(task)
        await db_session.commit()

        with patch("app.services.export.export_service.ExportService"):
            await process_export_task(task.id, db_session)

        await db_session.refresh(task)
        assert task.status == ExportStatus.FAILED
        assert task.error_message is not None
        assert "未找到有效的简历" in task.error_message

    async def test_process_export_task_not_pending(
        self, db_session: AsyncSession
    ):
        """测试: 非 PENDING 状态任务不处理"""
        from app.api.v1.export_tasks import process_export_task

        user = User(
            email="not_pending@example.com",
            password_hash="hash",
            username="not_pending",
            role="user"
        )
        db_session.add(user)
        await db_session.commit()

        # 创建已完成任务
        task = ExportTask(
            user_id=user.id,
            resume_ids=[],
            export_format=ExportFormat.PDF,
            options={},
            status=ExportStatus.COMPLETED,
            progress=100.0
        )
        db_session.add(task)
        await db_session.commit()

        original_status = task.status
        original_progress = task.progress

        # 调用处理函数
        with patch("app.services.export.export_service.ExportService"):
            await process_export_task(task.id, db_session)

        # 验证状态未改变
        await db_session.refresh(task)
        assert task.status == original_status
        assert task.progress == original_progress

    async def test_process_export_task_not_found(
        self, db_session: AsyncSession
    ):
        """测试: 任务不存在时不报错"""
        from app.api.v1.export_tasks import process_export_task

        # 不存在的任务 ID，应该正常返回不报错
        with patch("app.services.export.export_service.ExportService"):
            await process_export_task(99999, db_session)

    async def test_process_export_pdf_service_error(
        self, db_session: AsyncSession
    ):
        """测试: PDF 生成服务异常时任务失败"""
        from app.api.v1.export_tasks import process_export_task

        user = User(
            email="pdf_error@example.com",
            password_hash="hash",
            username="pdf_error",
            role="user"
        )
        db_session.add(user)
        await db_session.commit()

        resume = Resume(
            user_id=user.id,
            title="错误测试",
            content={},
            style_config={},
            status="draft"
        )
        db_session.add(resume)
        await db_session.commit()

        task = ExportTask(
            user_id=user.id,
            resume_ids=[resume.id],
            export_format=ExportFormat.PDF,
            options={},
            status=ExportStatus.PENDING,
            progress=0.0
        )
        db_session.add(task)
        await db_session.commit()

        # Mock 服务抛出异常
        mock_export_service = AsyncMock()
        mock_export_service.to_pdf = AsyncMock(side_effect=Exception("PDF生成失败"))

        with patch("app.services.export.export_service.ExportService", return_value=mock_export_service):
            await process_export_task(task.id, db_session)

        await db_session.refresh(task)
        assert task.status == ExportStatus.FAILED
        assert "PDF生成失败" in task.error_message

    async def test_process_export_progress_updates(
        self, db_session: AsyncSession
    ):
        """测试: 进度更新"""
        from app.api.v1.export_tasks import process_export_task

        user = User(
            email="progress@example.com",
            password_hash="hash",
            username="progress",
            role="user"
        )
        db_session.add(user)
        await db_session.commit()

        resume = Resume(
            user_id=user.id,
            title="进度测试",
            content={},
            style_config={},
            status="draft"
        )
        db_session.add(resume)
        await db_session.commit()

        task = ExportTask(
            user_id=user.id,
            resume_ids=[resume.id],
            export_format=ExportFormat.PDF,
            options={},
            status=ExportStatus.PENDING,
            progress=0.0
        )
        db_session.add(task)
        await db_session.commit()

        mock_export_service = AsyncMock()
        mock_export_service.to_pdf = AsyncMock(return_value=b"pdf")

        with patch("app.services.export.export_service.ExportService", return_value=mock_export_service):
            with patch("os.makedirs"):
                with patch("builtins.open", mock_open()):
                    await process_export_task(task.id, db_session)

        await db_session.refresh(task)
        assert task.progress == 100.0

    async def test_process_export_with_template_html(
        self, db_session: AsyncSession
    ):
        """测试: 带模板 HTML 的导出"""
        from app.api.v1.export_tasks import process_export_task

        user = User(
            email="template@example.com",
            password_hash="hash",
            username="template",
            role="user"
        )
        db_session.add(user)
        await db_session.commit()

        resume = Resume(
            user_id=user.id,
            title="模板测试",
            content={"basic_info": {"name": "用户"}},
            style_config={},
            status="draft"
        )
        db_session.add(resume)
        await db_session.commit()

        # 带模板配置的任务
        task = ExportTask(
            user_id=user.id,
            resume_ids=[resume.id],
            export_format=ExportFormat.HTML,
            options={"template_html": "<div>{{content}}</div>"},
            status=ExportStatus.PENDING,
            progress=0.0
        )
        db_session.add(task)
        await db_session.commit()

        mock_export_service = AsyncMock()
        mock_export_service.to_html = AsyncMock(return_value="<html>结果</html>")

        with patch("app.services.export.export_service.ExportService", return_value=mock_export_service):
            with patch("os.makedirs"):
                with patch("builtins.open", mock_open()):
                    await process_export_task(task.id, db_session)

        await db_session.refresh(task)
        assert task.status == ExportStatus.COMPLETED

    async def test_process_export_creates_directory(
        self, db_session: AsyncSession
    ):
        """测试: 自动创建导出目录"""
        from app.api.v1.export_tasks import process_export_task

        user = User(
            email="mkdir_test@example.com",
            password_hash="hash",
            username="mkdir_test",
            role="user"
        )
        db_session.add(user)
        await db_session.commit()

        resume = Resume(
            user_id=user.id,
            title="目录创建测试",
            content={},
            style_config={},
            status="draft"
        )
        db_session.add(resume)
        await db_session.commit()

        task = ExportTask(
            user_id=user.id,
            resume_ids=[resume.id],
            export_format=ExportFormat.PDF,
            options={},
            status=ExportStatus.PENDING,
            progress=0.0
        )
        db_session.add(task)
        await db_session.commit()

        mock_export_service = AsyncMock()
        mock_export_service.to_pdf = AsyncMock(return_value=b"pdf")

        makedirs_calls = []

        def track_makedirs(path, exist_ok=False):
            makedirs_calls.append(path)

        with patch("app.services.export.export_service.ExportService", return_value=mock_export_service):
            with patch("os.makedirs", side_effect=track_makedirs):
                with patch("builtins.open", mock_open()):
                    await process_export_task(task.id, db_session)

        await db_session.refresh(task)
        assert task.status == ExportStatus.COMPLETED
        assert len(makedirs_calls) > 0
        assert f"data/exports/{user.id}" in makedirs_calls[0]

    async def test_process_export_sets_file_metadata(
        self, db_session: AsyncSession
    ):
        """测试: 设置文件元数据"""
        from app.api.v1.export_tasks import process_export_task

        user = User(
            email="metadata@example.com",
            password_hash="hash",
            username="metadata",
            role="user"
        )
        db_session.add(user)
        await db_session.commit()

        resume = Resume(
            user_id=user.id,
            title="元数据测试",
            content={},
            style_config={},
            status="draft"
        )
        db_session.add(resume)
        await db_session.commit()

        task = ExportTask(
            user_id=user.id,
            resume_ids=[resume.id],
            export_format=ExportFormat.PDF,
            options={},
            status=ExportStatus.PENDING,
            progress=0.0
        )
        db_session.add(task)
        await db_session.commit()

        expected_file_size = 12345
        mock_export_service = AsyncMock()
        mock_export_service.to_pdf = AsyncMock(return_value=b"x" * expected_file_size)

        with patch("app.services.export.export_service.ExportService", return_value=mock_export_service):
            with patch("os.makedirs"):
                with patch("builtins.open", mock_open()):
                    await process_export_task(task.id, db_session)

        await db_session.refresh(task)
        assert task.status == ExportStatus.COMPLETED
        assert task.file_size == expected_file_size
        assert task.file_path is not None
        assert task.completed_at is not None


class TestExportTaskStatusTransitions:
    """导出任务状态转换测试"""

    async def test_pending_to_processing_transition(
        self, db_session: AsyncSession
    ):
        """测试: PENDING -> PROCESSING -> COMPLETED 状态转换"""
        from app.api.v1.export_tasks import process_export_task

        user = User(
            email="transition@example.com",
            password_hash="hash",
            username="transition",
            role="user"
        )
        db_session.add(user)
        await db_session.commit()

        resume = Resume(
            user_id=user.id,
            title="状态转换测试",
            content={},
            style_config={},
            status="draft"
        )
        db_session.add(resume)
        await db_session.commit()

        task = ExportTask(
            user_id=user.id,
            resume_ids=[resume.id],
            export_format=ExportFormat.PDF,
            options={},
            status=ExportStatus.PENDING,
            progress=0.0
        )
        db_session.add(task)
        await db_session.commit()

        # 检查初始状态
        assert task.status == ExportStatus.PENDING
        assert task.progress == 0.0
        assert task.started_at is None

        mock_export_service = AsyncMock()
        mock_export_service.to_pdf = AsyncMock(return_value=b"pdf")

        with patch("app.services.export.export_service.ExportService", return_value=mock_export_service):
            with patch("os.makedirs"):
                with patch("builtins.open", mock_open()):
                    await process_export_task(task.id, db_session)

        await db_session.refresh(task)
        assert task.status == ExportStatus.COMPLETED
        assert task.started_at is not None

    async def test_processing_to_failed_on_error(
        self, db_session: AsyncSession
    ):
        """测试: PROCESSING -> FAILED 错误转换"""
        from app.api.v1.export_tasks import process_export_task

        user = User(
            email="fail_trans@example.com",
            password_hash="hash",
            username="fail_trans",
            role="user"
        )
        db_session.add(user)
        await db_session.commit()

        resume = Resume(
            user_id=user.id,
            title="失败转换测试",
            content={},
            style_config={},
            status="draft"
        )
        db_session.add(resume)
        await db_session.commit()

        task = ExportTask(
            user_id=user.id,
            resume_ids=[resume.id],
            export_format=ExportFormat.PDF,
            options={},
            status=ExportStatus.PENDING,
            progress=0.0
        )
        db_session.add(task)
        await db_session.commit()

        mock_export_service = AsyncMock()
        mock_export_service.to_pdf = AsyncMock(side_effect=RuntimeError("服务错误"))

        with patch("app.services.export.export_service.ExportService", return_value=mock_export_service):
            with patch("os.makedirs"):
                await process_export_task(task.id, db_session)

        await db_session.refresh(task)
        assert task.status == ExportStatus.FAILED
        assert "服务错误" in task.error_message
        assert task.completed_at is not None
