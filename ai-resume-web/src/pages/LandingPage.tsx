import { useRef } from 'react';
import { Link } from 'react-router-dom';
import { SEO } from '../components/SEO';
import PublicNavbar from '../components/PublicNavbar';
import HeroSection from '../components/landing/HeroSection';
import StatsSection from '../components/landing/StatsSection';
import FeaturesSection from '../components/landing/FeaturesSection';
import HowItWorksSection from '../components/landing/HowItWorksSection';
import TestimonialsSection from '../components/landing/TestimonialsSection';
import PricingSection from '../components/landing/PricingSection';
import DownloadSection from '../components/landing/DownloadSection';
import FAQSection from '../components/landing/FAQSection';
import Footer from '../components/landing/Footer';
import { gsap, useGSAP, MOTION_OK } from '../animation/motion';
import './LandingPage.css';

function CTASection() {
  const ref = useRef<HTMLElement>(null);

  /* 终章:内盒落定,光晕随滚动缓移 */
  useGSAP(
    () => {
      const mm = gsap.matchMedia();
      mm.add(MOTION_OK, () => {
        gsap.from('.lp-cta-box', {
          y: 64,
          autoAlpha: 0,
          scale: 0.97,
          duration: 0.9,
          ease: 'ink',
          scrollTrigger: { trigger: '.lp-cta', start: 'top 78%', once: true },
        });
        gsap.from('.lp-cta-box > *:not(.lp-cta-glow)', {
          y: 26,
          autoAlpha: 0,
          duration: 0.7,
          stagger: 0.1,
          ease: 'ink',
          scrollTrigger: { trigger: '.lp-cta', start: 'top 70%', once: true },
        });
        gsap.fromTo(
          '.lp-cta-glow',
          { xPercent: -30 },
          {
            xPercent: 30,
            ease: 'none',
            scrollTrigger: { trigger: '.lp-cta', start: 'top bottom', end: 'bottom top', scrub: 1 },
          }
        );
      });
      return () => mm.revert();
    },
    { scope: ref }
  );

  return (
    <section className="lp-cta" ref={ref}>
      <div className="lp-container">
        <div className="lp-cta-box">
          <div className="lp-cta-glow" aria-hidden="true" />
          <h2 className="lp-cta-title">
            30秒生成你的<span style={{ color: 'var(--lp-accent)' }}>专业简历</span>
          </h2>
          <p className="lp-cta-desc">
            支持 DeepSeek / OpenAI / 小米 MiMo 多模型 · 完全免费 · 数据本地存储
          </p>
          <div style={{ position: 'relative', display: 'flex', gap: 16, justifyContent: 'center', flexWrap: 'wrap' }}>
            <Link to="/register" className="lp-btn-primary lp-btn-shine">
              免费开始制作
              <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" strokeWidth={2} stroke="currentColor" width="18" height="18"><path strokeLinecap="round" strokeLinejoin="round" d="M13.5 4.5 21 12m0 0-7.5 7.5M21 12H3" /></svg>
            </Link>
            <Link to="/login" className="lp-btn-secondary">已有账号，登录</Link>
          </div>
        </div>
      </div>
    </section>
  );
}

export default function LandingPage() {
  return (
    <>
      <SEO
        title="免费AI简历生成器 - 30秒生成专业简历 | ndtool"
        description="免费AI简历生成器，支持DeepSeek/OpenAI多模型。30秒智能生成专业简历，200+模板，AI优化+JD匹配，PDF/Word一键导出。应届生、跳槽者都在用的免费简历制作工具。"
      />
      {/* 全站统一 hm 导航,与 /career 等公开页同源同风格 */}
      <div className="landing-page" data-motion-ignore>
        <PublicNavbar />
        <HeroSection />
        <StatsSection />
        <FeaturesSection />
        <HowItWorksSection />
        <TestimonialsSection />
        <PricingSection />
        <DownloadSection />
        <FAQSection />
        <CTASection />
        <Footer />
      </div>
    </>
  );
}
