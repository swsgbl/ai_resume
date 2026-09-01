/**
 * Card 组件测试
 */
import { describe, it, expect, vi } from 'vitest';
import { render, screen } from '@testing-library/react';
import '@testing-library/jest-dom';
import userEvent from '@testing-library/user-event';
import { Card } from './Card';

describe('Card Component', () => {
  it('渲染卡片内容', () => {
    render(<Card>卡片内容</Card>);

    expect(screen.getByText('卡片内容')).toBeInTheDocument();
  });

  it('使用默认 solid 样式', () => {
    const { container } = render(<Card>Solid Card</Card>);

    const card = container.firstChild as HTMLElement;
    expect(card).toHaveClass('card-elevation-1');
  });

  it('应用 glass 变体样式', () => {
    const { container } = render(<Card variant="glass">Glass Card</Card>);

    const card = container.firstChild as HTMLElement;
    expect(card).toHaveClass('card-glass');
  });

  it('应用 neon 变体样式', () => {
    const { container } = render(<Card variant="neon">Neon Card</Card>);

    const card = container.firstChild as HTMLElement;
    expect(card).toHaveClass('card-neon');
  });

  it('应用 hover 变体样式', () => {
    const { container } = render(<Card variant="hover">Hover Card</Card>);

    const card = container.firstChild as HTMLElement;
    expect(card).toHaveClass('card-hover', 'cursor-pointer');
  });

  it('应用自定义类名', () => {
    const { container } = render(<Card className="custom-card">内容</Card>);

    const card = container.firstChild as HTMLElement;
    expect(card).toHaveClass('custom-card');
  });

  it('有 onClick 时显示 cursor-pointer', () => {
    const handleClick = vi.fn();

    const { container } = render(<Card onClick={handleClick}>Clickable</Card>);

    const card = container.firstChild as HTMLElement;
    expect(card).toHaveClass('cursor-pointer');
  });

  it('点击卡片触发 onClick', async () => {
    const handleClick = vi.fn();
    const user = userEvent.setup();

    render(<Card onClick={handleClick}>点击我</Card>);

    await user.click(screen.getByText('点击我'));

    expect(handleClick).toHaveBeenCalledTimes(1);
  });

  it('hover 变体添加额外的 cursor-pointer 类', () => {
    const { container } = render(<Card variant="hover">Hover</Card>);

    const card = container.firstChild as HTMLElement;
    // 应该有两个 cursor-pointer 类（来自 variant 和 onClick 检查）
    const classes = card.className;
    expect(classes).toContain('cursor-pointer');
  });

  it('组合多个变体和自定义类名', () => {
    const { container } = render(
      <Card variant="glass" className="p-8">
        Combined
      </Card>
    );

    const card = container.firstChild as HTMLElement;
    expect(card).toHaveClass('card-glass', 'p-8');
  });

  it('渲染复杂的子内容', () => {
    render(
      <Card>
        <h2>标题</h2>
        <p>段落内容</p>
        <button>按钮</button>
      </Card>
    );

    expect(screen.getByText('标题')).toBeInTheDocument();
    expect(screen.getByText('段落内容')).toBeInTheDocument();
    expect(screen.getByText('按钮')).toBeInTheDocument();
  });

  it('无 onClick 时不添加 cursor-pointer', () => {
    const { container } = render(<Card variant="solid">Non-clickable</Card>);

    const card = container.firstChild as HTMLElement;
    expect(card.className).not.toContain('cursor-pointer');
  });

  it('保持 onClick 的 cursor-pointer 即使是 solid 变体', () => {
    const handleClick = vi.fn();

    const { container } = render(
      <Card variant="solid" onClick={handleClick}>
        Clickable Solid
      </Card>
    );

    const card = container.firstChild as HTMLElement;
    expect(card).toHaveClass('cursor-pointer');
  });
});
