import axios, { AxiosError, AxiosInstance, AxiosResponse } from 'axios';

/**
 * 获取默认API基础URL
 * 尝试从localStorage读取用户配置的API地址，否则使用默认值
 */
function getDefaultBaseURL(): string {
  if (typeof localStorage !== 'undefined') {
    return localStorage.getItem('api_base_url') || 'http://127.0.0.1:8000/api/v1';
  }
  return 'http://127.0.0.1:8000/api/v1';
}

/**
 * API 异常类
 * 用于处理API请求返回的错误信息
 */
export class ApiException extends Error {
  constructor(
    public errorMessage: string,
    public statusCode: number,
    public detail?: unknown
  ) {
    super(errorMessage);
    this.name = 'ApiException';
  }
}

/**
 * API 客户端配置
 */
export interface ApiClientConfig {
  baseURL?: string;
  timeout?: number;
  getToken?: () => string | null;
  setToken?: (token: string) => void;
  onUnauthorized?: () => void;
}

/**
 * API 客户端类
 */
export class ApiClient {
  private client: AxiosInstance;
  private token: string | null = null;
  private config: Required<Pick<ApiClientConfig, 'baseURL' | 'timeout'>>;

  constructor(config: ApiClientConfig = {}) {
    this.config = {
      baseURL: config.baseURL ?? getDefaultBaseURL(),
      timeout: config.timeout ?? 30000,
    };

    this.client = axios.create({
      baseURL: this.config.baseURL,
      timeout: this.config.timeout,
      headers: {
        'Content-Type': 'application/json',
        Accept: 'application/json',
      },
      // 只接受 2xx 状态码为成功，其他都视为错误
      validateStatus: (status) => status >= 200 && status < 300,
    });

    this.setupInterceptors(config);
  }

  /**
   * 设置请求拦截器
   */
  private setupInterceptors(config: ApiClientConfig): void {
    // 请求拦截器
    this.client.interceptors.request.use(
      (request) => {
        const token = config.getToken?.() ?? this.token;
        if (token) {
          request.headers.Authorization = `Bearer ${token}`;
        }
        return request;
      },
      (error) => Promise.reject(error)
    );

    // 响应拦截器
    this.client.interceptors.response.use(
      (response) => response,
      (error) => {
        if (error.response?.status === 401) {
          this.clearToken();
          config.onUnauthorized?.();
        }
        return Promise.reject(this.handleError(error));
      }
    );
  }

  /**
   * 处理 API 响应
   * 支持所有2xx状态码（200, 201, 204等）
   */
  private handleResponse<T>(response: AxiosResponse): T {
    // 处理有数据的情况
    if (response.data) {
      if (typeof response.data === 'object' && 'data' in response.data) {
        return response.data.data as T;
      }
      return response.data as T;
    }

    // 处理204 No Content等情况
    if (response.status === 204) {
      return undefined as T;
    }

    throw new Error(response.data?.message ?? '请求失败');
  }

  /**
   * 处理 API 错误
   */
  private handleError(error: unknown): unknown {
    if (axios.isCancel(error)) {
      return new Error('请求已取消');
    }

    if (axios.isAxiosError(error)) {
      const axiosError = error as AxiosError;

      // 超时错误
      if (
        axiosError.code === 'ECONNABORTED' ||
        axiosError.message.includes('timeout')
      ) {
        return new Error('连接超时，请检查网络');
      }

      // 连接错误
      if (axiosError.code === 'ERR_NETWORK') {
        return new Error('无法连接到服务器，请检查网络或服务器配置');
      }

      // 响应错误
      if (axiosError.response) {
        const data = axiosError.response.data as { message?: string; detail?: unknown };
        let message = '请求失败';

        if (typeof data === 'object') {
          message = (data.message ?? data.detail ?? message) as string;
          if (data.detail && typeof data.detail === 'object' && 'msg' in data.detail) {
            message = (data.detail as { msg: string }).msg;
          }
        }

        return new ApiException(
          message as string,
          axiosError.response.status,
          data.detail
        );
      }
    }

    return new Error(error instanceof Error ? error.message : '未知错误');
  }

  /**
   * 设置访问令牌
   */
  setToken(token: string): void {
    this.token = token;
  }

  /**
   * 清除访问令牌
   */
  clearToken(): void {
    this.token = null;
  }

  /**
   * 获取访问令牌
   */
  getToken(): string | null {
    return this.token;
  }

  /**
   * 设置基础 URL
   */
  setBaseURL(url: string): void {
    this.config.baseURL = url;
    this.client.defaults.baseURL = url;
  }

  /**
   * 获取基础 URL
   */
  getBaseURL(): string {
    return this.config.baseURL;
  }

  /**
   * GET 请求
   */
  async get<T>(url: string, params?: Record<string, unknown>): Promise<T> {
    const response = await this.client.get(url, { params });
    return this.handleResponse<T>(response);
  }

  /**
   * POST 请求
   */
  async post<T>(url: string, data?: unknown, config?: Record<string, unknown>): Promise<T> {
    const response = await this.client.post(url, data, config);
    return this.handleResponse<T>(response);
  }

  /**
   * PUT 请求
   */
  async put<T>(url: string, data?: unknown): Promise<T> {
    const response = await this.client.put(url, data);
    return this.handleResponse<T>(response);
  }

  /**
   * PATCH 请求
   */
  async patch<T>(url: string, data?: unknown): Promise<T> {
    const response = await this.client.patch(url, data);
    return this.handleResponse<T>(response);
  }

  /**
   * DELETE 请求
   */
  async delete<T>(url: string): Promise<T> {
    const response = await this.client.delete(url);
    return this.handleResponse<T>(response);
  }

  /**
   * 上传文件
   */
  async upload<T>(url: string, file: File, onProgress?: (progress: number) => void): Promise<T> {
    const formData = new FormData();
    formData.append('file', file);

    const response = await this.client.post(url, formData, {
      headers: {
        'Content-Type': 'multipart/form-data',
      },
      onUploadProgress: (progressEvent) => {
        if (onProgress && progressEvent.total) {
          const progress = Math.round((progressEvent.loaded * 100) / progressEvent.total);
          onProgress(progress);
        }
      },
    });

    return this.handleResponse<T>(response);
  }

  /**
   * 获取原始 axios 实例
   */
  get instance(): AxiosInstance {
    return this.client;
  }
}

// 默认导出单例
let defaultClient: ApiClient | null = null;

// Token getter that can be configured
let tokenGetter: (() => string | null) | null = null;

export function setTokenGetter(getter: () => string | null): void {
  tokenGetter = getter;
  // Update existing client if it exists
  if (defaultClient) {
    defaultClient.setToken(tokenGetter() ?? '');
  }
}

export function createApiClient(config?: ApiClientConfig): ApiClient {
  if (!defaultClient) {
    defaultClient = new ApiClient({
      ...config,
      getToken: () => tokenGetter?.() ?? null,
    });
  }
  return defaultClient;
}

export function getApiClient(): ApiClient {
  if (!defaultClient) {
    defaultClient = new ApiClient({
      getToken: () => tokenGetter?.() ?? null,
    });
  }
  return defaultClient;
}

/**
 * 初始化API客户端，配置token获取函数
 */
export function initApiClient(getToken: () => string | null): void {
  setTokenGetter(getToken);
}
