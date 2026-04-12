import { useTranslation } from 'react-i18next';

export function LanguageSwitcher() {
  const { i18n, t } = useTranslation();
  const targetLang = i18n.language === 'zh' ? 'en' : 'zh';

  return (
    <button
      onClick={() => i18n.changeLanguage(targetLang)}
      className="px-3 py-1 text-xs border border-[#252525] rounded text-[#8A8580] hover:text-[#E8E4DE] hover:border-[#5A5652] transition-colors"
      aria-label={t('nav.language')}
    >
      {t('nav.language')}
    </button>
  );
}
