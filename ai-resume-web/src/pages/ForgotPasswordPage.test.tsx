/**
 * ForgotPasswordPage 组件测试
 */
import { describe, it, expect, vi } from 'vitest';
import { render, screen } from '@testing-library/react';
import '@testing-library/jest-dom';
import { MemoryRouter } from 'react-router-dom';
import ForgotPasswordPage from './ForgotPasswordPage';

// Mock UIComponents
interface MockButtonProps {
  children: React.ReactNode;
  loading?: boolean;
  disabled?: boolean;
  'data-testid'?: string;
  onClick?: () => void;
  type?: 'button' | 'submit' | 'reset';
}

interface MockInputProps {
  label?: string;
  'data-testid'?: string;
  type?: string;
  placeholder?: string;
  value?: string;
  required?: boolean;
}

interface MockGradientTextProps {
  children: React.ReactNode;
}

vi.mock('../components/UIComponents', () => ({
  Button: ({ children, loading, disabled, ...props }: MockButtonProps) => (
    <button {...props} disabled={disabled || loading} data-testid={props['data-testid']}>
      {children}
    </button>
  ),
  Input: ({ label, ...props }: MockInputProps) => (
    <div>
      {label && <label>{label}</label>}
      <input {...props} data-testid={props['data-testid']} />
    </div>
  ),
  GradientText: ({ children }: MockGradientTextProps) => <span className="gradient-text">{children}</span>,
  Orb: () => null,
}));

// Mock fetch
global.fetch = vi.fn(() =>
  Promise.resolve({
    ok: true,
    json: () => Promise.resolve({}),
  } as Response)
);

describe('ForgotPasswordPage', () => {
  // Increase timeout for all tests in this describe block
  vi.setConfig({ testTimeout: 10000 });
  it('渲染重置密码页面', () => {
    render(
      <MemoryRouter future={{ v7_startTransition: true, v7_relativeSplatPath: true }}>
        <ForgotPasswordPage />
      </MemoryRouter>
    );

    expect(screen.getByText('重置密码')).toBeInTheDocument();
  });

  it('默认显示邮箱输入步骤', () => {
    render(
      <MemoryRouter future={{ v7_startTransition: true, v7_relativeSplatPath: true }}>
        <ForgotPasswordPage />
      </MemoryRouter>
    );

    expect(screen.getByText('输入邮箱获取验证码')).toBeInTheDocument();
    expect(screen.getByText('邮箱地址')).toBeInTheDocument();
    expect(screen.getByText('发送验证码')).toBeInTheDocument();
  });

  it('显示返回登录链接', () => {
    render(
      <MemoryRouter future={{ v7_startTransition: true, v7_relativeSplatPath: true }}>
        <ForgotPasswordPage />
      </MemoryRouter>
    );

    expect(screen.getByText('返回登录')).toBeInTheDocument();
  });

  it('有进度指示器', () => {
    const { container } = render(
      <MemoryRouter future={{ v7_startTransition: true, v7_relativeSplatPath: true }}>
        <ForgotPasswordPage />
      </MemoryRouter>
    );

    // 应该有3个进度条div
    const progressBars = container.querySelectorAll('.rounded-full');
    expect(progressBars.length).toBe(3);
  });
});
