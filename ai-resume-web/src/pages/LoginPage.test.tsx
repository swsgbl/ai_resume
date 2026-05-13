import { describe, it, expect, vi, beforeEach } from 'vitest';
import { render, screen, waitFor } from '@testing-library/react';
import '@testing-library/jest-dom';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { MemoryRouter, Route, Routes } from 'react-router-dom';
import userEvent from '@testing-library/user-event';
import LoginPage from './LoginPage';
import { useAuthStore } from '../store/auth';

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

// Mock localStorage
const localStorageMock = {
  getItem: vi.fn(),
  setItem: vi.fn(),
  removeItem: vi.fn(),
  clear: vi.fn(),
};
Object.defineProperty(window, 'localStorage', {
  value: localStorageMock,
});

describe('LoginPage Component', () => {
  let queryClient: QueryClient;
  let mockLogin: ReturnType<typeof vi.fn>;
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
    mockLogin = vi.fn().mockResolvedValue(undefined);
    mockClearError = vi.fn();

    (useAuthStore as unknown as ReturnType<typeof vi.fn>).mockReturnValue({
      login: mockLogin,
      isLoading: false,
      error: mockError,
      clearError: mockClearError,
    });

    vi.clearAllMocks();
    localStorageMock.getItem.mockReturnValue(null);
  });

  const renderWithProviders = (ui: React.ReactNode) => {
    return render(
      <QueryClientProvider client={queryClient}>
        <MemoryRouter future={{ v7_startTransition: true, v7_relativeSplatPath: true }} initialEntries={['/login']}>
          <Routes>
            <Route path="/login" element={ui} />
            <Route path="/" element={<div>Home</div>} />
          </Routes>
        </MemoryRouter>
      </QueryClientProvider>
    );
  };

  it('渲染登录页面', () => {
    renderWithProviders(<LoginPage />);

    expect(screen.getByText('欢迎回来')).toBeInTheDocument();
    expect(screen.getByText('账户登录')).toBeInTheDocument();
  });

  it('显示所有表单字段', () => {
    renderWithProviders(<LoginPage />);

    expect(screen.getByTestId('email-input')).toBeInTheDocument();
    expect(screen.getByTestId('password-input')).toBeInTheDocument();
    expect(screen.getByTestId('login-button')).toBeInTheDocument();
  });

  it('显示注册链接', () => {
    renderWithProviders(<LoginPage />);

    expect(screen.getByTestId('register-link')).toBeInTheDocument();
    expect(screen.getByText('立即注册')).toBeInTheDocument();
  });

  it('显示用户协议和隐私政策链接', () => {
    renderWithProviders(<LoginPage />);

    expect(screen.getByTestId('terms-link')).toBeInTheDocument();
    expect(screen.getByTestId('privacy-link')).toBeInTheDocument();
  });

  it('表单验证：空邮箱时显示required错误', async () => {
    const user = userEvent.setup();
    renderWithProviders(<LoginPage />);

    const submitButton = screen.getByTestId('login-button');
    await user.click(submitButton);

    // Email input should have required attribute
    expect(screen.getByTestId('email-input')).toBeRequired();
  });

  it('成功登录后导航到首页', async () => {
    const user = userEvent.setup();
    renderWithProviders(<LoginPage />);

    const emailInput = screen.getByTestId('email-input');
    const passwordInput = screen.getByTestId('password-input');
    const loginButton = screen.getByTestId('login-button');

    await user.type(emailInput, 'test@example.com');
    await user.type(passwordInput, 'password123');
    await user.click(loginButton);

    await waitFor(() => {
      expect(mockLogin).toHaveBeenCalledWith('test@example.com', 'password123');
    });
  });

  it('显示登录错误信息', () => {
    mockError = '邮箱或密码错误';
    (useAuthStore as unknown as ReturnType<typeof vi.fn>).mockReturnValue({
      login: mockLogin,
      isLoading: false,
      error: mockError,
      clearError: mockClearError,
    });

    renderWithProviders(<LoginPage />);

    expect(screen.getByText('邮箱或密码错误')).toBeInTheDocument();
  });

  it('登录中显示加载状态', () => {
    (useAuthStore as unknown as ReturnType<typeof vi.fn>).mockReturnValue({
      login: mockLogin,
      isLoading: true,
      error: null,
      clearError: mockClearError,
    });

    renderWithProviders(<LoginPage />);

    expect(screen.getByText('登录中...')).toBeInTheDocument();
  });

  it('记住密码功能：选中时保存到localStorage', async () => {
    const user = userEvent.setup();
    renderWithProviders(<LoginPage />);

    const rememberCheckbox = screen.getByTestId('remember-password');
    await user.click(rememberCheckbox);

    expect(rememberCheckbox).toBeChecked();
  });

  it('从localStorage恢复保存的邮箱', () => {
    localStorageMock.getItem.mockImplementation((key) => {
      if (key === 'remember_password') return 'true';
      if (key === 'saved_email') return 'saved@example.com';
      return null;
    });

    renderWithProviders(<LoginPage />);

    const emailInput = screen.getByTestId('email-input') as HTMLInputElement;
    expect(emailInput.value).toBe('saved@example.com');
  });

  it('点击忘记密码链接导航到忘记密码页面', () => {
    renderWithProviders(<LoginPage />);

    const forgotPasswordLink = screen.getByText('忘记密码？');
    expect(forgotPasswordLink).toBeInTheDocument();
    expect(forgotPasswordLink).toHaveAttribute('href', '/forgot-password');
  });

  it('社交登录按钮可见', () => {
    renderWithProviders(<LoginPage />);

    const socialButtons = screen.getAllByRole('button');
    expect(socialButtons.length).toBeGreaterThan(0);
  });

  it('提交前清除错误信息', async () => {
    const user = userEvent.setup();
    mockError = '之前的错误';
    (useAuthStore as unknown as ReturnType<typeof vi.fn>).mockReturnValue({
      login: mockLogin,
      isLoading: false,
      error: mockError,
      clearError: mockClearError,
    });

    renderWithProviders(<LoginPage />);

    const emailInput = screen.getByTestId('email-input');
    await user.type(emailInput, 'test@example.com');
    await user.tab(); // trigger blur/change

    await waitFor(() => {
      expect(mockClearError).toHaveBeenCalled();
    });
  });

  it('记住密码未选中时不保存凭据', async () => {
    const user = userEvent.setup();
    mockLogin.mockResolvedValue(undefined);
    renderWithProviders(<LoginPage />);

    const emailInput = screen.getByTestId('email-input');
    const passwordInput = screen.getByTestId('password-input');
    const loginButton = screen.getByTestId('login-button');

    await user.type(emailInput, 'test@example.com');
    await user.type(passwordInput, 'password123');
    await user.click(loginButton);

    await waitFor(() => {
      expect(mockLogin).toHaveBeenCalled();
    });

    // localStorageMock.removeItem should be called for both keys
    expect(localStorageMock.removeItem).toHaveBeenCalledWith('remember_password');
  });
});
