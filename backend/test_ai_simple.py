"""
测试 AI 简历生成功能 - 简化版
"""
import asyncio
from app.services.ai.providers.openai_provider import OpenAIProvider
from app.core.config import settings
from loguru import logger

async def test_ai_generation():
    """测试 AI 简历生成"""
    try:
        # 初始化 OpenAI 提供商
        provider = OpenAIProvider(
            api_key=settings.OPENAI_API_KEY,
            model=settings.OPENAI_MODEL,
            max_tokens=settings.OPENAI_MAX_TOKENS,
            temperature=settings.OPENAI_TEMPERATURE
        )

        logger.info(f"✅ 提供商: {provider.provider_name}")
        logger.info(f"✅ 是否可用: {provider.is_available}")

        if not provider.is_available:
            logger.warning("⚠️ OpenAI 不可用，可能没有配置 API Key")
            return None

        # 测试数据
        user_info = {
            "basic_info": {
                "name": "张三",
                "phone": "13800138000",
                "email": "zhangsan@example.com",
                "title": "软件工程师"
            },
            "education": [
                {
                    "school": "清华大学",
                    "degree": "本科",
                    "major": "计算机科学",
                    "start_date": "2018-09",
                    "end_date": "2022-06"
                }
            ],
            "work_experience": [
                {
                    "company": "某某科技",
                    "position": "后端开发工程师",
                    "start_date": "2022-07",
                    "end_date": "2024-12",
                    "description": "负责后端开发和维护"
                }
            ],
            "projects": [
                {
                    "name": "AI 简历生成平台",
                    "role": "全栈开发",
                    "description": "使用 FastAPI 和 React 开发"
                }
            ],
            "skills": [
                "Python",
                "FastAPI",
                "React",
                "Docker",
                "Git"
            ],
            "certifications": []
        }

        target_position = "高级软件工程师"
        style = "professional"
        language = "zh"

        # 生成简历内容
        logger.info(f"正在生成简历内容...")
        logger.info(f"目标岗位: {target_position}")
        logger.info(f"风格: {style}")
        logger.info(f"语言: {language}")

        result = await provider.generate_resume_content(
            user_info=user_info,
            target_position=target_position,
            style=style,
            language=language
        )

        if result and not result.get("_fallback"):
            logger.success("✅ AI 生成成功！")

            # 打印生成的简历
            logger.info("\n" + "=" * 60)
            logger.info("生成的简历内容")
            logger.info("=" * 60)

            import json
            logger.info(json.dumps(result, ensure_ascii=False, indent=2))

            logger.success("=" * 60)
            logger.success("测试通过！✅")
            logger.success("=" * 60)

            return result
        else:
            logger.warning("⚠️ 生成结果为降级模式（可能 API 调用失败）")
            logger.info(f"结果: {json.dumps(result, ensure_ascii=False, indent=2)}")
            return result

    except Exception as e:
        logger.error(f"❌ AI 生成失败: {e}")
        import traceback
        logger.error(traceback.format_exc())
        return None

async def test_optimize():
    """测试内容优化"""
    try:
        provider = OpenAIProvider(
            api_key=settings.OPENAI_API_KEY,
            model=settings.OPENAI_MODEL,
            max_tokens=settings.OPENAI_MAX_TOKENS,
            temperature=settings.OPENAI_TEMPERATURE
        )

        if not provider.is_available:
            logger.warning("⚠️ OpenAI 不可用")
            return None

        original = "我负责开发后端，使用了 FastAPI 和 React，项目运行良好。"

        logger.info(f"\n原文: {original}")
        logger.info("正在优化...")

        # STAR 法则优化
        optimized = await provider.optimize_content(
            original=original,
            optimization_type="star_method"
        )

        logger.success(f"✅ STAR 法则优化: {optimized}")

        # 量化优化
        quantified = await provider.optimize_content(
            original=original,
            optimization_type="quantify"
        )

        logger.success(f"✅ 量化优化: {quantified}")

        return True

    except Exception as e:
        logger.error(f"❌ 优化失败: {e}")
        import traceback
        logger.error(traceback.format_exc())
        return False

async def main():
    """主函数"""
    logger.info("=" * 60)
    logger.info("AI 简历生成测试 - 简化版")
    logger.info("=" * 60)

    # 测试简历生成
    await test_ai_generation()

    logger.info("\n" + "=" * 60)

    # 测试内容优化
    await test_optimize()

if __name__ == "__main__":
    asyncio.run(main())
