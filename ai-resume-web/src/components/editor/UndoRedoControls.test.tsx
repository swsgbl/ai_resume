/**
 * UndoRedoControls 组件测试
 */
import { describe, it, expect, vi } from 'vitest';
import { render, screen } from '@testing-library/react';
import '@testing-library/jest-dom';
import userEvent from '@testing-library/user-event';
import { UndoRedoControls, UndoHistoryIndicator } from './UndoRedoControls';

describe('UndoRedoControls', () => {
  it('渲染撤销和重做按钮', () => {
    render(
      <UndoRedoControls
        canUndo={false}
        canRedo={false}
        onUndo={vi.fn()}
        onRedo={vi.fn()}
      />
    );

    expect(screen.getByTitle('撤销 (Ctrl+Z)')).toBeInTheDocument();
    expect(screen.getByTitle('重做 (Ctrl+Shift+Z)')).toBeInTheDocument();
  });

  it('canUndo 为 false 时禁用撤销按钮', () => {
    render(
      <UndoRedoControls
        canUndo={false}
        canRedo={true}
        onUndo={vi.fn()}
        onRedo={vi.fn()}
      />
    );

    const undoButton = screen.getByTitle('撤销 (Ctrl+Z)');
    expect(undoButton).toBeDisabled();
    expect(undoButton).toHaveClass('bg-gray-100', 'text-gray-400', 'cursor-not-allowed');
  });

  it('canUndo 为 true 时启用撤销按钮', () => {
    render(
      <UndoRedoControls
        canUndo={true}
        canRedo={false}
        onUndo={vi.fn()}
        onRedo={vi.fn()}
      />
    );

    const undoButton = screen.getByTitle('撤销 (Ctrl+Z)');
    expect(undoButton).not.toBeDisabled();
    expect(undoButton).toHaveClass('bg-white', 'hover:bg-gray-100', 'text-gray-700');
  });

  it('canRedo 为 false 时禁用重做按钮', () => {
    render(
      <UndoRedoControls
        canUndo={true}
        canRedo={false}
        onUndo={vi.fn()}
        onRedo={vi.fn()}
      />
    );

    const redoButton = screen.getByTitle('重做 (Ctrl+Shift+Z)');
    expect(redoButton).toBeDisabled();
    expect(redoButton).toHaveClass('bg-gray-100', 'text-gray-400', 'cursor-not-allowed');
  });

  it('canRedo 为 true 时启用重做按钮', () => {
    render(
      <UndoRedoControls
        canUndo={false}
        canRedo={true}
        onUndo={vi.fn()}
        onRedo={vi.fn()}
      />
    );

    const redoButton = screen.getByTitle('重做 (Ctrl+Shift+Z)');
    expect(redoButton).not.toBeDisabled();
    expect(redoButton).toHaveClass('bg-white', 'hover:bg-gray-100', 'text-gray-700');
  });

  it('点击撤销按钮触发 onUndo', async () => {
    const handleUndo = vi.fn();
    const user = userEvent.setup();

    render(
      <UndoRedoControls
        canUndo={true}
        canRedo={false}
        onUndo={handleUndo}
        onRedo={vi.fn()}
      />
    );

    await user.click(screen.getByTitle('撤销 (Ctrl+Z)'));
    expect(handleUndo).toHaveBeenCalledTimes(1);
  });

  it('点击重做按钮触发 onRedo', async () => {
    const handleRedo = vi.fn();
    const user = userEvent.setup();

    render(
      <UndoRedoControls
        canUndo={false}
        canRedo={true}
        onUndo={vi.fn()}
        onRedo={handleRedo}
      />
    );

    await user.click(screen.getByTitle('重做 (Ctrl+Shift+Z)'));
    expect(handleRedo).toHaveBeenCalledTimes(1);
  });

  it('禁用状态下点击不触发回调', async () => {
    const handleUndo = vi.fn();
    const handleRedo = vi.fn();
    const user = userEvent.setup();

    render(
      <UndoRedoControls
        canUndo={false}
        canRedo={false}
        onUndo={handleUndo}
        onRedo={handleRedo}
      />
    );

    await user.click(screen.getByTitle('撤销 (Ctrl+Z)'));
    await user.click(screen.getByTitle('重做 (Ctrl+Shift+Z)'));

    expect(handleUndo).not.toHaveBeenCalled();
    expect(handleRedo).not.toHaveBeenCalled();
  });

  it('显示快捷键提示', () => {
    render(
      <UndoRedoControls
        canUndo={false}
        canRedo={false}
        onUndo={vi.fn()}
        onRedo={vi.fn()}
      />
    );

    expect(screen.getByText('Ctrl+Z 撤销')).toBeInTheDocument();
  });

  it('应用自定义类名', () => {
    const { container } = render(
      <UndoRedoControls
        canUndo={false}
        canRedo={false}
        onUndo={vi.fn()}
        onRedo={vi.fn()}
        className="custom-class"
      />
    );

    const wrapper = container.querySelector('.custom-class');
    expect(wrapper).toBeInTheDocument();
  });
});

describe('UndoHistoryIndicator', () => {
  it('显示历史记录数量', () => {
    render(<UndoHistoryIndicator pastLength={5} futureLength={2} />);

    expect(screen.getByText('历史记录: 5')).toBeInTheDocument();
  });

  it('显示可重做数量', () => {
    render(<UndoHistoryIndicator pastLength={5} futureLength={2} />);

    expect(screen.getByText('(可重做: 2)')).toBeInTheDocument();
  });

  it('没有可重做时不显示重做提示', () => {
    render(<UndoHistoryIndicator pastLength={5} futureLength={0} />);

    expect(screen.queryByText(/\(可重做:/)).not.toBeInTheDocument();
  });

  it('正确计算历史记录百分比', () => {
    const { container } = render(
      <UndoHistoryIndicator pastLength={25} futureLength={0} maxHistory={50} />
    );

    const progressBar = container.querySelector('.bg-green-500');
    expect(progressBar).toHaveStyle({ width: '50%' });
  });

  it('历史记录使用量 < 50% 时显示绿色', () => {
    const { container } = render(
      <UndoHistoryIndicator pastLength={20} futureLength={0} maxHistory={50} />
    );

    expect(container.querySelector('.bg-green-500')).toBeInTheDocument();
  });

  it('历史记录使用量 > 50% 时显示黄色', () => {
    const { container } = render(
      <UndoHistoryIndicator pastLength={30} futureLength={0} maxHistory={50} />
    );

    expect(container.querySelector('.bg-yellow-500')).toBeInTheDocument();
  });

  it('历史记录使用量 > 80% 时显示红色', () => {
    const { container } = render(
      <UndoHistoryIndicator pastLength={45} futureLength={0} maxHistory={50} />
    );

    expect(container.querySelector('.bg-red-500')).toBeInTheDocument();
  });

  it('历史记录使用量达到 100% 时不超出', () => {
    const { container } = render(
      <UndoHistoryIndicator pastLength={100} futureLength={0} maxHistory={50} />
    );

    const progressBar = container.querySelector('.bg-red-500');
    expect(progressBar).toHaveStyle({ width: '100%' });
  });
});
