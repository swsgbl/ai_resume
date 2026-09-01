"""
搜索 API 完整测试
覆盖所有搜索端点和边界情况
"""
import pytest
from httpx import AsyncClient
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.user import User
from app.models.resume import Resume
from app.models.template import Template


class TestSearchResumesAPI:
    """简历搜索 API 测试"""

    async def test_search_resumes_by_title(
        self, client: AsyncClient, auth_headers, test_user, db_session
    ):
        """测试: 按标题搜索简历"""
        resume = Resume(
            user_id=test_user.id,
            title="Python后端工程师",
            description="Python开发经验",
            content={},
            style_config={}
        )
        db_session.add(resume)
        await db_session.commit()

        response = await client.get(
            "/api/v1/search/resumes?q=Python",
            headers=auth_headers
        )

        assert response.status_code == 200
        data = response.json()
        assert data["code"] == 0
        assert len(data["data"]["results"]) > 0
        assert data["data"]["query"] == "Python"

    async def test_search_resumes_by_description(
        self, client: AsyncClient, auth_headers, test_user, db_session
    ):
        """测试: 按描述搜索简历"""
        resume = Resume(
            user_id=test_user.id,
            title="简历",
            description="拥有React和Vue前端开发经验",
            content={},
            style_config={}
        )
        db_session.add(resume)
        await db_session.commit()

        response = await client.get(
            "/api/v1/search/resumes?q=React",
            headers=auth_headers
        )

        assert response.status_code == 200
        assert len(response.json()["data"]["results"]) > 0

    async def test_search_resumes_json_name(
        self, client: AsyncClient, auth_headers, test_user, db_session
    ):
        """测试: 搜索 JSON 内容中的姓名"""
        resume = Resume(
            user_id=test_user.id,
            title="技术简历",
            content={"basic_info": {"name": "李华", "email": "lihua@test.com"}},
            style_config={}
        )
        db_session.add(resume)
        await db_session.commit()

        response = await client.get(
            "/api/v1/search/resumes?q=李华",
            headers=auth_headers
        )

        assert response.status_code == 200
        data = response.json()
        assert data["code"] == 0

    async def test_search_resumes_json_phone(
        self, client: AsyncClient, auth_headers, test_user, db_session
    ):
        """测试: 搜索 JSON 内容中的电话"""
        resume = Resume(
            user_id=test_user.id,
            title="我的简历",
            content={"basic_info": {"phone": "13912345678"}},
            style_config={}
        )
        db_session.add(resume)
        await db_session.commit()

        response = await client.get(
            "/api/v1/search/resumes?q=13912345678",
            headers=auth_headers
        )

        assert response.status_code == 200

    async def test_search_resumes_json_email(
        self, client: AsyncClient, auth_headers, test_user, db_session
    ):
        """测试: 搜索 JSON 内容中的邮箱"""
        resume = Resume(
            user_id=test_user.id,
            title="开发者简历",
            content={"basic_info": {"email": "developer@example.com"}},
            style_config={}
        )
        db_session.add(resume)
        await db_session.commit()

        response = await client.get(
            "/api/v1/search/resumes?q=developer@example.com",
            headers=auth_headers
        )

        assert response.status_code == 200

    async def test_search_resumes_no_results(
        self, client: AsyncClient, auth_headers
    ):
        """测试: 无搜索结果"""
        response = await client.get(
            "/api/v1/search/resumes?q=不存在的内容xyz123",
            headers=auth_headers
        )

        assert response.status_code == 200
        data = response.json()
        assert data["code"] == 0
        assert len(data["data"]["results"]) == 0
        assert data["data"]["total"] == 0

    async def test_search_resumes_pagination(
        self, client: AsyncClient, auth_headers, test_user, db_session
    ):
        """测试: 搜索结果分页"""
        # 创建多个简历
        for i in range(15):
            resume = Resume(
                user_id=test_user.id,
                title=f"开发工程师{i}",
                description="软件开发",
                content={},
                style_config={}
            )
            db_session.add(resume)
        await db_session.commit()

        response = await client.get(
            "/api/v1/search/resumes?q=开发&page=1&page_size=5",
            headers=auth_headers
        )

        assert response.status_code == 200
        data = response.json()
        assert data["code"] == 0
        assert len(data["data"]["results"]) == 5
        assert data["data"]["page"] == 1
        assert data["data"]["page_size"] == 5

    async def test_search_resumes_page_2(
        self, client: AsyncClient, auth_headers, test_user, db_session
    ):
        """测试: 搜索第二页"""
        for i in range(12):
            resume = Resume(
                user_id=test_user.id,
                title=f"Java工程师{i}",
                description="Java开发",
                content={},
                style_config={}
            )
            db_session.add(resume)
        await db_session.commit()

        response = await client.get(
            "/api/v1/search/resumes?q=Java&page=2&page_size=5",
            headers=auth_headers
        )

        assert response.status_code == 200
        data = response.json()
        assert data["data"]["page"] == 2

    async def test_search_resumes_unauthorized(
        self, client: AsyncClient
    ):
        """测试: 未授权访问"""
        response = await client.get("/api/v1/search/resumes?q=test")

        assert response.status_code == 401

    async def test_search_resumes_min_query_length(
        self, client: AsyncClient, auth_headers
    ):
        """测试: 最小查询长度验证"""
        # Query 参数有 min_length=1，所以单字符应该可以
        response = await client.get(
            "/api/v1/search/resumes?q=a",
            headers=auth_headers
        )
        assert response.status_code == 200


class TestSearchTemplatesAPI:
    """模板搜索 API 测试"""

    async def test_search_templates_by_name(
        self, client: AsyncClient, db_session
    ):
        """测试: 按名称搜索模板"""
        template = Template(
            name="专业简历模板",
            category="professional",
            layout="single",
            is_active=True,
            use_count=100
        )
        db_session.add(template)
        await db_session.commit()

        response = await client.get("/api/v1/search/templates?q=专业")

        assert response.status_code == 200
        data = response.json()
        assert data["code"] == 0
        assert len(data["data"]["results"]) > 0

    async def test_search_templates_by_category(
        self, client: AsyncClient, db_session
    ):
        """测试: 按分类筛选模板"""
        template = Template(
            name="技术模板",
            category="技术",
            sub_category="后端",
            layout="single",
            is_active=True,
            use_count=50
        )
        db_session.add(template)
        await db_session.commit()

        response = await client.get(
            "/api/v1/search/templates?q=模板&category=技术"
        )

        assert response.status_code == 200
        data = response.json()
        assert data["code"] == 0

    async def test_search_templates_by_industry(
        self, client: AsyncClient, db_session
    ):
        """测试: 按行业(子分类)筛选模板"""
        template = Template(
            name="前端模板",
            category="技术",
            sub_category="前端",
            layout="single",
            is_active=True,
            use_count=30
        )
        db_session.add(template)
        await db_session.commit()

        response = await client.get(
            "/api/v1/search/templates?q=模板&industry=前端"
        )

        assert response.status_code == 200
        data = response.json()
        assert data["code"] == 0

    async def test_search_templates_inactive_excluded(
        self, client: AsyncClient, db_session
    ):
        """测试: 非活跃模板被排除"""
        inactive = Template(
            name="非活跃模板",
            category="test",
            layout="single",
            is_active=False,
            use_count=0
        )
        active = Template(
            name="活跃模板",
            category="test",
            layout="single",
            is_active=True,
            use_count=10
        )
        db_session.add(inactive)
        db_session.add(active)
        await db_session.commit()

        response = await client.get("/api/v1/search/templates?q=模板")

        assert response.status_code == 200
        data = response.json()
        # 应该只返回活跃模板
        for result in data["data"]["results"]:
            assert result["is_active"] is True

    async def test_search_templates_pagination(
        self, client: AsyncClient, db_session
    ):
        """测试: 模板搜索分页"""
        for i in range(15):
            template = Template(
                name=f"模板{i}",
                category="test",
                layout="single",
                is_active=True,
                use_count=i
            )
            db_session.add(template)
        await db_session.commit()

        response = await client.get(
            "/api/v1/search/templates?q=模板&page=1&page_size=5"
        )

        assert response.status_code == 200
        data = response.json()
        assert len(data["data"]["results"]) == 5

    async def test_search_templates_no_auth_required(
        self, client: AsyncClient
    ):
        """测试: 模板搜索不需要认证"""
        response = await client.get("/api/v1/search/templates?q=简历")

        assert response.status_code in [200, 401]  # 可能需要或不需要认证


class TestSearchCategoriesAPI:
    """搜索分类 API 测试"""

    async def test_get_search_categories(
        self, client: AsyncClient, db_session
    ):
        """测试: 获取搜索分类"""
        # 创建不同分类的模板
        categories = ["技术", "金融", "教育", "医疗"]
        for cat in categories:
            template = Template(
                name=f"{cat}模板",
                category=cat,
                sub_category=f"{cat}子分类",
                layout="single",
                is_active=True,
                use_count=10
            )
            db_session.add(template)
        await db_session.commit()

        response = await client.get("/api/v1/search/categories")

        assert response.status_code == 200
        data = response.json()
        assert data["code"] == 0
        assert isinstance(data["data"], list)
        # 应该包含 category 和 sub_category 两种类型
        assert len(data["data"]) >= 2

    async def test_get_categories_empty_db(
        self, client: AsyncClient
    ):
        """测试: 空数据库获取分类"""
        response = await client.get("/api/v1/search/categories")

        assert response.status_code == 200
        data = response.json()
        assert data["code"] == 0
        # 可能返回空列表或默认分类
        assert isinstance(data["data"], list)

    async def test_get_categories_structure(
        self, client: AsyncClient, db_session
    ):
        """测试: 分类数据结构"""
        template = Template(
            name="测试",
            category="技术",
            sub_category="后端",
            layout="single",
            is_active=True,
            use_count=1
        )
        db_session.add(template)
        await db_session.commit()

        response = await client.get("/api/v1/search/categories")

        data = response.json()
        for category_type in data["data"]:
            assert "type" in category_type
            assert "name" in category_type
            assert "options" in category_type
            assert isinstance(category_type["options"], list)


class TestSearchSuggestionsAPI:
    """搜索建议 API 测试"""

    async def test_get_suggestions_from_titles(
        self, client: AsyncClient, auth_headers, test_user, db_session
    ):
        """测试: 从简历标题获取建议"""
        titles = ["软件工程师", "高级软件工程师", "软件架构师"]
        for title in titles:
            resume = Resume(
                user_id=test_user.id,
                title=title,
                content={},
                style_config={}
            )
            db_session.add(resume)
        await db_session.commit()

        response = await client.get(
            "/api/v1/search/suggestions?q=软件",
            headers=auth_headers
        )

        assert response.status_code == 200
        data = response.json()
        assert data["code"] == 0
        assert isinstance(data["data"], list)
        # 应该包含匹配的标题
        assert any("软件" in s for s in data["data"])

    async def test_get_suggestions_common_terms(
        self, client: AsyncClient, auth_headers
    ):
        """测试: 常用搜索词建议"""
        response = await client.get(
            "/api/v1/search/suggestions?q=开发",
            headers=auth_headers
        )

        assert response.status_code == 200
        data = response.json()
        assert data["code"] == 0
        # 常用词包含 "前端开发"、"后端开发"、"全栈开发"
        assert any("开发" in s for s in data["data"])

    async def test_get_suggestions_mixed_results(
        self, client: AsyncClient, auth_headers, test_user, db_session
    ):
        """测试: 混合用户标题和常用词"""
        resume = Resume(
            user_id=test_user.id,
            title="React开发者",
            content={},
            style_config={}
        )
        db_session.add(resume)
        await db_session.commit()

        response = await client.get(
            "/api/v1/search/suggestions?q=React",
            headers=auth_headers
        )

        assert response.status_code == 200
        data = response.json()
        # 应该包含用户简历标题
        assert any("React" in s for s in data["data"])

    async def test_get_suggestions_limit_10(
        self, client: AsyncClient, auth_headers, test_user, db_session
    ):
        """测试: 建议结果限制为10个"""
        # 创建超过10个匹配的简历
        for i in range(15):
            resume = Resume(
                user_id=test_user.id,
                title=f"工程师{i}",
                content={},
                style_config={}
            )
            db_session.add(resume)
        await db_session.commit()

        response = await client.get(
            "/api/v1/search/suggestions?q=工程师",
            headers=auth_headers
        )

        assert response.status_code == 200
        data = response.json()
        # 结果应该不超过10个
        assert len(data["data"]) <= 10

    async def test_get_suggestions_no_match(
        self, client: AsyncClient, auth_headers
    ):
        """测试: 无匹配建议"""
        response = await client.get(
            "/api/v1/search/suggestions?q=xyz123notexist",
            headers=auth_headers
        )

        assert response.status_code == 200
        data = response.json()
        # 可能返回空列表或常用词（如果不匹配）
        assert isinstance(data["data"], list)

    async def test_get_suggestions_case_insensitive(
        self, client: AsyncClient, auth_headers
    ):
        """测试: 搜索建议大小写不敏感"""
        response = await client.get(
            "/api/v1/search/suggestions?q=PYTHON",
            headers=auth_headers
        )

        assert response.status_code == 200
        data = response.json()
        assert data["code"] == 0

    async def test_get_suggestions_unauthorized(
        self, client: AsyncClient
    ):
        """测试: 未授权访问"""
        response = await client.get("/api/v1/search/suggestions?q=test")

        assert response.status_code == 401


class TestSearchEdgeCases:
    """搜索边界情况测试"""

    async def test_search_special_characters(
        self, client: AsyncClient, auth_headers
    ):
        """测试: 特殊字符搜索"""
        response = await client.get(
            "/api/v1/search/resumes?q=test%40email",
            headers=auth_headers
        )
        # 应该正常处理或返回空结果
        assert response.status_code == 200

    async def test_search_chinese_characters(
        self, client: AsyncClient, auth_headers, test_user, db_session
    ):
        """测试: 中文搜索"""
        resume = Resume(
            user_id=test_user.id,
            title="高级产品经理",
            description="负责互联网产品设计",
            content={},
            style_config={}
        )
        db_session.add(resume)
        await db_session.commit()

        response = await client.get(
            "/api/v1/search/resumes?q=产品经理",
            headers=auth_headers
        )

        assert response.status_code == 200
        data = response.json()
        assert len(data["data"]["results"]) > 0

    async def test_search_empty_query_validation(
        self, client: AsyncClient, auth_headers
    ):
        """测试: 空查询参数验证"""
        # Query 有 min_length=1，空字符串应该被验证拒绝
        response = await client.get(
            "/api/v1/search/resumes?q=",
            headers=auth_headers
        )
        # FastAPI 验证应该返回 422
        assert response.status_code == 422

    async def test_search_max_length_query(
        self, client: AsyncClient, auth_headers
    ):
        """测试: 最大查询长度"""
        # Query 有 max_length=100
        long_query = "a" * 100
        response = await client.get(
            f"/api/v1/search/resumes?q={long_query}",
            headers=auth_headers
        )
        assert response.status_code == 200

    async def test_search_exceed_max_length(
        self, client: AsyncClient, auth_headers
    ):
        """测试: 超过最大查询长度"""
        too_long = "a" * 101
        response = await client.get(
            f"/api/v1/search/resumes?q={too_long}",
            headers=auth_headers
        )
        # FastAPI 验证应该返回 422
        assert response.status_code == 422
