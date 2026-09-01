import { useRef } from 'react';
import gsap from 'gsap';
import { ScrollTrigger } from 'gsap/ScrollTrigger';
import { useGSAP } from '@gsap/react';
import './MotionPage.css';

gsap.registerPlugin(ScrollTrigger, useGSAP);

/* 应用页面的进场/滚动声部(落地页自带编排,经 data-motion-ignore 跳过) */
const REVEAL_SELECTOR = [
  '.card-glass',
  '.card-hover',
  '.card-neon',
  '.card',
  'article',
  'form',
  '[class*="p-4"][class*="bg-[#0B1E3A]"]',
  '[class*="p-5"][class*="bg-[#0B1E3A]"]',
  '[class*="p-6"][class*="bg-[#0B1E3A]"]',
].join(', ');

const CARD_SELECTOR = [
  '.card-glass',
  '.card-hover',
  '.card-neon',
].join(', ');

const ACTION_SELECTOR = [
  '.btn-primary',
  '.btn-secondary',
  '.btn-accent',
].join(', ');

function isForeground(element: HTMLElement) {
  return !element.closest('nav, header, footer, [data-motion-ignore]');
}

function selectForeground(root: HTMLElement, selector: string, limit?: number) {
  const elements = Array.from(root.querySelectorAll<HTMLElement>(selector)).filter(isForeground);
  return typeof limit === 'number' ? elements.slice(0, limit) : elements;
}

function isNearViewport(element: HTMLElement) {
  if (typeof window === 'undefined') return false;
  return element.getBoundingClientRect().top < window.innerHeight * 1.35;
}

export default function MotionPage({ children }: { children: React.ReactNode }) {
  const rootRef = useRef<HTMLDivElement>(null);
  const progressRef = useRef<HTMLSpanElement>(null);

  useGSAP(
    (_context, contextSafe) => {
      const root = rootRef.current;
      if (!root) return;

      /* 路由切换回到页首,让入场编排始终从第一屏讲起 */
      window.scrollTo(0, 0);

      const media = gsap.matchMedia();

      media.add(
        {
          standard: '(prefers-reduced-motion: no-preference)',
          finePointer: '(hover: hover) and (pointer: fine)',
        },
        (context) => {
          const conditions = context.conditions;
          if (!conditions?.standard || !contextSafe) return;

          gsap.defaults({ duration: 0.65, ease: 'power3.out' });

          /* 顶部阅读进度:朱砂墨线 */
          if (progressRef.current) {
            gsap.fromTo(
              progressRef.current,
              { scaleX: 0 },
              {
                scaleX: 1,
                ease: 'none',
                scrollTrigger: {
                  trigger: root,
                  start: 'top top',
                  end: 'max',
                  scrub: 0.25,
                },
              }
            );
          }

          /* 页面入场:整体浮现 → 标题声部 → 行动声部 */
          const headings = selectForeground(root, 'h1, h2, h3')
            .filter(isNearViewport)
            .slice(0, 12);
          const actions = selectForeground(root, ACTION_SELECTOR)
            .filter(isNearViewport)
            .slice(0, 8);

          const timeline = gsap.timeline();
          timeline.fromTo(
            root,
            { opacity: 0, y: 14 },
            { opacity: 1, y: 0, duration: 0.42, ease: 'power2.out' }
          );

          if (headings.length > 0) {
            timeline.fromTo(
              headings,
              { y: 30, autoAlpha: 0 },
              { y: 0, autoAlpha: 1, stagger: 0.06 },
              '-=0.12'
            );
          }

          if (actions.length > 0) {
            timeline.fromTo(
              actions,
              { y: 18, autoAlpha: 0, scale: 0.96 },
              { y: 0, autoAlpha: 1, scale: 1, stagger: 0.055 },
              '-=0.35'
            );
          }

          /* 滚动声部:进入视口的卡片声部浮现 */
          const registeredReveals = new Set<HTMLElement>();
          const playReveals = (elements: Element[]) => {
            gsap.to(elements, {
              y: 0,
              autoAlpha: 1,
              scale: 1,
              duration: 0.7,
              ease: 'power3.out',
              stagger: { amount: 0.3 },
              overwrite: true,
            });
          };
          const registerReveals = (elements: HTMLElement[]) => {
            const newElements = elements.filter(
              (element) => isForeground(element) && !registeredReveals.has(element)
            );
            if (newElements.length === 0) return;

            newElements.forEach((element) => {
              registeredReveals.add(element);
              element.dataset.motionReveal = '';
            });

            gsap.set(newElements, { y: 42, autoAlpha: 0, scale: 0.985 });
            const viewportHeight = window.innerHeight || 0;
            const immediate = newElements.filter(
              (element) => element.getBoundingClientRect().top < viewportHeight * 0.88
            );
            const deferred = newElements.filter(
              (element) => !immediate.includes(element)
            );

            if (immediate.length > 0) playReveals(immediate);

            ScrollTrigger.batch(deferred, {
              start: 'top 88%',
              once: true,
              onEnter: playReveals,
            });
          };

          registerReveals(selectForeground(root, REVEAL_SELECTOR).slice(0, 80));

          const cleanupFunctions: Array<() => void> = [];
          const interactiveControls = new Set<HTMLElement>();

          const registerTilt = (elements: HTMLElement[]) => {
            elements.forEach((element) => {
              if (interactiveControls.has(element)) return;
              interactiveControls.add(element);
              element.dataset.motionTilt = '';

              gsap.set(element, { transformPerspective: 850 });
              const rotateXTo = gsap.quickTo(element, 'rotationX', {
                duration: 0.35,
                ease: 'power3.out',
              });
              const rotateYTo = gsap.quickTo(element, 'rotationY', {
                duration: 0.35,
                ease: 'power3.out',
              });

              const handleMove = contextSafe((event: PointerEvent) => {
                const rect = element.getBoundingClientRect();
                const x = (event.clientX - rect.left) / rect.width - 0.5;
                const y = (event.clientY - rect.top) / rect.height - 0.5;
                rotateXTo(y * -7);
                rotateYTo(x * 9);
              });
              const handleEnter = contextSafe(() => {
                gsap.to(element, { scale: 1.015, duration: 0.25, overwrite: 'auto' });
              });
              const handleLeave = contextSafe(() => {
                rotateXTo(0);
                rotateYTo(0);
                gsap.to(element, { scale: 1, duration: 0.35, overwrite: 'auto' });
              });

              element.addEventListener('pointermove', handleMove);
              element.addEventListener('pointerenter', handleEnter);
              element.addEventListener('pointerleave', handleLeave);
              cleanupFunctions.push(() => {
                element.removeEventListener('pointermove', handleMove);
                element.removeEventListener('pointerenter', handleEnter);
                element.removeEventListener('pointerleave', handleLeave);
              });
            });
          };

          const registerMagnetic = (elements: HTMLElement[]) => {
            elements.forEach((element) => {
              if (interactiveControls.has(element)) return;
              interactiveControls.add(element);
              element.dataset.motionMagnetic = '';

              const xTo = gsap.quickTo(element, 'x', {
                duration: 0.32,
                ease: 'power3.out',
              });
              const yTo = gsap.quickTo(element, 'y', {
                duration: 0.32,
                ease: 'power3.out',
              });

              const handleMove = contextSafe((event: PointerEvent) => {
                const rect = element.getBoundingClientRect();
                const x = (event.clientX - rect.left) / rect.width - 0.5;
                const y = (event.clientY - rect.top) / rect.height - 0.5;
                xTo(x * 12);
                yTo(y * 9);
              });
              const handleLeave = contextSafe(() => {
                xTo(0);
                yTo(0);
              });

              element.addEventListener('pointermove', handleMove);
              element.addEventListener('pointerleave', handleLeave);
              cleanupFunctions.push(() => {
                element.removeEventListener('pointermove', handleMove);
                element.removeEventListener('pointerleave', handleLeave);
              });
            });
          };

          /* 按压反馈:落指微缩,松手回弹 */
          const registerPress = (elements: HTMLElement[]) => {
            elements.forEach((element) => {
              if (element.dataset.motionPress) return;
              element.dataset.motionPress = '';

              const handleDown = contextSafe(() => {
                gsap.to(element, { scale: 0.965, duration: 0.12, overwrite: 'auto' });
              });
              const handleUp = contextSafe(() => {
                gsap.to(element, { scale: 1, duration: 0.32, ease: 'back.out(2)', overwrite: 'auto' });
              });

              element.addEventListener('pointerdown', handleDown);
              element.addEventListener('pointerup', handleUp);
              element.addEventListener('pointerleave', handleUp);
              cleanupFunctions.push(() => {
                element.removeEventListener('pointerdown', handleDown);
                element.removeEventListener('pointerup', handleUp);
                element.removeEventListener('pointerleave', handleUp);
              });
            });
          };

          if (conditions.finePointer) {
            registerTilt(selectForeground(root, CARD_SELECTOR).slice(0, 48));
            registerMagnetic(selectForeground(root, ACTION_SELECTOR).slice(0, 32));
          }
          registerPress(selectForeground(root, ACTION_SELECTOR).slice(0, 48));

          let animationFrame = 0;
          const observer = new MutationObserver(() => {
            if (animationFrame) return;
            animationFrame = requestAnimationFrame(() => {
              animationFrame = 0;
              registerReveals(selectForeground(root, REVEAL_SELECTOR).slice(0, 80));
              if (conditions.finePointer) {
                registerTilt(selectForeground(root, CARD_SELECTOR).slice(0, 48));
                registerMagnetic(selectForeground(root, ACTION_SELECTOR).slice(0, 32));
              }
              registerPress(selectForeground(root, ACTION_SELECTOR).slice(0, 48));
            });
          });
          observer.observe(root, { childList: true, subtree: true });

          if (document.fonts) {
            void document.fonts.ready.then(() => {
              if (root.isConnected) ScrollTrigger.refresh();
            });
          }

          return () => {
            observer.disconnect();
            if (animationFrame) cancelAnimationFrame(animationFrame);
            cleanupFunctions.forEach((cleanup) => cleanup());
          };
        },
        root
      );

      return () => media.revert();
    },
    { scope: rootRef }
  );

  return (
    <div ref={rootRef} className="motion-page">
      <span ref={progressRef} className="motion-progress" aria-hidden="true" />
      {children}
    </div>
  );
}
