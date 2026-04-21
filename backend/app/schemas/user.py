"""
用户相关的 Pydantic 模式
"""
from datetime import datetime
from typing import Optional
from pydantic import BaseModel, EmailStr, Field, field_validator, ConfigDict
import re


class UserBase(BaseModel):
    """用户基础模式"""
    email: EmailStr
    phone: Optional[str] = None
    username: Optional[str] = None


class UserCreate(BaseModel):
    """用户注册模式"""
    email: EmailStr
    password: str = Field(..., min_length=6, max_length=50)
    phone: Optional[str] = None
    username: Optional[str] = None
    
    @field_validator('password')
    @classmethod
    def validate_password(cls, v: str) -> str:
        if len(v) < 6:
            raise ValueError('密码长度至少6个字符')
        if not re.search(r'[A-Za-z]', v):
            raise ValueError('密码必须包含字母')
        if not re.search(r'\d', v):
            raise ValueError('密码必须包含数字')
        return v
    
    @field_validator('phone')
    @classmethod
    def validate_phone(cls, v: Optional[str]) -> Optional[str]:
        if v and not re.match(r'^1[3-9]\d{9}$', v):
            raise ValueError('请输入正确的手机号')
        return v


class UserLogin(BaseModel):
    """用户登录模式"""
    email: EmailStr
    password: str


class UserUpdate(BaseModel):
    """用户更新模式"""
    username: Optional[str] = None
    phone: Optional[str] = None
    avatar_url: Optional[str] = None


class UserResponse(BaseModel):
    """用户响应模式"""
    id: int
    email: str
    phone: Optional[str] = None
    username: Optional[str] = None
    avatar_url: Optional[str] = None
    role: str
    is_active: bool
    is_verified: bool
    created_at: datetime
    updated_at: datetime

    # OAuth 绑定状态（只返回是否绑定，不暴露 ID）
    has_google: bool = False
    has_github: bool = False
    has_gitee: bool = False
    has_discord: bool = False
    has_wechat: bool = False

    model_config = ConfigDict(from_attributes=True)


class TokenResponse(BaseModel):
    """令牌响应模式"""
    access_token: str
    refresh_token: str
    token_type: str = "bearer"
    expires_in: int


class TokenRefresh(BaseModel):
    """令牌刷新模式"""
    refresh_token: str


class PasswordChange(BaseModel):
    """密码修改模式"""
    old_password: str
    new_password: str = Field(..., min_length=6, max_length=50)

    @field_validator('new_password')
    @classmethod
    def validate_password(cls, v: str) -> str:
        if len(v) < 6:
            raise ValueError('密码长度至少6个字符')
        return v


class PasswordResetRequest(BaseModel):
    """密码重置请求模式"""
    email: EmailStr = Field(..., description="用户邮箱")


class PasswordResetVerify(BaseModel):
    """密码重置验证模式"""
    email: EmailStr = Field(..., description="用户邮箱")
    code: str = Field(..., min_length=6, max_length=6, description="重置验证码")
    new_password: str = Field(..., min_length=6, max_length=50, description="新密码")

    @field_validator('new_password')
    @classmethod
    def validate_password(cls, v: str) -> str:
        if len(v) < 6:
            raise ValueError('密码长度至少6个字符')
        return v


class WechatLoginRequest(BaseModel):
    """微信登录请求模式"""
    code: str = Field(..., description="微信授权码")


class WechatUserInfo(BaseModel):
    """微信用户信息模式"""
    openid: str
    unionid: Optional[str] = None
    nickname: Optional[str] = None
    headimgurl: Optional[str] = None
    sex: Optional[int] = None
    province: Optional[str] = None
    city: Optional[str] = None
    country: Optional[str] = None


# ==================== OAuth Schemas ====================

class OAuthLoginRequest(BaseModel):
    """OAuth 登录请求模式"""
    code: str = Field(..., description="OAuth 授权码")
    state: str = Field(..., description="OAuth 状态参数（防CSRF）")
    redirect_uri: Optional[str] = Field(None, description="重定向URI（可选，用于覆盖默认值）")


class OAuthBindRequest(BaseModel):
    """OAuth 绑定请求模式"""
    code: str = Field(..., description="OAuth 授权码")
    state: str = Field(..., description="OAuth 状态参数（防CSRF）")


class OAuthUserInfo(BaseModel):
    """OAuth 用户信息响应模式"""
    provider: str  # 'google' or 'github'
    provider_id: str
    email: Optional[str] = None
    verified_email: bool = False
    name: Optional[str] = None
    avatar_url: Optional[str] = None


class OAuthAuthorizeRequest(BaseModel):
    """OAuth 授权请求模式 - 获取授权URL"""
    redirect_uri: Optional[str] = Field(None, description="授权后重定向的URI")
    state: Optional[str] = Field(None, description="自定义状态参数（可选，系统会自动生成）")


# ==================== 短信验证码 Schemas ====================

class SMSSendRequest(BaseModel):
    """发送短信验证码请求"""
    phone: str = Field(..., description="手机号（中国大陆11位）")

    @field_validator('phone')
    @classmethod
    def validate_phone(cls, v: str) -> str:
        if not re.match(r'^1[3-9]\d{9}$', v):
            raise ValueError('请输入正确的11位手机号')
        return v


class SMSLoginRequest(BaseModel):
    """手机号+验证码登录请求"""
    phone: str = Field(..., description="手机号")
    code: str = Field(..., min_length=4, max_length=6, description="短信验证码")
    sms_token: str = Field("", description="发送验证码时返回的token")

    @field_validator('phone')
    @classmethod
    def validate_phone(cls, v: str) -> str:
        if not re.match(r'^1[3-9]\d{9}$', v):
            raise ValueError('请输入正确的11位手机号')
        return v


class SMSRegisterRequest(BaseModel):
    """手机号注册请求"""
    phone: str = Field(..., description="手机号")
    code: str = Field(..., min_length=4, max_length=6, description="短信验证码")
    sms_token: str = Field("", description="发送验证码时返回的token")
    password: str = Field(..., min_length=6, max_length=50, description="密码")
    username: Optional[str] = Field(None, description="用户名（可选）")

    @field_validator('phone')
    @classmethod
    def validate_phone(cls, v: str) -> str:
        if not re.match(r'^1[3-9]\d{9}$', v):
            raise ValueError('请输入正确的11位手机号')
        return v

    @field_validator('password')
    @classmethod
    def validate_password(cls, v: str) -> str:
        if len(v) < 6:
            raise ValueError('密码长度至少6个字符')
        if not re.search(r'[A-Za-z]', v):
            raise ValueError('密码必须包含字母')
        if not re.search(r'\d', v):
            raise ValueError('密码必须包含数字')
        return v
