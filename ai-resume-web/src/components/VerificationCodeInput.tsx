import { useState, useEffect, useCallback } from 'react';
import { Button, Input } from './UIComponents';

interface VerificationCodeInputProps {
  phone: string;
  onCodeChange: (code: string) => void;
  onSmsTokenChange?: (token: string) => void;
  code: string;
}

const API_BASE = () => import.meta.env.VITE_API_URL || '';

/**
 * 短信验证码输入 + 发送按钮 + 60秒冷却
 */
export default function VerificationCodeInput({ phone, onCodeChange, onSmsTokenChange, code }: VerificationCodeInputProps) {
  const [countdown, setCountdown] = useState(0);
  const [sending, setSending] = useState(false);
  const [sendError, setSendError] = useState<string | null>(null);
  const [sendSuccess, setSendSuccess] = useState(false);

  useEffect(() => {
    if (countdown <= 0) return;
    const timer = setTimeout(() => setCountdown((c) => c - 1), 1000);
    return () => clearTimeout(timer);
  }, [countdown]);

  const handleSend = useCallback(async () => {
    if (countdown > 0 || !phone) return;

    // 前端格式校验
    if (!/^1[3-9]\d{9}$/.test(phone)) {
      setSendError('请先输入正确的11位手机号');
      return;
    }

    setSending(true);
    setSendError(null);
    setSendSuccess(false);

    try {
      const res = await fetch(`${API_BASE()}/api/v1/auth/sms/send`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ phone }),
      });
      const data = await res.json();

      if (!res.ok) {
        throw new Error(data.detail || '发送失败');
      }

      setSendSuccess(true);
      const cooldown = data?.data?.cooldown || 60;
      setCountdown(cooldown);
      if (data?.data?.sms_token && onSmsTokenChange) {
        onSmsTokenChange(data.data.sms_token);
      }
    } catch (err) {
      setSendError(err instanceof Error ? err.message : '发送失败');
    } finally {
      setSending(false);
    }
  }, [phone, countdown, onSmsTokenChange]);

  return (
    <div className="space-y-2">
      <div className="flex gap-2">
        <div className="flex-1">
          <Input
            id="sms-code"
            label="验证码"
            type="text"
            value={code}
            onChange={(e) => {
              onCodeChange(e.target.value.replace(/\D/g, '').slice(0, 6));
              setSendError(null);
            }}
            placeholder="6位数字验证码"
            maxLength={6}
            required
          />
        </div>
        <div className="flex items-end">
          <Button
            type="button"
            variant={countdown > 0 ? 'ghost' : 'primary'}
            size="md"
            onClick={handleSend}
            loading={sending}
            disabled={countdown > 0 || !phone}
            className="whitespace-nowrap min-w-[120px]"
          >
            {countdown > 0 ? `${countdown}s` : sending ? '发送中' : '获取验证码'}
          </Button>
        </div>
      </div>

      {sendError && <p className="text-rose-400 text-xs">{sendError}</p>}
      {sendSuccess && countdown > 0 && (
        <p className="text-emerald-400 text-xs">验证码已发送，5分钟内有效</p>
      )}
    </div>
  );
}
