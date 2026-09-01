"""
端到端测试：AI 简历生成完整流程
"""
import asyncio
import httpx
from app.core.database import init_db, close_db, get_db
from app.core.security import get_password_hash, create_access_token
from app.models.user import User
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from loguru import logger

# 后端 API
BASE_URL = "http://127.0.0.1:8000"
API_PREFIX = "/api/v1"

# 测试数据
TEST_USER = {
    "email": "e2e_test@example.com",
    "username": "e2e_tester",
    "password": "TestE2E123!"
}

RESUME_DATA = {
    "title": "E2E 测试简历",
    "content": {
        "basic_info": {
            "name": "E2E 测试用户",
            "email": "e2e_test@example.com",
            "phone": "13800138000",
            "title": "软件工程师",
            "summary": "专注于全栈开发",
            "job_intention": "高级软件工程师",
            "self_introduction": "具有5年全栈开发经验"
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
                "company": "测试公司",
                "position": "后端开发",
                "start_date": "2022-07",
                "end_date": "2024-12",
                "description": "负责后端开发"
            }
        ],
        "projects": [
            {
                "name": "AI 简历平台",
                "role": "全栈开发",
                "description": "使用 FastAPI 和 React"
            }
        ],
        "skills": [
            "Python",
            "FastAPI",
            "React",
            "Docker"
        ],
        "certifications": []
    }
}


async def test_backend_api():
    """测试后端 API 基础功能"""
    logger.info("=" * 60)
    logger.info("测试 1: 后端 API 基础功能")
    logger.info("=" * 60)

    async with httpx.AsyncClient(timeout=30.0) as client:
        try:
            # 测试健康检查
            response = await client.get(f"{BASE_URL}/health")
            if response.status_code == 200:
                logger.success("✅ 健康检查通过")
            else:
                logger.error(f"❌ 健康检查失败: {response.status_code}")

            # 测试 API 文档
            response = await client.get(f"{BASE_URL}/docs")
            if response.status_code == 200:
                logger.success("✅ API 文档可访问")
            else:
                logger.error(f"❌ API 文档不可访问: {response.status_code}")

            return True

        except Exception as e:
            logger.error(f"❌ 后端 API 测试失败: {e}")
            import traceback
            logger.error(traceback.format_exc())
            return False


async def test_user_registration():
    """测试用户注册"""
    logger.info("\n" + "=" * 60)
    logger.info("测试 2: 用户注册")
    logger.info("=" * 60)

    async with httpx.AsyncClient(timeout=30.0) as client:
        try:
            # 注册用户
            response = await client.post(
                f"{BASE_URL}{API_PREFIX}/auth/register",
                json=TEST_USER
            )

            if response.status_code == 200:
                result = response.json()
                logger.success("✅ 用户注册成功")
                logger.info(f"用户: {result['data']['user']['username']}")
                logger.info(f"Token: {result['data']['access_token'][:20]}...")
                return result['data']['access_token']
            elif response.status_code == 400:
                logger.warning("⚠️ 用户已存在，尝试登录")
                return await test_user_login()
            else:
                logger.error(f"❌ 注册失败: {response.text}")
                return None

        except Exception as e:
            logger.error(f"❌ 注册测试失败: {e}")
            return None


async def test_user_login():
    """测试用户登录"""
    logger.info("\n" + "=" * 60)
    logger.info("测试 3: 用户登录")
    logger.info("=" * 60)

    async with httpx.AsyncClient(timeout=30.0) as client:
        try:
            response = await client.post(
                f"{BASE_URL}{API_PREFIX}/auth/login",
                data={
                    "username": TEST_USER["email"],
                    "password": TEST_USER["password"]
                }
            )

            if response.status_code == 200:
                result = response.json()
                logger.success("✅ 用户登录成功")
                logger.info(f"Token: {result['data']['access_token'][:20]}...")
                return result['data']['access_token']
            else:
                logger.error(f"❌ 登录失败: {response.text}")
                return None

        except Exception as e:
            logger.error(f"❌ 登录测试失败: {e}")
            return None


async def test_create_resume(access_token: str):
    """测试创建简历"""
    logger.info("\n" + "=" * 60)
    logger.info("测试 4: 创建简历")
    logger.info("=" * 60)

    async with httpx.AsyncClient(timeout=30.0) as client:
        try:
            headers = {
                "Authorization": f"Bearer {access_token}"
            }

            response = await client.post(
                f"{BASE_URL}{API_PREFIX}/resumes/",
                json=RESUME_DATA,
                headers=headers
            )

            if response.status_code == 200:
                result = response.json()
                logger.success("✅ 简历创建成功")
                logger.info(f"简历 ID: {result['data']['id']}")
                logger.info(f"简历标题: {result['data']['title']}")
                return result['data']['id']
            else:
                logger.error(f"❌ 创建简历失败: {response.text}")
                return None

        except Exception as e:
            logger.error(f"❌ 创建简历测试失败: {e}")
            import traceback
            logger.error(traceback.format_exc())
            return None


async def test_ai_generation(resume_id: int, access_token: str):
    """测试 AI 生成简历"""
    logger.info("\n" + "=" * 60)
    logger.info("测试 5: AI 生成简历")
    logger.info("=" * 60)

    async with httpx.AsyncClient(timeout=120.0) as client:
        try:
            headers = {
                "Authorization": f"Bearer {access_token}"
            }

            logger.info(f"正在为简历 {resume_id} 生成 AI 内容...")
            logger.info("这可能需要 10-20 秒...")

            response = await client.post(
                f"{BASE_URL}{API_PREFIX}/resumes/{resume_id}/ai-generate",
                json={
                    "target_position": RESUME_DATA["content"]["basic_info"]["job_intention"]
                },
                headers=headers
            )

            if response.status_code == 200:
                result = response.json()
                logger.success("✅ AI 生成成功！")
                logger.info(f"生成的简介: {result['data']['content']['basic_info']['self_introduction'][:50]}...")
                return True
            else:
                logger.error(f"❌ AI 生成失败: {response.text}")
                return False

        except Exception as e:
            logger.error(f"❌ AI 生成测试失败: {e}")
            import traceback
            logger.error(traceback.format_exc())
            return False


async def test_get_resume(resume_id: int, access_token: str):
    """测试获取简历"""
    logger.info("\n" + "=" * 60)
    logger.info("测试 6: 获取简历")
    logger.info("=" * 60)

    async with httpx.AsyncClient(timeout=30.0) as client:
        try:
            headers = {
                "Authorization": f"Bearer {access_token}"
            }

            response = await client.get(
                f"{BASE_URL}{API_PREFIX}/resumes/{resume_id}",
                headers=headers
            )

            if response.status_code == 200:
                result = response.json()
                logger.success("✅ 获取简历成功")
                logger.info(f"简历标题: {result['data']['title']}")
                logger.info(f"AI 状态: {result['data']['ai_generated']}")
                return True
            else:
                logger.error(f"❌ 获取简历失败: {response.text}")
                return False

        except Exception as e:
            logger.error(f"❌ 获取简历测试失败: {e}")
            return False


async def test_optimize_content(resume_id: int, access_token: str):
    """测试内容优化"""
    logger.info("\n" + "=" * 60)
    logger.info("测试 7: 内容优化")
    logger.info("=" * 60)

    async with httpx.AsyncClient(timeout=60.0) as client:
        try:
            headers = {
                "Authorization": f"Bearer {access_token}"
            }

            original_text = RESUME_DATA["content"]["work_experience"][0]["description"]
            logger.info(f"原文: {original_text}")

            response = await client.post(
                f"{BASE_URL}{API_PREFIX}/ai/optimize",
                json={
                    "original": original_text,
                    "optimization_type": "star_method"
                },
                headers=headers
            )

            if response.status_code == 200:
                result = response.json()
                logger.success("✅ 内容优化成功！")
                logger.info(f"优化后: {result['data']['optimized'][:100]}...")
                return True
            else:
                logger.error(f"❌ 内容优化失败: {response.text}")
                return False

        except Exception as e:
            logger.error(f"❌ 内容优化测试失败: {e}")
            return False


async def main():
    """主函数"""
    logger.info("=" * 60)
    logger.info("AI 简历平台 - 端到端测试")
    logger.info("=" * 60)

    # 初始化数据库
    await init_db()
    logger.success("✅ 数据库初始化完成\n")

    # 运行测试
    results = {}

    # 测试 1: 后端 API
    results['backend_api'] = await test_backend_api()

    # 测试 2-3: 注册和登录
    access_token = await test_user_registration()
    results['user_auth'] = access_token is not None

    # 测试 4: 创建简历
    if access_token:
        resume_id = await test_create_resume(access_token)
        results['create_resume'] = resume_id is not None
    else:
        results['create_resume'] = False
        resume_id = None

    # 测试 5: AI 生成
    if resume_id and access_token:
        results['ai_generation'] = await test_ai_generation(resume_id, access_token)
    else:
        results['ai_generation'] = False

    # 测试 6: 获取简历
    if resume_id and access_token:
        results['get_resume'] = await test_get_resume(resume_id, access_token)
    else:
        results['get_resume'] = False

    # 测试 7: 内容优化
    if access_token:
        results['optimize_content'] = await test_optimize_content(resume_id, access_token) if resume_id else False
    else:
        results['optimize_content'] = False

    # 总结
    logger.info("\n" + "=" * 60)
    logger.info("测试总结")
    logger.info("=" * 60)

    for test_name, result in results.items():
        status = "✅" if result else "❌"
        logger.info(f"{test_name}: {status}")

    # 关闭数据库
    await close_db()

    logger.success("=" * 60)
    logger.success("端到端测试完成！")
    logger.success("=" * 60)

    # 统计
    passed = sum(1 for r in results.values() if r)
    total = len(results)
    logger.success(f"\n通过: {passed}/{total} ({passed*100//total}%)")


if __name__ == "__main__":
    asyncio.run(main())
