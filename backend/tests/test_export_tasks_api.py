"""
异步导出任务 API 测试
"""
import pytest
from httpx import AsyncClient
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.export_task import ExportFormat, ExportStatus


class TestExportTasksAPI:
    """导出任务 API 测试"""

    async def test_create_export_task(
        self,
        client: AsyncClient,
        auth_headers: dict,
        test_resume: "Resume"
    ):
        """测试创建导出任务"""
        response = await client.post(
            "/api/v1/export-tasks",
            json={
                "resume_ids": [test_resume.id],
                "export_format": "pdf",
                "options": {}
            },
            headers=auth_headers
        )

        assert response.status_code == 200
        data = response.json()
        assert data["code"] == 0
        assert "data" in data
        assert data["data"]["export_format"] == "pdf"
        assert data["data"]["status"] == "pending"
        assert data["data"]["resume_ids"] == [test_resume.id]

    async def test_create_export_task_invalid_format(
        self,
        client: AsyncClient,
        auth_headers: dict,
        test_resume: "Resume"
    ):
        """测试创建导出任务 - 无效格式"""
        response = await client.post(
            "/api/v1/export-tasks",
            json={
                "resume_ids": [test_resume.id],
                "export_format": "invalid",
                "options": {}
            },
            headers=auth_headers
        )

        assert response.status_code == 422  # Validation error

    async def test_create_export_task_unauthorized(
        self,
        client: AsyncClient,
        test_resume: "Resume"
    ):
        """测试创建导出任务 - 未授权"""
        response = await client.post(
            "/api/v1/export-tasks",
            json={
                "resume_ids": [test_resume.id],
                "export_format": "pdf",
                "options": {}
            }
        )

        assert response.status_code == 401

    async def test_list_export_tasks(
        self,
        client: AsyncClient,
        auth_headers: dict,
        test_export_task: "ExportTask"
    ):
        """测试获取导出任务列表"""
        response = await client.get(
            "/api/v1/export-tasks",
            headers=auth_headers
        )

        assert response.status_code == 200
        data = response.json()
        assert data["code"] == 0
        assert "data" in data
        assert data["data"]["total"] >= 1
        assert len(data["data"]["items"]) >= 1

    async def test_list_export_tasks_with_pagination(
        self,
        client: AsyncClient,
        auth_headers: dict
    ):
        """测试获取导出任务列表 - 分页"""
        response = await client.get(
            "/api/v1/export-tasks?page=1&page_size=10",
            headers=auth_headers
        )

        assert response.status_code == 200
        data = response.json()
        assert data["code"] == 0
        assert "data" in data

    async def test_list_export_tasks_with_status_filter(
        self,
        client: AsyncClient,
        auth_headers: dict,
        test_export_task: "ExportTask"
    ):
        """测试获取导出任务列表 - 状态筛选"""
        response = await client.get(
            "/api/v1/export-tasks?status_filter=pending",
            headers=auth_headers
        )

        assert response.status_code == 200
        data = response.json()
        assert data["code"] == 0
        assert "data" in data

    async def test_get_export_task(
        self,
        client: AsyncClient,
        auth_headers: dict,
        test_export_task: "ExportTask"
    ):
        """测试获取导出任务详情"""
        response = await client.get(
            f"/api/v1/export-tasks/{test_export_task.id}",
            headers=auth_headers
        )

        assert response.status_code == 200
        data = response.json()
        assert data["code"] == 0
        assert data["data"]["id"] == test_export_task.id
        assert data["data"]["export_format"] == test_export_task.export_format

    async def test_get_export_task_not_found(
        self,
        client: AsyncClient,
        auth_headers: dict
    ):
        """测试获取导出任务详情 - 不存在"""
        response = await client.get(
            "/api/v1/export-tasks/99999",
            headers=auth_headers
        )

        assert response.status_code == 404

    async def test_get_export_task_unauthorized(
        self,
        client: AsyncClient,
        test_export_task: "ExportTask"
    ):
        """测试获取导出任务详情 - 未授权"""
        response = await client.get(
            f"/api/v1/export-tasks/{test_export_task.id}"
        )

        assert response.status_code == 401

    async def test_delete_export_task(
        self,
        client: AsyncClient,
        auth_headers: dict,
        db_session: AsyncSession,
        test_export_task: "ExportTask"
    ):
        """测试删除导出任务"""
        task_id = test_export_task.id
        response = await client.delete(
            f"/api/v1/export-tasks/{task_id}",
            headers=auth_headers
        )

        assert response.status_code == 200
        data = response.json()
        assert data["code"] == 0
        assert "message" in data["data"]

        # 验证任务已删除
        from sqlalchemy import select
        from app.models.export_task import ExportTask
        result = await db_session.execute(
            select(ExportTask).where(ExportTask.id == task_id)
        )
        assert result.scalar_one_or_none() is None

    async def test_delete_export_task_not_found(
        self,
        client: AsyncClient,
        auth_headers: dict
    ):
        """测试删除导出任务 - 不存在"""
        response = await client.delete(
            "/api/v1/export-tasks/99999",
            headers=auth_headers
        )

        assert response.status_code == 404

    async def test_download_export_file_not_completed(
        self,
        client: AsyncClient,
        auth_headers: dict,
        test_export_task: "ExportTask"
    ):
        """测试下载导出文件 - 任务未完成"""
        response = await client.get(
            f"/api/v1/export-tasks/{test_export_task.id}/download",
            headers=auth_headers
        )

        assert response.status_code == 400
        data = response.json()
        assert "尚未完成" in data["detail"]

    async def test_download_export_file_not_found(
        self,
        client: AsyncClient,
        auth_headers: dict
    ):
        """测试下载导出文件 - 任务不存在"""
        response = await client.get(
            "/api/v1/export-tasks/99999/download",
            headers=auth_headers
        )

        assert response.status_code == 404
