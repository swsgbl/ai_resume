"""
简历 CRUD 测试
"""
import pytest
from httpx import AsyncClient
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from app.models.resume import Resume
from app.models.user import User
from app.core.security import get_password_hash
from loguru import logger


@pytest.mark.asyncio
class TestResumeCRUD:
    """简历 CRUD 测试"""

    async def create_test_user(self, db: AsyncSession) -> User:
        """创建测试用户"""
        user = User(
            email="test_resume@example.com",
            username="resume_tester",
            hashed_password=get_password_hash("Test123!")
        )
        db.add(user)
        await db.commit()
        await db.refresh(user)
        return user

    async def test_create_resume(self, client: AsyncClient, db: AsyncSession, auth_headers: dict):
        """测试创建简历"""
        # 创建测试用户
        user = await self.create_test_user(db)
        auth_headers["Authorization"] = f"Bearer test_token_{user.id}"

        resume_data = {
            "title": "测试简历",
            "description": "这是一个测试简历",
            "content": {
                "basic_info": {
                    "name": "测试用户",
                    "email": "test@example.com",
                    "phone": "13800138000",
                    "title": "软件工程师"
                },
                "education": [],
                "work_experience": [],
                "projects": [],
                "skills": []
            }
        }

        response = await client.post(
            "/api/v1/resumes/",
            json=resume_data,
            headers=auth_headers
        )

        logger.info(f"创建简历响应: {response.status_code}")

        assert response.status_code == 200, f"创建简历失败: {response.text}"
        data = response.json()
        assert data["code"] == 200
        assert data["data"]["title"] == "测试简历"

    async def test_get_resume(self, client: AsyncClient, db: AsyncSession, auth_headers: dict):
        """测试获取简历"""
        # 创建测试用户和简历
        user = await self.create_test_user(db)
        resume = Resume(
            user_id=user.id,
            title="获取测试简历",
            content={"basic_info": {"name": "测试用户"}}
        )
        db.add(resume)
        await db.commit()
        await db.refresh(resume)

        auth_headers["Authorization"] = f"Bearer test_token_{user.id}"

        response = await client.get(
            f"/api/v1/resumes/{resume.id}",
            headers=auth_headers
        )

        assert response.status_code == 200, f"获取简历失败: {response.text}"
        data = response.json()
        assert data["data"]["title"] == "获取测试简历"

    async def test_update_resume(self, client: AsyncClient, db: AsyncSession, auth_headers: dict):
        """测试更新简历"""
        # 创建测试用户和简历
        user = await self.create_test_user(db)
        resume = Resume(
            user_id=user.id,
            title="更新前",
            content={"basic_info": {"name": "测试用户"}}
        )
        db.add(resume)
        await db.commit()
        await db.refresh(resume)

        auth_headers["Authorization"] = f"Bearer test_token_{user.id}"

        update_data = {
            "title": "更新后",
            "content": {
                "basic_info": {"name": "已更新"}
            }
        }

        response = await client.put(
            f"/api/v1/resumes/{resume.id}",
            json=update_data,
            headers=auth_headers
        )

        assert response.status_code == 200, f"更新简历失败: {response.text}"
        data = response.json()
        assert data["data"]["title"] == "更新后"

    async def test_delete_resume(self, client: AsyncClient, db: AsyncSession, auth_headers: dict):
        """测试删除简历"""
        # 创建测试用户和简历
        user = await self.create_test_user(db)
        resume = Resume(
            user_id=user.id,
            title="待删除",
            content={"basic_info": {"name": "测试用户"}}
        )
        db.add(resume)
        await db.commit()
        await db.refresh(resume)
        resume_id = resume.id

        auth_headers["Authorization"] = f"Bearer test_token_{user.id}"

        # 删除简历
        response = await client.delete(
            f"/api/v1/resumes/{resume_id}",
            headers=auth_headers
        )

        assert response.status_code == 200, f"删除简历失败: {response.text}"

        # 验证删除
        query = select(Resume).where(Resume.id == resume_id)
        result = await db.execute(query)
        deleted_resume = result.scalar_one_or_none()
        assert deleted_resume is None, "简历应该被删除"

    async def test_list_resumes(self, client: AsyncClient, db: AsyncSession, auth_headers: dict):
        """测试获取简历列表"""
        # 创建测试用户和多个简历
        user = await self.create_test_user(db)

        for i in range(3):
            resume = Resume(
                user_id=user.id,
                title=f"简历 {i+1}",
                content={"basic_info": {"name": f"用户{i+1}"}}
            )
            db.add(resume)

        await db.commit()

        auth_headers["Authorization"] = f"Bearer test_token_{user.id}"

        response = await client.get(
            "/api/v1/resumes/",
            headers=auth_headers
        )

        assert response.status_code == 200, f"获取简历列表失败: {response.text}"
        data = response.json()
        assert len(data["data"]) == 3

    async def test_unauthorized_access(self, client: AsyncClient, db: AsyncSession):
        """测试未授权访问"""
        # 创建简历
        user = await self.create_test_user(db)
        resume = Resume(
            user_id=user.id,
            title="私有简历",
            content={"basic_info": {"name": "测试用户"}}
        )
        db.add(resume)
        await db.commit()
        await db.refresh(resume)

        # 尝试不使用 token 访问
        response = await client.get(f"/api/v1/resumes/{resume.id}")

        assert response.status_code == 401, "应该返回未授权"


@pytest.fixture
async def auth_headers():
    """返回认证头（简化版，生产环境应使用真实 JWT）"""
    return {}


@pytest.fixture
async def client():
    """返回测试客户端"""
    import os
    os.environ['NO_PROXY'] = '127.0.0.1,localhost'
    os.environ['no_proxy'] = '127.0.0.1,localhost'

    from app.main import app
    from app.core.database import init_db, close_db

    # 初始化数据库
    await init_db()

    async with AsyncClient(app=app, base_url="http://127.0.0.1:8000") as ac:
        yield ac

    # 关闭数据库
    await close_db()


@pytest.fixture
async def db():
    """返回数据库会话"""
    from app.core.database import get_db

    async for session in get_db():
        yield session
        break


if __name__ == "__main__":
    pytest.main([__file__, "-v", "--asyncio-mode=auto"])
