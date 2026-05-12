"""
职业智能路由 — 融合 career-ops 评估引擎 + Polanyi 默会知识理论
"""
import json
import logging
from typing import List, Optional
from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel, Field
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from app.core.database import get_db
from app.core.security import get_current_user
from app.models.user import User
from app.models.resume import Resume
from app.schemas.common import Response
from app.services.ai.prompts.manager import PromptManager

logger = logging.getLogger(__name__)
router = APIRouter(prefix="/career", tags=["职业智能"])


# ============ 请求/响应模型 ============

class JDEvaluateRequest(BaseModel):
    """JD 全景评估请求"""
    resume_id: int = Field(..., description="简历ID")
    job_description: str = Field(..., min_length=50, description="职位描述(JD)")
    user_preferences: Optional[str] = Field(None, description="用户偏好（行业、城市、薪资等）")


class StoryBankRequest(BaseModel):
    """故事银行请求"""
    resume_id: int = Field(..., description="简历ID")
    existing_stories: Optional[str] = Field(None, description="已有故事(JSON)")
    additional_context: Optional[str] = Field(None, description="补充信息")


class SmartTailorRequest(BaseModel):
    """智能定制请求"""
    resume_id: int = Field(..., description="简历ID")
    job_description: str = Field(..., min_length=50, description="目标职位描述")


# ============ JD 全景评估 ============

@router.post("/evaluate", response_model=Response[dict])
async def evaluate_jd(
    request: JDEvaluateRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """
    JD 全景评估 — 融合 career-ops 6维评估系统 + Polanyi 默会知识

    6个评估维度:
    - A) 职位摘要 — 公司类型、团队规模、职级、远程政策
    - B) 简历匹配 — 优势、差距、隐藏资产、竞争力位置
    - C) 等级策略 — 向上争取/同级展示/降维打击
    - D) 薪资研究 — 预估范围、市场位置、谈判筹码
    - E) 个性化方案 — 简历修改建议、关键词注入、叙事调整
    - F) 面试准备 — 预测问题、STAR+R 故事、案例推荐
    """
    result = await db.execute(
        select(Resume).where(Resume.id == request.resume_id, Resume.user_id == current_user.id)
    )
    resume = result.scalar_one_or_none()

    if not resume:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="简历不存在")

    resume_content = json.dumps(resume.content, ensure_ascii=False) if isinstance(resume.content, dict) else str(resume.content)

    prompt = PromptManager() \
        .system("career_intelligence") \
        .task("career/jd_evaluate") \
        .vars(
            resume_content=resume_content[:3000],
            job_description=request.job_description[:2000],
            user_preferences=request.user_preferences or "未指定"
        ) \
        .build()

    try:
        from app.services.ai.ai_service_factory import get_ai_provider
        ai_service = get_ai_provider()
        ai_response = await ai_service.generate_content(
            system_prompt=prompt["system"],
            user_prompt=prompt["user"],
            temperature=0.7
        )

        parsed = _parse_ai_json(ai_response)

        return Response(
            data=parsed,
            message="评估完成"
        )
    except Exception as e:
        logger.error(f"JD评估失败: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"AI 评估服务暂时不可用: {str(e)}"
        )


# ============ 故事银行 ============

@router.post("/story-bank", response_model=Response[dict])
async def generate_story_bank(
    request: StoryBankRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """
    STAR+R 故事银行 — 基于 Polanyi 默会知识理论挖掘隐性经验

    帮助用户从过往经历中提取:
    - 无法写在简历上但面试中最有价值的隐性经验
    - 可复用的 STAR+R 面试故事
    - 职业转折点的深层叙事
    - 区别于同级别候选人的默会优势
    """
    result = await db.execute(
        select(Resume).where(Resume.id == request.resume_id, Resume.user_id == current_user.id)
    )
    resume = result.scalar_one_or_none()

    if not resume:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="简历不存在")

    resume_content = json.dumps(resume.content, ensure_ascii=False) if isinstance(resume.content, dict) else str(resume.content)

    prompt = PromptManager() \
        .system("career_intelligence") \
        .task("career/story_bank") \
        .vars(
            resume_content=resume_content[:3000],
            existing_stories=request.existing_stories or "[]",
            additional_context=request.additional_context or ""
        ) \
        .build()

    try:
        from app.services.ai.ai_service_factory import get_ai_provider
        ai_service = get_ai_provider()
        ai_response = await ai_service.generate_content(
            system_prompt=prompt["system"],
            user_prompt=prompt["user"],
            temperature=0.8
        )

        parsed = _parse_ai_json(ai_response)

        return Response(
            data=parsed,
            message="故事挖掘完成"
        )
    except Exception as e:
        logger.error(f"故事银行生成失败: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"AI 服务暂时不可用: {str(e)}"
        )


# ============ 智能简历定制 ============

@router.post("/smart-tailor", response_model=Response[dict])
async def smart_tailor_resume(
    request: SmartTailorRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """
    智能简历定制 — 基于 JD 评估结果，生成针对特定职位的简历优化建议

    结合 career-ops 的 ATS 优化 + Polanyi 默会知识的直觉判断，
    不仅做关键词匹配，还调整简历的整体叙事和策略方向。
    """
    result = await db.execute(
        select(Resume).where(Resume.id == request.resume_id, Resume.user_id == current_user.id)
    )
    resume = result.scalar_one_or_none()

    if not resume:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="简历不存在")

    resume_content = json.dumps(resume.content, ensure_ascii=False) if isinstance(resume.content, dict) else str(resume.content)

    tailor_prompt = f"""你是一位融合了 career-ops 评估智慧的简历定制专家。

基于 Polanyi 的默会知识理论，你不只是做关键词替换，而是：
1. 理解这个 JD 背后真正在寻找什么样的人（直觉判断）
2. 调整简历的叙事角度，让用户"看起来就是"这个岗位的理想人选
3. 优化 ATS 兼容性的同时保持真实性和个性化

用户当前简历:
{resume_content[:2500]}

目标职位描述:
{request.job_description[:1500]}

请返回 JSON 格式的定制建议:
{{
  "tailored_content": {{完整定制后的简历内容}},
  "changes_made": [
    {{"section": "修改板块", "before": "修改前", "after": "修改后", "why": "为什么这样改"}}
  ],
  "keywords_injected": ["注入的关键词"],
  "narrative_angle": "整体叙事调整方向",
  "confidence_notes": "哪些修改是确信的，哪些需要用户确认"
}}"""

    try:
        from app.services.ai.ai_service_factory import get_ai_provider
        ai_service = get_ai_provider()
        ai_response = await ai_service.generate_content(
            system_prompt="你是一位融合了 career-ops 评估智慧的简历定制专家，同时具备 Polanyi 默会知识的直觉判断力。",
            user_prompt=tailor_prompt,
            temperature=0.6
        )

        parsed = _parse_ai_json(ai_response)

        return Response(
            data=parsed,
            message="智能定制完成"
        )
    except Exception as e:
        logger.error(f"智能定制失败: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"AI 服务暂时不可用: {str(e)}"
        )


# ============ 辅助函数 ============

def _parse_ai_json(response: str) -> dict:
    """解析 AI 返回的 JSON，容错处理"""
    if isinstance(response, dict):
        return response

    text = str(response)

    # 尝试从 markdown 代码块中提取
    if "```json" in text:
        start = text.index("```json") + 7
        end = text.index("```", start)
        text = text[start:end]
    elif "```" in text:
        start = text.index("```") + 3
        end = text.index("```", start)
        text = text[start:end]

    text = text.strip()

    try:
        return json.loads(text)
    except json.JSONDecodeError:
        return {
            "raw_response": text[:1000],
            "error": "AI 返回格式异常，请重试"
        }
