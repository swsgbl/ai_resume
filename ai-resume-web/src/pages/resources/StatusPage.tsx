import { useTranslation } from 'react-i18next';
import PublicLayout from '../../components/PublicLayout';
import ResourceLayout from '../../components/resources/ResourceLayout';

export default function StatusPage() {
  const { t } = useTranslation();

  const services = [
    { name: t('resources.status.api'), status: 'online' },
    { name: t('resources.status.database'), status: 'online' },
  ];

  return (
    <PublicLayout>
      <ResourceLayout>
        <h1 className="text-3xl font-bold text-[#EAF4FA] mb-8">{t('resources.status.title')}</h1>

        {/* Server Status */}
        <section className="mb-10">
          <h2 className="text-lg font-semibold text-[#EAF4FA] mb-4 pb-2 border-b border-[#1E3A5C]">
            {t('resources.status.server')}
          </h2>
          <div className="flex items-center gap-3 p-4 bg-[#0B1E3A] border border-[#1E3A5C] rounded">
            <span className="w-2.5 h-2.5 rounded-full bg-[#8FAE8B] animate-pulse" />
            <span className="text-[#8FAE8B] font-medium">{t('resources.status.online')}</span>
          </div>
        </section>

        {/* Services */}
        <section className="mb-10">
          <h2 className="text-lg font-semibold text-[#EAF4FA] mb-4 pb-2 border-b border-[#1E3A5C]">
            {t('resources.status.services')}
          </h2>
          <div className="space-y-2">
            {services.map((svc) => (
              <div key={svc.name} className="flex items-center justify-between p-3 bg-[#0B1E3A] border border-[#1E3A5C] rounded">
                <span className="text-sm text-[#EAF4FA]">{svc.name}</span>
                <div className="flex items-center gap-2">
                  <span className="w-2 h-2 rounded-full bg-[#8FAE8B]" />
                  <span className="text-xs text-[#8FAE8B]">{t('resources.status.online')}</span>
                </div>
              </div>
            ))}
          </div>
        </section>

        {/* System Info */}
        <section>
          <h2 className="text-lg font-semibold text-[#EAF4FA] mb-4 pb-2 border-b border-[#1E3A5C]">
            {t('resources.status.systemInfo')}
          </h2>
          <div className="p-4 bg-[#0B1E3A] border border-[#1E3A5C] rounded space-y-2 text-sm">
            <div className="flex justify-between">
              <span className="text-[#8FA8C0]">{t('resources.status.version')}</span>
              <span className="text-[#EAF4FA] font-mono">2.0.0</span>
            </div>
            <div className="flex justify-between">
              <span className="text-[#8FA8C0]">{t('resources.status.lastUpdate')}</span>
              <span className="text-[#EAF4FA]">2026-04-12</span>
            </div>
          </div>
        </section>
      </ResourceLayout>
    </PublicLayout>
  );
}
