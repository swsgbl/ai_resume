/**
 * HelpPage 组件测试
 */
import { describe, it, expect, vi } from 'vitest';
import { render, screen } from '@testing-library/react';
import '@testing-library/jest-dom';
import { MemoryRouter } from 'react-router-dom';
import { HelmetProvider } from 'react-helmet-async';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { I18nextProvider } from 'react-i18next';
import i18n from 'i18next';
import { initReactI18next } from 'react-i18next';
import zh from '../locales/zh.json';
import en from '../locales/en.json';
import HelpPage from './HelpPage';

// Mock UIComponents
vi.mock('../components/UIComponents', () => ({
  GradientText: ({ children }: { children: React.ReactNode }) => <span className="gradient-text">{children}</span>,
  Orb: () => null,
}));

// Mock SEO component
vi.mock('../components/SEO', () => ({
  SEO: () => null,
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

describe('HelpPage', () => {
  const wrapper = ({ children }: { children: React.ReactNode }) => (
    <QueryClientProvider client={queryClient}>
      <I18nextProvider i18n={testI18n}>
        <HelmetProvider>
          <MemoryRouter>
            {children}
          </MemoryRouter>
        </HelmetProvider>
      </I18nextProvider>
    </QueryClientProvider>
  );

  it('渲染帮助中心页面', () => {
    render(<HelpPage />, { wrapper });

    expect(screen.getByText(/帮助中心/)).toBeInTheDocument();
    expect(screen.getByText('常见问题解答和使用指南')).toBeInTheDocument();
  });

  it('显示快速导航卡片', () => {
    render(<HelpPage />, { wrapper });

    expect(screen.getByText('新用户注册')).toBeInTheDocument();
    expect(screen.getByText('模板库')).toBeInTheDocument();
    expect(screen.getByText('联系客服')).toBeInTheDocument();
  });

  it('显示所有 FAQ 问题', () => {
    render(<HelpPage />, { wrapper });

    const expectedQuestions = [
      '如何创建一份新简历？',
      '如何使用 AI 功能生成简历？',
      '支持哪些导出格式？',
      '如何更换简历模板？',
      '忘记密码怎么办？',
      '如何联系客服？'
    ];

    expectedQuestions.forEach(question => {
      expect(screen.getByText(question)).toBeInTheDocument();
    });
  });

  it('显示使用指南', () => {
    render(<HelpPage />, { wrapper });

    expect(screen.getByText('使用指南')).toBeInTheDocument();
    expect(screen.getByText('1. 创建账号')).toBeInTheDocument();
    expect(screen.getByText('2. 创建简历')).toBeInTheDocument();
    expect(screen.getByText('3. AI 优化')).toBeInTheDocument();
    expect(screen.getByText('4. 导出简历')).toBeInTheDocument();
  });

  it('有登录链接', () => {
    render(<HelpPage />, { wrapper });

    expect(screen.getAllByText('登录').length).toBeGreaterThan(0);
  });
});
