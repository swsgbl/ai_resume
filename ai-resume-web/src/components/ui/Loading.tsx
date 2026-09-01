interface SpinnerProps {
  size?: 'sm' | 'md' | 'lg';
}

/**
 * Spinner 组件 - Design System v2.0
 *
 * 使用设计系统颜色：
 * - 边框: surface-0 (暗色)
 * - 顶部强调色: primary-500 (印泥朱砂)
 *
 * 尺寸符合 Touch Target 标准
 */
export function Spinner({ size = 'md' }: SpinnerProps) {
  const sizeClasses = {
    sm: 'w-5 h-5',
    md: 'w-8 h-8',
    lg: 'w-12 h-12',
  };

  return <div className={`spinner ${sizeClasses[size]} border-4 rounded-full border-[var(--color-border)] border-t-[var(--color-primary-500)]`} />;
}
