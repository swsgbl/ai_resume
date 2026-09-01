/**
 * 撤销/重做工具栏组件
 */
import { Undo, Redo } from 'lucide-react';
import clsx from 'clsx';

interface UndoRedoControlsProps {
  canUndo: boolean;
  canRedo: boolean;
  onUndo: () => void;
  onRedo: () => void;
  className?: string;
}

export function UndoRedoControls({
  canUndo,
  canRedo,
  onUndo,
  onRedo,
  className,
}: UndoRedoControlsProps) {
  return (
    <div className={clsx('flex items-center gap-2', className)}>
      <button
        type="button"
        onClick={onUndo}
        disabled={!canUndo}
        title="撤销 (Ctrl+Z)"
        className={clsx(
          'p-2 rounded-lg transition-all',
          canUndo
            ? 'bg-white hover:bg-gray-100 text-gray-700 shadow-sm'
            : 'bg-gray-100 text-gray-400 cursor-not-allowed'
        )}
      >
        <Undo className="w-5 h-5" />
      </button>

      <button
        type="button"
        onClick={onRedo}
        disabled={!canRedo}
        title="重做 (Ctrl+Shift+Z)"
        className={clsx(
          'p-2 rounded-lg transition-all',
          canRedo
            ? 'bg-white hover:bg-gray-100 text-gray-700 shadow-sm'
            : 'bg-gray-100 text-gray-400 cursor-not-allowed'
        )}
      >
        <Redo className="w-5 h-5" />
      </button>

      {/* 快捷键提示 */}
      <div className="hidden sm:block text-xs text-gray-500 ml-2">
        <span className="hidden md:inline">Ctrl+Z 撤销</span>
      </div>
    </div>
  );
}

/**
 * 撤销历史状态指示器
 */
interface UndoHistoryIndicatorProps {
  pastLength: number;
  futureLength: number;
  maxHistory?: number;
}

export function UndoHistoryIndicator({
  pastLength,
  futureLength,
  maxHistory = 50,
}: UndoHistoryIndicatorProps) {
  const percentage = Math.min((pastLength / maxHistory) * 100, 100);

  return (
    <div className="flex items-center gap-2 text-xs text-gray-500">
      <span>历史记录: {pastLength}</span>
      {futureLength > 0 && <span>(可重做: {futureLength})</span>}

      {/* 历史记录使用量指示条 */}
      <div className="w-16 h-1.5 bg-gray-200 rounded-full overflow-hidden">
        <div
          className={clsx(
            'h-full transition-colors',
            percentage > 80 ? 'bg-red-500' : percentage > 50 ? 'bg-yellow-500' : 'bg-green-500'
          )}
          style={{ width: `${percentage}%` }}
        />
      </div>
    </div>
  );
}
