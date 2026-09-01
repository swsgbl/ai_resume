import { useState } from 'react';
import { Link } from 'react-router-dom';
import { useTranslation } from 'react-i18next';
import PublicLayout from '../../components/PublicLayout';
import ResourceLayout from '../../components/resources/ResourceLayout';

const CATEGORIES = [
  {
    key: 'common',
    items: [
      { path: '/resources/toolbox', icon: 'wrench', labelKey: 'resources.toolbox.title', descKey: 'resources.categories.common' },
      { path: '/resources/security', icon: 'shield', labelKey: 'resources.security.title', descKey: 'resources.security.detection.title' },
    ],
  },
  {
    key: 'popular',
    items: [
      { path: '/resources/list', icon: 'folder', labelKey: 'resources.list.title', descKey: 'resources.list.system.title' },
      { path: '/resources/toolbox', icon: 'box', labelKey: 'resources.toolbox.software.title', descKey: 'resources.toolbox.software.title' },
    ],
  },
] as const;

const ICONS: Record<string, JSX.Element> = {
  wrench: <svg className="w-6 h-6" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={1.5}><path strokeLinecap="round" strokeLinejoin="round" d="M11.42 15.17 17.25 21A2.652 2.652 0 0 0 21 17.25l-5.877-5.877M11.42 15.17l2.496-2.497a2.143 2.143 0 0 0-3.03-3.03l-2.497 2.496m0 0L3 7.5m5.389 4.59L7.5 3m4.59 5.389L21 16.5" /></svg>,
  shield: <svg className="w-6 h-6" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={1.5}><path strokeLinecap="round" strokeLinejoin="round" d="M9 12.75 11.25 15 15 9.75m-3-7.036A11.959 11.959 0 0 1 3.598 6 11.99 11.99 0 0 0 3 9.749c0 5.592 3.824 10.29 9 11.623 5.176-1.332 9-6.03 9-11.622 0-1.31-.21-2.571-.598-3.751h-.152c-3.196 0-6.1-1.248-8.25-3.285Z" /></svg>,
  folder: <svg className="w-6 h-6" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={1.5}><path strokeLinecap="round" strokeLinejoin="round" d="M2.25 12.75V12A2.25 2.25 0 0 1 4.5 9.75h15A2.25 2.25 0 0 1 21.75 12v.75m-8.69-6.44-2.12-2.12a1.5 1.5 0 0 0-1.061-.44H4.5A2.25 2.25 0 0 0 2.25 6v12a2.25 2.25 0 0 0 2.25 2.25h15A2.25 2.25 0 0 0 21.75 18V9a2.25 2.25 0 0 0-2.25-2.25h-5.379a1.5 1.5 0 0 1-1.06-.44Z" /></svg>,
  box: <svg className="w-6 h-6" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={1.5}><path strokeLinecap="round" strokeLinejoin="round" d="m20.25 7.5-.625 10.632a2.25 2.25 0 0 1-2.247 2.118H6.622a2.25 2.25 0 0 1-2.247-2.118L3.75 7.5M10 11.25h4M3.375 7.5h17.25c.621 0 1.125-.504 1.125-1.125v-1.5c0-.621-.504-1.125-1.125-1.125H3.375c-.621 0-1.125.504-1.125 1.125v1.5c0 .621.504 1.125 1.125 1.125Z" /></svg>,
};

export default function ResourcesMainPage() {
  const { t } = useTranslation();
  const [search, setSearch] = useState('');

  return (
    <PublicLayout>
      <ResourceLayout>
        {/* Header */}
        <div className="mb-10">
          <h1 className="text-3xl font-bold text-[#EAF4FA] mb-2">{t('resources.title')}</h1>
          <p className="text-[#8FA8C0]">{t('resources.subtitle')}</p>
        </div>

        {/* Search */}
        <div className="mb-8">
          <div className="flex gap-3">
            <input
              type="text"
              value={search}
              onChange={(e) => setSearch(e.target.value)}
              placeholder={t('resources.search.placeholder')}
              className="flex-1 bg-[#0B1E3A] border border-[#1E3A5C] rounded px-4 py-2.5 text-sm text-[#EAF4FA] placeholder-[#5A7490] focus:outline-none focus:border-[#4FD8EB] transition-colors"
            />
            <button className="px-5 py-2.5 bg-[#4FD8EB] text-[#081426] text-sm font-medium rounded hover:bg-[#2FA8D8] transition-colors">
              {t('resources.search.button')}
            </button>
          </div>
        </div>

        {/* Categories */}
        {CATEGORIES.map((cat) => (
          <section key={cat.key} className="mb-10">
            <h2 className="text-lg font-semibold text-[#EAF4FA] mb-4 pb-2 border-b border-[#1E3A5C]">
              {t(`resources.categories.${cat.key}.title`)}
            </h2>
            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              {cat.items.map((item) => (
                <Link
                  key={item.path + item.labelKey}
                  to={item.path}
                  className="group flex items-start gap-4 p-5 bg-[#0B1E3A] border border-[#1E3A5C] rounded hover:border-[#4FD8EB] transition-all"
                >
                  <div className="text-[#4FD8EB] mt-0.5">{ICONS[item.icon]}</div>
                  <div>
                    <h3 className="text-[#EAF4FA] font-medium group-hover:text-[#4FD8EB] transition-colors">
                      {t(item.labelKey)}
                    </h3>
                    <p className="text-sm text-[#8FA8C0] mt-1">{t(item.descKey)}</p>
                  </div>
                </Link>
              ))}
            </div>
          </section>
        ))}
      </ResourceLayout>
    </PublicLayout>
  );
}
