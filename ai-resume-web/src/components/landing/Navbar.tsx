import { useState, useEffect } from 'react';
import { Link } from 'react-router-dom';
import { useTranslation } from 'react-i18next';

export default function Navbar() {
  const [scrolled, setScrolled] = useState(false);
  const [menuOpen, setMenuOpen] = useState(false);
  const { t, i18n } = useTranslation();

  useEffect(() => {
    const onScroll = () => setScrolled(window.scrollY > 40);
    window.addEventListener('scroll', onScroll, { passive: true });
    return () => window.removeEventListener('scroll', onScroll);
  }, []);

  return (
    <>
      <nav className={`lp-navbar${scrolled ? ' scrolled' : ''}`}>
        <div className="lp-navbar-inner">
          <Link to="/" className="lp-logo">
            <span className="lp-logo-icon">N</span>
            ndtool
          </Link>

          <div className="lp-nav-menu">
            <Link to="/career" className="lp-nav-link">{t('nav.career')}</Link>
            <Link to="/resources" className="lp-nav-link">{t('nav.resources')}</Link>
            <Link to="/trae" className="lp-nav-link">{t('nav.trae')}</Link>
            <Link to="/about" className="lp-nav-link">{t('nav.about')}</Link>
            <Link to="/help" className="lp-nav-link">{t('nav.help')}</Link>
            <button
              onClick={() => i18n.changeLanguage(i18n.language === 'zh' ? 'en' : 'zh')}
              className="lp-nav-link"
            >
              {t('nav.language')}
            </button>
            <Link to="/login" className="lp-nav-link lp-nav-login">{t('nav.login')}</Link>
            <Link to="/register" className="lp-nav-cta">{t('nav.register')}</Link>
          </div>

          <button
            className={`lp-hamburger${menuOpen ? ' open' : ''}`}
            onClick={() => setMenuOpen(!menuOpen)}
            aria-label="菜单"
          >
            <span /><span /><span />
          </button>
        </div>
      </nav>

      <div className={`lp-mobile-menu${menuOpen ? ' open' : ''}`}>
        <Link to="/career" className="lp-nav-link" onClick={() => setMenuOpen(false)}>{t('nav.career')}</Link>
        <Link to="/resources" className="lp-nav-link" onClick={() => setMenuOpen(false)}>{t('nav.resources')}</Link>
        <Link to="/trae" className="lp-nav-link" onClick={() => setMenuOpen(false)}>{t('nav.trae')}</Link>
        <Link to="/about" className="lp-nav-link" onClick={() => setMenuOpen(false)}>{t('nav.about')}</Link>
        <Link to="/help" className="lp-nav-link" onClick={() => setMenuOpen(false)}>{t('nav.help')}</Link>
        <button onClick={() => { i18n.changeLanguage(i18n.language === 'zh' ? 'en' : 'zh'); setMenuOpen(false); }} className="lp-nav-link">
          {t('nav.language')}
        </button>
        <Link to="/login" className="lp-nav-link" onClick={() => setMenuOpen(false)}>{t('nav.login')}</Link>
        <Link to="/register" className="lp-nav-cta" onClick={() => setMenuOpen(false)}>{t('nav.register')}</Link>
      </div>
    </>
  );
}
