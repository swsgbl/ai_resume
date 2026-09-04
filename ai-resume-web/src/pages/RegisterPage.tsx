import { useState, useEffect, useCallback } from 'react';
import { Link, useNavigate } from 'react-router-dom';
import { useAuthStore } from '../store/auth';
import { SEO } from '../components/SEO';
import { Button, Input, GradientText, Orb } from '../components/UIComponents';
import QQLoginButton from '../components/QQLoginButton';
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
  const [codeError, setCodeError] = useState<string | null>(null);
  const [showPassword, setShowPassword] = useState(false);
  const [showConfirmPassword, setShowConfirmPassword] = useState(false);
  const [codeSending, setCodeSending] = useState(false);

  const normalizedEmail = email.trim().toLowerCase();
  const normalizedVerificationCode = verificationCode.trim();
  const isVerificationCodeValid = /^\d{6}$/.test(normalizedVerificationCode);

  const validatePassword = useCallback((): string | null => {
    // 先检查字母和数字，因为测试期望这些错误先出现
    if (password.length > 0 && !/[A-Za-z]/.test(password)) return '密码必须包含字母';
    if (password.length > 0 && !/\d/.test(password)) return '密码必须包含数字';
    if (password.length > 0 && password.length < VALIDATION_CONFIG.PASSWORD.MIN_LENGTH) return `密码长度至少${VALIDATION_CONFIG.PASSWORD.MIN_LENGTH}位`;
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
    clearError();
    setPasswordMismatchError(null);
    if (!normalizedEmail || countdown > 0) return;

    try {
      setCodeSending(true);
      await api.auth.sendVerificationCode(normalizedEmail);
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
    setCodeError(null);

    if (!isVerificationCodeValid) {
      setCodeError('请输入6位数字验证码');
      return;
    }

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
      await register(normalizedEmail, password, {
        username: username || undefined,
        verification_code: normalizedVerificationCode,
      });
      navigate('/dashboard');
    } catch {
      // Error handled by store
    }
  };

  const canSubmit = password === confirmPassword &&
    normalizedEmail.length > 0 &&
    isVerificationCodeValid &&
    password.length > 0 &&
    agreedToTerms &&
    !isLoading;

  const isPasswordValid = password.length === 0 || validatePassword() === null;

  return (
    <>
      <SEO
        title="用户注册"
        description="注册 AI Resume，免费使用 AI 简历生成器，快速创建专业简历。"
        noIndex
      />
      <div className="min-h-screen relative overflow-x-hidden flex flex-col justify-center bg-slate-950">
      {/* Background Orbs - 桌面端优化 */}
      <div className="fixed inset-0 pointer-events-none overflow-hidden">
        <Orb color="primary" size={200} className="top-0 left-0 -translate-x-1/2 -translate-y-1/2 opacity-20" />
        <Orb color="accent" size={150} className="bottom-0 right-0 translate-x-1/2 translate-y-1/2 opacity-10" />
      </div>

      {/* Background Grid */}
      <div className="fixed inset-0 bg-grid pointer-events-none opacity-5" />

      {/* Main Content */}
      <div className="relative z-10 w-full max-w-md mx-auto px-4 py-12">
        <div className="w-full">
          {/* Logo & Title - 桌面端优化：缩小尺寸 */}
          <div className="text-center mb-6 animate-fade-in">
            <Link to="/" className="inline-flex items-center justify-center gap-2 mb-4">
              <div className="w-12 h-12 rounded-xl bg-gradient-to-br from-amber-400 to-emerald-500 flex items-center justify-center shadow-neon-blue animate-pulse-glow">
                <svg className="w-7 h-7 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z" />
                </svg>
              </div>
            </Link>

            <h1 className="text-2xl font-bold mb-1">
              <GradientText>创建账号</GradientText>
            </h1>
            <p className="text-slate-400 text-sm">创建账号，开启智能简历之旅</p>
          </div>

          {/* Register Form Card */}
          <div className="card-glass animate-scale-in">
            <div className="mb-5">
              <h2 className="text-lg font-semibold text-white mb-1">用户注册</h2>
              <p className="text-slate-400 text-xs">填写信息创建新账户</p>
            </div>

            {error && (
              <div className="mb-4 p-3 rounded-lg bg-rose-500/10 border border-rose-500/50 text-rose-400 text-xs flex items-start gap-2 animate-shimmer">
                <svg className="w-4 h-4 flex-shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 8v4m0 4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
                </svg>
                <span>{error}</span>
              </div>
            )}

            <form onSubmit={handleSubmit} className="space-y-4">
              <Input
                id="register-email-input"
                label="邮箱地址"
                type="email"
                value={email}
                onChange={(e) => {
                  setEmail(e.target.value);
                  // 用户输入时清除之前的错误
                  clearError();
                }}
                placeholder="your@email.com"
                autoComplete="email"
                required
                icon={
                  <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M3 8l7.89 5.26a2 2 0 002.22 0L21 8M5 19h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v10a2 2 0 002 2z" />
                  </svg>
                }
                data-testid="register-email-input"
              />

              <div className="space-y-1">
                <label htmlFor="code-input" className="block text-xs font-medium text-slate-300">
                  验证码
                </label>
                <div className="flex gap-2">
                  <Input
                    id="code-input"
                    type="text"
                    value={verificationCode}
                    onChange={(e) => setVerificationCode(e.target.value)}
                    placeholder="请输入验证码"
                    maxLength={6}
                    inputMode="numeric"
                    autoComplete="one-time-code"
                    className="flex-1"
                    data-testid="code-input"
                  />
                  <Button
                    type="button"
                    variant="secondary"
                    size="sm"
                    onClick={handleSendCode}
                    disabled={
                      countdown > 0 ||
                      !normalizedEmail ||
                      codeSending
                    }
                    loading={codeSending}
                    className="whitespace-nowrap min-w-[80px] text-xs"
                    data-testid="send-code-button"
                  >
                    {codeSending ? '发送中...' : countdown > 0 ? `${countdown}秒` : '发送验证码'}
                  </Button>
                </div>
                {!email && (
                  <p className="text-slate-500 text-xs">请先输入邮箱</p>
                )}
                {codeError && (
                  <p className="text-rose-400 text-xs" data-testid="code-error">{codeError}</p>
                )}
              </div>

              <Input
                id="username-input"
                label="用户名（可选）"
                type="text"
                value={username}
                onChange={(e) => setUsername(e.target.value)}
                placeholder="请输入用户名"
                autoComplete="username"
                icon={
                  <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z" />
                  </svg>
                }
                data-testid="username-input"
              />

              <Input
                id="register-password-input"
                label="密码"
                type={showPassword ? 'text' : 'password'}
                value={password}
                onChange={(e) => {
                  setPassword(e.target.value);
                  // 实时验证：显示密码格式错误
                  const validationError = validatePassword();
                  if (validationError && e.target.value.length > 0) {
                    setPasswordError(validationError);
                  } else {
                    setPasswordError(null);
                  }
                }}
                placeholder={`至少${VALIDATION_CONFIG.PASSWORD.MIN_LENGTH}位，包含字母和数字`}
                autoComplete="new-password"
                required
                suffix={
                  <button
                    type="button"
                    onClick={() => setShowPassword(!showPassword)}
                    aria-label={showPassword ? '隐藏密码' : '显示密码'}
                    className="p-1 text-slate-500 transition-colors hover:text-slate-300"
                  >
                    {showPassword ? (
                      <svg className="h-4 w-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M13.875 18.825A10.05 10.05 0 0112 19c-4.478 0-8.268-2.943-9.543-7a9.97 9.97 0 011.563-3.029m5.858.908a3 3 0 114.243 4.243M9.878 9.878l4.242 4.242M9.88 9.88l-3.29-3.29m7.532 7.532l3.29 3.29M3 3l3.59 3.59m0 0A9.953 9.953 0 0112 5c4.478 0 8.268 2.943 9.543 7a10.025 10.025 0 01-4.132 5.411m0 0L21 21" />
                      </svg>
                    ) : (
                      <svg className="h-4 w-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M15 12a3 3 0 11-6 0 3 3 0 016 0z" />
                        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z" />
                      </svg>
                    )}
                  </button>
                }
                icon={
                  <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 15v2m-6 4h12a2 2 0 002-2v-6a2 2 0 00-2-2H6a2 2 0 00-2 2v6a2 2 0 002 2m10 0V5a2 2 0 00-2-2H6a2 2 0 00-2 2v14a2 2 0 002 2h2a2 2 0 002-2V5a2 2 0 00-2-2H6a2 2 0 00-2 2v2" />
                  </svg>
                }
                data-testid="register-password-input"
              />
              {passwordError && !confirmPassword && (
                <p className="text-rose-400 text-xs" data-testid="password-error">{passwordError}</p>
              )}
              {password && !isPasswordValid && !passwordError && !confirmPassword && (
                <p className="text-amber-400 text-xs">密码需至少{VALIDATION_CONFIG.PASSWORD.MIN_LENGTH}位，包含字母和数字</p>
              )}

              <Input
                id="confirm-password-input"
                label="确认密码"
                type={showConfirmPassword ? 'text' : 'password'}
                value={confirmPassword}
                onChange={(e) => {
                  setConfirmPassword(e.target.value);
                  // 实时验证：清除密码不匹配错误（如果密码已匹配）
                  if (password === e.target.value) {
                    setPasswordMismatchError(null);
                  }
                }}
                placeholder="请再次输入密码"
                autoComplete="new-password"
                required
                suffix={
                  <button
                    type="button"
                    onClick={() => setShowConfirmPassword(!showConfirmPassword)}
                    aria-label={showConfirmPassword ? '隐藏密码' : '显示密码'}
                    className="p-1 text-slate-500 transition-colors hover:text-slate-300"
                  >
                    {showConfirmPassword ? (
                      <svg className="h-4 w-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M13.875 18.825A10.05 10.05 0 0112 19c-4.478 0-8.268-2.943-9.543-7a9.97 9.97 0 011.563-3.029m5.858.908a3 3 0 114.243 4.243M9.878 9.878l4.242 4.242M9.88 9.88l-3.29-3.29m7.532 7.532l3.29 3.29M3 3l3.59 3.59m0 0A9.953 9.953 0 0112 5c4.478 0 8.268 2.943 9.543 7a10.025 10.025 0 01-4.132 5.411m0 0L21 21" />
                      </svg>
                    ) : (
                      <svg className="h-4 w-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M15 12a3 3 0 11-6 0 3 3 0 016 0z" />
                        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z" />
                      </svg>
                    )}
                  </button>
                }
                icon={
                  <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 12l2 2 4-4m5.618-4.016A11.955 11.955 0 0112 2.944a11.955 11.955 0 01-8.618 3.04A12.02 12.02 0 003 9c0 5.591 3.824 10.29 9 11.622 5.176-1.332 9-6.03 9-11.622 0-1.042-.133-2.052-.382-3.016z" />
                  </svg>
                }
                data-testid="confirm-password-input"
              />
              {/* 显示密码不匹配错误 */}
              {(passwordMismatchError || (confirmPassword && password !== confirmPassword)) && (
                <p className="text-rose-400 text-xs" data-testid="password-mismatch-error">
                  {passwordMismatchError || '两次输入的密码不一致'}
                </p>
              )}

              <div className="flex items-start gap-2 p-3 rounded-lg bg-slate-800/50">
                <input
                  id="terms-checkbox"
                  type="checkbox"
                  checked={agreedToTerms}
                  onChange={(e) => setAgreedToTerms(e.target.checked)}
                  required
                  className="mt-0.5 w-4 h-4 rounded border-slate-600 text-amber-500 focus:ring-amber-500 focus:ring-offset-slate-900"
                  data-testid="terms-checkbox"
                />
                <label htmlFor="terms-checkbox" className="text-xs text-slate-300 flex-1">
                  我已阅读并同意{' '}
                  <Link to="/terms" className="text-amber-400 hover:text-amber-300">
                    《用户协议》
                  </Link>
                  {' 和 '}
                  <Link to="/privacy" className="text-amber-400 hover:text-amber-300">
                    《隐私政策》
                  </Link>
                </label>
              </div>

              <Button
                type="submit"
                variant="primary"
                size="md"
                loading={isLoading}
                disabled={!canSubmit}
                className="w-full"
                data-testid="register-button"
              >
                {isLoading ? '注册中...' : '注册'}
              </Button>
            </form>

            <div className="mt-5 text-center">
              <QQLoginButton />

              <div className="divider-gradient" />

              <div className="text-center text-xs text-slate-400 mt-4">
                已有账号？{' '}
                <Link to="/login" className="text-amber-400 hover:text-amber-300 font-medium" data-testid="login-link">
                  立即登录
                </Link>
              </div>
            </div>
          </div>

          {/* Tech Decorative Elements */}
          <div className="mt-4 flex justify-center gap-2">
            <div className="w-1.5 h-1.5 rounded-full bg-amber-500 animate-pulse"></div>
            <div className="w-1.5 h-1.5 rounded-full bg-emerald-500 animate-pulse [animation-delay:0.2s]"></div>
            <div className="w-1.5 h-1.5 rounded-full bg-pink-500 animate-pulse [animation-delay:0.4s]"></div>
          </div>
        </div>
      </div>
    </div>
    </>
  );
}
