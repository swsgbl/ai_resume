import { useEffect, useState } from 'react';
import { useScrollAnimation } from './useScrollAnimation';

/**
 * 数字滚动计数动画 — 元素进入视口时从 0 计数到目标值
 * @param end 目标数字
 * @param duration 动画时长 ms
 * @param suffix 后缀 (如 "+", "%")
 */
export function useCountUp(end: number, duration = 2000, suffix = '') {
  const { ref, isVisible } = useScrollAnimation<HTMLSpanElement>(0.3);
  const [display, setDisplay] = useState(`0${suffix}`);

  useEffect(() => {
    if (!isVisible) return;

    let startTime: number | null = null;
    let rafId: number;

    const animate = (timestamp: number) => {
      if (!startTime) startTime = timestamp;
      const progress = Math.min((timestamp - startTime) / duration, 1);

      // easeOutExpo 缓动
      const eased = progress === 1 ? 1 : 1 - Math.pow(2, -10 * progress);
      const current = Math.floor(eased * end);

      setDisplay(`${current.toLocaleString()}${suffix}`);

      if (progress < 1) {
        rafId = requestAnimationFrame(animate);
      }
    };

    rafId = requestAnimationFrame(animate);
    return () => cancelAnimationFrame(rafId);
  }, [isVisible, end, duration, suffix]);

  return { ref, display };
}
