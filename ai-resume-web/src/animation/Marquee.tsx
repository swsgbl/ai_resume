import { useRef } from 'react';
import { gsap, useGSAP, MOTION_OK } from './motion';

interface MarqueeProps {
  children: React.ReactNode;
  /** 滚动一圈的秒数(越小越快) */
  speed?: number;
  /** 反向滚动 */
  reverse?: boolean;
  /** 悬停时减速凝视 */
  pauseOnHover?: boolean;
  className?: string;
}

/**
 * 无缝跑马灯 — 内容渲染两份,track 位移 50% 循环。
 * 减少动效偏好下第二份自动隐藏,内容静止呈现。
 */
export function Marquee({
  children,
  speed = 28,
  reverse = false,
  pauseOnHover = true,
  className = '',
}: MarqueeProps) {
  const rootRef = useRef<HTMLDivElement>(null);

  useGSAP(
    () => {
      const root = rootRef.current;
      if (!root) return;
      const track = root.querySelector<HTMLElement>('[data-marquee-track]');
      if (!track) return;

      const mm = gsap.matchMedia();
      mm.add(MOTION_OK, () => {
        if (reverse) gsap.set(track, { xPercent: -50 });
        const tween = gsap.to(track, {
          xPercent: reverse ? 0 : -50,
          ease: 'none',
          duration: speed,
          repeat: -1,
        });

        if (!pauseOnHover) return;
        const enter = () => gsap.to(tween, { timeScale: 0.12, duration: 0.5, overwrite: 'auto' });
        const leave = () => gsap.to(tween, { timeScale: 1, duration: 0.5, overwrite: 'auto' });
        root.addEventListener('pointerenter', enter);
        root.addEventListener('pointerleave', leave);
        return () => {
          root.removeEventListener('pointerenter', enter);
          root.removeEventListener('pointerleave', leave);
        };
      });
      return () => mm.revert();
    },
    { scope: rootRef, dependencies: [speed, reverse, pauseOnHover], revertOnUpdate: true }
  );

  return (
    <div ref={rootRef} className={`marquee ${className}`}>
      <div data-marquee-track className="marquee-track">
        <div className="marquee-group">{children}</div>
        <div className="marquee-group" data-marquee-copy aria-hidden="true">
          {children}
        </div>
      </div>
    </div>
  );
}
