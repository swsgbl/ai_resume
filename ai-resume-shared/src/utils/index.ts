import type { User } from '../types/index.js';

/**
 * 本地存储工具
 */
export const storage = {
  /**
   * 获取 token
   */
  getToken(): string | null {
    return localStorage.getItem('access_token');
  },

  /**
   * 设置 token
   */
  setToken(token: string): void {
    localStorage.setItem('access_token', token);
  },

  /**
   * 移除 token
   */
  removeToken(): void {
    localStorage.removeItem('access_token');
  },

  /**
   * 获取刷新 token
   */
  getRefreshToken(): string | null {
    return localStorage.getItem('refresh_token');
  },

  /**
   * 设置刷新 token
   */
  setRefreshToken(token: string): void {
    localStorage.setItem('refresh_token', token);
  },

  /**
   * 移除刷新 token
   */
  removeRefreshToken(): void {
    localStorage.removeItem('refresh_token');
  },

  /**
   * 获取用户信息 - 修复返回类型
   */
  getUser(): User | null {
    const data = localStorage.getItem('user');
    if (!data) return null;
    try {
      return JSON.parse(data) as User;
    } catch {
      return null;
    }
  },

  /**
   * 设置用户信息 - 添加数据验证
   */
  setUser(user: unknown): void {
    if (!user || typeof user !== 'object') {
      throw new Error('Invalid user data');
    }
    // 使用structuredClone进行深拷贝，避免JSON.parse/stringify的限制
    const sanitized = structuredClone(user);
    localStorage.setItem('user', JSON.stringify(sanitized));
  },

  /**
   * 移除用户信息
   */
  removeUser(): void {
    localStorage.removeItem('user');
  },

  /**
   * 清除所有认证数据
   */
  clearAuth(): void {
    this.removeToken();
    this.removeRefreshToken();
    this.removeUser();
  },

  /**
   * 获取 API 基础 URL
   */
  getBaseURL(): string {
    return localStorage.getItem('api_base_url') || 'http://127.0.0.1:8000/api/v1';
  },

  /**
   * 设置 API 基础 URL
   */
  setBaseURL(url: string): void {
    localStorage.setItem('api_base_url', url);
  },

  /**
   * 移除 API 基础 URL
   */
  removeBaseURL(): void {
    localStorage.removeItem('api_base_url');
  },

  /**
   * 获取 AI 提供商
   */
  getAIProvider(): string {
    return localStorage.getItem('ai_provider') || 'openai';
  },

  /**
   * 设置 AI 提供商
   */
  setAIProvider(provider: string): void {
    localStorage.setItem('ai_provider', provider);
  },

  /**
   * 获取 OpenAI API Key
   */
  getOpenAIApiKey(): string | null {
    return localStorage.getItem('openai_api_key');
  },

  /**
   * 设置 OpenAI API Key
   */
  setOpenAIApiKey(key: string): void {
    localStorage.setItem('openai_api_key', key);
  },

  /**
   * 获取 OpenAI 模型
   */
  getOpenAIModel(): string | null {
    return localStorage.getItem('openai_model');
  },

  /**
   * 设置 OpenAI 模型
   */
  setOpenAIModel(model: string): void {
    localStorage.setItem('openai_model', model);
  },

  /**
   * 获取 DeepSeek API Key
   */
  getDeepSeekApiKey(): string | null {
    return localStorage.getItem('deepseek_api_key');
  },

  /**
   * 设置 DeepSeek API Key
   */
  setDeepSeekApiKey(key: string): void {
    localStorage.setItem('deepseek_api_key', key);
  },

  /**
   * 获取 DeepSeek 模型
   */
  getDeepSeekModel(): string | null {
    return localStorage.getItem('deepseek_model');
  },

  /**
   * 设置 DeepSeek 模型
   */
  setDeepSeekModel(model: string): void {
    localStorage.setItem('deepseek_model', model);
  },

  /**
   * 获取小米 API Key
   */
  getXiaomiApiKey(): string | null {
    return localStorage.getItem('xiaomi_api_key');
  },

  /**
   * 设置小米 API Key
   */
  setXiaomiApiKey(key: string): void {
    localStorage.setItem('xiaomi_api_key', key);
  },

  /**
   * 获取小米模型
   */
  getXiaomiModel(): string | null {
    return localStorage.getItem('xiaomi_model');
  },

  /**
   * 设置小米模型
   */
  setXiaomiModel(model: string): void {
    localStorage.setItem('xiaomi_model', model);
  },

  /**
   * 清除所有配置
   */
  clearAll(): void {
    localStorage.clear();
  },
};

/**
 * 格式化日期
 */
export function formatDate(date: string | Date): string {
  const d = typeof date === 'string' ? new Date(date) : date;
  const year = d.getFullYear();
  const month = String(d.getMonth() + 1).padStart(2, '0');
  const day = String(d.getDate()).padStart(2, '0');
  return `${year}-${month}-${day}`;
}

/**
 * 格式化日期时间
 */
export function formatDateTime(date: string | Date): string {
  const d = typeof date === 'string' ? new Date(date) : date;
  const year = d.getFullYear();
  const month = String(d.getMonth() + 1).padStart(2, '0');
  const day = String(d.getDate()).padStart(2, '0');
  const hours = String(d.getHours()).padStart(2, '0');
  const minutes = String(d.getMinutes()).padStart(2, '0');
  return `${year}-${month}-${day} ${hours}:${minutes}`;
}

/**
 * 生成随机 ID
 */
export function generateId(): string {
  return Math.random().toString(36).substring(2, 9);
}

/**
 * 防抖函数
 */
export function debounce<T extends (...args: unknown[]) => unknown>(
  fn: T,
  delay: number
): (...args: Parameters<T>) => void {
  let timeoutId: ReturnType<typeof setTimeout> | null = null;

  return function (this: unknown, ...args: Parameters<T>) {
    if (timeoutId) {
      clearTimeout(timeoutId);
    }
    timeoutId = setTimeout(() => {
      fn.apply(this, args);
    }, delay);
  };
}

/**
 * 节流函数
 */
export function throttle<T extends (...args: unknown[]) => unknown>(
  fn: T,
  delay: number
): (...args: Parameters<T>) => void {
  let lastCall = 0;

  return function (this: unknown, ...args: Parameters<T>) {
    const now = Date.now();
    if (now - lastCall >= delay) {
      lastCall = now;
      fn.apply(this, args);
    }
  };
}

/**
 * 下载文件
 */
export function downloadFile(url: string, filename: string): void {
  const link = document.createElement('a');
  link.href = url;
  link.download = filename;
  document.body.appendChild(link);
  link.click();
  document.body.removeChild(link);
}

/**
 * 复制到剪贴板
 */
export async function copyToClipboard(text: string): Promise<boolean> {
  try {
    await navigator.clipboard.writeText(text);
    return true;
  } catch {
    // 降级方案
    const textarea = document.createElement('textarea');
    textarea.value = text;
    textarea.style.position = 'fixed';
    textarea.style.opacity = '0';
    document.body.appendChild(textarea);
    textarea.select();
    const success = document.execCommand('copy');
    document.body.removeChild(textarea);
    return success;
  }
}

/**
 * 验证邮箱
 * 使用更标准的邮箱验证正则表达式
 */
export function isValidEmail(email: string): boolean {
  // 常见的邮箱验证正则：允许字母、数字、点、下划线、百分号、加号、减号
  const regex = /^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$/;
  return regex.test(email);
}

/**
 * 验证手机号（中国大陆）
 */
export function isValidPhone(phone: string): boolean {
  const regex = /^1[3-9]\d{9}$/;
  return regex.test(phone);
}

/**
 * 验证密码强度（至少8位，包含字母和数字）
 *
 * 验证规则：
 * - 最小长度8位
 * - 必须包含字母（大小写均可）
 * - 必须包含数字
 *
 * 强度评估：
 * - 弱：满足基本要求（8位+字母+数字）
 * - 中：12位以上 或 包含特殊字符
 * - 强：12位以上 且 包含特殊字符
 */
export function isValidPassword(password: string): {
  valid: boolean;
  strength: 'weak' | 'medium' | 'strong';
  message?: string;
} {
  if (password.length < 8) {
    return { valid: false, strength: 'weak', message: '密码长度至少8位' };
  }
  if (!/[A-Za-z]/.test(password)) {
    return { valid: false, strength: 'weak', message: '密码必须包含字母' };
  }
  if (!/\d/.test(password)) {
    return { valid: false, strength: 'weak', message: '密码必须包含数字' };
  }

  // 检查密码强度（与验证规则对齐）
  let strengthLevel = 0;
  if (password.length >= 12) strengthLevel++;
  if (/[!@#$%^&*()_+\-=\[\]{};':"\\|,.<>\/?]/.test(password)) strengthLevel++;

  if (strengthLevel >= 2) {
    return { valid: true, strength: 'strong' };
  } else if (strengthLevel === 1) {
    return { valid: true, strength: 'medium' };
  }
  return { valid: true, strength: 'weak' };
}

/**
 * 获取文件扩展名
 */
export function getFileExtension(filename: string): string {
  return filename.slice(((filename.lastIndexOf('.') - 1) >>> 0) + 2);
}

/**
 * 格式化文件大小
 */
export function formatFileSize(bytes: number): string {
  if (bytes === 0) return '0 Bytes';
  const k = 1024;
  const sizes = ['Bytes', 'KB', 'MB', 'GB'];
  const i = Math.floor(Math.log(bytes) / Math.log(k));
  return Math.round((bytes / Math.pow(k, i)) * 100) / 100 + ' ' + sizes[i];
}
