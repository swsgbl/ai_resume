"""
性能测试脚本

测试后端 API 性能，包括：
- 数据库查询性能
- API 响应时间
- 并发请求处理
"""
import asyncio
import time
import statistics
import pytest
from httpx import AsyncClient
from typing import List


class PerformanceMetrics:
    """性能指标收集"""

    def __init__(self):
        self.response_times: List[float] = []
        self.success_count = 0
        self.error_count = 0

    def add_response(self, duration: float, success: bool):
        self.response_times.append(duration)
        if success:
            self.success_count += 1
        else:
            self.error_count += 1

    @property
    def total_requests(self) -> int:
        return len(self.response_times)

    def get_stats(self) -> dict:
        if not self.response_times:
            return {"message": "No data"}

        return {
            "total_requests": len(self.response_times),
            "success": self.success_count,
            "errors": self.error_count,
            "avg_ms": statistics.mean(self.response_times) * 1000,
            "min_ms": min(self.response_times) * 1000,
            "max_ms": max(self.response_times) * 1000,
            "median_ms": statistics.median(self.response_times) * 1000,
        }


async def _test_endpoint_performance(
    client: AsyncClient,
    url: str,
    iterations: int = 10
) -> PerformanceMetrics:
    """测试单个端点性能"""
    metrics = PerformanceMetrics()

    for _ in range(iterations):
        start = time.time()
        try:
            response = await client.get(url)
            duration = time.time() - start
            metrics.add_response(duration, 200 <= response.status_code < 300)
        except Exception:
            duration = time.time() - start
            metrics.add_response(duration, False)

    return metrics


async def _test_concurrent_requests(
    base_url: str,
    endpoint: str,
    concurrent_users: int = 10,
    requests_per_user: int = 5
) -> dict:
    """测试并发请求性能"""
    metrics = PerformanceMetrics()

    async def user_requests():
        async with AsyncClient() as client:
            for _ in range(requests_per_user):
                start = time.time()
                try:
                    response = await client.get(f"{base_url}{endpoint}")
                    duration = time.time() - start
                    metrics.add_response(duration, 200 <= response.status_code < 300)
                except Exception:
                    duration = time.time() - start
                    metrics.add_response(duration, False)

    start_time = time.time()
    await asyncio.gather(*[user_requests() for _ in range(concurrent_users)])
    total_time = time.time() - start_time

    stats = metrics.get_stats()
    stats["total_time"] = f"{total_time:.2f}s"
    stats["requests_per_second"] = f"{len(metrics.response_times) / total_time:.2f}"

    return stats


class TestPerformance:
    """性能测试套件"""

    async def test_database_connection_speed(self):
        """测试数据库连接速度"""
        from sqlalchemy.ext.asyncio import create_async_engine
        from sqlalchemy import text

        engine = create_async_engine(
            "sqlite+aiosqlite:///:memory:",
            echo=False
        )

        times = []
        for _ in range(10):
            start = time.time()
            async with engine.begin() as conn:
                await conn.execute(text("SELECT 1"))
            times.append((time.time() - start) * 1000)

        await engine.dispose()

        avg = statistics.mean(times)
        print(f"✅ 数据库连接平均耗时: {avg:.2f}ms")
        assert avg < 10, f"数据库连接太慢: {avg:.2f}ms"

    async def test_health_endpoint(self):
        """测试健康检查端点性能"""
        # 检查后端服务是否运行
        try:
            async with AsyncClient(base_url="http://127.0.0.1:8000") as client:
                quick_response = await client.get("/health", timeout=1.0)
                if quick_response.status_code != 200:
                    pytest.skip("后端服务未运行，跳过性能测试")
        except Exception:
            pytest.skip("后端服务未运行，跳过性能测试")

        async with AsyncClient(base_url="http://127.0.0.1:8000") as client:
            metrics = await _test_endpoint_performance(client, "/health", 20)

            stats = metrics.get_stats()
            print(f"✅ Health 端点性能: {stats['avg_ms']:.2f}ms (平均)")

            assert stats["avg_ms"] < 10, f"Health 端点响应太慢: {stats['avg_ms']:.2f}ms"
            assert metrics.success_count == stats["total_requests"], "所有请求都应该成功"

    async def test_templates_endpoint_performance(self):
        """测试模板列表端点性能"""
        # 检查后端服务是否运行
        try:
            async with AsyncClient(base_url="http://127.0.0.1:8000") as client:
                quick_response = await client.get("/health", timeout=1.0)
                if quick_response.status_code != 200:
                    pytest.skip("后端服务未运行，跳过性能测试")
        except Exception:
            pytest.skip("后端服务未运行，跳过性能测试")

        async with AsyncClient(base_url="http://127.0.0.1:8000") as client:
            metrics = await _test_endpoint_performance(client, "/api/v1/templates", 10)

            stats = metrics.get_stats()
            print(f"✅ Templates 端点性能: {stats['avg_ms']:.2f}ms (平均)")

            assert stats["avg_ms"] < 100, f"Templates 端点响应太慢: {stats['avg_ms']:.2f}ms"

    async def test_concurrent_load(self):
        """测试并发负载"""
        # 检查后端服务是否运行
        try:
            async with AsyncClient(base_url="http://127.0.0.1:8000") as client:
                quick_response = await client.get("/health", timeout=1.0)
                if quick_response.status_code != 200:
                    pytest.skip("后端服务未运行，跳过性能测试")
        except Exception:
            pytest.skip("后端服务未运行，跳过性能测试")

        stats = await _test_concurrent_requests(
            "http://127.0.0.1:8000",
            "/health",
            concurrent_users=20,
            requests_per_user=5
        )

        print(f"✅ 并发测试: {stats['total_requests']} 请求, "
              f"{stats['avg_ms']:.2f}ms 平均响应, "
              f"{stats['requests_per_second']} 请求/秒")

        assert stats["avg_ms"] < 100, f"并发响应太慢: {stats['avg_ms']:.2f}ms"
        assert stats["errors"] == 0, f"存在 {stats['errors']} 个错误"


if __name__ == "__main__":
    import pytest

    pytest.main([__file__, "-v", "-s"])
