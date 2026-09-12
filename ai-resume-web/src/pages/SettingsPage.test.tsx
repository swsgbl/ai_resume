/**
 * SettingsPage 组件测试 — 多厂商路由版
 */
import { describe, it, expect, vi, beforeEach } from 'vitest';
import { render, screen, fireEvent } from '@testing-library/react';
import '@testing-library/jest-dom';
import { MemoryRouter } from 'react-router-dom';
import SettingsPage from './SettingsPage';

// Mock @ai-resume/shared
vi.mock('@ai-resume/shared', () => ({
  storage: {
    getBaseURL: vi.fn(() => '/api/v1'),
    setBaseURL: vi.fn(),
    getAIProvider: vi.fn(() => 'openai'),
    setAIProvider: vi.fn(),
    getOpenAIApiKey: vi.fn(() => ''),
    setOpenAIApiKey: vi.fn(),
    getOpenAIModel: vi.fn(() => 'gpt-4'),
    setOpenAIModel: vi.fn(),
    getDeepSeekApiKey: vi.fn(() => ''),
    setDeepSeekApiKey: vi.fn(),
    getDeepSeekModel: vi.fn(() => 'deepseek-chat'),
    setDeepSeekModel: vi.fn(),
    getXiaomiApiKey: vi.fn(() => ''),
    setXiaomiApiKey: vi.fn(),
    getXiaomiModel: vi.fn(() => 'MiMo-V2-Flash'),
    setXiaomiModel: vi.fn(),
    clearAll: vi.fn(),
  },
}));

vi.mock('@ai-resume/shared/api', () => ({
  getApiClient: vi.fn(() => ({
    setBaseURL: vi.fn(),
  })),
}));

vi.mock('../agent/ModelConfigCard', () => ({
  default: () => <div data-testid="model-config-card">ModelConfigCard</div>,
}));

// SEO 用 react-helmet-async(需 Provider),测试与其他页面一致直接 mock
vi.mock('../components/SEO', () => ({
  SEO: () => null,
}));

// 真实 Orb 依赖 gsap matchMedia,jsdom 下不可用 — 与其他页面测试一致进行 mock
vi.mock('../components/UIComponents', () => ({
  GradientText: ({ children }: { children: React.ReactNode }) => <span>{children}</span>,
  Orb: () => null,
}));

Object.defineProperty(window, 'confirm', { value: vi.fn(() => true), writable: true });
Object.defineProperty(window, 'location', {
  value: { href: '', reload: vi.fn() },
  writable: true,
});

describe('SettingsPage', () => {
  beforeEach(() => {
    vi.clearAllMocks();
    localStorage.clear();
  });

  const renderPage = () =>
    render(
      <MemoryRouter future={{ v7_startTransition: true, v7_relativeSplatPath: true }}>
        <SettingsPage />
      </MemoryRouter>
    );

  it('渲染设置页与新页头', () => {
    renderPage();
    expect(screen.getByText('设置')).toBeInTheDocument();
    expect(screen.getByText('所有配置仅保存在这台设备的浏览器里,不会上传服务器')).toBeInTheDocument();
  });

  it('渲染三个功能分区', () => {
    renderPage();
    expect(screen.getByTestId('section-models')).toBeInTheDocument();
    expect(screen.getByTestId('section-server')).toBeInTheDocument();
    expect(screen.getByTestId('section-privacy')).toBeInTheDocument();
  });

  it('AI 模型分区包含多厂商配置组件与车间入口', () => {
    renderPage();
    expect(screen.getByTestId('model-config-card')).toBeInTheDocument();
    expect(screen.getByText('去车间使用 →')).toBeInTheDocument();
  });

  it('服务器地址显示默认值并带「默认」徽章,无修改时保存禁用', () => {
    renderPage();
    expect(screen.getByTestId('server-url-input')).toHaveValue('/api/v1');
    expect(screen.getByText('默认')).toBeInTheDocument();
    expect(screen.getByTestId('save-url-button')).toBeDisabled();
  });

  it('修改地址后可保存且调用 storage', async () => {
    const { storage } = await import('@ai-resume/shared');
    renderPage();

    fireEvent.change(screen.getByTestId('server-url-input'), {
      target: { value: 'https://api.example.com/api/v1' },
    });
    expect(screen.getByTestId('save-url-button')).toBeEnabled();
    fireEvent.click(screen.getByTestId('save-url-button'));

    expect(storage.setBaseURL).toHaveBeenCalledWith('https://api.example.com/api/v1');
    expect(await screen.findByTestId('url-message')).toHaveTextContent('已保存,立即生效');
    expect(screen.getByText('自定义')).toBeInTheDocument();
  });

  it('非法地址被拒绝保存', async () => {
    const { storage } = await import('@ai-resume/shared');
    renderPage();

    fireEvent.change(screen.getByTestId('server-url-input'), { target: { value: 'not-a-url' } });
    fireEvent.click(screen.getByTestId('save-url-button'));

    expect(storage.setBaseURL).not.toHaveBeenCalled();
    expect(await screen.findByTestId('url-message')).toHaveTextContent('地址格式不对');
  });

  it('自定义地址可恢复默认', async () => {
    const { storage } = await import('@ai-resume/shared');
    vi.mocked(storage.getBaseURL).mockReturnValue('https://custom.example.com/api/v1');
    renderPage();

    const resetBtn = screen.getByTestId('reset-url-button');
    expect(resetBtn).toBeInTheDocument();
    fireEvent.click(resetBtn);

    expect(storage.setBaseURL).toHaveBeenCalledWith('/api/v1');
    expect(await screen.findByTestId('url-message')).toHaveTextContent('已恢复默认地址');
  });

  it('清除配置需确认并重载页面', async () => {
    const { storage } = await import('@ai-resume/shared');
    renderPage();

    fireEvent.click(screen.getByTestId('clear-all-button'));
    expect(storage.clearAll).toHaveBeenCalled();
    expect(window.location.reload).toHaveBeenCalled();
  });
});
