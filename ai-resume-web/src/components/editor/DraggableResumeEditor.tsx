/**
 * 可拖拽的简历内容编辑器容器
 * 支持工作经历、教育经历、项目等区块的拖拽排序
 */
import { DndContext, closestCenter, KeyboardSensor, PointerSensor, useSensor, useSensors, type DragEndEvent } from '@dnd-kit/core';
import { SortableContext, sortableKeyboardCoordinates, verticalListSortingStrategy } from '@dnd-kit/sortable';

// 使用泛型使组件更灵活
interface SortableItem<T = unknown> {
  id: string;
  content: T;
}

interface DraggableResumeEditorProps<T = unknown> {
  items: SortableItem<T>[];
  onReorder: (items: SortableItem<T>[]) => void;
  renderItem: (item: SortableItem<T>, index: number) => React.ReactNode;
}

export function DraggableResumeEditor<T = unknown>({ items, onReorder, renderItem }: DraggableResumeEditorProps<T>) {
  const sensors = useSensors(
    useSensor(PointerSensor),
    useSensor(KeyboardSensor, {
      coordinateGetter: sortableKeyboardCoordinates,
    })
  );

  const handleDragEnd = (event: DragEndEvent) => {
    const { active, over } = event;

    if (over && active.id !== over.id) {
      const oldIndex = items.findIndex((item) => item.id === String(active.id));
      const newIndex = items.findIndex((item) => item.id === String(over.id));

      const newItems = [...items];
      const [removed] = newItems.splice(oldIndex, 1);
      newItems.splice(newIndex, 0, removed);

      onReorder(newItems);
    }
  };

  return (
    <DndContext sensors={sensors} collisionDetection={closestCenter} onDragEnd={handleDragEnd}>
      <SortableContext items={items.map((item) => item.id)} strategy={verticalListSortingStrategy}>
        <div className="space-y-4">
          {items.map((item, index) => renderItem(item, index))}
        </div>
      </SortableContext>
    </DndContext>
  );
}
