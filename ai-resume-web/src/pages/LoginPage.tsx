import { useState, useEffect } from 'react';
import { Link, useNavigate } from 'react-router-dom';
import { useAuthStore } from '../store/auth';
import { SEO } from '../components/SEO';
import OAuthProviderIcon from '../components/OAuthProviderIcon';
import { Button, Input, GradientText, Orb } from '../components/UIComponents';

// 存储键名常量
const REMEMBER_PASSWORD_KEY = 'remember_password';
const SAVED_EMAIL_KEY = 'saved_email';

export default function LoginPage() {
  const navigate = useNavigate();
  const { login, isLoading, error, clearError } = useAuthStore();
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [showPassword, setShowPassword] = useState(false);
  const [rememberPassword, setRememberPassword] = useState(false);

  // 页面加载时检查是否有保存的凭据
  useEffect(() => {
    const remember = localStorage.getItem(REMEMBER_PASSWORD_KEY) === 'true';
    if (remember) {
      const savedEmail = localStorage.getItem(SAVED_EMAIL_KEY);
      if (savedEmail) {
        setEmail(savedEmail);
        setRememberPassword(true);
      }
    }
  }, []);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    clearError();

    try {
      await login(email, password);

      // 登录成功后保存凭据
      if (rememberPassword) {
        localStorage.setItem(REMEMBER_PASSWORD_KEY, 'true');
        localStorage.setItem(SAVED_EMAIL_KEY, email);
      } else {
        localStorage.removeItem(REMEMBER_PASSWORD_KEY);
        localStorage.removeItem(SAVED_EMAIL_KEY);
      }

      navigate('/dashboard');
    } catch {
      // Error handled by store
    }
  };

  return (
    <>
      <SEO
        title="用户登录"
        description="登录 AI Resume，管理你的简历，使用 AI 技术快速创建专业简历。"
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
          {/* Logo & Title */}
          <div className="text-center mb-6">
            <Link to="/" className="inline-flex items-center justify-center gap-3 mb-4">
              <div className="w-12 h-12 rounded-xl bg-gradient-to-br from-amber-400 to-emerald-500 flex items-center justify-center shadow-neon-blue">
                <svg className="w-7 h-7 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z" />
                </svg>
              </div>
            </Link>

            <h1 className="text-2xl font-bold mb-1">
              <GradientText>欢迎回来</GradientText>
            </h1>
            <p className="text-slate-400 text-sm">登录以继续创建你的专业简历</p>
          </div>

          {/* Login Form Card */}
          <div className="card-glass">
            <div className="mb-5">
              <h2 className="text-lg font-semibold text-white mb-1">账户登录</h2>
              <p className="text-slate-400 text-xs">输入你的账户信息</p>
            </div>

            {error && (
              <div className="mb-4 p-3 rounded-lg bg-rose-500/10 border border-rose-500/50 text-rose-400 text-xs flex items-start gap-2">
                <svg className="w-4 h-4 flex-shrink-0 mt-0.5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 8v4m0 4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
                </svg>
                <span>{error}</span>
              </div>
            )}

            <form onSubmit={handleSubmit} className="space-y-4">
              <Input
                id="email-input"
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
                data-testid="email-input"
              />

              <div className="space-y-1">
                <div className="flex items-center justify-between">
                  <label htmlFor="password-input" className="block text-xs font-medium text-slate-300">
                    密码
                  </label>
                  <Link to="/forgot-password" className="text-xs text-amber-400 hover:text-amber-300">
                    忘记密码？
                  </Link>
                </div>
                <Input
                  id="password-input"
                  type={showPassword ? 'text' : 'password'}
                  value={password}
                  onChange={(e) => setPassword(e.target.value)}
                  placeholder="•••••••••"
                  autoComplete="current-password"
                  required
                  icon={
                    <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 15v2m-6 4h12a2 2 0 002-2v-6a2 2 0 00-2-2H6a2 2 0 00-2 2v6a2 2 0 002 2m10 0V5a2 2 0 00-2-2H6a2 2 0 00-2 2v2" />
                    </svg>
                  }
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
                  data-testid="password-input"
                />
              </div>

              {/* 记住邮箱(下次自动填充,密码由浏览器密码管理器保管) */}
              <div className="flex items-center gap-2">
                <input
                  id="remember-password"
                  type="checkbox"
                  checked={rememberPassword}
                  onChange={(e) => setRememberPassword(e.target.checked)}
                  className="w-4 h-4 rounded border-slate-600 text-amber-500 focus:ring-amber-500 focus:ring-offset-slate-900"
                  data-testid="remember-password"
                />
                <label htmlFor="remember-password" className="text-xs text-slate-300 cursor-pointer select-none">
                  记住邮箱
                </label>
              </div>

              <Button
                type="submit"
                variant="primary"
                size="md"
                loading={isLoading}
                className="w-full"
                data-testid="login-button"
              >
                {isLoading ? '登录中...' : '登录'}
              </Button>
            </form>

            <div className="mt-4 text-center">
              <p className="text-slate-400 text-xs mb-3">或使用以下方式登录</p>

              {/* Social Login Buttons - 跳转统一登录页(微信/Google/GitHub/Gitee/Discord) */}
              <div className="flex gap-2 justify-center mb-4">
                {(['google', 'github', 'gitee', 'discord'] as const).map((provider) => (
                  <Link
                    key={provider}
                    to="/unified-login"
                    aria-label={`使用 ${provider} 登录`}
                    className="w-9 h-9 rounded-lg glass-effect flex items-center justify-center text-slate-300 hover:text-white hover:bg-white/10 transition-all"
                  >
                    <OAuthProviderIcon provider={provider} className="w-4 h-4" />
                  </Link>
                ))}
              </div>

              <div className="divider-gradient" />

              <div className="text-center text-xs text-slate-400">
                还没有账号？
                <Link to="/register" className="text-amber-400 hover:text-amber-300 font-medium ml-1" data-testid="register-link">
                  立即注册
                </Link>
              </div>
            </div>

            {/* Footer Links */}
            <div className="mt-4 pt-3 border-t border-slate-700/50 text-center">
              <div className="flex justify-center gap-4 text-xs text-slate-500">
                <Link to="/terms" className="hover:text-slate-300 transition-colors" data-testid="terms-link">
                  用户协议
                </Link>
                <Link to="/privacy" className="hover:text-slate-300 transition-colors" data-testid="privacy-link">
                  隐私政策
                </Link>
                <Link to="/help" className="hover:text-slate-300 transition-colors">
                  帮助中心
                </Link>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
    </>
  );
}
