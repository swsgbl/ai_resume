import { ReactNode } from 'react';

export function Divider({ className = '' }: { className?: string }) {
  return <div className={`divider-gradient my-6 ${className}`} />;
}

interface OrbProps {
  color?: 'primary' | 'accent';
  size?: number;
  className?: string;
}

export function Orb({ color = 'primary', size = 150, className = '' }: OrbProps) {
  const colorClasses = {
    primary: 'orb-primary',
    accent: 'orb-accent',
  };

  return (
    <div
      className={`bg-orb ${colorClasses[color]} ${className}`}
      style={{ width: size, height: size }}
    />
  );
}

interface IconWrapperProps {
  children: ReactNode;
  variant?: 'primary' | 'accent' | 'glass';
  size?: 'sm' | 'md' | 'lg';
  className?: string;
}

/**
 * IconWrapper - Design System v2.0
 *
 * 使用设计系统颜色：
 * - primary: primary-500/20 背景
 * - accent: accent-500/20 背景
 * - glass: 半透明玻璃效果
 *
 * 符合 Touch Target 标准
 */
export function IconWrapper({ children, variant = 'glass', size = 'md', className = '' }: IconWrapperProps) {
  const sizeClasses = {
    sm: 'w-10 h-10',
    md: 'w-12 h-12',
    lg: 'w-16 h-16',
  };

  const variantClasses = {
    primary: 'bg-[var(--color-primary-500)]/20 text-[var(--color-primary-400)]',
    accent: 'bg-[var(--color-accent-500)]/20 text-[var(--color-accent-400)]',
    glass: 'glass-effect text-[var(--color-text-secondary)]',
  };

  return (
    <div className={`${sizeClasses[size]} ${variantClasses[variant]} rounded-xl flex items-center justify-center min-w-touch min-h-touch ${className}`}>
      {children}
    </div>
  );
}

interface StatusIndicatorProps {
  status: 'online' | 'offline' | 'away' | 'busy';
  showText?: boolean;
}

/**
 * StatusIndicator - Design System v2.0
 *
 * 使用语义颜色系统：
 * - online: success-500
 * - offline: text-muted
 * - away: warning-500
 * - busy: error-500
 */
export function StatusIndicator({ status, showText = false }: StatusIndicatorProps) {
  const statusConfig = {
    online: { color: 'bg-[var(--color-success-500)]', text: '在线' },
    offline: { color: 'bg-[var(--color-text-muted)]', text: '离线' },
    away: { color: 'bg-[var(--color-warning-500)]', text: '离开' },
    busy: { color: 'bg-[var(--color-error-500)]', text: '忙碌' },
  };

  const config = statusConfig[status];

  return (
    <div className="flex items-center gap-2">
      <span className={`relative flex h-3 w-3`}>
        <span className={`absolute inline-flex h-full w-full rounded-full ${config.color} opacity-75 animate-ping`}></span>
        <span className={`relative inline-flex rounded-full h-3 w-3 ${config.color}`}></span>
      </span>
      {showText && <span className="text-sm text-[var(--color-text-secondary)]">{config.text}</span>}
    </div>
  );
}
