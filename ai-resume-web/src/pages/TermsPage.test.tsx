/**
 * TermsPage 组件测试
 */
import { describe, it, expect, vi } from 'vitest';
import { render, screen } from '@testing-library/react';
import '@testing-library/jest-dom';
import { MemoryRouter } from 'react-router-dom';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { I18nextProvider } from 'react-i18next';
import i18n from 'i18next';
import { initReactI18next } from 'react-i18next';
import zh from '../locales/zh.json';
import en from '../locales/en.json';
import TermsPage from './TermsPage';

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

describe('TermsPage', () => {
  const wrapper = ({ children }: { children: React.ReactNode }) => (
    <QueryClientProvider client={queryClient}>
      <I18nextProvider i18n={testI18n}>
        <MemoryRouter future={{ v7_startTransition: true, v7_relativeSplatPath: true }}>
          {children}
        </MemoryRouter>
      </I18nextProvider>
    </QueryClientProvider>
  );

  it('渲染用户协议页面', () => {
    render(<TermsPage />, { wrapper });

    expect(screen.getByText('用户协议')).toBeInTheDocument();
  });

  it('显示最后更新日期', () => {
    render(<TermsPage />, { wrapper });

    expect(screen.getByText(/最后更新日期：/)).toBeInTheDocument();
    expect(screen.getByText(/2024年1月1日/)).toBeInTheDocument();
  });

  it('包含主要章节标题', () => {
    const { container } = render(<TermsPage />, { wrapper });

    // 检查页面主要内容是否存在
    const pageTitle = screen.getByText('用户协议');
    expect(pageTitle).toBeInTheDocument();

    // 检查是否有section标题
    const headings = container.querySelectorAll('h2');
    expect(headings.length).toBeGreaterThan(0);
  });

  it('有登录链接', () => {
    render(<TermsPage />, { wrapper });

    expect(screen.getAllByText('登录').length).toBeGreaterThan(0);
  });

  it('显示平台Logo', () => {
    render(<TermsPage />, { wrapper });

    expect(screen.getByText('ndtool')).toBeInTheDocument();
  });
});
