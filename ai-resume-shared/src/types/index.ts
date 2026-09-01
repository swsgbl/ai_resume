/**
 * 用户角色枚举
 */
export enum UserRole {
  USER = 'user',
  PREMIUM = 'premium',
  ENTERPRISE = 'enterprise',
  ADMIN = 'admin',
}

/**
 * 简历状态枚举
 */
export enum ResumeStatus {
  DRAFT = 'draft',
  PUBLISHED = 'published',
  ARCHIVED = 'archived',
}

/**
 * 用户接口
 */
export interface User {
  id: number;
  email: string;
  phone?: string;
  role: UserRole;
  avatar?: string;
  nickname?: string;
  created_at: string;
  updated_at?: string;
}

/**
 * 认证响应接口
 */
export interface AuthResponse {
  access_token: string;
  refresh_token?: string;
  token_type: string;
  expires_in?: number;
  user?: User;
}

/**
 * 基本信息
 */
export interface BasicInfo {
  name?: string;
  email?: string;
  phone?: string;
  location?: string;
  title?: string;
  summary?: string;
  avatar?: string;
  linkedin?: string;
  github?: string;
  website?: string;
  job_intention?: string;
  self_introduction?: string;
}

/**
 * 教育经历
 */
export interface Education {
  id?: string;
  school: string;
  degree: string;
  major?: string;
  start_date?: string;
  end_date?: string;
  gpa?: string;
  description?: string;
}

/**
 * 工作经历
 */
export interface WorkExperience {
  id?: string;
  company: string;
  position: string;
  start_date?: string;
  end_date?: string;
  is_current?: boolean;
  location?: string;
  description?: string;
  achievements?: string[];
}

/**
 * 项目经历
 */
export interface Project {
  id?: string;
  name: string;
  role?: string;
  start_date?: string;
  end_date?: string;
  description?: string;
  tech_stack?: string[];
  highlights?: string[];
  link?: string;
}

/**
 * 技能
 */
export interface Skill {
  id?: string;
  name: string;
  category?: string;
  level?: number;
  keywords?: string[];
}

/**
 * 证书荣誉
 */
export interface Certification {
  id?: string;
  name: string;
  issuer?: string;
  issue_date?: string;
  expiry_date?: string;
  credential_id?: string;
  url?: string;
}

/**
 * 自定义模块
 */
export interface CustomSection {
  id?: string;
  title: string;
  content?: string;
  items?: CustomItem[];
  order?: number;
}

/**
 * 自定义条目
 */
export interface CustomItem {
  title?: string;
  subtitle?: string;
  description?: string;
  date?: string;
}

/**
 * 简历内容
 */
export interface ResumeContent {
  basic_info?: BasicInfo;
  education?: Education[];
  work_experience?: WorkExperience[];
  projects?: Project[];
  skills?: Skill[];
  certifications?: Certification[];
  custom_sections?: CustomSection[];
}

/**
 * 简历接口
 */
export interface Resume {
  id: number;
  user_id: number;
  title: string;
  content?: ResumeContent;
  template_id?: number;
  status: ResumeStatus;
  created_at: string;
  updated_at?: string;
  description?: string;
}

/**
 * 模板接口
 */
export interface Template {
  id: number;
  name: string;
  description?: string;
  category?: string;
  sub_category?: string;
  level?: string;
  layout: 'single' | 'double';
  thumbnail_url?: string;
  preview_url?: string;
  is_premium: boolean;
  is_favorited?: boolean;
  use_count: number;
  style_config?: Record<string, unknown>;
  created_at: string;
}

/**
 * 分页响应 - 与后端 PageResponse 一致
 */
export interface PaginatedResponse<T> {
  data: T[];
  total: number;
  page: number;
  page_size: number;
  total_pages?: number;
}

/**
 * API 响应基础类型
 */
export interface ApiResponse<T = unknown> {
  code: number;
  message: string;
  data?: T;
  detail?: unknown;
}

/**
 * AI 提供商枚举
 */
export enum AIProvider {
  OPENAI = 'openai',
  DEEPSEEK = 'deepseek',
  XIAOMI = 'xiaomi',
}

/**
 * 简历筛选条件
 */
export interface ResumeFilter { status?: ResumeStatus; search?: string; page?: number; page_size?: number; [key: string]: unknown; }

/**
 * 模板筛选条件
 */
export interface TemplateFilter { category?: string; sub_category?: string; level?: string; is_premium?: boolean; search?: string; sort_by?: string; page?: number; page_size?: number; [key: string]: unknown; }

/**
 * 注册请求数据
 */
export interface RegisterRequest {
  email: string;
  password: string;
  phone?: string;
  username?: string;
  verification_code: string;
}

/**
 * 登录请求数据
 */
export interface LoginRequest {
  email: string;
  password: string;
}

/**
 * 创建简历请求数据
 */
export interface CreateResumeRequest {
  title: string;
  description?: string;
  template_id?: number;
  content?: ResumeContent;
}

/**
 * 更新简历请求数据
 */
export interface UpdateResumeRequest {
  title?: string;
  description?: string;
  template_id?: number;
  content?: ResumeContent;
  style_config?: Record<string, unknown>;
}

/**
 * AI 生成简历请求
 */
export interface AIGenerateRequest {
  target_position: string;
  user_background?: string;
  style?: string;
  language?: string;
}

/**
 * AI 优化内容请求
 */
export interface AIOptimizeRequest {
  content: string;
  optimization_type: string;
  context?: string;
}

/**
 * API 错误类
 */
export class ApiException extends Error {
  constructor(
    public message: string,
    public statusCode: number,
    public detail?: unknown
  ) {
    super(message);
    this.name = 'ApiException';
  }
}
