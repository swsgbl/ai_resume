import { ReactNode } from 'react';

interface CardProps {
  variant?: 'glass' | 'neon' | 'hover' | 'solid';
  children: ReactNode;
  className?: string;
  onClick?: () => void;
}

export function Card({ variant = 'solid', children, className = '', onClick }: CardProps) {
  const variantClasses = {
    glass: 'card-glass',
    neon: 'card-neon',
    hover: 'card-hover cursor-pointer',
    solid: 'rounded-2xl p-6 bg-slate-800/50 border border-slate-700/50',
  };

  return (
    <div className={`${variantClasses[variant]} ${onClick ? 'cursor-pointer' : ''} ${className}`} onClick={onClick}>
      {children}
    </div>
  );
}
