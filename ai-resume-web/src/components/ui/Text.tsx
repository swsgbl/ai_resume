import { ReactNode } from 'react';

interface GradientTextProps {
  children: ReactNode;
  variant?: 'primary' | 'accent' | 'full';
  className?: string;
}

export function GradientText({ children, variant = 'full', className = '' }: GradientTextProps) {
  const variantClasses = {
    primary: 'text-gradient-primary',
    accent: 'text-gradient-accent',
    full: 'text-gradient',
  };

  return <span className={`${variantClasses[variant]} ${className}`}>{children}</span>;
}
