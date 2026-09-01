/**
 * Loading/Spinner 组件测试
 */
import { describe, it, expect } from 'vitest';
import { render } from '@testing-library/react';
import '@testing-library/jest-dom';
import { Spinner } from './Loading';

describe('Spinner Component', () => {
  it('渲染加载动画', () => {
    const { container } = render(<Spinner />);

    const spinner = container.querySelector('.spinner');
    expect(spinner).toBeInTheDocument();
  });

  it('应用小尺寸样式', () => {
    const { container } = render(<Spinner size="sm" />);

    const spinner = container.querySelector('.spinner') as HTMLElement;
    expect(spinner).toHaveClass('w-5', 'h-5');
  });

  it('应用中尺寸样式（默认）', () => {
    const { container } = render(<Spinner size="md" />);

    const spinner = container.querySelector('.spinner') as HTMLElement;
    expect(spinner).toHaveClass('w-8', 'h-8');
  });

  it('应用大尺寸样式', () => {
    const { container } = render(<Spinner size="lg" />);

    const spinner = container.querySelector('.spinner') as HTMLElement;
    expect(spinner).toHaveClass('w-12', 'h-12');
  });

  it('包含正确的边框样式', () => {
    const { container } = render(<Spinner />);

    const spinner = container.querySelector('.spinner') as HTMLElement;
    expect(spinner).toHaveClass(
      'border-4',
      'border-[var(--color-border)]',
      'border-t-[var(--color-primary-500)]'
    );
  });

  it('应用圆形边框', () => {
    const { container } = render(<Spinner />);

    const spinner = container.querySelector('.spinner') as HTMLElement;
    expect(spinner).toHaveClass('rounded-full');
  });

  it('默认为中尺寸', () => {
    const { container } = render(<Spinner />);

    const spinner = container.querySelector('.spinner') as HTMLElement;
    expect(spinner).toHaveClass('w-8', 'h-8');
  });
});
