import { ReactNode } from 'react';

interface ButtonProps extends React.ButtonHTMLAttributes<HTMLButtonElement> {
  variant?: 'primary' | 'secondary' | 'ghost' | 'accent' | 'danger';
  size?: 'sm' | 'md' | 'lg';
  loading?: boolean;
  icon?: ReactNode;
  children: ReactNode;
}

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
  const baseClasses = `${displayClass} items-center justify-center gap-2 font-semibold rounded-xl transition-all duration-300 cursor-pointer`;

  const variantClasses = {
    primary: 'btn-primary text-white',
    secondary: 'btn-secondary',
    ghost: 'btn-ghost',
    accent: 'btn-accent',
    danger: 'px-6 py-3 rounded-xl font-semibold bg-gradient-to-r from-rose-500 to-red-600 text-white hover:scale-105 shadow-lg shadow-rose-500/30',
  };

  const sizeClasses = {
    sm: 'px-4 py-2 text-sm',
    md: 'px-6 py-3',
    lg: 'px-8 py-4 text-lg',
  };

  return (
    <button
      className={`${baseClasses} ${variantClasses[variant]} ${sizeClasses[size]} ${disabled || loading ? 'opacity-50 cursor-not-allowed' : ''} ${className}`}
      disabled={disabled || loading}
      {...props}
    >
      {loading ? (
        <div className="spinner w-5 h-5 border-2 border-current border-t-transparent rounded-full" />
      ) : icon}
      {children}
    </button>
  );
}
