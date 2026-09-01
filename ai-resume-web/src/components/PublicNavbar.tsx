import { useState, useEffect, useRef } from 'react';
import { Link, useLocation } from 'react-router-dom';
import { useTranslation } from 'react-i18next';
import { gsap, ScrollTrigger, useGSAP, MOTION_OK } from '../animation/motion';

const NAV_ITEMS = [
  { path: '/', labelKey: 'nav.home' },
  { path: '/os', labelKey: 'nav.os' },
  { path: '/career', labelKey: 'nav.career' },
  { path: '/resources', labelKey: 'nav.resources' },
  { path: '/trae', labelKey: 'nav.trae' },
  { path: '/harmony-harness/', labelKey: 'nav.harmony', external: true },
  { path: '/about', labelKey: 'nav.about' },
] as const;
/* 帮助/条款/隐私已收纳至"关于"页的支持与法律区块 */

export default function PublicNavbar() {
  const [scrolled, setScrolled] = useState(false);
  const [menuOpen, setMenuOpen] = useState(false);
  const location = useLocation();
  const { t, i18n } = useTranslation();
  const navRef = useRef<HTMLElement>(null);
  const menuRef = useRef<HTMLDivElement>(null);

  /* 入场 + 下滚让路、上滚召回(移动端菜单展开时不隐藏) */
  useGSAP(
    () => {
      const nav = navRef.current;
      if (!nav) return;

      const mm = gsap.matchMedia();
      mm.add(
        { ok: MOTION_OK, desktop: '(min-width: 769px)' },
        (ctx) => {
          const { ok, desktop } = ctx.conditions as { ok: boolean; desktop: boolean };
          if (!ok) return;

          gsap.from(nav, { yPercent: -120, duration: 0.8, ease: 'ink' });

          if (!desktop) return;
          const show = (direction: number) => {
            gsap.to(nav, { yPercent: direction < 0 ? 0 : -120, duration: 0.45, ease: 'silk', overwrite: 'auto' });
          };
          ScrollTrigger.create({
            start: 'top -80',
            end: 'max',
            onUpdate: (self) => show(self.direction),
          });
        }
      );
      return () => mm.revert();
    },
    { scope: navRef }
  );

  /* 移动菜单:链接鱼贯而入 */
  useGSAP(
    () => {
      const menu = menuRef.current;
      if (!menu || !menuOpen) return;

      const mm = gsap.matchMedia();
      mm.add(MOTION_OK, () => {
        gsap.fromTo(
          menu.children,
          { x: -18, autoAlpha: 0 },
          { x: 0, autoAlpha: 1, duration: 0.4, stagger: 0.05, ease: 'ink', delay: 0.05 }
        );
      });
      return () => mm.revert();
    },
    { scope: menuRef, dependencies: [menuOpen], revertOnUpdate: true }
  );

  useEffect(() => {
    const onScroll = () => setScrolled(window.scrollY > 40);
    window.addEventListener('scroll', onScroll, { passive: true });
    return () => window.removeEventListener('scroll', onScroll);
  }, []);

  useEffect(() => {
    setMenuOpen(false);
  }, [location.pathname]);

  return (
    <>
      <nav className={`pub-nav${scrolled ? ' scrolled' : ''}`} ref={navRef}>
        <div className="pub-nav-inner">
          <Link to="/" className="pub-nav-logo">
            <span className="pub-nav-logo-icon">N</span>
            ndtool
          </Link>

          <div className="pub-nav-links">
            {NAV_ITEMS.map((item) =>
              'external' in item && item.external ? (
                <a key={item.path} href={item.path} className="pub-nav-link">
                  {t(item.labelKey)}
                </a>
              ) : (
                <Link
                  key={item.path}
                  to={item.path}
                  className={`pub-nav-link${location.pathname === item.path ? ' active' : ''}`}
                >
                  {t(item.labelKey)}
                </Link>
              ),
            )}
            <button
              onClick={() => i18n.changeLanguage(i18n.language === 'zh' ? 'en' : 'zh')}
              className="pub-nav-link pub-nav-lang"
              aria-label="Switch language"
            >
              {t('nav.language')}
            </button>
          </div>

          <div className="pub-nav-actions">
            <Link to="/login" className="pub-nav-login">{t('nav.login')}</Link>
            <Link to="/register" className="pub-nav-cta">{t('nav.register')}</Link>
          </div>

          <button
            className={`pub-hamburger${menuOpen ? ' open' : ''}`}
            onClick={() => setMenuOpen(!menuOpen)}
            aria-label="菜单"
            aria-expanded={menuOpen}
          >
            <span /><span /><span />
          </button>
        </div>
      </nav>

      <div className={`pub-mobile-menu${menuOpen ? ' open' : ''}`} ref={menuRef}>
        {NAV_ITEMS.map((item) =>
          'external' in item && item.external ? (
            <a
              key={item.path}
              href={item.path}
              className="pub-nav-link"
              onClick={() => setMenuOpen(false)}
            >
              {t(item.labelKey)}
            </a>
          ) : (
            <Link
              key={item.path}
              to={item.path}
              className={`pub-nav-link${location.pathname === item.path ? ' active' : ''}`}
              onClick={() => setMenuOpen(false)}
            >
              {t(item.labelKey)}
            </Link>
          ),
        )}
        <button
          onClick={() => { i18n.changeLanguage(i18n.language === 'zh' ? 'en' : 'zh'); setMenuOpen(false); }}
          className="pub-nav-link"
        >
          {t('nav.language')}
        </button>
        <Link to="/login" className="pub-nav-link" onClick={() => setMenuOpen(false)}>{t('nav.login')}</Link>
        <Link to="/register" className="pub-nav-cta" onClick={() => setMenuOpen(false)}>{t('nav.register')}</Link>
      </div>
    </>
  );
}
