"""
Export API 扩展测试 - 针对缺失的特定行
"""
import pytest
from httpx import AsyncClient
from unittest.mock import AsyncMock, patch, MagicMock
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
import io

from app.models.user import User
from app.models.resume import Resume
from app.models.template import Template


class TestExportTemplateHandling:
    """测试模板处理逻辑 (行 45-52)"""

    async def test_pdf_export_with_template_fetch(
        self, client: AsyncClient, auth_headers, test_user, db_session
    ):
        """测试: PDF 导出时正确获取模板"""
        # 创建带有 html_content 的模板
        template = Template(
            name="PDF测试模板",
            category="professional",
            is_premium=False,
            html_content="<div class='resume'>{{name}}</div>",
            css_content=".resume { font-size: 12pt; }",
            style={}
        )
        db_session.add(template)
        await db_session.commit()

        # 使用该模板创建简历
        resume = Resume(
            user_id=test_user.id,
            title="使用模板的简历",
            content={"basic_info": {"name": "张三"}},
            style_config={"theme": "professional"},
            template_id=template.id
        )
        db_session.add(resume)
        await db_session.commit()

        mock_pdf = b"%PDF-1.4 test content"

        with patch("app.api.v1.export.export_service.to_pdf", new_callable=AsyncMock) as mock_to_pdf:
            mock_to_pdf.return_value = mock_pdf

            response = await client.get(
                f"/api/v1/export/{resume.id}/pdf",
                headers=auth_headers
            )

            assert response.status_code == 200
            # 验证模板 HTML 被传递
            mock_to_pdf.assert_called_once()
            call_kwargs = mock_to_pdf.call_args.kwargs
            assert call_kwargs["template_html"] == template.html_content

    async def test_pdf_export_with_null_template_html(
        self, client: AsyncClient, auth_headers, test_user, db_session
    ):
        """测试: 模板存在但 html_content 为 None"""
        template = Template(
            name="空HTML模板",
            category="test",
            is_premium=False,
            html_content=None,  # 关键：HTML 内容为空
            css_content=None,
            style={}
        )
        db_session.add(template)
        await db_session.commit()

        resume = Resume(
            user_id=test_user.id,
            title="空模板简历",
            content={},
            template_id=template.id
        )
        db_session.add(resume)
        await db_session.commit()

        mock_pdf = b"%PDF-1.4"

        with patch("app.api.v1.export.export_service.to_pdf", new_callable=AsyncMock) as mock_to_pdf:
            mock_to_pdf.return_value = mock_pdf

            response = await client.get(
                f"/api/v1/export/{resume.id}/pdf",
                headers=auth_headers
            )

            assert response.status_code == 200
            # 应该传递 None 作为 template_html
            call_kwargs = mock_to_pdf.call_args.kwargs
            assert call_kwargs["template_html"] is None

    async def test_pdf_export_template_not_found(
        self, client: AsyncClient, auth_headers, test_user, db_session
    ):
        """测试: 简历引用了不存在的模板"""
        resume = Resume(
            user_id=test_user.id,
            title="无效模板简历",
            content={},
            template_id=99999  # 不存在的模板 ID
        )
        db_session.add(resume)
        await db_session.commit()

        mock_pdf = b"%PDF-1.4"

        with patch("app.api.v1.export.export_service.to_pdf", new_callable=AsyncMock) as mock_to_pdf:
            mock_to_pdf.return_value = mock_pdf

            response = await client.get(
                f"/api/v1/export/{resume.id}/pdf",
                headers=auth_headers
            )

            assert response.status_code == 200
            # 应该优雅处理，传递 None
            call_kwargs = mock_to_pdf.call_args.kwargs
            assert call_kwargs["template_html"] is None


class TestExportWordWithTemplate:
    """测试 Word 导出 (行 90-105)"""

    async def test_word_export_ignores_template(
        self, client: AsyncClient, auth_headers, test_user, db_session
    ):
        """测试: Word 导出不使用模板 HTML"""
        template = Template(
            name="Word测试模板",
            category="professional",
            is_premium=False,
            html_content="<div>{{name}}</div>",
            css_content="body { }",
            style={}
        )
        db_session.add(template)
        await db_session.commit()

        resume = Resume(
            user_id=test_user.id,
            title="Word导出简历",
            content={"basic_info": {"name": "李四"}},
            template_id=template.id
        )
        db_session.add(resume)
        await db_session.commit()

        mock_word = b"PK\x03\x04 docx content"

        with patch("app.api.v1.export.export_service.to_word", new_callable=AsyncMock) as mock_to_word:
            mock_to_word.return_value = mock_word

            response = await client.get(
                f"/api/v1/export/{resume.id}/word",
                headers=auth_headers
            )

            assert response.status_code == 200
            assert response.headers["content-type"] == "application/vnd.openxmlformats-officedocument.wordprocessingml.document"
            # Word 导出不应该传递模板
            call_kwargs = mock_to_word.call_args.kwargs
            assert "template_html" not in call_kwargs


class TestExportHTMLEncoding:
    """测试 HTML 导出编码 (行 125-151)"""

    async def test_html_export_content_encoding(
        self, client: AsyncClient, auth_headers, test_resume
    ):
        """测试: HTML 导出 UTF-8 编码"""
        mock_html = "<html><head><meta charset='utf-8'></head><body>中文内容</body></html>"

        with patch("app.api.v1.export.export_service.to_html", new_callable=AsyncMock) as mock_to_html:
            mock_to_html.return_value = mock_html

            response = await client.get(
                f"/api/v1/export/{test_resume.id}/html",
                headers=auth_headers
            )

            assert response.status_code == 200
            assert "utf-8" in response.headers["content-type"]
            # 验证响应体是字节
            assert isinstance(response.content, bytes)

    async def test_html_export_with_template_html(
        self, client: AsyncClient, auth_headers, test_user, db_session
    ):
        """测试: HTML 导出使用模板"""
        template = Template(
            name="HTML模板",
            category="modern",
            is_premium=False,
            html_content="<html><body>{{content}}</body></html>",
            css_content="body { padding: 20px; }",
            style={}
        )
        db_session.add(template)
        await db_session.commit()

        resume = Resume(
            user_id=test_user.id,
            title="HTML导出简历",
            content={"basic_info": {"name": "王五"}},
            template_id=template.id
        )
        db_session.add(resume)
        await db_session.commit()

        mock_html = "<html><body>渲染结果</body></html>"

        with patch("app.api.v1.export.export_service.to_html", new_callable=AsyncMock) as mock_to_html:
            mock_to_html.return_value = mock_html

            response = await client.get(
                f"/api/v1/export/{resume.id}/html",
                headers=auth_headers
            )

            assert response.status_code == 200
            call_kwargs = mock_to_html.call_args.kwargs
            assert call_kwargs["template_html"] == template.html_content

    async def test_html_export_special_filename(
        self, client: AsyncClient, auth_headers, test_user, db_session
    ):
        """测试: 特殊字符文件名处理"""
        special_title = '简历"中文"<test>.pdf'
        resume = Resume(
            user_id=test_user.id,
            title=special_title,
            content={}
        )
        db_session.add(resume)
        await db_session.commit()

        mock_html = "<html><body>test</body></html>"

        with patch("app.api.v1.export.export_service.to_html", new_callable=AsyncMock) as mock_to_html:
            mock_to_html.return_value = mock_html

            response = await client.get(
                f"/api/v1/export/{resume.id}/html",
                headers=auth_headers
            )

            assert response.status_code == 200
            # 应该有 Content-Disposition 头
            assert "Content-Disposition" in response.headers


class TestPreviewResume:
    """测试简历预览 (行 171-195)"""

    async def test_preview_inline_display(
        self, client: AsyncClient, auth_headers, test_resume
    ):
        """测试: 预览应该是内联显示，不带下载"""
        mock_html = "<html><body>预览内容</body></html>"

        with patch("app.api.v1.export.export_service.to_html", new_callable=AsyncMock) as mock_to_html:
            mock_to_html.return_value = mock_html

            response = await client.get(
                f"/api/v1/export/{test_resume.id}/preview",
                headers=auth_headers
            )

            assert response.status_code == 200
            assert "text/html" in response.headers["content-type"]
            # 预览不应该有 attachment 的 Content-Disposition
            content_disposition = response.headers.get("Content-Disposition", "")
            assert "attachment" not in content_disposition

    async def test_preview_with_template(
        self, client: AsyncClient, auth_headers, test_user, db_session
    ):
        """测试: 预览使用模板"""
        template = Template(
            name="预览模板",
            category="minimal",
            is_premium=False,
            html_content="<div class='preview'>{{content}}</div>",
            css_content=".preview { background: #fff; }",
            style={}
        )
        db_session.add(template)
        await db_session.commit()

        resume = Resume(
            user_id=test_user.id,
            title="预览简历",
            content={},
            template_id=template.id
        )
        db_session.add(resume)
        await db_session.commit()

        mock_html = "<html><body>预览</body></html>"

        with patch("app.api.v1.export.export_service.to_html", new_callable=AsyncMock) as mock_to_html:
            mock_to_html.return_value = mock_html

            response = await client.get(
                f"/api/v1/export/{resume.id}/preview",
                headers=auth_headers
            )

            assert response.status_code == 200
            call_kwargs = mock_to_html.call_args.kwargs
            assert call_kwargs["template_html"] == template.html_content


class TestExportStyles:
    """测试导出样式获取 (行 204-233)"""

    async def test_get_styles_structure(
        self, client: AsyncClient
    ):
        """测试: 获取样式列表的结构"""
        response = await client.get("/api/v1/export/styles")

        assert response.status_code == 200
        data = response.json()
        assert data["code"] == 0
        assert "data" in data
        assert isinstance(data["data"], list)

    async def test_get_styles_known_ids(
        self, client: AsyncClient
    ):
        """测试: 包含预期的样式 ID"""
        response = await client.get("/api/v1/export/styles")

        assert response.status_code == 200
        data = response.json()

        style_ids = [s["id"] for s in data["data"]]
        # 验证有一些常见的样式
        expected_styles = ["modern", "professional", "minimal", "creative"]
        for style_id in expected_styles:
            assert style_id in style_ids

    async def test_get_style_fields_complete(
        self, client: AsyncClient
    ):
        """测试: 每个样式包含完整字段"""
        response = await client.get("/api/v1/export/styles")

        assert response.status_code == 200
        data = response.json()

        for style in data["data"]:
            assert "id" in style
            assert "name" in style
            assert "description" in style
            assert "primary_color" in style
            assert "secondary_color" in style
            assert "font_family" in style
            assert "layout" in style

    async def test_get_styles_no_auth_required(
        self, client: AsyncClient
    ):
        """测试: 获取样式不需要认证"""
        # 不带认证头访问
        response = await client.get("/api/v1/export/styles")
        assert response.status_code == 200


class TestExportErrorHandling:
    """测试错误处理"""

    async def test_pdf_export_service_exception(
        self, client: AsyncClient, auth_headers, test_resume
    ):
        """测试: PDF 导出服务异常"""
        with patch("app.api.v1.export.export_service.to_pdf", new_callable=AsyncMock) as mock_to_pdf:
            mock_to_pdf.side_effect = Exception("生成 PDF 失败")

            response = await client.get(
                f"/api/v1/export/{test_resume.id}/pdf",
                headers=auth_headers
            )

            assert response.status_code == 500
            data = response.json()
            assert "生成 PDF 失败" in data["detail"]


class TestExportContentVariations:
    """测试不同内容类型的导出"""

    async def test_export_empty_content(
        self, client: AsyncClient, auth_headers, test_user, db_session
    ):
        """测试: 导出空内容简历"""
        resume = Resume(
            user_id=test_user.id,
            title="空内容",
            content=None,
            style_config=None
        )
        db_session.add(resume)
        await db_session.commit()

        mock_pdf = b"%PDF-1.4 empty"

        with patch("app.api.v1.export.export_service.to_pdf", new_callable=AsyncMock) as mock_to_pdf:
            mock_to_pdf.return_value = mock_pdf

            response = await client.get(
                f"/api/v1/export/{resume.id}/pdf",
                headers=auth_headers
            )

            assert response.status_code == 200
            # 应该传递空字典
            call_kwargs = mock_to_pdf.call_args.kwargs
            assert call_kwargs["resume_content"] == {}

    async def test_export_with_style_config(
        self, client: AsyncClient, auth_headers, test_user, db_session
    ):
        """测试: 导出带样式配置的简历"""
        style_config = {
            "theme": "modern",
            "primary_color": "#2563eb",
            "font_size": 12
        }
        resume = Resume(
            user_id=test_user.id,
            title="带样式简历",
            content={"basic_info": {"name": "样式测试"}},
            style_config=style_config
        )
        db_session.add(resume)
        await db_session.commit()

        mock_pdf = b"%PDF-1.4 styled"

        with patch("app.api.v1.export.export_service.to_pdf", new_callable=AsyncMock) as mock_to_pdf:
            mock_to_pdf.return_value = mock_pdf

            response = await client.get(
                f"/api/v1/export/{resume.id}/pdf",
                headers=auth_headers
            )

            assert response.status_code == 200
            call_kwargs = mock_to_pdf.call_args.kwargs
            assert call_kwargs["style_config"] == style_config
