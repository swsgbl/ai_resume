import { useTranslation } from 'react-i18next';
import PublicLayout from '../../components/PublicLayout';
import ResourceLayout from '../../components/resources/ResourceLayout';

const RESOURCE_SECTIONS = [
  {
    key: 'system',
    icon: <svg className="w-8 h-8" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={1.5}><path strokeLinecap="round" strokeLinejoin="round" d="M9 17.25v1.007a3 3 0 0 1-.879 2.122L7.5 21h9l-.621-.621A3 3 0 0 1 15 18.257V17.25m6-12V15a2.25 2.25 0 0 1-2.25 2.25H5.25A2.25 2.25 0 0 1 3 15V5.25m18 0A2.25 2.25 0 0 0 18.75 3H5.25A2.25 2.25 0 0 0 3 5.25m18 0V12a2.25 2.25 0 0 1-2.25 2.25H5.25A2.25 2.25 0 0 1 3 12V5.25" /></svg>,
    items: ['iso', 'drivers', 'patches'],
  },
  {
    key: 'dev',
    icon: <svg className="w-8 h-8" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={1.5}><path strokeLinecap="round" strokeLinejoin="round" d="M17.25 6.75 22.5 12l-5.25 5.25m-10.5 0L1.5 12l5.25-5.25m7.5-3-4.5 16.5" /></svg>,
    items: ['sdk', 'api', 'examples'],
  },
  {
    key: 'security',
    icon: <svg className="w-8 h-8" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={1.5}><path strokeLinecap="round" strokeLinejoin="round" d="M9 12.75 11.25 15 15 9.75m-3-7.036A11.959 11.959 0 0 1 3.598 6 11.99 11.99 0 0 0 3 9.749c0 5.592 3.824 10.29 9 11.623 5.176-1.332 9-6.03 9-11.622 0-1.31-.21-2.571-.598-3.751h-.152c-3.196 0-6.1-1.248-8.25-3.285Z" /></svg>,
    items: ['patches', 'guides', 'vulndb'],
  },
] as const;

export default function ResourcesListPage() {
  const { t } = useTranslation();

  return (
    <PublicLayout>
      <ResourceLayout>
        <h1 className="text-3xl font-bold text-[#EAF4FA] mb-8">{t('resources.list.title')}</h1>

        <div className="space-y-10">
          {RESOURCE_SECTIONS.map((section) => (
            <section key={section.key}>
              <div className="flex items-center gap-3 mb-4 pb-2 border-b border-[#1E3A5C]">
                <div className="text-[#4FD8EB]">{section.icon}</div>
                <h2 className="text-lg font-semibold text-[#EAF4FA]">
                  {t(`resources.list.${section.key}.title`)}
                </h2>
              </div>
              <div className="grid grid-cols-1 sm:grid-cols-3 gap-3">
                {section.items.map((item) => (
                  <div
                    key={item}
                    className="p-4 bg-[#0B1E3A] border border-[#1E3A5C] rounded hover:border-[#4FD8EB] transition-all cursor-default"
                  >
                    <h3 className="text-[#EAF4FA] text-sm font-medium">
                      {t(`resources.list.${section.key}.${item}`)}
                    </h3>
                  </div>
                ))}
              </div>
            </section>
          ))}
        </div>
      </ResourceLayout>
    </PublicLayout>
  );
}
