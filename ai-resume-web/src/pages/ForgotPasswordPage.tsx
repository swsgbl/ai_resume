import { useState } from 'react';
import { Link, useNavigate } from 'react-router-dom';
import { Button, Input, GradientText, Orb } from '../components/UIComponents';

interface Step {
  type: 'email' | 'verify' | 'reset';
}

export default function ForgotPasswordPage() {
  const navigate = useNavigate();
  const [step, setStep] = useState<Step>({ type: 'email' });
  const [email, setEmail] = useState('');
  const [code, setCode] = useState('');
  const [newPassword, setNewPassword] = useState('');
  const [confirmPassword, setConfirmPassword] = useState('');
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState('');
  const [countdown, setCountdown] = useState(0);

  const handleSendCode = async (e: React.FormEvent) => {
    e.preventDefault();
    setIsLoading(true);
    setError('');

    try {
      // 调用后端API发送验证码
      const response = await fetch(`${import.meta.env.VITE_API_URL}/api/v1/auth/password-reset/request`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ email })
      });

      if (!response.ok) {
        throw new Error('发送失败，请稍后重试');
      }

      setStep({ type: 'verify' });
      startCountdown();
    } catch (err) {
      setError(err instanceof Error ? err.message : '发送失败，请稍后重试');
    } finally {
      setIsLoading(false);
    }
  };

  const handleVerifyCode = async (e: React.FormEvent) => {
    e.preventDefault();
    setIsLoading(true);
    setError('');

    try {
      // 验证码校验通过后进入重置密码步骤
      setStep({ type: 'reset' });
    } catch (err) {
      setError(err instanceof Error ? err.message : '验证失败，请检查验证码');
    } finally {
      setIsLoading(false);
    }
  };

  const handleResetPassword = async (e: React.FormEvent) => {
    e.preventDefault();

    if (newPassword !== confirmPassword) {
      setError('两次输入的密码不一致');
      return;
    }

    if (newPassword.length < 6) {
      setError('密码长度至少6位');
      return;
    }

    setIsLoading(true);
    setError('');

    try {
      const response = await fetch(`${import.meta.env.VITE_API_URL}/api/v1/auth/password-reset/verify`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ email, code, new_password: newPassword })
      });

      if (!response.ok) {
        const data = await response.json();
        throw new Error(data.detail || '重置失败，请稍后重试');
      }

      // 重置成功，跳转到登录页
      navigate('/login', { replace: true });
    } catch (err) {
      setError(err instanceof Error ? err.message : '重置失败，请稍后重试');
    } finally {
      setIsLoading(false);
    }
  };

  const startCountdown = () => {
    setCountdown(60);
    const timer = setInterval(() => {
      setCountdown(prev => {
        if (prev <= 1) {
          clearInterval(timer);
          return 0;
        }
        return prev - 1;
      });
    }, 1000);
  };

  const handleResendCode = async () => {
    if (countdown > 0) return;
    await handleSendCode({ preventDefault: () => {} } as React.FormEvent);
  };

  return (
    <div className="min-h-screen relative overflow-x-hidden flex flex-col justify-center bg-slate-950">
      {/* Background Orbs */}
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
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M15 7a2 2 0 012 2m4 0a6 6 0 01-7.743 5.743L11 17H9v2H7v2H4a1 1 0 01-1-1v-2.586a1 1 0 01.293-.707l5.964-5.964A6 6 0 1121 9z" />
                </svg>
              </div>
            </Link>

            <h1 className="text-2xl font-bold mb-1">
              <GradientText>重置密码</GradientText>
            </h1>
            <p className="text-slate-400 text-sm">
              {step.type === 'email' && '输入邮箱获取验证码'}
              {step.type === 'verify' && '输入验证码验证身份'}
              {step.type === 'reset' && '设置新密码'}
            </p>
          </div>

          {/* Form Card */}
          <div className="card-glass">
            {/* Progress Steps */}
            <div className="flex items-center justify-center gap-2 mb-6">
              <div className={`w-8 h-1 rounded-full transition-colors ${step.type === 'email' || step.type === 'verify' || step.type === 'reset' ? 'bg-amber-500' : 'bg-slate-700'}`} />
              <div className={`w-8 h-1 rounded-full transition-colors ${step.type === 'verify' || step.type === 'reset' ? 'bg-amber-500' : 'bg-slate-700'}`} />
              <div className={`w-8 h-1 rounded-full transition-colors ${step.type === 'reset' ? 'bg-amber-500' : 'bg-slate-700'}`} />
            </div>

            {error && (
              <div className="mb-4 p-3 rounded-lg bg-rose-500/10 border border-rose-500/50 text-rose-400 text-xs flex items-start gap-2">
                <svg className="w-4 h-4 flex-shrink-0 mt-0.5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 8v4m0 4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
                </svg>
                <span>{error}</span>
              </div>
            )}

            {/* Step 1: Email Input */}
            {step.type === 'email' && (
              <form onSubmit={handleSendCode} className="space-y-4">
                <Input
                  id="reset-email"
                  label="邮箱地址"
                  type="email"
                  value={email}
                  onChange={(e) => setEmail(e.target.value)}
                  placeholder="your@email.com"
                  required
                  icon={
                    <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M3 8l7.89 5.26a2 2 0 002.22 0L21 8M5 19h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v10a2 2 0 002 2z" />
                    </svg>
                  }
                />

                <Button
                  type="submit"
                  variant="primary"
                  size="md"
                  loading={isLoading}
                  className="w-full"
                >
                  {isLoading ? '发送中...' : '发送验证码'}
                </Button>
              </form>
            )}

            {/* Step 2: Verify Code */}
            {step.type === 'verify' && (
              <form onSubmit={handleVerifyCode} className="space-y-4">
                <div className="p-3 rounded-lg bg-slate-800/50 border border-slate-700/50">
                  <p className="text-xs text-slate-300">验证码已发送至</p>
                  <p className="text-sm font-semibold text-white">{email}</p>
                </div>

                <Input
                  id="verify-code"
                  label="验证码"
                  type="text"
                  value={code}
                  onChange={(e) => setCode(e.target.value)}
                  placeholder="请输入6位验证码"
                  required
                  maxLength={6}
                  icon={
                    <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 12l2 2 4-4m5.618-4.016A11.955 11.955 0 0112 2.944a11.955 11.955 0 01-8.618 3.04A12.02 12.02 0 003 9c0 5.591 3.824 10.29 9 11.622 5.176-1.332 9-6.03 9-11.622 0-1.042-.133-2.052-.382-3.016z" />
                    </svg>
                  }
                />

                <button
                  type="button"
                  onClick={handleResendCode}
                  disabled={countdown > 0}
                  className="text-xs text-amber-400 hover:text-amber-300 disabled:text-slate-500 disabled:cursor-not-allowed transition-colors"
                >
                  {countdown > 0 ? `${countdown}秒后重新发送` : '重新发送验证码'}
                </button>

                <Button
                  type="submit"
                  variant="primary"
                  size="md"
                  loading={isLoading}
                  className="w-full"
                >
                  {isLoading ? '验证中...' : '下一步'}
                </Button>

                <button
                  type="button"
                  onClick={() => setStep({ type: 'email' })}
                  className="w-full text-xs text-slate-400 hover:text-slate-300 transition-colors"
                >
                  返回修改邮箱
                </button>
              </form>
            )}

            {/* Step 3: Reset Password */}
            {step.type === 'reset' && (
              <form onSubmit={handleResetPassword} className="space-y-4">
                <Input
                  id="new-password"
                  label="新密码"
                  type="password"
                  value={newPassword}
                  onChange={(e) => setNewPassword(e.target.value)}
                  placeholder="至少6位密码"
                  required
                  minLength={6}
                  icon={
                    <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 15v2m-6 4h12a2 2 0 002-2v-6a2 2 0 00-2-2H6a2 2 0 00-2 2v6a2 2 0 002 2zm10-10V7a4 4 0 00-8 0v4h8z" />
                    </svg>
                  }
                />

                <Input
                  id="confirm-password"
                  label="确认新密码"
                  type="password"
                  value={confirmPassword}
                  onChange={(e) => setConfirmPassword(e.target.value)}
                  placeholder="再次输入新密码"
                  required
                  icon={
                    <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z" />
                    </svg>
                  }
                />

                <Button
                  type="submit"
                  variant="primary"
                  size="md"
                  loading={isLoading}
                  className="w-full"
                >
                  {isLoading ? '重置中...' : '重置密码'}
                </Button>

                <button
                  type="button"
                  onClick={() => setStep({ type: 'verify' })}
                  className="w-full text-xs text-slate-400 hover:text-slate-300 transition-colors"
                >
                  返回上一步
                </button>
              </form>
            )}

            {/* Back to Login */}
            <div className="mt-4 text-center">
              <Link to="/login" className="text-xs text-slate-400 hover:text-slate-300 transition-colors">
                <svg className="w-3 h-3 inline-block mr-1" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M15 19l-7-7 7-7" />
                </svg>
                返回登录
              </Link>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
