"""
模板 API 增强测试 - 提高覆盖率
"""
import pytest
from httpx import AsyncClient
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select


class TestTemplatesEnhanced:
    """模板 API 增强测试"""

    async def test_list_templates_with_all_filters(
        self, client: AsyncClient, db_session
    ):
        """测试使用所有筛选条件"""
        from app.models.template import Template

        template = Template(
            name="高级技术模板",
            category="技术",
            sub_category="后端开发",
            level="senior",
            layout="modern",
            is_premium=True,
            is_active=True,
            use_count=100
        )
        db_session.add(template)
        await db_session.commit()

        response = await client.get(
            "/api/v1/templates?category=技术&sub_category=后端开发&level=senior&is_premium=true"
        )
        assert response.status_code == 200
        data = response.json()
        assert data["code"] == 0

    async def test_list_templates_sub_category_filter(
        self, client: AsyncClient, db_session
    ):
        """测试子分类筛选"""
        from app.models.template import Template

        template1 = Template(
            name="前端模板",
            category="技术",
            sub_category="前端开发",
            layout="modern",
            is_active=True,
            use_count=50
        )
        template2 = Template(
            name="后端模板",
            category="技术",
            sub_category="后端开发",
            layout="classic",
            is_active=True,
            use_count=60
        )
        db_session.add(template1)
        db_session.add(template2)
        await db_session.commit()

        response = await client.get(
            "/api/v1/templates?sub_category=前端开发"
        )
        assert response.status_code == 200

    async def test_list_templates_premium_only(
        self, client: AsyncClient, db_session
    ):
        """测试只获取高级模板"""
        from app.models.template import Template

        template = Template(
            name="高级模板",
            category="技术",
            layout="modern",
            is_premium=True,
            is_active=True,
            use_count=100
        )
        db_session.add(template)
        await db_session.commit()

        response = await client.get(
            "/api/v1/templates?is_premium=true"
        )
        assert response.status_code == 200

    async def test_get_template_not_found(
        self, client: AsyncClient
    ):
        """测试获取不存在的模板"""
        response = await client.get("/api/v1/templates/99999")
        assert response.status_code == 404

    async def test_use_template_not_found(
        self, client: AsyncClient, auth_headers
    ):
        """测试使用不存在的模板"""
        response = await client.post(
            "/api/v1/templates/99999/use",
            headers=auth_headers
        )
        assert response.status_code == 404

    async def test_use_premium_template_without_permission(
        self, client: AsyncClient, auth_headers, db_session
    ):
        """测试普通用户使用高级模板"""
        from app.models.template import Template
        from app.models.user import User

        # 确保用户是普通用户
        result = await db_session.execute(select(User).where(User.email == "test@example.com"))
        user = result.scalar_one_or_none()
        if user:
            user.role = "user"
            await db_session.commit()

        # 创建高级模板
        template = Template(
            name="高级模板",
            category="技术",
            layout="modern",
            is_premium=True,
            is_active=True,
            use_count=100
        )
        db_session.add(template)
        await db_session.commit()

        response = await client.post(
            f"/api/v1/templates/{template.id}/use",
            headers=auth_headers
        )
        assert response.status_code == 403


class TestTemplateCategories:
    """模板分类测试"""

    async def test_get_categories_empty(
        self, client: AsyncClient
    ):
        """测试获取分类列表（空）"""
        response = await client.get("/api/v1/templates/categories")
        assert response.status_code == 200
        data = response.json()
        assert data["code"] == 0

    async def test_get_categories_with_data(
        self, client: AsyncClient, db_session
    ):
        """测试获取有数据的分类列表"""
        from app.models.template import Template

        for category in ["技术", "金融", "教育", "医疗"]:
            template = Template(
                name=f"{category}模板",
                category=category,
                layout="modern",
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


class TestTemplateFavorites:
    """模板收藏测试"""

    async def test_favorite_template_not_found(
        self, client: AsyncClient, auth_headers
    ):
        """测试收藏不存在的模板"""
        response = await client.post(
            "/api/v1/templates/99999/favorite",
            headers=auth_headers
        )
        assert response.status_code == 404

    async def test_favorite_template_twice(
        self, client: AsyncClient, auth_headers, db_session, test_user
    ):
        """测试重复收藏模板"""
        from app.models.template import Template, Favorite

        template = Template(
            name="收藏测试模板",
            category="技术",
            layout="modern",
            is_active=True,
            use_count=0
        )
        db_session.add(template)
        await db_session.commit()

        # 第一次收藏
        response1 = await client.post(
            f"/api/v1/templates/{template.id}/favorite",
            headers=auth_headers
        )
        assert response1.status_code == 200

        # 第二次收藏（应该失败）
        response2 = await client.post(
            f"/api/v1/templates/{template.id}/favorite",
            headers=auth_headers
        )
        assert response2.status_code == 400

    async def test_unfavorite_not_favorited_template(
        self, client: AsyncClient, auth_headers, db_session
    ):
        """测试取消未收藏的模板"""
        from app.models.template import Template

        template = Template(
            name="取消收藏测试",
            category="技术",
            layout="modern",
            is_active=True,
            use_count=0
        )
        db_session.add(template)
        await db_session.commit()

        response = await client.delete(
            f"/api/v1/templates/{template.id}/favorite",
            headers=auth_headers
        )
        assert response.status_code == 404

    async def test_get_favorite_templates_empty(
        self, client: AsyncClient, auth_headers
    ):
        """测试获取空收藏列表"""
        response = await client.get(
            "/api/v1/templates/favorites/list",
            headers=auth_headers
        )
        assert response.status_code == 200
        data = response.json()
        assert data["code"] == 0
        assert data["data"] == []

    async def test_get_favorite_templates_with_data(
        self, client: AsyncClient, auth_headers, db_session, test_user
    ):
        """测试获取有数据的收藏列表"""
        from app.models.template import Template, Favorite

        template = Template(
            name="收藏列表测试",
            category="技术",
            layout="modern",
            is_active=True,
            use_count=0
        )
        db_session.add(template)
        await db_session.commit()

        # 添加收藏
        favorite = Favorite(
            user_id=test_user.id,
            target_type="template",
            target_id=template.id
        )
        db_session.add(favorite)
        await db_session.commit()

        response = await client.get(
            "/api/v1/templates/favorites/list",
            headers=auth_headers
        )
        assert response.status_code == 200
        data = response.json()
        assert data["code"] == 0
