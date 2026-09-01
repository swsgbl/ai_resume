"""
AI 限流装饰器测试
"""
import pytest
from unittest.mock import AsyncMock, patch
from sqlalchemy.ext.asyncio import AsyncSession

from app.services.ai_limit_decorator import (
    AIUsageLimitExceeded,
    check_ai_limit,
    require_ai_limit
)
from app.models.user import User


class TestAIUsageLimitExceeded:
    """AI 使用限制异常测试"""

    def test_ai_usage_limit_exceeded_creation(self):
        """测试: 创建限制异常"""
        exception = AIUsageLimitExceeded(used=100, limit=50, period="day")

        assert exception.used == 100
        assert exception.limit == 50
        assert exception.period == "day"
        assert "100/50" in exception.detail
        assert "day" in exception.detail

    def test_ai_usage_limit_exceeded_default_period(self):
        """测试: 默认周期为 day"""
        exception = AIUsageLimitExceeded(used=10, limit=5)

        assert exception.period == "day"

    def test_ai_usage_limit_exceeded_status_code(self):
        """测试: 状态码为 429"""
        exception = AIUsageLimitExceeded(used=10, limit=5)

        assert exception.status_code == 429


class TestCheckAILimitDecorator:
    """AI 限制检查装饰器测试"""

    async def test_check_ai_limit_daily_exceeded(
        self, db_session, test_user
    ):
        """测试: 每日限制超出"""
        mock_service = AsyncMock()
        mock_service.check_daily_limit = AsyncMock(return_value=(False, 100, 100))
        mock_service.check_monthly_limit = AsyncMock(return_value=(True, 100, 1000))

        with patch("app.services.ai_limit_decorator.get_ai_usage_service", return_value=mock_service):
            @check_ai_limit(operation="test")
            async def test_function(user_id: int, db: AsyncSession):
                return "success"

            with pytest.raises(AIUsageLimitExceeded) as exc_info:
                await test_function(user_id=test_user.id, db=db_session)

            assert exc_info.value.period == "day"
            assert exc_info.value.used == 100

    async def test_check_ai_limit_monthly_exceeded(
        self, db_session, test_user
    ):
        """测试: 每月限制超出"""
        mock_service = AsyncMock()
        mock_service.check_daily_limit = AsyncMock(return_value=(True, 50, 100))
        mock_service.check_monthly_limit = AsyncMock(return_value=(False, 2000, 2000))

        with patch("app.services.ai_limit_decorator.get_ai_usage_service", return_value=mock_service):
            @check_ai_limit(operation="optimize")
            async def test_function(user_id: int, db: AsyncSession):
                return "success"

            with pytest.raises(AIUsageLimitExceeded) as exc_info:
                await test_function(user_id=test_user.id, db=db_session)

            assert exc_info.value.period == "month"

    async def test_check_ai_limit_within_limits(
        self, db_session, test_user
    ):
        """测试: 在限制范围内执行"""
        class ResultWithAttrs:
            def __init__(self):
                self.prompt_tokens = 10
                self.completion_tokens = 20
                self.total_tokens = 30
                self.provider = "test"
                self.model = "test-model"

        mock_service = AsyncMock()
        mock_service.check_daily_limit = AsyncMock(return_value=(True, 50, 100))
        mock_service.check_monthly_limit = AsyncMock(return_value=(True, 500, 2000))
        mock_service.record_usage = AsyncMock()

        with patch("app.services.ai_limit_decorator.get_ai_usage_service", return_value=mock_service):
            @check_ai_limit(operation="generate")
            async def test_function(user_id: int, db: AsyncSession):
                return ResultWithAttrs()

            result = await test_function(user_id=test_user.id, db=db_session)

            assert result is not None
            mock_service.record_usage.assert_called_once()

    async def test_check_ai_limit_no_db_or_user_id(self):
        """测试: 没有 db 或 user_id 时直接调用"""
        @check_ai_limit()
        async def test_function():
            return "direct_call"

        result = await test_function()
        assert result == "direct_call"

    async def test_check_ai_limit_extracts_db_from_args(
        self, db_session
    ):
        """测试: 从位置参数提取 db"""
        mock_service = AsyncMock()
        mock_service.check_daily_limit = AsyncMock(return_value=(True, 1, 100))
        mock_service.check_monthly_limit = AsyncMock(return_value=(True, 1, 1000))
        mock_service.record_usage = AsyncMock()

        with patch("app.services.ai_limit_decorator.get_ai_usage_service", return_value=mock_service):
            @check_ai_limit()
            async def test_function(db: AsyncSession, user_id: int):
                return "positional_args"

            result = await test_function(db_session, 123)
            assert result == "positional_args"

    async def test_check_ai_limit_records_usage_with_result(
        self, db_session, test_user
    ):
        """测试: 从返回结果记录使用量"""
        class MockResult:
            def __init__(self):
                self.prompt_tokens = 100
                self.completion_tokens = 200
                self.total_tokens = 300
                self.provider = "openai"
                self.model = "gpt-4"

        mock_service = AsyncMock()
        mock_service.check_daily_limit = AsyncMock(return_value=(True, 1, 100))
        mock_service.check_monthly_limit = AsyncMock(return_value=(True, 1, 1000))
        mock_service.record_usage = AsyncMock()

        with patch("app.services.ai_limit_decorator.get_ai_usage_service", return_value=mock_service):
            @check_ai_limit(operation="generate")
            async def test_function(user_id: int, db: AsyncSession):
                return MockResult()

            await test_function(user_id=test_user.id, db=db_session)

            mock_service.record_usage.assert_called_once()
            call_kwargs = mock_service.record_usage.call_args.kwargs
            assert call_kwargs["prompt_tokens"] == 100
            assert call_kwargs["completion_tokens"] == 200
            assert call_kwargs["total_tokens"] == 300
            assert call_kwargs["provider"] == "openai"
            assert call_kwargs["model"] == "gpt-4"
            assert call_kwargs["operation"] == "generate"

    async def test_check_ai_limit_result_without_dict(
        self, db_session, test_user
    ):
        """测试: 返回结果没有 __dict__ 属性"""
        mock_service = AsyncMock()
        mock_service.check_daily_limit = AsyncMock(return_value=(True, 1, 100))
        mock_service.check_monthly_limit = AsyncMock(return_value=(True, 1, 1000))
        mock_service.record_usage = AsyncMock()

        with patch("app.services.ai_limit_decorator.get_ai_usage_service", return_value=mock_service):
            @check_ai_limit()
            async def test_function(user_id: int, db: AsyncSession):
                return "string_result"  # 没有 __dict__

            result = await test_function(user_id=test_user.id, db=db_session)

            assert result == "string_result"
            # 不应该调用 record_usage
            mock_service.record_usage.assert_not_called()


class TestRequireAILimit:
    """require_ai_limit 依赖函数测试"""

    async def test_require_ai_limit_daily_exceeded(
        self, db_session
    ):
        """测试: 每日限制超出"""
        mock_service = AsyncMock()
        mock_service.check_daily_limit = AsyncMock(return_value=(False, 100, 100))
        mock_service.check_monthly_limit = AsyncMock(return_value=(True, 100, 1000))

        with patch("app.services.ai_limit_decorator.get_ai_usage_service", return_value=mock_service):
            with pytest.raises(AIUsageLimitExceeded) as exc_info:
                await require_ai_limit(user_id=123, db=db_session)

            assert exc_info.value.period == "day"

    async def test_require_ai_limit_monthly_exceeded(
        self, db_session
    ):
        """测试: 每月限制超出"""
        mock_service = AsyncMock()
        mock_service.check_daily_limit = AsyncMock(return_value=(True, 50, 100))
        mock_service.check_monthly_limit = AsyncMock(return_value=(False, 2000, 2000))

        with patch("app.services.ai_limit_decorator.get_ai_usage_service", return_value=mock_service):
            with pytest.raises(AIUsageLimitExceeded) as exc_info:
                await require_ai_limit(user_id=456, db=db_session)

            assert exc_info.value.period == "month"

    async def test_require_ai_limit_within_limits(
        self, db_session
    ):
        """测试: 在限制范围内通过"""
        mock_service = AsyncMock()
        mock_service.check_daily_limit = AsyncMock(return_value=(True, 50, 100))
        mock_service.check_monthly_limit = AsyncMock(return_value=(True, 500, 2000))

        with patch("app.services.ai_limit_decorator.get_ai_usage_service", return_value=mock_service):
            result = await require_ai_limit(user_id=789, db=db_session, operation="optimize")

            assert result is None

    async def test_require_ai_limit_default_operation(
        self, db_session
    ):
        """测试: 默认操作为 generate"""
        mock_service = AsyncMock()
        mock_service.check_daily_limit = AsyncMock(return_value=(True, 1, 100))
        mock_service.check_monthly_limit = AsyncMock(return_value=(True, 1, 1000))

        with patch("app.services.ai_limit_decorator.get_ai_usage_service", return_value=mock_service):
            result = await require_ai_limit(user_id=999, db=db_session)

            assert result is None


class TestAILimitIntegration:
    """AI 限流集成测试"""

    async def test_decorator_preserves_function_attributes(
        self, db_session, test_user
    ):
        """测试: 装饰器保留原函数属性"""
        mock_service = AsyncMock()
        mock_service.check_daily_limit = AsyncMock(return_value=(True, 1, 100))
        mock_service.check_monthly_limit = AsyncMock(return_value=(True, 1, 1000))
        mock_service.record_usage = AsyncMock()

        with patch("app.services.ai_limit_decorator.get_ai_usage_service", return_value=mock_service):
            @check_ai_limit(operation="test")
            async def original_function(user_id: int, db: AsyncSession):
                """原函数文档"""
                return "result"

            # 检查函数名和文档被保留
            assert original_function.__name__ == "original_function"
            assert "原函数文档" in original_function.__doc__ or original_function.__doc__ == "原函数文档"

    async def test_decorator_with_kwargs(
        self, db_session, test_user
    ):
        """测试: 装饰器处理关键字参数"""
        mock_service = AsyncMock()
        mock_service.check_daily_limit = AsyncMock(return_value=(True, 1, 100))
        mock_service.check_monthly_limit = AsyncMock(return_value=(True, 1, 1000))
        mock_service.record_usage = AsyncMock()

        with patch("app.services.ai_limit_decorator.get_ai_usage_service", return_value=mock_service):
            @check_ai_limit()
            async def test_function(user_id: int, db: AsyncSession, extra_param: str = "default"):
                return extra_param

            result = await test_function(user_id=test_user.id, db=db_session, extra_param="custom")

            assert result == "custom"

    async def test_multiple_operations_separate_tracking(
        self, db_session
    ):
        """测试: 不同操作分别跟踪"""
        class ResultWithAttrs:
            def __init__(self, value):
                self.value = value
                self.prompt_tokens = 10
                self.completion_tokens = 10
                self.total_tokens = 20
                self.provider = "test"
                self.model = "test-model"

        mock_service = AsyncMock()
        mock_service.check_daily_limit = AsyncMock(return_value=(True, 1, 100))
        mock_service.check_monthly_limit = AsyncMock(return_value=(True, 1, 1000))
        mock_service.record_usage = AsyncMock()

        with patch("app.services.ai_limit_decorator.get_ai_usage_service", return_value=mock_service):
            @check_ai_limit(operation="generate")
            async def generate_func(user_id: int, db: AsyncSession):
                return ResultWithAttrs("generated")

            @check_ai_limit(operation="optimize")
            async def optimize_func(user_id: int, db: AsyncSession):
                return ResultWithAttrs("optimized")

            await generate_func(user_id=1, db=db_session)
            await optimize_func(user_id=1, db=db_session)

            # 验证 record_usage 被调用两次，operation 不同
            assert mock_service.record_usage.call_count == 2
            operations = [call.kwargs["operation"] for call in mock_service.record_usage.call_args_list]
            assert "generate" in operations
            assert "optimize" in operations
