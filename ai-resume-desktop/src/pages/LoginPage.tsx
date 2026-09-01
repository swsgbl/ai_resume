import { useState } from 'react';
import { Link, useNavigate } from 'react-router-dom';
import { useAuthStore } from '../store/auth';
import { Button, Input, GradientText, Orb } from '../components/UIComponents';

export default function LoginPage() {
  const navigate = useNavigate();
  const { login, isLoading, error, clearError } = useAuthStore();
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    clearError();

    try {
      await login(email, password);
      navigate('/');
    } catch {
      // Error handled by store
    }
  };

  return (
    <div className="min-h-screen relative overflow-x-hidden flex flex-col justify-center bg-slate-950">
      {/* Background Orbs - 优化尺寸 */}
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
              <GradientText>欢迎回来</GradientText>
            </h1>
            <p className="text-slate-400">登录以继续创建你的专业简历</p>
          </div>

          {/* Login Form Card */}
          <div className="card-glass animate-scale-in">
            <div className="mb-8">
              <h2 className="text-xl font-semibold text-white mb-1">账户登录</h2>
              <p className="text-slate-400 text-sm">输入你的账户信息</p>
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
                id="email-input"
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
                data-testid="email-input"
              />

              <div className="space-y-2">
                <div className="flex items-center justify-between">
                  <label htmlFor="password-input" className="block text-sm font-medium text-slate-300">
                    密码
                  </label>
                  <Link to="/forgot-password" className="text-sm text-sky-400 hover:text-sky-300">
                    忘记密码？
                  </Link>
                </div>
                <Input
                  id="password-input"
                  type="password"
                  value={password}
                  onChange={(e) => setPassword(e.target.value)}
                  placeholder="•••••••••"
                  required
                  icon={
                    <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 15v2m-6 4h12a2 2 0 002-2v-6a2 2 0 00-2-2H6a2 2 0 00-2 2v6a2 2 0 002 2m10 0V5a2 2 0 00-2-2H6a2 2 0 00-2 2v14a2 2 0 002 2h2a2 2 0 002-2V5a2 2 0 00-2-2H6a2 2 0 00-2 2v2" />
                    </svg>
                  }
                  data-testid="password-input"
                />
              </div>

              <Button
                type="submit"
                variant="primary"
                size="lg"
                loading={isLoading}
                className="w-full"
                data-testid="login-button"
              >
                {isLoading ? '登录中...' : '登录'}
              </Button>
            </form>

            <div className="mt-8 text-center">
              <p className="text-slate-400 text-sm mb-4">或使用以下方式登录</p>

              {/* Social Login Buttons */}
              <div className="flex gap-3 justify-center mb-6">
                <button type="button" disabled title="第三方登录 - 即将开放" className="w-12 h-12 rounded-xl glass-effect flex items-center justify-center text-slate-500 cursor-not-allowed opacity-60">
                  <svg className="w-6 h-6" fill="currentColor" viewBox="0 0 24 24">
                    <path d="M12 2C6.477 2 2 6.477 2 12c0 5.523 4.477 10 10 10 5.523 0 10-4.477 10-10S17.523 2 12 2zm3.295 14.772l-1.148-1.148a4.002 4.002 0 01-1.414 0l-1.147 1.147a4.002 4.002 0 010 5.656 4.002 4.002 0 011.414 0l1.147-1.147a4.002 4.002 0 015.656 0 4.002 4.002 0 01-1.414 0l-1.148-1.148a4.002 4.002 0 00-5.656 0 4.002 4.002 0 010-5.656z" />
                  </svg>
                </button>
                <button type="button" disabled title="第三方登录 - 即将开放" className="w-12 h-12 rounded-xl glass-effect flex items-center justify-center text-slate-500 cursor-not-allowed opacity-60">
                  <svg className="w-6 h-6" fill="currentColor" viewBox="0 0 24 24">
                    <path d="M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm-1 17.93c-3.95-.49-7-3.85-7-8.93h4.07c.71 0 1.29-.58 1.29-1.29v-6.43c0-.71-.58-1.29-1.29-1.29H9.43c-.71 0-1.29.58-1.29 1.29v6.43c0 .71.58 1.29 1.29 1.29 1.29v-2.43c0-1.25.6-2.28-1.36-3.5-.43-.5.28-.87-.71-1.25-.88-1.25-.88-2.06-.23-2.93-.09-.87.14-1.68.73-2.37 1.12-.69.39-1.45 1.01-1.69 1.25-.24.24-.28.56-.14-1.25.73-1.69 1.12-.69.39-1.45 1.01-1.69 1.25-.24.24-.28.56-.14-1.25.73-1.69 1.12-.69.39-1.45 1.01-1.69 1.25-.24.24-.28.56-.14-1.25.73-1.69 1.12-.69.39-1.45 1.01-1.69 1.25-.24.24-.28.56-.14-1.25.73-1.69 1.12-.69.39-1.45 1.01-1.69 1.25-.24.24-.28.56-.14-1.25.73-1.69 1.12-.69.39-1.45 1.01-1.69 1.25-.24.24-.28.56-.14-1.25.73-1.69 1.12-.69.39-1.45 1.01-1.69 1.25z" />
                  </svg>
                </button>
                <button type="button" disabled title="第三方登录 - 即将开放" className="w-12 h-12 rounded-xl glass-effect flex items-center justify-center text-slate-500 cursor-not-allowed opacity-60">
                  <svg className="w-6 h-6" fill="currentColor" viewBox="0 0 24 24">
                    <path d="M8.69 14.25c.68-.27 1.36-.53 2.05-.78l.44-.17c.68-.27 1.35-.54 2.03-.81.68-.27 1.36-.53 2.05-.78.68-.27 1.35-.54 2.03-.81.68-.27 1.36-.53 2.05-.78.68-.27 1.35-.54 2.03-.81.68-.27 1.36-.53 2.05-.78l.44.17c.68.27 1.36.53 2.05.78.68.27 1.35.54 2.03.81l.44.17c.68.27 1.36.53 2.05.78.68.27 1.35.54 2.03.81.68.27 1.36.53 2.05.78.68.27 1.35.54 2.03.81l.44.17c.68-.27 1.36-.53 2.05-.78.68-.27 1.35-.54 2.03-.81.68-.27 1.36-.53 2.05-.78.68-.27 1.35-.54 2.03-.81.68-.27 1.36-.53 2.05-.78.68-.27 1.35-.54 2.03-.81l-.44-.17c-.68.27-1.36-.53-2.05-.78-.68-.27-1.35-.54-2.03-.81-.68-.27-1.36-.53-2.05-.78-.68-.27-1.35-.54-2.03-.81-.68-.27-1.36-.53-2.05-.78-.68-.27-1.35-.54-2.03-.81-.68-.27-1.36-.53-2.05-.78l-.44-.17c-.68.27-1.36.53-2.05.78-.68.27-1.35.54-2.03.81-.68.27-1.36.53-2.05.78-.68.27-1.35.54-2.03.81-.68.27-1.36.53-2.05.78-.68.27-1.35.54-2.03.81-.68.27-1.36-.53-2.05.78l-.44.17c-.68.27-1.36.53-2.05.78-.68.27-1.35.54-2.03.81-.68.27-1.36.53-2.05.78-.68.27-1.35.54-2.03.81-.68.27-1.36-.53-2.05.78-.68.27-1.35-.54-2.03.81l-.44-.17c-.68.27-1.36.53-2.05.78-.68.27-1.35.54-2.03.81-.68.27-1.36-.53-2.05.78-.68.27-1.35.54-2.03.81zM12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2z" />
                  </svg>
                </button>
              </div>

              <div className="divider-gradient" />

              <div className="text-center text-sm text-slate-400">
                还没有账号？
                <Link to="/register" className="text-sky-400 hover:text-sky-300 font-medium ml-1" data-testid="register-link">
                  立即注册
                </Link>
              </div>
            </div>

            {/* Footer Links */}
            <div className="mt-6 pt-6 border-t border-slate-700/50 text-center">
              <div className="flex justify-center gap-6 text-xs text-slate-500">
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

          {/* Tech Decorative Elements */}
          <div className="mt-8 flex justify-center gap-2">
            <div className="w-2 h-2 rounded-full bg-sky-500 animate-pulse"></div>
            <div className="w-2 h-2 rounded-full bg-accent-500 animate-pulse" style={{ animationDelay: '0.2s' }}></div>
            <div className="w-2 h-2 rounded-full bg-pink-500 animate-pulse" style={{ animationDelay: '0.4s' }}></div>
          </div>
        </div>
      </div>
    </div>
  );
}
