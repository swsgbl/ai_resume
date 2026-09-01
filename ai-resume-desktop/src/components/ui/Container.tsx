import { ReactNode } from 'react';

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
    <div className={`rounded-2xl p-6 bg-slate-900/50 border ${colorClasses[color]} ${className}`}>
      {children}
    </div>
  );
}

interface SectionProps {
  children: ReactNode;
  className?: string;
  container?: boolean;
}

export function Section({ children, className = '', container = true }: SectionProps) {
  return (
    <section className={`py-20 ${className}`}>
      {container ? (
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          {children}
        </div>
      ) : children}
    </section>
  );
}
