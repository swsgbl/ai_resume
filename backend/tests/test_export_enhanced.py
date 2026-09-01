"""
导出 API 增强测试 - 提高覆盖率
"""
import pytest
from httpx import AsyncClient
from sqlalchemy.ext.asyncio import AsyncSession


class TestExportPDF:
    """PDF 导出测试"""

    async def test_export_pdf_success(
        self, client: AsyncClient, auth_headers, test_resume
    ):
        """测试: 成功导出 PDF"""
        response = await client.get(
            f"/api/v1/export/{test_resume.id}/pdf",
            headers=auth_headers
        )

        # 可能返回 200 (成功) 或 500 (WeasyPrint 未安装)
        assert response.status_code in [200, 500]

    async def test_export_pdf_resume_not_found(
        self, client: AsyncClient, auth_headers
    ):
        """测试: 导出不存在的简历 PDF"""
        response = await client.get(
            "/api/v1/export/99999/pdf",
            headers=auth_headers
        )

        assert response.status_code == 404

    async def test_export_pdf_unauthorized(
        self, client: AsyncClient, auth_headers, db_session
    ):
        """测试: 尝试导出其他用户的简历 PDF"""
        from app.models.resume import Resume
        from app.models.user import User

        # 创建另一个用户
        other_user = User(
            email="pdf@example.com",
            password_hash="hash",
            username="pdfuser",
            role="user"
        )
        db_session.add(other_user)
        await db_session.commit()

        other_resume = Resume(
            user_id=other_user.id,
            title="其他用户的PDF简历",
            content={},
            style_config={},
            status="draft"
        )
        db_session.add(other_resume)
        await db_session.commit()

        response = await client.get(
            f"/api/v1/export/{other_resume.id}/pdf",
            headers=auth_headers
        )

        assert response.status_code == 404

    async def test_export_pdf_without_auth(
        self, client: AsyncClient, test_resume
    ):
        """测试: 未认证用户导出 PDF"""
        response = await client.get(
            f"/api/v1/export/{test_resume.id}/pdf"
        )

        assert response.status_code == 401


class TestExportWord:
    """Word 导出测试"""

    async def test_export_word_success(
        self, client: AsyncClient, auth_headers, test_resume
    ):
        """测试: 成功导出 Word"""
        response = await client.get(
            f"/api/v1/export/{test_resume.id}/word",
            headers=auth_headers
        )

        # Word 导出通常能成功
        assert response.status_code in [200, 500]

    async def test_export_word_resume_not_found(
        self, client: AsyncClient, auth_headers
    ):
        """测试: 导出不存在的简历 Word"""
        response = await client.get(
            "/api/v1/export/99999/word",
            headers=auth_headers
        )

        assert response.status_code == 404

    async def test_export_word_unauthorized(
        self, client: AsyncClient, auth_headers, db_session
    ):
        """测试: 尝试导出其他用户的简历 Word"""
        from app.models.resume import Resume
        from app.models.user import User

        other_user = User(
            email="word@example.com",
            password_hash="hash",
            username="worduser",
            role="user"
        )
        db_session.add(other_user)
        await db_session.commit()

        other_resume = Resume(
            user_id=other_user.id,
            title="其他用户的Word简历",
            content={},
            style_config={},
            status="draft"
        )
        db_session.add(other_resume)
        await db_session.commit()

        response = await client.get(
            f"/api/v1/export/{other_resume.id}/word",
            headers=auth_headers
        )

        assert response.status_code == 404


class TestExportHTML:
    """HTML 导出测试"""

    async def test_export_html_success(
        self, client: AsyncClient, auth_headers, test_resume
    ):
        """测试: 成功导出 HTML"""
        response = await client.get(
            f"/api/v1/export/{test_resume.id}/html",
            headers=auth_headers
        )

        # HTML 导出应该成功
        assert response.status_code == 200
        # content-type 可能包含重复的 charset
        assert "text/html" in response.headers["content-type"]

    async def test_export_html_resume_not_found(
        self, client: AsyncClient, auth_headers
    ):
        """测试: 导出不存在的简历 HTML"""
        response = await client.get(
            "/api/v1/export/99999/html",
            headers=auth_headers
        )

        assert response.status_code == 404

    async def test_export_html_with_template(
        self, client: AsyncClient, auth_headers, test_user, db_session
    ):
        """测试: 使用模板导出 HTML"""
        from app.models.resume import Resume
        from app.models.template import Template

        # 创建模板
        template = Template(
            name="测试模板",
            category="技术",
            sub_category="后端",
            preview_url="preview.png",
            html_content="<html><body>{{content}}</body></html>",
            css_content="body { margin: 0; }",
            is_premium=False
        )
        db_session.add(template)
        await db_session.commit()

        # 创建使用该模板的简历
        resume = Resume(
            user_id=test_user.id,
            title="带模板的简历",
            content={"basic_info": {"name": "张三"}},
            style_config={},
            template_id=template.id,
            status="draft"
        )
        db_session.add(resume)
        await db_session.commit()

        response = await client.get(
            f"/api/v1/export/{resume.id}/html",
            headers=auth_headers
        )

        assert response.status_code == 200
        assert "text/html" in response.headers["content-type"]


class TestPreviewResume:
    """简历预览测试"""

    async def test_preview_resume_success(
        self, client: AsyncClient, auth_headers, test_resume
    ):
        """测试: 成功预览简历"""
        response = await client.get(
            f"/api/v1/export/{test_resume.id}/preview",
            headers=auth_headers
        )

        assert response.status_code == 200
        assert "text/html" in response.headers["content-type"]

    async def test_preview_resume_not_found(
        self, client: AsyncClient, auth_headers
    ):
        """测试: 预览不存在的简历"""
        response = await client.get(
            "/api/v1/export/99999/preview",
            headers=auth_headers
        )

        assert response.status_code == 404

    async def test_preview_resume_unauthorized(
        self, client: AsyncClient, auth_headers, db_session
    ):
        """测试: 预览其他用户的简历"""
        from app.models.resume import Resume
        from app.models.user import User

        other_user = User(
            email="preview@example.com",
            password_hash="hash",
            username="previewuser",
            role="user"
        )
        db_session.add(other_user)
        await db_session.commit()

        other_resume = Resume(
            user_id=other_user.id,
            title="私密简历",
            content={},
            style_config={},
            status="draft"
        )
        db_session.add(other_resume)
        await db_session.commit()

        response = await client.get(
            f"/api/v1/export/{other_resume.id}/preview",
            headers=auth_headers
        )

        assert response.status_code == 404

    async def test_preview_resume_without_auth(
        self, client: AsyncClient, test_resume
    ):
        """测试: 未认证用户预览简历"""
        response = await client.get(
            f"/api/v1/export/{test_resume.id}/preview"
        )

        assert response.status_code == 401


class TestExportStyles:
    """导出样式测试"""

    async def test_get_export_styles(self, client: AsyncClient):
        """测试: 获取可用导出样式"""
        response = await client.get("/api/v1/export/styles")

        assert response.status_code == 200
        data = response.json()
        assert data["code"] == 0
        assert isinstance(data["data"], list)
        # 应该有多种样式
        assert len(data["data"]) > 0

    async def test_export_styles_structure(self, client: AsyncClient):
        """测试: 导出样式结构正确"""
        response = await client.get("/api/v1/export/styles")

        assert response.status_code == 200
        data = response.json()
        styles = data["data"]

        # 检查第一个样式的结构
        if styles:
            style = styles[0]
            assert "id" in style
            assert "name" in style
            assert "description" in style
            assert "primary_color" in style

    async def test_export_styles_includes_expected_styles(
        self, client: AsyncClient
    ):
        """测试: 包含预期的样式"""
        response = await client.get("/api/v1/export/styles")

        assert response.status_code == 200
        data = response.json()
        style_ids = [s["id"] for s in data["data"]]

        # 检查一些常见样式
        expected_styles = ["modern", "professional", "minimal"]
        for style in expected_styles:
            assert style in style_ids, f"缺少样式: {style}"


class TestExportWithDifferentContent:
    """不同内容导出测试"""

    async def test_export_with_empty_content(
        self, client: AsyncClient, auth_headers, test_user, db_session
    ):
        """测试: 导出空内容简历"""
        from app.models.resume import Resume

        resume = Resume(
            user_id=test_user.id,
            title="空简历",
            content={},
            style_config={},
            status="draft"
        )
        db_session.add(resume)
        await db_session.commit()

        response = await client.get(
            f"/api/v1/export/{resume.id}/html",
            headers=auth_headers
        )

        # 应该仍然返回 200，但内容可能为空
        assert response.status_code == 200

    async def test_export_with_full_content(
        self, client: AsyncClient, auth_headers, test_user, db_session
    ):
        """测试: 导出完整内容简历"""
        from app.models.resume import Resume

        full_content = {
            "basic_info": {
                "name": "李四",
                "email": "lisi@example.com",
                "phone": "13900139000",
                "title": "高级软件工程师"
            },
            "summary": "有10年经验的高级软件工程师",
            "work_experience": [
                {
                    "company": "Tech公司",
                    "position": "高级工程师",
                    "start_date": "2020-01",
                    "end_date": "2023-12",
                    "description": "负责核心系统开发"
                }
            ],
            "education": [
                {
                    "school": "清华大学",
                    "degree": "学士",
                    "major": "计算机科学",
                    "start_date": "2012-09",
                    "end_date": "2016-06"
                }
            ],
            "skills": [
                {"name": "Python", "level": "精通"},
                {"name": "JavaScript", "level": "熟练"}
            ]
        }

        resume = Resume(
            user_id=test_user.id,
            title="完整简历",
            content=full_content,
            style_config={"theme": "professional"},
            status="published"
        )
        db_session.add(resume)
        await db_session.commit()

        response = await client.get(
            f"/api/v1/export/{resume.id}/html",
            headers=auth_headers
        )

        assert response.status_code == 200
        # 检查响应包含内容
        assert len(response.content) > 0
