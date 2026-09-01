import { ReactNode } from 'react';

interface ButtonProps extends React.ButtonHTMLAttributes<HTMLButtonElement> {
  variant?: 'primary' | 'secondary' | 'ghost' | 'accent' | 'danger';
  size?: 'sm' | 'md' | 'lg';
  loading?: boolean;
  icon?: ReactNode;
  children: ReactNode;
}

/**
 * Button 组件 - Design System v2.0
 *
 * 所有按钮自动包含：
 * - WCAG AAA 触摸目标 (min 44×44px)
 * - 完整状态 (hover/active/focus/disabled)
 * - Focus ring (键盘导航可见性)
 */
export function Button({
  variant = 'primary',
  size = 'md',
  loading = false,
  icon,
  children,
  className = '',
  disabled,
  ...props
}: ButtonProps) {
  // Use flex instead of inline-flex when w-full is present for proper width behavior
  const displayClass = className.includes('w-full') ? 'flex' : 'inline-flex';

  // 基础类 - 使用 Tailwind 的 rounded-md 替代 rounded-xl 以匹配设计系统
  const baseClasses = `${displayClass} items-center justify-center gap-2 font-semibold rounded-md transition-all duration-300 min-h-touch min-w-touch`;

  // 变体类 - 使用 Design System v2.0 的按钮类
  const variantClasses = {
    primary: 'btn-primary text-white',
    secondary: 'btn-secondary',
    ghost: 'btn-ghost',
    accent: 'btn-accent',
    // Danger 使用 error 颜色
    danger: 'bg-error-500 hover:bg-error-700 text-white hover:shadow-2 transition-all duration-300',
  };

  // 尺寸类 - 确保最小触摸目标
  const sizeClasses = {
    sm: 'px-4 py-2.5 text-sm min-h-11', // 44px
    md: 'px-6 py-3 min-h-touch',  // 44px
    lg: 'px-8 py-4 text-lg min-h-12', // 48px
  };

  // Loading 状态
  const isLoading = loading && !disabled;

  return (
    <button
      className={`${baseClasses} ${variantClasses[variant]} ${sizeClasses[size]} ${disabled || isLoading ? 'cursor-not-allowed' : ''} ${className}`}
      disabled={disabled || isLoading}
      {...props}
    >
      {isLoading ? (
        <div className="spinner w-5 h-5 border-2 border-current border-t-transparent rounded-full" />
      ) : icon}
      {children}
    </button>
  );
}
