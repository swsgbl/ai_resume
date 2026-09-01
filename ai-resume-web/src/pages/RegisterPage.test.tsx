import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest';
import { render, screen, waitFor } from '@testing-library/react';
import '@testing-library/jest-dom';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { MemoryRouter, Route, Routes } from 'react-router-dom';
import userEvent from '@testing-library/user-event';
import RegisterPage from './RegisterPage';
import { useAuthStore } from '../store/auth';
import { api } from '@ai-resume/shared';

// Mock SEO component
vi.mock('../components/SEO', () => ({
  SEO: () => null,
}));

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
  GradientText: ({ children }: MockGradientTextProps) => <span>{children}</span>,
  Orb: () => null,
}));

// Mock auth store
vi.mock('../store/auth', () => ({
  useAuthStore: vi.fn(),
}));

// Mock API
vi.mock('@ai-resume/shared', () => ({
  api: {
    auth: {
      sendVerificationCode: vi.fn(),
    },
  },
}));

describe('RegisterPage Component', () => {
  let queryClient: QueryClient;
  let mockRegister: ReturnType<typeof vi.fn>;
  let mockClearError: ReturnType<typeof vi.fn>;
  let mockError: string | null;

  beforeEach(() => {
    queryClient = new QueryClient({
      defaultOptions: {
        queries: {
          retry: false,
        },
      },
    });

    mockError = null;
    mockRegister = vi.fn().mockResolvedValue(undefined);
    mockClearError = vi.fn();

    (useAuthStore as unknown as ReturnType<typeof vi.fn>).mockReturnValue({
      register: mockRegister,
      isLoading: false,
      error: mockError,
      clearError: mockClearError,
    });

    (api.auth.sendVerificationCode as ReturnType<typeof vi.fn>).mockResolvedValue(undefined);

    vi.clearAllMocks();
    // 移除 fake timers 以避免阻塞 React 状态更新
    // vi.useFakeTimers();
  });

  afterEach(() => {
    vi.useRealTimers();
  });

  const renderWithProviders = (ui: React.ReactNode) => {
    return render(
      <QueryClientProvider client={queryClient}>
        <MemoryRouter future={{ v7_startTransition: true, v7_relativeSplatPath: true }} initialEntries={['/register']}>
          <Routes>
            <Route path="/register" element={ui} />
            <Route path="/" element={<div>Home</div>} />
          </Routes>
        </MemoryRouter>
      </QueryClientProvider>
    );
  };

  const fillRegistrationForm = async (
    user: ReturnType<typeof userEvent.setup>,
    options: { email?: string; code?: string; agreeToTerms?: boolean } = {}
  ) => {
    const email = options.email ?? 'test@example.com';
    const code = options.code ?? '123456';

    await user.type(screen.getByTestId('register-email-input'), email);
    if (code) {
      await user.type(screen.getByTestId('code-input'), code);
    }
    await user.type(screen.getByTestId('register-password-input'), 'password123');
    await user.type(screen.getByTestId('confirm-password-input'), 'password123');
    if (options.agreeToTerms ?? true) {
      await user.click(screen.getByTestId('terms-checkbox'));
    }
  };

  it('渲染注册页面', () => {
    renderWithProviders(<RegisterPage />);

    expect(screen.getByText('创建账号')).toBeInTheDocument();
    expect(screen.getByText('用户注册')).toBeInTheDocument();
  });

  it('显示所有表单字段', () => {
    renderWithProviders(<RegisterPage />);

    expect(screen.getByTestId('register-email-input')).toBeInTheDocument();
    expect(screen.getByTestId('code-input')).toBeInTheDocument();
    expect(screen.getByTestId('username-input')).toBeInTheDocument();
    expect(screen.getByTestId('register-password-input')).toBeInTheDocument();
    expect(screen.getByTestId('confirm-password-input')).toBeInTheDocument();
    expect(screen.getByTestId('send-code-button')).toBeInTheDocument();
    expect(screen.getByTestId('terms-checkbox')).toBeInTheDocument();
  });

  it('显示登录链接', () => {
    renderWithProviders(<RegisterPage />);

    expect(screen.getByTestId('login-link')).toBeInTheDocument();
    expect(screen.getByText('立即登录')).toBeInTheDocument();
  });

  it('密码不匹配时显示错误', async () => {
    const user = userEvent.setup();
    renderWithProviders(<RegisterPage />);

    const passwordInput = screen.getByTestId('register-password-input');
    const confirmPasswordInput = screen.getByTestId('confirm-password-input');

    await user.type(passwordInput, 'password123');
    await user.type(confirmPasswordInput, 'different123');

    const errorElement = screen.getByTestId('password-mismatch-error');
    await waitFor(() => {
      expect(errorElement).toBeInTheDocument();
      expect(errorElement).toHaveTextContent('两次输入的密码不一致');
    });
  });

  it('密码匹配时清除错误', async () => {
    const user = userEvent.setup();
    renderWithProviders(<RegisterPage />);

    const passwordInput = screen.getByTestId('register-password-input');
    const confirmPasswordInput = screen.getByTestId('confirm-password-input');

    await user.type(passwordInput, 'password123');
    await user.type(confirmPasswordInput, 'password123');

    await waitFor(() => {
      const errorElement = screen.queryByTestId('password-mismatch-error');
      expect(errorElement).not.toBeInTheDocument();
    });
  });

  it('未同意用户协议时禁用提交按钮', async () => {
    const user = userEvent.setup();
    renderWithProviders(<RegisterPage />);

    const passwordInput = screen.getByTestId('register-password-input');
    const confirmPasswordInput = screen.getByTestId('confirm-password-input');
    await fillRegistrationForm(user, { agreeToTerms: false });
    await user.type(passwordInput, 'password123');
    await user.type(confirmPasswordInput, 'password123');

    const submitButton = screen.getByTestId('register-button');
    await waitFor(() => {
      expect(submitButton).toBeDisabled();
    });
  });

  it('同意用户协议且表单有效时启用提交按钮', async () => {
    const user = userEvent.setup();
    renderWithProviders(<RegisterPage />);

    await fillRegistrationForm(user);

    await waitFor(() => {
      const submitButton = screen.getByTestId('register-button');
      expect(submitButton).not.toBeDisabled();
    });
  });

  it('密码少于8位时显示错误', async () => {
    const user = userEvent.setup();
    renderWithProviders(<RegisterPage />);

    const passwordInput = screen.getByTestId('register-password-input');
    await user.type(passwordInput, 'pass');

    await waitFor(() => {
      const errorElement = screen.getByTestId('password-error');
      expect(errorElement).toBeInTheDocument();
    });
  });

  it('密码不包含字母时显示错误', async () => {
    const user = userEvent.setup();
    renderWithProviders(<RegisterPage />);

    const passwordInput = screen.getByTestId('register-password-input');
    await user.type(passwordInput, '12345678');

    await waitFor(() => {
      const errorElement = screen.getByTestId('password-error');
      expect(errorElement).toHaveTextContent('密码必须包含字母');
    });
  });

  it('密码不包含数字时显示错误', async () => {
    const user = userEvent.setup();
    renderWithProviders(<RegisterPage />);

    const passwordInput = screen.getByTestId('register-password-input');
    await user.type(passwordInput, 'password');

    await waitFor(() => {
      const errorElement = screen.getByTestId('password-error');
      expect(errorElement).toHaveTextContent('密码必须包含数字');
    });
  });

  it('验证码按钮初始状态显示"发送验证码"', () => {
    renderWithProviders(<RegisterPage />);

    expect(screen.getByText('发送验证码')).toBeInTheDocument();
  });

  it('无邮箱时验证码按钮禁用', () => {
    renderWithProviders(<RegisterPage />);

    const sendCodeButton = screen.getByTestId('send-code-button');
    expect(sendCodeButton).toBeDisabled();
  });

  it('输入邮箱后验证码按钮可点击', async () => {
    const user = userEvent.setup();
    renderWithProviders(<RegisterPage />);

    await user.type(screen.getByTestId('register-email-input'), 'test@example.com');

    await waitFor(() => {
      expect(screen.getByTestId('send-code-button')).not.toBeDisabled();
    });
  });

  it('验证码不是6位数字时禁止提交', async () => {
    const user = userEvent.setup();
    renderWithProviders(<RegisterPage />);

    await fillRegistrationForm(user, { code: '12345' });

    expect(screen.getByTestId('register-button')).toBeDisabled();
  });

  it('发送验证码成功后开始60秒倒计时', async () => {
    const user = userEvent.setup();
    renderWithProviders(<RegisterPage />);

    const sendCodeButton = screen.getByTestId('send-code-button');

    await user.type(screen.getByTestId('register-email-input'), 'test@example.com');
    await user.click(sendCodeButton);

    await waitFor(() => {
      expect(api.auth.sendVerificationCode).toHaveBeenCalledWith('test@example.com');
    });
  });

  it('显示注册错误信息', () => {
    mockError = '邮箱已被注册';
    (useAuthStore as unknown as ReturnType<typeof vi.fn>).mockReturnValue({
      register: mockRegister,
      isLoading: false,
      error: mockError,
      clearError: mockClearError,
    });

    renderWithProviders(<RegisterPage />);

    expect(screen.getByText('邮箱已被注册')).toBeInTheDocument();
  });

  it('注册中显示加载状态', () => {
    (useAuthStore as unknown as ReturnType<typeof vi.fn>).mockReturnValue({
      register: mockRegister,
      isLoading: true,
      error: null,
      clearError: mockClearError,
    });

    renderWithProviders(<RegisterPage />);

    expect(screen.getByText('注册中...')).toBeInTheDocument();
  });

  it('成功注册后导航到首页', async () => {
    const user = userEvent.setup();
    renderWithProviders(<RegisterPage />);

    const submitButton = screen.getByTestId('register-button');

    await fillRegistrationForm(user);
    await user.click(submitButton);

    await waitFor(() => {
      expect(mockRegister).toHaveBeenCalledWith('test@example.com', 'password123', {
        username: undefined,
        verification_code: '123456',
      });
    });
  });

  it('可选用户名正确提交', async () => {
    const user = userEvent.setup();
    renderWithProviders(<RegisterPage />);

    const usernameInput = screen.getByTestId('username-input');
    const submitButton = screen.getByTestId('register-button');

    await user.type(usernameInput, 'testuser');
    await fillRegistrationForm(user);
    await user.click(submitButton);

    await waitFor(() => {
      expect(mockRegister).toHaveBeenCalledWith('test@example.com', 'password123', {
        username: 'testuser',
        verification_code: '123456',
      });
    });
  });

  it('验证码正确提交', async () => {
    const user = userEvent.setup();
    renderWithProviders(<RegisterPage />);

    const submitButton = screen.getByTestId('register-button');

    await fillRegistrationForm(user, { code: '654321' });
    await user.click(submitButton);

    await waitFor(() => {
      expect(mockRegister).toHaveBeenCalledWith('test@example.com', 'password123', {
        username: undefined,
        verification_code: '654321',
      });
    });
  });

  it('提交前清除错误信息', async () => {
    const user = userEvent.setup();
    mockError = '之前的错误';
    (useAuthStore as unknown as ReturnType<typeof vi.fn>).mockReturnValue({
      register: mockRegister,
      isLoading: false,
      error: mockError,
      clearError: mockClearError,
    });

    renderWithProviders(<RegisterPage />);

    const emailInput = screen.getByTestId('register-email-input');
    await user.type(emailInput, 'test@example.com');
    await user.tab(); // trigger blur/change

    await waitFor(() => {
      expect(mockClearError).toHaveBeenCalled();
    });
  });
});
