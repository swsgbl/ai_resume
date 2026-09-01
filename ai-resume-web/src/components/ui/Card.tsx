import { ReactNode } from 'react';

interface CardProps {
  variant?: 'glass' | 'neon' | 'hover' | 'solid' | 'elevation-1' | 'elevation-2' | 'elevation-3';
  children: ReactNode;
  className?: string;
  onClick?: () => void;
}

/**
 * Card 组件 - Design System v2.0
 *
 * 使用 4 级表面层级系统：
 * - elevation-1: surface-1 (默认卡片)
 * - elevation-2: surface-2 (重要卡片)
 * - elevation-3: surface-3 (悬浮层)
 *
 * 每个变体自动包含对应级别的阴影和边框
 */
export function Card({ variant = 'solid', children, className = '', onClick }: CardProps) {
  const variantClasses = {
    // 向后兼容的旧变体
    glass: 'card-glass',
    neon: 'card-neon',
    hover: 'card-hover cursor-pointer',
    // 使用新的 Design System v2.0 类
    solid: 'card-elevation-1',
    'elevation-1': 'card-elevation-1',
    'elevation-2': 'card-elevation-2',
    'elevation-3': 'card-elevation-3',
  };

  return (
    <div
      className={`${variantClasses[variant]} ${onClick ? 'cursor-pointer' : ''} ${className}`}
      onClick={onClick}
    >
      {children}
    </div>
  );
}
