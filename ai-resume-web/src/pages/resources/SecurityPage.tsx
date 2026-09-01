import { useTranslation } from 'react-i18next';
import PublicLayout from '../../components/PublicLayout';
import ResourceLayout from '../../components/resources/ResourceLayout';

export default function SecurityPage() {
  const { t } = useTranslation();

  const sections = [
    { key: 'detection', icon: 'shield-check' },
    { key: 'instructions', icon: 'book' },
    { key: 'disclaimer', icon: 'info' },
  ] as const;

  const ICONS: Record<string, JSX.Element> = {
    'shield-check': <svg className="w-6 h-6" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={1.5}><path strokeLinecap="round" strokeLinejoin="round" d="M9 12.75 11.25 15 15 9.75M21 12c0 1.268-.63 2.39-1.593 3.068a3.745 3.745 0 0 1-1.043 3.296 3.745 3.745 0 0 1-3.296 1.043A3.745 3.745 0 0 1 12 21c-1.268 0-2.39-.63-3.068-1.593a3.746 3.746 0 0 1-3.296-1.043 3.745 3.745 0 0 1-1.043-3.296A3.745 3.745 0 0 1 3 12c0-1.268.63-2.39 1.593-3.068a3.745 3.745 0 0 1 1.043-3.296 3.746 3.746 0 0 1 3.296-1.043A3.746 3.746 0 0 1 12 3c1.268 0 2.39.63 3.068 1.593a3.746 3.746 0 0 1 3.296 1.043 3.746 3.746 0 0 1 1.043 3.296A3.745 3.745 0 0 1 21 12Z" /></svg>,
    'book': <svg className="w-6 h-6" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={1.5}><path strokeLinecap="round" strokeLinejoin="round" d="M12 6.042A8.967 8.967 0 0 0 6 3.75c-1.052 0-2.062.18-3 .512v14.25A8.987 8.987 0 0 1 6 18c2.305 0 4.408.867 6 2.292m0-14.25a8.966 8.966 0 0 1 6-2.292c1.052 0 2.062.18 3 .512v14.25A8.987 8.987 0 0 0 18 18a8.967 8.967 0 0 0-6 2.292m0-14.25v14.25" /></svg>,
    'info': <svg className="w-6 h-6" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={1.5}><path strokeLinecap="round" strokeLinejoin="round" d="m11.25 11.25.041-.02a.75.75 0 0 1 1.063.852l-.708 2.836a.75.75 0 0 0 1.063.853l.041-.021M21 12a9 9 0 1 1-18 0 9 9 0 0 1 18 0Zm-9-3.75h.008v.008H12V8.25Z" /></svg>,
  };

  return (
    <PublicLayout>
      <ResourceLayout>
        <h1 className="text-3xl font-bold text-[#EAF4FA] mb-8">{t('resources.security.title')}</h1>

        <div className="space-y-6">
          {sections.map((section) => (
            <div key={section.key} className="p-6 bg-[#0B1E3A] border border-[#1E3A5C] rounded">
              <div className="flex items-start gap-4">
                <div className="text-[#4FD8EB] flex-shrink-0 mt-0.5">
                  {ICONS[section.icon]}
                </div>
                <div>
                  <h2 className="text-lg font-semibold text-[#EAF4FA] mb-2">
                    {t(`resources.security.${section.key}.title`)}
                  </h2>
                  <p className="text-[#8FA8C0] text-sm leading-relaxed">
                    {t(`resources.security.${section.key}.desc`)}
                  </p>
                </div>
              </div>
            </div>
          ))}
        </div>
      </ResourceLayout>
    </PublicLayout>
  );
}
