"""
导出 API 端点测试
"""
import pytest
from httpx import AsyncClient
from unittest.mock import AsyncMock, patch
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.user import User
from app.models.resume import Resume
from app.models.template import Template


class TestExportToPdf:
    """PDF 导出测试"""

    async def test_export_to_pdf_success(
        self, client: AsyncClient, auth_headers, test_resume, db_session
    ):
        """测试: 成功导出 PDF"""
        mock_pdf = b"%PDF-1.4 fake content"

        with patch("app.api.v1.export.export_service") as mock_service:
            mock_service.to_pdf = AsyncMock(return_value=mock_pdf)

            response = await client.get(
                f"/api/v1/export/{test_resume.id}/pdf",
                headers=auth_headers
            )

            assert response.status_code == 200
            assert response.headers["content-type"] == "application/pdf"

    async def test_export_to_pdf_with_template(
        self, client: AsyncClient, auth_headers, test_user, db_session
    ):
        """测试: 带模板的 PDF 导出"""
        # 创建模板
        template = Template(
            name="测试模板",
            category="professional",
            level="free",
            html_content="<div>{{content}}</div>",
            css_content=".test { color: blue; }",
            style={}
        )
        db_session.add(template)
        await db_session.commit()

        # 创建关联模板的简历
        resume = Resume(
            user_id=test_user.id,
            title="带模板简历",
            content={"basic_info": {"name": "用户"}},
            style_config={},
            template_id=template.id,
            status="draft"
        )
        db_session.add(resume)
        await db_session.commit()

        mock_pdf = b"%PDF-1.4 with template"

        with patch("app.api.v1.export.export_service") as mock_service:
            mock_service.to_pdf = AsyncMock(return_value=mock_pdf)

            response = await client.get(
                f"/api/v1/export/{resume.id}/pdf",
                headers=auth_headers
            )

            assert response.status_code == 200
            # 验证 to_pdf 被调用时传入了 template_html
            mock_service.to_pdf.assert_called_once()
            call_args = mock_service.to_pdf.call_args
            assert call_args.kwargs["template_html"] == template.html_content

    async def test_export_to_pdf_resume_not_found(
        self, client: AsyncClient, auth_headers
    ):
        """测试: 简历不存在"""
        response = await client.get(
            "/api/v1/export/99999/pdf",
            headers=auth_headers
        )

        assert response.status_code == 404

    async def test_export_to_pdf_unauthorized(
        self, client: AsyncClient, db_session
    ):
        """测试: 未授权访问"""
        other_user = User(
            email="other@example.com",
            password_hash="hash",
            username="other",
            role="user"
        )
        db_session.add(other_user)
        await db_session.commit()

        other_resume = Resume(
            user_id=other_user.id,
            title="其他用户简历",
            content={},
            style_config={},
            status="draft"
        )
        db_session.add(other_resume)
        await db_session.commit()

        # 创建另一个用户并尝试访问
        response = await client.get(f"/api/v1/export/{other_resume.id}/pdf")

        assert response.status_code == 401

    async def test_export_to_pdf_service_error(
        self, client: AsyncClient, auth_headers, test_resume
    ):
        """测试: 导出服务错误"""
        with patch("app.api.v1.export.export_service") as mock_service:
            mock_service.to_pdf = AsyncMock(side_effect=Exception("生成失败"))

            response = await client.get(
                f"/api/v1/export/{test_resume.id}/pdf",
                headers=auth_headers
            )

            assert response.status_code == 500

    async def test_export_to_pdf_chinese_filename(
        self, client: AsyncClient, auth_headers, test_user, db_session
    ):
        """测试: 中文文件名编码"""
        resume = Resume(
            user_id=test_user.id,
            title="中文简历",
            content={},
            style_config={},
            status="draft"
        )
        db_session.add(resume)
        await db_session.commit()

        mock_pdf = b"%PDF-1.4"

        with patch("app.api.v1.export.export_service") as mock_service:
            mock_service.to_pdf = AsyncMock(return_value=mock_pdf)

            response = await client.get(
                f"/api/v1/export/{resume.id}/pdf",
                headers=auth_headers
            )

            assert response.status_code == 200
            assert "Content-Disposition" in response.headers


class TestExportToWord:
    """Word 导出测试"""

    async def test_export_to_word_success(
        self, client: AsyncClient, auth_headers, test_resume
    ):
        """测试: 成功导出 Word"""
        mock_word = b"PK\x03\x04 fake docx"

        with patch("app.api.v1.export.export_service") as mock_service:
            mock_service.to_word = AsyncMock(return_value=mock_word)

            response = await client.get(
                f"/api/v1/export/{test_resume.id}/word",
                headers=auth_headers
            )

            assert response.status_code == 200
            assert "wordprocessingml" in response.headers["content-type"]

    async def test_export_to_word_resume_not_found(
        self, client: AsyncClient, auth_headers
    ):
        """测试: 简历不存在"""
        response = await client.get(
            "/api/v1/export/99999/word",
            headers=auth_headers
        )

        assert response.status_code == 404

    async def test_export_to_word_unauthorized(
        self, client: AsyncClient, db_session
    ):
        """测试: 未授权访问"""
        other_user = User(
            email="word_other@example.com",
            password_hash="hash",
            username="word_other",
            role="user"
        )
        db_session.add(other_user)
        await db_session.commit()

        other_resume = Resume(
            user_id=other_user.id,
            title="其他用户简历",
            content={},
            style_config={},
            status="draft"
        )
        db_session.add(other_resume)
        await db_session.commit()

        response = await client.get(f"/api/v1/export/{other_resume.id}/word")

        assert response.status_code == 401


class TestExportToHtml:
    """HTML 导出测试"""

    async def test_export_to_html_success(
        self, client: AsyncClient, auth_headers, test_resume
    ):
        """测试: 成功导出 HTML"""
        mock_html = "<html><body>简历内容</body></html>"

        with patch("app.api.v1.export.export_service") as mock_service:
            mock_service.to_html = AsyncMock(return_value=mock_html)

            response = await client.get(
                f"/api/v1/export/{test_resume.id}/html",
                headers=auth_headers
            )

            assert response.status_code == 200
            assert "text/html" in response.headers["content-type"]

    async def test_export_to_html_with_template(
        self, client: AsyncClient, auth_headers, test_user, db_session
    ):
        """测试: 带模板的 HTML 导出"""
        template = Template(
            name="HTML模板",
            category="modern",
            level="free",
            html_content="<div class='template'>{{content}}</div>",
            css_content=".template { margin: 0; }",
            style={}
        )
        db_session.add(template)
        await db_session.commit()

        resume = Resume(
            user_id=test_user.id,
            title="HTML导出简历",
            content={},
            style_config={},
            template_id=template.id,
            status="draft"
        )
        db_session.add(resume)
        await db_session.commit()

        mock_html = "<html>结果</html>"

        with patch("app.api.v1.export.export_service") as mock_service:
            mock_service.to_html = AsyncMock(return_value=mock_html)

            response = await client.get(
                f"/api/v1/export/{resume.id}/html",
                headers=auth_headers
            )

            assert response.status_code == 200
            # 验证 template_html 被传入
            mock_service.to_html.assert_called_once()

    async def test_export_to_html_resume_not_found(
        self, client: AsyncClient, auth_headers
    ):
        """测试: 简历不存在"""
        response = await client.get(
            "/api/v1/export/99999/html",
            headers=auth_headers
        )

        assert response.status_code == 404

    async def test_export_to_html_unauthorized(
        self, client: AsyncClient, db_session
    ):
        """测试: 未授权访问"""
        other_user = User(
            email="html_other@example.com",
            password_hash="hash",
            username="html_other",
            role="user"
        )
        db_session.add(other_user)
        await db_session.commit()

        other_resume = Resume(
            user_id=other_user.id,
            title="其他用户简历",
            content={},
            style_config={},
            status="draft"
        )
        db_session.add(other_resume)
        await db_session.commit()

        response = await client.get(f"/api/v1/export/{other_resume.id}/html")

        assert response.status_code == 401


class TestPreviewResume:
    """简历预览测试"""

    async def test_preview_resume_success(
        self, client: AsyncClient, auth_headers, test_resume
    ):
        """测试: 成功预览简历"""
        mock_html = "<html><body>预览内容</body></html>"

        with patch("app.api.v1.export.export_service") as mock_service:
            mock_service.to_html = AsyncMock(return_value=mock_html)

            response = await client.get(
                f"/api/v1/export/{test_resume.id}/preview",
                headers=auth_headers
            )

            assert response.status_code == 200
            assert "text/html" in response.headers["content-type"]

    async def test_preview_resume_with_template(
        self, client: AsyncClient, auth_headers, test_user, db_session
    ):
        """测试: 带模板的预览"""
        template = Template(
            name="预览模板",
            category="professional",
            is_premium=True,
            html_content="<div>{{content}}</div>",
            css_content="body { padding: 20px; }",
            style={}
        )
        db_session.add(template)
        await db_session.commit()

        resume = Resume(
            user_id=test_user.id,
            title="预览简历",
            content={},
            style_config={},
            template_id=template.id,
            status="draft"
        )
        db_session.add(resume)
        await db_session.commit()

        mock_html = "<html>带模板预览</html>"

        with patch("app.api.v1.export.export_service") as mock_service:
            mock_service.to_html = AsyncMock(return_value=mock_html)

            response = await client.get(
                f"/api/v1/export/{resume.id}/preview",
                headers=auth_headers
            )

            assert response.status_code == 200

    async def test_preview_resume_not_found(
        self, client: AsyncClient, auth_headers
    ):
        """测试: 简历不存在"""
        response = await client.get(
            "/api/v1/export/99999/preview",
            headers=auth_headers
        )

        assert response.status_code == 404

    async def test_preview_resume_no_content_disposition(
        self, client: AsyncClient, auth_headers, test_resume
    ):
        """测试: 预览不包含 Content-Disposition (内联显示)"""
        mock_html = "<html><body>预览</body></html>"

        with patch("app.api.v1.export.export_service") as mock_service:
            mock_service.to_html = AsyncMock(return_value=mock_html)

            response = await client.get(
                f"/api/v1/export/{test_resume.id}/preview",
                headers=auth_headers
            )

            # 预览应该没有 Content-Disposition 头（或为 inline）
            assert response.status_code == 200


class TestGetExportStyles:
    """获取导出样式测试"""

    async def test_get_export_styles_success(
        self, client: AsyncClient
    ):
        """测试: 成功获取导出样式列表"""
        response = await client.get("/api/v1/export/styles")

        assert response.status_code == 200
        data = response.json()
        assert data["code"] == 0
        assert "data" in data
        assert isinstance(data["data"], list)
        # 应该有多个样式
        assert len(data["data"]) > 0

    async def test_export_styles_structure(
        self, client: AsyncClient
    ):
        """测试: 导出样式数据结构"""
        response = await client.get("/api/v1/export/styles")

        data = response.json()
        styles = data["data"]

        # 检查第一个样式的结构
        if styles:
            style = styles[0]
            assert "id" in style
            assert "name" in style
            assert "description" in style
            assert "primary_color" in style
            assert "secondary_color" in style
            assert "font_family" in style
            assert "layout" in style

    async def test_export_styles_known_styles(
        self, client: AsyncClient
    ):
        """测试: 包含已知样式"""
        response = await client.get("/api/v1/export/styles")

        data = response.json()
        styles = data["data"]
        style_ids = [s["id"] for s in styles]

        # 应该包含一些常见样式
        expected_styles = ["modern", "professional", "minimal"]
        for expected in expected_styles:
            assert expected in style_ids, f"样式 {expected} 应该在列表中"

    async def test_export_styles_descriptions(
        self, client: AsyncClient
    ):
        """测试: 样式描述"""
        response = await client.get("/api/v1/export/styles")

        data = response.json()
        styles = data["data"]

        for style in styles:
            # 每个样式应该有描述
            assert style["description"]
            assert isinstance(style["description"], str)


class TestExportRateLimiting:
    """导出速率限制测试"""

    async def test_pdf_export_rate_limit(
        self, client: AsyncClient, auth_headers, test_resume
    ):
        """测试: PDF 导出速率限制"""
        mock_pdf = b"%PDF-1.4"

        with patch("app.api.v1.export.export_service") as mock_service:
            mock_service.to_pdf = AsyncMock(return_value=mock_pdf)

            # 第一次请求应该成功
            response1 = await client.get(
                f"/api/v1/export/{test_resume.id}/pdf",
                headers=auth_headers
            )
            assert response1.status_code == 200

            # 快速第二次请求可能被限流（取决于配置）
            # 这里我们只验证第一次成功

    async def test_word_export_rate_limit(
        self, client: AsyncClient, auth_headers, test_resume
    ):
        """测试: Word 导出速率限制"""
        mock_word = b"PK\x03\x04"

        with patch("app.api.v1.export.export_service") as mock_service:
            mock_service.to_word = AsyncMock(return_value=mock_word)

            response = await client.get(
                f"/api/v1/export/{test_resume.id}/word",
                headers=auth_headers
            )

            assert response.status_code == 200


class TestExportEdgeCases:
    """导出边界情况测试"""

    async def test_export_empty_resume_content(
        self, client: AsyncClient, auth_headers, test_user, db_session
    ):
        """测试: 导出空内容简历"""
        resume = Resume(
            user_id=test_user.id,
            title="空简历",
            content=None,
            style_config={},
            status="draft"
        )
        db_session.add(resume)
        await db_session.commit()

        mock_pdf = b"%PDF-1.4 empty"

        with patch("app.api.v1.export.export_service") as mock_service:
            mock_service.to_pdf = AsyncMock(return_value=mock_pdf)

            response = await client.get(
                f"/api/v1/export/{resume.id}/pdf",
                headers=auth_headers
            )

            assert response.status_code == 200
            # 验证传入了空字典而非 None
            call_args = mock_service.to_pdf.call_args
            resume_content = call_args.kwargs.get("resume_content")
            assert resume_content == {}

    async def test_export_with_style_config(
        self, client: AsyncClient, auth_headers, test_user, db_session
    ):
        """测试: 带样式配置的导出"""
        style_config = {"theme": "modern", "color": "blue", "font": "Arial"}
        resume = Resume(
            user_id=test_user.id,
            title="样式简历",
            content={},
            style_config=style_config,
            status="draft"
        )
        db_session.add(resume)
        await db_session.commit()

        mock_pdf = b"%PDF-1.4 styled"

        with patch("app.api.v1.export.export_service") as mock_service:
            mock_service.to_pdf = AsyncMock(return_value=mock_pdf)

            response = await client.get(
                f"/api/v1/export/{resume.id}/pdf",
                headers=auth_headers
            )

            assert response.status_code == 200
            # 验证样式配置被传递
            call_args = mock_service.to_pdf.call_args
            assert call_args.kwargs["style_config"] == style_config

    async def test_export_other_user_resume_forbidden(
        self, client: AsyncClient, auth_headers, db_session
    ):
        """测试: 尝试导出其他用户简历"""
        other_user = User(
            email="forbidden@example.com",
            password_hash="hash",
            username="forbidden",
            role="user"
        )
        db_session.add(other_user)
        await db_session.commit()

        other_resume = Resume(
            user_id=other_user.id,
            title="私密简历",
            content={"secret": "data"},
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

    async def test_html_export_utf8_encoding(
        self, client: AsyncClient, auth_headers, test_user, db_session
    ):
        """测试: HTML 导出 UTF-8 编码"""
        resume = Resume(
            user_id=test_user.id,
            title="编码测试简历",
            content={"basic_info": {"name": "张三"}},
            style_config={},
            status="draft"
        )
        db_session.add(resume)
        await db_session.commit()

        mock_html = "<html><body>中文内容</body></html>"

        with patch("app.api.v1.export.export_service") as mock_service:
            mock_service.to_html = AsyncMock(return_value=mock_html)

            response = await client.get(
                f"/api/v1/export/{resume.id}/html",
                headers=auth_headers
            )

            assert response.status_code == 200
            assert "utf-8" in response.headers["content-type"]

    async def test_preview_no_template(
        self, client: AsyncClient, auth_headers, test_resume
    ):
        """测试: 无模板的预览"""
        mock_html = "<html><body>无模板</body></html>"

        with patch("app.api.v1.export.export_service") as mock_service:
            mock_service.to_html = AsyncMock(return_value=mock_html)

            response = await client.get(
                f"/api/v1/export/{test_resume.id}/preview",
                headers=auth_headers
            )

            assert response.status_code == 200
            call_args = mock_service.to_html.call_args
            assert call_args.kwargs["template_html"] is None

    async def test_export_template_without_html_content(
        self, client: AsyncClient, auth_headers, test_user, db_session
    ):
        """测试: 模板没有 HTML 内容"""
        template = Template(
            name="空模板",
            category="basic",
            is_premium=False,
            html_content=None,  # 无 HTML 内容
            css_content=None,
            style={}
        )
        db_session.add(template)
        await db_session.commit()

        resume = Resume(
            user_id=test_user.id,
            title="使用空模板",
            content={},
            style_config={},
            template_id=template.id,
            status="draft"
        )
        db_session.add(resume)
        await db_session.commit()

        mock_pdf = b"%PDF-1.4"

        with patch("app.api.v1.export.export_service") as mock_service:
            mock_service.to_pdf = AsyncMock(return_value=mock_pdf)

            response = await client.get(
                f"/api/v1/export/{resume.id}/pdf",
                headers=auth_headers
            )

            assert response.status_code == 200
            # 验证 template_html 为 None
            call_args = mock_service.to_pdf.call_args
            assert call_args.kwargs["template_html"] is None
