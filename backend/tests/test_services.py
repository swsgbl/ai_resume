"""
后端服务层单元测试

测试覆盖:
- AIUsageService: AI使用限制和计费服务
- EmailService: 邮件发送和验证码服务
- ExportService: 导出服务 (部分)
- OAuthService: OAuth认证服务 (部分)
"""
import pytest
from unittest.mock import Mock, AsyncMock, patch, MagicMock, AsyncMock
from datetime import datetime, timezone, timedelta
from decimal import Decimal
from sqlalchemy.ext.asyncio import AsyncSession

from app.services.ai_usage_service import (
    AIUsageService,
    get_ai_usage_service,
    TOKEN_PRICING
)
from app.services.email_service import EmailService
from app.services.oauth_service import (
    GoogleOAuthProvider,
    GitHubOAuthProvider
)
from app.models.user import User, UserRole
from app.models.ai_usage import AIUsageLimit, AIUsageRecord


# ============================================================================
# Module-level Fixtures
# ============================================================================

class MockRedis:
    """模拟 Redis，同时支持存储值和跟踪调用"""

    def __init__(self):
        self._store = {}
        self._call_counts = {k: 0 for k in ['get', 'set', 'setex', 'incr', 'expire', 'delete', 'close']}
        self._default_return_values = {}  # 可配置的默认返回值

    def set_return_value(self, method, value):
        """设置方法的默认返回值"""
        self._default_return_values[method] = value

    async def get(self, key):
        self._call_counts['get'] += 1
        # 如果有配置的返回值，优先使用
        if 'get' in self._default_return_values and key not in self._store:
            return self._default_return_values['get']
        return self._store.get(key)

    async def set(self, key, value):
        self._call_counts['set'] += 1
        self._store[key] = value

    async def setex(self, key, seconds, value):
        self._call_counts['setex'] += 1
        self._store[key] = value

    async def incr(self, key):
        self._call_counts['incr'] += 1
        self._store[key] = self._store.get(key, 0) + 1
        return self._store[key]

    async def delete(self, key):
        self._call_counts['delete'] += 1
        self._store.pop(key, None)

    async def close(self):
        self._call_counts['close'] += 1

    async def expire(self, key, seconds):
        self._call_counts['expire'] += 1

    @property
    def call_count(self):
        """兼容旧代码，返回总调用次数"""
        return sum(self._call_counts.values())

    def get_call_count(self, method):
        """获取特定方法的调用次数"""
        return self._call_counts.get(method, 0)


@pytest.fixture
async def mock_redis():
    """Mock Redis连接 - 模块级别，供所有测试使用"""
    redis_instance = MockRedis()

    # 同时 mock AI usage service 和 email service 的 Redis
    with patch("app.services.ai_usage_service.redis.from_url", return_value=redis_instance), \
         patch("app.services.email_service.redis.from_url", return_value=redis_instance):
        yield redis_instance


# ============================================================================
# AIUsageService 测试
# ============================================================================

class TestAIUsageService:
    """AI使用服务测试"""

    @pytest.fixture
    async def service(self):
        """创建服务实例"""
        return AIUsageService()

    async def test_get_user_limit_creates_default_for_new_user(
        self,
        service: AIUsageService,
        db_session: AsyncSession,
        test_user: User
    ):
        """测试: 为新用户创建默认限制"""
        limit = await service.get_user_limit(db_session, test_user.id)

        assert limit is not None
        assert limit.user_id == test_user.id
        assert limit.tier == "free"  # 默认用户是 free
        assert limit.daily_limit == 10
        assert limit.monthly_limit == 200

    async def test_get_user_limit_returns_existing_limit(
        self,
        service: AIUsageService,
        db_session: AsyncSession,
        test_user: User
    ):
        """测试: 返回现有用户限制"""
        # 首次调用创建限制
        first_limit = await service.get_user_limit(db_session, test_user.id)
        first_limit.daily_limit = 50
        await db_session.commit()

        # 再次调用应返回相同限制
        second_limit = await service.get_user_limit(db_session, test_user.id)

        assert second_limit.id == first_limit.id
        assert second_limit.daily_limit == 50

    async def test_get_user_limit_for_premium_user(
        self,
        service: AIUsageService,
        db_session: AsyncSession
    ):
        """测试: Premium用户获取Pro限制"""
        # 创建Premium用户
        premium_user = User(
            email="premium@test.com",
            username="premium_user",
            password_hash="hash",
            role=UserRole.PREMIUM,
            is_active=True
        )
        db_session.add(premium_user)
        await db_session.commit()
        await db_session.refresh(premium_user)

        limit = await service.get_user_limit(db_session, premium_user.id)

        assert limit.tier == "pro"
        assert limit.daily_limit == 100
        assert limit.monthly_limit == 2000

    async def test_check_daily_limit_within_bounds(
        self,
        service: AIUsageService,
        db_session: AsyncSession,
        test_user: User,
        mock_redis
    ):
        """测试: 每日限制检查 - 在限制内"""
        # Mock Redis返回0次使用
        mock_redis.set_return_value('get', "0")

        # 确保重置时间有时区信息
        limit = await service.get_user_limit(db_session, test_user.id)
        limit.last_daily_reset = datetime.now(timezone.utc)
        await db_session.commit()

        is_allowed, used, limit = await service.check_daily_limit(db_session, test_user.id)

        assert is_allowed is True
        assert used == 0
        assert limit == 10  # free用户每日限制

    async def test_check_daily_limit_exceeded(
        self,
        service: AIUsageService,
        db_session: AsyncSession,
        test_user: User,
        mock_redis
    ):
        """测试: 每日限制检查 - 超出限制"""
        # Mock Redis返回10次使用 (达到限制)
        mock_redis.set_return_value('get', "10")

        # 确保重置时间有时区信息
        limit = await service.get_user_limit(db_session, test_user.id)
        limit.last_daily_reset = datetime.now(timezone.utc)
        await db_session.commit()

        is_allowed, used, limit = await service.check_daily_limit(db_session, test_user.id)

        assert is_allowed is False
        assert used == 10
        assert limit == 10

    async def test_check_daily_limit_resets_on_new_day(
        self,
        service: AIUsageService,
        db_session: AsyncSession,
        test_user: User,
        mock_redis
    ):
        """测试: 每日限制在当天重置"""
        # 创建昨天的重置时间
        yesterday = datetime.now(timezone.utc) - timedelta(days=1)
        limit = await service.get_user_limit(db_session, test_user.id)
        limit.last_daily_reset = yesterday
        await db_session.commit()

        # Mock Redis返回0次使用
        mock_redis.set_return_value('get', "0")

        is_allowed, used, limit_count = await service.check_daily_limit(db_session, test_user.id)

        # 重置时间应更新
        assert limit.last_daily_reset.date() == datetime.now(timezone.utc).date()
        assert is_allowed is True

    async def test_check_monthly_limit_within_bounds(
        self,
        service: AIUsageService,
        db_session: AsyncSession,
        test_user: User,
        mock_redis
    ):
        """测试: 每月限制检查 - 在限制内"""
        mock_redis.set_return_value('get', "50")

        # 确保重置时间有时区信息
        limit = await service.get_user_limit(db_session, test_user.id)
        limit.last_monthly_reset = datetime.now(timezone.utc)
        await db_session.commit()

        is_allowed, used, limit = await service.check_monthly_limit(db_session, test_user.id)

        assert is_allowed is True
        assert used == 50
        assert limit == 200

    async def test_check_monthly_limit_exceeded(
        self,
        service: AIUsageService,
        db_session: AsyncSession,
        test_user: User,
        mock_redis
    ):
        """测试: 每月限制检查 - 超出限制"""
        mock_redis.set_return_value('get', "200")

        # 确保重置时间有时区信息
        limit = await service.get_user_limit(db_session, test_user.id)
        limit.last_monthly_reset = datetime.now(timezone.utc)
        await db_session.commit()

        is_allowed, used, limit = await service.check_monthly_limit(db_session, test_user.id)

        assert is_allowed is False
        assert used == 200
        assert limit == 200

    async def test_record_usage_creates_record(
        self,
        service: AIUsageService,
        db_session: AsyncSession,
        test_user: User,
        mock_redis
    ):
        """测试: 记录AI使用"""
        record = await service.record_usage(
            db_session,
            test_user.id,
            provider="openai",
            model="gpt-4",
            operation="generate_resume",
            prompt_tokens=100,
            completion_tokens=200,
            total_tokens=300
        )

        assert record is not None
        assert record.user_id == test_user.id
        assert record.provider == "openai"
        assert record.model == "gpt-4"
        assert record.prompt_tokens == 100
        assert record.completion_tokens == 200
        assert record.total_tokens == 300
        # 计算成本: 300/1000 * 0.03 = 0.009
        assert float(record.estimated_cost) == float(Decimal("0.009"))

    async def test_record_usage_increments_redis_counters(
        self,
        service: AIUsageService,
        db_session: AsyncSession,
        test_user: User,
        mock_redis
    ):
        """测试: 记录使用时更新Redis计数器"""
        await service.record_usage(
            db_session,
            test_user.id,
            provider="openai",
            model="gpt-4",
            operation="test",
            total_tokens=100
        )

        # 验证Redis计数器被调用
        assert mock_redis.get_call_count('incr') == 2  # daily + monthly
        assert mock_redis.get_call_count('expire') == 2

    async def test_get_user_usage_stats(
        self,
        service: AIUsageService,
        db_session: AsyncSession,
        test_user: User
    ):
        """测试: 获取用户使用统计"""
        # 创建一些使用记录
        now = datetime.now(timezone.utc)
        record1 = AIUsageRecord(
            user_id=test_user.id,
            provider="openai",
            model="gpt-4",
            operation="generate_resume",
            total_tokens=100,
            estimated_cost=Decimal("0.003")
        )
        record2 = AIUsageRecord(
            user_id=test_user.id,
            provider="deepseek",
            model="deepseek-chat",
            operation="optimize_resume",
            total_tokens=200,
            estimated_cost=Decimal("0.00028")
        )
        db_session.add_all([record1, record2])
        await db_session.commit()

        stats = await service.get_user_usage_stats(db_session, test_user.id, days=30)

        assert stats["total_calls"] == 2
        assert stats["total_tokens"] == 300
        assert abs(stats["total_cost"] - 0.00328) < 0.0001
        assert len(stats["by_provider"]) == 2
        assert len(stats["by_operation"]) == 2

    async def test_ensure_billing_period_creates_new_period(
        self,
        service: AIUsageService,
        db_session: AsyncSession,
        test_user: User
    ):
        """测试: 确保计费周期存在"""
        billing = await service.ensure_billing_period(db_session, test_user.id)

        assert billing is not None
        assert billing.user_id == test_user.id
        assert billing.total_calls == 0

        # 再次调用应返回相同记录
        billing2 = await service.ensure_billing_period(db_session, test_user.id)
        assert billing.id == billing2.id

    def test_get_ai_usage_service_singleton(self):
        """测试: AIUsageService单例模式"""
        service1 = get_ai_usage_service()
        service2 = get_ai_usage_service()

        assert service1 is service2

    def test_token_pricing_constants(self):
        """测试: Token定价常量"""
        assert "openai" in TOKEN_PRICING
        assert "deepseek" in TOKEN_PRICING
        assert "xiaomi" in TOKEN_PRICING

        assert TOKEN_PRICING["openai"]["gpt-4"] == Decimal("0.03")
        assert TOKEN_PRICING["deepseek"]["deepseek-chat"] == Decimal("0.0014")


# ============================================================================
# EmailService 测试
# ============================================================================

class TestEmailService:
    """邮件服务测试"""

    @pytest.fixture
    def service(self):
        """创建服务实例"""
        return EmailService()

    def test_generate_code(self, service: EmailService):
        """测试: 生成验证码"""
        code = service.generate_code()

        assert len(code) == 6
        assert code.isdigit()

    def test_generate_code_custom_length(self, service: EmailService):
        """测试: 生成自定义长度验证码"""
        code = service.generate_code(length=8)

        assert len(code) == 8
        assert code.isdigit()

    async def test_save_code_memory_fallback(
        self,
        service: EmailService
    ):
        """测试: 保存验证码到内存后备"""
        # Mock get_redis 返回 None 以强制使用内存后备
        with patch.object(service, 'get_redis', return_value=None):
            await service.save_code("test@example.com", "123456", expire_minutes=5)

        assert "test@example.com" in service._verification_codes
        # 验证码以哈希形式存储，不存储明文
        assert "code_hash" in service._verification_codes["test@example.com"]
        assert service._verification_codes["test@example.com"]["used"] is False

    async def test_verify_code_valid_memory(
        self,
        service: EmailService
    ):
        """测试: 验证有效验证码 (内存)"""
        # Mock get_redis 返回 None 以强制使用内存后备
        with patch.object(service, 'get_redis', return_value=None):
            await service.save_code("test@example.com", "654321", expire_minutes=5)
            is_valid = await service.verify_code("test@example.com", "654321")

        assert is_valid is True
        # 验证后立即删除，防止重用（一次性使用）
        assert "test@example.com" not in service._verification_codes

    async def test_verify_code_invalid_memory(
        self,
        service: EmailService
    ):
        """测试: 验证无效验证码 (内存)"""
        service._redis = None
        await service.save_code("test@example.com", "654321", expire_minutes=5)

        is_valid = await service.verify_code("test@example.com", "111111")

        assert is_valid is False

    async def test_verify_code_expired_memory(
        self,
        service: EmailService
    ):
        """测试: 验证过期验证码 (内存)"""
        # 保存一个过期的验证码
        past_time = datetime.now(timezone.utc) - timedelta(minutes=10)
        service._verification_codes["test@example.com"] = {
            "code": "654321",
            "expire_time": past_time,
            "used": False
        }

        # Mock get_redis 返回 None 以强制使用内存后备
        with patch.object(service, 'get_redis', return_value=None):
            is_valid = await service.verify_code("test@example.com", "654321")

        assert is_valid is False
        assert "test@example.com" not in service._verification_codes

    async def test_verify_code_consume_one_time(
        self,
        service: EmailService
    ):
        """测试: 验证码只能使用一次"""
        # Mock get_redis 返回 None 以强制使用内存后备
        with patch.object(service, 'get_redis', return_value=None):
            await service.save_code("test@example.com", "654321", expire_minutes=5)

            # 第一次验证
            is_valid1 = await service.verify_code("test@example.com", "654321")
            # 第二次验证
            is_valid2 = await service.verify_code("test@example.com", "654321")

        assert is_valid1 is True
        assert is_valid2 is False

    async def test_save_reset_code(self, service: EmailService):
        """测试: 保存密码重置码"""
        # Mock get_redis 返回 None 以强制使用内存后备
        with patch.object(service, 'get_redis', return_value=None):
            await service.save_reset_code("test@example.com", "999888", expire_minutes=15)

        assert "test@example.com" in service._reset_codes
        # 重置码也以哈希形式存储，不存储明文
        assert "code_hash" in service._reset_codes["test@example.com"]

    async def test_verify_reset_code_valid(self, service: EmailService):
        """测试: 验证有效重置码"""
        # Mock get_redis 返回 None 以强制使用内存后备
        with patch.object(service, 'get_redis', return_value=None):
            await service.save_reset_code("test@example.com", "888777", expire_minutes=15)

            is_valid = await service.verify_reset_code("test@example.com", "888777")

        assert is_valid is True

    async def test_send_verification_email_debug(
        self,
        service: EmailService,
        capsys
    ):
        """测试: 发送验证码邮件 (DEBUG模式)"""
        with patch("app.services.email_service.settings") as mock_settings:
            mock_settings.DEBUG = True

            result = await service.send_verification_email("test@example.com", "123456")

            assert result is True
            captured = capsys.readouterr()
            assert "123456" in captured.out

    async def test_send_password_reset_email_debug(
        self,
        service: EmailService,
        capsys
    ):
        """测试: 发送密码重置邮件 (DEBUG模式)"""
        with patch("app.services.email_service.settings") as mock_settings:
            mock_settings.DEBUG = True

            result = await service.send_password_reset_email("test@example.com", "111222")

            assert result is True
            captured = capsys.readouterr()
            assert "111222" in captured.out

    async def test_send_verification_email_uses_threaded_smtp(
        self,
        service: EmailService
    ):
        """测试: SMTP 使用线程池、STARTTLS 和超时"""
        with patch("app.services.email_service.settings") as mock_settings:
            mock_settings.DEBUG = False
            mock_settings.SMTP_HOST = "smtp.example.com"
            mock_settings.SMTP_PORT = 465
            mock_settings.SMTP_USER = "sender@example.com"
            mock_settings.SMTP_PASSWORD = "test-password"

            with patch("app.services.email_service.smtplib.SMTP") as mock_smtp:
                result = await service.send_verification_email(
                    "test@example.com",
                    "123456"
                )

        assert result is True
        mock_smtp.assert_called_once_with("smtp.example.com", 465, timeout=10)
        smtp_context = mock_smtp.return_value.__enter__.return_value
        smtp_context.starttls.assert_called_once_with()
        smtp_context.login.assert_called_once_with(
            "sender@example.com",
            "test-password"
        )
        smtp_context.send_message.assert_called_once()

    async def test_send_email_requires_complete_smtp_config(
        self,
        service: EmailService
    ):
        """测试: SMTP 配置缺失时发送失败且不连接服务器"""
        with patch("app.services.email_service.settings") as mock_settings:
            mock_settings.DEBUG = False
            mock_settings.SMTP_HOST = "smtp.example.com"
            mock_settings.SMTP_PORT = None
            mock_settings.SMTP_USER = "sender@example.com"
            mock_settings.SMTP_PASSWORD = "test-password"

            with patch("app.services.email_service.smtplib.SMTP") as mock_smtp:
                result = await service.send_verification_email(
                    "test@example.com",
                    "123456"
                )

        assert result is False
        mock_smtp.assert_not_called()

    async def test_cleanup_expired_codes(self, service: EmailService):
        """测试: 清理过期验证码"""
        service._redis = None
        now = datetime.now(timezone.utc)

        # 添加一个过期的验证码
        service._verification_codes["expired@example.com"] = {
            "code": "111111",
            "expire_time": now - timedelta(minutes=10),
            "used": False
        }
        # 添加一个有效的验证码
        service._verification_codes["valid@example.com"] = {
            "code": "222222",
            "expire_time": now + timedelta(minutes=5),
            "used": False
        }

        await service.cleanup_expired_codes()

        assert "expired@example.com" not in service._verification_codes
        assert "valid@example.com" in service._verification_codes


# ============================================================================
# OAuthService 测试
# ============================================================================

class TestGoogleOAuthProvider:
    """Google OAuth提供商测试"""

    @pytest.fixture
    def provider(self):
        """创建Google OAuth提供商"""
        with patch("app.services.oauth_service.settings") as mock_settings:
            mock_settings.GOOGLE_CLIENT_ID = "test_client_id"
            mock_settings.GOOGLE_CLIENT_SECRET = "test_secret"
            mock_settings.GOOGLE_REDIRECT_URI = "http://localhost:8000/callback"
            return GoogleOAuthProvider()

    def test_initialization(self, provider):
        """测试: 提供商初始化"""
        assert provider.name == "google"
        assert provider.client_id == "test_client_id"

    def test_initialization_raises_without_client_id(self):
        """测试: 缺少CLIENT_ID时抛出异常"""
        with patch("app.services.oauth_service.settings") as mock_settings:
            mock_settings.GOOGLE_CLIENT_ID = ""

            with pytest.raises(ValueError, match="GOOGLE_CLIENT_ID 未配置"):
                GoogleOAuthProvider()

    @pytest.mark.asyncio
    async def test_get_authorization_url(self, provider):
        """测试: 获取授权URL"""
        url = await provider.get_authorization_url("random_state_123")

        assert "accounts.google.com/o/oauth2/v2/auth" in url
        assert "client_id=test_client_id" in url
        assert "state=random_state_123" in url
        assert "openid" in url
        assert "email" in url

    @pytest.mark.asyncio
    async def test_get_authorization_url_custom_redirect(self, provider):
        """测试: 获取授权URL (自定义回调)"""
        custom_redirect = "http://custom-callback.com/auth"
        url = await provider.get_authorization_url("state_456", redirect_uri=custom_redirect)

        assert "redirect_uri=http%3A%2F%2Fcustom-callback.com%2Fauth" in url

    @pytest.mark.asyncio
    async def test_exchange_code_for_token_success(self, provider):
        """测试: 用授权码换取令牌 (成功)"""
        mock_response = Mock()
        mock_response.json.return_value = {
            "access_token": "test_access_token",
            "token_type": "Bearer",
            "expires_in": 3600
        }

        with patch("httpx.AsyncClient.post", return_value=mock_response):
            tokens = await provider.exchange_code_for_token("valid_code", "http://callback")

            assert tokens["access_token"] == "test_access_token"

    @pytest.mark.asyncio
    async def test_exchange_code_for_token_error(self, provider):
        """测试: 用授权码换取令牌 (错误)"""
        mock_response = Mock()
        mock_response.json.return_value = {
            "error": "invalid_grant",
            "error_description": "The code has expired"
        }

        with patch("httpx.AsyncClient.post", return_value=mock_response):
            with pytest.raises(Exception) as exc_info:
                await provider.exchange_code_for_token("invalid_code", "http://callback")

            assert "invalid_grant" in str(exc_info.value) or "Google OAuth 错误" in str(exc_info.value)

    @pytest.mark.asyncio
    async def test_get_user_info_success(self, provider):
        """测试: 获取用户信息 (成功)"""
        mock_response = Mock()
        mock_response.status_code = 200
        mock_response.json.return_value = {
            "id": "google_user_123",
            "email": "user@gmail.com",
            "verified_email": True,
            "name": "Test User",
            "picture": "https://example.com/avatar.jpg"
        }

        with patch("httpx.AsyncClient.get", return_value=mock_response):
            user_info = await provider.get_user_info("valid_token")

            assert user_info["email"] == "user@gmail.com"
            assert user_info["verified_email"] is True

    def test_normalize_user_info(self, provider):
        """测试: 标准化用户信息"""
        raw_info = {
            "id": "google_123",
            "email": "test@gmail.com",
            "verified_email": True,
            "name": "Test User",
            "picture": "https://example.com/pic.jpg",
            "locale": "en"
        }

        normalized = provider.normalize_user_info(raw_info)

        assert normalized["provider"] == "google"
        assert normalized["provider_id"] == "google_123"
        assert normalized["email"] == "test@gmail.com"
        assert normalized["verified_email"] is True
        assert normalized["avatar_url"] == "https://example.com/pic.jpg"


class TestGitHubOAuthProvider:
    """GitHub OAuth提供商测试"""

    @pytest.fixture
    def provider(self):
        """创建GitHub OAuth提供商"""
        with patch("app.services.oauth_service.settings") as mock_settings:
            mock_settings.GITHUB_CLIENT_ID = "test_github_id"
            mock_settings.GITHUB_CLIENT_SECRET = "test_github_secret"
            mock_settings.GITHUB_REDIRECT_URI = "http://localhost:8000/github/callback"
            return GitHubOAuthProvider()

    def test_initialization(self, provider):
        """测试: GitHub提供商初始化"""
        assert provider.name == "github"
        assert provider.client_id == "test_github_id"

    def test_initialization_raises_without_client_id(self):
        """测试: 缺少CLIENT_ID时抛出异常"""
        with patch("app.services.oauth_service.settings") as mock_settings:
            mock_settings.GITHUB_CLIENT_ID = ""

            with pytest.raises(ValueError, match="GITHUB_CLIENT_ID 未配置"):
                GitHubOAuthProvider()

    @pytest.mark.asyncio
    async def test_get_authorization_url(self, provider):
        """测试: 获取GitHub授权URL"""
        url = await provider.get_authorization_url("random_state")

        assert "github.com/login/oauth/authorize" in url
        assert "client_id=test_github_id" in url
        assert "state=random_state" in url


# ============================================================================
# ExportService 测试
# ============================================================================

class TestExportService:
    """导出服务测试"""

    @pytest.fixture
    def service(self):
        """创建导出服务实例"""
        from app.services.export.export_service import ExportService
        return ExportService()

    @pytest.fixture
    def sample_resume_content(self):
        """示例简历内容"""
        return {
            "basic_info": {
                "name": "张三",
                "email": "zhangsan@example.com",
                "phone": "13800138000",
                "location": "北京市",
                "self_introduction": "5年后端开发经验"
            },
            "education": [
                {
                    "school": "清华大学",
                    "major": "计算机科学与技术",
                    "degree": "本科",
                    "start_date": "2015-09",
                    "end_date": "2019-06"
                }
            ],
            "work_experience": [
                {
                    "company": "某科技公司",
                    "position": "后端工程师",
                    "start_date": "2019-07",
                    "end_date": "2024-06",
                    "description": "负责系统架构设计和开发"
                }
            ],
            "skills": [
                {"name": "Python", "level": "精通"},
                {"name": "FastAPI", "level": "熟练"},
                {"name": "PostgreSQL", "level": "熟练"},
                {"name": "Redis", "level": "掌握"}
            ]
        }

    def test_generate_html(self, service, sample_resume_content):
        """测试: 生成HTML内容"""
        html = service._generate_html_with_inline_css(
            sample_resume_content,
            {"theme": "blue", "font": "default"},
            None
        )

        assert "<!DOCTYPE html>" in html
        assert "<html" in html
        assert "张三" in html
        assert "zhangsan@example.com" in html

    @pytest.mark.asyncio
    async def test_to_word_generates_document(self, service, sample_resume_content):
        """测试: Word导出生成文档"""
        doc_bytes = await service.to_word(sample_resume_content)

        assert doc_bytes is not None
        assert len(doc_bytes) > 0
        # Word文档应该包含特定的二进制标识
        assert b"PK" in doc_bytes or len(doc_bytes) > 100

    def test_generate_css(self, service):
        """测试: 生成CSS样式"""
        css = service._generate_css({"theme": "blue"})

        assert isinstance(css, str)
        assert len(css) > 0

    @pytest.mark.asyncio
    async def test_to_pdf_raises_without_weasyprint(self, service):
        """测试: PDF导出在WeasyPrint不可用时抛出异常"""
        from app.services.export.export_service import WEASYPRINT_AVAILABLE

        if not WEASYPRINT_AVAILABLE:
            with pytest.raises(RuntimeError, match="WeasyPrint"):
                await service.to_pdf({})
        else:
            # 如果WeasyPrint可用，跳过此测试
            pytest.skip("WeasyPrint is available")


# ============================================================================
# 服务集成测试
# ============================================================================

class TestServiceIntegration:
    """服务集成测试"""

    @pytest.mark.asyncio
    async def test_ai_usage_and_email_service_interaction(
        self,
        db_session: AsyncSession,
        test_user: User,
        mock_redis
    ):
        """测试: AI使用服务和邮件服务交互"""
        from datetime import datetime, timezone

        ai_service = AIUsageService()
        email_service = EmailService()

        # Mock Redis 返回值
        mock_redis.set_return_value('get', "0")

        # 确保用户的限制配置有正确的时区
        limit = await ai_service.get_user_limit(db_session, test_user.id)
        limit.last_daily_reset = datetime.now(timezone.utc)
        await db_session.commit()

        # 检查限制
        is_allowed, used, daily_limit = await ai_service.check_daily_limit(db_session, test_user.id)
        assert is_allowed is True

        # 发送验证码
        code = email_service.generate_code()
        await email_service.save_code(test_user.email, code)
        is_valid = await email_service.verify_code(test_user.email, code)
        assert is_valid is True
