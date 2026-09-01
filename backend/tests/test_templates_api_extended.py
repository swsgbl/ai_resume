"""
Templates API 扩展测试 - 针对 templates.py 缺失覆盖行
"""
import pytest
from httpx import AsyncClient
from unittest.mock import AsyncMock, patch
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select

from app.models.user import User
from app.models.template import Template, Favorite


class TestListTemplatesFilters:
    """测试模板列表筛选 (行 65-72)"""

    async def test_list_templates_with_sub_category(
        self, client: AsyncClient, db_session
    ):
        """测试: 按子分类筛选"""
        # 创建模板
        template = Template(
            name="技术类简历",
            category="professional",
            sub_category="technology",
            layout="single",
            is_active=True,
            is_premium=False
        )
        db_session.add(template)
        await db_session.commit()

        response = await client.get(
            "/api/v1/templates?sub_category=technology"
        )

        assert response.status_code == 200
        data = response.json()
        assert data["total"] >= 1

    async def test_list_templates_with_level(
        self, client: AsyncClient, db_session
    ):
        """测试: 按级别筛选"""
        template = Template(
            name="高级模板",
            category="professional",
            level="senior",
            layout="single",
            is_active=True,
            is_premium=False
        )
        db_session.add(template)
        await db_session.commit()

        response = await client.get(
            "/api/v1/templates?level=senior"
        )

        assert response.status_code == 200

    async def test_list_templates_premium_only(
        self, client: AsyncClient, db_session
    ):
        """测试: 只显示高级模板"""
        template = Template(
            name="高级模板",
            category="premium",
            layout="single",
            is_active=True,
            is_premium=True
        )
        db_session.add(template)
        await db_session.commit()

        response = await client.get(
            "/api/v1/templates?is_premium=true"
        )

        assert response.status_code == 200
        data = response.json()
        for t in data["data"]:
            assert t["is_premium"] is True

    async def test_list_free_templates_only(
        self, client: AsyncClient, db_session
    ):
        """测试: 只显示免费模板"""
        template = Template(
            name="免费模板",
            category="basic",
            layout="single",
            is_active=True,
            is_premium=False
        )
        db_session.add(template)
        await db_session.commit()

        response = await client.get(
            "/api/v1/templates?is_premium=false"
        )

        assert response.status_code == 200
        data = response.json()
        for t in data["data"]:
            assert t["is_premium"] is False


class TestGetCategories:
    """测试获取分类 (行 86-88)"""

    async def test_get_categories(
        self, client: AsyncClient, db_session
    ):
        """测试: 获取所有分类"""
        # 创建多个分类的模板
        for cat in ["professional", "creative", "minimal"]:
            template = Template(
                name=f"{cat}模板",
                category=cat,
                layout="single",
                is_active=True
            )
            db_session.add(template)
        await db_session.commit()

        response = await client.get("/api/v1/templates/categories")

        assert response.status_code == 200
        data = response.json()
        assert isinstance(data["data"], list)
        assert "professional" in data["data"]


class TestGetTemplateDetail:
    """测试获取模板详情 (行 100-108)"""

    async def test_get_template_success(
        self, client: AsyncClient, db_session
    ):
        """测试: 成功获取模板详情"""
        template = Template(
            name="详情模板",
            category="test",
            layout="single",
            description="这是一个测试模板",
            is_active=True
        )
        db_session.add(template)
        await db_session.commit()

        response = await client.get(f"/api/v1/templates/{template.id}")

        assert response.status_code == 200
        data = response.json()
        assert data["data"]["name"] == "详情模板"
        assert data["data"]["description"] == "这是一个测试模板"

    async def test_get_template_not_found(
        self, client: AsyncClient
    ):
        """测试: 模板不存在"""
        response = await client.get("/api/v1/templates/99999")

        assert response.status_code == 404
        assert "模板不存在" in response.json()["detail"]

    async def test_get_inactive_template(
        self, client: AsyncClient, db_session
    ):
        """测试: 获取已禁用模板"""
        template = Template(
            name="禁用模板",
            category="test",
            layout="single",
            is_active=False
        )
        db_session.add(template)
        await db_session.commit()

        response = await client.get(f"/api/v1/templates/{template.id}")

        assert response.status_code == 404


class TestUseTemplate:
    """测试使用模板 (行 124-142)"""

    async def test_use_free_template(
        self, client: AsyncClient, auth_headers, db_session
    ):
        """测试: 使用免费模板"""
        template = Template(
            name="免费使用模板",
            category="basic",
            layout="single",
            is_active=True,
            is_premium=False,
            use_count=5
        )
        db_session.add(template)
        await db_session.commit()

        old_count = template.use_count

        response = await client.post(
            f"/api/v1/templates/{template.id}/use",
            headers=auth_headers
        )

        assert response.status_code == 200
        await db_session.refresh(template)
        assert template.use_count == old_count + 1

    async def test_use_premium_template_as_free_user(
        self, client: AsyncClient, auth_headers, test_user, db_session
    ):
        """测试: 免费用户使用高级模板"""
        # 确保用户是普通用户
        test_user.role = "user"
        await db_session.commit()

        template = Template(
            name="高级模板",
            category="premium",
            layout="single",
            is_active=True,
            is_premium=True
        )
        db_session.add(template)
        await db_session.commit()

        response = await client.post(
            f"/api/v1/templates/{template.id}/use",
            headers=auth_headers
        )

        assert response.status_code == 403
        assert "高级会员" in response.json()["detail"]

    async def test_use_nonexistent_template(
        self, client: AsyncClient, auth_headers
    ):
        """测试: 使用不存在的模板"""
        response = await client.post(
            "/api/v1/templates/99999/use",
            headers=auth_headers
        )

        assert response.status_code == 404


class TestFavoriteTemplate:
    """测试收藏模板 (行 156-185)"""

    async def test_favorite_template_success(
        self, client: AsyncClient, auth_headers, db_session
    ):
        """测试: 成功收藏模板"""
        template = Template(
            name="可收藏模板",
            category="test",
            layout="single",
            is_active=True
        )
        db_session.add(template)
        await db_session.commit()

        response = await client.post(
            f"/api/v1/templates/{template.id}/favorite",
            headers=auth_headers
        )

        assert response.status_code == 200
        assert "收藏成功" in response.json()["message"]

        # 验证收藏记录
        result = await db_session.execute(
            select(Favorite).where(
                Favorite.target_type == "template",
                Favorite.target_id == template.id
            )
        )
        assert result.scalar_one_or_none() is not None

    async def test_favorite_nonexistent_template(
        self, client: AsyncClient, auth_headers
    ):
        """测试: 收藏不存在的模板"""
        response = await client.post(
            "/api/v1/templates/99999/favorite",
            headers=auth_headers
        )

        assert response.status_code == 404

    async def test_favorite_already_favorited(
        self, client: AsyncClient, auth_headers, test_user, db_session
    ):
        """测试: 重复收藏"""
        template = Template(
            name="重复收藏测试",
            category="test",
            layout="single",
            is_active=True
        )
        db_session.add(template)
        await db_session.commit()

        # 首次收藏
        favorite = Favorite(
            user_id=test_user.id,
            target_type="template",
            target_id=template.id
        )
        db_session.add(favorite)
        await db_session.commit()

        # 再次收藏
        response = await client.post(
            f"/api/v1/templates/{template.id}/favorite",
            headers=auth_headers
        )

        assert response.status_code == 400
        assert "已收藏" in response.json()["detail"]


class TestUnfavoriteTemplate:
    """测试取消收藏 (行 202-213)"""

    async def test_unfavorite_template_success(
        self, client: AsyncClient, auth_headers, test_user, db_session
    ):
        """测试: 成功取消收藏"""
        template = Template(
            name="取消收藏测试",
            category="test",
            layout="single",
            is_active=True
        )
        db_session.add(template)
        await db_session.commit()

        # 先收藏
        favorite = Favorite(
            user_id=test_user.id,
            target_type="template",
            target_id=template.id
        )
        db_session.add(favorite)
        await db_session.commit()

        # 取消收藏
        response = await client.delete(
            f"/api/v1/templates/{template.id}/favorite",
            headers=auth_headers
        )

        assert response.status_code == 200
        assert "取消收藏成功" in response.json()["message"]

    async def test_unfavorite_not_favorited(
        self, client: AsyncClient, auth_headers
    ):
        """测试: 取消收藏未收藏的模板"""
        response = await client.delete(
            "/api/v1/templates/12345/favorite",
            headers=auth_headers
        )

        assert response.status_code == 404
        assert "未收藏" in response.json()["detail"]


class TestGetFavoriteTemplates:
    """测试获取收藏列表"""

    async def test_get_favorite_templates_empty(
        self, client: AsyncClient, auth_headers
    ):
        """测试: 获取空收藏列表"""
        response = await client.get(
            "/api/v1/templates/favorites/list",
            headers=auth_headers
        )

        assert response.status_code == 200
        data = response.json()
        assert data["data"] == []

    async def test_get_favorite_templates_with_items(
        self, client: AsyncClient, auth_headers, test_user, db_session
    ):
        """测试: 获取收藏列表"""
        # 创建模板并收藏
        template = Template(
            name="收藏列表测试",
            category="test",
            layout="single",
            is_active=True
        )
        db_session.add(template)
        await db_session.commit()

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
        assert len(data["data"]) >= 1
