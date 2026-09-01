"""
安全工具模块 - 输入验证、XSS防护、SQL注入防护
"""

import re
import html
from typing import Any
from fastapi import HTTPException, status


class SecurityValidator:
    """安全验证器"""

    # 危险字符和模式
    SQL_INJECTION_PATTERNS = [
        r"(\b(SELECT|INSERT|UPDATE|DELETE|DROP|CREATE|ALTER|TRUNCATE)\b)",
        r"(--|#|/\*|\*/)",
        r"(\b(OR|AND)\b\s+\d+\s*=\s*\d+)",
        r"(\b(UNION)\b\s+\b(SELECT)\b)",
        r"(;\s*(SELECT|INSERT|UPDATE|DELETE|DROP))",
    ]

    XSS_PATTERNS = [
        r"<script[^>]*>.*?</script>",
        r"javascript:",
        r"on\w+\s*=",
        r"<iframe[^>]*>",
        r"<object[^>]*>",
        r"<embed[^>]*>",
    ]

    # 文件上传白名单
    ALLOWED_FILE_TYPES = {
        "application/pdf": [".pdf"],
        "application/msword": [".doc"],
        "application/vnd.openxmlformats-officedocument.wordprocessingml.document": [".docx"],
        "image/jpeg": [".jpg", ".jpeg"],
        "image/png": [".png"],
    }

    MAX_FILE_SIZE = 10 * 1024 * 1024  # 10MB

    @classmethod
    def sanitize_string(cls, value: str) -> str:
        """清理字符串，防止XSS攻击"""
        if not isinstance(value, str):
            return value

        # HTML实体编码
        sanitized = html.escape(value)

        # 移除潜在的危险内容
        for pattern in cls.XSS_PATTERNS:
            sanitized = re.sub(pattern, "", sanitized, flags=re.IGNORECASE)

        return sanitized

    @classmethod
    def validate_sql_safe(cls, value: str) -> bool:
        """验证是否安全（无SQL注入风险）"""
        if not isinstance(value, str):
            return True

        for pattern in cls.SQL_INJECTION_PATTERNS:
            if re.search(pattern, value, re.IGNORECASE):
                return False

        return True

    @classmethod
    def validate_email(cls, email: str) -> bool:
        """验证邮箱格式"""
        pattern = r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$"
        return bool(re.match(pattern, email))

    @classmethod
    def validate_phone(cls, phone: str) -> bool:
        """验证手机号格式（中国大陆）"""
        pattern = r"^1[3-9]\d{9}$"
        return bool(re.match(pattern, phone))

    @classmethod
    def validate_password_strength(cls, password: str) -> dict:
        """验证密码强度"""
        result = {"is_valid": True, "score": 0, "messages": []}

        # 长度检查
        if len(password) < 8:
            result["messages"].append("密码长度至少8位")
            result["is_valid"] = False
        else:
            result["score"] += 1

        # 包含数字
        if re.search(r"\d", password):
            result["score"] += 1
        else:
            result["messages"].append("建议包含数字")

        # 包含小写字母
        if re.search(r"[a-z]", password):
            result["score"] += 1
        else:
            result["messages"].append("建议包含小写字母")

        # 包含大写字母
        if re.search(r"[A-Z]", password):
            result["score"] += 1
        else:
            result["messages"].append("建议包含大写字母")

        # 包含特殊字符
        if re.search(r'[!@#$%^&*(),.?":{}|<>]', password):
            result["score"] += 1
        else:
            result["messages"].append("建议包含特殊字符")

        return result

    @classmethod
    def validate_file_upload(cls, content_type: str, file_size: int, filename: str) -> dict:
        """验证文件上传"""
        result = {"is_valid": True, "message": ""}

        # 检查文件类型
        if content_type not in cls.ALLOWED_FILE_TYPES:
            result["is_valid"] = False
            result["message"] = "不支持的文件类型"
            return result

        # 检查文件扩展名
        ext = "." + filename.split(".")[-1].lower() if "." in filename else ""
        if ext not in cls.ALLOWED_FILE_TYPES.get(content_type, []):
            result["is_valid"] = False
            result["message"] = "文件扩展名与类型不匹配"
            return result

        # 检查文件大小
        if file_size > cls.MAX_FILE_SIZE:
            result["is_valid"] = False
            result["message"] = f"文件大小超过限制({cls.MAX_FILE_SIZE // 1024 // 1024}MB)"
            return result

        return result

    @classmethod
    def sanitize_filename(cls, filename: str) -> str:
        """清理文件名"""
        # 移除路径遍历字符
        filename = filename.replace("..", "").replace("/", "").replace("\\", "")

        # 只保留安全字符
        safe_chars = re.sub(r"[^a-zA-Z0-9._-]", "_", filename)

        return safe_chars


class RateLimiter:
    """简单的速率限制器（内存版本，生产环境建议使用Redis）"""

    _requests = {}  # {key: [(timestamp, count)]}

    @classmethod
    def check_rate_limit(cls, key: str, max_requests: int = 100, window_seconds: int = 60) -> bool:
        """检查是否超过速率限制"""
        import time

        current_time = time.time()
        window_start = current_time - window_seconds

        # 获取该key的请求记录
        if key not in cls._requests:
            cls._requests[key] = []

        # 清理过期记录
        cls._requests[key] = [(ts, count) for ts, count in cls._requests[key] if ts > window_start]

        # 计算当前窗口内的请求数
        total_requests = sum(count for _, count in cls._requests[key])

        if total_requests >= max_requests:
            return False

        # 记录本次请求
        cls._requests[key].append((current_time, 1))

        return True


def validate_input(value: Any, field_name: str = "输入") -> Any:
    """通用输入验证装饰器"""
    if isinstance(value, str):
        # SQL注入检查
        if not SecurityValidator.validate_sql_safe(value):
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST, detail=f"{field_name}包含非法字符"
            )

        # XSS清理
        return SecurityValidator.sanitize_string(value)

    elif isinstance(value, dict):
        return {k: validate_input(v, k) for k, v in value.items()}

    elif isinstance(value, list):
        return [validate_input(item, field_name) for item in value]

    return value
