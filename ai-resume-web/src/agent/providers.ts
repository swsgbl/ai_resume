/**
 * 多厂商模型路由存储 — 参考 OpenCode 的 provider 路由方案(models.dev 全量目录思路)
 *
 * 设计:
 * - 每个厂商一份完整配置(baseUrl + apiKey + 当前选用模型),可并存多家
 * - defaultId 即「路由」:车间所有 Agent 默认走该厂商,可随时切换
 * - 内置 26 家主流厂商目录(国内/海外/本地三分组),支持自定义接入
 * - 向后兼容:首次加载自动迁移旧的单配置 os_model_config
 * - 密钥仅存本机浏览器(产品隐私承诺),绝不上传
 */

export interface ProviderConfig {
  /** 稳定 id:预设厂商用目录 id,自定义用 provider-<时间戳> */
  id: string;
  /** 显示名 */
  name: string;
  /** OpenAI 兼容端点 */
  baseUrl: string;
  apiKey: string;
  /** 该厂商下当前选用的模型 */
  model: string;
}

export interface ProviderStore {
  providers: ProviderConfig[];
  /** 路由:车间默认使用的厂商 id */
  defaultId: string;
}

/** 预设厂商目录(OpenCode/models.dev 思路:全量厂商 + 分组 + 模型候选) */
export interface ProviderPreset {
  id: string;
  name: string;
  baseUrl: string;
  models: string[];
  /** 引导文案 */
  desc: string;
  /** 密钥申请地址(空表示无需密钥) */
  keyUrl?: string;
  /** 分组:cn 国内 / global 海外 / local 本地 */
  category: 'cn' | 'global' | 'local';
}

export const PROVIDER_CATEGORY_LABELS: Record<ProviderPreset['category'], string> = {
  cn: '国内厂商',
  global: '海外厂商',
  local: '本地运行',
};

export const PROVIDER_PRESETS: ProviderPreset[] = [
  // ===== 国内 =====
  {
    id: 'deepseek',
    name: 'DeepSeek',
    baseUrl: 'https://api.deepseek.com/v1',
    models: ['deepseek-chat', 'deepseek-reasoner'],
    desc: '性价比高 · 推荐',
    keyUrl: 'https://platform.deepseek.com/api_keys',
    category: 'cn',
  },
  {
    id: 'qwen',
    name: '阿里通义千问',
    baseUrl: 'https://dashscope.aliyuncs.com/compatible-mode/v1',
    models: ['qwen-plus', 'qwen-max', 'qwen-turbo', 'qwen2.5-72b-instruct'],
    desc: '百炼平台 · Qwen 全系',
    keyUrl: 'https://bailian.console.aliyun.com/?apiKey=1',
    category: 'cn',
  },
  {
    id: 'glm',
    name: '智谱 GLM',
    baseUrl: 'https://open.bigmodel.cn/api/paas/v4',
    models: ['glm-4-flash', 'glm-4-plus', 'glm-4-air'],
    desc: 'glm-4-flash 免费',
    keyUrl: 'https://open.bigmodel.cn/usercenter/apikeys',
    category: 'cn',
  },
  {
    id: 'kimi',
    name: '月之暗面 Kimi',
    baseUrl: 'https://api.moonshot.cn/v1',
    models: ['moonshot-v1-8k', 'moonshot-v1-32k', 'kimi-k2-0711-preview'],
    desc: '长文本擅长',
    keyUrl: 'https://platform.moonshot.cn/console/api-keys',
    category: 'cn',
  },
  {
    id: 'doubao',
    name: '火山方舟(豆包)',
    baseUrl: 'https://ark.cn-beijing.volces.com/api/v3',
    models: ['doubao-pro-32k', 'doubao-pro-128k', 'doubao-lite-32k'],
    desc: '字节豆包 · 需创建推理接入点',
    keyUrl: 'https://console.volcengine.com/ark/region:ark+cn-beijing/apiKey',
    category: 'cn',
  },
  {
    id: 'hunyuan',
    name: '腾讯混元',
    baseUrl: 'https://api.hunyuan.cloud.tencent.com/v1',
    models: ['hunyuan-turbo', 'hunyuan-pro', 'hunyuan-lite'],
    desc: 'hunyuan-lite 免费',
    keyUrl: 'https://console.cloud.tencent.com/hunyuan/api-key',
    category: 'cn',
  },
  {
    id: 'minimax',
    name: 'MiniMax',
    baseUrl: 'https://api.minimax.chat/v1',
    models: ['MiniMax-Text-01', 'abab6.5s-chat'],
    desc: '长上下文 · 多模态',
    keyUrl: 'https://platform.minimaxi.com/user-center/basic-information/interface-key',
    category: 'cn',
  },
  {
    id: 'stepfun',
    name: '阶跃星辰',
    baseUrl: 'https://api.stepfun.com/v1',
    models: ['step-2-16k', 'step-1v-8k'],
    desc: 'Step 系列',
    keyUrl: 'https://platform.stepfun.com/interface-key',
    category: 'cn',
  },
  {
    id: 'yi',
    name: '零一万物',
    baseUrl: 'https://api.lingyiwanwu.com/v1',
    models: ['yi-large', 'yi-medium'],
    desc: 'Yi 系列',
    keyUrl: 'https://platform.lingyiwanwu.com/apikeys',
    category: 'cn',
  },
  {
    id: 'baidu',
    name: '百度千帆',
    baseUrl: 'https://qianfan.baidubce.com/v2',
    models: ['ernie-4.0-turbo-8k', 'ernie-3.5-8k'],
    desc: '文心一言全系',
    keyUrl: 'https://console.bce.baidu.com/iam/#/iam/apikey/list',
    category: 'cn',
  },
  {
    id: 'siliconflow',
    name: '硅基流动',
    baseUrl: 'https://api.siliconflow.cn/v1',
    models: ['deepseek-ai/DeepSeek-V3', 'Qwen/Qwen2.5-72B-Instruct'],
    desc: '聚合平台 · 一把 Key 多家模型 · 有免费额度',
    keyUrl: 'https://cloud.siliconflow.cn/account/ak',
    category: 'cn',
  },
  {
    id: 'xiaomi',
    name: '小米 MiMo',
    baseUrl: 'https://api.xiaomi.com/v1',
    models: ['MiMo-V2-Flash', 'mimo-pro'],
    desc: '新玩家 · 有免费额度',
    keyUrl: 'https://platform.xiaomimimo.com/',
    category: 'cn',
  },
  // ===== 海外 =====
  {
    id: 'openai',
    name: 'OpenAI',
    baseUrl: 'https://api.openai.com/v1',
    models: ['gpt-4o-mini', 'gpt-4o', 'gpt-4.1-mini'],
    desc: 'GPT 系列 · 需海外支付',
    keyUrl: 'https://platform.openai.com/api-keys',
    category: 'global',
  },
  {
    id: 'anthropic',
    name: 'Anthropic Claude',
    baseUrl: 'https://api.anthropic.com/v1',
    models: ['claude-sonnet-4-20250514', 'claude-3-5-sonnet-latest', 'claude-3-5-haiku-latest'],
    desc: 'Claude 系列 · 写作质量佳',
    keyUrl: 'https://console.anthropic.com/settings/keys',
    category: 'global',
  },
  {
    id: 'gemini',
    name: 'Google Gemini',
    baseUrl: 'https://generativelanguage.googleapis.com/v1beta/openai',
    models: ['gemini-2.0-flash', 'gemini-1.5-pro'],
    desc: '有免费额度 · 需海外网络',
    keyUrl: 'https://aistudio.google.com/app/apikey',
    category: 'global',
  },
  {
    id: 'groq',
    name: 'Groq',
    baseUrl: 'https://api.groq.com/openai/v1',
    models: ['llama-3.3-70b-versatile', 'llama-3.1-8b-instant'],
    desc: '极速推理 · 有免费额度',
    keyUrl: 'https://console.groq.com/keys',
    category: 'global',
  },
  {
    id: 'openrouter',
    name: 'OpenRouter',
    baseUrl: 'https://openrouter.ai/api/v1',
    models: ['openai/gpt-4o-mini', 'anthropic/claude-3.5-sonnet', 'google/gemini-2.0-flash-001'],
    desc: '聚合平台 · 数百模型一个 Key',
    keyUrl: 'https://openrouter.ai/keys',
    category: 'global',
  },
  {
    id: 'mistral',
    name: 'Mistral',
    baseUrl: 'https://api.mistral.ai/v1',
    models: ['mistral-large-latest', 'mistral-small-latest'],
    desc: '欧洲代表厂商',
    keyUrl: 'https://console.mistral.ai/api-keys',
    category: 'global',
  },
  {
    id: 'xai',
    name: 'xAI Grok',
    baseUrl: 'https://api.x.ai/v1',
    models: ['grok-2-latest', 'grok-2-mini'],
    desc: '马斯克旗下 xAI',
    keyUrl: 'https://console.x.ai',
    category: 'global',
  },
  {
    id: 'together',
    name: 'Together AI',
    baseUrl: 'https://api.together.xyz/v1',
    models: ['meta-llama/Llama-3.3-70B-Instruct-Turbo', 'Qwen/Qwen2.5-72B-Instruct-Turbo'],
    desc: '开源模型云托管',
    keyUrl: 'https://api.together.ai/settings/api-keys',
    category: 'global',
  },
  {
    id: 'fireworks',
    name: 'Fireworks AI',
    baseUrl: 'https://api.fireworks.ai/inference/v1',
    models: ['accounts/fireworks/models/llama-v3p3-70b-instruct'],
    desc: '高速开源模型推理',
    keyUrl: 'https://fireworks.ai/account/api-keys',
    category: 'global',
  },
  {
    id: 'cerebras',
    name: 'Cerebras',
    baseUrl: 'https://api.cerebras.ai/v1',
    models: ['llama3.1-70b', 'llama3.1-8b'],
    desc: '晶圆级加速 · 极快',
    keyUrl: 'https://cloud.cerebras.ai',
    category: 'global',
  },
  {
    id: 'perplexity',
    name: 'Perplexity',
    baseUrl: 'https://api.perplexity.ai',
    models: ['sonar', 'sonar-pro'],
    desc: '带联网搜索能力',
    keyUrl: 'https://www.perplexity.ai/settings/api',
    category: 'global',
  },
  {
    id: 'deepinfra',
    name: 'DeepInfra',
    baseUrl: 'https://api.deepinfra.com/v1/openai',
    models: ['meta-llama/Llama-3.3-70B-Instruct', 'deepseek-ai/DeepSeek-V3'],
    desc: '低价开源模型',
    keyUrl: 'https://deepinfra.com/dash/api_keys',
    category: 'global',
  },
  // ===== 本地 =====
  {
    id: 'ollama',
    name: 'Ollama',
    baseUrl: 'http://localhost:11434/v1',
    models: ['qwen2.5', 'llama3.1'],
    desc: '完全免费 · 模型跑在你电脑上',
    category: 'local',
  },
  {
    id: 'lmstudio',
    name: 'LM Studio',
    baseUrl: 'http://localhost:1234/v1',
    models: ['local-model'],
    desc: '本地图形化模型管理',
    category: 'local',
  },
  {
    id: 'vllm',
    name: 'vLLM',
    baseUrl: 'http://localhost:8000/v1',
    models: ['local-model'],
    desc: '自建推理服务',
    category: 'local',
  },
];

const STORAGE_KEY = 'os_providers';
const LEGACY_KEY = 'os_model_config';

/** 预设目录 → 已配置厂商(取目录默认模型) */
export function presetToConfig(preset: ProviderPreset): ProviderConfig {
  return {
    id: preset.id,
    name: preset.name,
    baseUrl: preset.baseUrl,
    apiKey: '',
    model: preset.models[0] ?? '',
  };
}

/** 读多厂商存储;首次使用自动迁移旧的单配置 */
export function loadProviderStore(): ProviderStore {
  try {
    const raw = localStorage.getItem(STORAGE_KEY);
    if (raw) {
      const parsed = JSON.parse(raw) as ProviderStore;
      if (Array.isArray(parsed.providers) && parsed.providers.length > 0) {
        // 修正缺失的默认路由(指向第一个已配置密钥的,否则第一个)
        if (!parsed.defaultId || !parsed.providers.some((p) => p.id === parsed.defaultId)) {
          const withKey = parsed.providers.find((p) => p.apiKey.trim() !== '');
          parsed.defaultId = (withKey ?? parsed.providers[0]).id;
        }
        return parsed;
      }
    }
  } catch {
    // 数据损坏,走迁移
  }
  return migrateLegacy();
}

/** 旧单配置(os_model_config)→ 单厂商 store;无旧数据则空 store */
function migrateLegacy(): ProviderStore {
  const empty: ProviderStore = { providers: [], defaultId: '' };
  try {
    const raw = localStorage.getItem(LEGACY_KEY);
    if (!raw) return empty;
    const legacy = JSON.parse(raw) as { baseUrl?: string; model?: string };
    if (!legacy.baseUrl || !legacy.model) return empty;
    // 按 baseUrl 反查预设目录取名,查不到算自定义
    const preset = PROVIDER_PRESETS.find((p) => p.baseUrl === legacy.baseUrl);
    const provider: ProviderConfig = {
      id: preset?.id ?? 'custom-legacy',
      name: preset?.name ?? '自定义',
      baseUrl: legacy.baseUrl,
      apiKey: '',
      model: legacy.model,
    };
    const store: ProviderStore = { providers: [provider], defaultId: provider.id };
    persist(store);
    return store;
  } catch {
    return empty;
  }
}

function persist(store: ProviderStore): void {
  localStorage.setItem(STORAGE_KEY, JSON.stringify(store));
}

export function saveProviderStore(store: ProviderStore): void {
  persist(store);
}

/** 保存单个厂商配置(存在则覆盖,否则追加);首个配置自动成为默认路由 */
export function saveProviderConfig(config: ProviderConfig): ProviderStore {
  const store = loadProviderStore();
  const idx = store.providers.findIndex((p) => p.id === config.id);
  if (idx >= 0) store.providers[idx] = config;
  else store.providers.push(config);
  if (!store.defaultId || !store.providers.some((p) => p.id === store.defaultId)) {
    store.defaultId = config.id;
  }
  persist(store);
  return store;
}

export function removeProvider(id: string): ProviderStore {
  const store = loadProviderStore();
  store.providers = store.providers.filter((p) => p.id !== id);
  if (store.defaultId === id) {
    const next = store.providers.find((p) => p.apiKey.trim() !== '') ?? store.providers[0];
    store.defaultId = next?.id ?? '';
  }
  persist(store);
  return store;
}

/** 切换默认路由:车间所有 Agent 立即改走该厂商 */
export function setDefaultProvider(id: string): ProviderStore {
  const store = loadProviderStore();
  if (store.providers.some((p) => p.id === id)) {
    store.defaultId = id;
    persist(store);
  }
  return store;
}

/** 默认路由当前是否可用(已配置密钥) */
export function isRouteReady(store?: ProviderStore): boolean {
  const s = store ?? loadProviderStore();
  const current = s.providers.find((p) => p.id === s.defaultId);
  return !!current && current.apiKey.trim() !== '';
}
