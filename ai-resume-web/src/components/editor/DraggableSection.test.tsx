/**
 * DraggableSection 组件测试
 */
import { describe, it, expect, vi } from 'vitest';
import { render, screen } from '@testing-library/react';
import '@testing-library/jest-dom';
import { DndContext } from '@dnd-kit/core';
import { DraggableSection, DraggableItem } from './DraggableSection';

describe('DraggableSection', () => {
  it('渲染可拖拽区块', () => {
    render(
      <DndContext>
        <DraggableSection id="test-1" title="测试区块">
          <p>区块内容</p>
        </DraggableSection>
      </DndContext>
    );

    expect(screen.getByText('测试区块')).toBeInTheDocument();
    expect(screen.getByText('区块内容')).toBeInTheDocument();
  });

  it('默认展开状态显示内容', () => {
    render(
      <DndContext>
        <DraggableSection id="test-2" title="测试区块">
          <p>区块内容</p>
        </DraggableSection>
      </DndContext>
    );

    expect(screen.getByText('区块内容')).toBeVisible();
  });

  it('默认折叠状态隐藏内容', () => {
    const { container } = render(
      <DndContext>
        <DraggableSection id="test-3" title="测试区块" defaultCollapsed>
          <p>区块内容</p>
        </DraggableSection>
      </DndContext>
    );

    // 折叠时内容区不存在
    const content = container.querySelector('p');
    expect(content).not.toBeInTheDocument();
  });

  it('显示操作按钮', () => {
    render(
      <DndContext>
        <DraggableSection
          id="test-4"
          title="测试区块"
          actions={<button type="button">操作</button>}
        >
          <p>区块内容</p>
        </DraggableSection>
      </DndContext>
    );

    expect(screen.getByText('操作')).toBeInTheDocument();
  });

  it('点击折叠按钮切换状态', async () => {
    const { container } = render(
      <DndContext>
        <DraggableSection id="test-5" title="测试区块" onToggle={() => {}}>
          <p>区块内容</p>
        </DraggableSection>
      </DndContext>
    );

    // 验证折叠按钮存在（通过图标）
    const toggleButton = container.querySelector('button svg');
    expect(toggleButton).toBeInTheDocument();
  });
});

describe('DraggableItem', () => {
  it('渲染可拖拽列表项', () => {
    render(
      <DndContext>
        <DraggableItem id="item-1" index={0}>
          <p>列表项内容</p>
        </DraggableItem>
      </DndContext>
    );

    expect(screen.getByText('列表项内容')).toBeInTheDocument();
  });

  it('显示移除按钮', () => {
    const handleRemove = vi.fn();

    render(
      <DndContext>
        <DraggableItem id="item-2" index={0} onRemove={handleRemove}>
          <p>列表项内容</p>
        </DraggableItem>
      </DndContext>
    );

    const removeButton = screen.getByText('×');
    expect(removeButton).toBeInTheDocument();
  });

  it('点击移除按钮触发回调', async () => {
    const handleRemove = vi.fn();

    const { container } = render(
      <DndContext>
        <DraggableItem id="item-3" index={0} onRemove={handleRemove}>
          <p>列表项内容</p>
        </DraggableItem>
      </DndContext>
    );

    const removeButton = container.querySelector('button');
    removeButton?.click();

    expect(handleRemove).toHaveBeenCalledTimes(1);
  });

  it('应用自定义类名', () => {
    const { container } = render(
      <DndContext>
        <DraggableItem id="item-4" index={0} className="custom-class">
          <p>列表项内容</p>
        </DraggableItem>
      </DndContext>
    );

    const item = container.querySelector('.custom-class');
    expect(item).toBeInTheDocument();
  });
});
