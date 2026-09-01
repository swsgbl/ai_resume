import { useRef } from 'react';
import { gsap, useGSAP, MOTION_OK } from './motion';

interface AnimatedCounterProps {
  /** 目标数值 */
  value: number;
  prefix?: string;
  suffix?: string;
  /** 小数位数(如 99.2% 传 1) */
  decimals?: number;
  /** 计数时长(秒) */
  duration?: number;
  /** 延迟启动(秒),用于与入场时间线对齐 */
  delay?: number;
  className?: string;
  /** true 时不等待进入视口,立即计数(首屏用) */
  immediate?: boolean;
}

function format(value: number, decimals: number, prefix: string, suffix: string) {
  return `${prefix}${value.toLocaleString('en-US', {
    minimumFractionDigits: decimals,
    maximumFractionDigits: decimals,
  })}${suffix}`;
}

/**
 * 数字计数 — ink 缓动从 0 滚动到目标值,千分位格式化。
 * 无 JS 动画环境(测试/减少动效偏好)直接呈现最终数值。
 */
export function AnimatedCounter({
  value,
  prefix = '',
  suffix = '',
  decimals = 0,
  duration = 1.6,
  delay = 0,
  className,
  immediate = false,
}: AnimatedCounterProps) {
  const rootRef = useRef<HTMLSpanElement>(null);

  useGSAP(
    () => {
      const el = rootRef.current;
      if (!el) return;

      const mm = gsap.matchMedia();
      mm.add(MOTION_OK, () => {
        const state = { v: 0 };
        el.textContent = format(0, decimals, prefix, suffix);
        gsap.to(state, {
          v: value,
          duration,
          delay,
          ease: 'ink',
          ...(immediate
            ? {}
            : { scrollTrigger: { trigger: el, start: 'top 90%', once: true } }),
          onUpdate: () => {
            el.textContent = format(state.v, decimals, prefix, suffix);
          },
        });
      });
      return () => mm.revert();
    },
    {
      scope: rootRef,
      dependencies: [value, prefix, suffix, decimals, duration, delay, immediate],
      revertOnUpdate: true,
    }
  );

  return (
    <span ref={rootRef} className={className}>
      {format(value, decimals, prefix, suffix)}
    </span>
  );
}
