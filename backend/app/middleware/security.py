"""
安全中间件 - 安全头部和 CSRF 保护
"""

from fastapi import Request
from starlette.middleware.base import BaseHTTPMiddleware
from app.core.config import settings


class SecurityHeadersMiddleware(BaseHTTPMiddleware):
    """安全头部中间件 - 添加常见的安全 HTTP 头部"""

    async def dispatch(self, request: Request, call_next):
        response = await call_next(request)

        # 基本安全头部
        security_headers = {
            # 防止 MIME 类型嗅探
            "X-Content-Type-Options": "nosniff",
            # 防止点击劫持
            "X-Frame-Options": "DENY",
            # 启用 XSS 过滤器
            "X-XSS-Protection": "1; mode=block",
            # 控制引用信息泄露
            "Referrer-Policy": "strict-origin-when-cross-origin",
            # 限制权限
            "Permissions-Policy": "geolocation=(), microphone=(), camera=(), payment=()",
        }

        # 应用安全头部
        for header, value in security_headers.items():
            response.headers[header] = value

        # 生产环境添加 HSTS（强制 HTTPS）
        if not settings.DEBUG:
            response.headers["Strict-Transport-Security"] = (
                "max-age=31536000; includeSubDomains; preload"
            )

        return response


class CSPMiddleware(BaseHTTPMiddleware):
    """内容安全策略中间件 - 防止 XSS 攻击"""

    async def dispatch(self, request: Request, call_next):
        response = await call_next(request)

        # CSP 策略
        if settings.DEBUG:
            # 开发环境：宽松策略
            csp_policy = (
                "default-src 'self'; "
                "script-src 'self' 'unsafe-inline' 'unsafe-eval'; "
                "style-src 'self' 'unsafe-inline'; "
                "img-src 'self' data: blob:; "
                "font-src 'self'; "
                "connect-src 'self' ws://localhost:* wss://localhost:*; "
                "frame-src 'self'; "
                "base-uri 'self'; "
                "form-action 'self';"
            )
        else:
            # 生产环境：严格策略
            csp_policy = (
                "default-src 'self'; "
                "script-src 'self' 'unsafe-inline'; "
                "style-src 'self' 'unsafe-inline'; "
                "img-src 'self' data: blob: https:; "
                "font-src 'self'; "
                "connect-src 'self'; "
                "frame-src 'none'; "
                "base-uri 'self'; "
                "form-action 'self'; "
                "object-src 'none'; "
                "media-src 'self'; "
                "manifest-src 'self';"
            )

        response.headers["Content-Security-Policy"] = csp_policy
        return response
