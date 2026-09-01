/**
 * Badge 组件测试
 */
import { describe, it, expect } from 'vitest';
import { render, screen } from '@testing-library/react';
import '@testing-library/jest-dom';
import { Badge } from './Badge';

describe('Badge Component', () => {
  it('渲染徽章内容', () => {
    render(<Badge>新功能</Badge>);

    expect(screen.getByText('新功能')).toBeInTheDocument();
  });

  it('使用默认 neon 样式', () => {
    const { container } = render(<Badge>Neon Badge</Badge>);

    const badge = container.firstChild as HTMLElement;
    expect(badge).toHaveClass('badge-neon', 'text-white');
  });

  it('应用 outline 变体样式', () => {
    const { container } = render(<Badge variant="outline">Outline</Badge>);

    const badge = container.firstChild as HTMLElement;
    expect(badge).toHaveClass('badge-outline');
  });

  it('应用 success 变体样式', () => {
    const { container } = render(<Badge variant="success">Success</Badge>);

    const badge = container.firstChild as HTMLElement;
    expect(badge).toHaveClass(
      'px-3',
      'py-1',
      'rounded-full',
      'text-xs',
      'font-semibold',
      'bg-success-soft',
      'border',
      'border-success-500/50'
    );
  });

  it('应用 warning 变体样式', () => {
    const { container } = render(<Badge variant="warning">Warning</Badge>);

    const badge = container.firstChild as HTMLElement;
    expect(badge).toHaveClass(
      'px-3',
      'py-1',
      'rounded-full',
      'text-xs',
      'font-semibold',
      'bg-warning-soft',
      'border',
      'border-warning-500/50'
    );
  });

  it('应用 error 变体样式', () => {
    const { container } = render(<Badge variant="error">Error</Badge>);

    const badge = container.firstChild as HTMLElement;
    expect(badge).toHaveClass(
      'px-3',
      'py-1',
      'rounded-full',
      'text-xs',
      'font-semibold',
      'bg-error-soft',
      'border',
      'border-error-500/50'
    );
  });

  it('渲染 span 元素', () => {
    const { container } = render(<Badge>内容</Badge>);

    const badge = container.firstChild as HTMLElement;
    expect(badge.tagName).toBe('SPAN');
  });

  it('渲染文本内容', () => {
    render(<Badge>Beta</Badge>);

    expect(screen.getByText('Beta')).toBeInTheDocument();
  });

  it('渲染数字内容', () => {
    render(<Badge>99+</Badge>);

    expect(screen.getByText('99+')).toBeInTheDocument();
  });

  it('渲染图标和文本组合', () => {
    render(
      <Badge>
        ★ 精选
      </Badge>
    );

    expect(screen.getByText('★ 精选')).toBeInTheDocument();
  });

  it('success 变体有正确的颜色类', () => {
    const { container } = render(<Badge variant="success">成功</Badge>);

    const badge = container.firstChild as HTMLElement;
    expect(badge).toHaveClass('bg-success-soft', 'border-success-500/50');
  });

  it('warning 变体有正确的颜色类', () => {
    const { container } = render(<Badge variant="warning">警告</Badge>);

    const badge = container.firstChild as HTMLElement;
    expect(badge).toHaveClass('bg-warning-soft', 'border-warning-500/50');
  });

  it('error 变体有正确的颜色类', () => {
    const { container } = render(<Badge variant="error">错误</Badge>);

    const badge = container.firstChild as HTMLElement;
    expect(badge).toHaveClass('bg-error-soft', 'border-error-500/50');
  });

  it('所有变体都有 rounded-full 类', () => {
    const { container: successContainer } = render(<Badge variant="success">Success</Badge>);
    const { container: warningContainer } = render(<Badge variant="warning">Warning</Badge>);
    const { container: errorContainer } = render(<Badge variant="error">Error</Badge>);

    expect(successContainer.firstChild).toHaveClass('rounded-full');
    expect(warningContainer.firstChild).toHaveClass('rounded-full');
    expect(errorContainer.firstChild).toHaveClass('rounded-full');
  });

  it('所有状态变体都有 text-xs 和 font-semibold 类', () => {
    const { container: successContainer } = render(<Badge variant="success">Success</Badge>);
    const { container: warningContainer } = render(<Badge variant="warning">Warning</Badge>);
    const { container: errorContainer } = render(<Badge variant="error">Error</Badge>);

    expect(successContainer.firstChild).toHaveClass('text-xs', 'font-semibold');
    expect(warningContainer.firstChild).toHaveClass('text-xs', 'font-semibold');
    expect(errorContainer.firstChild).toHaveClass('text-xs', 'font-semibold');
  });
});
