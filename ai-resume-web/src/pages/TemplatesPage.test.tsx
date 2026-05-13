/**
 * TemplatesPage 组件测试
 */
import { describe, it, expect, vi } from 'vitest';
import { render, screen } from '@testing-library/react';
import '@testing-library/jest-dom';
import { MemoryRouter } from 'react-router-dom';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import TemplatesPage from './TemplatesPage';

// Mock SEO component
vi.mock('../components/SEO', () => ({
  SEO: () => null,
}));

// Mock API
vi.mock('@ai-resume/shared/api', () => ({
  api: {
    template: {
      getTemplates: vi.fn(() => Promise.resolve({ data: [], total: 0 })),
      favoriteTemplate: vi.fn(),
      unfavoriteTemplate: vi.fn(),
    },
    resume: {
      createResume: vi.fn(() => Promise.resolve({ id: 1 })),
    },
  },
}));

// Mock window.alert
Object.defineProperty(window, 'alert', {
  value: vi.fn(),
  writable: true,
});

// Mock window.location
Object.defineProperty(window, 'location', {
  value: { href: '' },
  writable: true,
});

describe('TemplatesPage', () => {
  let queryClient: QueryClient;

  const createWrapper = () => {
    queryClient = new QueryClient({
      defaultOptions: {
        queries: {
          retry: false,
        },
      },
    });

    return ({ children }: { children: React.ReactNode }) => (
      <QueryClientProvider client={queryClient}>
        <MemoryRouter future={{ v7_startTransition: true, v7_relativeSplatPath: true }}>
          {children}
        </MemoryRouter>
      </QueryClientProvider>
    );
  };

  it('渲染模板库页面', () => {
    const Wrapper = createWrapper();
    render(<TemplatesPage />, { wrapper: Wrapper });

    expect(screen.getByText(/免费简历模板/)).toBeInTheDocument();
  });

  it('有导航链接', () => {
    const Wrapper = createWrapper();
    render(<TemplatesPage />, { wrapper: Wrapper });

    expect(screen.getByText('AI 简历')).toBeInTheDocument();
    expect(screen.getByText('我的简历')).toBeInTheDocument();
    expect(screen.getByText('个人中心')).toBeInTheDocument();
  });

  it('有搜索框', () => {
    const Wrapper = createWrapper();
    render(<TemplatesPage />, { wrapper: Wrapper });

    const searchInput = screen.getByPlaceholderText('搜索模板...');
    expect(searchInput).toBeInTheDocument();
  });

  it('显示分类筛选', () => {
    const Wrapper = createWrapper();
    const { container } = render(<TemplatesPage />, { wrapper: Wrapper });

    // 检查页面中包含筛选相关的文本
    expect(container.textContent).toContain('互联网');
    expect(container.textContent).toContain('金融');
    expect(container.textContent).toContain('教育');
  });
});
