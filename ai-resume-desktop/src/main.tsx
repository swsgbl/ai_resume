import { StrictMode } from 'react';
import { createRoot } from 'react-dom/client';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { BrowserRouter, useLocation } from 'react-router-dom';
import { getCurrentWindow } from '@tauri-apps/api/window';
import { useEffect } from 'react';
import { initApiClient } from '@ai-resume/shared/api';
import { storage } from '@ai-resume/shared';
import App from './App';
import './index.css';

// 初始化API客户端，配置token获取
initApiClient(() => storage.getToken());

const queryClient = new QueryClient({
  defaultOptions: {
    queries: {
      retry: 1,
      refetchOnWindowFocus: false,
    },
  },
});

// Wrapper to handle Tauri window state
function AppWrapper() {
  const location = useLocation();

  useEffect(() => {
    const titles: Record<string, string> = {
      '/': 'AI 简历 - 首页',
      '/login': 'AI 简历 - 登录',
      '/register': 'AI 简历 - 注册',
      '/resumes': 'AI 简历 - 我的简历',
      '/templates': 'AI 简历 - 模板中心',
      '/profile': 'AI 简历 - 个人中心',
      '/settings': 'AI 简历 - 设置',
    };

    const title = titles[location.pathname] || 'AI 简历';
    document.title = title;
    const appWindow = getCurrentWindow();
    appWindow.setTitle(title).catch(console.error);
  }, [location]);

  return <App />;
}

createRoot(document.getElementById('root')!).render(
  <StrictMode>
    <QueryClientProvider client={queryClient}>
      <BrowserRouter>
        <AppWrapper />
      </BrowserRouter>
    </QueryClientProvider>
  </StrictMode>
);
