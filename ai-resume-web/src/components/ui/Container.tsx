import { ReactNode } from 'react';

/**
 * Container 组件 - Design System v2.0
 *
 * 使用 4px 间距网格令牌：
 * - Section 默认使用 py-section-lg (96px)
 * - 符合 Mobile First 响应式设计
 */

interface GlassContainerProps {
  children: ReactNode;
  className?: string;
}

export function GlassContainer({ children, className = '' }: GlassContainerProps) {
  return (
    <div className={`card-glass ${className}`}>
      {children}
    </div>
  );
}

interface NeonContainerProps {
  children: ReactNode;
  color?: 'blue' | 'purple' | 'pink' | 'green';
  className?: string;
}

export function NeonContainer({ children, color = 'blue', className = '' }: NeonContainerProps) {
  const colorClasses = {
    blue: 'shadow-neon-blue',
    purple: 'shadow-neon-purple',
    pink: 'shadow-neon-pink',
    green: 'shadow-green-500/50',
  };

  return (
    <div className={`rounded-2xl p-6 bg-[var(--color-surface-2)] border border-[var(--color-border)] ${colorClasses[color]} ${className}`}>
      {children}
    </div>
  );
}

interface SectionProps {
  children: ReactNode;
  className?: string;
  container?: boolean;
  size?: 'sm' | 'md' | 'lg' | 'xl';
}

export function Section({ children, className = '', container = true, size = 'lg' }: SectionProps) {
  const sizeClasses = {
    sm: 'py-section-sm',  // 48px
    md: 'py-section',     // 64px
    lg: 'py-section-lg',  // 96px
    xl: 'py-section-xl',  // 120px
  };

  return (
    <section className={`${sizeClasses[size]} ${className}`}>
      {container ? (
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          {children}
        </div>
      ) : children}
    </section>
  );
}
