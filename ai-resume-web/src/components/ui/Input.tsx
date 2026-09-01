import { ReactNode } from 'react';

interface InputProps extends Omit<React.InputHTMLAttributes<HTMLInputElement>, 'id'> {
  label?: string;
  error?: string;
  success?: string;
  icon?: ReactNode;
  /** 输入框右侧后缀(如密码可见性切换按钮) */
  suffix?: ReactNode;
  // id现在是必需的
  id: string;
  // 显式支持data-testid
  'data-testid'?: string;
}

/**
 * Input 组件 - Design System v2.0
 *
 * 包含完整状态系统：
 * - default (默认状态)
 * - focus (输入聚焦，带 focus ring)
 * - error (错误状态，红色边框 + 阴影)
 * - success (成功状态，绿色边框 + 阴影)
 * - disabled (禁用状态，半透明)
 *
 * 自动满足 WCAG AAA 触摸目标 (44px 高度)
 */
export function Input({ label, error, success, icon, suffix, className = '', id, 'data-testid': testId, ...props }: InputProps) {
  // 构建输入框类名
  const inputClasses = [
    'input-cyber',
    icon ? 'pl-12' : '',
    suffix ? 'pr-11' : '',
    error ? 'input-error' : '',
    success ? 'input-success' : '',
    className
  ].filter(Boolean).join(' ');

  // 确定状态消息类和内容
  const hasMessage = error || success;
  const messageClass = error ? 'text-error' : success ? 'text-success' : 'text-muted';
  const messageText = error || success;

  return (
    <div className="w-full">
      {label && (
        <label htmlFor={id} className="block text-sm font-medium text-text-secondary mb-2">
          {label}
        </label>
      )}
      <div className="relative">
        {icon && (
          <div className="absolute left-4 top-1/2 -translate-y-1/2 text-text-muted">
            {icon}
          </div>
        )}
        <input
          id={id}
          data-testid={testId}
          className={inputClasses}
          aria-invalid={error ? 'true' : undefined}
          aria-describedby={hasMessage ? `${id}-message` : undefined}
          {...props}
        />
        {suffix && (
          <div className="absolute right-3 top-1/2 -translate-y-1/2 flex items-center">
            {suffix}
          </div>
        )}
      </div>
      {hasMessage && (
        <p id={`${id}-message`} className={`mt-2 text-sm ${messageClass}`}>
          {messageText}
        </p>
      )}
    </div>
  );
}
