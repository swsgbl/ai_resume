/**
 * Button 组件测试
 */
import { describe, it, expect, vi } from 'vitest';
import { render, screen } from '@testing-library/react';
import '@testing-library/jest-dom';
import userEvent from '@testing-library/user-event';
import { Button } from './Button';

describe('Button Component', () => {
  it('渲染基本按钮', () => {
    render(<Button>点击我</Button>);

    expect(screen.getByRole('button')).toHaveTextContent('点击我');
  });

  it('渲染不同变体的按钮', () => {
    const { rerender } = render(<Button variant="primary">Primary</Button>);
    expect(screen.getByRole('button')).toHaveClass('btn-primary');

    rerender(<Button variant="secondary">Secondary</Button>);
    expect(screen.getByRole('button')).toHaveClass('btn-secondary');

    rerender(<Button variant="ghost">Ghost</Button>);
    expect(screen.getByRole('button')).toHaveClass('btn-ghost');

    rerender(<Button variant="accent">Accent</Button>);
    expect(screen.getByRole('button')).toHaveClass('btn-accent');

    rerender(<Button variant="danger">Danger</Button>);
    expect(screen.getByRole('button')).toHaveClass('bg-error-500', 'hover:bg-error-700');
  });

  it('渲染不同尺寸的按钮', () => {
    const { rerender } = render(<Button size="sm">Small</Button>);
    expect(screen.getByRole('button')).toHaveClass('px-4', 'py-2.5', 'text-sm', 'min-h-11');

    rerender(<Button size="md">Medium</Button>);
    expect(screen.getByRole('button')).toHaveClass('px-6', 'py-3');

    rerender(<Button size="lg">Large</Button>);
    expect(screen.getByRole('button')).toHaveClass('px-8', 'py-4', 'text-lg');
  });

  it('显示加载状态', () => {
    render(<Button loading>加载中</Button>);

    const button = screen.getByRole('button');
    expect(button).toBeDisabled();
    expect(button.querySelector('.spinner')).toBeInTheDocument();
  });

  it('加载时禁用按钮', () => {
    render(<Button loading>点击</Button>);

    expect(screen.getByRole('button')).toHaveClass('cursor-not-allowed');
  });

  it('显示图标', () => {
    render(
      <Button icon={<span data-testid="test-icon">★</span>}>
        带图标
      </Button>
    );

    expect(screen.getByTestId('test-icon')).toBeInTheDocument();
  });

  it('禁用状态', () => {
    render(<Button disabled>禁用按钮</Button>);

    expect(screen.getByRole('button')).toBeDisabled();
  });

  it('点击事件触发', async () => {
    const handleClick = vi.fn();
    const user = userEvent.setup();

    render(<Button onClick={handleClick}>点击</Button>);

    await user.click(screen.getByRole('button'));

    expect(handleClick).toHaveBeenCalledTimes(1);
  });

  it('禁用时不触发点击事件', async () => {
    const handleClick = vi.fn();
    const user = userEvent.setup();

    render(<Button onClick={handleClick} disabled>禁用</Button>);

    await user.click(screen.getByRole('button'));

    expect(handleClick).not.toHaveBeenCalled();
  });

  it('加载时不触发点击事件', async () => {
    const handleClick = vi.fn();
    const user = userEvent.setup();

    render(<Button onClick={handleClick} loading>加载中</Button>);

    await user.click(screen.getByRole('button'));

    expect(handleClick).not.toHaveBeenCalled();
  });

  it('应用自定义类名', () => {
    render(<Button className="custom-class">自定义</Button>);

    expect(screen.getByRole('button')).toHaveClass('custom-class');
  });

  it('全宽按钮使用 flex 布局', () => {
    render(<Button className="w-full">全宽</Button>);

    expect(screen.getByRole('button')).toHaveClass('flex');
  });

  it('非全宽按钮使用 inline-flex 布局', () => {
    render(<Button>正常</Button>);

    expect(screen.getByRole('button')).toHaveClass('inline-flex');
  });

  it('传递额外的 HTML 属性', () => {
    render(
      <Button data-testid="test-button" name="submit" form="login-form">
        提交
      </Button>
    );

    const button = screen.getByTestId('test-button');
    expect(button).toHaveAttribute('name', 'submit');
    expect(button).toHaveAttribute('form', 'login-form');
  });
});
