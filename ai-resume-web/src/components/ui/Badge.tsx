import { ReactNode } from 'react';

interface BadgeProps {
  variant?: 'neon' | 'outline' | 'success' | 'warning' | 'error';
  children: ReactNode;
}

/**
 * Badge 组件 - Design System v2.0
 *
 * 使用语义颜色系统：
 * - success: 基于 accent 绿色
 * - warning: 暖橙系列
 * - error: 基于 primary 红色
 *
 * 所有变体符合 WCAG AAA 可读性标准
 */
export function Badge({ variant = 'neon', children }: BadgeProps) {
  const variantClasses = {
    // 向后兼容的旧变体
    neon: 'badge-neon text-white',
    outline: 'badge-outline',
    // 使用新的 Design System v2.0 语义颜色
    success: 'px-3 py-1 rounded-full text-xs font-semibold bg-success-soft border border-success-500/50 min-w-touch min-h-touch inline-flex items-center justify-center',
    warning: 'px-3 py-1 rounded-full text-xs font-semibold bg-warning-soft border border-warning-500/50 min-w-touch min-h-touch inline-flex items-center justify-center',
    error: 'px-3 py-1 rounded-full text-xs font-semibold bg-error-soft border border-error-500/50 min-w-touch min-h-touch inline-flex items-center justify-center',
  };

  return <span className={variantClasses[variant]}>{children}</span>;
}
