/**
 * 可拖拽区块组件 - 用于简历各部分的拖拽排序
 */
import { useSortable } from '@dnd-kit/sortable';
import { CSS } from '@dnd-kit/utilities';
import { GripVertical, ChevronDown, ChevronUp } from 'lucide-react';
import { useState } from 'react';
import clsx from 'clsx';

interface DraggableSectionProps {
  id: string;
  children: React.ReactNode;
  title: string;
  onToggle?: () => void;
  defaultCollapsed?: boolean;
  className?: string;
  actions?: React.ReactNode;
}

export function DraggableSection({
  id,
  children,
  title,
  onToggle,
  defaultCollapsed = false,
  className,
  actions,
}: DraggableSectionProps) {
  const [collapsed, setCollapsed] = useState(defaultCollapsed);

  const {
    attributes,
    listeners,
    setNodeRef,
    transform,
    transition,
    isDragging,
  } = useSortable({ id });

  const style = {
    transform: CSS.Transform.toString(transform),
    transition,
  };

  const handleToggle = () => {
    setCollapsed(!collapsed);
    onToggle?.();
  };

  return (
    <div
      ref={setNodeRef}
      style={style}
      className={clsx(
        'card border-l-4 transition-shadow',
        isDragging ? 'opacity-50 shadow-lg' : '',
        className
      )}
    >
      {/* 拖拽手柄和标题栏 */}
      <div className="flex items-center justify-between p-4 border-b">
        <div className="flex items-center gap-3 flex-1">
          <button
            type="button"
            className="cursor-grab active:cursor-grabbing text-gray-400 hover:text-gray-600"
            {...attributes}
            {...listeners}
          >
            <GripVertical className="w-5 h-5" />
          </button>
          <h3 className="font-semibold text-gray-900">{title}</h3>
        </div>

        <div className="flex items-center gap-2">
          {actions}
          {onToggle && (
            <button
              type="button"
              onClick={handleToggle}
              className="p-1 hover:bg-gray-100 rounded text-gray-500 hover:text-gray-700"
            >
              {collapsed ? (
                <ChevronDown className="w-5 h-5" />
              ) : (
                <ChevronUp className="w-5 h-5" />
              )}
            </button>
          )}
        </div>
      </div>

      {/* 内容区 */}
      {!collapsed && <div className="p-4">{children}</div>}
    </div>
  );
}

/**
 * 可拖拽的简历项组件 (用于工作经历、教育经历等列表项)
 */
interface DraggableItemProps {
  id: string;
  index: number;
  children: React.ReactNode;
  onRemove?: () => void;
  className?: string;
}

export function DraggableItem({ id, children, onRemove, className }: DraggableItemProps) {
  const {
    attributes,
    listeners,
    setNodeRef,
    transform,
    transition,
    isDragging,
  } = useSortable({ id });

  const style = {
    transform: CSS.Transform.toString(transform),
    transition,
    zIndex: isDragging ? 1 : 0,
  };

  return (
    <div
      ref={setNodeRef}
      style={style}
      className={clsx(
        'relative card group',
        isDragging ? 'opacity-50 scale-105' : '',
        className
      )}
    >
      {/* 拖拽手柄 */}
      <div
        className="absolute left-2 top-1/2 -translate-y-1/2 cursor-grab active:cursor-grabbing text-gray-300 hover:text-gray-500 opacity-0 group-hover:opacity-100 transition-opacity"
        {...attributes}
        {...listeners}
      >
        <GripVertical className="w-5 h-5" />
      </div>

      {/* 内容 */}
      <div className="pl-10">{children}</div>

      {/* 移除按钮 */}
      {onRemove && (
        <button
          type="button"
          onClick={onRemove}
          className="absolute right-4 top-4 text-gray-400 hover:text-red-500 opacity-0 group-hover:opacity-100 transition-opacity"
        >
          ×
        </button>
      )}

      {/* 序号指示器 */}
      <div className="absolute left-0 top-0 bottom-0 w-1 bg-primary-500 rounded-l" />
    </div>
  );
}
