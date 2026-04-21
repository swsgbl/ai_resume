import { useState } from 'react';
import { Button, Input } from '../components/UIComponents';

interface EmailCompletionModalProps {
  providerName: string;
  onSubmit: (email: string) => Promise<void>;
  onSkip: () => void;
}

/**
 * OAuth 授权后无邮箱时，弹出补全邮箱弹窗
 */
export default function EmailCompletionModal({ providerName, onSubmit, onSkip }: EmailCompletionModalProps) {
  const [email, setEmail] = useState('');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError(null);

    if (!email || !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)) {
      setError('请输入有效的邮箱地址');
      return;
    }

    setLoading(true);
    try {
      await onSubmit(email);
    } catch (err) {
      setError(err instanceof Error ? err.message : '绑定邮箱失败');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/60 backdrop-blur-sm">
      <div className="card-glass w-full max-w-md mx-4 p-6">
        <h2 className="text-lg font-bold text-white mb-2">完善邮箱信息</h2>
        <p className="text-slate-400 text-sm mb-4">
          你的 {providerName} 账号未提供邮箱地址。填写邮箱后可接收重要通知并提高账号安全性。
        </p>

        <form onSubmit={handleSubmit} className="space-y-4">
          <Input
            id="oauth-email"
            label="邮箱地址"
            type="email"
            value={email}
            onChange={(e) => { setEmail(e.target.value); setError(null); }}
            placeholder="your@email.com"
            required
          />

          {error && (
            <p className="text-rose-400 text-xs">{error}</p>
          )}

          <div className="flex gap-3">
            <Button
              type="submit"
              variant="primary"
              size="md"
              loading={loading}
              className="flex-1"
            >
              {loading ? '绑定中...' : '绑定邮箱'}
            </Button>
            <Button
              type="button"
              variant="ghost"
              size="md"
              onClick={onSkip}
            >
              稍后再说
            </Button>
          </div>
        </form>
      </div>
    </div>
  );
}
