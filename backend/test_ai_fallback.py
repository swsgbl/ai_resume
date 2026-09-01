"""
测试 AI 简历生成功能 - 降级模式测试
"""
import asyncio
from app.services.ai.providers.openai_provider import OpenAIProvider
from loguru import logger

async def test_fallback_mode():
    """测试降级模式（无 API Key）"""
    try:
        # 初始化 OpenAI 提供商，不提供 API Key
        provider = OpenAIProvider(
            api_key="",  # 无效的 API Key
            model="gpt-4",
            max_tokens=4000,
            temperature=0.7
        )

        logger.info(f"✅ 提供商: {provider.provider_name}")
        logger.info(f"✅ 是否可用: {provider.is_available}")

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

        # 生成简历内容（降级模式）
        logger.info(f"正在生成简历内容（降级模式）...")
        logger.info(f"目标岗位: {target_position}")

        result = await provider.generate_resume_content(
            user_info=user_info,
            target_position=target_position,
            style=style,
            language=language
        )

        logger.success("✅ 降级模式生成成功！")

        # 打印生成的简历
        logger.info("\n" + "=" * 60)
        logger.info("生成的简历内容（降级模式）")
        logger.info("=" * 60)

        import json
        logger.info(json.dumps(result, ensure_ascii=False, indent=2))

        logger.success("=" * 60)
        logger.success("降级模式测试通过！✅")
        logger.success("=" * 60)

        return True

    except Exception as e:
        logger.error(f"❌ 降级模式测试失败: {e}")
        import traceback
        logger.error(traceback.format_exc())
        return False

async def test_optimize_fallback():
    """测试内容优化降级模式"""
    try:
        provider = OpenAIProvider(
            api_key="",  # 无效的 API Key
            model="gpt-4",
            max_tokens=4000,
            temperature=0.7
        )

        original = "我负责开发后端，使用了 FastAPI 和 React，项目运行良好。"

        logger.info(f"\n原文: {original}")
        logger.info("正在优化（降级模式）...")

        # STAR 法则优化
        optimized = await provider.optimize_content(
            original=original,
            optimization_type="star_method"
        )

        logger.success(f"✅ STAR 法则优化（降级）: {optimized}")

        # 量化优化
        quantified = await provider.optimize_content(
            original=original,
            optimization_type="quantify"
        )

        logger.success(f"✅ 量化优化（降级）: {quantified}")

        logger.success("=" * 60)
        logger.success("优化降级模式测试通过！✅")
        logger.success("=" * 60)

        return True

    except Exception as e:
        logger.error(f"❌ 优化降级模式测试失败: {e}")
        import traceback
        logger.error(traceback.format_exc())
        return False

async def main():
    """主函数"""
    logger.info("=" * 60)
    logger.info("AI 简历生成测试 - 降级模式")
    logger.info("=" * 60)

    # 测试简历生成
    await test_fallback_mode()

    logger.info("\n" + "=" * 60)

    # 测试内容优化
    await test_optimize_fallback()

if __name__ == "__main__":
    asyncio.run(main())
