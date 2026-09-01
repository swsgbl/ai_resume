"""
Export API 综合测试 - 针对缺失覆盖行
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


class TestExportToPdfComprehensive:
    """PDF 导出综合测试"""

    async def test_export_pdf_with_template_html(
        self, client: AsyncClient, auth_headers, test_user, db_session
    ):
        """测试: 使用带 HTML 内容的模板导出 PDF"""
        template = Template(
            name="PDF模板",
            category="test",
            is_premium=False,
            html_content="<div class='template'>{{content}}</div>",
            css_content=".template { color: blue; }",
            style={}
        )
        db_session.add(template)
        await db_session.commit()

        resume = Resume(
            user_id=test_user.id,
            title="PDF测试简历",
            content={"basic_info": {"name": "测试"}},
            style_config={},
            template_id=template.id
        )
        db_session.add(resume)
        await db_session.commit()

        mock_pdf = b"%PDF-1.4 test pdf content"

        with patch("app.api.v1.export.export_service") as mock_service:
            mock_service.to_pdf = AsyncMock(return_value=mock_pdf)

            response = await client.get(
                f"/api/v1/export/{resume.id}/pdf",
                headers=auth_headers
            )

            assert response.status_code == 200
            # 验证传入了模板 HTML
            mock_service.to_pdf.assert_called_once()
            call_kwargs = mock_service.to_pdf.call_args.kwargs
            assert call_kwargs["template_html"] == template.html_content

    async def test_export_pdf_with_empty_content(
        self, client: AsyncClient, auth_headers, test_user, db_session
    ):
        """测试: 简历内容为空时导出"""
        resume = Resume(
            user_id=test_user.id,
            title="空内容简历",
            content=None,
            style_config={},
            template_id=None
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
            call_kwargs = mock_service.to_pdf.call_args.kwargs
            assert call_kwargs["resume_content"] == {}

    async def test_export_pdf_with_style_config(
        self, client: AsyncClient, auth_headers, test_user, db_session
    ):
        """测试: 使用样式配置导出"""
        style_config = {"theme": "modern", "color": "#2B2B2B", "font": "Arial"}
        resume = Resume(
            user_id=test_user.id,
            title="样式测试简历",
            content={"basic_info": {"name": "样式"}},
            style_config=style_config,
            template_id=None
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
            # 验证传入了样式配置
            call_kwargs = mock_service.to_pdf.call_args.kwargs
            assert call_kwargs["style_config"] == style_config

    async def test_export_pdf_service_error(
        self, client: AsyncClient, auth_headers, test_resume
    ):
        """测试: 导出服务返回错误"""
        with patch("app.api.v1.export.export_service") as mock_service:
            mock_service.to_pdf = AsyncMock(side_effect=Exception("导出失败"))

            response = await client.get(
                f"/api/v1/export/{test_resume.id}/pdf",
                headers=auth_headers
            )

            assert response.status_code == 500
            data = response.json()
            assert "导出失败" in data["detail"]

    async def test_export_pdf_chinese_filename(
        self, client: AsyncClient, auth_headers, test_user, db_session
    ):
        """测试: 中文文件名正确编码"""
        resume = Resume(
            user_id=test_user.id,
            title="中文简历名称",
            content={},
            style_config={}
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
            # 验证 Content-Disposition 头存在
            assert "Content-Disposition" in response.headers


class TestExportToWordComprehensive:
    """Word 导出综合测试"""

    async def test_export_word_success(
        self, client: AsyncClient, auth_headers, test_resume
    ):
        """测试: 成功导出 Word"""
        mock_word = b"PK\x03\x04 fake docx content"

        with patch("app.api.v1.export.export_service") as mock_service:
            mock_service.to_word = AsyncMock(return_value=mock_word)

            response = await client.get(
                f"/api/v1/export/{test_resume.id}/word",
                headers=auth_headers
            )

            assert response.status_code == 200
            assert response.headers["content-type"] == "application/vnd.openxmlformats-officedocument.wordprocessingml.document"

    async def test_export_word_with_content(
        self, client: AsyncClient, auth_headers, test_user, db_session
    ):
        """测试: 带内容的 Word 导出"""
        resume = Resume(
            user_id=test_user.id,
            title="Word测试",
            content={
                "basic_info": {"name": "张三"},
                "work_experience": [{"company": "ABC公司"}]
            },
            style_config={"theme": "professional"}
        )
        db_session.add(resume)
        await db_session.commit()

        mock_word = b"PK\x03\x04 docx with content"

        with patch("app.api.v1.export.export_service") as mock_service:
            mock_service.to_word = AsyncMock(return_value=mock_word)

            response = await client.get(
                f"/api/v1/export/{resume.id}/word",
                headers=auth_headers
            )

            assert response.status_code == 200
            # 验证传入了正确的内容
            call_kwargs = mock_service.to_word.call_args.kwargs
            assert "work_experience" in call_kwargs["resume_content"]

    async def test_export_word_with_empty_style(
        self, client: AsyncClient, auth_headers, test_user, db_session
    ):
        """测试: 空样式配置导出"""
        resume = Resume(
            user_id=test_user.id,
            title="无样式简历",
            content={},
            style_config=None
        )
        db_session.add(resume)
        await db_session.commit()

        mock_word = b"PK\x03\x04 no style"

        with patch("app.api.v1.export.export_service") as mock_service:
            mock_service.to_word = AsyncMock(return_value=mock_word)

            response = await client.get(
                f"/api/v1/export/{resume.id}/word",
                headers=auth_headers
            )

            assert response.status_code == 200
            # 空样式配置应该被处理为 None 或 {}
            call_kwargs = mock_service.to_word.call_args.kwargs
            assert call_kwargs.get("style_config") is None or call_kwargs.get("style_config") == {}


class TestExportToHtmlComprehensive:
    """HTML 导出综合测试"""

    async def test_export_html_with_template(
        self, client: AsyncClient, auth_headers, test_user, db_session
    ):
        """测试: 使用模板导出 HTML"""
        template = Template(
            name="HTML模板",
            category="test",
            is_premium=False,
            html_content="<div>{{content}}</div>",
            css_content="body { margin: 0; }",
            style={}
        )
        db_session.add(template)
        await db_session.commit()

        resume = Resume(
            user_id=test_user.id,
            title="HTML导出测试",
            content={"basic_info": {"name": "HTML"}},
            style_config={},
            template_id=template.id
        )
        db_session.add(resume)
        await db_session.commit()

        mock_html = "<html><body>HTML内容</body></html>"

        with patch("app.api.v1.export.export_service") as mock_service:
            mock_service.to_html = AsyncMock(return_value=mock_html)

            response = await client.get(
                f"/api/v1/export/{resume.id}/html",
                headers=auth_headers
            )

            assert response.status_code == 200
            assert "text/html" in response.headers["content-type"]
            # 验证使用了模板 HTML
            call_kwargs = mock_service.to_html.call_args.kwargs
            assert call_kwargs["template_html"] == template.html_content

    async def test_export_html_no_template(
        self, client: AsyncClient, auth_headers, test_resume
    ):
        """测试: 无模板导出 HTML"""
        mock_html = "<html><body>无模板内容</body></html>"

        with patch("app.api.v1.export.export_service") as mock_service:
            mock_service.to_html = AsyncMock(return_value=mock_html)

            response = await client.get(
                f"/api/v1/export/{test_resume.id}/html",
                headers=auth_headers
            )

            assert response.status_code == 200
            # 验证没有模板 HTML
            call_kwargs = mock_service.to_html.call_args.kwargs
            assert call_kwargs["template_html"] is None

    async def test_export_html_encoding(
        self, client: AsyncClient, auth_headers, test_resume
    ):
        """测试: HTML 导出 UTF-8 编码"""
        mock_html = "<html><body>中文内容测试</body></html>"

        with patch("app.api.v1.export.export_service") as mock_service:
            mock_service.to_html = AsyncMock(return_value=mock_html)

            response = await client.get(
                f"/api/v1/export/{test_resume.id}/html",
                headers=auth_headers
            )

            assert response.status_code == 200
            assert "utf-8" in response.headers["content-type"]


class TestPreviewResumeComprehensive:
    """简历预览综合测试"""

    async def test_preview_with_template(
        self, client: AsyncClient, auth_headers, test_user, db_session
    ):
        """测试: 使用模板预览"""
        template = Template(
            name="预览模板",
            category="test",
            is_premium=False,
            html_content="<div class='preview'>{{content}}</div>",
            css_content=".preview { background: #fff; }",
            style={}
        )
        db_session.add(template)
        await db_session.commit()

        resume = Resume(
            user_id=test_user.id,
            title="预览测试",
            content={},
            style_config={},
            template_id=template.id
        )
        db_session.add(resume)
        await db_session.commit()

        mock_html = "<html><body>预览内容</body></html>"

        with patch("app.api.v1.export.export_service") as mock_service:
            mock_service.to_html = AsyncMock(return_value=mock_html)

            response = await client.get(
                f"/api/v1/export/{resume.id}/preview",
                headers=auth_headers
            )

            assert response.status_code == 200
            # 验证使用了模板 HTML
            call_kwargs = mock_service.to_html.call_args.kwargs
            assert call_kwargs["template_html"] == template.html_content

    async def test_preview_no_content_disposition(
        self, client: AsyncClient, auth_headers, test_resume
    ):
        """测试: 预览不包含 Content-Disposition（内联显示）"""
        mock_html = "<html><body>内联预览</body></html>"

        with patch("app.api.v1.export.export_service") as mock_service:
            mock_service.to_html = AsyncMock(return_value=mock_html)

            response = await client.get(
                f"/api/v1/export/{test_resume.id}/preview",
                headers=auth_headers
            )

            assert response.status_code == 200
            # 预览应该没有 attachment Content-Disposition 或为 inline
            content_disposition = response.headers.get("Content-Disposition", "")
            assert "attachment" not in content_disposition or "inline" in content_disposition


class TestGetExportStylesComprehensive:
    """获取导出样式综合测试"""

    async def test_get_styles_response_structure(
        self, client: AsyncClient
    ):
        """测试: 获取样式响应结构"""
        response = await client.get("/api/v1/export/styles")

        assert response.status_code == 200
        data = response.json()
        assert data["code"] == 0
        assert "data" in data
        assert isinstance(data["data"], list)

    async def test_get_styles_content_fields(
        self, client: AsyncClient
    ):
        """测试: 样式内容字段完整"""
        response = await client.get("/api/v1/export/styles")

        assert response.status_code == 200
        data = response.json()

        for style in data["data"]:
            # 验证必需字段
            assert "id" in style
            assert "name" in style
            assert "description" in style
            assert "primary_color" in style
            assert "secondary_color" in style
            assert "font_family" in style
            assert "layout" in style

    async def test_get_styles_known_styles(
        self, client: AsyncClient
    ):
        """测试: 包含已知样式"""
        response = await client.get("/api/v1/export/styles")

        assert response.status_code == 200
        data = response.json()

        style_ids = [s["id"] for s in data["data"]]
        # 应该包含一些常见样式
        expected_styles = ["modern", "professional", "minimal", "creative"]
        for expected in expected_styles:
            assert expected in style_ids, f"样式 {expected} 应该在列表中"

    async def test_get_styles_color_formats(
        self, client: AsyncClient
    ):
        """测试: 颜色格式正确"""
        response = await client.get("/api/v1/export/styles")

        assert response.status_code == 200
        data = response.json()

        for style in data["data"]:
            # 颜色应该是十六进制格式
            primary_color = style["primary_color"]
            assert primary_color.startswith("#") or primary_color.startswith("rgb")

    async def test_get_styles_no_auth_required(
        self, client: AsyncClient
    ):
        """测试: 获取样式不需要认证"""
        response = await client.get("/api/v1/export/styles")

        # 不需要认证
        assert response.status_code == 200


class TestExportEdgeCases:
    """导出边界情况测试"""

    async def test_export_nonexistent_resume(
        self, client: AsyncClient, auth_headers
    ):
        """测试: 导出不存在的简历"""
        response = await client.get(
            "/api/v1/export/99999/pdf",
            headers=auth_headers
        )

        assert response.status_code == 404

    async def test_export_other_user_resume(
        self, client: AsyncClient, auth_headers, db_session
    ):
        """测试: 尝试导出其他用户的简历"""
        other_user = User(
            email="export_other@example.com",
            password_hash="hash",
            username="export_other",
            role="user"
        )
        db_session.add(other_user)
        await db_session.commit()

        other_resume = Resume(
            user_id=other_user.id,
            title="其他用户简历",
            content={"secret": "data"},
            style_config={}
        )
        db_session.add(other_resume)
        await db_session.commit()

        response = await client.get(
            f"/api/v1/export/{other_resume.id}/pdf",
            headers=auth_headers
        )

        assert response.status_code == 404

    async def test_export_word_nonexistent_resume(
        self, client: AsyncClient, auth_headers
    ):
        """测试: Word 导出不存在的简历"""
        response = await client.get(
            "/api/v1/export/99999/word",
            headers=auth_headers
        )

        assert response.status_code == 404

    async def test_export_html_nonexistent_resume(
        self, client: AsyncClient, auth_headers
    ):
        """测试: HTML 导出不存在的简历"""
        response = await client.get(
            "/api/v1/export/99999/html",
            headers=auth_headers
        )

        assert response.status_code == 404

    async def test_preview_nonexistent_resume(
        self, client: AsyncClient, auth_headers
    ):
        """测试: 预览不存在的简历"""
        response = await client.get(
            "/api/v1/export/99999/preview",
            headers=auth_headers
        )

        assert response.status_code == 404

    async def test_all_exports_require_auth(
        self, client: AsyncClient
    ):
        """测试: 所有导出端点都需要认证"""
        endpoints = [
            "/api/v1/export/1/pdf",
            "/api/v1/export/1/word",
            "/api/v1/export/1/html",
            "/api/v1/export/1/preview"
        ]

        for endpoint in endpoints:
            response = await client.get(endpoint)
            assert response.status_code == 401, f"{endpoint} 应该需要认证"
