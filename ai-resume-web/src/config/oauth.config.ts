/**
 * OAuth 统一配置文件
 *
 * 使用说明：
 * 1. 在各平台创建 OAuth 应用，获取 Client ID 和 Client Secret
 * 2. 将 Client ID / Client Secret 填入后端 .env 文件（前端不需要密钥）
 * 3. enabled 开关控制平台是否在前端显示
 */

export interface OAuthProviderConfig {
  key: string;
  name: string;
  enabled: boolean;
  color: string;
  bgColor: string;
  icon: string;
}

export const OAUTH_PROVIDERS: OAuthProviderConfig[] = [
  {
    key: 'google',
    name: 'Google',
    enabled: true,
    color: '#4285F4',
    bgColor: 'rgba(66, 133, 244, 0.15)',
    icon: 'google',
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
    key: 'gitee',
    name: 'Gitee',
    enabled: true,
    color: '#C71D23',
    bgColor: 'rgba(199, 29, 35, 0.15)',
    icon: 'gitee',
  },
  {
    key: 'qq',
    name: 'QQ',
    enabled: true,
    color: '#12B7F5',
    bgColor: 'rgba(18, 183, 245, 0.15)',
    icon: 'qq',
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

const PROVIDER_STORAGE_IDS = {
  google: 1,
  github: 2,
  gitee: 3,
  qq: 4,
  discord: 5,
} as const;

// 获取所有已启用的 OAuth 提供商
export function getEnabledProviders(): OAuthProviderConfig[] {
  return OAUTH_PROVIDERS.filter((p) => p.enabled);
}

// 根据 key 获取提供商配置
export function getProvider(key: string): OAuthProviderConfig | undefined {
  return OAUTH_PROVIDERS.find((p) => p.key === key);
}

// API 基础地址
export function getApiBaseUrl(): string {
  return import.meta.env.VITE_API_URL || '';
}

export async function getStateFingerprint(state: string): Promise<string | null> {
  if (!globalThis.crypto?.subtle) return null;
  const digest = await crypto.subtle.digest('SHA-256', new TextEncoder().encode(state));
  return Array.from(new Uint8Array(digest), byte => byte.toString(16).padStart(2, '0')).join('');
}

// 发起 OAuth 授权流程
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
