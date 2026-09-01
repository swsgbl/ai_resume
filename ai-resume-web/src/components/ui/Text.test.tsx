/**
 * GradientText 组件测试
 */
import { describe, it, expect } from 'vitest';
import { render, screen } from '@testing-library/react';
import '@testing-library/jest-dom';
import { GradientText } from './Text';

describe('GradientText Component', () => {
  it('渲染渐变文本内容', () => {
    render(<GradientText>渐变文本</GradientText>);

    expect(screen.getByText('渐变文本')).toBeInTheDocument();
  });

  it('使用默认 full 渐变样式', () => {
    const { container } = render(<GradientText>Full Gradient</GradientText>);

    const text = container.firstChild as HTMLElement;
    expect(text).toHaveClass('text-gradient');
  });

  it('应用 primary 渐变样式', () => {
    const { container } = render(<GradientText variant="primary">Primary</GradientText>);

    const text = container.firstChild as HTMLElement;
    expect(text).toHaveClass('text-gradient-primary');
  });

  it('应用 accent 渐变样式', () => {
    const { container } = render(<GradientText variant="accent">Accent</GradientText>);

    const text = container.firstChild as HTMLElement;
    expect(text).toHaveClass('text-gradient-accent');
  });

  it('应用 full 渐变样式', () => {
    const { container } = render(<GradientText variant="full">Full</GradientText>);

    const text = container.firstChild as HTMLElement;
    expect(text).toHaveClass('text-gradient');
  });

  it('渲染 span 元素', () => {
    const { container } = render(<GradientText>文本</GradientText>);

    const text = container.firstChild as HTMLElement;
    expect(text.tagName).toBe('SPAN');
  });

  it('应用自定义类名', () => {
    const { container } = render(
      <GradientText className="text-2xl font-bold">
        自定义样式
      </GradientText>
    );

    const text = container.firstChild as HTMLElement;
    expect(text).toHaveClass('text-2xl', 'font-bold');
  });

  it('组合变体和自定义类名', () => {
    const { container } = render(
      <GradientText variant="primary" className="text-xl">
        Primary Title
      </GradientText>
    );

    const text = container.firstChild as HTMLElement;
    expect(text).toHaveClass('text-gradient-primary', 'text-xl');
  });

  it('渲染长文本内容', () => {
    render(
      <GradientText>
        这是一段很长的渐变文本内容，用于测试组件是否能正确渲染多行文本。
      </GradientText>
    );

    expect(screen.getByText(/这是一段很长的渐变文本/)).toBeInTheDocument();
  });

  it('渲染特殊字符', () => {
    render(<GradientText>★ 特殊符号 & 特殊字符</GradientText>);

    expect(screen.getByText('★ 特殊符号 & 特殊字符')).toBeInTheDocument();
  });

  it('渲染数字和字母', () => {
    render(<GradientText>ABC 123 xyz</GradientText>);

    expect(screen.getByText('ABC 123 xyz')).toBeInTheDocument();
  });

  it('保留原始文本内容', () => {
    render(<GradientText>原始文本</GradientText>);

    const text = screen.getByText('原始文本');
    expect(text.textContent).toBe('原始文本');
  });

  it('不修改子元素内容', () => {
    render(
      <GradientText>
        <span>嵌套元素</span>
      </GradientText>
    );

    expect(screen.getByText('嵌套元素')).toBeInTheDocument();
  });

  it('空字符串也能渲染', () => {
    const { container } = render(<GradientText>{''}</GradientText>);

    const text = container.firstChild as HTMLElement;
    expect(text).toBeInTheDocument();
    expect(text.textContent).toBe('');
  });

  it('默认变体为 full', () => {
    const { container } = render(<GradientText>默认</GradientText>);

    const text = container.firstChild as HTMLElement;
    expect(text).toHaveClass('text-gradient');
  });
});
