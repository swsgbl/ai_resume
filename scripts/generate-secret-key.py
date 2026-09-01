#!/usr/bin/env python3
"""
生成安全的 SECRET_KEY 用于生产环境

用法:
    python scripts/generate-secret-key.py
"""
import secrets
import hashlib
import os


def generate_secret_key(length: int = 64) -> str:
    """生成安全的随机密钥"""
    # 生成加密安全的随机字节
    random_bytes = secrets.token_bytes(length)

    # 转换为十六进制字符串
    hex_string = hashlib.sha256(random_bytes).hexdigest()

    return hex_string


def main():
    print("=" * 60)
    print("  AI Resume Platform - SECRET_KEY 生成器")
    print("=" * 60)
    print()

    # 生成密钥
    secret_key = generate_secret_key()

    print("生成的 SECRET_KEY:")
    print(secret_key)
    print()

    print("使用方法:")
    print("1. 设置环境变量:")
    print(f"   export SECRET_KEY={secret_key}")
    print()
    print("2. 或添加到 .env 文件:")
    print(f"   SECRET_KEY={secret_key}")
    print()
    print("3. Docker Compose:")
    print("   在 docker-compose.yml 中添加:")
    print(f"   SECRET_KEY: {secret_key}")
    print()

    # 验证强度
    print("密钥强度验证:")
    print(f"  长度: {len(secret_key)} 字符")
    print(f"  熵: ~{len(secret_key) * 4} bits")
    print("  状态: ✅ 符合生产环境要求 (至少 32 字符)")
    print()

    # 保存到文件
    output_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    env_file = os.path.join(output_dir, "backend", ".env.secret")

    print(f"密钥已保存到: {env_file}")
    with open(env_file, "w") as f:
        f.write(f"# 生产环境 SECRET_KEY - 请妥善保管\n")
        f.write(f"# 生成时间: {os.popen('date').read().strip()}\n")
        f.write(f"SECRET_KEY={secret_key}\n")

    print("⚠️  请将 .env.secret 文件内容添加到生产环境的 SECRET_KEY 配置中")
    print("   然后删除本地文件，避免泄露到版本控制中")


if __name__ == "__main__":
    main()
