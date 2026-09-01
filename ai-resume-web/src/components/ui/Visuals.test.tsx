/**
 * Visuals 组件测试
 */
import { describe, it, expect } from 'vitest';
import { render, screen } from '@testing-library/react';
import '@testing-library/jest-dom';
import { Divider, Orb, IconWrapper, StatusIndicator } from './Visuals';

describe('Divider', () => {
  it('渲染分割线', () => {
    const { container } = render(<Divider />);

    const divider = container.firstChild as HTMLElement;
    expect(divider).toBeInTheDocument();
  });

  it('应用 divider-gradient 样式', () => {
    const { container } = render(<Divider />);

    const divider = container.firstChild as HTMLElement;
    expect(divider).toHaveClass('divider-gradient');
  });

  it('应用 my-6 垂直间距', () => {
    const { container } = render(<Divider />);

    const divider = container.firstChild as HTMLElement;
    expect(divider).toHaveClass('my-6');
  });

  it('应用自定义类名', () => {
    const { container } = render(<Divider className="my-10" />);

    const divider = container.firstChild as HTMLElement;
    expect(divider).toHaveClass('my-10');
  });

  it('渲染 div 元素', () => {
    const { container } = render(<Divider />);

    const divider = container.firstChild as HTMLElement;
    expect(divider.tagName).toBe('DIV');
  });
});

describe('Orb', () => {
  it('渲染光球元素', () => {
    const { container } = render(<Orb />);

    const orb = container.firstChild as HTMLElement;
    expect(orb).toBeInTheDocument();
  });

  it('使用默认 primary 颜色', () => {
    const { container } = render(<Orb />);

    const orb = container.firstChild as HTMLElement;
    expect(orb).toHaveClass('orb-primary');
  });

  it('应用 primary 颜色样式', () => {
    const { container } = render(<Orb color="primary" />);

    const orb = container.firstChild as HTMLElement;
    expect(orb).toHaveClass('orb-primary');
  });

  it('应用 accent 颜色样式', () => {
    const { container } = render(<Orb color="accent" />);

    const orb = container.firstChild as HTMLElement;
    expect(orb).toHaveClass('orb-accent');
  });

  it('使用默认尺寸 150px', () => {
    const { container } = render(<Orb />);

    const orb = container.firstChild as HTMLElement;
    expect(orb).toHaveStyle({ width: '150px', height: '150px' });
  });

  it('应用自定义尺寸', () => {
    const { container } = render(<Orb size={200} />);

    const orb = container.firstChild as HTMLElement;
    expect(orb).toHaveStyle({ width: '200px', height: '200px' });
  });

  it('应用 bg-orb 样式', () => {
    const { container } = render(<Orb />);

    const orb = container.firstChild as HTMLElement;
    expect(orb).toHaveClass('bg-orb');
  });

  it('应用自定义类名', () => {
    const { container } = render(<Orb className="opacity-50" />);

    const orb = container.firstChild as HTMLElement;
    expect(orb).toHaveClass('opacity-50');
  });

  it('组合颜色和自定义类名', () => {
    const { container } = render(<Orb color="accent" className="custom-class" />);

    const orb = container.firstChild as HTMLElement;
    expect(orb).toHaveClass('orb-accent', 'custom-class');
  });
});

describe('IconWrapper', () => {
  it('渲染图标包装器内容', () => {
    render(<IconWrapper>★</IconWrapper>);

    expect(screen.getByText('★')).toBeInTheDocument();
  });

  it('使用默认 glass 变体', () => {
    const { container } = render(<IconWrapper>图标</IconWrapper>);

    const wrapper = container.firstChild as HTMLElement;
    expect(wrapper).toHaveClass('glass-effect', 'text-[var(--color-text-secondary)]');
  });

  it('应用 primary 变体', () => {
    const { container } = render(<IconWrapper variant="primary">图标</IconWrapper>);

    const wrapper = container.firstChild as HTMLElement;
    expect(wrapper).toHaveClass(
      'bg-[var(--color-primary-500)]/20',
      'text-[var(--color-primary-400)]'
    );
  });

  it('应用 accent 变体', () => {
    const { container } = render(<IconWrapper variant="accent">图标</IconWrapper>);

    const wrapper = container.firstChild as HTMLElement;
    expect(wrapper).toHaveClass(
      'bg-[var(--color-accent-500)]/20',
      'text-[var(--color-accent-400)]'
    );
  });

  it('使用默认 md 尺寸', () => {
    const { container } = render(<IconWrapper>图标</IconWrapper>);

    const wrapper = container.firstChild as HTMLElement;
    expect(wrapper).toHaveClass('w-12', 'h-12');
  });

  it('应用 sm 尺寸', () => {
    const { container } = render(<IconWrapper size="sm">小</IconWrapper>);

    const wrapper = container.firstChild as HTMLElement;
    expect(wrapper).toHaveClass('w-10', 'h-10');
  });

  it('应用 lg 尺寸', () => {
    const { container } = render(<IconWrapper size="lg">大</IconWrapper>);

    const wrapper = container.firstChild as HTMLElement;
    expect(wrapper).toHaveClass('w-16', 'h-16');
  });

  it('有基础样式类', () => {
    const { container } = render(<IconWrapper>基础</IconWrapper>);

    const wrapper = container.firstChild as HTMLElement;
    expect(wrapper).toHaveClass('rounded-xl', 'flex', 'items-center', 'justify-center');
  });

  it('应用自定义类名', () => {
    const { container } = render(<IconWrapper className="custom">自定义</IconWrapper>);

    const wrapper = container.firstChild as HTMLElement;
    expect(wrapper).toHaveClass('custom');
  });

  it('渲染复杂图标内容', () => {
    render(
      <IconWrapper>
        <svg data-testid="test-icon">
          <circle cx="10" cy="10" r="10" />
        </svg>
      </IconWrapper>
    );

    expect(screen.getByTestId('test-icon')).toBeInTheDocument();
  });
});

describe('StatusIndicator', () => {
  it('渲染 online 状态指示器', () => {
    const { container } = render(<StatusIndicator status="online" />);

    // 默认不显示文本，只检查圆点存在
    const dots = container.querySelectorAll('.bg-\\[var\\(--color-success-500\\)\\]');
    expect(dots.length).toBe(2);
  });

  it('渲染 offline 状态指示器', () => {
    render(<StatusIndicator status="offline" />);

    const indicator = screen.queryByText('离线');
    expect(indicator).not.toBeInTheDocument(); // 默认不显示文本
  });

  it('渲染 away 状态指示器', () => {
    render(<StatusIndicator status="away" showText />);

    expect(screen.getByText('离开')).toBeInTheDocument();
  });

  it('渲染 busy 状态指示器', () => {
    render(<StatusIndicator status="busy" showText />);

    expect(screen.getByText('忙碌')).toBeInTheDocument();
  });

  it('online 状态使用绿色', () => {
    const { container } = render(<StatusIndicator status="online" />);

    const dots = container.querySelectorAll('.bg-\\[var\\(--color-success-500\\)\\]');
    expect(dots.length).toBe(2); // 两个圆点都有绿色背景
  });

  it('offline 状态使用灰色', () => {
    const { container } = render(<StatusIndicator status="offline" />);

    const dots = container.querySelectorAll('.bg-\\[var\\(--color-text-muted\\)\\]');
    expect(dots.length).toBe(2);
  });

  it('away 状态使用琥珀色', () => {
    const { container } = render(<StatusIndicator status="away" />);

    const dots = container.querySelectorAll('.bg-\\[var\\(--color-warning-500\\)\\]');
    expect(dots.length).toBe(2);
  });

  it('busy 状态使用红色', () => {
    const { container } = render(<StatusIndicator status="busy" />);

    const dots = container.querySelectorAll('.bg-\\[var\\(--color-error-500\\)\\]');
    expect(dots.length).toBe(2);
  });

  it('showText=false 时不显示文本', () => {
    render(<StatusIndicator status="online" showText={false} />);

    expect(screen.queryByText('在线')).not.toBeInTheDocument();
  });

  it('showText=true 时显示文本', () => {
    render(<StatusIndicator status="online" showText={true} />);

    expect(screen.getByText('在线')).toBeInTheDocument();
  });

  it('第一个圆点有 animate-ping 动画', () => {
    const { container } = render(<StatusIndicator status="online" />);

    const pingDot = container.querySelector('.animate-ping');
    expect(pingDot).toBeInTheDocument();
  });

  it('有正确的圆点尺寸', () => {
    const { container } = render(<StatusIndicator status="online" />);

    const dots = container.querySelectorAll('.h-3.w-3');
    expect(dots.length).toBe(2);
  });

  it('使用 flex 布局和间距', () => {
    const { container } = render(<StatusIndicator status="online" showText />);

    const wrapper = container.firstChild as HTMLElement;
    expect(wrapper).toHaveClass('flex', 'items-center', 'gap-2');
  });

  it('文本有正确的样式', () => {
    render(<StatusIndicator status="online" showText />);

    const text = screen.getByText('在线');
    expect(text).toHaveClass('text-sm', 'text-[var(--color-text-secondary)]');
  });

  it('相对圆点定位正确', () => {
    const { container } = render(<StatusIndicator status="online" />);

    const relativeDot = container.querySelector('.relative.inline-flex.rounded-full');
    expect(relativeDot).toBeInTheDocument();
  });
});
