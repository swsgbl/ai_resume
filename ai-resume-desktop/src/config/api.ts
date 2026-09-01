import { createApiClient } from '@ai-resume/shared/api';

// 桌面端API配置
const API_BASE_URL = import.meta.env.VITE_API_BASE_URL || 'http://192.168.8.6:8080/api';

// 创建配置好的API客户端
export const apiClient = createApiClient({
  baseURL: API_BASE_URL,
  timeout: 30000,
});

// 重新导出API服务，使用配置的客户端
export { apiClient as api };
