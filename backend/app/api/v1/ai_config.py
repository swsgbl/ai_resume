"""
AI模型配置管理路由
提供AI提供商的查询、切换、配置等功能
"""

from typing import Optional, List
from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel

from app.core.security import get_current_user
from app.models.user import User
from app.schemas.common import Response
from app.services.ai.ai_service_factory import (
    get_ai_service_factory,
    AIProvider,
)

router = APIRouter(prefix="/ai", tags=["AI配置"])


# ========== 请求/响应模型 ==========


class ProviderInfo(BaseModel):
    """提供商信息"""

    provider: str
    name: str
    available: bool
    model: str


class ProviderConfig(BaseModel):
    """提供商配置"""

    provider: str
    api_key: Optional[str] = None
    model: Optional[str] = None
    base_url: Optional[str] = None
    max_tokens: Optional[int] = None
    temperature: Optional[float] = None


class SwitchProviderRequest(BaseModel):
    """切换提供商请求"""

    provider: str


# ========== API端点 ==========


@router.get("/providers", response_model=Response[List[ProviderInfo]])
async def get_providers(current_user: User = Depends(get_current_user)):
    """获取所有可用的AI提供商列表"""
    factory = get_ai_service_factory()
    providers = factory.get_available_providers()

    return Response(data=[ProviderInfo(**p) for p in providers], message="获取成功")


@router.get("/providers/current", response_model=Response[str])
async def get_current_provider(current_user: User = Depends(get_current_user)):
    """获取当前使用的AI提供商"""
    factory = get_ai_service_factory()
    current = factory.current_provider or factory.config.DEFAULT_PROVIDER

    return Response(
        data=current.value if isinstance(current, AIProvider) else current, message="获取成功"
    )


@router.post("/providers/switch", response_model=Response[str])
async def switch_provider(
    request: SwitchProviderRequest, current_user: User = Depends(get_current_user)
):
    """切换AI提供商"""
    try:
        provider = AIProvider(request.provider)
    except ValueError:
        raise HTTPException(status_code=400, detail=f"不支持的提供商: {request.provider}")

    factory = get_ai_service_factory()
    ai_service = factory.switch_provider(provider)

    if not ai_service.is_available:
        raise HTTPException(
            status_code=400, detail=f"提供商 {ai_service.provider_name} 不可用，请先配置API密钥"
        )

    return Response(data=request.provider, message=f"已切换到 {ai_service.provider_name}")


@router.post("/providers/config", response_model=Response)
async def update_provider_config(
    config: ProviderConfig, current_user: User = Depends(get_current_user)
):
    """更新AI提供商配置"""
    try:
        provider = AIProvider(config.provider)
    except ValueError:
        raise HTTPException(status_code=400, detail=f"不支持的提供商: {config.provider}")

    factory = get_ai_service_factory()

    # 构建配置参数
    update_kwargs = {}
    if config.api_key is not None:
        update_kwargs["api_key"] = config.api_key
    if config.model is not None:
        update_kwargs["model"] = config.model
    if config.base_url is not None:
        update_kwargs["base_url"] = config.base_url
    if config.max_tokens is not None:
        update_kwargs["max_tokens"] = config.max_tokens
    if config.temperature is not None:
        update_kwargs["temperature"] = config.temperature

    # 更新配置
    factory.update_config(provider, **update_kwargs)

    return Response(message=f"{config.provider} 配置已更新")


@router.get("/models", response_model=Response[dict])
async def get_available_models(
    provider: Optional[str] = None, current_user: User = Depends(get_current_user)
):
    """获取可用的模型列表"""
    models = {
        "openai_v2": {
            "name": "OpenAI (优化版)",
            "models": [
                {"id": "gpt-4", "name": "GPT-4", "description": "最强大的模型，三元协同Agent架构"},
                {"id": "gpt-4-turbo", "name": "GPT-4 Turbo", "description": "更快更经济的GPT-4"},
            ],
            "website": "https://platform.openai.com",
        },
        "openai": {
            "name": "OpenAI",
            "models": [
                {"id": "gpt-4", "name": "GPT-4", "description": "最强大的模型"},
                {"id": "gpt-4-turbo", "name": "GPT-4 Turbo", "description": "更快更经济的GPT-4"},
                {"id": "gpt-3.5-turbo", "name": "GPT-3.5 Turbo", "description": "经济实用的选择"},
            ],
            "website": "https://platform.openai.com",
        },
        "deepseek": {
            "name": "DeepSeek",
            "models": [
                {"id": "deepseek-chat", "name": "DeepSeek Chat", "description": "深度求索对话模型"},
                {"id": "deepseek-coder", "name": "DeepSeek Coder", "description": "代码专用模型"},
            ],
            "website": "https://platform.deepseek.com",
        },
        "xiaomi": {
            "name": "小米AI",
            "models": [
                {
                    "id": "MiMo-V2-Flash",
                    "name": "MiMo V2 Flash",
                    "description": "小米MiMo V2 Flash模型",
                },
                {"id": "mimo-v2-pro", "name": "MiMo V2 Pro", "description": "小米MiMo V2 Pro模型"},
            ],
            "website": "https://platform.xiaomimimo.com",
        },
    }

    if provider:
        if provider not in models:
            raise HTTPException(status_code=404, detail=f"未找到提供商: {provider}")
        return Response(data=models[provider])

    return Response(data=models)


@router.get("/config/default", response_model=Response[dict])
async def get_default_config(current_user: User = Depends(get_current_user)):
    """获取默认AI配置"""
    factory = get_ai_service_factory()
    config = factory.config

    return Response(
        data={
            "default_provider": config.DEFAULT_PROVIDER,
            "openai": {
                "model": config.OPENAI_MODEL,
                "max_tokens": config.OPENAI_MAX_TOKENS,
                "temperature": config.OPENAI_TEMPERATURE,
            },
            "deepseek": {
                "model": config.DEEPSEEK_MODEL,
                "base_url": config.DEEPSEEK_BASE_URL,
                "max_tokens": config.DEEPSEEK_MAX_TOKENS,
                "temperature": config.DEEPSEEK_TEMPERATURE,
            },
            "xiaomi": {
                "model": config.XIAOMI_MODEL,
                "base_url": config.XIAOMI_BASE_URL,
                "max_tokens": config.XIAOMI_MAX_TOKENS,
                "temperature": config.XIAOMI_TEMPERATURE,
            },
        }
    )
