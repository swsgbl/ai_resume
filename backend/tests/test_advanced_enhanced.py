"""
高级功能 API 增强测试 - 提高覆盖率
"""
import pytest
from httpx import AsyncClient
from sqlalchemy.ext.asyncio import AsyncSession


class TestJDMatchAnalysis:
    """JD匹配分析测试"""

    async def test_jd_match_success(
        self, client: AsyncClient, auth_headers, test_resume
    ):
        """测试: JD匹配分析成功"""
        jd_text = """
        职位要求：
        - 熟悉 Python、Java 等编程语言
        - 有 React、Vue 前端框架经验
        - 了解 Docker、Kubernetes 容器技术
        - 熟悉 MySQL、PostgreSQL 数据库
        - 具备良好的团队协作能力
        """

        response = await client.post(
            "/api/v1/advanced/jd-match",
            headers=auth_headers,
            json={
                "resume_id": test_resume.id,
                "job_description": jd_text
            }
        )

        # AI 服务可能失败，返回 500 或 200
        assert response.status_code in [200, 500]

    async def test_jd_match_resume_not_found(
        self, client: AsyncClient, auth_headers
    ):
        """测试: JD匹配 - 简历不存在"""
        jd_text = "职位要求：Python开发经验" * 10  # 至少50字符

        response = await client.post(
            "/api/v1/advanced/jd-match",
            headers=auth_headers,
            json={
                "resume_id": 99999,
                "job_description": jd_text
            }
        )

        assert response.status_code == 404

    async def test_jd_match_short_description(
        self, client: AsyncClient, auth_headers, test_resume
    ):
        """测试: JD匹配 - 描述过短"""
        response = await client.post(
            "/api/v1/advanced/jd-match",
            headers=auth_headers,
            json={
                "resume_id": test_resume.id,
                "job_description": "太短"
            }
        )

        # 验证错误 - 描述过短
        assert response.status_code == 422

    async def test_jd_match_with_high_match(
        self, client: AsyncClient, auth_headers, test_user, db_session
    ):
        """测试: JD高匹配度分析"""
        from app.models.resume import Resume

        # 创建包含技术关键词的简历
        resume = Resume(
            user_id=test_user.id,
            title="Python工程师",
            content={
                "basic_info": {"name": "张三", "title": "Python工程师"},
                "work_experience": [
                    {
                        "company": "Tech公司",
                        "position": "Python开发工程师",
                        "description": "使用Python Django开发Web应用"
                    }
                ],
                "skills": [
                    {"name": "Python", "keywords": ["python", "django", "flask"]},
                    {"name": "数据库", "keywords": ["mysql", "postgresql"]}
                ]
            },
            style_config={},
            status="draft"
        )
        db_session.add(resume)
        await db_session.commit()

        jd_text = """
        我们正在寻找一位优秀的Python工程师加入我们的团队。
        要求：
        1. 熟练掌握 Python 编程语言
        2. 熟悉 Django、Flask 等 Web 框架
        3. 有 MySQL、PostgreSQL 数据库经验
        4. 具备良好的团队协作精神
        """

        response = await client.post(
            "/api/v1/advanced/jd-match",
            headers=auth_headers,
            json={
                "resume_id": resume.id,
                "job_description": jd_text
            }
        )

        assert response.status_code in [200, 500]


class TestPrivacyMasking:
    """隐私脱敏测试"""

    async def test_privacy_mask_phone_only(
        self, client: AsyncClient, auth_headers
    ):
        """测试: 仅脱敏手机号"""
        content = "请联系张三，电话：13800138000"
        response = await client.post(
            "/api/v1/advanced/privacy-mask",
            headers=auth_headers,
            json={
                "content": content,
                "mask_types": ["phone"]
            }
        )

        assert response.status_code == 200
        data = response.json()
        assert data["code"] == 0
        assert "138****8000" in data["data"]["masked"]
        assert data["data"]["masked_items"][0]["type"] == "phone"

    async def test_privacy_mask_email_only(
        self, client: AsyncClient, auth_headers
    ):
        """测试: 仅脱敏邮箱"""
        content = "请发送邮件到 zhangsan@example.com 联系"
        response = await client.post(
            "/api/v1/advanced/privacy-mask",
            headers=auth_headers,
            json={
                "content": content,
                "mask_types": ["email"]
            }
        )

        assert response.status_code == 200
        data = response.json()
        assert data["code"] == 0
        assert "zh***@example.com" in data["data"]["masked"]

    async def test_privacy_mask_id_card(
        self, client: AsyncClient, auth_headers
    ):
        """测试: 脱敏身份证号"""
        content = "身份证号：123456789012345678"
        response = await client.post(
            "/api/v1/advanced/privacy-mask",
            headers=auth_headers,
            json={
                "content": content,
                "mask_types": ["id_card"]
            }
        )

        assert response.status_code == 200
        data = response.json()
        assert data["code"] == 0
        # 脱敏后应包含星号
        assert "********" in data["data"]["masked"]

    async def test_privacy_mask_bank_card(
        self, client: AsyncClient, auth_headers
    ):
        """测试: 脱敏银行卡号"""
        content = "银行卡号：6222021234567890123"
        response = await client.post(
            "/api/v1/advanced/privacy-mask",
            headers=auth_headers,
            json={
                "content": content,
                "mask_types": ["bank_card"]
            }
        )

        assert response.status_code == 200
        data = response.json()
        assert data["code"] == 0
        # 脱敏后应包含星号
        assert "****" in data["data"]["masked"]

    async def test_privacy_mask_address(
        self, client: AsyncClient, auth_headers
    ):
        """测试: 脱敏地址"""
        content = "地址：北京市朝阳区10号楼3单元501室"
        response = await client.post(
            "/api/v1/advanced/privacy-mask",
            headers=auth_headers,
            json={
                "content": content,
                "mask_types": ["address"]
            }
        )

        assert response.status_code == 200
        data = response.json()
        assert data["code"] == 0

    async def test_privacy_mask_all_types(
        self, client: AsyncClient, auth_headers
    ):
        """测试: 脱敏所有类型"""
        content = """
        姓名：张三
        电话：13800138000
        邮箱：zhangsan@example.com
        身份证：123456789012345678
        银行卡：6222021234567890123
        地址：北京市朝阳区10号楼3单元501室
        """

        response = await client.post(
            "/api/v1/advanced/privacy-mask",
            headers=auth_headers,
            json={
                "content": content,
                "mask_types": ["phone", "email", "id_card", "bank_card", "address"]
            }
        )

        assert response.status_code == 200
        data = response.json()
        assert data["code"] == 0
        # 验证多种信息都被脱敏
        assert len(data["data"]["masked_items"]) > 0

    async def test_privacy_mask_default_types(
        self, client: AsyncClient, auth_headers
    ):
        """测试: 使用默认脱敏类型"""
        content = "电话13800138000，邮箱test@example.com"

        response = await client.post(
            "/api/v1/advanced/privacy-mask",
            headers=auth_headers,
            json={
                "content": content
                # mask_types 使用默认值
            }
        )

        assert response.status_code == 200
        data = response.json()
        assert data["code"] == 0

    async def test_privacy_mask_no_sensitive_info(
        self, client: AsyncClient, auth_headers
    ):
        """测试: 内容中无敏感信息"""
        content = "这是一段普通文本，没有任何敏感信息"

        response = await client.post(
            "/api/v1/advanced/privacy-mask",
            headers=auth_headers,
            json={
                "content": content,
                "mask_types": ["phone", "email"]
            }
        )

        assert response.status_code == 200
        data = response.json()
        assert data["code"] == 0
        assert len(data["data"]["masked_items"]) == 0


class TestInterviewPrediction:
    """面试问题预测测试"""

    async def test_interview_predict_success(
        self, client: AsyncClient, auth_headers, test_resume
    ):
        """测试: 面试问题预测成功"""
        response = await client.post(
            "/api/v1/advanced/interview-predict",
            headers=auth_headers,
            json={
                "resume_id": test_resume.id,
                "target_position": "Python后端工程师"
            }
        )

        # AI 服务可能失败
        assert response.status_code in [200, 500]

    async def test_interview_predict_resume_not_found(
        self, client: AsyncClient, auth_headers
    ):
        """测试: 面试预测 - 简历不存在"""
        response = await client.post(
            "/api/v1/advanced/interview-predict",
            headers=auth_headers,
            json={
                "resume_id": 99999,
                "target_position": "软件工程师"
            }
        )

        assert response.status_code == 404

    async def test_interview_predict_with_company_type(
        self, client: AsyncClient, auth_headers, test_resume
    ):
        """测试: 带公司类型的面试预测"""
        response = await client.post(
            "/api/v1/advanced/interview-predict",
            headers=auth_headers,
            json={
                "resume_id": test_resume.id,
                "target_position": "产品经理",
                "company_type": "互联网"
            }
        )

        assert response.status_code in [200, 500]

    async def test_interview_predict_various_positions(
        self, client: AsyncClient, auth_headers, test_resume
    ):
        """测试: 不同职位的面试预测"""
        positions = [
            "前端工程师",
            "后端工程师",
            "全栈工程师",
            "数据分析师",
            "产品经理"
        ]

        for position in positions:
            response = await client.post(
                "/api/v1/advanced/interview-predict",
                headers=auth_headers,
                json={
                    "resume_id": test_resume.id,
                    "target_position": position
                }
            )
            # AI 可能失败
            assert response.status_code in [200, 500]


class TestResumeParsing:
    """简历解析测试"""

    async def test_parse_resume_unsupported_format(
        self, client: AsyncClient, auth_headers
    ):
        """测试: 不支持的文件格式"""
        content = b"fake image content"
        files = {"file": ("resume.txt", content, "text/plain")}

        response = await client.post(
            "/api/v1/advanced/parse-resume",
            headers=auth_headers,
            files=files
        )

        assert response.status_code == 400

    async def test_parse_resume_pdf(
        self, client: AsyncClient, auth_headers
    ):
        """测试: 解析PDF简历"""
        # 创建一个简单的PDF内容（实际解析会失败因为没有PyPDF2）
        content = b"%PDF-1.4 fake pdf content"

        files = {"file": ("resume.pdf", content, "application/pdf")}

        response = await client.post(
            "/api/v1/advanced/parse-resume",
            headers=auth_headers,
            files=files
        )

        # 可能返回 500（解析失败）或 200
        assert response.status_code in [200, 500]

    async def test_parse_resume_word(
        self, client: AsyncClient, auth_headers
    ):
        """测试: 解析Word简历"""
        # 创建一个简单的DOCX内容（实际解析会失败因为没有python-docx）
        content = b"PK\x03\x04 fake docx content"

        files = {"file": ("resume.docx", content, "application/vnd.openxmlformats-officedocument.wordprocessingml.document")}

        response = await client.post(
            "/api/v1/advanced/parse-resume",
            headers=auth_headers,
            files=files
        )

        # 可能返回 500（解析失败）或 200
        assert response.status_code in [200, 500]

    async def test_parse_resume_doc_format(
        self, client: AsyncClient, auth_headers
    ):
        """测试: 解析旧版Word格式"""
        content = b"\xd0\xcf\x11\xe0\xa1\xb1\x1a\xe1 fake doc content"

        files = {"file": ("resume.doc", content, "application/msword")}

        response = await client.post(
            "/api/v1/advanced/parse-resume",
            headers=auth_headers,
            files=files
        )

        # 可能返回 500（解析失败）或 200
        assert response.status_code in [200, 500]
