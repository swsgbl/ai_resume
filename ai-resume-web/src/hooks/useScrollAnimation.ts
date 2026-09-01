import { useEffect, useRef, useState } from 'react';

/**
 * Intersection Observer hook — 元素进入视口时触发动画
 * 返回 ref，绑定到目标元素即可
 */
export function useScrollAnimation<T extends HTMLElement = HTMLDivElement>(
  threshold = 0.15,
  rootMargin = '0px 0px -60px 0px'
) {
  const ref = useRef<T>(null);
  const [isVisible, setIsVisible] = useState(false);

  useEffect(() => {
    const el = ref.current;
    if (!el) return;

    const observer = new IntersectionObserver(
      ([entry]) => {
        if (entry.isIntersecting) {
          setIsVisible(true);
          observer.unobserve(el);
        }
      },
      { threshold, rootMargin }
    );

    observer.observe(el);
    return () => observer.disconnect();
  }, [threshold, rootMargin]);

  return { ref, isVisible };
}

/**
 * 批量监听 — 给多个子元素添加依次延迟动画
 */
export function useStaggerAnimation<T extends HTMLElement = HTMLDivElement>(
  count: number,
  baseDelay = 100
) {
  const containerRef = useRef<T>(null);
  const [visibleItems, setVisibleItems] = useState<Set<number>>(new Set());

  useEffect(() => {
    const el = containerRef.current;
    if (!el) return;

    const observer = new IntersectionObserver(
      ([entry]) => {
        if (entry.isIntersecting) {
          for (let i = 0; i < count; i++) {
            setTimeout(() => {
              setVisibleItems((prev) => new Set(prev).add(i));
            }, i * baseDelay);
          }
          observer.unobserve(el);
        }
      },
      { threshold: 0.1 }
    );

    observer.observe(el);
    return () => observer.disconnect();
  }, [count, baseDelay]);

  return { containerRef, visibleItems };
}
