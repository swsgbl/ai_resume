"""
AI Config API 增强测试 - 提高覆盖率
"""
import pytest
from httpx import AsyncClient


class TestAIProviders:
    """AI 提供商测试"""

    async def test_get_providers(
        self, client: AsyncClient, auth_headers
    ):
        """测试: 获取所有可用的 AI 提供商"""
        response = await client.get(
            "/api/v1/ai/providers",
            headers=auth_headers
        )

        assert response.status_code == 200
        data = response.json()
        assert data["code"] == 0
        assert isinstance(data["data"], list)
        # 应该有多个提供商
        assert len(data["data"]) > 0

    async def test_get_providers_without_auth(
        self, client: AsyncClient
    ):
        """测试: 未认证获取提供商"""
        response = await client.get("/api/v1/ai/providers")

        assert response.status_code == 401


class TestCurrentProvider:
    """当前提供商测试"""

    async def test_get_current_provider(
        self, client: AsyncClient, auth_headers
    ):
        """测试: 获取当前使用的 AI 提供商"""
        response = await client.get(
            "/api/v1/ai/providers/current",
            headers=auth_headers
        )

        assert response.status_code == 200
        data = response.json()
        assert data["code"] == 0
        assert data["data"] in ["openai", "deepseek", "xiaomi", "openai_v2"]

    async def test_get_current_provider_without_auth(
        self, client: AsyncClient
    ):
        """测试: 未认证获取当前提供商"""
        response = await client.get("/api/v1/ai/providers/current")

        assert response.status_code == 401


class TestSwitchProvider:
    """切换提供商测试"""

    async def test_switch_to_openai(
        self, client: AsyncClient, auth_headers
    ):
        """测试: 切换到 OpenAI"""
        response = await client.post(
            "/api/v1/ai/providers/switch",
            headers=auth_headers,
            json={"provider": "openai"}
        )

        # 可能成功或因配置不可用而失败
        assert response.status_code in [200, 400]

    async def test_switch_to_deepseek(
        self, client: AsyncClient, auth_headers
    ):
        """测试: 切换到 DeepSeek"""
        response = await client.post(
            "/api/v1/ai/providers/switch",
            headers=auth_headers,
            json={"provider": "deepseek"}
        )

        assert response.status_code in [200, 400]

    async def test_switch_to_xiaomi(
        self, client: AsyncClient, auth_headers
    ):
        """测试: 切换到小米 AI"""
        response = await client.post(
            "/api/v1/ai/providers/switch",
            headers=auth_headers,
            json={"provider": "xiaomi"}
        )

        assert response.status_code in [200, 400]

    async def test_switch_to_invalid_provider(
        self, client: AsyncClient, auth_headers
    ):
        """测试: 切换到无效的提供商"""
        response = await client.post(
            "/api/v1/ai/providers/switch",
            headers=auth_headers,
            json={"provider": "invalid_provider"}
        )

        assert response.status_code == 400

    async def test_switch_provider_without_auth(
        self, client: AsyncClient
    ):
        """测试: 未认证切换提供商"""
        response = await client.post(
            "/api/v1/ai/providers/switch",
            json={"provider": "openai"}
        )

        assert response.status_code == 401


class TestUpdateProviderConfig:
    """更新提供商配置测试"""

    async def test_update_openai_config(
        self, client: AsyncClient, auth_headers
    ):
        """测试: 更新 OpenAI 配置"""
        response = await client.post(
            "/api/v1/ai/providers/config",
            headers=auth_headers,
            json={
                "provider": "openai",
                "model": "gpt-4-turbo",
                "max_tokens": 4000,
                "temperature": 0.7
            }
        )

        assert response.status_code == 200

    async def test_update_deepseek_config(
        self, client: AsyncClient, auth_headers
    ):
        """测试: 更新 DeepSeek 配置"""
        response = await client.post(
            "/api/v1/ai/providers/config",
            headers=auth_headers,
            json={
                "provider": "deepseek",
                "model": "deepseek-chat",
                "api_key": "test-key-123"
            }
        )

        assert response.status_code == 200

    async def test_update_config_with_base_url(
        self, client: AsyncClient, auth_headers
    ):
        """测试: 更新配置包含 base_url"""
        response = await client.post(
            "/api/v1/ai/providers/config",
            headers=auth_headers,
            json={
                "provider": "openai",
                "base_url": "https://api.openai.com/v1"
            }
        )

        assert response.status_code == 200

    async def test_update_invalid_provider_config(
        self, client: AsyncClient, auth_headers
    ):
        """测试: 更新无效提供商配置"""
        response = await client.post(
            "/api/v1/ai/providers/config",
            headers=auth_headers,
            json={
                "provider": "invalid_provider"
            }
        )

        assert response.status_code == 400

    async def test_update_config_with_temperature(
        self, client: AsyncClient, auth_headers
    ):
        """测试: 更新温度参数"""
        for temp in [0.0, 0.5, 1.0, 1.5]:
            response = await client.post(
                "/api/v1/ai/providers/config",
                headers=auth_headers,
                json={
                    "provider": "openai",
                    "temperature": temp
                }
            )
            assert response.status_code == 200

    async def test_update_config_without_auth(
        self, client: AsyncClient
    ):
        """测试: 未认证更新配置"""
        response = await client.post(
            "/api/v1/ai/providers/config",
            json={
                "provider": "openai",
                "model": "gpt-4"
            }
        )

        assert response.status_code == 401


class TestAvailableModels:
    """可用模型测试"""

    async def test_get_all_models(
        self, client: AsyncClient, auth_headers
    ):
        """测试: 获取所有可用模型"""
        response = await client.get(
            "/api/v1/ai/models",
            headers=auth_headers
        )

        assert response.status_code == 200
        data = response.json()
        assert data["code"] == 0
        assert isinstance(data["data"], dict)
        # 应该包含多个提供商的模型
        assert "openai" in data["data"] or "deepseek" in data["data"]

    async def test_get_openai_models(
        self, client: AsyncClient, auth_headers
    ):
        """测试: 获取 OpenAI 模型"""
        response = await client.get(
            "/api/v1/ai/models?provider=openai",
            headers=auth_headers
        )

        assert response.status_code == 200
        data = response.json()
        assert data["code"] == 0
        assert "models" in data["data"]
        assert len(data["data"]["models"]) > 0

    async def test_get_deepseek_models(
        self, client: AsyncClient, auth_headers
    ):
        """测试: 获取 DeepSeek 模型"""
        response = await client.get(
            "/api/v1/ai/models?provider=deepseek",
            headers=auth_headers
        )

        assert response.status_code == 200
        data = response.json()
        assert data["code"] == 0
        assert "models" in data["data"]

    async def test_get_xiaomi_models(
        self, client: AsyncClient, auth_headers
    ):
        """测试: 获取小米 AI 模型"""
        response = await client.get(
            "/api/v1/ai/models?provider=xiaomi",
            headers=auth_headers
        )

        assert response.status_code == 200
        data = response.json()
        assert data["code"] == 0
        assert "models" in data["data"]

    async def test_get_invalid_provider_models(
        self, client: AsyncClient, auth_headers
    ):
        """测试: 获取无效提供商的模型"""
        response = await client.get(
            "/api/v1/ai/models?provider=invalid_provider",
            headers=auth_headers
        )

        assert response.status_code == 404

    async def test_get_models_without_auth(
        self, client: AsyncClient
    ):
        """测试: 未认证获取模型"""
        response = await client.get("/api/v1/ai/models")

        assert response.status_code == 401


class TestDefaultConfig:
    """默认配置测试"""

    async def test_get_default_config(
        self, client: AsyncClient, auth_headers
    ):
        """测试: 获取默认 AI 配置"""
        response = await client.get(
            "/api/v1/ai/config/default",
            headers=auth_headers
        )

        assert response.status_code == 200
        data = response.json()
        assert data["code"] == 0
        assert "default_provider" in data["data"]

    async def test_default_config_structure(
        self, client: AsyncClient, auth_headers
    ):
        """测试: 默认配置结构正确"""
        response = await client.get(
            "/api/v1/ai/config/default",
            headers=auth_headers
        )

        assert response.status_code == 200
        data = response.json()
        config = data["data"]

        # 检查默认提供商
        assert config["default_provider"] in ["openai", "deepseek", "xiaomi", "openai_v2"]

    async def test_get_default_config_without_auth(
        self, client: AsyncClient
    ):
        """测试: 未认证获取默认配置"""
        response = await client.get("/api/v1/ai/config/default")

        assert response.status_code == 401
