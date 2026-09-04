import { useRef } from 'react';
import { Link } from 'react-router-dom';
import { gsap, SplitText, useGSAP, MOTION_OK, FINE_POINTER } from '../../animation/motion';
import { AnimatedCounter } from '../../animation/AnimatedCounter';
import QQLoginButton from '../QQLoginButton';

const Arrow = () => (
  <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" strokeWidth={2} stroke="currentColor" width="18" height="18">
    <path strokeLinecap="round" strokeLinejoin="round" d="M13.5 4.5 21 12m0 0-7.5 7.5M21 12H3" />
  </svg>
);

const Sparkle = () => (
  <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" strokeWidth={2} stroke="currentColor" width="16" height="16">
    <path strokeLinecap="round" strokeLinejoin="round" d="M9.813 15.904 9 18.75l-.813-2.846a4.5 4.5 0 0 0-3.09-3.09L2.25 12l2.846-.813a4.5 4.5 0 0 0 3.09-3.09L9 5.25l.813 2.846a4.5 4.5 0 0 0 3.09 3.09L15.75 12l-2.846.813a4.5 4.5 0 0 0-3.09 3.09ZM18.259 8.715 18 9.75l-.259-1.035a3.375 3.375 0 0 0-2.455-2.456L14.25 6l1.036-.259a3.375 3.375 0 0 0 2.455-2.456L18 2.25l.259 1.035a3.375 3.375 0 0 0 2.456 2.456L21.75 6l-1.035.259a3.375 3.375 0 0 0-2.456 2.456Z" />
  </svg>
);

const heroStats = [
  { value: 10000, suffix: '+', decimals: 0, label: '活跃用户' },
  { value: 50000, suffix: '+', decimals: 0, label: '简历生成' },
  { value: 99.2, suffix: '%', decimals: 1, label: '用户好评' },
  { value: 200, suffix: '+', decimals: 0, label: '精美模板' },
];

export default function HeroSection() {
  const rootRef = useRef<HTMLElement>(null);

  useGSAP(
    (_context, contextSafe) => {
      const root = rootRef.current;
      if (!root) return;

      const mm = gsap.matchMedia();
      mm.add(
        { ok: MOTION_OK, fine: FINE_POINTER },
        (ctx) => {
          const { ok, fine } = ctx.conditions as { ok: boolean; fine: boolean };
          if (!ok) return;

          /* —— 背景声部:光斑各自漂移,纸纹网格静静浮现 —— */
          gsap.from('.lp-hero-grid', { autoAlpha: 0, duration: 1.8, ease: 'silk' });
          gsap.utils.toArray<HTMLElement>('.lp-hero-orb', root).forEach((orb, i) => {
            gsap.from(orb, { autoAlpha: 0, scale: 0.7, duration: 1.4, delay: 0.1 + i * 0.15, ease: 'ink' });
            const core = orb.firstElementChild;
            if (core) {
              gsap.to(core, {
                y: i === 0 ? -34 : 30,
                x: i === 0 ? 22 : -18,
                duration: 7 + i * 2,
                yoyo: true,
                repeat: -1,
                ease: 'sine.inOut',
              });
            }
          });

          /* —— 主时间线:落印 → 逐字落墨 → 副文 → 行动 → 数据 —— */
          const titleEl = root.querySelector<HTMLElement>('.lp-hero-title');
          let chars: HTMLElement[] = [];
          if (titleEl) {
            const split = SplitText.create(titleEl, { type: 'chars', mask: 'chars' });
            chars = split.chars as unknown as HTMLElement[];
            /* 嵌套渐变 span 被切分后 background-clip 失效,
               将渐变类下放到每个字符,让每字独立渲染渐变 */
            chars.forEach((char) => {
              if (char.closest('.gradient-text')) {
                char.classList.add('gradient-text');
              }
            });
          }

          const tl = gsap.timeline({ delay: 0.15, defaults: { ease: 'ink' } });
          tl.from('.lp-hero-badge', { y: 26, autoAlpha: 0, scale: 0.9, duration: 0.55, ease: 'settle' });
          if (chars.length > 0) {
            tl.from(chars, { yPercent: 130, duration: 0.9, stagger: 0.032 }, '-=0.2');
          }
          tl.from('.lp-hero-subtitle', { y: 28, autoAlpha: 0, duration: 0.7 }, '-=0.55')
            .from(
              '.lp-hero-actions > *',
              { y: 22, autoAlpha: 0, scale: 0.94, duration: 0.55, stagger: 0.1, ease: 'settle' },
              '-=0.4'
            )
            .from('.lp-hero-stat', { y: 26, autoAlpha: 0, duration: 0.6, stagger: 0.08 }, '-=0.3');

          /* —— 墨滴滚动提示 —— */
          const cue = root.querySelector('.lp-hero-cue');
          if (cue) {
            tl.from(cue, { autoAlpha: 0, y: -10, duration: 0.6 }, '-=0.2');
            gsap
              .timeline({ repeat: -1, repeatDelay: 0.4 })
              .fromTo('.lp-hero-cue-line', { scaleY: 0, transformOrigin: 'top center' }, { scaleY: 1, duration: 0.75, ease: 'silk' })
              .set('.lp-hero-cue-line', { transformOrigin: 'bottom center' })
              .to('.lp-hero-cue-line', { scaleY: 0, duration: 0.55, ease: 'silk' });
          }

          /* —— 滚动视差:内容沉入纸面 —— */
          gsap.to('.lp-hero-content', {
            y: 96,
            autoAlpha: 0.15,
            ease: 'none',
            scrollTrigger: { trigger: root, start: 'top top', end: 'bottom top', scrub: 0.6 },
          });
          gsap.to('.lp-hero-orb', {
            yPercent: (i) => (i === 0 ? -22 : -40),
            ease: 'none',
            scrollTrigger: { trigger: root, start: 'top top', end: 'bottom top', scrub: 0.8 },
          });
          gsap.to(cue, {
            autoAlpha: 0,
            ease: 'none',
            scrollTrigger: { trigger: root, start: 'top top', end: '20% top', scrub: true },
          });

          /* —— 鼠标视差 + 磁性按钮(精确指针专属) —— */
          const cleanups: Array<() => void> = [];
          if (fine && contextSafe) {
            const orbA = root.querySelector<HTMLElement>('.orb-a');
            const orbB = root.querySelector<HTMLElement>('.orb-b');
            const grid = root.querySelector<HTMLElement>('.lp-hero-grid');
            if (orbA && orbB) {
              const aX = gsap.quickTo(orbA, 'x', { duration: 1.2, ease: 'sine.out' });
              const aY = gsap.quickTo(orbA, 'y', { duration: 1.2, ease: 'sine.out' });
              const bX = gsap.quickTo(orbB, 'x', { duration: 1.4, ease: 'sine.out' });
              const bY = gsap.quickTo(orbB, 'y', { duration: 1.4, ease: 'sine.out' });
              const onMove = contextSafe((event: PointerEvent) => {
                const nx = event.clientX / window.innerWidth - 0.5;
                const ny = event.clientY / window.innerHeight - 0.5;
                aX(nx * 28);
                aY(ny * 20);
                bX(nx * -20);
                bY(ny * -16);
                if (grid) gsap.to(grid, { x: nx * -10, y: ny * -8, duration: 1.6, ease: 'sine.out', overwrite: 'auto' });
              });
              window.addEventListener('pointermove', onMove);
              cleanups.push(() => window.removeEventListener('pointermove', onMove));
            }

            /* 磁性按钮:指尖吸引,离开回弹 */
            root.querySelectorAll<HTMLElement>('.lp-hero-actions a').forEach((btn) => {
              const xTo = gsap.quickTo(btn, 'x', { duration: 0.4, ease: 'power3.out' });
              const yTo = gsap.quickTo(btn, 'y', { duration: 0.4, ease: 'power3.out' });
              const onBtnMove = contextSafe((event: PointerEvent) => {
                const rect = btn.getBoundingClientRect();
                xTo(((event.clientX - rect.left) / rect.width - 0.5) * 14);
                yTo(((event.clientY - rect.top) / rect.height - 0.5) * 10);
              });
              const onBtnLeave = contextSafe(() => {
                gsap.to(btn, { x: 0, y: 0, duration: 0.7, ease: 'elastic.out(1, 0.4)', overwrite: 'auto' });
              });
              btn.addEventListener('pointermove', onBtnMove);
              btn.addEventListener('pointerleave', onBtnLeave);
              cleanups.push(() => {
                btn.removeEventListener('pointermove', onBtnMove);
                btn.removeEventListener('pointerleave', onBtnLeave);
              });
            });
          }
          return () => cleanups.forEach((fn) => fn());
        },
        root
      );

      return () => mm.revert();
    },
    { scope: rootRef }
  );

  return (
    <section className="lp-hero" ref={rootRef}>
      <div className="lp-hero-bg" aria-hidden="true">
        <div className="lp-hero-orb orb-a">
          <div className="lp-hero-orb-core core-vermilion" />
        </div>
        <div className="lp-hero-orb orb-b">
          <div className="lp-hero-orb-core core-celadon" />
        </div>
        <div className="lp-hero-grid" />
      </div>

      <div className="lp-hero-content">
        <div className="lp-hero-badge">
          <Sparkle />
          30秒生成 · 多模型AI驱动 · 完全免费
        </div>

        <h1 className="lp-hero-title">
          30秒<span className="gradient-text">AI生成</span>专业简历
        </h1>

        <p className="lp-hero-subtitle">
          支持 DeepSeek · OpenAI · 小米 MiMo 三大模型
          <br />
          200+ 模板 · AI 智能优化 · 一键导出 PDF/Word
        </p>

        <div className="lp-hero-actions">
          <Link to="/login" className="lp-btn-primary">
            免费开始制作 <Arrow />
          </Link>
          <Link to="/templates" className="lp-btn-secondary">
            浏览模板
          </Link>
          <QQLoginButton size="lg" className="lp-qq-login" />
        </div>

        <div className="lp-hero-stats">
          {heroStats.map((stat) => (
            <div className="lp-hero-stat" key={stat.label}>
              <div className="lp-hero-stat-value">
                <AnimatedCounter value={stat.value} suffix={stat.suffix} decimals={stat.decimals} duration={1.8} delay={1.25} immediate />
              </div>
              <div className="lp-hero-stat-label">{stat.label}</div>
            </div>
          ))}
        </div>
      </div>

      <div className="lp-hero-cue" aria-hidden="true">
        <span className="lp-hero-cue-label">SCROLL</span>
        <span className="lp-hero-cue-line" />
      </div>
    </section>
  );
}
