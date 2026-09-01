import { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { useAuthStore } from '../store/auth';
import { SEO } from '../components/SEO';
import { Button, Input, GradientText } from '../components/UIComponents';
import OAuthProviderIcon from '../components/OAuthProviderIcon';
import PhoneBindingForm from '../components/PhoneBindingForm';
import { initiateOAuth } from '../config/oauth.config';

interface AccountBinding {
  bound: boolean;
  value: string | null;
  is_primary: boolean;
  verified: boolean;
}

interface AccountBindings {
  email: AccountBinding;
  phone: AccountBinding;
  wechat: AccountBinding;
  google: AccountBinding;
  github: AccountBinding;
  gitee: AccountBinding;
  discord: AccountBinding;
}

// 账号类型配置
const ACCOUNT_TYPES: { key: keyof AccountBindings; label: string; colorClass: string; iconProvider?: string }[] = [
  { key: 'email', label: '邮箱', colorClass: 'bg-blue-500/20 text-blue-400', iconProvider: undefined },
  { key: 'phone', label: '手机号', colorClass: 'bg-emerald-500/20 text-emerald-400', iconProvider: undefined },
  { key: 'google', label: 'Google', colorClass: 'bg-red-500/20', iconProvider: 'google' },
  { key: 'github', label: 'GitHub', colorClass: 'bg-slate-700/50', iconProvider: 'github' },
  { key: 'gitee', label: 'Gitee', colorClass: 'bg-red-600/20', iconProvider: 'gitee' },
  { key: 'discord', label: 'Discord', colorClass: 'bg-indigo-500/20', iconProvider: 'discord' },
  { key: 'wechat', label: '微信', colorClass: 'bg-green-500/20', iconProvider: undefined },
];

export default function AccountSettingsPage() {
  const navigate = useNavigate();
  const { token } = useAuthStore();
  const [bindings, setBindings] = useState<AccountBindings | null>(null);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  // 邮箱绑定表单
  const [bindEmail, setBindEmail] = useState('');
  const [bindPassword, setBindPassword] = useState('');
  const [bindCode, setBindCode] = useState('');
  const [showBindEmailForm, setShowBindEmailForm] = useState(false);

  // 解绑
  const [unbindPassword, setUnbindPassword] = useState('');

  const apiBaseUrl = import.meta.env.VITE_API_URL || '';

  useEffect(() => {
    if (!token) { navigate('/login'); return; }
    fetchBindings();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [token, navigate]);

  const fetchBindings = async () => {
    try {
      const res = await fetch(`${apiBaseUrl}/api/v1/account/bindings`, {
        headers: { 'Authorization': `Bearer ${token}` },
      });
      if (!res.ok) throw new Error('获取账号信息失败');
      const data = await res.json();
      setBindings(data.data);
    } catch (err) {
      setError(err instanceof Error ? err.message : '获取账号信息失败');
    }
  };

  const handleBindEmail = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);
    setError(null);
    try {
      const res = await fetch(`${apiBaseUrl}/api/v1/account/bind/email`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json', 'Authorization': `Bearer ${token}` },
        body: JSON.stringify({ email: bindEmail, password: bindPassword, verification_code: bindCode }),
      });
      const data = await res.json();
      if (!res.ok) throw new Error(data.detail || '绑定失败');
      alert('邮箱绑定成功');
      setShowBindEmailForm(false);
      setBindEmail(''); setBindPassword(''); setBindCode('');
      fetchBindings();
    } catch (err) {
      setError(err instanceof Error ? err.message : '绑定失败');
    } finally {
      setLoading(false);
    }
  };

  const handleUnbind = async (accountType: string) => {
    if (!unbindPassword) { alert('请先输入密码以确认解绑'); return; }
    if (!confirm('确定要解绑此账号吗？解绑后将无法使用该方式登录。')) return;

    setLoading(true);
    setError(null);
    try {
      const res = await fetch(`${apiBaseUrl}/api/v1/account/unbind`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json', 'Authorization': `Bearer ${token}` },
        body: JSON.stringify({ account_type: accountType, password: unbindPassword }),
      });
      const data = await res.json();
      if (!res.ok) throw new Error(data.detail || '解绑失败');
      alert('解绑成功');
      setUnbindPassword('');
      fetchBindings();
    } catch (err) {
      setError(err instanceof Error ? err.message : '解绑失败');
    } finally {
      setLoading(false);
    }
  };

  const handleOAuthBind = async (provider: string) => {
    try {
      // 保存当前页面用于绑定后返回
      sessionStorage.setItem('oauth_bind_return', '/account-settings');
      await initiateOAuth(provider);
    } catch (err) {
      alert(err instanceof Error ? err.message : '绑定失败');
    }
  };

  if (!bindings) {
    return (
      <div className="min-h-screen flex items-center justify-center bg-slate-950">
        <div className="text-slate-400">加载中...</div>
      </div>
    );
  }

  return (
    <>
      <SEO title="账号设置" description="管理你的登录方式和账号绑定" />

      <div className="min-h-screen bg-slate-950 py-12 px-4">
        <div className="max-w-3xl mx-auto">
          <div className="mb-6">
            <h1 className="text-2xl font-bold mb-1"><GradientText>账号设置</GradientText></h1>
            <p className="text-slate-400 text-sm">管理你的登录方式和账号绑定</p>
          </div>

          {error && (
            <div className="mb-4 p-3 rounded-lg bg-rose-500/10 border border-rose-500/50 text-rose-400 text-sm">
              {error}
            </div>
          )}

          <div className="space-y-4">
            {/* 邮箱账号 */}
            <div className="card-glass p-4">
              <div className="flex items-center justify-between">
                <div className="flex items-center gap-3">
                  <div className={`w-10 h-10 rounded-lg flex items-center justify-center ${ACCOUNT_TYPES[0].colorClass}`}>
                    <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M3 8l7.89 5.26a2 2 0 002.22 0L21 8M5 19h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v10a2 2 0 002 2z" />
                    </svg>
                  </div>
                  <div>
                    <div className="flex items-center gap-2">
                      <span className="font-medium text-white">邮箱</span>
                      {bindings.email.is_primary && <span className="text-xs px-2 py-0.5 rounded bg-amber-500/20 text-amber-400">主账号</span>}
                      {bindings.email.verified && <span className="text-xs px-2 py-0.5 rounded bg-emerald-500/20 text-emerald-400">已验证</span>}
                    </div>
                    <p className="text-sm text-slate-400">{bindings.email.bound ? bindings.email.value : '未绑定'}</p>
                  </div>
                </div>
                {bindings.email.bound ? (
                  <Button variant="secondary" size="sm" onClick={() => handleUnbind('email')} disabled={bindings.email.is_primary}>解绑</Button>
                ) : (
                  <Button variant="primary" size="sm" onClick={() => setShowBindEmailForm(true)}>绑定</Button>
                )}
              </div>

              {showBindEmailForm && (
                <form onSubmit={handleBindEmail} className="mt-4 space-y-3">
                  <Input id="bind-email" label="邮箱地址" type="email" value={bindEmail} onChange={(e) => setBindEmail(e.target.value)} placeholder="your@email.com" required />
                  <Input id="bind-code" label="验证码" type="text" value={bindCode} onChange={(e) => setBindCode(e.target.value)} placeholder="6位验证码" required />
                  <Input id="bind-password" label="当前密码" type="password" value={bindPassword} onChange={(e) => setBindPassword(e.target.value)} placeholder="••••••••" required />
                  <div className="flex gap-2">
                    <Button type="submit" variant="primary" size="sm" loading={loading}>确认绑定</Button>
                    <Button type="button" variant="ghost" size="sm" onClick={() => setShowBindEmailForm(false)}>取消</Button>
                  </div>
                </form>
              )}
            </div>

            {/* 手机号绑定 */}
            <div className="card-glass p-4">
              <div className="flex items-center gap-3 mb-3">
                <div className="w-10 h-10 rounded-lg bg-emerald-500/20 flex items-center justify-center">
                  <svg className="w-5 h-5 text-emerald-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 18h.01M8 21h8a2 2 0 002-2V5a2 2 0 00-2-2H8a2 2 0 00-2 2v14a2 2 0 002 2z" />
                  </svg>
                </div>
                <div>
                  <span className="font-medium text-white">手机号</span>
                  <p className="text-sm text-slate-400">{bindings.phone.bound ? `已绑定: ${bindings.phone.value}` : '未绑定'}</p>
                </div>
              </div>
              <PhoneBindingForm currentPhone={bindings.phone.value} token={token!} onSuccess={fetchBindings} />
            </div>

            {/* OAuth 账号列表 */}
            {ACCOUNT_TYPES.filter(t => t.iconProvider).map(({ key, label, colorClass, iconProvider }) => {
              const binding = bindings[key];
              return (
                <div key={key} className="card-glass p-4">
                  <div className="flex items-center justify-between">
                    <div className="flex items-center gap-3">
                      <div className={`w-10 h-10 rounded-lg flex items-center justify-center ${colorClass}`}>
                        {iconProvider && <OAuthProviderIcon provider={iconProvider} />}
                      </div>
                      <div>
                        <span className="font-medium text-white">{label}</span>
                        <p className="text-sm text-slate-400">{binding?.bound ? binding.value : '未绑定'}</p>
                      </div>
                    </div>
                    {binding?.bound ? (
                      <Button variant="ghost" size="sm" onClick={() => handleUnbind(key)}>解绑</Button>
                    ) : (
                      <Button variant="ghost" size="sm" onClick={() => iconProvider && handleOAuthBind(iconProvider)}>绑定</Button>
                    )}
                  </div>
                </div>
              );
            })}

            {/* 安全提示 */}
            <div className="card-glass p-4 border border-amber-500/30">
              <div className="flex gap-3">
                <svg className="w-5 h-5 text-amber-400 flex-shrink-0 mt-0.5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z" />
                </svg>
                <div>
                  <h3 className="font-medium text-amber-400 mb-1">安全提示</h3>
                  <p className="text-sm text-slate-400">解绑账号前请确保至少保留一种登录方式。建议保留邮箱登录作为主账号。</p>
                </div>
              </div>
            </div>

            {/* 解绑验证密码 */}
            <div className="card-glass p-4">
              <h3 className="font-medium text-white mb-3">解绑验证</h3>
              <Input
                id="unbind-password"
                label="当前密码"
                type="password"
                value={unbindPassword}
                onChange={(e) => setUnbindPassword(e.target.value)}
                placeholder="解绑操作需要验证密码"
              />
            </div>
          </div>
        </div>
      </div>
    </>
  );
}
