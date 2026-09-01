import type {
  AuthResponse,
  RegisterRequest,
  Resume,
  ResumeFilter,
  CreateResumeRequest,
  UpdateResumeRequest,
  AIGenerateRequest,
  AIOptimizeRequest,
  Template,
  TemplateFilter,
  PaginatedResponse,
} from '../types/index.js';
import { ApiClient, createApiClient, getApiClient, initApiClient } from './client.js';

// Re-export client functions
export { ApiClient, createApiClient, getApiClient, initApiClient };

/**
 * 认证 API
 */
export class AuthApi {
  constructor(private client: ApiClient = getApiClient()) {}

  /**
   * 发送邮箱验证码
   */
  async sendVerificationCode(email: string): Promise<void> {
    await this.client.post('/email/send-code', { email });
  }

  /**
   * 验证邮箱验证码
   */
  async verifyEmailCode(email: string, code: string): Promise<void> {
    await this.client.post('/email/verify-code', { email, code });
  }

  /**
   * 用户注册 - 修复：使用JSON而非FormData
   */
  async register(data: RegisterRequest): Promise<AuthResponse> {
    const payload: Record<string, string> = {
      email: data.email,
      password: data.password,
      verification_code: data.verification_code,
    };
    if (data.phone) payload.phone = data.phone;
    if (data.username) payload.username = data.username;

    return this.client.post<AuthResponse>('/auth/register', payload);
  }

  /**
   * 用户登录 - 使用form-data格式
   */
  async login(email: string, password: string): Promise<AuthResponse> {
    // 使用URLSearchParams发送form-data格式
    const params = new URLSearchParams();
    params.append('username', email);
    params.append('password', password);

    return this.client.post<AuthResponse>('/auth/login', params.toString(), {
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
      },
    });
  }

  /**
   * 获取当前用户信息
   */
  async getCurrentUser(): Promise<{ id: number; email: string; role: string }> {
    return this.client.get('/auth/me');
  }

  /**
   * 刷新令牌
   */
  async refreshToken(refreshToken: string): Promise<AuthResponse> {
    return this.client.post<AuthResponse>('/auth/refresh', {
      refresh_token: refreshToken,
    });
  }

  /**
   * 微信登录
   */
  async wechatLogin(code: string): Promise<AuthResponse> {
    return this.client.post<AuthResponse>('/auth/wechat/login', { code });
  }

  /**
   * 绑定微信
   */
  async wechatBind(code: string): Promise<void> {
    await this.client.post('/auth/wechat/bind', { code });
  }

  /**
   * 解绑微信
   */
  async wechatUnbind(): Promise<void> {
    await this.client.post('/auth/wechat/unbind');
  }
}

/**
 * 简历 API
 */
export class ResumeApi {
  constructor(private client: ApiClient = getApiClient()) {}

  /**
   * 获取简历列表
   */
  async getResumes(filter?: ResumeFilter): Promise<PaginatedResponse<Resume>> {
    return this.client.get<PaginatedResponse<Resume>>('/resumes', filter);
  }

  /**
   * 获取简历详情
   */
  async getResume(id: number): Promise<Resume> {
    return this.client.get<Resume>(`/resumes/${id}`);
  }

  /**
   * 创建简历
   */
  async createResume(data: CreateResumeRequest): Promise<Resume> {
    return this.client.post<Resume>('/resumes', data);
  }

  /**
   * 更新简历
   */
  async updateResume(id: number, data: UpdateResumeRequest): Promise<Resume> {
    return this.client.put<Resume>(`/resumes/${id}`, data);
  }

  /**
   * 删除简历
   */
  async deleteResume(id: number): Promise<void> {
    await this.client.delete(`/resumes/${id}`);
  }

  /**
   * 复制简历
   */
  async copyResume(id: number): Promise<Resume> {
    return this.client.post<Resume>(`/resumes/${id}/copy`);
  }

  /**
   * AI 生成简历内容
   */
  async aiGenerateResume(id: number, data: AIGenerateRequest): Promise<Resume> {
    return this.client.post<Resume>(`/resumes/${id}/ai/generate`, data);
  }

  /**
   * AI 优化内容
   */
  async aiOptimizeContent(data: AIOptimizeRequest): Promise<{ optimized: string }> {
    return this.client.post<{ optimized: string }>('/resumes/ai/optimize', data);
  }

  /**
   * 获取 PDF 导出 URL
   */
  getPdfExportUrl(id: number): string {
    const baseUrl = this.client.getBaseURL();
    return `${baseUrl}/../export/${id}/pdf`;
  }

  /**
   * 获取 Word 导出 URL
   */
  getWordExportUrl(id: number): string {
    const baseUrl = this.client.getBaseURL();
    return `${baseUrl}/../export/${id}/word`;
  }

  /**
   * 获取 HTML 导出 URL
   */
  getHtmlExportUrl(id: number): string {
    const baseUrl = this.client.getBaseURL();
    return `${baseUrl}/../export/${id}/html`;
  }

  /**
   * 获取预览 URL
   */
  getPreviewUrl(id: number): string {
    const baseUrl = this.client.getBaseURL();
    return `${baseUrl}/../export/${id}/preview`;
  }
}

/**
 * 模板 API
 */
export class TemplateApi {
  constructor(private client: ApiClient = getApiClient()) {}

  /**
   * 获取模板列表
   */
  async getTemplates(filter?: TemplateFilter): Promise<PaginatedResponse<Template>> {
    return this.client.get<PaginatedResponse<Template>>('/templates', filter);
  }

  /**
   * 获取模板详情
   */
  async getTemplate(id: number): Promise<Template> {
    return this.client.get<Template>(`/templates/${id}`);
  }

  /**
   * 获取模板分类
   */
  async getCategories(): Promise<string[]> {
    return this.client.get<string[]>('/templates/categories');
  }

  /**
   * 收藏模板
   */
  async favoriteTemplate(id: number): Promise<void> {
    await this.client.post(`/templates/${id}/favorite`);
  }

  /**
   * 取消收藏模板
   */
  async unfavoriteTemplate(id: number): Promise<void> {
    await this.client.delete(`/templates/${id}/favorite`);
  }

  /**
   * 获取收藏的模板列表
   */
  async getFavoriteTemplates(page = 1, pageSize = 20): Promise<PaginatedResponse<Template>> {
    return this.client.get<PaginatedResponse<Template>>('/templates/favorites/list', {
      page,
      page_size: pageSize,
    });
  }
}

/**
 * API 服务聚合导出
 */
export const api = {
  auth: new AuthApi(),
  resume: new ResumeApi(),
  template: new TemplateApi(),
};

// 默认导出
export default api;
