"""
日志管理模块 - 统一日志配置、分级管理、审计追踪
"""

import sys
import os
from datetime import datetime
from pathlib import Path
from typing import Optional, Dict, Any
from loguru import logger
from functools import wraps
import json


class LogConfig:
    """日志配置"""

    # 日志目录
    LOG_DIR = Path("logs")

    # 日志级别
    LOG_LEVEL = os.getenv("LOG_LEVEL", "INFO")

    # 日志文件配置
    LOG_FILES = {
        "app": {
            "path": "logs/app.log",
            "rotation": "10 MB",
            "retention": "30 days",
            "level": "INFO",
            "description": "应用主日志",
        },
        "error": {
            "path": "logs/error.log",
            "rotation": "10 MB",
            "retention": "90 days",
            "level": "ERROR",
            "description": "错误日志",
        },
        "access": {
            "path": "logs/access.log",
            "rotation": "50 MB",
            "retention": "7 days",
            "level": "INFO",
            "description": "访问日志",
        },
        "audit": {
            "path": "logs/audit.log",
            "rotation": "20 MB",
            "retention": "365 days",
            "level": "INFO",
            "description": "审计日志（数据操作记录）",
        },
        "ai": {
            "path": "logs/ai_service.log",
            "rotation": "20 MB",
            "retention": "30 days",
            "level": "DEBUG",
            "description": "AI服务日志",
        },
        "security": {
            "path": "logs/security.log",
            "rotation": "10 MB",
            "retention": "90 days",
            "level": "WARNING",
            "description": "安全事件日志",
        },
        "performance": {
            "path": "logs/performance.log",
            "rotation": "20 MB",
            "retention": "14 days",
            "level": "INFO",
            "description": "性能监控日志",
        },
    }

    # 日志格式
    CONSOLE_FORMAT = (
        "<green>{time:YYYY-MM-DD HH:mm:ss.SSS}</green> | "
        "<level>{level: <8}</level> | "
        "<cyan>{name}</cyan>:<cyan>{function}</cyan>:<cyan>{line}</cyan> | "
        "<level>{message}</level>"
    )

    FILE_FORMAT = (
        "{time:YYYY-MM-DD HH:mm:ss.SSS} | "
        "{level: <8} | "
        "{name}:{function}:{line} | "
        "{message}"
    )

    JSON_FORMAT = True  # 是否使用JSON格式（便于日志分析）


class LogManager:
    """日志管理器"""

    _initialized = False
    _loggers = {}

    @classmethod
    def init_logging(cls, debug: bool = False):
        """初始化日志系统"""
        if cls._initialized:
            return

        # 创建日志目录
        LogConfig.LOG_DIR.mkdir(parents=True, exist_ok=True)

        # 移除默认处理器
        logger.remove()

        # 添加控制台输出
        log_level = "DEBUG" if debug else LogConfig.LOG_LEVEL
        logger.add(
            sys.stdout,
            colorize=True,
            format=LogConfig.CONSOLE_FORMAT,
            level=log_level,
            filter=lambda record: record["level"].name != "ACCESS",
        )

        # 添加各类型日志文件
        for log_type, config in LogConfig.LOG_FILES.items():
            logger.add(
                config["path"],
                rotation=config["rotation"],
                retention=config["retention"],
                compression="zip",
                level=config["level"],
                format=LogConfig.FILE_FORMAT,
                encoding="utf-8",
                enqueue=True,  # 异步写入
                filter=lambda record, lt=log_type: cls._filter_log(record, lt),
            )

        cls._initialized = True
        logger.info("日志系统初始化完成")

    @classmethod
    def _filter_log(cls, record, log_type: str) -> bool:
        """日志过滤器"""
        extra = record.get("extra", {})

        # 根据日志类型过滤
        if log_type == "error":
            return record["level"].name in ["ERROR", "CRITICAL"]
        elif log_type == "access":
            return extra.get("log_type") == "access"
        elif log_type == "audit":
            return extra.get("log_type") == "audit"
        elif log_type == "ai":
            return extra.get("log_type") == "ai"
        elif log_type == "security":
            return extra.get("log_type") == "security"
        elif log_type == "performance":
            return extra.get("log_type") == "performance"
        elif log_type == "app":
            # 主日志记录所有非特殊类型
            return extra.get("log_type") not in ["access", "audit", "ai", "security", "performance"]

        return True

    @classmethod
    def get_logger(cls, name: str = "app"):
        """获取指定类型的日志记录器"""
        if name not in cls._loggers:
            cls._loggers[name] = logger.bind(log_type=name)
        return cls._loggers[name]


# 便捷日志记录函数
class AppLogger:
    """应用日志记录器"""

    @staticmethod
    def info(message: str, **kwargs):
        logger.info(message, **kwargs)

    @staticmethod
    def debug(message: str, **kwargs):
        logger.debug(message, **kwargs)

    @staticmethod
    def warning(message: str, **kwargs):
        logger.warning(message, **kwargs)

    @staticmethod
    def error(message: str, exc_info: bool = False, **kwargs):
        if exc_info:
            logger.exception(message, **kwargs)
        else:
            logger.error(message, **kwargs)

    @staticmethod
    def critical(message: str, **kwargs):
        logger.critical(message, **kwargs)


class AccessLogger:
    """访问日志记录器"""

    _logger = logger.bind(log_type="access")

    @classmethod
    def log_request(
        cls,
        method: str,
        path: str,
        client_ip: str,
        status_code: int,
        response_time: float,
        user_id: Optional[int] = None,
        user_agent: Optional[str] = None,
    ):
        """记录HTTP请求"""
        log_data = {
            "event": "http_request",
            "method": method,
            "path": path,
            "client_ip": client_ip,
            "status_code": status_code,
            "response_time_ms": round(response_time * 1000, 2),
            "user_id": user_id,
            "user_agent": user_agent,
            "timestamp": datetime.now().isoformat(),
        }
        cls._logger.info(json.dumps(log_data, ensure_ascii=False))


class AuditLogger:
    """审计日志记录器 - 记录数据操作"""

    _logger = logger.bind(log_type="audit")

    @classmethod
    def log_operation(
        cls,
        action: str,
        resource_type: str,
        resource_id: Any,
        user_id: Optional[int] = None,
        old_value: Any = None,
        new_value: Any = None,
        ip_address: Optional[str] = None,
        details: Optional[Dict] = None,
    ):
        """记录数据操作"""
        log_data = {
            "event": "data_operation",
            "action": action,  # create, read, update, delete
            "resource_type": resource_type,  # user, resume, template
            "resource_id": str(resource_id),
            "user_id": user_id,
            "ip_address": ip_address,
            "timestamp": datetime.now().isoformat(),
        }

        if old_value is not None:
            log_data["old_value"] = str(old_value)[:500]  # 截断防止过长
        if new_value is not None:
            log_data["new_value"] = str(new_value)[:500]
        if details:
            log_data["details"] = details

        cls._logger.info(json.dumps(log_data, ensure_ascii=False))

    @classmethod
    def log_login(cls, user_id: int, ip_address: str, success: bool, reason: str = None):
        """记录登录事件"""
        log_data = {
            "event": "user_login",
            "user_id": user_id,
            "ip_address": ip_address,
            "success": success,
            "reason": reason,
            "timestamp": datetime.now().isoformat(),
        }
        cls._logger.info(json.dumps(log_data, ensure_ascii=False))

    @classmethod
    def log_logout(cls, user_id: int, ip_address: str):
        """记录登出事件"""
        log_data = {
            "event": "user_logout",
            "user_id": user_id,
            "ip_address": ip_address,
            "timestamp": datetime.now().isoformat(),
        }
        cls._logger.info(json.dumps(log_data, ensure_ascii=False))


class AILogger:
    """AI服务日志记录器"""

    _logger = logger.bind(log_type="ai")

    @classmethod
    def log_request(
        cls,
        action: str,
        model: str,
        prompt_tokens: int = 0,
        completion_tokens: int = 0,
        response_time: float = 0,
        success: bool = True,
        error: str = None,
        user_id: Optional[int] = None,
    ):
        """记录AI请求"""
        log_data = {
            "event": "ai_request",
            "action": action,  # generate, optimize, translate, parse
            "model": model,
            "prompt_tokens": prompt_tokens,
            "completion_tokens": completion_tokens,
            "total_tokens": prompt_tokens + completion_tokens,
            "response_time_ms": round(response_time * 1000, 2),
            "success": success,
            "user_id": user_id,
            "timestamp": datetime.now().isoformat(),
        }

        if error:
            log_data["error"] = error

        if success:
            cls._logger.info(json.dumps(log_data, ensure_ascii=False))
        else:
            cls._logger.error(json.dumps(log_data, ensure_ascii=False))


class SecurityLogger:
    """安全事件日志记录器"""

    _logger = logger.bind(log_type="security")

    @classmethod
    def log_event(
        cls,
        event_type: str,
        severity: str,
        ip_address: str,
        user_id: Optional[int] = None,
        details: Optional[Dict] = None,
    ):
        """记录安全事件"""
        log_data = {
            "event": "security_event",
            "event_type": event_type,
            "severity": severity,  # low, medium, high, critical
            "ip_address": ip_address,
            "user_id": user_id,
            "details": details,
            "timestamp": datetime.now().isoformat(),
        }

        if severity in ["high", "critical"]:
            cls._logger.critical(json.dumps(log_data, ensure_ascii=False))
        elif severity == "medium":
            cls._logger.warning(json.dumps(log_data, ensure_ascii=False))
        else:
            cls._logger.info(json.dumps(log_data, ensure_ascii=False))

    @classmethod
    def log_rate_limit(cls, ip_address: str, path: str, user_id: Optional[int] = None):
        """记录速率限制事件"""
        cls.log_event(
            event_type="rate_limit_exceeded",
            severity="medium",
            ip_address=ip_address,
            user_id=user_id,
            details={"path": path},
        )

    @classmethod
    def log_invalid_input(cls, ip_address: str, input_type: str, user_id: Optional[int] = None):
        """记录非法输入事件"""
        cls.log_event(
            event_type="invalid_input_detected",
            severity="high",
            ip_address=ip_address,
            user_id=user_id,
            details={"input_type": input_type},
        )

    @classmethod
    def log_auth_failure(cls, ip_address: str, reason: str, username: str = None):
        """记录认证失败"""
        cls.log_event(
            event_type="authentication_failure",
            severity="medium",
            ip_address=ip_address,
            details={"reason": reason, "username": username},
        )


class PerformanceLogger:
    """性能监控日志记录器"""

    _logger = logger.bind(log_type="performance")

    @classmethod
    def log_slow_request(cls, path: str, method: str, response_time: float, threshold: float = 1.0):
        """记录慢请求"""
        log_data = {
            "event": "slow_request",
            "path": path,
            "method": method,
            "response_time_ms": round(response_time * 1000, 2),
            "threshold_ms": threshold * 1000,
            "timestamp": datetime.now().isoformat(),
        }
        cls._logger.warning(json.dumps(log_data, ensure_ascii=False))

    @classmethod
    def log_memory_usage(cls, used_mb: float, total_mb: float):
        """记录内存使用"""
        log_data = {
            "event": "memory_usage",
            "used_mb": round(used_mb, 2),
            "total_mb": round(total_mb, 2),
            "usage_percent": round(used_mb / total_mb * 100, 2) if total_mb > 0 else 0,
            "timestamp": datetime.now().isoformat(),
        }
        cls._logger.info(json.dumps(log_data, ensure_ascii=False))

    @classmethod
    def log_db_query(cls, query: str, duration: float, rows_affected: int = 0):
        """记录数据库查询"""
        log_data = {
            "event": "db_query",
            "query": query[:200],  # 截断
            "duration_ms": round(duration * 1000, 2),
            "rows_affected": rows_affected,
            "timestamp": datetime.now().isoformat(),
        }
        if duration > 0.5:  # 超过500ms的慢查询
            cls._logger.warning(json.dumps(log_data, ensure_ascii=False))
        else:
            cls._logger.debug(json.dumps(log_data, ensure_ascii=False))


# 日志装饰器
def log_function_call(log_type: str = "app"):
    """函数调用日志装饰器"""

    def decorator(func):
        @wraps(func)
        async def async_wrapper(*args, **kwargs):
            func_name = f"{func.__module__}.{func.__name__}"
            start_time = datetime.now()

            try:
                result = await func(*args, **kwargs)
                duration = (datetime.now() - start_time).total_seconds()
                logger.bind(log_type=log_type).debug(
                    f"函数调用成功: {func_name} | 耗时: {duration:.3f}s"
                )
                return result
            except Exception as e:
                duration = (datetime.now() - start_time).total_seconds()
                logger.bind(log_type=log_type).error(
                    f"函数调用失败: {func_name} | 耗时: {duration:.3f}s | 错误: {str(e)}"
                )
                raise

        @wraps(func)
        def sync_wrapper(*args, **kwargs):
            func_name = f"{func.__module__}.{func.__name__}"
            start_time = datetime.now()

            try:
                result = func(*args, **kwargs)
                duration = (datetime.now() - start_time).total_seconds()
                logger.bind(log_type=log_type).debug(
                    f"函数调用成功: {func_name} | 耗时: {duration:.3f}s"
                )
                return result
            except Exception as e:
                duration = (datetime.now() - start_time).total_seconds()
                logger.bind(log_type=log_type).error(
                    f"函数调用失败: {func_name} | 耗时: {duration:.3f}s | 错误: {str(e)}"
                )
                raise

        import asyncio

        if asyncio.iscoroutinefunction(func):
            return async_wrapper
        return sync_wrapper

    return decorator


# 初始化日志系统的便捷函数
def setup_logging(debug: bool = False):
    """设置日志系统"""
    LogManager.init_logging(debug=debug)
