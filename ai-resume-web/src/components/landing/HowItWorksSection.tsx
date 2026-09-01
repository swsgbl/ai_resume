import { useRef } from 'react';
import { gsap, useGSAP, MOTION_OK } from '../../animation/motion';
import { useSectionReveal } from '../../animation/useSectionReveal';

const steps = [
  {
    num: '1',
    title: '注册 / 登录',
    desc: '30 秒完成注册，立即开始创建你的专业简历。支持邮箱和第三方登录。',
  },
  {
    num: '2',
    title: 'AI 生成 / 编辑',
    desc: '输入基本信息，AI 自动生成简历初稿。选择模板，自定义编辑内容，实时预览效果。',
  },
  {
    num: '3',
    title: '导出 / 投递',
    desc: '一键导出 PDF、Word 或 HTML 格式。直接投递，让 HR 眼前一亮。',
  },
];

export default function HowItWorksSection() {
  const ref = useSectionReveal<HTMLElement>({
    children: '.lp-step',
    childFrom: { y: 56, autoAlpha: 0 },
    childStagger: 0.16,
  });
  const lineRef = useRef<SVGPathElement>(null);

  /* 笔画线随滚动绘出,朱砂起笔、青瓷收笔;数字印章依次落定 */
  useGSAP(
    () => {
      const scopeRoot = ref.current;
      if (!scopeRoot) return;

      const mm = gsap.matchMedia();
      mm.add(
        { ok: MOTION_OK, desktop: '(min-width: 769px)' },
        (ctx) => {
          const { ok, desktop } = ctx.conditions as { ok: boolean; desktop: boolean };
          if (!ok) return;

          const path = lineRef.current;
          if (path && desktop) {
            gsap.fromTo(
              path,
              { drawSVG: '0% 0%' },
              {
                drawSVG: '0% 100%',
                ease: 'none',
                scrollTrigger: {
                  trigger: '.lp-steps',
                  start: 'top 78%',
                  end: 'top 30%',
                  scrub: 0.8,
                },
              }
            );
          }

          gsap.utils.toArray<HTMLElement>('.lp-step-number', scopeRoot).forEach((num) => {
            gsap.from(num, {
              scale: 0,
              rotation: -22,
              duration: 0.55,
              ease: 'settle',
              scrollTrigger: { trigger: num, start: 'top 86%', once: true },
            });
          });
        },
        scopeRoot
      );
      return () => mm.revert();
    },
    { scope: ref }
  );

  return (
    <section className="lp-how" ref={ref}>
      <div className="lp-container">
        <div className="lp-section-header">
          <div className="lp-section-badge">使用流程</div>
          <h2 className="lp-section-title">三步搞定完美简历</h2>
          <p className="lp-section-subtitle">简单三步，从零到投递</p>
        </div>
        <div className="lp-steps">
          <svg className="lp-steps-line" viewBox="0 0 1000 8" preserveAspectRatio="none" aria-hidden="true">
            <defs>
              <linearGradient id="lp-steps-ink" x1="0" y1="0" x2="1" y2="0">
                <stop offset="0" stopColor="#4FD8EB" stopOpacity="0.9" />
                <stop offset="0.5" stopColor="#8FA8C0" stopOpacity="0.5" />
                <stop offset="1" stopColor="#7DDF9A" stopOpacity="0.9" />
              </linearGradient>
            </defs>
            <path ref={lineRef} d="M0 4 H1000" fill="none" stroke="url(#lp-steps-ink)" strokeWidth="2" />
          </svg>
          {steps.map((s) => (
            <div key={s.num} className="lp-step">
              <div className="lp-step-number">{s.num}</div>
              <h3 className="lp-step-title">{s.title}</h3>
              <p className="lp-step-desc">{s.desc}</p>
            </div>
          ))}
        </div>
      </div>
    </section>
  );
}
