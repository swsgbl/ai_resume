/**
 * OAuth 统一配置文件
 *
 * 渠道可用性由后端 /auth/oauth/providers 动态返回(未配密钥的渠道不显示)
 * 静态数组仅提供图标/颜色等元数据
 * state 采用 SHA-256 指纹存储,provider 以数字 ID 入 sessionStorage(防注入)
 */

export interface OAuthProviderConfig {
  key: string;
  name: string;
  enabled: boolean;
  color: string;
  bgColor: string;
  icon: string;
}

/** 所有已知渠道的元数据(图标/颜色/名称), 无论后端是否配置 */
const PROVIDER_META: OAuthProviderConfig[] = [
  {
    key: 'qq',
    name: 'QQ',
    enabled: true,
    color: '#12B7F5',
    bgColor: 'rgba(18, 183, 245, 0.15)',
    icon: 'qq',
  },
  {
    key: 'gitee',
    name: 'Gitee',
    enabled: true,
    color: '#C71D23',
    bgColor: 'rgba(199, 29, 35, 0.15)',
    icon: 'gitee',
  },
  {
    key: 'github',
    name: 'GitHub',
    enabled: true,
    color: '#ffffff',
    bgColor: 'rgba(255, 255, 255, 0.1)',
    icon: 'github',
  },
  {
    key: 'google',
    name: 'Google',
    enabled: true,
    color: '#4285F4',
    bgColor: 'rgba(66, 133, 244, 0.15)',
    icon: 'google',
  },
  {
    key: 'discord',
    name: 'Discord',
    enabled: true,
    color: '#5865F2',
    bgColor: 'rgba(88, 101, 242, 0.15)',
    icon: 'discord',
  },
];

/** provider 数字 ID(sessionStorage 防注入,OAuthCallbackPage 校验用) */
const PROVIDER_STORAGE_IDS = {
  google: 1,
  github: 2,
  gitee: 3,
  qq: 4,
  discord: 5,
} as const;

/** 向后兼容:返回静态全量列表(仅用于 OAuthProviderIcon 图标渲染等无需动态过滤的场景) */
export const OAUTH_PROVIDERS = PROVIDER_META;

/** 根据 key 获取渠道元数据 */
export function getProvider(key: string): OAuthProviderConfig | undefined {
  return PROVIDER_META.find((p) => p.key === key);
}

/** API 基础地址 */
export function getApiBaseUrl(): string {
  return import.meta.env.VITE_API_URL || '';
}

/** state 的 SHA-256 指纹(原始 state 不落存储,回调时比对哈希) */
export async function getStateFingerprint(state: string): Promise<string | null> {
  if (!globalThis.crypto?.subtle) return null;
  const digest = await crypto.subtle.digest('SHA-256', new TextEncoder().encode(state));
  return Array.from(new Uint8Array(digest), (byte) => byte.toString(16).padStart(2, '0')).join('');
}

/**
 * 从后端获取实际可用的 OAuth 渠道列表(未配密钥的渠道不返回)
 * 后端端点: GET /api/v1/auth/oauth/providers → { providers: ["qq","gitee",...] }
 */
let _cachedAvailable: string[] | null = null;
export async function fetchAvailableProviders(): Promise<OAuthProviderConfig[]> {
  const baseUrl = getApiBaseUrl();
  if (_cachedAvailable === null) {
    try {
      const res = await fetch(`${baseUrl}/api/v1/auth/oauth/providers`);
      if (res.ok) {
        const data = await res.json();
        _cachedAvailable = data.providers ?? [];
      } else {
        _cachedAvailable = [];
      }
    } catch {
      _cachedAvailable = [];
    }
  }
  return PROVIDER_META.filter((p) => _cachedAvailable!.includes(p.key));
}

/** 同步版(供已 fetch 后的场景使用,避免 async) */
export function getCachedProviders(): OAuthProviderConfig[] {
  if (_cachedAvailable === null) return [];
  return PROVIDER_META.filter((p) => _cachedAvailable!.includes(p.key));
}

/** 清除缓存(用于测试或配置变更后) */
export function clearProviderCache(): void {
  _cachedAvailable = null;
}

/** 发起 OAuth 授权流程 */
export async function initiateOAuth(providerKey: string): Promise<void> {
  const baseUrl = getApiBaseUrl();
  const providerStorageId = PROVIDER_STORAGE_IDS[providerKey as keyof typeof PROVIDER_STORAGE_IDS];
  if (!providerStorageId) {
    throw new Error(`不支持的 OAuth 提供商: ${providerKey}`);
  }
  const res = await fetch(`${baseUrl}/api/v1/auth/oauth/${providerKey}/authorize`);
  const json = await res.json();

  if (!res.ok || !json?.data?.auth_url) {
    throw new Error(json?.detail || `获取 ${providerKey} 授权地址失败`);
  }

  // 保存 state 到 sessionStorage 用于回调验证
  const stateFingerprint = await getStateFingerprint(json.data.state);
  if (stateFingerprint) {
    sessionStorage.setItem('oauth_state_hash', stateFingerprint);
  }
  sessionStorage.setItem('oauth_provider', String(providerStorageId));

  // 跳转到第三方授权页
  window.location.href = json.data.auth_url;
}
