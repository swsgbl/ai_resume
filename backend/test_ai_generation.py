"""
测试 AI 简历生成功能
"""
import asyncio
from app.services.ai.ai_service_factory import get_ai_provider, AIProvider
from app.core.config import settings
from loguru import logger

async def test_ai_generation():
    """测试 AI 简历生成"""
    try:
        # 初始化 AI 提供商
        provider = get_ai_provider()

        # 获取当前提供商
        current = await provider.get_current_provider()
        logger.info(f"当前 AI 提供商: {current}")

        # 测试生成简历内容
        prompt = """
请为以下信息生成一段专业的个人简介：

职位: 软件工程师
经验: 5年
技能: Python, FastAPI, React, Docker, Git
项目: AI 简历生成平台

要求:
1. 突出技术能力
2. 强调项目经验
3. 使用 STAR 法则
4. 语言简洁专业
"""

        logger.info(f"生成简历内容...")
        result = await provider.generate_resume_content(prompt)

        logger.success(f"✅ AI 生成成功！")
        logger.info(f"\n{result}")

        return result

    except Exception as e:
        logger.error(f"❌ AI 生成失败: {e}")
        import traceback
        logger.error(traceback.format_exc())
        return None

async def test_provider_switch():
    """测试切换 AI 提供商"""
    try:
        provider = get_ai_provider()

        # 查看可用提供商
        providers = await provider.get_available_providers()
        logger.info(f"可用提供商: {providers}")

        # 获取当前配置
        config = await provider.get_config()
        logger.info(f"当前配置: {config}")

    except Exception as e:
        logger.error(f"❌ 查询提供商失败: {e}")
        import traceback
        logger.error(traceback.format_exc())

async def main():
    """主函数"""
    logger.info("=" * 60)
    logger.info("AI 简历生成测试")
    logger.info("=" * 60)

    # 测试提供商信息
    await test_provider_switch()

    logger.info("\n" + "=" * 60)

    # 测试简历生成
    result = await test_ai_generation()

    if result:
        logger.success("=" * 60)
        logger.success("所有测试通过！✅")
        logger.success("=" * 60)
    else:
        logger.error("=" * 60)
        logger.error("测试失败！❌")
        logger.error("=" * 60)

if __name__ == "__main__":
    asyncio.run(main())
