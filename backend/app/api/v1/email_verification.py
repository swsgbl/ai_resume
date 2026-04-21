"""
邮箱验证路由
"""
from fastapi import APIRouter, Depends, HTTPException, status, Request
from pydantic import BaseModel, EmailStr
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select

from app.services.email_service import email_service
from app.core.database import get_db
from app.core.rate_limit import limiter, RateLimit
from app.models.user import User

router = APIRouter(prefix="/email", tags=["邮箱验证"])


class SendCodeRequest(BaseModel):
    """发送验证码请求"""
    email: EmailStr


class VerifyCodeRequest(BaseModel):
    """验证验证码请求"""
    email: EmailStr
    code: str


@router.post("/send-code", response_model=dict)
@limiter.limit(RateLimit.AUTH_CODE_SEND)
async def send_verification_code(request: Request, body: SendCodeRequest):
    """发送验证码"""
    try:
        # 生成验证码
        code = email_service.generate_code(length=6)

        # 保存验证码到 Redis（5分钟有效期）
        await email_service.save_code(body.email, code, expire_minutes=5)

        # 发送邮件
        success = await email_service.send_verification_email(
            email=body.email,
            code=code
        )

        if not success:
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="发送验证码失败，请稍后重试"
            )

        return {
            "code": 200,
            "message": "验证码已发送到您的邮箱，请查收",
            "data": {
                "expire_in": 300  # 5分钟，单位秒
            }
        }

    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"发送验证码失败: {str(e)}"
        )


@router.post("/verify-code", response_model=dict)
@limiter.limit(RateLimit.AUTH_CODE_VERIFY)
async def verify_code(request: Request, body: VerifyCodeRequest, db: AsyncSession = Depends(get_db)):
    """验证验证码（带速率限制）"""
    try:
        # 1. 验证验证码
        is_valid = await email_service.verify_code(body.email, body.code)

        if not is_valid:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="验证码错误或已过期"
            )

        # 2. 更新数据库验证状态
        result = await db.execute(select(User).where(User.email == body.email))
        user = result.scalar_one_or_none()

        if user:
            user.is_verified = True
            await db.commit()

        return {
            "code": 200,
            "message": "验证成功",
            "data": {
                "verified": True
            }
        }

    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"验证失败: {str(e)}"
        )
