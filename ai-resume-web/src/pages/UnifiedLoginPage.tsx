import { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { useAuthStore } from '../store/auth';
import { SEO } from '../components/SEO';
import { Button, Input, GradientText } from '../components/UIComponents';
import OAuthProviderIcon from '../components/OAuthProviderIcon';
import VerificationCodeInput from '../components/VerificationCodeInput';
import { getEnabledProviders, initiateOAuth } from '../config/oauth.config';

type LoginTab = 'email' | 'phone' | 'oauth';

const API_BASE = () => import.meta.env.VITE_API_URL || '';

export default function UnifiedLoginPage() {
  const navigate = useNavigate();
  const { login, loginWithOAuth, isLoading, error, clearError } = useAuthStore();

  const [activeTab, setActiveTab] = useState<LoginTab>('email');
  const [email, setEmail] = useState('');
  const [phone, setPhone] = useState('');
  const [password, setPassword] = useState('');
  const [smsCode, setSmsCode] = useState('');
  const [smsToken, setSmsToken] = useState('');
  const [oauthLoading, setOAuthLoading] = useState<string | null>(null);

  const enabledProviders = getEnabledProviders();

  const handleEmailLogin = async (e: React.FormEvent) => {
    e.preventDefault();
    clearError();
    try {
      await login(email, password);
      navigate('/dashboard');
    } catch { /* handled by store */ }
  };

  const handleSMSLogin = async (e: React.FormEvent) => {
    e.preventDefault();
    clearError();

    if (!/^1[3-9]\d{9}$/.test(phone)) {
      alert('请输入正确的11位手机号');
      return;
    }
    if (!smsCode || smsCode.length < 4) {
      alert('请输入验证码');
      return;
    }

    try {
      const res = await fetch(`${API_BASE()}/api/v1/auth/sms/login`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ phone, code: smsCode, sms_token: smsToken }),
      });
      const data = await res.json();

      if (!res.ok) throw new Error(data.detail || '登录失败');

      const tokenData = data.data;
      loginWithOAuth(tokenData.access_token, tokenData.refresh_token);
      navigate('/dashboard');
    } catch (err) {
      alert(err instanceof Error ? err.message : '登录失败');
    }
  };

  const handleOAuthLogin = async (providerKey: string) => {
    setOAuthLoading(providerKey);
    try {
      await initiateOAuth(providerKey);
    } catch (err) {
      alert(err instanceof Error ? err.message : '授权失败，请重试');
      setOAuthLoading(null);
    }
  };

  return (
    <>
      <SEO title="统一登录" description="支持邮箱、手机号、第三方账号登录" noIndex />

      <div className="min-h-screen relative overflow-x-hidden flex flex-col justify-center bg-slate-950">
        <div className="fixed inset-0 pointer-events-none overflow-hidden">
          <div className="absolute top-0 left-0 w-96 h-96 bg-amber-500/10 rounded-full blur-3xl" />
          <div className="absolute bottom-0 right-0 w-96 h-96 bg-emerald-500/10 rounded-full blur-3xl" />
        </div>

        <div className="relative z-10 w-full max-w-md mx-auto px-4 py-12">
          <div className="text-center mb-6">
            <h1 className="text-2xl font-bold mb-1">
              <GradientText>欢迎回来</GradientText>
            </h1>
            <p className="text-slate-400 text-sm">选择你的登录方式</p>
          </div>

          <div className="card-glass">
            {/* Tab 切换 */}
            <div className="flex gap-2 mb-6">
              <button
                onClick={() => setActiveTab('email')}
                className={`flex-1 py-2 px-4 rounded-lg text-sm font-medium transition-all ${
                  activeTab === 'email'
                    ? 'bg-amber-500 text-white'
                    : 'bg-slate-800 text-slate-300 hover:bg-slate-700'
                }`}
              >
                邮箱登录
              </button>
              <button
                onClick={() => setActiveTab('phone')}
                className={`flex-1 py-2 px-4 rounded-lg text-sm font-medium transition-all ${
                  activeTab === 'phone'
                    ? 'bg-amber-500 text-white'
                    : 'bg-slate-800 text-slate-300 hover:bg-slate-700'
                }`}
              >
                手机登录
              </button>
              <button
                onClick={() => setActiveTab('oauth')}
                className={`flex-1 py-2 px-4 rounded-lg text-sm font-medium transition-all ${
                  activeTab === 'oauth'
                    ? 'bg-amber-500 text-white'
                    : 'bg-slate-800 text-slate-300 hover:bg-slate-700'
                }`}
              >
                第三方
              </button>
            </div>

            {error && (
              <div className="mb-4 p-3 rounded-lg bg-rose-500/10 border border-rose-500/50 text-rose-400 text-xs">
                {error}
              </div>
            )}

            {/* 邮箱登录 */}
            {activeTab === 'email' && (
              <form onSubmit={handleEmailLogin} className="space-y-4">
                <Input
                  id="email"
                  label="邮箱地址"
                  type="email"
                  value={email}
                  onChange={(e) => { setEmail(e.target.value); clearError(); }}
                  placeholder="your@email.com"
                  required
                />
                <Input
                  id="password"
                  label="密码"
                  type="password"
                  value={password}
                  onChange={(e) => setPassword(e.target.value)}
                  placeholder="••••••••"
                  required
                />
                <Button type="submit" variant="primary" size="md" loading={isLoading} className="w-full">
                  {isLoading ? '登录中...' : '登录'}
                </Button>
              </form>
            )}

            {/* 手机号+验证码登录 */}
            {activeTab === 'phone' && (
              <form onSubmit={handleSMSLogin} className="space-y-4">
                <Input
                  id="phone"
                  label="手机号"
                  type="tel"
                  value={phone}
                  onChange={(e) => { setPhone(e.target.value.replace(/\D/g, '').slice(0, 11)); clearError(); }}
                  placeholder="请输入11位手机号"
                  maxLength={11}
                  required
                />
                <VerificationCodeInput
                  phone={phone}
                  code={smsCode}
                  onCodeChange={setSmsCode}
                  onSmsTokenChange={setSmsToken}
                />
                <Button type="submit" variant="primary" size="md" loading={isLoading} className="w-full">
                  {isLoading ? '登录中...' : '验证码登录'}
                </Button>
                <p className="text-center text-slate-500 text-xs">
                  未注册手机号请先<a href="/register" className="text-amber-400 hover:text-amber-300 ml-1">注册账号</a>
                </p>
              </form>
            )}

            {/* 第三方登录 */}
            {activeTab === 'oauth' && (
              <div className="space-y-3">
                <p className="text-center text-slate-400 text-sm mb-4">
                  选择第三方账号一键登录
                </p>
                {enabledProviders.map((provider) => (
                  <Button
                    key={provider.key}
                    variant="ghost"
                    size="md"
                    className="w-full"
                    onClick={() => handleOAuthLogin(provider.key)}
                    loading={oauthLoading === provider.key}
                  >
                    <span className="flex items-center justify-center gap-2">
                      <OAuthProviderIcon provider={provider.key} />
                      使用 {provider.name} 登录
                    </span>
                  </Button>
                ))}
              </div>
            )}

            <div className="mt-4 text-center">
              <div className="divider-gradient" />
              <p className="text-slate-400 text-xs mt-4">
                还没有账号？
                <a href="/register" className="text-amber-400 hover:text-amber-300 font-medium ml-1">
                  立即注册
                </a>
              </p>
            </div>
          </div>
        </div>
      </div>
    </>
  );
}
