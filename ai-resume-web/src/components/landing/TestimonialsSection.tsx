import { useSectionReveal } from '../../animation/useSectionReveal';
import { Marquee } from '../../animation/Marquee';

const testimonials = [
  {
    name: '张小明',
    role: '应届生 · 成功入职字节跳动',
    text: '用 AI 简历生成器做了第一份简历，没想到面试邀请率这么高！模板很专业，AI 优化建议特别有用。',
    color: '#f59e0b',
  },
  {
    name: '李思思',
    role: '产品经理 · 成功跳槽阿里',
    text: '从模板选择到 AI 优化，整个流程非常顺畅。导出的 PDF 格式完美，直接投递拿到了理想 offer。',
    color: '#10b981',
  },
  {
    name: '王大伟',
    role: '高级工程师 · 成功入职腾讯',
    text: '作为技术人员，之前做的简历太朴素了。用了这个平台后，简历专业度提升了一个档次，强烈推荐！',
    color: '#38bdf8',
  },
  {
    name: '陈雨桐',
    role: '留学生 · 拿下新加坡 offer',
    text: '中英文简历一键切换太方便了，JD 匹配功能帮我把经历改写得更有针对性，一周收到三个面试。',
    color: '#c084fc',
  },
  {
    name: '刘畅',
    role: '设计师 · 入职独角兽公司',
    text: '模板审美在线，排版细节考究。AI 生成初稿后自己微调了半小时就导出投递，效率拉满。',
    color: '#fb7185',
  },
  {
    name: '赵启航',
    role: '金融分析师 · 春招上岸',
    text: 'ATS 兼容检测让我少走了很多弯路，之前简历总是过不了系统筛选，改完第二天就收到了笔试通知。',
    color: '#34d399',
  },
];

function TestimonialCard({ t }: { t: (typeof testimonials)[number] }) {
  return (
    <div className="lp-testimonial-card">
      <div className="lp-testimonial-stars">★★★★★</div>
      <p className="lp-testimonial-text">“{t.text}”</p>
      <div className="lp-testimonial-author">
        <div className="lp-testimonial-avatar" style={{ background: `${t.color}22`, color: t.color }}>
          {t.name[0]}
        </div>
        <div>
          <div className="lp-testimonial-name">{t.name}</div>
          <div className="lp-testimonial-role">{t.role}</div>
        </div>
      </div>
    </div>
  );
}

export default function TestimonialsSection() {
  const ref = useSectionReveal<HTMLElement>({ splitTitle: false });
  const rowA = testimonials.slice(0, 3);
  const rowB = testimonials.slice(3);

  return (
    <section className="lp-testimonials" ref={ref}>
      <div className="lp-container">
        <div className="lp-section-header">
          <div className="lp-section-badge">用户评价</div>
          <h2 className="lp-section-title">他们都在用</h2>
          <p className="lp-section-subtitle">听听成功拿到 offer 的用户怎么说</p>
        </div>
      </div>
      <div className="lp-testimonials-marquee">
        <Marquee speed={36}>
          {rowA.map((t) => (
            <TestimonialCard key={t.name} t={t} />
          ))}
        </Marquee>
        <Marquee speed={42} reverse>
          {rowB.map((t) => (
            <TestimonialCard key={t.name} t={t} />
          ))}
        </Marquee>
      </div>
    </section>
  );
}
