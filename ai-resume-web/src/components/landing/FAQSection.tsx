import { useRef, useState } from 'react';
import { gsap, useGSAP } from '../../animation/motion';
import { useSectionReveal } from '../../animation/useSectionReveal';

const faqs = [
  {
    q: 'AI 简历生成器真的免费吗？',
    a: '是的！基础功能完全免费，包括 3 份简历、20+ 模板和 PDF 导出。如果需要更多模板和高级功能，可以升级到专业版。',
  },
  {
    q: 'AI 生成的简历质量如何？',
    a: '我们的 AI 基于最新大语言模型，经过海量简历数据训练。生成的内容专业、精准、符合 HR 审美。99.2% 的用户对 AI 优化效果表示满意。',
  },
  {
    q: '我的数据安全吗？',
    a: '我们采用银行级加密保护您的数据。简历内容仅您自己可见，不会泄露给第三方。支持随时删除账户和所有数据。',
  },
  {
    q: '导出的 PDF 简历会有水印吗？',
    a: '免费版导出的 PDF 不带水印，直接可用于投递。专业版还支持 Word 和 HTML 格式导出，满足不同投递需求。',
  },
  {
    q: '支持哪些简历模板风格？',
    a: '目前提供 200+ 模板，涵盖简约风、商务风、创意风、技术风等多种风格。适用于应届生、社招、考研、留学等不同场景。',
  },
  {
    q: '可以用手机编辑简历吗？',
    a: 'Web 版支持手机浏览器访问和编辑。Android 和 iOS 原生客户端正在开发中，即将上线。',
  },
];

export default function FAQSection() {
  const [openIndex, setOpenIndex] = useState<number | null>(0);
  const ref = useSectionReveal<HTMLElement>({
    children: '.lp-faq-item',
    childFrom: { y: 36, autoAlpha: 0 },
    childStagger: 0.07,
  });
  const answerRefs = useRef<Array<HTMLDivElement | null>>([]);

  const { contextSafe } = useGSAP(() => {}, { scope: ref });

  /* 手风琴:高度丝绸般展开/收起,箭头随行 */
  const toggle = contextSafe((index: number) => {
    const next = openIndex === index ? null : index;
    setOpenIndex(next);

    const reduceMotion =
      typeof window !== 'undefined' &&
      window.matchMedia('(prefers-reduced-motion: reduce)').matches;
    if (reduceMotion) return; /* CSS 类切换即时呈现 */

    answerRefs.current.forEach((el, i) => {
      if (!el) return;
      gsap.to(el, {
        height: i === next ? 'auto' : 0,
        autoAlpha: i === next ? 1 : 0,
        duration: 0.5,
        ease: 'silk',
        overwrite: 'auto',
      });
    });
  });

  return (
    <section className="lp-faq" ref={ref}>
      <div className="lp-container">
        <div className="lp-section-header">
          <div className="lp-section-badge">常见问题</div>
          <h2 className="lp-section-title">你可能想知道</h2>
        </div>
        <div className="lp-faq-list">
          {faqs.map((faq, i) => (
            <div key={i} className={`lp-faq-item${openIndex === i ? ' open' : ''}`}>
              <button
                className="lp-faq-question"
                onClick={() => toggle(i)}
                aria-expanded={openIndex === i}
              >
                {faq.q}
                <svg
                  className={`lp-faq-arrow${openIndex === i ? ' open' : ''}`}
                  xmlns="http://www.w3.org/2000/svg"
                  fill="none"
                  viewBox="0 0 24 24"
                  strokeWidth={2}
                  stroke="currentColor"
                  width="20"
                  height="20"
                >
                  <path strokeLinecap="round" strokeLinejoin="round" d="m19.5 8.25-7.5 7.5-7.5-7.5" />
                </svg>
              </button>
              <div
                className="lp-faq-answer"
                ref={(el) => {
                  answerRefs.current[i] = el;
                }}
              >
                <p className="lp-faq-answer-inner">{faq.a}</p>
              </div>
            </div>
          ))}
        </div>
      </div>
    </section>
  );
}
