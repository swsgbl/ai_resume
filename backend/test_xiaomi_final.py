"""
测试小米 MiMo AI - 使用正确的模型名称
测试所有可用模型：mimo-v2-pro, mimo-v2-flash, mimo-v2-omni
"""
import asyncio
from app.services.ai.providers.xiaomi_provider import XiaomiProvider
from loguru import logger

XIAOMI_API_KEY = "sk-c0uo5p7vq8h9p0fm45978gvkky3dgtbhn68uai4y2pnyt12o"
XIAOMI_BASE_URL = "https://api.xiaomimimo.com/v1"

# 可用的模型
XIAOMI_MODELS = [
    "mimo-v2-pro",    # Pro 模型（推荐，免费到4月2日）
    "mimo-v2-flash",  # 快速模型
    "mimo-v2-omni"    # 全能模型
]

async def test_xiaomi_model(model_name: str):
    """测试单个小米模型"""
    try:
        provider = XiaomiProvider(
            api_key=XIAOMI_API_KEY,
            model=model_name,
            base_url=XIAOMI_BASE_URL,
            max_tokens=4000,
            temperature=0.7
        )

        logger.info(f"=" * 60)
        logger.info(f"测试模型: {model_name}")
        logger.info(f"=" * 60)

        logger.info(f"✅ 提供商: {provider.provider_name}")
        logger.info(f"✅ 是否可用: {provider.is_available}")

        if not provider.is_available:
            logger.warning(f"⚠️ 模型 {model_name} 不可用")
            return False

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

        result = await provider.generate_resume_content(
            user_info=user_info,
            target_position=target_position,
            style=style,
            language=language
        )

        if result and not result.get("_fallback"):
            logger.success(f"✅ 模型 {model_name} 生成成功！")

            # 打印基本信息
            basic_info = result.get("basic_info", {})
            logger.info(f"\n✅ 姓名: {basic_info.get('name', 'N/A')}")
            logger.info(f"✅ 岗位: {basic_info.get('job_intention', 'N/A')}")
            logger.info(f"✅ 简介: {basic_info.get('self_introduction', 'N/A')}")

            logger.success(f"=" * 60)
            logger.success(f"模型 {model_name} 测试通过！✅")
            logger.success(f"=" * 60)

            return True
        else:
            logger.warning(f"⚠️ 模型 {model_name} 生成结果为降级模式")
            return False

    except Exception as e:
        logger.error(f"❌ 模型 {model_name} 测试失败: {e}")
        import traceback
        logger.error(traceback.format_exc())
        return False

async def test_optimization(model_name: str):
    """测试内容优化"""
    try:
        provider = XiaomiProvider(
            api_key=XIAOMI_API_KEY,
            model=model_name,
            base_url=XIAOMI_BASE_URL,
            max_tokens=4000,
            temperature=0.7
        )

        if not provider.is_available:
            logger.warning(f"⚠️ 模型 {model_name} 不可用，跳过优化测试")
            return False

        original = "我负责开发后端，使用了 FastAPI 和 React，项目运行良好。"

        logger.info(f"\n原文: {original}")
        logger.info(f"正在使用 {model_name} 优化...")

        # STAR 法则优化
        optimized = await provider.optimize_content(
            original=original,
            optimization_type="star_method"
        )

        logger.success(f"✅ STAR 法则优化: {optimized[:100]}...")

        return True

    except Exception as e:
        logger.error(f"❌ 模型 {model_name} 优化失败: {e}")
        import traceback
        logger.error(traceback.format_exc())
        return False

async def main():
    """主函数"""
    logger.info("=" * 60)
    logger.info("小米 MiMo AI 简历生成测试 - 完整版")
    logger.info("=" * 60)

    results = {}

    # 测试所有模型
    for model in XIAOMI_MODELS:
        logger.info(f"\n\n{'#' * 60}")
        logger.info(f"测试 {model}")
        logger.info(f"{'#' * 60}\n")

        # 测试简历生成
        success = await test_xiaomi_model(model)
        results[model] = {"generation": success}

        # 测试内容优化
        if success:
            opt_success = await test_optimization(model)
            results[model]["optimization"] = opt_success

    # 总结
    logger.info("\n\n" + "=" * 60)
    logger.info("测试总结")
    logger.info("=" * 60)

    for model, result in results.items():
        generation = "✅" if result.get("generation") else "❌"
        optimization = "✅" if result.get("optimization") else "❌"
        logger.info(f"{model}: 生成 {generation}, 优化 {optimization}")

    logger.success("=" * 60)
    logger.success("小米 MiMo AI 集成完成！✅")
    logger.success("=" * 60)

if __name__ == "__main__":
    asyncio.run(main())
