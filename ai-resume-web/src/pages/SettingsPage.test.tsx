/**
 * SettingsPage 组件测试
 */
import { describe, it, expect, vi, beforeEach } from 'vitest';
import { render, screen } from '@testing-library/react';
import '@testing-library/jest-dom';
import { MemoryRouter } from 'react-router-dom';
import SettingsPage from './SettingsPage';

// Mock @ai-resume/shared
vi.mock('@ai-resume/shared', () => ({
  storage: {
    getBaseURL: vi.fn(() => 'http://127.0.0.1:8000/api/v1'),
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

// Mock window.confirm and window.location
Object.defineProperty(window, 'confirm', {
  value: vi.fn(() => true),
  writable: true,
});

Object.defineProperty(window, 'location', {
  value: { href: '', reload: vi.fn() },
  writable: true,
});

describe('SettingsPage', () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  it('渲染设置页面', () => {
    render(
      <MemoryRouter future={{ v7_startTransition: true, v7_relativeSplatPath: true }}>
        <SettingsPage />
      </MemoryRouter>
    );

    expect(screen.getByText('设置')).toBeInTheDocument();
  });

  it('显示服务器配置', () => {
    render(
      <MemoryRouter future={{ v7_startTransition: true, v7_relativeSplatPath: true }}>
        <SettingsPage />
      </MemoryRouter>
    );

    expect(screen.getByText('服务器配置')).toBeInTheDocument();
    expect(screen.getByText('后端服务器地址')).toBeInTheDocument();
  });

  it('显示 AI 提供商选择', () => {
    render(
      <MemoryRouter future={{ v7_startTransition: true, v7_relativeSplatPath: true }}>
        <SettingsPage />
      </MemoryRouter>
    );

    expect(screen.getByText('AI 模型配置')).toBeInTheDocument();
    expect(screen.getByText('选择 AI 提供商')).toBeInTheDocument();
    expect(screen.getByText('OpenAI')).toBeInTheDocument();
    expect(screen.getByText('DeepSeek')).toBeInTheDocument();
    expect(screen.getByText('小米AI')).toBeInTheDocument();
  });

  it('默认显示 OpenAI 配置', () => {
    render(
      <MemoryRouter future={{ v7_startTransition: true, v7_relativeSplatPath: true }}>
        <SettingsPage />
      </MemoryRouter>
    );

    expect(screen.getByText('OpenAI 配置')).toBeInTheDocument();
    expect(screen.getByText('API 密钥')).toBeInTheDocument();
    expect(screen.getByText('模型')).toBeInTheDocument();
  });

  it('有导航链接', () => {
    render(
      <MemoryRouter future={{ v7_startTransition: true, v7_relativeSplatPath: true }}>
        <SettingsPage />
      </MemoryRouter>
    );

    expect(screen.getByText('AI 简历')).toBeInTheDocument();
    expect(screen.getByText('我的简历')).toBeInTheDocument();
    expect(screen.getByText('模板库')).toBeInTheDocument();
  });

  it('显示操作按钮', () => {
    render(
      <MemoryRouter future={{ v7_startTransition: true, v7_relativeSplatPath: true }}>
        <SettingsPage />
      </MemoryRouter>
    );

    expect(screen.getByText('保存配置')).toBeInTheDocument();
    expect(screen.getByText('清除配置')).toBeInTheDocument();
  });

  it('显示其他设置链接', () => {
    render(
      <MemoryRouter future={{ v7_startTransition: true, v7_relativeSplatPath: true }}>
        <SettingsPage />
      </MemoryRouter>
    );

    expect(screen.getByText('关于')).toBeInTheDocument();
    expect(screen.getByText('帮助')).toBeInTheDocument();
    expect(screen.getByText('隐私政策')).toBeInTheDocument();
  });
});
