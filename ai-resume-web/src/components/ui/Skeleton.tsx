/**
 * 骨架屏组件 - Design System v2.0
 *
 * 使用表面层级系统：
 * - 基础背景: surface-1
 * - 卡片背景: surface-2/surface-3
 * - 边框: border 令牌
 */

interface SkeletonProps {
  className?: string;
  variant?: 'text' | 'circular' | 'rectangular' | 'rounded';
  width?: string | number;
  height?: string | number;
  animation?: 'pulse' | 'wave' | 'none';
}

/**
 * 合并类名的简单工具函数
 */
function cn(...classes: (string | undefined | false)[]) {
  return classes.filter(Boolean).join(' ');
}

/**
 * 基础骨架屏组件
 */
export function Skeleton({
  className,
  variant = 'rectangular',
  width,
  height,
  animation = 'pulse',
}: SkeletonProps) {
  const variantClasses: Record<string, string> = {
    text: 'rounded h-4',
    circular: 'rounded-full',
    rectangular: 'rounded-md',
    rounded: 'rounded-lg',
  };

  const animationClasses: Record<string, string> = {
    pulse: 'animate-pulse',
    wave: 'animate-shimmer',
    none: '',
  };

  const style: React.CSSProperties = {};
  if (width) style.width = typeof width === 'number' ? `${width}px` : width;
  if (height) style.height = typeof height === 'number' ? `${height}px` : height;

  return (
    <div
      className={cn(
        'bg-[var(--color-surface-1)]',
        variantClasses[variant],
        animationClasses[animation],
        className
      )}
      style={style}
      aria-hidden="true"
    />
  );
}

/**
 * 文本骨架屏 - 模拟文本行
 */
export function TextSkeleton({ lines = 3, className }: { lines?: number; className?: string }) {
  return (
    <div className={cn('space-y-2', className)}>
      {Array.from({ length: lines }).map((_, i) => (
        <Skeleton
          key={i}
          variant="text"
          className={cn(i === lines - 1 && 'w-3/4')}
        />
      ))}
    </div>
  );
}

/**
 * 头像骨架屏
 */
export function AvatarSkeleton({ size = 40 }: { size?: number }) {
  return (
    <div
      className="rounded-full bg-[var(--color-surface-1)] animate-pulse"
      style={{ width: size, height: size }}
      aria-hidden="true"
    />
  );
}

/**
 * 卡片骨架屏 - 模拟内容卡片
 */
export function CardSkeleton({ className }: { className?: string }) {
  return (
    <div className={cn('p-4 rounded-xl bg-[var(--color-surface-2)] border border-[var(--color-border)] shadow-1', className)}>
      <div className="flex items-start gap-4">
        <AvatarSkeleton size={48} />
        <div className="flex-1 space-y-2">
          <Skeleton variant="text" className="w-3/4 h-5" />
          <Skeleton variant="text" className="w-1/2 h-4" />
          <TextSkeleton lines={2} />
        </div>
      </div>
    </div>
  );
}

/**
 * 简历列表骨架屏
 */
export function ResumeListSkeleton({ count = 3 }: { count?: number }) {
  return (
    <div className="space-y-4">
      {Array.from({ length: count }).map((_, i) => (
        <CardSkeleton key={i} />
      ))}
    </div>
  );
}

/**
 * 模板网格骨架屏
 */
export function TemplateGridSkeleton({ count = 6 }: { count?: number }) {
  return (
    <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-6">
      {Array.from({ length: count }).map((_, i) => (
        <div key={i} className="rounded-xl bg-[var(--color-surface-2)] border border-[var(--color-border)] overflow-hidden shadow-1">
          <Skeleton variant="rectangular" className="w-full h-48 rounded-none" />
          <div className="p-4 space-y-2">
            <Skeleton variant="text" className="w-3/4 h-5" />
            <Skeleton variant="text" className="w-1/2 h-4" />
          </div>
        </div>
      ))}
    </div>
  );
}

/**
 * 导航栏骨架屏
 */
export function NavbarSkeleton() {
  return (
    <nav className="border-b border-[var(--color-border)] bg-[var(--color-surface-0)]/80 backdrop-blur-sm">
      <div className="max-w-7xl mx-auto px-4 py-3 flex items-center justify-between">
        <div className="flex items-center gap-8">
          <Skeleton variant="rectangular" width={120} height={32} className="rounded-lg" />
          <div className="hidden md:flex items-center gap-6">
            <Skeleton variant="text" width={60} />
            <Skeleton variant="text" width={60} />
          </div>
        </div>
        <div className="flex items-center gap-4">
          <AvatarSkeleton size={32} />
          <Skeleton variant="rectangular" width={80} height={32} className="rounded-lg" />
        </div>
      </div>
    </nav>
  );
}

/**
 * 页面加载骨架屏 - 完整页面加载状态
 */
export function PageLoadingSkeleton() {
  return (
    <div className="min-h-screen bg-[var(--color-bg)]">
      <NavbarSkeleton />
      <main className="max-w-7xl mx-auto px-4 py-8">
        <div className="mb-8">
          <Skeleton variant="text" className="w-1/3 h-8 mb-2" />
          <Skeleton variant="text" className="w-1/2 h-4" />
        </div>
        <ResumeListSkeleton count={4} />
      </main>
    </div>
  );
}

/**
 * 表单输入骨架屏
 */
export function InputSkeleton({ className }: { className?: string }) {
  return (
    <div className={cn('space-y-2', className)}>
      <Skeleton variant="text" className="w-20 h-4" />
      <Skeleton variant="rectangular" className="w-full h-10" />
    </div>
  );
}

/**
 * 按钮骨架屏
 */
export function ButtonSkeleton({ width = 100 }: { width?: number | string }) {
  return (
    <Skeleton
      variant="rectangular"
      width={width}
      height={40}
      className="rounded-xl"
    />
  );
}

export default Skeleton;
