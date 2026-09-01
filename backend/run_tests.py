"""
快速测试执行脚本
运行所有后端测试
"""
import os
import sys
import subprocess
from pathlib import Path
from loguru import logger


def run_test(test_file: str):
    """运行单个测试文件"""
    logger.info(f"运行测试: {test_file}")

    # 设置环境变量
    env = os.environ.copy()
    env['NO_PROXY'] = '127.0.0.1,localhost'
    env['no_proxy'] = '127.0.0.1,localhost'

    try:
        result = subprocess.run(
            [sys.executable, test_file],
            env=env,
            capture_output=True,
            text=True,
            timeout=300
        )

        if result.returncode == 0:
            logger.success(f"✅ {test_file} 通过")
            return True
        else:
            logger.error(f"❌ {test_file} 失败")
            logger.error(f"STDOUT: {result.stdout}")
            logger.error(f"STDERR: {result.stderr}")
            return False

    except subprocess.TimeoutExpired:
        logger.error(f"❌ {test_file} 超时")
        return False
    except Exception as e:
        logger.error(f"❌ {test_file} 异常: {e}")
        return False


def main():
    """主函数"""
    logger.info("=" * 60)
    logger.info("后端测试快速执行")
    logger.info("=" * 60)

    # 切换到后端目录
    backend_dir = Path(__file__).parent
    os.chdir(backend_dir)

    # 测试文件列表
    test_files = [
        "test_resumes.py",  # 简历 CRUD 测试
        "test_auth.py",     # 认证测试
        "test_xiaomi_final.py",  # AI 功能测试
    ]

    # 运行所有测试
    results = {}
    for test_file in test_files:
        if Path(test_file).exists():
            results[test_file] = run_test(test_file)
        else:
            logger.warning(f"⚠️ 测试文件不存在: {test_file}")
            results[test_file] = None

    # 总结
    logger.info("\n" + "=" * 60)
    logger.info("测试总结")
    logger.info("=" * 60)

    passed = 0
    failed = 0
    skipped = 0

    for test_file, result in results.items():
        if result is None:
            status = "⏭️  跳过"
            skipped += 1
        elif result:
            status = "✅ 通过"
            passed += 1
        else:
            status = "❌ 失败"
            failed += 1

        logger.info(f"{test_file}: {status}")

    logger.success("\n" + "=" * 60)
    logger.success(f"通过: {passed}, 失败: {failed}, 跳过: {skipped}")
    logger.success("=" * 60)

    # 返回码
    if failed > 0:
        sys.exit(1)
    else:
        sys.exit(0)


if __name__ == "__main__":
    main()
