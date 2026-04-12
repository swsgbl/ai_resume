import { useState, useEffect } from 'react';
import { Link, useLocation } from 'react-router-dom';
import { useTranslation } from 'react-i18next';

const NAV_ITEMS = [
  { path: '/', labelKey: 'nav.home' },
  { path: '/career', labelKey: 'nav.career' },
  { path: '/resources', labelKey: 'nav.resources' },
  { path: '/trae', labelKey: 'nav.trae' },
  { path: '/about', labelKey: 'nav.about' },
  { path: '/help', labelKey: 'nav.help' },
  { path: '/terms', labelKey: 'nav.terms' },
  { path: '/privacy', labelKey: 'nav.privacy' },
] as const;

export default function PublicNavbar() {
  const [scrolled, setScrolled] = useState(false);
  const [menuOpen, setMenuOpen] = useState(false);
  const location = useLocation();
  const { t, i18n } = useTranslation();

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
      <nav className={`pub-nav${scrolled ? ' scrolled' : ''}`}>
        <div className="pub-nav-inner">
          <Link to="/" className="pub-nav-logo">
            <span className="pub-nav-logo-icon">N</span>
            ndtool
          </Link>

          <div className="pub-nav-links">
            {NAV_ITEMS.map((item) => (
              <Link
                key={item.path}
                to={item.path}
                className={`pub-nav-link${location.pathname === item.path ? ' active' : ''}`}
              >
                {t(item.labelKey)}
              </Link>
            ))}
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
          >
            <span /><span /><span />
          </button>
        </div>
      </nav>

      <div className={`pub-mobile-menu${menuOpen ? ' open' : ''}`}>
        {NAV_ITEMS.map((item) => (
          <Link
            key={item.path}
            to={item.path}
            className={`pub-nav-link${location.pathname === item.path ? ' active' : ''}`}
            onClick={() => setMenuOpen(false)}
          >
            {t(item.labelKey)}
          </Link>
        ))}
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
