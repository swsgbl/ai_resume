"""
测试认证系统功能
"""
import asyncio
from fastapi.testclient import TestClient
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from app.main import app
from app.core.database import get_db, init_db, close_db
from app.core.security import (
    get_password_hash,
    create_access_token,
    decode_token
)
from app.models.user import User
from app.services.email_service import email_service
from app.schemas.user import UserCreate
from loguru import logger


async def test_registration():
    """测试用户注册"""
    logger.info("=" * 60)
    logger.info("测试 1: 用户注册")
    logger.info("=" * 60)

    try:
        with TestClient(app) as client:
            # 创建测试用户
            user_data = {
                "email": "test@example.com",
                "username": "testuser",
                "password": "Test123456!",
                "phone": "13800138000"
            }

            response = client.post("/api/v1/auth/register", json=user_data)
            logger.info(f"注册响应状态: {response.status_code}")

            if response.status_code == 200:
                result = response.json()
                logger.success(f"✅ 注册成功！")
                logger.info(f"用户: {result['data']['user']['username']}")
                logger.info(f"邮箱: {result['data']['user']['email']}")
                logger.info(f"Access Token: {result['data']['access_token'][:20]}...")
                return result['data']['access_token']
            else:
                logger.error(f"❌ 注册失败: {response.text}")
                return None

    except Exception as e:
        logger.error(f"❌ 注册测试失败: {e}")
        import traceback
        logger.error(traceback.format_exc())
        return None


async def test_login():
    """测试用户登录"""
    logger.info("\n" + "=" * 60)
    logger.info("测试 2: 用户登录")
    logger.info("=" * 60)

    try:
        with TestClient(app) as client:
            # 使用 OAuth2 表单格式登录
            login_data = {
                "username": "test@example.com",
                "password": "Test123456!"
            }

            response = client.post("/api/v1/auth/login", data=login_data)
            logger.info(f"登录响应状态: {response.status_code}")

            if response.status_code == 200:
                result = response.json()
                logger.success(f"✅ 登录成功！")
                logger.info(f"Token: {result['data']['access_token'][:20]}...")
                return result['data']['access_token']
            else:
                logger.error(f"❌ 登录失败: {response.text}")
                return None

    except Exception as e:
        logger.error(f"❌ 登录测试失败: {e}")
        import traceback
        logger.error(traceback.format_exc())
        return None


async def test_email_verification():
    """测试邮箱验证码功能"""
    logger.info("\n" + "=" * 60)
    logger.info("测试 3: 邮箱验证码")
    logger.info("=" * 60)

    try:
        # 生成验证码
        test_email = "verify@example.com"
        code = email_service.generate_code(length=6)
        logger.info(f"生成的验证码: {code}")

        # 保存验证码（现在使用异步方法）
        await email_service.save_code(test_email, code, expire_minutes=5)
        logger.success(f"✅ 验证码已保存")

        # 验证验证码（现在使用异步方法）
        is_valid = await email_service.verify_code(test_email, code)
        if is_valid:
            logger.success(f"✅ 验证码验证成功！")
        else:
            logger.error(f"❌ 验证码验证失败！")

        # 测试错误验证码
        is_valid = await email_service.verify_code(test_email, "000000")
        if not is_valid:
            logger.success(f"✅ 错误验证码被正确拒绝！")
        else:
            logger.error(f"❌ 错误验证码未正确拒绝！")

        return True

    except Exception as e:
        logger.error(f"❌ 邮箱验证测试失败: {e}")
        import traceback
        logger.error(traceback.format_exc())
        return False


async def test_password_reset():
    """测试密码重置功能"""
    logger.info("\n" + "=" * 60)
    logger.info("测试 4: 密码重置")
    logger.info("=" * 60)

    try:
        with TestClient(app) as client:
            # 请求密码重置
            reset_request = {
                "email": "test@example.com"
            }

            response = client.post("/api/v1/auth/password-reset/request", json=reset_request)
            logger.info(f"密码重置请求状态: {response.status_code}")

            if response.status_code == 200:
                result = response.json()
                logger.success(f"✅ 密码重置请求成功！")
                logger.info(f"消息: {result['message']}")
                return True
            else:
                logger.error(f"❌ 密码重置请求失败: {response.text}")
                return False

    except Exception as e:
        logger.error(f"❌ 密码重置测试失败: {e}")
        import traceback
        logger.error(traceback.format_exc())
        return False


async def test_token_validation():
    """测试 Token 验证"""
    logger.info("\n" + "=" * 60)
    logger.info("测试 5: Token 验证")
    logger.info("=" * 60)

    try:
        # 创建测试 token
        test_user_id = "test-user-id-12345"
        access_token = create_access_token(data={"sub": test_user_id})
        logger.info(f"生成的 Token: {access_token[:20]}...")

        # 验证 token
        payload = decode_token(access_token)
        logger.info(f"Token Payload: {payload}")

        if payload.get("sub") == test_user_id:
            logger.success(f"✅ Token 验证成功！")
            return True
        else:
            logger.error(f"❌ Token 验证失败！")
            return False

    except Exception as e:
        logger.error(f"❌ Token 验证测试失败: {e}")
        import traceback
        logger.error(traceback.format_exc())
        return False


async def test_protected_route():
    """测试受保护的路由"""
    logger.info("\n" + "=" * 60)
    logger.info("测试 6: 受保护的路由")
    logger.info("=" * 60)

    try:
        with TestClient(app) as client:
            # 注册获取 token
            user_data = {
                "email": "protected@example.com",
                "username": "protecteduser",
                "password": "Test123456!"
            }

            response = client.post("/api/v1/auth/register", json=user_data)
            if response.status_code != 200:
                logger.error(f"❌ 注册失败: {response.text}")
                return False

            token = response.json()['data']['access_token']

            # 访问受保护的路由
            headers = {"Authorization": f"Bearer {token}"}
            response = client.get("/api/v1/auth/me", headers=headers)
            logger.info(f"受保护路由响应状态: {response.status_code}")

            if response.status_code == 200:
                result = response.json()
                logger.success(f"✅ 受保护路由访问成功！")
                logger.info(f"用户: {result['data']['username']}")
                return True
            else:
                logger.error(f"❌ 受保护路由访问失败: {response.text}")
                return False

    except Exception as e:
        logger.error(f"❌ 受保护路由测试失败: {e}")
        import traceback
        logger.error(traceback.format_exc())
        return False


async def main():
    """主函数"""
    logger.info("=" * 60)
    logger.info("认证系统功能测试")
    logger.info("=" * 60)

    # 初始化数据库
    await init_db()
    logger.success("✅ 数据库初始化完成\n")

    # 运行所有测试
    results = {}

    # 测试 1: 注册
    results['registration'] = await test_registration()

    # 测试 2: 登录
    results['login'] = await test_login()

    # 测试 3: 邮箱验证
    results['email_verification'] = await test_email_verification()

    # 测试 4: 密码重置
    results['password_reset'] = await test_password_reset()

    # 测试 5: Token 验证
    results['token_validation'] = await test_token_validation()

    # 测试 6: 受保护路由
    results['protected_route'] = await test_protected_route()

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
    logger.success("认证系统测试完成！")
    logger.success("=" * 60)


if __name__ == "__main__":
    asyncio.run(main())
