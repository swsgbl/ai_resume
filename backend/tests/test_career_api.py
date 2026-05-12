"""
职业智能 API 集成测试
测试 JD 评估、故事银行、智能简历定制功能
"""
import pytest
from httpx import AsyncClient
from sqlalchemy.ext.asyncio import AsyncSession
from unittest.mock import AsyncMock, patch
import json


@pytest.mark.asyncio
class TestCareerJDEvaluate:
    """JD 全景评估测试"""

    async def test_evaluate_jd_success(
        self, client: AsyncClient, test_resume, auth_headers: dict
    ):
        """测试成功评估 JD"""
        jd_text = """
        职位：高级前端工程师
        公司：某知名互联网公司
        要求：
        - 5年以上前端开发经验
        - 精通 React、TypeScript
        - 有大型项目经验
        - 良好的团队协作能力
        """

        mock_response = {
            "职位摘要": {
                "公司类型": "互联网",
                "团队规模": "50-100人",
                "职级": "P6-P7",
                "远程政策": "部分远程"
            },
            "简历匹配": {
                "优势": ["技术栈匹配", "经验丰富"],
                "差距": ["缺少大型项目经验"],
                "竞争力位置": "中等偏上"
            },
            "等级策略": "同级展示",
            "薪资研究": {
                "预估范围": "25k-35k",
                "市场位置": "中上"
            }
        }

        with patch("app.services.ai.ai_service_factory.get_ai_provider") as mock_get_provider:
            mock_ai = AsyncMock()
            mock_ai.generate_content = AsyncMock(return_value=json.dumps(mock_response, ensure_ascii=False))
            mock_get_provider.return_value = mock_ai

            response = await client.post(
                "/api/v1/career/evaluate",
                headers=auth_headers,
                json={
                    "resume_id": test_resume.id,
                    "job_description": jd_text,
                    "user_preferences": "希望在北京工作，期望薪资30k+"
                }
            )

        assert response.status_code == 200
        data = response.json()
        assert data["code"] == 0  # Response schema uses 0 for success
        assert data["message"] == "评估完成"

    async def test_evaluate_jd_resume_not_found(
        self, client: AsyncClient, auth_headers: dict
    ):
        """测试评估不存在的简历"""
        response = await client.post(
            "/api/v1/career/evaluate",
            headers=auth_headers,
            json={
                "resume_id": 99999,
                "job_description": "这是一段足够长的职位描述内容。" * 10
            }
        )

        assert response.status_code == 404
        assert "简历不存在" in response.json()["detail"]

    async def test_evaluate_jd_too_short(
        self, client: AsyncClient, test_resume, auth_headers: dict
    ):
        """测试 JD 过短"""
        response = await client.post(
            "/api/v1/career/evaluate",
            headers=auth_headers,
            json={
                "resume_id": test_resume.id,
                "job_description": "太短"
            }
        )

        assert response.status_code == 422  # Validation error

    async def test_evaluate_jd_ai_failure(
        self, client: AsyncClient, test_resume, auth_headers: dict
    ):
        """测试 AI 服务失败"""
        with patch("app.services.ai.ai_service_factory.get_ai_provider") as mock_get_provider:
            mock_ai = AsyncMock()
            mock_ai.generate_content = AsyncMock(side_effect=Exception("AI 服务不可用"))
            mock_get_provider.return_value = mock_ai

            response = await client.post(
                "/api/v1/career/evaluate",
                headers=auth_headers,
                json={
                    "resume_id": test_resume.id,
                    "job_description": "这是一段足够长的职位描述，用于测试AI服务失败的场景。" * 10
                }
            )

        assert response.status_code == 500
        assert "AI 评估服务暂时不可用" in response.json()["detail"]


@pytest.mark.asyncio
class TestCareerStoryBank:
    """故事银行测试"""

    async def test_generate_story_bank_success(
        self, client: AsyncClient, test_resume, auth_headers: dict
    ):
        """测试成功生成故事银行"""
        mock_response = {
            "隐性经验": [
                {
                    "经历": "带领团队完成紧急项目",
                    "默会价值": "展现抗压能力和领导力",
                    "STAR故事": {
                        "情境": "项目临近上线，核心成员离职",
                        "任务": "确保项目按时交付",
                        "行动": "重新分配任务，加班赶工",
                        "结果": "按时上线，获得客户表扬"
                    }
                }
            ],
            "叙事建议": "在面试中强调危机处理经验"
        }

        with patch("app.services.ai.ai_service_factory.get_ai_provider") as mock_get_provider:
            mock_ai = AsyncMock()
            mock_ai.generate_content = AsyncMock(return_value=json.dumps(mock_response, ensure_ascii=False))
            mock_get_provider.return_value = mock_ai

            response = await client.post(
                "/api/v1/career/story-bank",
                headers=auth_headers,
                json={
                    "resume_id": test_resume.id,
                    "existing_stories": "[]",
                    "additional_context": "曾带领5人团队"
                }
            )

        assert response.status_code == 200
        data = response.json()
        assert data["code"] == 0  # Response schema uses 0 for success
        assert data["message"] == "故事挖掘完成"

    async def test_generate_story_bank_with_existing_stories(
        self, client: AsyncClient, test_resume, auth_headers: dict
    ):
        """测试基于已有故事生成新的故事"""
        existing = json.dumps([
            {"title": "解决线上故障", "impact": "挽回损失10万"}
        ], ensure_ascii=False)

        mock_response = {
            "新故事": [
                {
                    "title": "优化系统性能",
                    "impact": "响应时间减少50%"
                }
            ],
            "关联建议": "可以将优化故事与故障处理故事串联"
        }

        with patch("app.services.ai.ai_service_factory.get_ai_provider") as mock_get_provider:
            mock_ai = AsyncMock()
            mock_ai.generate_content = AsyncMock(return_value=json.dumps(mock_response, ensure_ascii=False))
            mock_get_provider.return_value = mock_ai

            response = await client.post(
                "/api/v1/career/story-bank",
                headers=auth_headers,
                json={
                    "resume_id": test_resume.id,
                    "existing_stories": existing
                }
            )

        assert response.status_code == 200

    async def test_generate_story_bank_resume_not_found(
        self, client: AsyncClient, auth_headers: dict
    ):
        """测试不存在的简历"""
        response = await client.post(
            "/api/v1/career/story-bank",
            headers=auth_headers,
            json={
                "resume_id": 99999
            }
        )

        assert response.status_code == 404


@pytest.mark.asyncio
class TestCareerSmartTailor:
    """智能简历定制测试"""

    async def test_smart_tailor_success(
        self, client: AsyncClient, test_resume, auth_headers: dict
    ):
        """测试成功智能定制简历"""
        jd = """
        职位：React 高级工程师
        要求：精通 React、Redux、TypeScript，有组件库开发经验
        """

        mock_response = {
            "tailored_content": {
                "basic_info": {"name": "张三"},
                "skills": ["React", "Redux", "TypeScript", "组件库"]
            },
            "changes_made": [
                {
                    "section": "技能",
                    "before": "Vue, React",
                    "after": "React, Redux, TypeScript",
                    "why": "与JD更匹配"
                }
            ],
            "keywords_injected": ["React", "Redux", "TypeScript", "组件库"],
            "narrative_angle": "强调React技术栈经验",
            "confidence_notes": "建议用户确认组件库经验"
        }

        with patch("app.services.ai.ai_service_factory.get_ai_provider") as mock_get_provider:
            mock_ai = AsyncMock()
            mock_ai.generate_content = AsyncMock(return_value=json.dumps(mock_response, ensure_ascii=False))
            mock_get_provider.return_value = mock_ai

            response = await client.post(
                "/api/v1/career/smart-tailor",
                headers=auth_headers,
                json={
                    "resume_id": test_resume.id,
                    "job_description": jd
                }
            )

        assert response.status_code == 200
        data = response.json()
        assert data["code"] == 0  # Response schema uses 0 for success
        assert "tailored_content" in data["data"]
        assert "changes_made" in data["data"]
        assert len(data["data"]["keywords_injected"]) > 0

    async def test_smart_tailor_jd_too_short(
        self, client: AsyncClient, test_resume, auth_headers: dict
    ):
        """测试 JD 过短"""
        response = await client.post(
            "/api/v1/career/smart-tailor",
            headers=auth_headers,
            json={
                "resume_id": test_resume.id,
                "job_description": "太短"
            }
        )

        assert response.status_code == 422

    async def test_smart_tailor_parse_error_fallback(
        self, client: AsyncClient, test_resume, auth_headers: dict
    ):
        """测试 AI 返回格式错误时的容错处理"""
        with patch("app.services.ai.ai_service_factory.get_ai_provider") as mock_get_provider:
            mock_ai = AsyncMock()
            mock_ai.generate_content = AsyncMock(return_value="这不是有效的JSON")
            mock_get_provider.return_value = mock_ai

            response = await client.post(
                "/api/v1/career/smart-tailor",
                headers=auth_headers,
                json={
                    "resume_id": test_resume.id,
                    "job_description": "这是一段足够长的职位描述内容。" * 20
                }
            )

        assert response.status_code == 200
        data = response.json()
        # 应该有容错处理
        assert "data" in data


@pytest.mark.asyncio
class TestCareerAPIUnauthorized:
    """未授权访问测试"""

    async def test_all_endpoints_require_auth(self, client: AsyncClient):
        """测试所有端点都需要认证"""
        endpoints = [
            ("/api/v1/career/evaluate", "post", {"resume_id": 1, "job_description": "测试" * 10}),
            ("/api/v1/career/story-bank", "post", {"resume_id": 1}),
            ("/api/v1/career/smart-tailor", "post", {"resume_id": 1, "job_description": "测试" * 10})
        ]

        for path, method, payload in endpoints:
            if method == "post":
                response = await client.post(path, json=payload)
            else:
                response = await client.get(path)

            assert response.status_code == 401, f"Endpoint {path} should require auth"


@pytest.mark.asyncio
class TestCareerAPIIntegration:
    """职业智能 API 完整流程测试"""

    async def test_career_intelligence_workflow(
        self, client: AsyncClient, test_resume, auth_headers: dict
    ):
        """测试完整的职业智能工作流：评估 -> 故事银行 -> 定制"""
        jd = """
        高级后端工程师 - 某大厂
        要求：Python、Go、微服务、高并发经验
        职级：P7
        薪资：35-50k
        """

        # 步骤1: JD 评估
        evaluate_response = {
            "职位摘要": {"职级": "P7"},
            "简历匹配": {"优势": ["后端经验"], "差距": ["缺少Go经验"]},
            "等级策略": "向上争取",
            "面试准备": {"预测问题": ["微服务设计"]},
            "薪资研究": {"预估范围": "35-50k"}
        }

        with patch("app.services.ai.ai_service_factory.get_ai_provider") as mock_get_provider:
            mock_ai = AsyncMock()
            mock_ai.generate_content = AsyncMock(return_value=json.dumps(evaluate_response, ensure_ascii=False))
            mock_get_provider.return_value = mock_ai

            resp = await client.post(
                "/api/v1/career/evaluate",
                headers=auth_headers,
                json={
                    "resume_id": test_resume.id,
                    "job_description": jd,
                    "user_preferences": "期望40k+"
                }
            )
            assert resp.status_code == 200

        # 步骤2: 生成故事银行
        story_response = {
            "隐性经验": [{"故事": "处理高并发场景"}],
            "面试故事": [{"title": "优化接口性能"}]
        }

        with patch("app.services.ai.ai_service_factory.get_ai_provider") as mock_get_provider:
            mock_ai = AsyncMock()
            mock_ai.generate_content = AsyncMock(return_value=json.dumps(story_response, ensure_ascii=False))
            mock_get_provider.return_value = mock_ai

            resp = await client.post(
                "/api/v1/career/story-bank",
                headers=auth_headers,
                json={"resume_id": test_resume.id}
            )
            assert resp.status_code == 200

        # 步骤3: 智能定制
        tailor_response = {
            "tailored_content": {"skills": ["Python", "Go", "微服务"]},
            "changes_made": [],
            "keywords_injected": ["Go", "微服务"],
            "narrative_angle": "强调学习能力和转型潜力"
        }

        with patch("app.services.ai.ai_service_factory.get_ai_provider") as mock_get_provider:
            mock_ai = AsyncMock()
            mock_ai.generate_content = AsyncMock(return_value=json.dumps(tailor_response, ensure_ascii=False))
            mock_get_provider.return_value = mock_ai

            resp = await client.post(
                "/api/v1/career/smart-tailor",
                headers=auth_headers,
                json={
                    "resume_id": test_resume.id,
                    "job_description": jd
                }
            )
            assert resp.status_code == 200
