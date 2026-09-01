"""
Templates API 增强测试 - 提高覆盖率
"""
import pytest
from httpx import AsyncClient
from sqlalchemy.ext.asyncio import AsyncSession


class TestListTemplates:
    """模板列表测试"""

    async def test_list_templates_default(
        self, client: AsyncClient, db_session
    ):
        """测试: 默认获取模板列表"""
        # 先创建一个模板
        from app.models.template import Template

        template = Template(
            name="测试模板",
            category="技术",
            sub_category="后端",
            layout="single",
            is_premium=False,
            is_active=True
        )
        db_session.add(template)
        await db_session.commit()

        response = await client.get("/api/v1/templates")

        assert response.status_code == 200
        data = response.json()
        assert data["code"] == 0
        # PageResponse 结构: data 是数组, total/page/page_size 在根级别
        assert "total" in data
        assert "data" in data
        assert isinstance(data["data"], list)

    async def test_list_templates_with_pagination(
        self, client: AsyncClient, db_session
    ):
        """测试: 分页获取模板"""
        # 先创建多个模板
        from app.models.template import Template

        for i in range(5):
            template = Template(
                name=f"分页测试模板{i}",
                category="技术",
                sub_category="测试",
                layout="single",
                is_premium=False,
                is_active=True
            )
            db_session.add(template)
        await db_session.commit()

        response = await client.get("/api/v1/templates?page=1&page_size=5")

        assert response.status_code == 200
        data = response.json()
        # PageResponse 结构: page 和 page_size 在根级别
        assert data["page"] == 1
        assert data["page_size"] == 5
        assert len(data["data"]) <= 5

    async def test_list_templates_by_category(
        self, client: AsyncClient
    ):
        """测试: 按分类筛选模板"""
        response = await client.get("/api/v1/templates?category=技术")

        assert response.status_code == 200
        data = response.json()
        assert data["code"] == 0

    async def test_list_templates_by_sub_category(
        self, client: AsyncClient
    ):
        """测试: 按子分类筛选模板"""
        response = await client.get("/api/v1/templates?sub_category=后端")

        assert response.status_code == 200
        data = response.json()
        assert data["code"] == 0

    async def test_list_templates_by_level(
        self, client: AsyncClient
    ):
        """测试: 按职级筛选模板"""
        response = await client.get("/api/v1/templates?level=senior")

        assert response.status_code == 200
        data = response.json()
        assert data["code"] == 0

    async def test_list_templates_free_only(
        self, client: AsyncClient, db_session
    ):
        """测试: 只获取免费模板"""
        from app.models.template import Template

        # 创建免费模板
        template = Template(
            name="免费模板",
            category="技术",
            sub_category="测试",
            layout="single",
            is_premium=False,
            is_active=True
        )
        db_session.add(template)
        await db_session.commit()

        response = await client.get("/api/v1/templates?is_premium=false")

        assert response.status_code == 200
        data = response.json()
        assert data["code"] == 0
        # 验证所有返回的模板都是免费的
        for template in data["data"]:
            assert template["is_premium"] is False

    async def test_list_templates_premium_only(
        self, client: AsyncClient
    ):
        """测试: 只获取高级模板"""
        response = await client.get("/api/v1/templates?is_premium=true")

        assert response.status_code == 200
        data = response.json()
        assert data["code"] == 0

    async def test_list_templates_combined_filters(
        self, client: AsyncClient
    ):
        """测试: 组合筛选条件"""
        response = await client.get(
            "/api/v1/templates?category=技术&sub_category=后端&level=mid"
        )

        assert response.status_code == 200
        data = response.json()
        assert data["code"] == 0

    async def test_list_templates_invalid_page(
        self, client: AsyncClient
    ):
        """测试: 无效页码"""
        response = await client.get("/api/v1/templates?page=0")

        # 验证错误 - 页码必须 >= 1
        assert response.status_code == 422

    async def test_list_templates_invalid_page_size(
        self, client: AsyncClient
    ):
        """测试: 无效页大小"""
        response = await client.get("/api/v1/templates?page_size=200")

        # 验证错误 - 页大小必须 <= 100
        assert response.status_code == 422


class TestGetCategories:
    """模板分类测试"""

    async def test_get_categories(
        self, client: AsyncClient
    ):
        """测试: 获取模板分类列表"""
        response = await client.get("/api/v1/templates/categories")

        assert response.status_code == 200
        data = response.json()
        assert data["code"] == 0
        assert isinstance(data["data"], list)


class TestGetTemplateDetail:
    """模板详情测试"""

    async def test_get_template_success(
        self, client: AsyncClient, db_session
    ):
        """测试: 成功获取模板详情"""
        from app.models.template import Template

        # 创建一个模板
        template = Template(
            name="详情测试模板",
            category="技术",
            sub_category="测试",
            layout="single",
            is_premium=False,
            is_active=True
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
        """测试: 获取不存在的模板"""
        response = await client.get("/api/v1/templates/99999")

        assert response.status_code == 404

    async def test_get_template_structure(
        self, client: AsyncClient, db_session
    ):
        """测试: 模板响应结构正确"""
        from app.models.template import Template

        template = Template(
            name="结构测试模板",
            category="技术",
            sub_category="测试",
            layout="single",
            is_premium=False,
            is_active=True
        )
        db_session.add(template)
        await db_session.commit()

        response = await client.get(f"/api/v1/templates/{template.id}")

        assert response.status_code == 200
        data = response.json()
        template = data["data"]

        # 验证必需字段
        assert "id" in template
        assert "name" in template
        assert "layout" in template
        assert "is_premium" in template
        assert "use_count" in template


class TestUseTemplate:
    """使用模板测试"""

    async def test_use_free_template_success(
        self, client: AsyncClient, auth_headers, db_session
    ):
        """测试: 成功使用免费模板"""
        # 创建一个免费模板
        from app.models.template import Template

        template = Template(
            name="免费测试模板",
            category="技术",
            sub_category="测试",
            layout="single",
            is_premium=False,
            is_active=True
        )
        db_session.add(template)
        await db_session.commit()

        response = await client.post(
            f"/api/v1/templates/{template.id}/use",
            headers=auth_headers
        )

        assert response.status_code == 200
        data = response.json()
        assert data["code"] == 0
        assert "使用成功" in data["message"]

    async def test_use_template_not_found(
        self, client: AsyncClient, auth_headers
    ):
        """测试: 使用不存在的模板"""
        response = await client.post(
            "/api/v1/templates/99999/use",
            headers=auth_headers
        )

        assert response.status_code == 404

    async def test_use_premium_template_as_free_user(
        self, client: AsyncClient, auth_headers, db_session
    ):
        """测试: 普通用户使用高级模板"""
        from app.models.template import Template

        template = Template(
            name="高级模板",
            category="技术",
            sub_category="测试",
            layout="single",
            is_premium=True,
            is_active=True
        )
        db_session.add(template)
        await db_session.commit()

        response = await client.post(
            f"/api/v1/templates/{template.id}/use",
            headers=auth_headers
        )

        assert response.status_code == 403
        data = response.json()
        assert "高级会员" in data["detail"]

    async def test_use_template_without_auth(
        self, client: AsyncClient, db_session
    ):
        """测试: 未认证使用模板"""
        from app.models.template import Template

        template = Template(
            name="测试模板",
            category="技术",
            sub_category="测试",
            layout="single",
            is_premium=False,
            is_active=True
        )
        db_session.add(template)
        await db_session.commit()

        response = await client.post(f"/api/v1/templates/{template.id}/use")

        assert response.status_code == 401


class TestFavoriteTemplate:
    """收藏模板测试"""

    async def test_favorite_template_success(
        self, client: AsyncClient, auth_headers, db_session
    ):
        """测试: 成功收藏模板"""
        from app.models.template import Template

        template = Template(
            name="可收藏模板",
            category="技术",
            sub_category="测试",
            layout="single",
            is_premium=False,
            is_active=True
        )
        db_session.add(template)
        await db_session.commit()

        response = await client.post(
            f"/api/v1/templates/{template.id}/favorite",
            headers=auth_headers
        )

        assert response.status_code == 200
        data = response.json()
        assert data["code"] == 0
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

    async def test_favorite_template_already_favorited(
        self, client: AsyncClient, auth_headers, db_session
    ):
        """测试: 收藏已收藏的模板"""
        from app.models.template import Template

        template = Template(
            name="重复收藏测试",
            category="技术",
            sub_category="测试",
            layout="single",
            is_premium=False,
            is_active=True
        )
        db_session.add(template)
        await db_session.commit()

        # 第一次收藏
        await client.post(
            f"/api/v1/templates/{template.id}/favorite",
            headers=auth_headers
        )

        # 第二次收藏应该失败
        response = await client.post(
            f"/api/v1/templates/{template.id}/favorite",
            headers=auth_headers
        )

        assert response.status_code == 400

    async def test_favorite_without_auth(
        self, client: AsyncClient, db_session
    ):
        """测试: 未认证收藏模板"""
        from app.models.template import Template

        template = Template(
            name="未认证收藏测试",
            category="技术",
            sub_category="测试",
            layout="single",
            is_premium=False,
            is_active=True
        )
        db_session.add(template)
        await db_session.commit()

        response = await client.post(f"/api/v1/templates/{template.id}/favorite")

        assert response.status_code == 401


class TestUnfavoriteTemplate:
    """取消收藏测试"""

    async def test_unfavorite_template_success(
        self, client: AsyncClient, auth_headers, db_session
    ):
        """测试: 成功取消收藏"""
        from app.models.template import Template

        template = Template(
            name="取消收藏测试",
            category="技术",
            sub_category="测试",
            layout="single",
            is_premium=False,
            is_active=True
        )
        db_session.add(template)
        await db_session.commit()

        # 先收藏
        await client.post(
            f"/api/v1/templates/{template.id}/favorite",
            headers=auth_headers
        )

        # 再取消收藏
        response = await client.delete(
            f"/api/v1/templates/{template.id}/favorite",
            headers=auth_headers
        )

        assert response.status_code == 200
        data = response.json()
        assert "取消收藏成功" in data["message"]

    async def test_unfavorite_template_not_favorited(
        self, client: AsyncClient, auth_headers, db_session
    ):
        """测试: 取消收藏未收藏的模板"""
        from app.models.template import Template

        template = Template(
            name="未收藏模板",
            category="技术",
            sub_category="测试",
            layout="single",
            is_premium=False,
            is_active=True
        )
        db_session.add(template)
        await db_session.commit()

        response = await client.delete(
            f"/api/v1/templates/{template.id}/favorite",
            headers=auth_headers
        )

        assert response.status_code == 404

    async def test_unfavorite_without_auth(
        self, client: AsyncClient
    ):
        """测试: 未认证取消收藏"""
        response = await client.delete("/api/v1/templates/1/favorite")

        assert response.status_code == 401


class TestGetFavoriteTemplates:
    """获取收藏列表测试"""

    async def test_get_favorite_templates_empty(
        self, client: AsyncClient, auth_headers
    ):
        """测试: 获取空的收藏列表"""
        response = await client.get(
            "/api/v1/templates/favorites/list",
            headers=auth_headers
        )

        assert response.status_code == 200
        data = response.json()
        assert data["code"] == 0
        assert data["data"] == []

    async def test_get_favorite_templates_with_items(
        self, client: AsyncClient, auth_headers, db_session
    ):
        """测试: 获取有内容的收藏列表"""
        from app.models.template import Template

        template = Template(
            name="收藏列表测试",
            category="技术",
            sub_category="测试",
            layout="single",
            is_premium=False,
            is_active=True
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
        assert len(data["data"]) > 0

    async def test_get_favorites_without_auth(
        self, client: AsyncClient
    ):
        """测试: 未认证获取收藏列表"""
        response = await client.get("/api/v1/templates/favorites/list")

        assert response.status_code == 401


class TestTemplateFilters:
    """模板筛选组合测试"""

    async def test_filter_by_category_and_level(
        self, client: AsyncClient
    ):
        """测试: 按分类和职级筛选"""
        response = await client.get(
            "/api/v1/templates?category=技术&level=entry"
        )

        assert response.status_code == 200

    async def test_filter_by_multiple_categories(
        self, client: AsyncClient
    ):
        """测试: 测试多个分类"""
        categories = ["技术", "金融", "教育"]
        for category in categories:
            response = await client.get(f"/api/v1/templates?category={category}")
            assert response.status_code == 200

    async def test_template_ordering(
        self, client: AsyncClient, db_session
    ):
        """测试: 模板按使用次数排序"""
        from app.models.template import Template

        # 创建多个模板，设置不同的使用次数
        for i in range(3):
            template = Template(
                name=f"排序测试{i}",
                category="技术",
                sub_category="测试",
                layout="single",
                is_premium=False,
                is_active=True,
                use_count=i + 1
            )
            db_session.add(template)
        await db_session.commit()

        response = await client.get("/api/v1/templates?category=技术&page_size=10")

        assert response.status_code == 200
        data = response.json()
        items = data["data"]

        # 验证是按使用次数降序排列
        if len(items) >= 2:
            for i in range(len(items) - 1):
                assert items[i]["use_count"] >= items[i + 1]["use_count"]
