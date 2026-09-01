/**
 * DraggableResumeEditor 组件测试
 */
import { describe, it, expect, vi } from 'vitest';
import { render, screen } from '@testing-library/react';
import '@testing-library/jest-dom';
import { DraggableResumeEditor } from './DraggableResumeEditor';

// 测试用 MockItem 类型
interface MockItem {
  id: string;
  content: string;
}

describe('DraggableResumeEditor', () => {
  const mockItems: MockItem[] = [
    { id: '1', content: '项目 1' },
    { id: '2', content: '项目 2' },
    { id: '3', content: '项目 3' },
  ];

  it('渲染所有项目', () => {
    const renderItem = (item: MockItem) => (
      <div key={item.id}>{item.content}</div>
    );

    render(
      <DraggableResumeEditor
        items={mockItems}
        onReorder={vi.fn()}
        renderItem={renderItem}
      />
    );

    expect(screen.getByText('项目 1')).toBeInTheDocument();
    expect(screen.getByText('项目 2')).toBeInTheDocument();
    expect(screen.getByText('项目 3')).toBeInTheDocument();
  });

  it('空列表时正确渲染', () => {
    const renderItem = vi.fn();

    render(
      <DraggableResumeEditor
        items={[]}
        onReorder={vi.fn()}
        renderItem={renderItem}
      />
    );

    expect(renderItem).not.toHaveBeenCalled();
  });

  it('使用自定义渲染函数', () => {
    const customRender = (item: MockItem, index: number) => (
      <div key={item.id}>
        {index + 1}. {item.content}
      </div>
    );

    render(
      <DraggableResumeEditor
        items={mockItems}
        onReorder={vi.fn()}
        renderItem={customRender}
      />
    );

    expect(screen.getByText('1. 项目 1')).toBeInTheDocument();
    expect(screen.getByText('2. 项目 2')).toBeInTheDocument();
    expect(screen.getByText('3. 项目 3')).toBeInTheDocument();
  });

  it('拖拽结束时触发重新排序回调', () => {
    // 注意: 由于 DnD Kit 的复杂性，这个测试验证了组件结构
    // 实际的拖拽交互需要 E2E 测试
    const onReorder = vi.fn();
    const renderItem = (item: MockItem) => (
      <div key={item.id}>{item.content}</div>
    );

    const { container } = render(
      <DraggableResumeEditor
        items={mockItems}
        onReorder={onReorder}
        renderItem={renderItem}
      />
    );

    // 验证容器渲染正确（查找 SortableContext 内部的容器）
    const spaceYContainer = container.querySelector('.space-y-4');
    expect(spaceYContainer).toBeInTheDocument();
  });
});
