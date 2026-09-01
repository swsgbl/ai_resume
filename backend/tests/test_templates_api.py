"""
Templates API 完整测试
覆盖所有端点和边界情况
"""
import pytest
from httpx import AsyncClient
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select

from app.models.user import User
from app.models.template import Template, Favorite


class TestTemplatesListAPI:
    """模板列表 API 测试"""

    async def test_list_templates_all(
        self, client: AsyncClient, db_session
    ):
        """测试: 获取所有模板"""
        # 创建一些模板
        for i in range(5):
            template = Template(
                name=f"模板{i}",
                category="技术",
                layout="single",
                is_active=True,
                is_premium=False,
                use_count=i * 10
            )
            db_session.add(template)
        await db_session.commit()

        response = await client.get("/api/v1/templates")

        assert response.status_code == 200
        data = response.json()
        assert data["code"] == 0
        assert len(data["data"]) >= 5

    async def test_list_templates_with_category_filter(
        self, client: AsyncClient, db_session
    ):
        """测试: 按分类筛选"""
        template1 = Template(
            name="技术模板",
            category="技术",
            layout="single",
            is_active=True,
            use_count=10
        )
        template2 = Template(
            name="金融模板",
            category="金融",
            layout="single",
            is_active=True,
            use_count=5
        )
        db_session.add(template1)
        db_session.add(template2)
        await db_session.commit()

        response = await client.get("/api/v1/templates?category=技术")

        assert response.status_code == 200
        data = response.json()
        for t in data["data"]:
            assert t["category"] == "技术"

    async def test_list_templates_with_sub_category_filter(
        self, client: AsyncClient, db_session
    ):
        """测试: 按子分类筛选"""
        template = Template(
            name="后端模板",
            category="技术",
            sub_category="后端",
            layout="single",
            is_active=True,
            use_count=10
        )
        db_session.add(template)
        await db_session.commit()

        response = await client.get("/api/v1/templates?sub_category=后端")

        assert response.status_code == 200
        data = response.json()
        for t in data["data"]:
            assert t["sub_category"] == "后端"

    async def test_list_templates_with_level_filter(
        self, client: AsyncClient, db_session
    ):
        """测试: 按职级筛选"""
        template = Template(
            name="高级模板",
            category="技术",
            level="senior",
            layout="single",
            is_active=True,
            use_count=10
        )
        db_session.add(template)
        await db_session.commit()

        response = await client.get("/api/v1/templates?level=senior")

        assert response.status_code == 200

    async def test_list_templates_premium_filter(
        self, client: AsyncClient, db_session
    ):
        """测试: 按付费类型筛选"""
        free = Template(
            name="免费模板",
            category="test",
            is_premium=False,
            layout="single",
            is_active=True,
            use_count=10
        )
        premium = Template(
            name="付费模板",
            category="test",
            is_premium=True,
            layout="single",
            is_active=True,
            use_count=5
        )
        db_session.add(free)
        db_session.add(premium)
        await db_session.commit()

        response = await client.get("/api/v1/templates?is_premium=true")

        assert response.status_code == 200
        data = response.json()
        for t in data["data"]:
            assert t["is_premium"] is True

    async def test_list_templates_pagination(
        self, client: AsyncClient, db_session
    ):
        """测试: 分页查询"""
        for i in range(25):
            template = Template(
                name=f"分页测试{i}",
                category="test",
                layout="single",
                is_active=True,
                use_count=i
            )
            db_session.add(template)
        await db_session.commit()

        response = await client.get("/api/v1/templates?page=1&page_size=10")

        assert response.status_code == 200
        data = response.json()
        assert len(data["data"]) == 10
        assert data["page"] == 1
        assert data["page_size"] == 10

    async def test_list_templates_ordering(
        self, client: AsyncClient, db_session
    ):
        """测试: 按使用次数排序"""
        t1 = Template(
            name="热门模板",
            category="test",
            layout="single",
            is_active=True,
            use_count=100
        )
        t2 = Template(
            name="冷门模板",
            category="test",
            layout="single",
            is_active=True,
            use_count=5
        )
        db_session.add(t1)
        db_session.add(t2)
        await db_session.commit()

        response = await client.get("/api/v1/templates?page_size=10")

        assert response.status_code == 200
        data = response.json()
        # 第一个应该是使用次数最多的
        assert data["data"][0]["use_count"] >= data["data"][1]["use_count"]

    async def test_list_templates_empty(
        self, client: AsyncClient
    ):
        """测试: 空模板列表"""
        response = await client.get("/api/v1/templates")

        assert response.status_code == 200
        data = response.json()
        assert data["code"] == 0


class TestGetTemplateAPI:
    """获取模板详情 API 测试"""

    async def test_get_template_success(
        self, client: AsyncClient, db_session
    ):
        """测试: 成功获取模板详情"""
        template = Template(
            name="测试模板",
            category="技术",
            layout="single",
            is_active=True,
            use_count=10
        )
        db_session.add(template)
        await db_session.commit()

        response = await client.get(f"/api/v1/templates/{template.id}")

        assert response.status_code == 200
        data = response.json()
        assert data["code"] == 0
        assert data["data"]["id"] == template.id

    async def test_get_template_not_found(
        self, client: AsyncClient
    ):
        """测试: 模板不存在"""
        response = await client.get("/api/v1/templates/99999")

        assert response.status_code == 404

    async def test_get_template_inactive(
        self, client: AsyncClient, db_session
    ):
        """测试: 获取非活跃模板"""
        template = Template(
            name="非活跃模板",
            category="test",
            layout="single",
            is_active=False,  # 非活跃
            use_count=0
        )
        db_session.add(template)
        await db_session.commit()

        response = await client.get(f"/api/v1/templates/{template.id}")

        # 非活跃模板应该返回 404
        assert response.status_code == 404


class TestUseTemplateAPI:
    """使用模板 API 测试"""

    async def test_use_free_template_success(
        self, client: AsyncClient, auth_headers, db_session
    ):
        """测试: 使用免费模板"""
        template = Template(
            name="免费模板",
            category="test",
            is_premium=False,
            layout="single",
            is_active=True,
            use_count=10
        )
        db_session.add(template)
        await db_session.commit()

        response = await client.post(
            f"/api/v1/templates/{template.id}/use",
            headers=auth_headers
        )

        assert response.status_code == 200
        data = response.json()
        assert "使用成功" in data["message"]

    async def test_use_premium_template_as_free_user(
        self, client: AsyncClient, auth_headers, db_session
    ):
        """测试: 普通用户使用付费模板"""
        template = Template(
            name="付费模板",
            category="test",
            is_premium=True,
            layout="single",
            is_active=True,
            use_count=10
        )
        db_session.add(template)
        await db_session.commit()

        response = await client.post(
            f"/api/v1/templates/{template.id}/use",
            headers=auth_headers
        )

        assert response.status_code == 403

    async def test_use_template_not_found(
        self, client: AsyncClient, auth_headers
    ):
        """测试: 使用不存在的模板"""
        response = await client.post(
            "/api/v1/templates/99999/use",
            headers=auth_headers
        )

        assert response.status_code == 404

    async def test_use_template_increments_count(
        self, client: AsyncClient, auth_headers, test_user, db_session
    ):
        """测试: 使用模板增加计数"""
        template = Template(
            name="计数测试",
            category="test",
            is_premium=False,
            layout="single",
            is_active=True,
            use_count=100
        )
        db_session.add(template)
        await db_session.commit()

        initial_count = template.use_count

        await client.post(
            f"/api/v1/templates/{template.id}/use",
            headers=auth_headers
        )

        # 刷新并验证计数增加
        await db_session.refresh(template)
        assert template.use_count == initial_count + 1

    async def test_use_template_unauthorized(
        self, client: AsyncClient, db_session
    ):
        """测试: 未授权使用模板"""
        template = Template(
            name="测试",
            category="test",
            is_premium=False,
            layout="single",
            is_active=True,
            use_count=0
        )
        db_session.add(template)
        await db_session.commit()

        response = await client.post(f"/api/v1/templates/{template.id}/use")

        assert response.status_code == 401


class TestFavoriteTemplateAPI:
    """收藏模板 API 测试"""

    async def test_favorite_template_success(
        self, client: AsyncClient, auth_headers, db_session
    ):
        """测试: 成功收藏模板"""
        template = Template(
            name="待收藏",
            category="test",
            layout="single",
            is_active=True,
            use_count=10
        )
        db_session.add(template)
        await db_session.commit()

        response = await client.post(
            f"/api/v1/templates/{template.id}/favorite",
            headers=auth_headers
        )

        assert response.status_code == 200
        data = response.json()
        assert "收藏成功" in data["message"]

    async def test_favorite_template_not_found(
        self, client: AsyncClient, auth_headers
    ):
        """测试: 收藏不存在的模板"""
        response = await client.post(
            "/api/v1/templates/99999/favorite",
            headers=auth_headers
        )

        assert response.status_code == 404

    async def test_favorite_inactive_template(
        self, client: AsyncClient, auth_headers, db_session
    ):
        """测试: 收藏非活跃模板"""
        template = Template(
            name="非活跃",
            category="test",
            layout="single",
            is_active=False,
            use_count=0
        )
        db_session.add(template)
        await db_session.commit()

        response = await client.post(
            f"/api/v1/templates/{template.id}/favorite",
            headers=auth_headers
        )

        assert response.status_code == 404

    async def test_favorite_already_favorited(
        self, client: AsyncClient, auth_headers, db_session
    ):
        """测试: 重复收藏模板"""
        template = Template(
            name="重复收藏",
            category="test",
            layout="single",
            is_active=True,
            use_count=10
        )
        db_session.add(template)
        await db_session.commit()

        # 第一次收藏
        await client.post(
            f"/api/v1/templates/{template.id}/favorite",
            headers=auth_headers
        )

        # 第二次收藏
        response = await client.post(
            f"/api/v1/templates/{template.id}/favorite",
            headers=auth_headers
        )

        assert response.status_code == 400
        data = response.json()
        assert "已收藏" in data["detail"]

    async def test_favorite_unauthorized(
        self, client: AsyncClient, db_session
    ):
        """测试: 未授权收藏"""
        template = Template(
            name="测试",
            category="test",
            layout="single",
            is_active=True,
            use_count=0
        )
        db_session.add(template)
        await db_session.commit()

        response = await client.post(f"/api/v1/templates/{template.id}/favorite")

        assert response.status_code == 401


class TestUnfavoriteTemplateAPI:
    """取消收藏模板 API 测试"""

    async def test_unfavorite_template_success(
        self, client: AsyncClient, auth_headers, db_session
    ):
        """测试: 成功取消收藏"""
        template = Template(
            name="取消收藏",
            category="test",
            layout="single",
            is_active=True,
            use_count=10
        )
        db_session.add(template)
        await db_session.commit()

        # 先收藏
        await client.post(
            f"/api/v1/templates/{template.id}/favorite",
            headers=auth_headers
        )

        # 取消收藏
        response = await client.delete(
            f"/api/v1/templates/{template.id}/favorite",
            headers=auth_headers
        )

        assert response.status_code == 200
        data = response.json()
        assert "取消收藏成功" in data["message"]

    async def test_unfavorite_not_favorited(
        self, client: AsyncClient, auth_headers
    ):
        """测试: 取消收藏未收藏的模板"""
        response = await client.delete(
            "/api/v1/templates/99999/favorite",
            headers=auth_headers
        )

        assert response.status_code == 404

    async def test_unfavorite_unauthorized(
        self, client: AsyncClient, db_session
    ):
        """测试: 未授权取消收藏"""
        template = Template(
            name="测试",
            category="test",
            layout="single",
            is_active=True,
            use_count=0
        )
        db_session.add(template)
        await db_session.commit()

        response = await client.delete(f"/api/v1/templates/{template.id}/favorite")

        assert response.status_code == 401


class TestGetFavoriteTemplatesAPI:
    """获取收藏模板列表 API 测试"""

    async def test_get_favorite_templates_success(
        self, client: AsyncClient, auth_headers, db_session
    ):
        """测试: 成功获取收藏列表"""
        template = Template(
            name="收藏测试",
            category="test",
            layout="single",
            is_active=True,
            use_count=10
        )
        db_session.add(template)
        await db_session.commit()

        # 收藏模板
        await client.post(
            f"/api/v1/templates/{template.id}/favorite",
            headers=auth_headers
        )

        # 获取收藏列表
        response = await client.get(
            "/api/v1/templates/favorites/list",
            headers=auth_headers
        )

        assert response.status_code == 200
        data = response.json()
        assert data["code"] == 0
        assert len(data["data"]) >= 1

    async def test_get_favorite_templates_empty(
        self, client: AsyncClient, auth_headers
    ):
        """测试: 空收藏列表"""
        response = await client.get(
            "/api/v1/templates/favorites/list",
            headers=auth_headers
        )

        assert response.status_code == 200
        data = response.json()
        assert data["data"] == []

    async def test_get_favorite_templates_excludes_inactive(
        self, client: AsyncClient, auth_headers, db_session
    ):
        """测试: 收藏列表排除非活跃模板"""
        template = Template(
            name="非活跃收藏",
            category="test",
            layout="single",
            is_active=True,
            use_count=10
        )
        db_session.add(template)
        await db_session.commit()

        # 收藏模板
        await client.post(
            f"/api/v1/templates/{template.id}/favorite",
            headers=auth_headers
        )

        # 设为非活跃
        template.is_active = False
        await db_session.commit()

        # 获取收藏列表
        response = await client.get(
            "/api/v1/templates/favorites/list",
            headers=auth_headers
        )

        assert response.status_code == 200
        data = response.json()
        # 应该不包含非活跃模板
        for t in data["data"]:
            assert t["id"] != template.id

    async def test_get_favorites_unauthorized(
        self, client: AsyncClient
    ):
        """测试: 未授权获取收藏列表"""
        response = await client.get("/api/v1/templates/favorites/list")

        assert response.status_code == 401


class TestGetCategoriesAPI:
    """获取分类 API 测试"""

    async def test_get_categories_success(
        self, client: AsyncClient, db_session
    ):
        """测试: 成功获取分类"""
        categories = ["技术", "金融", "教育"]
        for cat in categories:
            template = Template(
                name=f"{cat}模板",
                category=cat,
                layout="single",
                is_active=True,
                use_count=10
            )
            db_session.add(template)
        await db_session.commit()

        response = await client.get("/api/v1/templates/categories")

        assert response.status_code == 200
        data = response.json()
        assert data["code"] == 0
        assert isinstance(data["data"], list)
        # 应该包含我们添加的分类
        for cat in categories:
            assert cat in data["data"]

    async def test_get_categories_empty(
        self, client: AsyncClient
    ):
        """测试: 空分类列表"""
        response = await client.get("/api/v1/templates/categories")

        assert response.status_code == 200
        data = response.json()
        assert data["data"] == []
