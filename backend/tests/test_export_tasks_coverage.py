"""
提高 export_tasks.py 覆盖率的集成测试
针对 lines: 159-184, 205-216, 234-242, 260-300, 322-342
"""
import pytest
import os
from httpx import AsyncClient
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, and_
from unittest.mock import patch, MagicMock

from app.models.user import User
from app.models.resume import Resume
from app.models.export_task import ExportTask, ExportFormat, ExportStatus
from app.core.security import create_access_token


@pytest.mark.usefixtures("db_session")
class TestExportTasksCoverage:
    """提高 export_tasks.py 覆盖率"""

    async def test_create_export_task_full_flow(
        self, client: AsyncClient, auth_headers, test_user, db_session: AsyncSession
    ):
        """测试: 完整创建导出任务流程 (covers 159-184)"""
        # 创建简历
        resume = Resume(
            user_id=test_user.id,
            title="导出测试简历",
            content={"basic_info": {"name": "测试"}}
        )
        db_session.add(resume)
        await db_session.commit()
        await db_session.refresh(resume)

        response = await client.post(
            "/api/v1/export-tasks",
            json={
                "resume_ids": [resume.id],
                "export_format": "pdf",
                "options": {"style_config": {"theme": "blue"}}
            },
            headers=auth_headers
        )

        assert response.status_code == 200
        data = response.json()
        assert data["data"]["status"] == "pending"
        assert data["data"]["export_format"] == "pdf"

    async def test_create_export_task_partial_resume_access(
        self, client: AsyncClient, auth_headers, test_user, db_session: AsyncSession
    ):
        """测试: 部分简历无权访问 (covers 161-165)"""
        from app.models.user import UserRole

        # 创建自己的简历
        own_resume = Resume(
            user_id=test_user.id,
            title="我的简历",
            content={}
        )
        db_session.add(own_resume)

        # 创建其他用户
        other_user = User(
            email="other@example.com",
            password_hash="hash",
            role=UserRole.USER
        )
        db_session.add(other_user)
        await db_session.flush()

        # 创建其他用户的简历
        other_resume = Resume(
            user_id=other_user.id,
            title="他人简历",
            content={}
        )
        db_session.add(other_resume)
        await db_session.commit()
        await db_session.refresh(own_resume)
        await db_session.refresh(other_resume)

        response = await client.post(
            "/api/v1/export-tasks",
            json={
                "resume_ids": [own_resume.id, other_resume.id],
                "export_format": "pdf",
                "options": {}
            },
            headers=auth_headers
        )

        assert response.status_code == 404

    async def test_list_export_tasks_with_filters(
        self, client: AsyncClient, auth_headers, test_user, db_session: AsyncSession
    ):
        """测试: 带筛选的导出任务列表 (covers 196-216)"""
        # 创建多个导出任务
        for status, fmt in [(ExportStatus.PENDING, ExportFormat.PDF),
                            (ExportStatus.COMPLETED, ExportFormat.DOCX)]:
            task = ExportTask(
                user_id=test_user.id,
                resume_ids=[1],
                export_format=fmt,
                options={},
                status=status,
                progress=0.0
            )
            db_session.add(task)
        await db_session.commit()

        # 测试状态筛选
        response = await client.get(
            "/api/v1/export-tasks?status=pending",
            headers=auth_headers
        )

        assert response.status_code == 200
        data = response.json()
        assert data["data"]["total"] >= 1

        # 测试分页
        response = await client.get(
            "/api/v1/export-tasks?page=1&page_size=10",
            headers=auth_headers
        )

        assert response.status_code == 200

    async def test_get_export_task_success(
        self, client: AsyncClient, auth_headers, test_user, db_session: AsyncSession
    ):
        """测试: 获取导出任务详情 (covers 226-242)"""
        task = ExportTask(
            user_id=test_user.id,
            resume_ids=[1],
            export_format=ExportFormat.PDF,
            options={},
            status=ExportStatus.PENDING,
            progress=0.0
        )
        db_session.add(task)
        await db_session.commit()
        await db_session.refresh(task)

        response = await client.get(
            f"/api/v1/export-tasks/{task.id}",
            headers=auth_headers
        )

        assert response.status_code == 200
        data = response.json()
        assert data["data"]["id"] == task.id

    async def test_get_export_task_not_found(
        self, client: AsyncClient, auth_headers
    ):
        """测试: 获取不存在的任务"""
        response = await client.get(
            "/api/v1/export-tasks/99999",
            headers=auth_headers
        )

        assert response.status_code == 404

    async def test_get_export_task_unauthorized(
        self, client: AsyncClient, auth_headers, db_session: AsyncSession
    ):
        """测试: 获取其他用户的任务"""
        from app.models.user import UserRole

        # 创建其他用户
        other_user = User(
            email="other2@example.com",
            password_hash="hash"
        )
        db_session.add(other_user)
        await db_session.flush()

        task = ExportTask(
            user_id=other_user.id,
            resume_ids=[1],
            export_format=ExportFormat.PDF,
            options={},
            status=ExportStatus.PENDING,
            progress=0.0
        )
        db_session.add(task)
        await db_session.commit()
        await db_session.refresh(task)

        response = await client.get(
            f"/api/v1/export-tasks/{task.id}",
            headers=auth_headers
        )

        assert response.status_code == 404

    async def test_download_export_file_not_completed(
        self, client: AsyncClient, auth_headers, test_user, db_session: AsyncSession
    ):
        """测试: 下载未完成的任务 (covers 268-272)"""
        task = ExportTask(
            user_id=test_user.id,
            resume_ids=[1],
            export_format=ExportFormat.PDF,
            options={},
            status=ExportStatus.PROCESSING,
            progress=50.0
        )
        db_session.add(task)
        await db_session.commit()
        await db_session.refresh(task)

        response = await client.get(
            f"/api/v1/export-tasks/{task.id}/download",
            headers=auth_headers
        )

        assert response.status_code == 400

    async def test_download_export_file_not_found(
        self, client: AsyncClient, auth_headers, test_user, db_session: AsyncSession
    ):
        """测试: 下载不存在的文件 (covers 274-278)"""
        task = ExportTask(
            user_id=test_user.id,
            resume_ids=[1],
            export_format=ExportFormat.PDF,
            options={},
            status=ExportStatus.COMPLETED,
            progress=100.0,
            file_path=None  # 没有文件路径
        )
        db_session.add(task)
        await db_session.commit()
        await db_session.refresh(task)

        response = await client.get(
            f"/api/v1/export-tasks/{task.id}/download",
            headers=auth_headers
        )

        assert response.status_code == 404

    async def test_download_export_file_deleted(
        self, client: AsyncClient, auth_headers, test_user, db_session: AsyncSession
    ):
        """测试: 文件已被删除 (covers 283-287)"""
        task = ExportTask(
            user_id=test_user.id,
            resume_ids=[1],
            export_format=ExportFormat.PDF,
            options={},
            status=ExportStatus.COMPLETED,
            progress=100.0,
            file_path="/nonexistent/file.pdf"
        )
        db_session.add(task)
        await db_session.commit()
        await db_session.refresh(task)

        response = await client.get(
            f"/api/v1/export-tasks/{task.id}/download",
            headers=auth_headers
        )

        assert response.status_code == 404

    async def test_download_export_file_success_pdf(
        self, client: AsyncClient, auth_headers, test_user, db_session: AsyncSession
    ):
        """测试: 成功下载 PDF (covers 289-304)"""
        # 创建临时文件
        export_dir = "data/exports/1"
        os.makedirs(export_dir, exist_ok=True)
        test_file = f"{export_dir}/test_export.pdf"
        with open(test_file, "wb") as f:
            f.write(b"PDF content")

        task = ExportTask(
            user_id=test_user.id,
            resume_ids=[1],
            export_format=ExportFormat.PDF,
            options={},
            status=ExportStatus.COMPLETED,
            progress=100.0,
            file_path=test_file
        )
        db_session.add(task)
        await db_session.commit()
        await db_session.refresh(task)

        response = await client.get(
            f"/api/v1/export-tasks/{task.id}/download",
            headers=auth_headers
        )

        assert response.status_code == 200
        # 清理
        os.remove(test_file)

    async def test_download_export_file_success_docx(
        self, client: AsyncClient, auth_headers, test_user, db_session: AsyncSession
    ):
        """测试: 成功下载 DOCX (不同 MIME 类型)"""
        export_dir = "data/exports/1"
        os.makedirs(export_dir, exist_ok=True)
        test_file = f"{export_dir}/test_export.docx"
        with open(test_file, "wb") as f:
            f.write(b"DOCX content")

        task = ExportTask(
            user_id=test_user.id,
            resume_ids=[1],
            export_format=ExportFormat.DOCX,
            options={},
            status=ExportStatus.COMPLETED,
            progress=100.0,
            file_path=test_file
        )
        db_session.add(task)
        await db_session.commit()
        await db_session.refresh(task)

        response = await client.get(
            f"/api/v1/export-tasks/{task.id}/download",
            headers=auth_headers
        )

        assert response.status_code == 200
        os.remove(test_file)

    async def test_download_export_file_success_html(
        self, client: AsyncClient, auth_headers, test_user, db_session: AsyncSession
    ):
        """测试: 成功下载 HTML"""
        export_dir = "data/exports/1"
        os.makedirs(export_dir, exist_ok=True)
        test_file = f"{export_dir}/test_export.html"
        with open(test_file, "w") as f:
            f.write("<html>content</html>")

        task = ExportTask(
            user_id=test_user.id,
            resume_ids=[1],
            export_format=ExportFormat.HTML,
            options={},
            status=ExportStatus.COMPLETED,
            progress=100.0,
            file_path=test_file
        )
        db_session.add(task)
        await db_session.commit()
        await db_session.refresh(task)

        response = await client.get(
            f"/api/v1/export-tasks/{task.id}/download",
            headers=auth_headers
        )

        assert response.status_code == 200
        os.remove(test_file)

    async def test_delete_export_task_success(
        self, client: AsyncClient, auth_headers, test_user, db_session: AsyncSession
    ):
        """测试: 成功删除导出任务 (covers 322-342)"""
        # 创建测试文件
        export_dir = "data/exports/1"
        os.makedirs(export_dir, exist_ok=True)
        test_file = f"{export_dir}/test_delete.pdf"
        with open(test_file, "wb") as f:
            f.write(b"content")

        task = ExportTask(
            user_id=test_user.id,
            resume_ids=[1],
            export_format=ExportFormat.PDF,
            options={},
            status=ExportStatus.COMPLETED,
            progress=100.0,
            file_path=test_file
        )
        db_session.add(task)
        await db_session.commit()
        await db_session.refresh(task)

        response = await client.delete(
            f"/api/v1/export-tasks/{task.id}",
            headers=auth_headers
        )

        assert response.status_code == 200

        # 验证任务已删除
        result = await db_session.execute(
            select(ExportTask).where(ExportTask.id == task.id)
        )
        assert result.scalar_one_or_none() is None

        # 验证文件已删除
        assert not os.path.exists(test_file)

    async def test_delete_export_task_not_found(
        self, client: AsyncClient, auth_headers
    ):
        """测试: 删除不存在的任务"""
        response = await client.delete(
            "/api/v1/export-tasks/99999",
            headers=auth_headers
        )

        assert response.status_code == 404

    async def test_delete_export_task_with_file_delete_failure(
        self, client: AsyncClient, auth_headers, test_user, db_session: AsyncSession
    ):
        """测试: 文件删除失败但数据库记录删除成功 (covers 330-336)"""
        task = ExportTask(
            user_id=test_user.id,
            resume_ids=[1],
            export_format=ExportFormat.PDF,
            options={},
            status=ExportStatus.COMPLETED,
            progress=100.0,
            file_path="/nonexistent/file.pdf"  # 不存在的文件
        )
        db_session.add(task)
        await db_session.commit()
        await db_session.refresh(task)

        response = await client.delete(
            f"/api/v1/export-tasks/{task.id}",
            headers=auth_headers
        )

        # 即使文件删除失败，数据库记录应该被删除
        assert response.status_code == 200

        result = await db_session.execute(
            select(ExportTask).where(ExportTask.id == task.id)
        )
        assert result.scalar_one_or_none() is None
