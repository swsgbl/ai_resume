import { useState } from 'react';
import { Button, Input } from './UIComponents';

interface PhoneBindingFormProps {
  currentPhone?: string | null;
  token: string;
  onSuccess: () => void;
}

const PHONE_REGEX = /^1[3-9]\d{9}$/;

/**
 * 手机号绑定/修改/解绑组件
 * 纯前端格式校验，无需短信验证码
 */
export default function PhoneBindingForm({ currentPhone, token, onSuccess }: PhoneBindingFormProps) {
  const [phone, setPhone] = useState(currentPhone || '');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [success, setSuccess] = useState<string | null>(null);

  const isBound = !!currentPhone;
  const apiBaseUrl = import.meta.env.VITE_API_URL || '';

  const handleBind = async (e: React.FormEvent) => {
    e.preventDefault();
    setError(null);
    setSuccess(null);

    const trimmed = phone.trim();
    if (!PHONE_REGEX.test(trimmed)) {
      setError('请输入正确的11位手机号（中国大陆 1[3-9]开头）');
      return;
    }

    setLoading(true);
    try {
      const res = await fetch(`${apiBaseUrl}/api/v1/account/bind/phone`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${token}`,
        },
        body: JSON.stringify({ phone: trimmed }),
      });
      const data = await res.json();
      if (!res.ok) throw new Error(data.detail || '绑定失败');

      setSuccess('手机号绑定成功');
      onSuccess();
    } catch (err) {
      setError(err instanceof Error ? err.message : '绑定失败');
    } finally {
      setLoading(false);
    }
  };

  const handleUnbind = async () => {
    setError(null);
    setSuccess(null);

    if (!confirm('确定要解绑手机号吗？')) return;

    setLoading(true);
    try {
      const res = await fetch(`${apiBaseUrl}/api/v1/account/unbind`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${token}`,
        },
        body: JSON.stringify({ account_type: 'phone', password: '' }),
      });
      const data = await res.json();
      if (!res.ok) throw new Error(data.detail || '解绑失败');

      setPhone('');
      setSuccess('手机号已解绑');
      onSuccess();
    } catch (err) {
      setError(err instanceof Error ? err.message : '解绑失败');
    } finally {
      setLoading(false);
    }
  };

  return (
    <form onSubmit={handleBind} className="space-y-3">
      <Input
        id="phone-binding"
        label="手机号"
        type="tel"
        value={phone}
        onChange={(e) => {
          setPhone(e.target.value);
          setError(null);
        }}
        placeholder="请输入11位手机号"
        maxLength={11}
      />

      {error && <p className="text-rose-400 text-xs">{error}</p>}
      {success && <p className="text-emerald-400 text-xs">{success}</p>}

      <div className="flex gap-2">
        <Button
          type="submit"
          variant="primary"
          size="sm"
          loading={loading}
        >
          {isBound ? '修改手机号' : '绑定手机号'}
        </Button>
        {isBound && (
          <Button
            type="button"
            variant="ghost"
            size="sm"
            onClick={handleUnbind}
            disabled={loading}
          >
            解绑
          </Button>
        )}
        {phone && (
          <Button
            type="button"
            variant="ghost"
            size="sm"
            onClick={() => { setPhone(''); setError(null); }}
          >
            清空
          </Button>
        )}
      </div>
    </form>
  );
}
