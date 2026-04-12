import { StrictMode } from 'react';
import { createRoot } from 'react-dom/client';
import { BrowserRouter } from 'react-router-dom';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { HelmetProvider } from 'react-helmet-async';
import { initApiClient, getApiClient } from '@ai-resume/shared/api';
import { storage } from '@ai-resume/shared';
import App from './App';
import './i18n';
import './index.css';

// 初始化API客户端，配置token获取
initApiClient(() => storage.getToken());

// 设置API Base URL
const API_BASE_URL = import.meta.env.VITE_API_BASE_URL || '/api/v1';
getApiClient().setBaseURL(API_BASE_URL);

// 获取 basename（用于子路径部署）
const basename = import.meta.env.BASE_URL === '/' ? undefined : import.meta.env.BASE_URL?.replace(/\/$/, '');

// 初始化性能监控 (生产环境启用)
if (import.meta.env.PROD) {
  import('./utils/performance').then(({ initPerformanceMonitoring }) => {
    initPerformanceMonitoring().catch(console.error);
  });
}

const queryClient = new QueryClient({
  defaultOptions: {
    queries: {
      retry: 1,
      refetchOnWindowFocus: false,
    },
  },
});

createRoot(document.getElementById('root')!).render(
  <StrictMode>
    <HelmetProvider>
      <QueryClientProvider client={queryClient}>
        <BrowserRouter basename={basename}>
          <App />
        </BrowserRouter>
      </QueryClientProvider>
    </HelmetProvider>
  </StrictMode>
);
