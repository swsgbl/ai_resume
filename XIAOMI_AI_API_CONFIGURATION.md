# 小米AI API配置指南
**创建时间**: 2026-04-17 11:05
**DevOps Agent**: 29126157-6833-4f1e-94bd-6493bd95d3f2
**优先级**: P1 (高优先级)
**配置状态**: ✅ 已配置并验证

---

## 📋 当前配置状态

### ✅ 已完成配置
- **API密钥**: 已配置有效的API密钥
- **默认提供商**: 小米AI (mimo)
- **Base URL**: https://api.xiaomimimo.com/v1
- **环境变量**: 已在生产容器中生效

### 🔑 API密钥信息
```bash
# 当前使用的API密钥
XIAOMI_API_KEY=sk-c0uo5p7vq8h9p0fm45978gvkky3dgtbhn68uai4y2pnyt12o

# 默认AI提供商
DEFAULT_AI_PROVIDER=xiaomi
```

---

## 🎯 小米AI API配置

### API基本信息
- **服务商**: 小米AI (MIMO)
- **API文档**: https://platform.xiaomimimo.com/#/docs/quick-start/first-api-call
- **Base URL**: https://api.xiaomimimo.com/v1
- **认证方式**: Bearer Token
- **请求格式**: JSON (兼容OpenAI格式)

### 支持的模型
| 模型名称 | 用途 | 上下文长度 | 成本 |
|---------|------|-----------|------|
| `mimo-v2-pro` | 高质量生成 | 32K | 中等 |
| `mimo-v2-omni` | 全能生成 | 16K | 较低 |
| `mimo-v2-flash` | 快速响应 | 8K | 最低 |
| `mimo-v2-tts` | 语音合成 | - | - |

---

## 🔧 配置详情

### 后端配置
```python
# backend/app/core/config.py
class Settings(BaseSettings):
    # AI API配置
    DEFAULT_AI_PROVIDER: str = "xiaomi"
    XIAOMI_API_KEY: str = ""
    XIAOMI_BASE_URL: str = "https://api.xiaomimimo.com/v1"
    
    # 备用API提供商
    OPENAI_API_KEY: Optional[str] = None
    DEEPSEEK_API_KEY: Optional[str] = None
```

### 环境变量配置
```bash
# .env.production
XIAOMI_API_KEY=sk-c0uo5p7vq8h9p0fm45978gvkky3dgtbhn68uai4y2pnyt12o
DEFAULT_AI_PROVIDER=xiaomi
XIAOMI_BASE_URL=https://api.xiaomimimo.com/v1
```

### Docker容器配置
```yaml
# docker-compose.prod.yml
services:
  backend:
    environment:
      - XIAOMI_API_KEY=sk-c0uo5p7vq8h9p0fm45978gvkky3dgtbhn68uai4y2pnyt12o
      - DEFAULT_AI_PROVIDER=xiaomi
      - XIAOMI_BASE_URL=https://api.xiaomimimo.com/v1
```

---

## 🚀 API使用示例

### 基础请求
```python
import httpx
import os

async def call_xiaomi_api(prompt: str):
    """调用小米AI API"""
    api_key = os.getenv("XIAOMI_API_KEY")
    base_url = os.getenv("XIAOMI_BASE_URL", "https://api.xiaomimimo.com/v1")
    
    async with httpx.AsyncClient() as client:
        response = await client.post(
            f"{base_url}/chat/completions",
            headers={
                "Authorization": f"Bearer {api_key}",
                "Content-Type": "application/json"
            },
            json={
                "model": "mimo-v2-pro",
                "messages": [
                    {"role": "system", "content": "You are a helpful assistant."},
                    {"role": "user", "content": prompt}
                ],
                "temperature": 0.7,
                "max_tokens": 2000
            },
            timeout=60.0
        )
        
        if response.status_code == 200:
            return response.json()
        else:
            raise Exception(f"API调用失败: {response.status_code} - {response.text}")
```

### 简历生成专用
```python
async def generate_resume_content(user_data: dict):
    """使用小米AI生成简历内容"""
    prompt = f"""
    请基于以下用户信息生成专业简历:
    
    姓名: {user_data['name']}
    工作经验: {user_data['experience']}
    教育背景: {user_data['education']}
    技能: {user_data['skills']}
    
    请生成包含以下部分的简历:
    1. 专业概述
    2. 工作经历
    3. 教育背景
    4. 技能专长
    5. 项目经验
    """
    
    result = await call_xiaomi_api(prompt)
    return result['choices'][0]['message']['content']
```

---

## 📊 API监控和日志

### 监控指标
```python
from prometheus_client import Counter, Histogram

# API调用指标
xiaomi_api_calls = Counter('xiaomi_api_calls_total', 'Total Xiaomi API calls', ['model', 'status'])
xiaomi_api_duration = Histogram('xiaomi_api_duration_seconds', 'Xiaomi API call duration')
xiaomi_api_tokens = Counter('xiaomi_api_tokens_total', 'Total tokens used', ['model'])

# 在API调用中记录
@xiaomi_api_duration.time()
async def monitored_api_call():
    xiaomi_api_calls.labels(model='mimo-v2-pro', status='success').inc()
    # API调用逻辑
    pass
```

### 日志记录
```python
import logging

logger = logging.getLogger(__name__)

async def api_call_with_logging(prompt: str):
    logger.info(f"开始调用小米AI API", extra={
        "provider": "xiaomi",
        "model": "mimo-v2-pro",
        "prompt_length": len(prompt)
    })
    
    try:
        result = await call_xiaomi_api(prompt)
        logger.info("小米AI API调用成功", extra={
            "provider": "xiaomi",
            "tokens_used": result['usage']['total_tokens']
        })
        return result
    except Exception as e:
        logger.error(f"小米AI API调用失败: {str(e)}", extra={
            "provider": "xiaomi",
            "error": str(e)
        })
        raise
```

---

## 🔐 安全最佳实践

### 密钥管理
1. **环境变量**: 通过环境变量传递密钥，不硬编码
2. **密钥轮换**: 定期更换API密钥
3. **访问控制**: 限制密钥的访问权限
4. **监控告警**: 监控异常API调用

### 配置安全
```bash
# .env.production (不要提交到Git)
XIAOMI_API_KEY=sk-c0uo5p7vq8h9p0fm45978gvkky3dgtbhn68uai4y2pnyt12o

# .env.example (可以提交)
XIAOMI_API_KEY=your_xiaomi_api_key_here
```

### Docker安全
```yaml
# docker-compose.prod.yml
services:
  backend:
    env_file:
      - .env.production  # 从文件读取环境变量
    secrets:
      - xiaomi_api_key   # 或使用Docker secrets

secrets:
  xiaomi_api_key:
    file: ./secrets/xiaomi_api_key.txt
```

---

## 🧪 测试验证

### API连接测试
```bash
# 测试API可用性
curl -X POST "https://api.xiaomimimo.com/v1/chat/completions" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer sk-c0uo5p7vq8h9p0fm45978gvkky3dgtbhn68uai4y2pnyt12o" \
  -d '{
    "model": "mimo-v2-pro",
    "messages": [{"role": "user", "content": "Hello"}],
    "max_tokens": 10
  }'
```

### 集成测试
```python
# tests/test_xiaomi_api.py
import pytest
from app.services.ai_service import XiaomiAIService

@pytest.mark.asyncio
async def test_xiaomi_api_connection():
    """测试小米API连接"""
    service = XiaomiAIService()
    response = await service.generate_text("测试连接")
    assert response is not None
    assert len(response) > 0

@pytest.mark.asyncio  
async def test_resume_generation():
    """测试简历生成功能"""
    service = XiaomiAIService()
    user_data = {
        "name": "张三",
        "experience": "5年软件开发经验",
        "education": "计算机科学学士",
        "skills": "Python, JavaScript, React"
    }
    
    resume = await service.generate_resume(user_data)
    assert "张三" in resume
    assert len(resume) > 100
```

---

## 💰 成本优化

### 使用策略
1. **模型选择**: 根据任务复杂度选择合适的模型
2. **Prompt优化**: 减少不必要的prompt长度
3. **缓存机制**: 缓存常见问题的回复
4. **批处理**: 合并多个请求减少API调用

### 成本监控
```python
class CostTracker:
    """API使用成本跟踪"""
    
    COST_PER_1K_TOKENS = {
        "mimo-v2-pro": 0.02,
        "mimo-v2-omni": 0.01,
        "mimo-v2-flash": 0.005
    }
    
    def calculate_cost(self, model: str, tokens: int) -> float:
        """计算API调用成本"""
        cost_per_1k = self.COST_PER_1K_TOKENS.get(model, 0.01)
        return (tokens / 1000) * cost_per_1k
    
    def log_daily_cost(self):
        """记录每日成本"""
        daily_tokens = xiaomi_api_tokens._samples.sum()
        daily_cost = self.calculate_cost("mimo-v2-pro", daily_tokens)
        logger.info(f"今日API成本: ¥{daily_cost:.2f}")
```

---

## 🔄 备用方案

### 多提供商切换
```python
class AIServiceFactory:
    """AI服务工厂"""
    
    @staticmethod
    def create_service(provider: str = None):
        """创建AI服务实例"""
        provider = provider or os.getenv("DEFAULT_AI_PROVIDER", "xiaomi")
        
        if provider == "xiaomi":
            return XiaomiAIService()
        elif provider == "openai":
            return OpenAIService() 
        elif provider == "deepseek":
            return DeepSeekService()
        else:
            raise ValueError(f"不支持的AI提供商: {provider}")

# 使用示例
service = AIServiceFactory.create_service("xiaomi")
result = await service.generate_text("生成简历")
```

### 故障转移
```python
async def resilient_ai_call(prompt: str, max_retries: int = 3):
    """带故障转移的AI调用"""
    providers = ["xiaomi", "deepseek", "openai"]
    
    for provider in providers:
        try:
            service = AIServiceFactory.create_service(provider)
            return await service.generate_text(prompt)
        except Exception as e:
            logger.warning(f"{provider} 调用失败，尝试备用提供商: {e}")
            continue
    
    raise Exception("所有AI提供商均不可用")
```

---

## 📈 性能优化

### 连接池
```python
import httpx
from contextlib import asynccontextmanager

class XiaomiAIClient:
    """小米API客户端"""
    
    def __init__(self):
        self.client = None
    
    async def start(self):
        """初始化连接池"""
        self.client = httpx.AsyncClient(
            base_url="https://api.xiaomimimo.com/v1",
            headers={"Authorization": f"Bearer {os.getenv('XIAOMI_API_KEY')}"},
            timeout=60.0,
            limits=httpx.Limits(max_keepalive_connections=20, max_connections=100)
        )
    
    async def stop(self):
        """关闭连接池"""
        await self.client.aclose()
    
    async def chat(self, messages: list):
        """发送聊天请求"""
        response = await self.client.post("/chat/completions", json={
            "model": "mimo-v2-pro",
            "messages": messages
        })
        return response.json()

# 使用示例
client = XiaomiAIClient()
await client.start()
result = await client.chat([{"role": "user", "content": "Hello"}])
await client.stop()
```

### 异步批处理
```python
async def batch_generate(prompts: list[str], batch_size: int = 5):
    """批量生成文本"""
    results = []
    
    for i in range(0, len(prompts), batch_size):
        batch = prompts[i:i + batch_size]
        tasks = [call_xiaomi_api(prompt) for prompt in batch]
        batch_results = await asyncio.gather(*tasks, return_exceptions=True)
        results.extend(batch_results)
    
    return results
```

---

## 🐛 故障排除

### 常见问题

#### 1. API认证失败
**症状**: 401 Unauthorized
**解决方案**:
```bash
# 验证API密钥
echo $XIAOMI_API_KEY

# 检查密钥格式
curl -H "Authorization: Bearer $XIAOMI_API_KEY" https://api.xiaomimimo.com/v1/models
```

#### 2. 请求超时
**症状**: Request timeout
**解决方案**:
```python
# 增加超时时间
response = await client.post("/chat/completions", json=payload, timeout=120.0)

# 使用重试机制
from tenacity import retry, stop_after_attempt, wait_exponential

@retry(stop=stop_after_attempt(3), wait=wait_exponential(multiplier=1, min=4, max=10))
async def resilient_api_call():
    return await call_xiaomi_api(prompt)
```

#### 3. 令牌限制
**症状**: Token limit exceeded
**解决方案**:
```python
# 分段处理长文本
def split_text(text: str, max_length: int = 3000):
    """分割文本为合适长度"""
    sentences = text.split('。')
    chunks = []
    current_chunk = ""
    
    for sentence in sentences:
        if len(current_chunk) + len(sentence) < max_length:
            current_chunk += sentence + "。"
        else:
            chunks.append(current_chunk)
            current_chunk = sentence + "。"
    
    if current_chunk:
        chunks.append(current_chunk)
    
    return chunks
```

---

## 📞 联系信息

**配置负责人**: DevOps Agent (29126157-6833-4f1e-94bd-6493bd95d3f2)
**技术支持**: 小米AI平台
**API支持**: https://platform.xiaomimimo.com/#/support

---

## 📅 维护计划

### 日常维护
- **每日**: 监控API使用量和成本
- **每周**: 检查API错误率和性能
- **每月**: 评估备用提供商和成本优化

### 密钥轮换
- **频率**: 每90天轮换API密钥
- **流程**: 
  1. 生成新密钥
  2. 测试新密钥
  3. 更新环境变量
  4. 重启服务
  5. 撤销旧密钥

---

**文档版本**: v1.0
**配置状态**: ✅ 已验证可用
**最后更新**: 2026-04-17 11:05
**下次评审**: 2026-05-17
