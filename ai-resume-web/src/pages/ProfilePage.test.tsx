/**
 * ProfilePage 组件测试
 */
import { describe, it, expect, vi } from 'vitest';
import { render, screen } from '@testing-library/react';
import '@testing-library/jest-dom';
import { MemoryRouter } from 'react-router-dom';
import ProfilePage from './ProfilePage';

// Mock auth store
vi.mock('../store/auth', () => ({
  useAuthStore: vi.fn(() => ({
    user: {
      email: 'test@example.com',
      nickname: '测试用户',
      role: 'free',
    },
    logout: vi.fn(),
  })),
}));

// Mock window.confirm
Object.defineProperty(window, 'confirm', {
  value: vi.fn(() => true),
  writable: true,
});

// Mock window.location
Object.defineProperty(window, 'location', {
  value: { href: '' },
  writable: true,
});

describe('ProfilePage', () => {
  it('渲染个人中心页面', () => {
    render(
      <MemoryRouter future={{ v7_startTransition: true, v7_relativeSplatPath: true }}>
        <ProfilePage />
      </MemoryRouter>
    );

    expect(screen.getByText('个人中心')).toBeInTheDocument();
  });

  it('显示用户信息', () => {
    render(
      <MemoryRouter future={{ v7_startTransition: true, v7_relativeSplatPath: true }}>
        <ProfilePage />
      </MemoryRouter>
    );

    expect(screen.getByText('测试用户')).toBeInTheDocument();
    expect(screen.getByText('test@example.com')).toBeInTheDocument();
    expect(screen.getByText('免费版')).toBeInTheDocument();
  });

  it('显示会员升级卡片', () => {
    render(
      <MemoryRouter future={{ v7_startTransition: true, v7_relativeSplatPath: true }}>
        <ProfilePage />
      </MemoryRouter>
    );

    expect(screen.getByText('升级专业版')).toBeInTheDocument();
    expect(screen.getByText('立即升级')).toBeInTheDocument();
  });

  it('显示功能菜单', () => {
    render(
      <MemoryRouter future={{ v7_startTransition: true, v7_relativeSplatPath: true }}>
        <ProfilePage />
      </MemoryRouter>
    );

    expect(screen.getAllByText('我的简历').length).toBeGreaterThan(0);
    expect(screen.getByText('我的收藏')).toBeInTheDocument();
    expect(screen.getByText('设置')).toBeInTheDocument();
    expect(screen.getByText('帮助与反馈')).toBeInTheDocument();
    expect(screen.getByText('关于我们')).toBeInTheDocument();
    expect(screen.getByText('退出登录')).toBeInTheDocument();
  });

  it('有导航链接', () => {
    const { container } = render(
      <MemoryRouter future={{ v7_startTransition: true, v7_relativeSplatPath: true }}>
        <ProfilePage />
      </MemoryRouter>
    );

    expect(screen.getByText('AI 简历')).toBeInTheDocument();
    // "我的简历" 和 "模板库" 在页面中多次出现，使用 getAllByText 或检查容器
    expect(container.textContent).toContain('模板库');
  });
});
