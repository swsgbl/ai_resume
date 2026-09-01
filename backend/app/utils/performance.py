"""
缓存和性能优化工具
"""

import asyncio
import hashlib
from typing import Any, Optional, Callable
from functools import wraps
from datetime import datetime, timedelta
from loguru import logger


class MemoryCache:
    """
    内存缓存实现
    生产环境建议使用Redis替代
    """

    _cache = {}
    _expiry = {}

    @classmethod
    def get(cls, key: str) -> Optional[Any]:
        """获取缓存值"""
        if key in cls._cache:
            # 检查是否过期
            if key in cls._expiry:
                if datetime.now() > cls._expiry[key]:
                    cls.delete(key)
                    return None
            return cls._cache[key]
        return None

    @classmethod
    def set(cls, key: str, value: Any, ttl: int = 300) -> None:
        """
        设置缓存值

        Args:
            key: 缓存键
            value: 缓存值
            ttl: 过期时间（秒），默认5分钟
        """
        cls._cache[key] = value
        cls._expiry[key] = datetime.now() + timedelta(seconds=ttl)

    @classmethod
    def delete(cls, key: str) -> None:
        """删除缓存"""
        cls._cache.pop(key, None)
        cls._expiry.pop(key, None)

    @classmethod
    def clear(cls) -> None:
        """清空所有缓存"""
        cls._cache.clear()
        cls._expiry.clear()

    @classmethod
    def cleanup_expired(cls) -> int:
        """清理过期缓存，返回清理数量"""
        now = datetime.now()
        expired_keys = [key for key, expiry in cls._expiry.items() if now > expiry]
        for key in expired_keys:
            cls.delete(key)
        return len(expired_keys)

    @classmethod
    def get_stats(cls) -> dict:
        """获取缓存统计"""
        return {"total_keys": len(cls._cache), "memory_usage_estimate": len(str(cls._cache))}


def cache_key_builder(*args, **kwargs) -> str:
    """构建缓存键"""
    key_parts = [str(arg) for arg in args]
    key_parts.extend(f"{k}:{v}" for k, v in sorted(kwargs.items()))
    key_string = ":".join(key_parts)
    return hashlib.md5(key_string.encode()).hexdigest()


def cached(ttl: int = 300, key_prefix: str = ""):
    """
    缓存装饰器

    Args:
        ttl: 缓存过期时间（秒）
        key_prefix: 缓存键前缀
    """

    def decorator(func: Callable):
        @wraps(func)
        async def async_wrapper(*args, **kwargs):
            cache_key = f"{key_prefix}:{func.__name__}:{cache_key_builder(*args, **kwargs)}"

            # 尝试从缓存获取
            cached_value = MemoryCache.get(cache_key)
            if cached_value is not None:
                logger.debug(f"缓存命中: {cache_key}")
                return cached_value

            # 执行函数并缓存结果
            result = await func(*args, **kwargs)
            MemoryCache.set(cache_key, result, ttl)
            logger.debug(f"缓存设置: {cache_key}")
            return result

        @wraps(func)
        def sync_wrapper(*args, **kwargs):
            cache_key = f"{key_prefix}:{func.__name__}:{cache_key_builder(*args, **kwargs)}"

            cached_value = MemoryCache.get(cache_key)
            if cached_value is not None:
                return cached_value

            result = func(*args, **kwargs)
            MemoryCache.set(cache_key, result, ttl)
            return result

        if asyncio.iscoroutinefunction(func):
            return async_wrapper
        return sync_wrapper

    return decorator


def invalidate_cache(key_pattern: str):
    """
    缓存失效装饰器
    在函数执行后清除匹配的缓存
    """

    def decorator(func: Callable):
        @wraps(func)
        async def async_wrapper(*args, **kwargs):
            result = await func(*args, **kwargs)
            # 清除匹配的缓存
            keys_to_delete = [key for key in MemoryCache._cache.keys() if key_pattern in key]
            for key in keys_to_delete:
                MemoryCache.delete(key)
            logger.debug(f"缓存失效: {len(keys_to_delete)} 个键已清除")
            return result

        @wraps(func)
        def sync_wrapper(*args, **kwargs):
            result = func(*args, **kwargs)
            keys_to_delete = [key for key in MemoryCache._cache.keys() if key_pattern in key]
            for key in keys_to_delete:
                MemoryCache.delete(key)
            return result

        if asyncio.iscoroutinefunction(func):
            return async_wrapper
        return sync_wrapper

    return decorator


class PerformanceMonitor:
    """性能监控工具"""

    _metrics = {
        "request_count": 0,
        "error_count": 0,
        "total_response_time": 0,
        "slowest_request": 0,
        "endpoint_stats": {},
    }

    @classmethod
    def record_request(cls, endpoint: str, response_time: float, success: bool = True):
        """记录请求指标"""
        cls._metrics["request_count"] += 1
        cls._metrics["total_response_time"] += response_time

        if not success:
            cls._metrics["error_count"] += 1

        if response_time > cls._metrics["slowest_request"]:
            cls._metrics["slowest_request"] = response_time

        # 端点统计
        if endpoint not in cls._metrics["endpoint_stats"]:
            cls._metrics["endpoint_stats"][endpoint] = {"count": 0, "total_time": 0, "errors": 0}

        cls._metrics["endpoint_stats"][endpoint]["count"] += 1
        cls._metrics["endpoint_stats"][endpoint]["total_time"] += response_time
        if not success:
            cls._metrics["endpoint_stats"][endpoint]["errors"] += 1

    @classmethod
    def get_metrics(cls) -> dict:
        """获取性能指标"""
        request_count = cls._metrics["request_count"]
        return {
            "request_count": request_count,
            "error_count": cls._metrics["error_count"],
            "error_rate": cls._metrics["error_count"] / max(request_count, 1),
            "avg_response_time": cls._metrics["total_response_time"] / max(request_count, 1),
            "slowest_request": cls._metrics["slowest_request"],
            "endpoint_stats": cls._metrics["endpoint_stats"],
        }

    @classmethod
    def reset_metrics(cls):
        """重置指标"""
        cls._metrics = {
            "request_count": 0,
            "error_count": 0,
            "total_response_time": 0,
            "slowest_request": 0,
            "endpoint_stats": {},
        }


def timed(func: Callable):
    """计时装饰器"""

    @wraps(func)
    async def async_wrapper(*args, **kwargs):
        start_time = datetime.now()
        try:
            result = await func(*args, **kwargs)
            success = True
            return result
        except Exception:
            success = False
            raise
        finally:
            elapsed = (datetime.now() - start_time).total_seconds()
            PerformanceMonitor.record_request(func.__name__, elapsed, success)
            if elapsed > 1.0:  # 超过1秒的慢请求
                logger.warning(f"慢请求: {func.__name__} 耗时 {elapsed:.2f}s")

    @wraps(func)
    def sync_wrapper(*args, **kwargs):
        start_time = datetime.now()
        try:
            result = func(*args, **kwargs)
            success = True
            return result
        except Exception:
            success = False
            raise
        finally:
            elapsed = (datetime.now() - start_time).total_seconds()
            PerformanceMonitor.record_request(func.__name__, elapsed, success)

    if asyncio.iscoroutinefunction(func):
        return async_wrapper
    return sync_wrapper


class ConnectionPool:
    """
    连接池管理
    用于管理数据库和外部服务连接
    """

    _pools = {}

    @classmethod
    def get_pool(cls, name: str) -> Optional[Any]:
        """获取连接池"""
        return cls._pools.get(name)

    @classmethod
    def register_pool(cls, name: str, pool: Any):
        """注册连接池"""
        cls._pools[name] = pool
        logger.info(f"连接池已注册: {name}")

    @classmethod
    def close_all(cls):
        """关闭所有连接池"""
        for name, pool in cls._pools.items():
            if hasattr(pool, "close"):
                pool.close()
            elif hasattr(pool, "disconnect"):
                pool.disconnect()
            logger.info(f"连接池已关闭: {name}")
        cls._pools.clear()


# 批量处理工具
async def batch_process(items: list, processor: Callable, batch_size: int = 10):
    """
    批量处理工具

    Args:
        items: 待处理项目列表
        processor: 处理函数
        batch_size: 批次大小
    """
    results = []
    for i in range(0, len(items), batch_size):
        batch = items[i : i + batch_size]
        batch_results = await asyncio.gather(*[processor(item) for item in batch])
        results.extend(batch_results)
    return results


# 重试装饰器
def retry(max_attempts: int = 3, delay: float = 1.0, backoff: float = 2.0):
    """
    重试装饰器

    Args:
        max_attempts: 最大重试次数
        delay: 初始延迟（秒）
        backoff: 延迟增长倍数
    """

    def decorator(func: Callable):
        @wraps(func)
        async def async_wrapper(*args, **kwargs):
            current_delay = delay
            last_exception = None

            for attempt in range(max_attempts):
                try:
                    return await func(*args, **kwargs)
                except Exception as e:
                    last_exception = e
                    if attempt < max_attempts - 1:
                        logger.warning(
                            f"{func.__name__} 失败 (尝试 {attempt + 1}/{max_attempts}): {e}"
                        )
                        await asyncio.sleep(current_delay)
                        current_delay *= backoff

            logger.error(f"{func.__name__} 在 {max_attempts} 次尝试后失败")
            raise last_exception

        @wraps(func)
        def sync_wrapper(*args, **kwargs):
            import time

            current_delay = delay
            last_exception = None

            for attempt in range(max_attempts):
                try:
                    return func(*args, **kwargs)
                except Exception as e:
                    last_exception = e
                    if attempt < max_attempts - 1:
                        logger.warning(
                            f"{func.__name__} 失败 (尝试 {attempt + 1}/{max_attempts}): {e}"
                        )
                        time.sleep(current_delay)
                        current_delay *= backoff

            raise last_exception

        if asyncio.iscoroutinefunction(func):
            return async_wrapper
        return sync_wrapper

    return decorator
