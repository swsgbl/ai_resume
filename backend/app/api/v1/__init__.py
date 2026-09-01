"""
API v1 路由汇总
"""

from fastapi import APIRouter
from app.core.config import settings
from app.api.v1.auth import router as auth_router
from app.api.v1.auth_wechat import router as wechat_router
from app.api.v1.auth_oauth import router as oauth_router
from app.api.v1.resumes import router as resume_router
from app.api.v1.templates import router as template_router
from app.api.v1.export import router as export_router
from app.api.v1.export_tasks import router as export_tasks_router
from app.api.v1.advanced import router as advanced_router
from app.api.v1.compliance import router as compliance_router
from app.api.v1.email_verification import router as email_verification_router
from app.api.v1.ai_config import router as ai_config_router
from app.api.v1.ai_usage import router as ai_usage_router
from app.api.v1.search import router as search_router
from app.api.v1.career import router as career_router
from app.api.v1.account import router as account_router  # 账号管理

router = APIRouter()

# 注册各模块路由
router.include_router(auth_router)  # 基础认证 (/auth/*)
# 可选登录通道：未配置对应密钥时不挂载（认证栈可插拔，核心链路只依赖 JWT+邮箱）
if settings.WECHAT_APP_ID and settings.WECHAT_APP_SECRET:
    router.include_router(wechat_router)  # 微信登录 (/auth/wechat/*)
if (
    (settings.GITHUB_CLIENT_ID and settings.GITHUB_CLIENT_SECRET)
    or (settings.GITEE_CLIENT_ID and settings.GITEE_CLIENT_SECRET)
    or (settings.QQ_CONNECT_APP_ID and settings.QQ_CONNECT_APP_SECRET)
):
    router.include_router(oauth_router)  # OAuth登录 (/auth/oauth/*)
router.include_router(account_router)  # 账号管理 (/account/*)
router.include_router(resume_router)
router.include_router(template_router)
router.include_router(export_router)
router.include_router(export_tasks_router)  # 异步导出任务
router.include_router(advanced_router)
router.include_router(compliance_router)
router.include_router(email_verification_router)
router.include_router(ai_config_router)
router.include_router(ai_usage_router)
router.include_router(search_router)
router.include_router(career_router)  # 职业智能 (/career/*)
