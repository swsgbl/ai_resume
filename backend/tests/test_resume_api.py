"""
简历 API 集成测试
"""
import pytest
from httpx import AsyncClient


class TestResumeList:
    """简历列表测试"""

    async def test_list_resumes_empty(
        self, client: AsyncClient, auth_headers
    ):
        """测试空简历列表"""
        response = await client.get("/api/v1/resumes", headers=auth_headers)
        assert response.status_code == 200
        data = response.json()
        assert data["code"] == 0
        assert data["data"] == []
        assert data["total"] == 0

    async def test_list_resumes_with_data(
        self, client: AsyncClient, auth_headers, test_resume
    ):
        """测试有数据的简历列表"""
        response = await client.get("/api/v1/resumes", headers=auth_headers)
        assert response.status_code == 200
        data = response.json()
        assert data["code"] == 0
        assert len(data["data"]) == 1
        assert data["total"] == 1
        assert data["data"][0]["id"] == test_resume.id

    async def test_list_resumes_pagination(
        self, client: AsyncClient, auth_headers, test_user, db_session
    ):
        """测试分页"""
        from app.models.resume import Resume

        # 创建多个简历
        for i in range(15):
            resume = Resume(
                user_id=test_user.id,
                title=f"简历 {i}",
                content={},
                style_config={}
            )
            db_session.add(resume)
        await db_session.commit()

        # 第一页
        response = await client.get(
            "/api/v1/resumes?page=1&page_size=10",
            headers=auth_headers
        )
        assert response.status_code == 200
        data = response.json()
        assert len(data["data"]) == 10
        assert data["total"] >= 15

    async def test_list_resumes_unauthorized(self, client: AsyncClient):
        """测试未授权访问"""
        response = await client.get("/api/v1/resumes")
        assert response.status_code == 401


class TestResumeCreate:
    """创建简历测试"""

    async def test_create_resume_success(
        self, client: AsyncClient, auth_headers
    ):
        """测试成功创建简历"""
        response = await client.post(
            "/api/v1/resumes",
            headers=auth_headers,
            json={
                "title": "软件工程师简历",
                "description": "申请后端开发岗位",
                "template_id": None,
                "content": {
                    "basic_info": {
                        "name": "李四",
                        "email": "lisi@example.com",
                        "phone": "13900139000"
                    }
                },
                "style_config": {
                    "theme": "blue",
                    "font": "default"
                }
            }
        )
        assert response.status_code == 200
        data = response.json()
        assert data["code"] == 0
        assert data["data"]["title"] == "软件工程师简历"
        assert data["data"]["template_id"] is None

    async def test_create_resume_minimal(
        self, client: AsyncClient, auth_headers
    ):
        """测试最小简历创建"""
        response = await client.post(
            "/api/v1/resumes",
            headers=auth_headers,
            json={"title": "简单简历"}
        )
        assert response.status_code == 200
        data = response.json()
        assert data["code"] == 0

    async def test_create_resume_unauthorized(self, client: AsyncClient):
        """测试未授权创建"""
        response = await client.post(
            "/api/v1/resumes",
            json={"title": "未授权简历"}
        )
        assert response.status_code == 401


class TestResumeGet:
    """获取简历详情测试"""

    async def test_get_resume_success(
        self, client: AsyncClient, auth_headers, test_resume
    ):
        """测试成功获取简历"""
        response = await client.get(
            f"/api/v1/resumes/{test_resume.id}",
            headers=auth_headers
        )
        assert response.status_code == 200
        data = response.json()
        assert data["code"] == 0
        assert data["data"]["id"] == test_resume.id
        assert data["data"]["title"] == test_resume.title

    async def test_get_resume_not_found(
        self, client: AsyncClient, auth_headers
    ):
        """测试获取不存在的简历"""
        response = await client.get(
            "/api/v1/resumes/99999",
            headers=auth_headers
        )
        assert response.status_code == 404

    async def test_get_resume_unauthorized(
        self, client: AsyncClient, test_resume
    ):
        """测试未授权获取"""
        response = await client.get(f"/api/v1/resumes/{test_resume.id}")
        assert response.status_code == 401


class TestResumeUpdate:
    """更新简历测试"""

    async def test_update_resume_success(
        self, client: AsyncClient, auth_headers, test_resume
    ):
        """测试成功更新简历"""
        response = await client.put(
            f"/api/v1/resumes/{test_resume.id}",
            headers=auth_headers,
            json={
                "title": "更新后的简历",
                "description": "更新描述"
            }
        )
        assert response.status_code == 200
        data = response.json()
        assert data["code"] == 0
        assert data["data"]["title"] == "更新后的简历"
        assert data["data"]["version"] == 2  # 版本号从1递增到2

    async def test_update_resume_not_found(
        self, client: AsyncClient, auth_headers
    ):
        """测试更新不存在的简历"""
        response = await client.put(
            "/api/v1/resumes/99999",
            headers=auth_headers,
            json={"title": "更新"}
        )
        assert response.status_code == 404


class TestResumeDelete:
    """删除简历测试"""

    async def test_delete_resume_success(
        self, client: AsyncClient, auth_headers, test_resume
    ):
        """测试成功删除简历"""
        response = await client.delete(
            f"/api/v1/resumes/{test_resume.id}",
            headers=auth_headers
        )
        assert response.status_code == 200
        data = response.json()
        assert data["code"] == 0

        # 验证已删除
        response = await client.get(
            f"/api/v1/resumes/{test_resume.id}",
            headers=auth_headers
        )
        assert response.status_code == 404


class TestResumeVersions:
    """简历版本测试"""

    async def test_get_resume_versions(
        self, client: AsyncClient, auth_headers, test_resume, db_session
    ):
        """测试获取版本历史"""
        from app.models.resume import ResumeVersion

        # 创建版本记录
        version = ResumeVersion(
            resume_id=test_resume.id,
            version_number=1,
            content={"test": "old content"},
            style_config={},
            change_note="初始版本"
        )
        db_session.add(version)
        await db_session.commit()

        response = await client.get(
            f"/api/v1/resumes/{test_resume.id}/versions",
            headers=auth_headers
        )
        assert response.status_code == 200
        data = response.json()
        assert data["code"] == 0
        assert len(data["data"]) >= 1

    async def test_rollback_resume(
        self, client: AsyncClient, auth_headers, test_resume, db_session
    ):
        """测试回滚版本"""
        from app.models.resume import ResumeVersion

        # 创建版本记录
        old_content = {"old": "content"}
        version = ResumeVersion(
            resume_id=test_resume.id,
            version_number=1,
            content=old_content,
            style_config={},
            change_note="回滚测试版本"
        )
        db_session.add(version)
        await db_session.commit()

        # 执行回滚
        response = await client.post(
            f"/api/v1/resumes/{test_resume.id}/rollback/{version.id}",
            headers=auth_headers
        )
        assert response.status_code == 200
        data = response.json()
        assert data["code"] == 0
