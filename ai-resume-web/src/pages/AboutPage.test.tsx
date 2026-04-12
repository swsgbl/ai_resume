/**
 * AboutPage 组件测试
 */
import { describe, it, expect, vi, beforeEach } from 'vitest';
import { render, screen } from '@testing-library/react';
import '@testing-library/jest-dom';
import { MemoryRouter } from 'react-router-dom';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { I18nextProvider } from 'react-i18next';
import i18n from 'i18next';
import { initReactI18next } from 'react-i18next';
import zh from '../locales/zh.json';
import en from '../locales/en.json';
import AboutPage from './AboutPage';

// Mock UIComponents
vi.mock('../components/UIComponents', () => ({
  GradientText: ({ children }: { children: React.ReactNode }) => <span className="gradient-text">{children}</span>,
  Orb: () => null,
}));

// Create test-specific i18n instance
const testI18n = i18n.createInstance();
testI18n.use(initReactI18next).init({
  resources: {
    zh: { translation: zh },
    en: { translation: en },
  },
  lng: 'zh',
  fallbackLng: 'zh',
  interpolation: { escapeValue: false },
});

const queryClient = new QueryClient({
  defaultOptions: {
    queries: { retry: false },
    mutations: { retry: false },
  },
});

describe('AboutPage', () => {
  const wrapper = ({ children }: { children: React.ReactNode }) => (
    <QueryClientProvider client={queryClient}>
      <I18nextProvider i18n={testI18n}>
        <MemoryRouter>
          {children}
        </MemoryRouter>
      </I18nextProvider>
    </QueryClientProvider>
  );

  it('渲染关于我们页面', () => {
    render(<AboutPage />, { wrapper });

    expect(screen.getByText('关于我们')).toBeInTheDocument();
  });

  it('显示产品介绍', () => {
    render(<AboutPage />, { wrapper });

    expect(screen.getByText('AI 简历智能生成平台')).toBeInTheDocument();
    expect(screen.getByText(/利用前沿 AI 技术/)).toBeInTheDocument();
  });

  it('显示统计数据', () => {
    render(<AboutPage />, { wrapper });

    expect(screen.getByText('50+')).toBeInTheDocument();
    expect(screen.getByText('专业模板')).toBeInTheDocument();
    expect(screen.getByText('3')).toBeInTheDocument();
    expect(screen.getByText('AI 模型')).toBeInTheDocument();
    expect(screen.getByText('100K+')).toBeInTheDocument();
    expect(screen.getByText('服务用户')).toBeInTheDocument();
    expect(screen.getByText('98%')).toBeInTheDocument();
    expect(screen.getByText('满意度')).toBeInTheDocument();
  });

  it('显示核心功能', () => {
    render(<AboutPage />, { wrapper });

    expect(screen.getByText('核心功能')).toBeInTheDocument();
    expect(screen.getByText('AI 智能生成')).toBeInTheDocument();
    expect(screen.getByText('精美模板')).toBeInTheDocument();
    expect(screen.getByText('多格式导出')).toBeInTheDocument();
    expect(screen.getByText('安全可靠')).toBeInTheDocument();
  });

  it('显示联系信息', () => {
    render(<AboutPage />, { wrapper });

    expect(screen.getByText('联系我们')).toBeInTheDocument();
    expect(screen.getByText('support@airesume.com')).toBeInTheDocument();
    expect(screen.getByText('https://github.com/airesume')).toBeInTheDocument();
  });

  it('显示版本信息', () => {
    render(<AboutPage />, { wrapper });

    expect(screen.getByText('版本 1.0.0')).toBeInTheDocument();
    expect(screen.getByText(/© 2026 AI Resume/)).toBeInTheDocument();
  });

  it('导航链接正确', () => {
    render(<AboutPage />, { wrapper });

    expect(screen.getByText('ndtool')).toBeInTheDocument();
    expect(screen.getAllByText('登录').length).toBeGreaterThan(0);
  });
});
