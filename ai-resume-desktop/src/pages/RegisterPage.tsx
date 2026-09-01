import { useState, useEffect, useCallback } from 'react';
import { Link, useNavigate } from 'react-router-dom';
import { useAuthStore } from '../store/auth';
import { Button, Input, GradientText, Orb } from '../components/UIComponents';
import { api } from '@ai-resume/shared';

// 常量配置 - 组织为配置对象便于维护
const VALIDATION_CONFIG = {
  PASSWORD: {
    MIN_LENGTH: 8,
  },
  VERIFICATION_CODE: {
    COUNTDOWN_SECONDS: 60,
  },
} as const;

export default function RegisterPage() {
  const navigate = useNavigate();
  const { register, isLoading, error, clearError } = useAuthStore();
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [confirmPassword, setConfirmPassword] = useState('');
  const [username, setUsername] = useState('');
  const [verificationCode, setVerificationCode] = useState('');
  const [countdown, setCountdown] = useState(0);
  const [agreedToTerms, setAgreedToTerms] = useState(false);
  const [passwordError, setPasswordError] = useState<string | null>(null);
  const [passwordMismatchError, setPasswordMismatchError] = useState<string | null>(null);
  const [codeSending, setCodeSending] = useState(false);

  const validatePassword = useCallback((): string | null => {
    if (password.length < VALIDATION_CONFIG.PASSWORD.MIN_LENGTH) return `密码长度至少${VALIDATION_CONFIG.PASSWORD.MIN_LENGTH}位`;
    if (!/[A-Za-z]/.test(password)) return '密码必须包含字母';
    if (!/\d/.test(password)) return '密码必须包含数字';
    return null;
  }, [password]);

  // 修复内存泄漏：使用useEffect管理倒计时
  useEffect(() => {
    if (countdown > 0) {
      const timer = setInterval(() => {
        setCountdown(prev => prev - 1);
      }, 1000);
      return () => clearInterval(timer);
    }
  }, [countdown]);

  const handleSendCode = async () => {
    if (!email || countdown > 0) return;

    try {
      setCodeSending(true);
      await api.auth.sendVerificationCode(email);
      setCountdown(VALIDATION_CONFIG.VERIFICATION_CODE.COUNTDOWN_SECONDS);
    } catch (error) {
      const message = error instanceof Error ? error.message : '发送验证码失败，请稍后重试';
      setPasswordMismatchError(message);
      // API失败时也设置短暂冷却时间，避免频繁点击
      setCountdown(5);
    } finally {
      setCodeSending(false);
    }
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    clearError();
    setPasswordMismatchError(null);

    // 修复：添加密码不匹配的错误提示
    if (password !== confirmPassword) {
      setPasswordMismatchError('两次输入的密码不一致');
      return;
    }

    const validationError = validatePassword();
    if (validationError) {
      setPasswordError(validationError);
      return;
    }

    setPasswordError(null);

    try {
      await register(email, password, {
        username: username || undefined,
        verification_code: verificationCode || undefined,
      });
      navigate('/');
    } catch {
      // Error handled by store
    }
  };

  const canSubmit = password === confirmPassword &&
    password.length > 0 &&
    agreedToTerms &&
    !isLoading;

  const isPasswordValid = password.length === 0 || validatePassword() === null;

  return (
    <div className="min-h-screen relative overflow-x-hidden flex flex-col justify-center bg-slate-950">
      {/* Background Orbs - 桌面端优化 */}
      <div className="fixed inset-0 pointer-events-none overflow-hidden">
        <Orb color="primary" size={400} className="top-0 left-0 -translate-x-1/2 -translate-y-1/2 opacity-20" />
        <Orb color="accent" size={300} className="bottom-0 right-0 translate-x-1/2 translate-y-1/2 opacity-10" />
      </div>

      {/* Background Grid */}
      <div className="fixed inset-0 bg-grid pointer-events-none opacity-5" />

      {/* Main Content */}
      <div className="relative z-10 w-full max-w-md mx-auto px-4 py-12">
        <div className="w-full">
          {/* Logo & Title */}
          <div className="text-center mb-8 animate-fade-in">
            <Link to="/" className="inline-flex items-center justify-center gap-3 mb-6">
              <div className="w-16 h-16 rounded-2xl bg-gradient-to-br from-sky-400 to-accent-500 flex items-center justify-center shadow-neon-blue animate-pulse-glow">
                <svg className="w-10 h-10 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z" />
                </svg>
              </div>
            </Link>

            <h1 className="text-3xl font-bold mb-2">
              <GradientText>创建账号</GradientText>
            </h1>
            <p className="text-slate-400">创建账号，开启智能简历之旅</p>
          </div>

          {/* Register Form Card */}
          <div className="card-glass animate-scale-in">
            <div className="mb-8">
              <h2 className="text-xl font-semibold text-white mb-1">用户注册</h2>
              <p className="text-slate-400 text-sm">填写信息创建新账户</p>
            </div>

            {error && (
              <div className="mb-6 p-4 rounded-xl bg-rose-500/10 border border-rose-500/50 text-rose-400 text-sm flex items-start gap-3 animate-shimmer">
                <svg className="w-5 h-5 flex-shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 8v4m0 4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
                </svg>
                <span>{error}</span>
              </div>
            )}

            <form onSubmit={handleSubmit} className="space-y-5">
              <Input
                id="register-email-input"
                label="邮箱地址"
                type="email"
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                placeholder="your@email.com"
                required
                icon={
                  <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M3 8l7.89 5.26a2 2 0 002.22 0L21 8M5 19h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v10a2 2 0 002 2z" />
                  </svg>
                }
                data-testid="register-email-input"
              />

              <div className="space-y-2">
                <label htmlFor="code-input" className="block text-sm font-medium text-slate-300">
                  验证码
                </label>
                <div className="flex gap-3">
                  <Input
                    id="code-input"
                    type="text"
                    value={verificationCode}
                    onChange={(e) => setVerificationCode(e.target.value)}
                    placeholder="请输入验证码"
                    maxLength={6}
                    className="flex-1"
                    data-testid="code-input"
                  />
                  <Button
                    type="button"
                    variant="secondary"
                    size="md"
                    onClick={handleSendCode}
                    disabled={countdown > 0 || !email || codeSending}
                    loading={codeSending}
                    className="whitespace-nowrap min-w-[100px]"
                    data-testid="send-code-button"
                  >
                    {codeSending ? '发送中...' : countdown > 0 ? `${countdown}秒` : '发送验证码'}
                  </Button>
                </div>
                {!email && (
                  <p className="text-slate-500 text-xs">请先输入邮箱</p>
                )}
              </div>

              <Input
                id="username-input"
                label="用户名（可选）"
                type="text"
                value={username}
                onChange={(e) => setUsername(e.target.value)}
                placeholder="请输入用户名"
                icon={
                  <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z" />
                  </svg>
                }
                data-testid="username-input"
              />

              <Input
                id="register-password-input"
                label="密码"
                type="password"
                value={password}
                onChange={(e) => {
                  setPassword(e.target.value);
                  setPasswordError(null);
                }}
                placeholder={`至少${VALIDATION_CONFIG.PASSWORD.MIN_LENGTH}位，包含字母和数字`}
                required
                icon={
                  <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 15v2m-6 4h12a2 2 0 002-2v-6a2 2 0 00-2-2H6a2 2 0 00-2 2v6a2 2 0 002 2m10 0V5a2 2 0 00-2-2H6a2 2 0 00-2 2v14a2 2 0 002 2h2a2 2 0 002-2V5a2 2 0 00-2-2H6a2 2 0 00-2 2v2" />
                  </svg>
                }
                data-testid="register-password-input"
              />
              {passwordError && !confirmPassword && (
                <p className="text-rose-400 text-sm" data-testid="password-error">{passwordError}</p>
              )}
              {password && !isPasswordValid && !confirmPassword && (
                <p className="text-amber-400 text-sm">密码需至少{VALIDATION_CONFIG.PASSWORD.MIN_LENGTH}位，包含字母和数字</p>
              )}

              <Input
                id="confirm-password-input"
                label="确认密码"
                type="password"
                value={confirmPassword}
                onChange={(e) => setConfirmPassword(e.target.value)}
                placeholder="请再次输入密码"
                required
                icon={
                  <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 12l2 2 4-4m5.618-4.016A11.955 11.955 0 0112 2.944a11.955 11.955 0 01-8.618 3.04A12.02 12.02 0 003 9c0 5.591 3.824 10.29 9 11.622 5.176-1.332 9-6.03 9-11.622 0-1.042-.133-2.052-.382-3.016z" />
                  </svg>
                }
                data-testid="confirm-password-input"
              />
              {/* 显示密码不匹配错误 */}
              {(passwordMismatchError || (confirmPassword && password !== confirmPassword)) && (
                <p className="text-rose-400 text-sm" data-testid="password-mismatch-error">
                  {passwordMismatchError || '两次输入的密码不一致'}
                </p>
              )}

              <div className="flex items-start gap-3 p-4 rounded-xl bg-slate-800/50">
                <input
                  id="terms-checkbox"
                  type="checkbox"
                  checked={agreedToTerms}
                  onChange={(e) => setAgreedToTerms(e.target.checked)}
                  required
                  className="mt-1 w-5 h-5 rounded border-slate-600 text-sky-500 focus:ring-sky-500 focus:ring-offset-slate-900"
                  data-testid="terms-checkbox"
                />
                <label htmlFor="terms-checkbox" className="text-sm text-slate-300 flex-1">
                  我已阅读并同意{' '}
                  <Link to="/terms" className="text-sky-400 hover:text-sky-300">
                    《用户协议》
                  </Link>
                  {' 和 '}
                  <Link to="/privacy" className="text-sky-400 hover:text-sky-300">
                    《隐私政策》
                  </Link>
                </label>
              </div>

              <Button
                type="submit"
                variant="primary"
                size="lg"
                loading={isLoading}
                disabled={!canSubmit}
                className="w-full"
                data-testid="register-button"
              >
                {isLoading ? '注册中...' : '注册'}
              </Button>
            </form>

            <div className="mt-8 text-center">
              <div className="divider-gradient" />

              <div className="text-center text-sm text-slate-400 mt-6">
                已有账号？{' '}
                <Link to="/login" className="text-sky-400 hover:text-sky-300 font-medium" data-testid="login-link">
                  立即登录
                </Link>
              </div>
            </div>
          </div>

          {/* Tech Decorative Elements */}
          <div className="mt-8 flex justify-center gap-2">
            <div className="w-2 h-2 rounded-full bg-sky-500 animate-pulse"></div>
            <div className="w-2 h-2 rounded-full bg-accent-500 animate-pulse [animation-delay:0.2s]"></div>
            <div className="w-2 h-2 rounded-full bg-pink-500 animate-pulse [animation-delay:0.4s]"></div>
          </div>
        </div>
      </div>
    </div>
  );
}
