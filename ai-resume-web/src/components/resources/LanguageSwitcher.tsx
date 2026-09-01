import { useTranslation } from 'react-i18next';

export function LanguageSwitcher() {
  const { i18n, t } = useTranslation();
  const targetLang = i18n.language === 'zh' ? 'en' : 'zh';

  return (
    <button
      onClick={() => i18n.changeLanguage(targetLang)}
      className="px-3 py-1 text-xs border border-[#1E3A5C] rounded text-[#8FA8C0] hover:text-[#EAF4FA] hover:border-[#4FD8EB] transition-colors"
      aria-label={t('nav.language')}
    >
      {t('nav.language')}
    </button>
  );
}
