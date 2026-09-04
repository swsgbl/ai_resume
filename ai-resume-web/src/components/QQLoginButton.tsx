import { useState } from 'react';
import { initiateOAuth } from '../config/oauth.config';
import './QQLoginButton.css';

interface QQLoginButtonProps {
  size?: 'lg' | 'md';
  className?: string;
}

export default function QQLoginButton({ size = 'md', className = '' }: QQLoginButtonProps) {
  const [redirecting, setRedirecting] = useState(false);

  const handleClick = async () => {
    setRedirecting(true);
    try {
      await initiateOAuth('qq');
    } catch (err) {
      alert(err instanceof Error ? err.message : 'QQ 授权失败，请重试');
      setRedirecting(false);
    }
  };

  const source =
    size === 'lg'
      ? '/images/qq/qq-login-230x48.png'
      : '/images/qq/qq-login-170x32.png';

  return (
    <button
      type="button"
      onClick={handleClick}
      disabled={redirecting}
      aria-busy={redirecting}
      aria-label="用QQ帐号登录"
      data-testid="qq-login-button"
      className={`qq-login-button qq-login-button--${size} ${className}`.trim()}
    >
      <img src={source} alt="用QQ帐号登录" width={size === 'lg' ? 230 : 170} height={size === 'lg' ? 48 : 32} draggable={false} />
    </button>
  );
}
