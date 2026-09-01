/**
 * Skeleton 组件测试
 */
import { describe, it, expect } from 'vitest';
import { render, screen } from '@testing-library/react';
import '@testing-library/jest-dom';
import { Skeleton, TextSkeleton, AvatarSkeleton, CardSkeleton, ResumeListSkeleton, TemplateGridSkeleton, NavbarSkeleton, PageLoadingSkeleton, InputSkeleton, ButtonSkeleton } from './Skeleton';

describe('Skeleton', () => {
  it('渲染基础骨架屏', () => {
    const { container } = render(<Skeleton />);

    const skeleton = container.querySelector('.bg-\\[var\\(--color-surface-1\\)\\]');
    expect(skeleton).toBeInTheDocument();
  });

  it('应用不同的变体样式', () => {
    const { container: textContainer } = render(<Skeleton variant="text" />);
    expect(textContainer.querySelector('.rounded')).toBeInTheDocument();

    const { container: circularContainer } = render(<Skeleton variant="circular" />);
    expect(circularContainer.querySelector('.rounded-full')).toBeInTheDocument();

    const { container: rectangularContainer } = render(<Skeleton variant="rectangular" />);
    expect(rectangularContainer.querySelector('.rounded-md')).toBeInTheDocument();

    const { container: roundedContainer } = render(<Skeleton variant="rounded" />);
    expect(roundedContainer.querySelector('.rounded-lg')).toBeInTheDocument();
  });

  it('应用不同的动画效果', () => {
    const { container: pulseContainer } = render(<Skeleton animation="pulse" />);
    expect(pulseContainer.querySelector('.animate-pulse')).toBeInTheDocument();

    const { container: waveContainer } = render(<Skeleton animation="wave" />);
    expect(waveContainer.querySelector('.animate-shimmer')).toBeInTheDocument();

    const { container: noneContainer } = render(<Skeleton animation="none" />);
    expect(noneContainer.querySelector('.animate-pulse')).not.toBeInTheDocument();
  });

  it('应用自定义宽度', () => {
    const { container } = render(<Skeleton width="100px" />);

    const skeleton = container.firstChild as HTMLElement;
    expect(skeleton).toHaveStyle({ width: '100px' });
  });

  it('应用自定义高度', () => {
    const { container } = render(<Skeleton height="50px" />);

    const skeleton = container.firstChild as HTMLElement;
    expect(skeleton).toHaveStyle({ height: '50px' });
  });

  it('支持数字类型的高度和宽度', () => {
    const { container } = render(<Skeleton width={200} height={100} />);

    const skeleton = container.firstChild as HTMLElement;
    expect(skeleton).toHaveStyle({ width: '200px', height: '100px' });
  });

  it('应用自定义类名', () => {
    const { container } = render(<Skeleton className="custom-skeleton" />);

    const skeleton = container.firstChild as HTMLElement;
    expect(skeleton).toHaveClass('custom-skeleton');
  });

  it('设置 aria-hidden 属性', () => {
    const { container } = render(<Skeleton />);

    const skeleton = container.firstChild as HTMLElement;
    expect(skeleton).toHaveAttribute('aria-hidden', 'true');
  });
});

describe('TextSkeleton', () => {
  it('渲染指定行数的文本骨架屏', () => {
    const { container } = render(<TextSkeleton lines={5} />);

    const skeletons = container.querySelectorAll('.bg-\\[var\\(--color-surface-1\\)\\]');
    expect(skeletons.length).toBe(5);
  });

  it('默认渲染 3 行文本', () => {
    const { container } = render(<TextSkeleton />);

    const skeletons = container.querySelectorAll('.bg-\\[var\\(--color-surface-1\\)\\]');
    expect(skeletons.length).toBe(3);
  });

  it('最后一行宽度为 3/4', () => {
    const { container } = render(<TextSkeleton lines={3} />);

    const skeletons = container.querySelectorAll('.bg-\\[var\\(--color-surface-1\\)\\]');
    const lastSkeleton = skeletons[skeletons.length - 1] as HTMLElement;
    expect(lastSkeleton).toHaveClass('w-3/4');
  });

  it('应用自定义类名', () => {
    const { container } = render(<TextSkeleton className="custom-class" />);

    expect(container.querySelector('.custom-class')).toBeInTheDocument();
  });
});

describe('AvatarSkeleton', () => {
  it('渲染头像骨架屏', () => {
    const { container } = render(<AvatarSkeleton />);

    const avatar = container.firstChild as HTMLElement;
    expect(avatar).toHaveClass('rounded-full', 'bg-[var(--color-surface-1)]', 'animate-pulse');
  });

  it('应用自定义尺寸', () => {
    const { container } = render(<AvatarSkeleton size={60} />);

    const avatar = container.firstChild as HTMLElement;
    expect(avatar).toHaveStyle({ width: '60px', height: '60px' });
  });

  it('默认尺寸为 40px', () => {
    const { container } = render(<AvatarSkeleton />);

    const avatar = container.firstChild as HTMLElement;
    expect(avatar).toHaveStyle({ width: '40px', height: '40px' });
  });
});

describe('CardSkeleton', () => {
  it('渲染卡片骨架屏', () => {
    const { container } = render(<CardSkeleton />);

    expect(container.querySelector('.rounded-xl')).toBeInTheDocument();
    expect(container.querySelector('.border-\\[var\\(--color-border\\)\\]')).toBeInTheDocument();
  });

  it('包含头像和文本骨架', () => {
    const { container } = render(<CardSkeleton />);

    expect(container.querySelector('.rounded-full')).toBeInTheDocument();
    const textSkeletons = container.querySelectorAll('.h-4');
    expect(textSkeletons.length).toBeGreaterThan(0);
  });

  it('应用自定义类名', () => {
    const { container } = render(<CardSkeleton className="custom-card" />);

    expect(container.querySelector('.custom-card')).toBeInTheDocument();
  });
});

describe('ResumeListSkeleton', () => {
  it('渲染指定数量的卡片骨架屏', () => {
    const { container } = render(<ResumeListSkeleton count={5} />);

    const cards = container.querySelectorAll('.rounded-xl');
    expect(cards.length).toBe(5);
  });

  it('默认渲染 3 个卡片', () => {
    const { container } = render(<ResumeListSkeleton />);

    const cards = container.querySelectorAll('.rounded-xl');
    expect(cards.length).toBe(3);
  });
});

describe('TemplateGridSkeleton', () => {
  it('渲染网格布局的模板骨架屏', () => {
    const { container } = render(<TemplateGridSkeleton />);

    expect(container.querySelector('.grid')).toBeInTheDocument();
  });

  it('包含正确数量的模板项', () => {
    const { container } = render(<TemplateGridSkeleton count={6} />);

    const templates = container.querySelectorAll('.rounded-xl');
    expect(templates.length).toBe(6);
  });

  it('默认渲染 6 个模板', () => {
    const { container } = render(<TemplateGridSkeleton />);

    const templates = container.querySelectorAll('.rounded-xl');
    expect(templates.length).toBe(6);
  });
});

describe('NavbarSkeleton', () => {
  it('渲染导航栏骨架屏', () => {
    const { container } = render(<NavbarSkeleton />);

    expect(container.querySelector('nav')).toBeInTheDocument();
  });

  it('包含 Logo 和导航项', () => {
    render(<NavbarSkeleton />);

    expect(screen.getAllByText('').length).toBeGreaterThan(0);
  });
});

describe('PageLoadingSkeleton', () => {
  it('渲染完整页面加载骨架屏', () => {
    const { container } = render(<PageLoadingSkeleton />);

    expect(container.querySelector('.min-h-screen')).toBeInTheDocument();
  });

  it('包含导航栏和内容区', () => {
    const { container } = render(<PageLoadingSkeleton />);

    expect(container.querySelector('nav')).toBeInTheDocument();
    expect(container.querySelector('main')).toBeInTheDocument();
  });
});

describe('InputSkeleton', () => {
  it('渲染输入框骨架屏', () => {
    const { container } = render(<InputSkeleton />);

    const skeletons = container.querySelectorAll('.bg-\\[var\\(--color-surface-1\\)\\]');
    expect(skeletons.length).toBe(2); // 标签 + 输入框
  });

  it('应用自定义类名', () => {
    const { container } = render(<InputSkeleton className="custom-input" />);

    expect(container.querySelector('.custom-input')).toBeInTheDocument();
  });
});

describe('ButtonSkeleton', () => {
  it('渲染按钮骨架屏', () => {
    const { container } = render(<ButtonSkeleton />);

    const skeleton = container.querySelector('.rounded-xl');
    expect(skeleton).toBeInTheDocument();
  });

  it('默认宽度为 100px', () => {
    const { container } = render(<ButtonSkeleton />);

    const skeleton = container.firstChild as HTMLElement;
    expect(skeleton).toHaveStyle({ width: '100px' });
  });

  it('应用自定义宽度', () => {
    const { container } = render(<ButtonSkeleton width={150} />);

    const skeleton = container.firstChild as HTMLElement;
    expect(skeleton).toHaveStyle({ width: '150px' });
  });

  it('支持字符串宽度', () => {
    const { container } = render(<ButtonSkeleton width="100%" />);

    const skeleton = container.firstChild as HTMLElement;
    expect(skeleton).toHaveStyle({ width: '100%' });
  });
});
