"""
邮件发送服务
支持验证码、通知等邮件发送

验证码存储优先使用 Redis（生产环境），内存作为后备（开发环境）
"""
import secrets
import string
import hashlib
import asyncio
from datetime import datetime, timedelta, timezone
from typing import Optional
import smtplib
from html import escape
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
import redis.asyncio as redis

from app.core.config import settings


def _deliver_html_email(recipient: str, subject: str, html_body: str) -> None:
    """在线程池中同步投递邮件，避免阻塞事件循环。"""
    smtp_host = getattr(settings, "SMTP_HOST", None)
    smtp_port = getattr(settings, "SMTP_PORT", None)
    smtp_user = getattr(settings, "SMTP_USER", None)
    smtp_password = getattr(settings, "SMTP_PASSWORD", None)

    if not all((smtp_host, smtp_port, smtp_user, smtp_password)):
        print(f"⚠️ SMTP 未完整配置，邮件未发送给 {recipient}")
        raise ValueError("SMTP is not fully configured")

    msg = MIMEMultipart("alternative")
    msg["Subject"] = subject
    msg["From"] = smtp_user
    msg["To"] = recipient

    html_part = MIMEText(html_body, "html")
    msg.attach(html_part)

    with smtplib.SMTP(smtp_host, smtp_port, timeout=10) as server:
        server.starttls()
        server.login(smtp_user, smtp_password)
        server.send_message(msg)


class EmailService:
    """邮件服务类 - 使用 Redis 存储验证码（生产环境安全）"""

    def __init__(self):
        self.redis_url = settings.REDIS_URL
        self._redis: Optional[redis.Redis] = None
        # 内存后备（开发环境或 Redis 不可用时）
        self._verification_codes = {}
        self._reset_codes = {}

    async def get_redis(self):
        """获取 Redis 连接"""
        if self._redis is None:
            try:
                self._redis = redis.from_url(
                    self.redis_url,
                    encoding="utf-8",
                    decode_responses=True
                )
            except (redis.ConnectionError, redis.RedisError, ValueError):
                # Redis 连接失败时使用内存后备
                self._redis = None
        return self._redis

    async def close_redis(self):
        """关闭 Redis 连接"""
        if self._redis:
            try:
                await self._redis.close()
            except (redis.RedisError, RuntimeError):
                # Redis 关闭异常时静默处理
                pass
            self._redis = None

    def generate_code(self, length: int = 6) -> str:
        """生成验证码（使用 secrets 模块确保密码学安全）"""
        return ''.join(secrets.choice(string.digits) for _ in range(length))

    async def save_code(self, email: str, code: str, expire_minutes: int = 5) -> None:
        """保存验证码到 Redis（加密存储，带过期时间）"""
        redis_client = await self.get_redis()

        if redis_client:
            try:
                # 使用 SHA-256 哈希存储验证码
                code_hash = hashlib.sha256(code.encode()).hexdigest()
                key = f"verification_code:{email}"
                await redis_client.setex(key, expire_minutes * 60, code_hash)
                return
            except (redis.RedisError, RuntimeError):
                # Redis 失败，使用内存后备
                pass

        # 内存后备存储（也使用哈希）
        expire_time = datetime.now(timezone.utc) + timedelta(minutes=expire_minutes)
        code_hash = hashlib.sha256(code.encode()).hexdigest()
        self._verification_codes[email] = {
            'code_hash': code_hash,
            'expire_time': expire_time,
            'used': False
        }

    async def verify_code(self, email: str, code: str) -> bool:
        """验证验证码（使用哈希比较）"""
        redis_client = await self.get_redis()

        if redis_client:
            try:
                key = f"verification_code:{email}"
                stored_hash = await redis_client.get(key)

                if stored_hash is None:
                    # 验证码不存在或已过期
                    return False

                # 计算输入验证码的哈希
                code_hash = hashlib.sha256(code.encode()).hexdigest()

                if code_hash == stored_hash:
                    # 验证成功，删除验证码（一次性使用）
                    await redis_client.delete(key)
                    return True

                return False
            except (redis.RedisError, RuntimeError):
                # Redis 失败，使用内存后备
                pass

        # 内存后备验证
        if email not in self._verification_codes:
            return False

        stored_data = self._verification_codes[email]

        # 检查是否已使用
        if stored_data['used']:
            return False

        # 检查是否过期
        if datetime.now(timezone.utc) > stored_data['expire_time']:
            # 清除过期验证码
            del self._verification_codes[email]
            return False

        # 验证码匹配（比较哈希）
        code_hash = hashlib.sha256(code.encode()).hexdigest()
        if code_hash == stored_data['code_hash']:
            # 立即删除，防止重用
            del self._verification_codes[email]
            return True

        return False

    async def send_verification_email(
        self,
        email: str,
        code: str
    ) -> bool:
        """发送验证码邮件"""
        try:
            # 邮件内容
            subject = "【AI简历平台】邮箱验证码"
            body = f"""
            <html>
            <body style="font-family: Arial, sans-serif;">
                <div style="max-width: 600px; margin: 0 auto; padding: 20px;">
                    <h2 style="color: #333;">邮箱验证</h2>
                    <p>您好，</p>
                    <p>您正在注册AI简历智能生成平台，验证码如下：</p>
                    <div style="background-color: #f0f0f0; padding: 20px; text-align: center; font-size: 24px; font-weight: bold; letter-spacing: 5px; margin: 20px 0;">
                        {code}
                    </div>
                    <p>验证码有效期为 <strong>5分钟</strong>，请尽快完成验证。</p>
                    <p>如果这不是您的操作，请忽略此邮件。</p>
                    <hr style="margin: 20px 0; border: none; border-top: 1px solid #eee;">
                    <p style="color: #999; font-size: 12px;">
                        此邮件由系统自动发送，请勿直接回复。<br>
                        © 2025 AI简历智能生成平台. All rights reserved.
                    </p>
                </div>
            </body>
            </html>
            """

            # 开发环境：打印到日志
            if getattr(settings, 'DEBUG', False):
                print(f"\n{'='*50}")
                print(f"📧 邮件发送模拟")
                print(f"收件人: {email}")
                print(f"验证码: {code}")
                print(f"有效期: 5分钟")
                print(f"{'='*50}\n")
                return True

            await asyncio.to_thread(_deliver_html_email, email, subject, body)
            return True

        except Exception as e:
            print(f"发送邮件失败: {e}")
            return False

    async def send_notification_email(
        self,
        email: str,
        subject: str,
        content: str
    ) -> bool:
        """发送通知邮件"""
        try:
            # 开发环境：打印到日志
            if getattr(settings, 'DEBUG', False):
                print(f"\n{'='*50}")
                print(f"📧 通知邮件")
                print(f"收件人: {email}")
                print(f"主题: {subject}")
                print(f"内容: {content}")
                print(f"{'='*50}\n")
                return True

            html_content = f"""
            <html>
            <body style="font-family: Arial, sans-serif;">
                <div style="max-width: 600px; margin: 0 auto; padding: 20px;">
                    <h2 style="color: #333;">{escape(subject)}</h2>
                    <p style="color: #333;">{escape(content)}</p>
                </div>
            </body>
            </html>
            """
            await asyncio.to_thread(_deliver_html_email, email, subject, html_content)
            return True

        except Exception as e:
            print(f"发送邮件失败: {e}")
            return False

    async def cleanup_expired_codes(self) -> None:
        """清理过期的验证码（仅内存后备需要，Redis 自动过期）"""
        now = datetime.now(timezone.utc)
        expired_emails = [
            email for email, data in self._verification_codes.items()
            if now > data['expire_time']
        ]
        for email in expired_emails:
            del self._verification_codes[email]

    async def save_reset_code(self, email: str, code: str, expire_minutes: int = 15) -> None:
        """保存密码重置码到 Redis（哈希存储，带过期时间）"""
        redis_client = await self.get_redis()

        if redis_client:
            try:
                # 使用 SHA-256 哈希存储重置码
                code_hash = hashlib.sha256(code.encode()).hexdigest()
                key = f"reset_code:{email}"
                await redis_client.setex(key, expire_minutes * 60, code_hash)
                return
            except (redis.RedisError, RuntimeError):
                pass

        # 内存后备存储（也使用哈希）
        expire_time = datetime.now(timezone.utc) + timedelta(minutes=expire_minutes)
        code_hash = hashlib.sha256(code.encode()).hexdigest()
        self._reset_codes[email] = {
            'code_hash': code_hash,
            'expire_time': expire_time,
            'used': False
        }

    async def verify_reset_code(self, email: str, code: str) -> bool:
        """验证密码重置码（使用哈希比较）"""
        redis_client = await self.get_redis()

        if redis_client:
            try:
                key = f"reset_code:{email}"
                stored_hash = await redis_client.get(key)

                if stored_hash is None:
                    return False

                code_hash = hashlib.sha256(code.encode()).hexdigest()
                if code_hash == stored_hash:
                    await redis_client.delete(key)
                    return True

                return False
            except (redis.RedisError, RuntimeError):
                pass

        # 内存后备验证
        if email not in self._reset_codes:
            return False

        stored_data = self._reset_codes[email]

        if stored_data['used']:
            return False

        if datetime.now(timezone.utc) > stored_data['expire_time']:
            del self._reset_codes[email]
            return False

        code_hash = hashlib.sha256(code.encode()).hexdigest()
        if code_hash == stored_data['code_hash']:
            del self._reset_codes[email]
            return True

        return False

    async def send_password_reset_email(
        self,
        email: str,
        code: str
    ) -> bool:
        """发送密码重置邮件"""
        try:
            # 邮件内容
            subject = "【AI简历平台】密码重置验证码"
            body = f"""
            <html>
            <body style="font-family: Arial, sans-serif;">
                <div style="max-width: 600px; margin: 0 auto; padding: 20px;">
                    <h2 style="color: #333;">密码重置</h2>
                    <p>您好，</p>
                    <p>我们收到了您的密码重置请求，验证码如下：</p>
                    <div style="background-color: #f0f0f0; padding: 20px; text-align: center; font-size: 24px; font-weight: bold; letter-spacing: 5px; margin: 20px 0;">
                        {code}
                    </div>
                    <p>验证码有效期为 <strong>15分钟</strong>，请尽快完成密码重置。</p>
                    <p>如果这不是您的操作，请忽略此邮件，您的密码不会被修改。</p>
                    <hr style="margin: 20px 0; border: none; border-top: 1px solid #eee;">
                    <p style="color: #999; font-size: 12px;">
                        此邮件由系统自动发送，请勿直接回复。<br>
                        © 2025 AI简历智能生成平台. All rights reserved.
                    </p>
                </div>
            </body>
            </html>
            """

            # 开发环境：打印到日志
            if getattr(settings, 'DEBUG', False):
                print(f"\n{'='*50}")
                print(f"📧 密码重置邮件")
                print(f"收件人: {email}")
                print(f"重置码: {code}")
                print(f"有效期: 15分钟")
                print(f"{'='*50}\n")
                return True

            await asyncio.to_thread(_deliver_html_email, email, subject, body)
            return True

        except Exception as e:
            print(f"发送密码重置邮件失败: {e}")
            return False


# 全局实例
email_service = EmailService()
