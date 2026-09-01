"""
应用配置模块
"""

import os
import secrets
import hashlib
from typing import Optional, List, Union
from pydantic_settings import BaseSettings
from pydantic import ConfigDict, field_validator
from functools import lru_cache


def _generate_secure_key() -> str:
    """生成安全的随机密钥"""
    # 尝试验证环境变量中是否设置了安全的SECRET_KEY
    env_key = os.environ.get("SECRET_KEY", "")
    if env_key and len(env_key) >= 32:
        return env_key

    # 如果没有安全的环境变量密钥，生成一个随机密钥
    # 注意：这仅用于开发环境，生产环境必须通过环境变量设置
    random_bytes = secrets.token_bytes(32)
    return hashlib.sha256(random_bytes).hexdigest()


class Settings(BaseSettings):
    """应用配置"""

    # 应用基础配置
    APP_NAME: str = "AI简历智能生成平台"
    APP_VERSION: str = "1.0.0"
    DEBUG: bool = False  # 生产环境必须设为False
    API_V1_PREFIX: str = "/api/v1"

    # 服务器配置
    HOST: str = "0.0.0.0"
    PORT: int = 8000

    # 数据库配置
    # 开发环境使用SQLite，生产环境使用MySQL
    USE_SQLITE: bool = True  # 设为False使用MySQL
    DATABASE_URL: str = "sqlite+aiosqlite:///./ai_resume.db"
    DATABASE_POOL_SIZE: int = 5  # SQLite不需要大连接池
    DATABASE_MAX_OVERFLOW: int = 10

    # Redis配置
    REDIS_URL: str = "redis://localhost:6379/0"

    # JWT配置
    # 生产环境必须通过环境变量 SECRET_KEY 设置至少32位的强密钥
    SECRET_KEY: str = ""
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 30
    REFRESH_TOKEN_EXPIRE_DAYS: int = 7

    # ========== AI模型配置 ==========

    # 默认AI提供商
    DEFAULT_AI_PROVIDER: str = "openai"  # openai/deepseek/xiaomi

    # OpenAI配置
    OPENAI_API_KEY: str = ""
    OPENAI_MODEL: str = "gpt-4"
    OPENAI_MAX_TOKENS: int = 4000
    OPENAI_TEMPERATURE: float = 0.7

    # DeepSeek配置（中国AI模型）
    DEEPSEEK_API_KEY: str = ""
    DEEPSEEK_MODEL: str = "deepseek-chat"
    DEEPSEEK_BASE_URL: str = "https://api.deepseek.com"
    DEEPSEEK_MAX_TOKENS: int = 4000
    DEEPSEEK_TEMPERATURE: float = 0.7

    # 小米MiMo AI配置
    # 官方文档: https://platform.xiaomimimo.com/#/docs/quick-start/first-api-call
    XIAOMI_API_KEY: str = ""
    XIAOMI_MODEL: str = "MiMo-V2-Flash"  # 小米MiMo V2 Flash模型
    XIAOMI_BASE_URL: str = "https://api.xiaomimimo.com/v1"
    XIAOMI_MAX_TOKENS: int = 4000
    XIAOMI_TEMPERATURE: float = 0.7

    # 文件存储配置
    UPLOAD_DIR: str = "./uploads"
    MAX_UPLOAD_SIZE: int = 10 * 1024 * 1024  # 10MB
    ALLOWED_EXTENSIONS: List[str] = ["pdf", "doc", "docx", "png", "jpg", "jpeg"]

    # CORS配置 - 生产环境应只允许特定域名
    # 开发环境使用localhost，生产环境使用实际域名
    CORS_ORIGINS: Union[str, List[str]] = [
        "http://localhost:3000",
        "http://localhost:5173",
        "http://localhost:8080",
        "http://127.0.0.1:5173",
        "http://127.0.0.1:3000",
        "http://127.0.0.1:8080",
    ]

    @field_validator("CORS_ORIGINS", mode="before")
    @classmethod
    def parse_cors_origins(cls, v):
        if isinstance(v, str):
            # 支持逗号分隔或JSON数组格式
            if v.startswith("["):
                import json

                try:
                    return json.loads(v)
                except json.JSONDecodeError:
                    pass
            return [origin.strip() for origin in v.split(",")]
        return v

    # 邮件配置（可选）
    SMTP_HOST: Optional[str] = None
    SMTP_PORT: Optional[int] = None
    SMTP_USER: Optional[str] = None
    SMTP_PASSWORD: Optional[str] = None

    # ========== 短信验证码配置 ==========
    # 阿里云短信认证（个人免企业资质）
    # 开通教程: https://dysms.console.aliyun.com/ -> 国内消息 -> 添加签名和模板
    SMS_ALIBABA_ACCESS_KEY_ID: Optional[str] = None
    SMS_ALIBABA_ACCESS_KEY_SECRET: Optional[str] = None
    SMS_SIGN_NAME: str = "AI简历平台"  # 短信签名（需在阿里云审核通过）
    SMS_TEMPLATE_CODE: Optional[str] = None  # 验证码模板 CODE（如 SMS_123456789）
    SMS_ENABLED: bool = False  # 是否启用短信验证码（未配置时走开发模式）

    # 微信登录配置（可选）
    WECHAT_APP_ID: Optional[str] = None
    WECHAT_APP_SECRET: Optional[str] = None

    # ========== OAuth 配置 ==========

    # Google OAuth 配置
    # 获取凭证: https://console.cloud.google.com/apis/credentials
    GOOGLE_CLIENT_ID: Optional[str] = None
    GOOGLE_CLIENT_SECRET: Optional[str] = None
    GOOGLE_REDIRECT_URI: str = "http://localhost:8000/api/v1/auth/oauth/google/callback"

    # GitHub OAuth 配置
    # 创建 OAuth App: https://github.com/settings/developers
    GITHUB_CLIENT_ID: Optional[str] = None
    GITHUB_CLIENT_SECRET: Optional[str] = None
    GITHUB_REDIRECT_URI: str = "http://localhost:8000/api/v1/auth/oauth/github/callback"

    # Gitee OAuth 配置
    # 创建应用: https://gitee.com/oauth/applications
    GITEE_CLIENT_ID: Optional[str] = None
    GITEE_CLIENT_SECRET: Optional[str] = None
    GITEE_REDIRECT_URI: str = "http://localhost:8000/api/v1/auth/oauth/gitee/callback"

    # Discord OAuth 配置
    # 创建应用: https://discord.com/developers/applications
    DISCORD_CLIENT_ID: Optional[str] = None
    DISCORD_CLIENT_SECRET: Optional[str] = None
    DISCORD_REDIRECT_URI: str = "http://localhost:8000/api/v1/auth/oauth/discord/callback"

    # OAuth 状态存储（用于 CSRF 保护）
    # 开发环境使用内存存储，生产环境应使用 Redis
    OAUTH_STATE_TTL_SECONDS: int = 600  # 10分钟

    model_config = ConfigDict(env_file=".env", case_sensitive=True)


@lru_cache()
def get_settings() -> Settings:
    """获取配置单例"""
    settings = Settings()

    # 当 USE_SQLITE=True 时，强制使用 SQLite 数据库 URL
    # 这会覆盖环境变量中的 DATABASE_URL 设置
    if settings.USE_SQLITE:
        import os

        # 确保数据目录存在
        os.makedirs("./data", exist_ok=True)
        settings.DATABASE_URL = "sqlite+aiosqlite:///./data/ai_resume.db"

    # 生产环境安全检查
    if not settings.DEBUG:
        # 生产环境必须设置安全的SECRET_KEY
        if not settings.SECRET_KEY or len(settings.SECRET_KEY) < 32:
            import warnings

            warnings.warn(
                "⚠️ 生产环境警告: SECRET_KEY未设置或长度不足32位！"
                "请在环境变量中设置: export SECRET_KEY=<至少32位的随机字符串>"
            )
            # 使用生成的临时密钥（仅用于开发）
            settings.SECRET_KEY = _generate_secure_key()

        # 生产环境应该使用MySQL而不是SQLite
        if settings.USE_SQLITE:
            import warnings

            warnings.warn("⚠️ 生产环境警告: 建议将USE_SQLITE设为False使用MySQL数据库")

    return settings


settings = get_settings()
