import { useRef } from 'react';
import { gsap, SplitText, useGSAP, MOTION_OK } from './motion';

interface SectionRevealOptions {
  /** 进入视口时依次浮现的子元素选择器(如卡片网格) */
  children?: string;
  /** 子元素起始状态,默认自下方浮起 */
  childFrom?: gsap.TweenVars;
  /** 子元素交错间隔(秒) */
  childStagger?: number;
  /** 触发位置,默认元素顶部进入视口 80% 时 */
  start?: string;
  /** 标题逐字揭示(SplitText);CJK 按字切分 */
  splitTitle?: boolean;
}

/**
 * 区块进场编排 — 徽章落印 → 标题逐字 → 副标题浮现 → 子元素声部交错进场。
 * 所有动画在 prefers-reduced-motion: no-preference 下才创建。
 */
export function useSectionReveal<T extends HTMLElement = HTMLElement>(
  options: SectionRevealOptions = {}
) {
  const {
    children: childrenSelector,
    childFrom = { y: 56, autoAlpha: 0 },
    childStagger = 0.08,
    start = 'top 80%',
    splitTitle = true,
  } = options;

  const ref = useRef<T>(null);

  useGSAP(
    () => {
      const root = ref.current;
      if (!root) return;

      const mm = gsap.matchMedia();
      mm.add(MOTION_OK, () => {
        /* 标题区:徽章 → 标题逐字 → 副标题 */
        const header = root.querySelector<HTMLElement>('.lp-section-header');
        if (header) {
          const badge = header.querySelector<HTMLElement>('.lp-section-badge');
          const subtitle = header.querySelector<HTMLElement>('.lp-section-subtitle');

          let titleTween: gsap.core.Tween | null = null;
          if (splitTitle) {
            const title = header.querySelector<HTMLElement>('.lp-section-title');
            if (title) {
              const split = SplitText.create(title, { type: 'chars' });
              if (split.chars.length > 0) {
                gsap.set(title, { transformPerspective: 600 });
                titleTween = gsap.from(
                  split.chars,
                  {
                    yPercent: 70,
                    autoAlpha: 0,
                    rotationX: -50,
                    transformOrigin: '50% 100%',
                    duration: 0.7,
                    ease: 'ink',
                    stagger: 0.022,
                    paused: true,
                  }
                );
              }
            }
          }

          const headerTl = gsap.timeline({
            scrollTrigger: { trigger: header, start, once: true },
          });
          if (badge) {
            headerTl.from(badge, {
              y: 18,
              autoAlpha: 0,
              scale: 0.92,
              duration: 0.5,
              ease: 'settle',
            });
          }
          if (titleTween) {
            headerTl.add(() => titleTween?.play(), badge ? '-=0.28' : 0);
          }
          if (subtitle) {
            headerTl.from(
              subtitle,
              { y: 22, autoAlpha: 0, duration: 0.6, ease: 'ink' },
              '-=0.35'
            );
          }
        }

        /* 子元素声部 */
        if (childrenSelector) {
          const items = gsap.utils.toArray<HTMLElement>(childrenSelector, root);
          if (items.length > 0) {
            gsap.from(items, {
              ...childFrom,
              duration: 0.8,
              ease: 'ink',
              stagger: childStagger,
              scrollTrigger: { trigger: items[0], start, once: true },
            });
          }
        }
      });
      return () => mm.revert();
    },
    { scope: ref }
  );

  return ref;
}
