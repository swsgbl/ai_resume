import { Link } from 'react-router-dom';
import { SEO } from '../components/SEO';
import './TraePage.css';

const TRAE_URL = 'https://www.trae.ai/s/WzZjEx';

export default function TraePage() {
  return (
    <>
      <SEO
        title="AI简历生成器 - 免费在线智能简历制作工具 | ndtool"
        description="免费AI简历生成器，一键生成专业简历。50+精美模板，AI智能优化，支持PDF/Word导出。应届生、职场转型首选在线简历工具。"
      />
      <div className="trae-page" style={{ paddingTop: '64px' }}>
        {/* Navigation replaced by global PublicNavbar via PublicLayout */}

        {/* Hero */}
        <section className="lp-hero">
          <div className="lp-container lp-hero-content">
            <div className="lp-badge">
              <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" strokeWidth={2} stroke="currentColor" width="16" height="16"><path strokeLinecap="round" strokeLinejoin="round" d="M9.813 15.904 9 18.75l-.813-2.846a4.5 4.5 0 0 0-3.09-3.09L2.25 12l2.846-.813a4.5 4.5 0 0 0 3.09-3.09L9 5.25l.813 2.846a4.5 4.5 0 0 0 3.09 3.09L15.75 12l-2.846.813a4.5 4.5 0 0 0-3.09 3.09ZM18.259 8.715 18 9.75l-.259-1.035a3.375 3.375 0 0 0-2.455-2.456L14.25 6l1.036-.259a3.375 3.375 0 0 0 2.455-2.456L18 2.25l.259 1.035a3.375 3.375 0 0 0 2.456 2.456L21.75 6l-1.035.259a3.375 3.375 0 0 0-2.456 2.456Z" /></svg>
              AI 驱动简历生成
            </div>
            <h1>AI 一键生成专业简历</h1>
            <p className="lp-hero-sub">50+ 精美模板 · AI 智能优化 · PDF/Word 导出</p>
            <div className="lp-hero-cta-group">
              <a href={TRAE_URL} target="_blank" rel="noopener" className="lp-hero-cta">
                立即免费体验
                <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" strokeWidth={2} stroke="currentColor" width="20" height="20"><path strokeLinecap="round" strokeLinejoin="round" d="M13.5 4.5 21 12m0 0-7.5 7.5M21 12H3" /></svg>
              </a>
            </div>
            <p className="lp-hero-note">
              <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" strokeWidth={2} stroke="currentColor" width="16" height="16"><path strokeLinecap="round" strokeLinejoin="round" d="M12 18v-5.25m0 0a6.01 6.01 0 0 0 1.5-.189m-1.5.189a6.01 6.01 0 0 1-1.5-.189m3.75 7.478a12.06 12.06 0 0 1-4.5 0m3.75 2.383a14.406 14.406 0 0 1-3 0M14.25 18v-.192c0-.983.658-1.823 1.508-2.316a7.5 7.5 0 1 0-7.517 0c.85.493 1.509 1.333 1.509 2.316V18" /></svg>
              此链接注册免费使用
            </p>
          </div>
        </section>

        {/* Stats */}
        <section className="lp-stats">
          <div className="lp-container">
            <div className="lp-stats-header">
              <h2 className="lp-section-title">震撼优势</h2>
              <p className="lp-section-sub">用数据说话，体验前所未有的编程加速</p>
            </div>
            <div className="lp-stats-grid">
              <div className="lp-stat-card">
                <div className="lp-stat-icon">
                  <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" strokeWidth={2} stroke="currentColor"><path strokeLinecap="round" strokeLinejoin="round" d="M3.75 13.5l10.5-11.25L12 10.5h8.25L9.75 21.75 12 13.5H3.75z" /></svg>
                </div>
                <span className="lp-stat-number">10X</span>
                <h3 className="lp-stat-title">编程效率</h3>
                <p className="lp-stat-desc">智能代码补全和自动重构，让开发速度提升10倍</p>
              </div>
              <div className="lp-stat-card">
                <div className="lp-stat-icon">
                  <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" strokeWidth={2} stroke="currentColor"><path strokeLinecap="round" strokeLinejoin="round" d="M9 12.75 11.25 15 15 9.75m-3-7.036A11.959 11.959 0 0 1 3.598 6 11.99 11.99 0 0 0 3 9.749c0 5.592 3.824 10.29 9 11.623 5.176-1.332 9-6.03 9-11.622 0-1.31-.21-2.571-.598-3.751h-.152c-3.196 0-6.1-1.248-8.25-3.285Z" /></svg>
                </div>
                <span className="lp-stat-number">95%</span>
                <h3 className="lp-stat-title">错误减少</h3>
                <p className="lp-stat-desc">AI实时检测和修复bug，大幅减少代码错误率</p>
              </div>
              <div className="lp-stat-card">
                <div className="lp-stat-icon">
                  <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" strokeWidth={2} stroke="currentColor"><path strokeLinecap="round" strokeLinejoin="round" d="M12 6v6h4.5m4.5 0a9 9 0 1 1-18 0 9 9 0 0 1 18 0Z" /></svg>
                </div>
                <span className="lp-stat-number">24/7</span>
                <h3 className="lp-stat-title">AI助手</h3>
                <p className="lp-stat-desc">全天候智能编程助手，随时解答编程问题</p>
              </div>
            </div>
          </div>
        </section>

        {/* Features */}
        <section className="lp-features">
          <div className="lp-container">
            <h2 className="lp-section-title">核心功能特性</h2>
            <div className="lp-features-grid">
              {[
                { title: '智能代码补全', desc: '基于深度学习的代码补全，准确预测编程意图，比传统IDE智能100倍' },
                { title: '实时错误检测', desc: 'AI实时分析代码，提前发现潜在bug和性能问题，并提供智能修复建议' },
                { title: '自动代码重构', desc: '一键智能重构代码，优化结构、提升性能，让代码更加优雅高效' },
                { title: '智能文档生成', desc: '自动生成API文档、代码注释和技术文档，节省大量文档编写时间' },
                { title: '多语言支持', desc: '支持Python、JavaScript、Java、C++等50+主流编程语言' },
                { title: '云端协作', desc: '实时云端同步，团队协作无缝衔接，支持多人同时编辑' },
              ].map((f) => (
                <div key={f.title} className="lp-feature-card">
                  <div className="lp-feature-icon">
                    <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" strokeWidth={2} stroke="currentColor"><path strokeLinecap="round" strokeLinejoin="round" d="M9.813 15.904 9 18.75l-.813-2.846a4.5 4.5 0 0 0-3.09-3.09L2.25 12l2.846-.813a4.5 4.5 0 0 0 3.09-3.09L9 5.25l.813 2.846a4.5 4.5 0 0 0 3.09 3.09L15.75 12l-2.846.813a4.5 4.5 0 0 0-3.09 3.09Z" /></svg>
                  </div>
                  <h3 className="lp-feature-title">{f.title}</h3>
                  <p className="lp-feature-desc">{f.desc}</p>
                </div>
              ))}
            </div>
          </div>
        </section>

        {/* Comparison */}
        <section className="lp-comparison">
          <div className="lp-container">
            <h2 className="lp-section-title">全面分析</h2>
            <div className="lp-comparison-grid">
              <div className="lp-pros">
                <h3>
                  <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" strokeWidth={2} stroke="currentColor" width="22" height="22"><path strokeLinecap="round" strokeLinejoin="round" d="M9 12.75 11.25 15 15 9.75M21 12a9 9 0 1 1-18 0 9 9 0 0 1 18 0Z" /></svg>
                  巨大优势
                </h3>
                <ul>
                  {['编程效率提升10倍 - 智能补全和自动生成代码', 'AI智能程度业界领先 - 基于最新大模型技术', '大幅降低开发成本 - 减少人力和时间投入', '代码质量显著提升 - 自动优化和重构', '学习曲线平缓 - 新手快速上手', '支持所有主流语言 - 一站式开发环境', '团队协作效率翻倍 - 云端实时同步', '项目交付速度提升 - 赶工期神器', '安全性更高 - AI安全漏洞检测', '持续更新升级 - AI模型不断进化'].map((t) => (
                    <li key={t}>
                      <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" strokeWidth={2} stroke="currentColor"><path strokeLinecap="round" strokeLinejoin="round" d="M4.5 12.75l6 6 9-13.5" /></svg>
                      <strong>{t.split(' - ')[0]}</strong> - {t.split(' - ')[1]}
                    </li>
                  ))}
                </ul>
              </div>
              <div className="lp-cons">
                <h3>
                  <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" strokeWidth={2} stroke="currentColor" width="22" height="22"><path strokeLinecap="round" strokeLinejoin="round" d="M12 9v3.75m9-.75a9 9 0 1 1-18 0 9 9 0 0 1 18 0Zm-9 3.75h.008v.008H12v-.008Z" /></svg>
                  需要注意
                </h3>
                <ul>
                  {['需要网络连接使用云服务', '初期可能有学习适应期', '复杂项目仍需人工审核', '部分高级功能需要付费', '对硬件配置有一定要求'].map((t) => (
                    <li key={t}>
                      <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" strokeWidth={2} stroke="currentColor"><path strokeLinecap="round" strokeLinejoin="round" d="M12 9v3.75m9-.75a9 9 0 1 1-18 0 9 9 0 0 1 18 0Zm-9 3.75h.008v.008H12v-.008Z" /></svg>
                      {t}
                    </li>
                  ))}
                </ul>
              </div>
            </div>
          </div>
        </section>

        {/* CTA */}
        <section className="lp-cta-section">
          <div className="lp-container">
            <h2>立即开启AI编程新时代</h2>
            <p>通过专属邀请链接，享受额外优惠和特权</p>
            <a href={TRAE_URL} target="_blank" rel="noopener" className="lp-final-cta">
              点击这里立即体验 Trae.ai
              <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" strokeWidth={2} stroke="currentColor" width="20" height="20"><path strokeLinecap="round" strokeLinejoin="round" d="M13.5 4.5 21 12m0 0-7.5 7.5M21 12H3" /></svg>
            </a>
            <p className="lp-cta-note">邀请链接：{TRAE_URL}</p>
            <p className="lp-cta-free">
              <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" strokeWidth={2} stroke="currentColor" width="16" height="16"><path strokeLinecap="round" strokeLinejoin="round" d="M12 18v-5.25m0 0a6.01 6.01 0 0 0 1.5-.189m-1.5.189a6.01 6.01 0 0 1-1.5-.189m3.75 7.478a12.06 12.06 0 0 1-4.5 0m3.75 2.383a14.406 14.406 0 0 1-3 0M14.25 18v-.192c0-.983.658-1.823 1.508-2.316a7.5 7.5 0 1 0-7.517 0c.85.493 1.509 1.333 1.509 2.316V18" /></svg>
              此链接注册免费使用
            </p>
          </div>
        </section>

        {/* Footer */}
        <footer className="lp-footer">
          <div className="lp-container">
            <p>&copy; 2024 ndtool.cn | AI工具 + 简历平台</p>
            <p style={{ marginTop: 8 }}>
              <Link to="/login" style={{ color: '#38BDF8' }}>AI 简历</Link>
              {' | '}
              <a href="/resources/">资源激活工具站</a>
              <a href="/blog/ai-resume-guide.html">AI简历生成指南</a>
              <a href="/blog/fresh-graduate-resume.html">应届生简历怎么写</a>
            </p>
            <p className="lp-footer-disclaimer">此网站用于个人学习交流使用，如有侵权请联系 641600780@qq.com 删除</p>
          </div>
        </footer>
      </div>
    </>
  );
}
