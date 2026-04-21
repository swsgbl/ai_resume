"""
短信验证码服务 - 阿里云号码认证服务 (dypnsapi)

接口: SendSmsVerifyCode (发送) + VerifySmsCode (校验)
流程: 发送 → 返回 sms_token → 前端携带 sms_token + 用户输入验证码 → 校验
"""
import time
import json
from typing import Optional, Dict, Any

from alibabacloud_dypnsapi20170525.client import Client
from alibabacloud_dypnsapi20170525 import models as dypns_models
from alibabacloud_tea_openapi import models as open_api_models
from alibabacloud_tea_util import models as util_models

from app.core.config import settings


class SMSRateLimiter:
    """内存限流器（生产环境建议用 Redis）"""

    def __init__(self):
        self._phone_records: Dict[str, list] = {}
        self._ip_records: Dict[str, list] = {}

    def _clean(self, records: list, window: int) -> list:
        cutoff = time.time() - window
        return [t for t in records if t > cutoff]

    def can_send_phone(self, phone: str) -> bool:
        now = time.time()
        recs = self._clean(self._phone_records.get(phone, []), 3600)
        if recs and now - recs[-1] < 60:
            return False
        if len(recs) >= 5:
            return False
        recs.append(now)
        self._phone_records[phone] = recs
        return True

    def can_send_ip(self, ip: str) -> bool:
        now = time.time()
        recs = self._clean(self._ip_records.get(ip, []), 3600)
        if len(recs) >= 10:
            return False
        recs.append(now)
        self._ip_records[ip] = recs
        return True

    def get_cooldown(self, phone: str) -> int:
        recs = self._phone_records.get(phone, [])
        if not recs:
            return 0
        return max(0, int(60 - (time.time() - recs[-1])))


class SMSService:
    """阿里云号码认证 - 短信验证码服务"""

    def __init__(self):
        self.rate_limiter = SMSRateLimiter()
        self._client: Optional[Client] = None
        self.access_key_id = getattr(settings, 'SMS_ALIBABA_ACCESS_KEY_ID', '')
        self.access_key_secret = getattr(settings, 'SMS_ALIBABA_ACCESS_KEY_SECRET', '')
        self.sign_name = getattr(settings, 'SMS_SIGN_NAME', '')
        self.template_code = getattr(settings, 'SMS_TEMPLATE_CODE', '')
        self.enabled = bool(
            self.access_key_id
            and self.access_key_secret
            and self.sign_name
            and self.template_code
        )
        # 存储 sms_token: phone -> token
        self._tokens: Dict[str, str] = {}

    def _get_client(self) -> Client:
        if self._client is None:
            config = open_api_models.Config(
                access_key_id=self.access_key_id,
                access_key_secret=self.access_key_secret,
            )
            config.endpoint = 'dypnsapi.aliyuncs.com'
            self._client = Client(config)
        return self._client

    async def send_verification_code(self, phone: str) -> Dict[str, Any]:
        """发送短信验证码，返回 sms_token 供后续校验使用"""
        if getattr(settings, 'DEBUG', False) or not self.enabled:
            # 开发模式：生成模拟 token
            mock_token = f"dev_token_{phone}_{int(time.time())}"
            self._tokens[phone] = mock_token
            print(f"\n{'='*50}")
            print(f"[SMS 开发模式]")
            print(f"手机号: {phone}")
            print(f"sms_token: {mock_token}")
            print(f"{'='*50}\n")
            return {
                "success": True,
                "code": "OK",
                "request_id": "dev-mode",
                "sms_token": mock_token,
            }

        try:
            client = self._get_client()
            request = dypns_models.SendSmsVerifyCodeRequest(
                phone_number=phone,
                sign_name=self.sign_name,
                template_code=self.template_code,
                template_param=json.dumps({}),
                code_type=0,
                code_length=6,
                valid_time=300,
                interval=60,
            )
            runtime = util_models.RuntimeOptions()
            response = client.send_sms_verify_code_with_options(request, runtime)

            body = response.body
            if body.code == "OK":
                model = body.model.to_map() if body.model else {}
                sms_token = model.get("SmsToken", "")
                self._tokens[phone] = sms_token
                return {
                    "success": True,
                    "code": body.code,
                    "request_id": body.request_id,
                    "sms_token": sms_token,
                }
            else:
                return {
                    "success": False,
                    "code": body.code,
                    "message": body.message,
                    "request_id": body.request_id,
                }
        except Exception as e:
            return {"success": False, "code": "EXCEPTION", "message": str(e)}

    async def verify_code(self, phone: str, code: str, sms_token: str = "") -> bool:
        """校验短信验证码（需要发送时返回的 sms_token）"""
        if getattr(settings, 'DEBUG', False) or not self.enabled:
            print(f"[SMS 开发模式] 校验: phone={phone}, code={code} → 通过")
            return True

        # 优先用传入的 token，否则用缓存的
        token = sms_token or self._tokens.get(phone, "")
        if not token:
            return False

        try:
            client = self._get_client()
            request = dypns_models.VerifySmsCodeRequest(
                phone_number=phone,
                sms_code=code,
                sms_token=token,
            )
            runtime = util_models.RuntimeOptions()
            response = client.verify_sms_code_with_options(request, runtime)

            body = response.body
            if body.code == "OK":
                check_result = body.model
                if check_result and hasattr(check_result, 'verify_result'):
                    return check_result.verify_result in ("success", "PASS")
                return True
            return False
        except Exception as e:
            print(f"验证码校验异常: {e}")
            return False
        finally:
            self._tokens.pop(phone, None)


# 全局实例
sms_service = SMSService()
