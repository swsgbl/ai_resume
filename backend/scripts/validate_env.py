#!/usr/bin/env python3
"""
环境变量验证脚本

检查 .env 文件中的关键配置是否正确设置。
用于在部署前验证配置，避免因配置错误导致的服务故障。
"""

import os
import sys
import re
from pathlib import Path
from typing import List, Tuple

# 颜色输出
GREEN = "\033[92m"
YELLOW = "\033[93m"
RED = "\033[91m"
RESET = "\033[0m"


def check_passed(msg: str):
    print(f"{GREEN}✓{RESET} {msg}")


def check_warning(msg: str):
    print(f"{YELLOW}⚠{RESET} {msg}")


def check_failed(msg: str):
    print(f"{RED}✗{RESET} {msg}")


def validate_secret_key(key: str) -> Tuple[bool, str]:
    """验证 SECRET_KEY 是否符合要求"""
    if not key:
        return False, "未设置"
    if len(key) < 32:
        return False, f"长度不足（当前 {len(key)} 字符，至少需要 32 字符）"
    if key in ["CHANGE_THIS", "your-secret-key", "CHANGE_THIS_TO_A_SECURE_RANDOM_KEY"]:
        return False, "使用默认值，必须更换"
    return True, "OK"


def validate_database_url(url: str, use_sqlite: bool) -> Tuple[bool, str]:
    """验证数据库配置"""
    if use_sqlite:
        if "sqlite" not in url.lower():
            return False, "USE_SQLITE=true 但 DATABASE_URL 不是 SQLite"
        return True, "SQLite 配置正确"
    else:
        if "mysql" not in url.lower():
            return False, "USE_SQLITE=false 但 DATABASE_URL 不是 MySQL"
        # 检查是否包含默认密码
        if "your_password_here" in url or "SECURE_PASSWORD" in url:
            return False, "使用默认密码，必须更换"
        return True, "MySQL 配置正确"


def validate_api_key(key: str, provider: str) -> Tuple[bool, str]:
    """验证 API Key 格式"""
    if not key:
        return False, "未设置"
    if key.startswith("sk-your-") or key.startswith("your-"):
        return False, "使用占位符，必须设置实际值"
    if len(key) < 20:
        return False, f"长度异常（{len(key)} 字符）"
    return True, "OK"


def validate_email_config(smtp_host: str, smtp_user: str, smtp_password: str) -> Tuple[bool, str]:
    """验证邮件配置（可选）"""
    if not smtp_host and not smtp_user:
        return True, "邮件未配置（可选）"
    if smtp_host and smtp_user and smtp_password:
        if "your-" in smtp_user or "your-" in smtp_password:
            return False, "邮件配置使用占位符"
        return True, "邮件配置正确"
    return False, "邮件配置不完整"


def validate_env_file(env_path: Path) -> List[Tuple[bool, str, str]]:
    """验证环境文件，返回 (是否通过, 类别, 消息) 列表"""
    results = []

    # 读取环境文件
    env_vars = {}
    if env_path.exists():
        with open(env_path) as f:
            for line in f:
                line = line.strip()
                if line and not line.startswith("#") and "=" in line:
                    key, value = line.split("=", 1)
                    env_vars[key.strip()] = value.strip()
    else:
        results.append((False, "critical", f"环境文件不存在: {env_path}"))
        return results

    # 关键配置检查
    critical_checks = []

    # SECRET_KEY
    secret_key = env_vars.get("SECRET_KEY", "")
    passed, msg = validate_secret_key(secret_key)
    critical_checks.append((passed, "SECRET_KEY", msg))

    # 数据库配置
    use_sqlite = env_vars.get("USE_SQLITE", "true").lower() in ["true", "1", "yes"]
    database_url = env_vars.get("DATABASE_URL", "")
    passed, msg = validate_database_url(database_url, use_sqlite)
    critical_checks.append((passed, "DATABASE", msg))

    # DEBUG 模式检查
    debug = env_vars.get("DEBUG", "false").lower() in ["true", "1", "yes"]
    if debug:
        critical_checks.append((False, "DEBUG", "生产环境必须关闭 DEBUG"))
    else:
        critical_checks.append((True, "DEBUG", "已关闭（生产环境正确）"))

    # AI 配置检查（至少需要一个）
    default_provider = env_vars.get("DEFAULT_AI_PROVIDER", "openai")
    openai_key = env_vars.get("OPENAI_API_KEY", "")
    deepseek_key = env_vars.get("DEEPSEEK_API_KEY", "")
    xiaomi_key = env_vars.get("XIAOMI_API_KEY", "")

    has_openai = validate_api_key(openai_key, "openai")[0]
    has_deepseek = validate_api_key(deepseek_key, "deepseek")[0]
    has_xiaomi = validate_api_key(xiaomi_key, "xiaomi")[0]

    if not (has_openai or has_deepseek or has_xiaomi):
        critical_checks.append((False, "AI", "没有配置有效的 AI API Key"))
    else:
        providers = []
        if has_openai:
            providers.append("OpenAI")
        if has_deepseek:
            providers.append("DeepSeek")
        if has_xiaomi:
            providers.append("小米")
        critical_checks.append((True, "AI", f"已配置: {', '.join(providers)}"))

    # 可选配置检查
    optional_checks = []

    # OAuth 配置
    google_client_id = env_vars.get("GOOGLE_CLIENT_ID", "")
    github_client_id = env_vars.get("GITHUB_CLIENT_ID", "")
    wechat_app_id = env_vars.get("WECHAT_APP_ID", "")

    oauth_providers = []
    if google_client_id and not google_client_id.startswith("your-"):
        oauth_providers.append("Google")
    if github_client_id and not github_client_id.startswith("your-"):
        oauth_providers.append("GitHub")
    if wechat_app_id and not wechat_app_id.startswith("your-"):
        oauth_providers.append("微信")

    if oauth_providers:
        optional_checks.append((True, "OAuth", f"已配置: {', '.join(oauth_providers)}"))
    else:
        optional_checks.append((False, "OAuth", "未配置（可选）"))

    # 邮件配置
    smtp_host = env_vars.get("SMTP_HOST", "")
    smtp_user = env_vars.get("SMTP_USER", "")
    smtp_password = env_vars.get("SMTP_PASSWORD", "")
    passed, msg = validate_email_config(smtp_host, smtp_user, smtp_password)
    optional_checks.append((passed, "邮件", msg))

    # Redis 配置
    redis_url = env_vars.get("REDIS_URL", "")
    if redis_url and not redis_url.startswith("redis://localhost"):
        optional_checks.append((True, "Redis", f"已配置: {redis_url[:20]}..."))
    else:
        optional_checks.append((False, "Redis", "未配置（使用内存存储）"))

    # 组合结果
    for passed, category, msg in critical_checks:
        results.append((passed, "critical" if category in ["SECRET_KEY", "DATABASE", "DEBUG"] else "important", f"[{category}] {msg}"))

    for passed, category, msg in optional_checks:
        results.append((passed, "optional", f"[{category}] {msg}"))

    return results


def main():
    """主函数"""
    env_file = Path(__file__).parent.parent / ".env"
    env_production = Path(__file__).parent.parent / ".env.production"

    print("=" * 60)
    print("环境变量配置验证")
    print("=" * 60)
    print()

    # 检查哪个文件存在
    if env_production.exists():
        target_file = env_production
        print(f"检查文件: .env.production (生产环境)")
    elif env_file.exists():
        target_file = env_file
        print(f"检查文件: .env (开发环境)")
    else:
        check_failed("未找到环境配置文件（.env 或 .env.production）")
        print("\n请先创建配置文件:")
        print("  cp .env.example .env")
        sys.exit(1)

    print()

    # 验证配置
    results = validate_env_file(target_file)

    # 分类显示结果
    critical_failed = 0
    important_failed = 0

    for passed, level, msg in results:
        if level == "critical":
            if passed:
                check_passed(msg)
            else:
                check_failed(msg)
                critical_failed += 1
        elif level == "important":
            if passed:
                check_passed(msg)
            else:
                check_warning(msg)
                important_failed += 1
        else:  # optional
            if passed:
                check_passed(msg)
            else:
                check_warning(msg)

    print()
    print("=" * 60)

    # 总结
    if critical_failed > 0:
        print(f"{RED}验证失败: {critical_failed} 个关键配置错误{RESET}")
        print("\n请修复以下配置后再启动服务:")
        sys.exit(1)
    elif important_failed > 0:
        print(f"{YELLOW}验证通过（有警告）: {important_failed} 个建议修复的配置{RESET}")
        sys.exit(0)
    else:
        print(f"{GREEN}验证通过: 所有配置正确{RESET}")
        sys.exit(0)


if __name__ == "__main__":
    main()
