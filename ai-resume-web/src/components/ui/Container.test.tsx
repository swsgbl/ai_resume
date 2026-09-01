/**
 * Container 组件测试
 */
import { describe, it, expect } from 'vitest';
import { render, screen } from '@testing-library/react';
import '@testing-library/jest-dom';
import { GlassContainer, NeonContainer, Section } from './Container';

describe('GlassContainer', () => {
  it('渲染玻璃容器内容', () => {
    render(<GlassContainer>内容</GlassContainer>);

    expect(screen.getByText('内容')).toBeInTheDocument();
  });

  it('应用 card-glass 样式', () => {
    const { container } = render(<GlassContainer>Glass</GlassContainer>);

    const glassContainer = container.firstChild as HTMLElement;
    expect(glassContainer).toHaveClass('card-glass');
  });

  it('应用自定义类名', () => {
    const { container } = render(<GlassContainer className="p-8">自定义</GlassContainer>);

    const glassContainer = container.firstChild as HTMLElement;
    expect(glassContainer).toHaveClass('p-8');
  });

  it('组合类名', () => {
    const { container } = render(<GlassContainer className="custom-class">组合</GlassContainer>);

    const glassContainer = container.firstChild as HTMLElement;
    expect(glassContainer).toHaveClass('card-glass', 'custom-class');
  });

  it('渲染复杂内容', () => {
    render(
      <GlassContainer>
        <h2>标题</h2>
        <p>段落</p>
      </GlassContainer>
    );

    expect(screen.getByText('标题')).toBeInTheDocument();
    expect(screen.getByText('段落')).toBeInTheDocument();
  });
});

describe('NeonContainer', () => {
  it('渲染霓虹容器内容', () => {
    render(<NeonContainer>内容</NeonContainer>);

    expect(screen.getByText('内容')).toBeInTheDocument();
  });

  it('使用默认 blue 颜色', () => {
    const { container } = render(<NeonContainer>Blue Neon</NeonContainer>);

    const neonContainer = container.firstChild as HTMLElement;
    expect(neonContainer).toHaveClass('shadow-neon-blue');
  });

  it('应用 blue 颜色样式', () => {
    const { container } = render(<NeonContainer color="blue">Blue</NeonContainer>);

    const neonContainer = container.firstChild as HTMLElement;
    expect(neonContainer).toHaveClass('shadow-neon-blue');
  });

  it('应用 purple 颜色样式', () => {
    const { container } = render(<NeonContainer color="purple">Purple</NeonContainer>);

    const neonContainer = container.firstChild as HTMLElement;
    expect(neonContainer).toHaveClass('shadow-neon-purple');
  });

  it('应用 pink 颜色样式', () => {
    const { container } = render(<NeonContainer color="pink">Pink</NeonContainer>);

    const neonContainer = container.firstChild as HTMLElement;
    expect(neonContainer).toHaveClass('shadow-neon-pink');
  });

  it('应用 green 颜色样式', () => {
    const { container } = render(<NeonContainer color="green">Green</NeonContainer>);

    const neonContainer = container.firstChild as HTMLElement;
    expect(neonContainer).toHaveClass('shadow-green-500/50');
  });

  it('有基础样式类', () => {
    const { container } = render(<NeonContainer>基础</NeonContainer>);

    const neonContainer = container.firstChild as HTMLElement;
    expect(neonContainer).toHaveClass(
      'rounded-2xl',
      'p-6',
      'bg-[var(--color-surface-2)]',
      'border',
      'border-[var(--color-border)]'
    );
  });

  it('应用自定义类名', () => {
    const { container } = render(<NeonContainer className="mt-4">自定义</NeonContainer>);

    const neonContainer = container.firstChild as HTMLElement;
    expect(neonContainer).toHaveClass('mt-4');
  });

  it('组合颜色和自定义类名', () => {
    const { container } = render(
      <NeonContainer color="purple" className="p-8">
        组合
      </NeonContainer>);

    const neonContainer = container.firstChild as HTMLElement;
    expect(neonContainer).toHaveClass('shadow-neon-purple', 'p-8');
  });
});

describe('Section', () => {
  it('渲染区块内容', () => {
    render(<Section>区块内容</Section>);

    expect(screen.getByText('区块内容')).toBeInTheDocument();
  });

  it('默认使用容器布局', () => {
    const { container } = render(<Section>有容器</Section>);

    const section = container.firstChild as HTMLElement;
    const div = section.querySelector('div');
    expect(div).toHaveClass('max-w-7xl', 'mx-auto', 'px-4');
  });

  it('container=false 时不使用容器布局', () => {
    const { container } = render(<Section container={false}>无容器</Section>);

    const section = container.firstChild as HTMLElement;
    const div = section.querySelector('div');
    expect(div).toBeNull();
  });

  it('有基础 py-section-lg 样式', () => {
    const { container } = render(<Section>垂直间距</Section>);

    const section = container.firstChild as HTMLElement;
    expect(section).toHaveClass('py-section-lg');
  });

  it('应用自定义类名', () => {
    const { container } = render(<Section className="bg-slate-900">背景</Section>);

    const section = container.firstChild as HTMLElement;
    expect(section).toHaveClass('bg-slate-900');
  });

  it('组合基础样式和自定义类名', () => {
    const { container } = render(<Section className="mt-10">组合</Section>);

    const section = container.firstChild as HTMLElement;
    expect(section).toHaveClass('py-section-lg', 'mt-10');
  });

  it('容器有响应式内边距', () => {
    const { container } = render(<Section>响应式</Section>);

    const section = container.firstChild as HTMLElement;
    const div = section.querySelector('div');
    expect(div).toHaveClass('px-4', 'sm:px-6', 'lg:px-8');
  });

  it('渲染 section 元素', () => {
    const { container } = render(<Section>Section</Section>);

    const section = container.firstChild as HTMLElement;
    expect(section.tagName).toBe('SECTION');
  });
});
