/**
 * ResumeListPage 组件测试
 */
import { describe, it, expect, vi } from 'vitest';
import { render, screen } from '@testing-library/react';
import '@testing-library/jest-dom';
import { MemoryRouter } from 'react-router-dom';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import ResumeListPage from './ResumeListPage';

// Mock SEO component
vi.mock('../components/SEO', () => ({
  SEO: () => null,
}));

// Mock Skeleton component
vi.mock('../components/ui/Skeleton', () => ({
  ResumeListSkeleton: ({ count = 6 }: { count?: number }) => (
    <div data-testid="skeleton-loading">
      {Array.from({ length: count }).map((_, i) => (
        <div key={i} style={{ margin: '10px', padding: '20px', background: '#f0f0f0' }}>
          ⏳ 加载中...
        </div>
      ))}
    </div>
  ),
}));

// Mock API
vi.mock('@ai-resume/shared/api', () => ({
  api: {
    resume: {
      getResumes: vi.fn(() => Promise.resolve({ data: [], total: 0 })),
      deleteResume: vi.fn(),
      getPdfExportUrl: vi.fn((id: number) => `/api/resumes/${id}/pdf`),
      getWordExportUrl: vi.fn((id: number) => `/api/resumes/${id}/word`),
      getHtmlExportUrl: vi.fn((id: number) => `/api/resumes/${id}/html`),
    },
  },
}));

// Mock window.open
Object.defineProperty(window, 'open', {
  value: vi.fn(),
  writable: true,
});

// Mock window.confirm
Object.defineProperty(window, 'confirm', {
  value: vi.fn(() => true),
  writable: true,
});

// Mock window.alert
Object.defineProperty(window, 'alert', {
  value: vi.fn(),
  writable: true,
});

describe('ResumeListPage', () => {
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

  it('渲染简历列表页面', () => {
    const Wrapper = createWrapper();
    render(<ResumeListPage />, { wrapper: Wrapper });

    expect(screen.getByText('我的简历')).toBeInTheDocument();
    expect(screen.getByText('新建简历')).toBeInTheDocument();
  });

  it('显示加载状态', () => {
    const Wrapper = createWrapper();
    render(<ResumeListPage />, { wrapper: Wrapper });

    // 骨架屏应该存在
    expect(screen.getAllByText(/⏳/)).toBeTruthy();
  });

  it('显示筛选按钮', () => {
    const Wrapper = createWrapper();
    render(<ResumeListPage />, { wrapper: Wrapper });

    expect(screen.getByText('全部')).toBeInTheDocument();
    expect(screen.getByText('草稿')).toBeInTheDocument();
    expect(screen.getByText('已发布')).toBeInTheDocument();
    expect(screen.getByText('已归档')).toBeInTheDocument();
  });

  it('有导航链接', () => {
    const Wrapper = createWrapper();
    render(<ResumeListPage />, { wrapper: Wrapper });

    expect(screen.getByText('AI 简历')).toBeInTheDocument();
    expect(screen.getByText('模板库')).toBeInTheDocument();
    expect(screen.getByText('个人中心')).toBeInTheDocument();
  });
});
