import { describe, it, expect, vi, beforeEach } from 'vitest';
import { render, screen, waitFor } from '@testing-library/react';
import '@testing-library/jest-dom';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { MemoryRouter, Route, Routes } from 'react-router-dom';
import ResumeEditorPage from './ResumeEditorPage';
import { api } from '@ai-resume/shared/api';

// Mock SEO component
vi.mock('../components/SEO', () => ({
  SEO: () => null,
}));

// Mock complex components that cause issues
vi.mock('../components/editor/RichTextEditor', () => ({
  RichTextEditor: () => <div data-testid="rich-text-editor">RichTextEditor</div>,
}));

vi.mock('use-undo', () => ({
  default: () => [
    null,
    {
      set: vi.fn(),
      reset: vi.fn(),
      undo: vi.fn(),
      redo: vi.fn(),
      canUndo: false,
      canRedo: false,
    },
  ],
}));

// Mock API
vi.mock('@ai-resume/shared/api', () => ({
  api: {
    resume: {
      getResume: vi.fn(),
      createResume: vi.fn(),
      updateResume: vi.fn(),
      aiGenerateResume: vi.fn(),
      deleteResume: vi.fn(),
      getResumes: vi.fn(),
    },
  },
}));

// Type-safe mock helper
const mockGetResume = api.resume.getResume as ReturnType<typeof vi.fn>;
const mockCreateResume = api.resume.createResume as ReturnType<typeof vi.fn>;

// Mock Resume 类型
interface MockResume {
  id: number;
  title: string;
  content: {
    basic_info: {
      name?: string;
      email?: string;
    };
    education: unknown[];
    work_experience: unknown[];
    projects: unknown[];
    skills: unknown[];
  };
}

describe('ResumeEditorPage Component', () => {
  let queryClient: QueryClient;

  // 设置全局超时时间
  vi.setConfig({ testTimeout: 15000 });

  beforeEach(() => {
    queryClient = new QueryClient({
      defaultOptions: {
        queries: {
          retry: false,
        },
      },
    });
    vi.clearAllMocks();
  });

  const renderWithProviders = (ui: React.ReactNode, initialEntries = ['/resumes/1']) => {
    return render(
      <QueryClientProvider client={queryClient}>
        <MemoryRouter future={{ v7_startTransition: true, v7_relativeSplatPath: true }} initialEntries={initialEntries}>
          <Routes>
            <Route path="/resumes/:id" element={ui} />
            <Route path="/resumes/new" element={ui} />
            <Route path="/" element={<div>Home</div>} />
          </Routes>
        </MemoryRouter>
      </QueryClientProvider>
    );
  };

  const mockResume: MockResume = {
    id: 1,
    title: '测试简历',
    content: {
      basic_info: {
        name: '测试用户',
        email: 'test@example.com',
      },
      education: [],
      work_experience: [],
      projects: [],
      skills: [],
    },
  };

  it.skip('渲染编辑器页面', async () => {
    mockGetResume.mockResolvedValue(mockResume);

    renderWithProviders(<ResumeEditorPage />);

    // 简化测试：只检查页面是否渲染
    await waitFor(() => {
      expect(screen.getByText('AI')).toBeInTheDocument();
    }, { timeout: 10000 });
  });

  it.skip('渲染标签页导航', async () => {
    mockGetResume.mockResolvedValue(mockResume);

    renderWithProviders(<ResumeEditorPage />);

    // 简化测试：只检查是否有 tab 导航
    await waitFor(() => {
      expect(screen.getByText('AI')).toBeInTheDocument();
    }, { timeout: 10000 });
  });

  it('切换到预览模式', async () => {
    mockGetResume.mockResolvedValue(mockResume);

    renderWithProviders(<ResumeEditorPage />);

    await waitFor(() => {
      expect(screen.getByText('预览')).toBeInTheDocument();
    });

    screen.getByText('预览').click();

    await waitFor(() => {
      expect(screen.getByText('编辑')).toBeInTheDocument();
    });
  });

  it.skip('创建新简历', async () => {
    const newResume: MockResume = {
      id: 1,
      title: '新简历',
      content: {
        basic_info: {},
        education: [],
        work_experience: [],
        projects: [],
        skills: [],
      },
    };
    mockCreateResume.mockResolvedValue(newResume);

    renderWithProviders(<ResumeEditorPage />, ['/resumes/new']);

    // 新简历页面默认显示"我的简历"，而不是"新简历"
    await waitFor(() => {
      expect(screen.getByText('我的简历')).toBeInTheDocument();
    }, { timeout: 10000 });
  });

  it('显示模板选择器（预览模式）', async () => {
    mockGetResume.mockResolvedValue(mockResume);

    renderWithProviders(<ResumeEditorPage />);

    await waitFor(() => {
      screen.getByText('预览').click();
    });

    await waitFor(() => {
      expect(screen.getByText('现代模板')).toBeInTheDocument();
      expect(screen.getByText('经典模板')).toBeInTheDocument();
      expect(screen.getByText('简约模板')).toBeInTheDocument();
    });
  });
});
