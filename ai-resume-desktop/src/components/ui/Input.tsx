import { ReactNode } from 'react';

interface InputProps extends Omit<React.InputHTMLAttributes<HTMLInputElement>, 'id'> {
  label?: string;
  error?: string;
  icon?: ReactNode;
  // id现在是必需的
  id: string;
  // 显式支持data-testid
  'data-testid'?: string;
}

export function Input({ label, error, icon, className = '', id, 'data-testid': testId, ...props }: InputProps) {
  return (
    <div className="w-full">
      {label && (
        <label htmlFor={id} className="block text-sm font-medium text-slate-300 mb-2">
          {label}
        </label>
      )}
      <div className="relative">
        {icon && (
          <div className="absolute left-4 top-1/2 -translate-y-1/2 text-slate-400">
            {icon}
          </div>
        )}
        <input
          id={id}
          data-testid={testId}
          className={`input-cyber ${icon ? 'pl-12' : ''} ${error ? 'border-rose-500' : ''} ${className}`}
          {...props}
        />
      </div>
      {error && (
        <p className="mt-2 text-sm text-rose-400">{error}</p>
      )}
    </div>
  );
}
