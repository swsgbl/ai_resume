"""
Export API 集成测试 - 完整流程测试
"""
import pytest
from httpx import AsyncClient
from unittest.mock import AsyncMock, patch, MagicMock
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select

from app.models.user import User
from app.models.resume import Resume
from app.models.template import Template


class TestExportAPIRealFlow:
    """测试 Export API 实际代码流程"""

    async def test_pdf_export_with_mock_service(
        self, client: AsyncClient, auth_headers, test_user, db_session
    ):
        """测试: PDF 导出 - mock export_service 返回值"""
        resume = Resume(
            user_id=test_user.id,
            title="完整流程测试简历",
            content={"basic_info": {"name": "测试用户"}},
            style_config={"theme": "modern"}
        )
        db_session.add(resume)
        await db_session.commit()

        # Mock export_service 方法返回值
        with patch("app.api.v1.export.export_service") as mock_service:
            mock_service.to_pdf = AsyncMock(return_value=b"%PDF-1.4 test content")

            response = await client.get(
                f"/api/v1/export/{resume.id}/pdf",
                headers=auth_headers
            )

        assert response.status_code == 200
        assert response.headers["content-type"] == "application/pdf"
        # 验证传入了正确的参数
        mock_service.to_pdf.assert_called_once()
        call_kwargs = mock_service.to_pdf.call_args.kwargs
        assert "resume_content" in call_kwargs
        assert "style_config" in call_kwargs

    async def test_pdf_export_with_template_check(
        self, client: AsyncClient, auth_headers, test_user, db_session
    ):
        """测试: PDF 导出时正确处理模板"""
        # 创建模板
        template = Template(
            name="测试模板",
            category="professional",
            is_premium=False,
            html_content="<div>{{name}}</div>",
            css_content=".test { color: blue; }",
            style={}
        )
        db_session.add(template)
        await db_session.commit()

        # 创建使用模板的简历
        resume = Resume(
            user_id=test_user.id,
            title="模板简历",
            content={"basic_info": {"name": "模板用户"}},
            template_id=template.id
        )
        db_session.add(resume)
        await db_session.commit()

        # Mock export_service
        with patch("app.api.v1.export.export_service") as mock_service:
            mock_service.to_pdf = AsyncMock(return_value=b"%PDF-1.4")

            response = await client.get(
                f"/api/v1/export/{resume.id}/pdf",
                headers=auth_headers
            )

        assert response.status_code == 200
        # 验证传入了模板 HTML
        call_kwargs = mock_service.to_pdf.call_args.kwargs
        assert "template_html" in call_kwargs

    async def test_word_export_params(
        self, client: AsyncClient, auth_headers, test_user, db_session
    ):
        """测试: Word 导出参数传递"""
        resume = Resume(
            user_id=test_user.id,
            title="Word导出测试",
            content={"basic_info": {"name": "Word用户"}},
            style_config={"theme": "professional"}
        )
        db_session.add(resume)
        await db_session.commit()

        with patch("app.api.v1.export.export_service") as mock_service:
            mock_service.to_word = AsyncMock(return_value=b"PK\x03\x04 docx")

            response = await client.get(
                f"/api/v1/export/{resume.id}/word",
                headers=auth_headers
            )

        assert response.status_code == 200
        # 验证参数
        call_kwargs = mock_service.to_word.call_args.kwargs
        assert "resume_content" in call_kwargs
        assert "style_config" in call_kwargs

    async def test_html_export_params(
        self, client: AsyncClient, auth_headers, test_user, db_session
    ):
        """测试: HTML 导出参数传递"""
        resume = Resume(
            user_id=test_user.id,
            title="HTML导出测试",
            content={"basic_info": {"name": "HTML用户"}},
            style_config={"theme": "minimal"}
        )
        db_session.add(resume)
        await db_session.commit()

        with patch("app.api.v1.export.export_service") as mock_service:
            mock_service.to_html = AsyncMock(return_value="<html><body>test</body></html>")

            response = await client.get(
                f"/api/v1/export/{resume.id}/html",
                headers=auth_headers
            )

        assert response.status_code == 200
        call_kwargs = mock_service.to_html.call_args.kwargs
        assert "template_html" in call_kwargs

    async def test_preview_params(
        self, client: AsyncClient, auth_headers, test_user, db_session
    ):
        """测试: 预览参数传递"""
        resume = Resume(
            user_id=test_user.id,
            title="预览测试简历",
            content={"basic_info": {"name": "预览用户"}},
            style_config={}
        )
        db_session.add(resume)
        await db_session.commit()

        with patch("app.api.v1.export.export_service") as mock_service:
            mock_service.to_html = AsyncMock(return_value="<html><body>preview</body></html>")

            response = await client.get(
                f"/api/v1/export/{resume.id}/preview",
                headers=auth_headers
            )

        assert response.status_code == 200
        # 预览不应该有 Content-Disposition attachment
        content_disposition = response.headers.get("Content-Disposition", "")
        assert "attachment" not in content_disposition

    async def test_export_error_handling(
        self, client: AsyncClient, auth_headers, test_resume
    ):
        """测试: 导出服务异常处理"""
        with patch("app.api.v1.export.export_service") as mock_service:
            mock_service.to_pdf = AsyncMock(side_effect=Exception("生成失败"))

            response = await client.get(
                f"/api/v1/export/{test_resume.id}/pdf",
                headers=auth_headers
            )

        assert response.status_code == 500
        data = response.json()
        assert "生成失败" in data["detail"]

    async def test_export_checks_ownership(
        self, client: AsyncClient, auth_headers, db_session
    ):
        """测试: 导出检查简历所有权"""
        other_user = User(
            email="other_owner@example.com",
            password_hash="hash",
            username="other_owner",
            role="user"
        )
        db_session.add(other_user)
        await db_session.commit()

        other_resume = Resume(
            user_id=other_user.id,
            title="其他用户简历",
            content={}
        )
        db_session.add(other_resume)
        await db_session.commit()

        response = await client.get(
            f"/api/v1/export/{other_resume.id}/pdf",
            headers=auth_headers
        )

        assert response.status_code == 404

    async def test_export_nonexistent_resume(
        self, client: AsyncClient, auth_headers
    ):
        """测试: 导出不存在的简历"""
        response = await client.get(
            "/api/v1/export/99999/pdf",
            headers=auth_headers
        )

        assert response.status_code == 404

    async def test_export_with_null_content(
        self, client: AsyncClient, auth_headers, test_user, db_session
    ):
        """测试: 处理空内容"""
        resume = Resume(
            user_id=test_user.id,
            title="空内容简历",
            content=None,
            style_config=None
        )
        db_session.add(resume)
        await db_session.commit()

        with patch("app.api.v1.export.export_service") as mock_service:
            mock_service.to_pdf = AsyncMock(return_value=b"%PDF-1.4")

            response = await client.get(
                f"/api/v1/export/{resume.id}/pdf",
                headers=auth_headers
            )

        assert response.status_code == 200
        # 验证空内容被转换为空字典
        call_kwargs = mock_service.to_pdf.call_args.kwargs
        assert call_kwargs["resume_content"] == {}

    async def test_template_not_found_handling(
        self, client: AsyncClient, auth_headers, test_user, db_session
    ):
        """测试: 模板不存在时的处理"""
        resume = Resume(
            user_id=test_user.id,
            title="无效模板简历",
            content={},
            template_id=99999  # 不存在的模板
        )
        db_session.add(resume)
        await db_session.commit()

        with patch("app.api.v1.export.export_service") as mock_service:
            mock_service.to_pdf = AsyncMock(return_value=b"%PDF-1.4")

            response = await client.get(
                f"/api/v1/export/{resume.id}/pdf",
                headers=auth_headers
            )

        assert response.status_code == 200
        # 应该传递 None 作为 template_html
        call_kwargs = mock_service.to_pdf.call_args.kwargs
        assert call_kwargs["template_html"] is None

    async def test_template_with_null_html(
        self, client: AsyncClient, auth_headers, test_user, db_session
    ):
        """测试: 模板 HTML 为空时的处理"""
        template = Template(
            name="空HTML模板",
            category="test",
            is_premium=False,
            html_content=None,  # 关键：HTML 内容为空
            css_content=None
        )
        db_session.add(template)
        await db_session.commit()

        resume = Resume(
            user_id=test_user.id,
            title="空HTML模板简历",
            content={},
            template_id=template.id
        )
        db_session.add(resume)
        await db_session.commit()

        with patch("app.api.v1.export.export_service") as mock_service:
            mock_service.to_pdf = AsyncMock(return_value=b"%PDF-1.4")

            response = await client.get(
                f"/api/v1/export/{resume.id}/pdf",
                headers=auth_headers
            )

        assert response.status_code == 200
        call_kwargs = mock_service.to_pdf.call_args.kwargs
        assert call_kwargs["template_html"] is None

    async def test_get_styles_response(
        self, client: AsyncClient
    ):
        """测试: 获取样式列表"""
        response = await client.get("/api/v1/export/styles")

        assert response.status_code == 200
        data = response.json()
        assert "data" in data
        assert isinstance(data["data"], list)
        
        # 验证样式结构
        for style in data["data"]:
            assert "id" in style
            assert "name" in style
            assert "primary_color" in style

    async def test_export_requires_auth(
        self, client: AsyncClient
    ):
        """测试: 导出需要认证"""
        response = await client.get("/api/v1/export/1/pdf")
        assert response.status_code == 401

    async def test_word_export_content_type(
        self, client: AsyncClient, auth_headers, test_resume
    ):
        """测试: Word 导出内容类型"""
        with patch("app.api.v1.export.export_service") as mock_service:
            mock_service.to_word = AsyncMock(return_value=b"PK\x03\x04 docx")

            response = await client.get(
                f"/api/v1/export/{test_resume.id}/word",
                headers=auth_headers
            )

        assert response.status_code == 200
        assert "wordprocessingml" in response.headers["content-type"]

    async def test_html_export_encoding(
        self, client: AsyncClient, auth_headers, test_resume
    ):
        """测试: HTML 导出 UTF-8 编码"""
        with patch("app.api.v1.export.export_service") as mock_service:
            mock_service.to_html = AsyncMock(return_value="<html>中文</html>")

            response = await client.get(
                f"/api/v1/export/{test_resume.id}/html",
                headers=auth_headers
            )

        assert response.status_code == 200
        assert "utf-8" in response.headers["content-type"]

    async def test_filename_encoding(
        self, client: AsyncClient, auth_headers, test_user, db_session
    ):
        """测试: 文件名编码"""
        resume = Resume(
            user_id=test_user.id,
            title="中文文件名",
            content={}
        )
        db_session.add(resume)
        await db_session.commit()

        with patch("app.api.v1.export.export_service") as mock_service:
            mock_service.to_pdf = AsyncMock(return_value=b"%PDF-1.4")

            response = await client.get(
                f"/api/v1/export/{resume.id}/pdf",
                headers=auth_headers
            )

        assert response.status_code == 200
        assert "Content-Disposition" in response.headers
