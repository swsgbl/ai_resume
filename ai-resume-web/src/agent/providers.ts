/**
 * 多厂商模型路由存储 — 参考 OpenCode 的 provider 路由方案
 *
 * 设计:
 * - 每个厂商一份完整配置(baseUrl + apiKey + 当前选用模型),可并存多家
 * - defaultId 即「路由」:车间所有 Agent 默认走该厂商,可随时切换
 * - 预设目录内置主流 OpenAI 兼容厂商(含模型候选),也支持自定义接入
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

/** 预设厂商目录(models.dev 思路的本地精简版) */
export interface ProviderPreset {
  id: string;
  name: string;
  baseUrl: string;
  models: string[];
  /** 引导文案 */
  desc: string;
  /** 密钥申请地址(空表示无需密钥) */
  keyUrl?: string;
}

export const PROVIDER_PRESETS: ProviderPreset[] = [
  {
    id: 'deepseek',
    name: 'DeepSeek',
    baseUrl: 'https://api.deepseek.com/v1',
    models: ['deepseek-chat', 'deepseek-reasoner'],
    desc: '国内直连 · 性价比高 · 推荐',
    keyUrl: 'https://platform.deepseek.com/api_keys',
  },
  {
    id: 'openai',
    name: 'OpenAI',
    baseUrl: 'https://api.openai.com/v1',
    models: ['gpt-4o-mini', 'gpt-4o', 'gpt-4.1-mini'],
    desc: '效果强 · 需海外网络与支付',
    keyUrl: 'https://platform.openai.com/api-keys',
  },
  {
    id: 'xiaomi',
    name: '小米 MiMo',
    baseUrl: 'https://api.xiaomi.com/v1',
    models: ['MiMo-V2-Flash', 'mimo-pro'],
    desc: '新玩家 · 有免费额度',
    keyUrl: 'https://platform.xiaomimimo.com/',
  },
  {
    id: 'siliconflow',
    name: '硅基流动',
    baseUrl: 'https://api.siliconflow.cn/v1',
    models: ['deepseek-ai/DeepSeek-V3', 'Qwen/Qwen2.5-72B-Instruct'],
    desc: '国内聚合平台 · 一把 Key 多家模型',
    keyUrl: 'https://cloud.siliconflow.cn/account/ak',
  },
  {
    id: 'openrouter',
    name: 'OpenRouter',
    baseUrl: 'https://openrouter.ai/api/v1',
    models: ['anthropic/claude-3.5-sonnet', 'google/gemini-2.0-flash-001'],
    desc: '海外聚合平台 · 数百模型任选',
    keyUrl: 'https://openrouter.ai/keys',
  },
  {
    id: 'ollama',
    name: '本地 Ollama',
    baseUrl: 'http://localhost:11434/v1',
    models: ['qwen2.5', 'llama3.1'],
    desc: '完全免费 · 模型跑在你自己电脑上',
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
