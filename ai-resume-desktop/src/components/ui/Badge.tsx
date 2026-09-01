import { ReactNode } from 'react';

interface BadgeProps {
  variant?: 'neon' | 'outline' | 'success' | 'warning' | 'error';
  children: ReactNode;
}

export function Badge({ variant = 'neon', children }: BadgeProps) {
  const variantClasses = {
    neon: 'badge-neon text-white',
    outline: 'badge-outline',
    success: 'px-3 py-1 rounded-full text-xs font-semibold bg-green-500/20 text-green-400 border border-green-500/50',
    warning: 'px-3 py-1 rounded-full text-xs font-semibold bg-amber-500/20 text-amber-400 border border-amber-500/50',
    error: 'px-3 py-1 rounded-full text-xs font-semibold bg-rose-500/20 text-rose-400 border border-rose-500/50',
  };

  return <span className={variantClasses[variant]}>{children}</span>;
}
