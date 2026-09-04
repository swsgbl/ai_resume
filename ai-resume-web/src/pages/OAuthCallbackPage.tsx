import { useEffect, useState } from 'react';
import { useNavigate, useSearchParams } from 'react-router-dom';
import { useAuthStore } from '../store/auth';
import { SEO } from '../components/SEO';
import { Spinner } from '../components/UIComponents';
import EmailCompletionModal from '../components/EmailCompletionModal';

function getApiBaseUrl(): string {
  return import.meta.env.VITE_API_URL || '';
}

/**
 * OAuth 回调处理页面
 *
 * 支持两种流程：
 * 1. 授权码流程：从第三方回调带 code+state，前端换取 token
 * 2. 直接 token 流程：后端已处理完成，URL 带 access_token（兼容旧流程）
 */
export default function OAuthCallbackPage() {
  const navigate = useNavigate();
  const [searchParams] = useSearchParams();
  const { loginWithOAuth } = useAuthStore();

  const [status, setStatus] = useState<'loading' | 'error' | 'need_email'>('loading');
  const [errorMsg, setErrorMsg] = useState('');
  const [pendingTokens, setPendingTokens] = useState<{ access: string; refresh?: string } | null>(null);
  const [providerName, setProviderName] = useState('');

  useEffect(() => {
    handleCallback();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  const handleCallback = async () => {
    const code = searchParams.get('code');
    const state = searchParams.get('state');
    const error = searchParams.get('error');
    const accessToken = searchParams.get('access_token');
    const refreshToken = searchParams.get('refresh_token');

    // OAuth 授权错误
    if (error) {
      setErrorMsg(searchParams.get('error_description') || error);
      setStatus('error');
      return;
    }

    // 直接 token 流程（兼容旧模式）
    if (accessToken) {
      loginWithOAuth(accessToken, refreshToken || undefined);
      navigate('/dashboard', { replace: true });
      return;
    }

    // 授权码流程
    if (code && state) {
      const savedState = sessionStorage.getItem('oauth_state');
      const provider = sessionStorage.getItem('oauth_provider') || 'github';

      // 验证 state 防止 CSRF
      if (savedState && savedState !== state) {
        setErrorMsg('安全验证失败，请重新登录');
        setStatus('error');
        return;
      }

      // 清理 sessionStorage
      sessionStorage.removeItem('oauth_state');
      sessionStorage.removeItem('oauth_provider');

      try {
        const baseUrl = getApiBaseUrl();
        // QQ 后台登记的是后端回调地址；后端 GET 回跳会转到本页。
        // 换 token 时不传 redirect_uri，让服务端使用登记地址。
        const frontendCallbackUrl = `${window.location.origin}/oauth/callback`;

        const res = await fetch(`${baseUrl}/api/v1/auth/oauth/${provider}/callback`, {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({
            code,
            state,
            redirect_uri: provider === 'qq' ? undefined : frontendCallbackUrl,
          }),
        });

        const data = await res.json();

        if (!res.ok) {
          // 邮箱已被注册的特殊处理
          if (data.detail?.includes('邮箱已被注册')) {
            setErrorMsg(data.detail);
            setStatus('error');
            return;
          }
          throw new Error(data.detail || 'OAuth 登录失败');
        }

        const tokenData = data.data;
        loginWithOAuth(tokenData.access_token, tokenData.refresh_token);

        // 检查是否需要补全邮箱
        const userResponse = await fetch(`${baseUrl}/api/v1/auth/me`, {
          headers: { 'Authorization': `Bearer ${tokenData.access_token}` },
        });
        if (userResponse.ok) {
          const userData = (await userResponse.json()).data;
          // 如果邮箱是占位符，弹出邮箱补全弹窗
          if (userData.email?.endsWith('.local')) {
            setProviderName(provider.charAt(0).toUpperCase() + provider.slice(1));
            setPendingTokens({ access: tokenData.access_token, refresh: tokenData.refresh_token });
            setStatus('need_email');
            return;
          }
        }

        navigate('/dashboard', { replace: true });
      } catch (err) {
        setErrorMsg(err instanceof Error ? err.message : '登录失败，请重试');
        setStatus('error');
      }
      return;
    }

    // 无有效参数，返回登录页
    navigate('/login', { replace: true });
  };

  const handleEmailSubmit = async (email: string) => {
    if (!pendingTokens) return;
    const baseUrl = getApiBaseUrl();
    const res = await fetch(`${baseUrl}/api/v1/account/bind/email`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${pendingTokens.access}`,
      },
      body: JSON.stringify({ email, password: '', verification_code: 'oauth_skip' }),
    });
    if (!res.ok) {
      const data = await res.json();
      throw new Error(data.detail || '绑定邮箱失败');
    }
    setStatus('loading');
    navigate('/dashboard', { replace: true });
  };

  return (
    <>
      <SEO title="登录处理中" description="正在处理第三方登录..." noIndex />

      <div className="min-h-screen flex items-center justify-center bg-slate-950">
        {status === 'loading' && (
          <div className="text-center">
            <Spinner size="lg" />
            <p className="mt-4 text-slate-400">正在处理登录...</p>
          </div>
        )}

        {status === 'error' && (
          <div className="text-center max-w-md mx-auto px-4">
            <div className="card-glass p-6">
              <div className="w-12 h-12 mx-auto mb-4 rounded-full bg-rose-500/20 flex items-center justify-center">
                <svg className="w-6 h-6 text-rose-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
                </svg>
              </div>
              <h2 className="text-lg font-bold text-white mb-2">登录失败</h2>
              <p className="text-slate-400 text-sm mb-4">{errorMsg}</p>
              <button
                onClick={() => navigate('/login', { replace: true })}
                className="px-4 py-2 bg-amber-500 text-white rounded-lg text-sm font-medium hover:bg-amber-600 transition-colors"
              >
                返回登录
              </button>
            </div>
          </div>
        )}

        {status === 'need_email' && (
          <EmailCompletionModal
            providerName={providerName}
            onSubmit={handleEmailSubmit}
            onSkip={() => navigate('/dashboard', { replace: true })}
          />
        )}
      </div>
    </>
  );
}
