import { useTranslation } from 'react-i18next';
import PublicLayout from '../../components/PublicLayout';
import ResourceLayout from '../../components/resources/ResourceLayout';
import { systemTools, softwareTools, type Tool } from '../../data/resources';

function ToolCard({ tool }: { tool: Tool }) {
  const { t, i18n } = useTranslation();
  const isEn = i18n.language === 'en';

  return (
    <div className="p-4 bg-[#161616] border border-[#252525] rounded hover:border-[#5A5652] transition-all">
      <div className="flex items-start justify-between gap-3">
        <div className="flex-1 min-w-0">
          <h3 className="text-[#E8E4DE] font-medium truncate">
            {isEn ? tool.nameEn : tool.name}
          </h3>
          <p className="text-sm text-[#8A8580] mt-1">
            {isEn ? tool.descriptionEn : tool.description}
          </p>
          <div className="flex gap-3 mt-2 text-xs text-[#5A5652]">
            <span>v{tool.version}</span>
            <span>{tool.size}</span>
          </div>
        </div>
        <div className="flex-shrink-0">
          {tool.cloudStorage ? (
            <a
              href={tool.cloudStorage.url}
              target="_blank"
              rel="noopener noreferrer"
              className="px-3 py-1.5 bg-[#C84B31] text-white text-sm rounded hover:bg-[#A63D28] transition-colors"
            >
              {t('resources.download')}
            </a>
          ) : (
            <span className="px-3 py-1.5 text-sm text-[#5A5652] border border-[#252525] rounded">
              {t('resources.useNow')}
            </span>
          )}
        </div>
      </div>
      {tool.cloudStorage?.extractCode && (
        <p className="mt-2 text-xs text-[#8A8580]">
          {t('resources.extractCode')}: <span className="text-[#C84B31] font-mono">{tool.cloudStorage.extractCode}</span>
        </p>
      )}
    </div>
  );
}

export default function ToolboxPage() {
  const { t } = useTranslation();

  return (
    <PublicLayout>
      <ResourceLayout>
        <h1 className="text-3xl font-bold text-[#E8E4DE] mb-8">{t('resources.toolbox.title')}</h1>

        {/* System Tools */}
        {systemTools.length > 0 && (
          <section className="mb-10">
            <h2 className="text-lg font-semibold text-[#E8E4DE] mb-4 pb-2 border-b border-[#252525]">
              {t('resources.toolbox.system.title')}
            </h2>
            <div className="space-y-3">
              {systemTools.map((tool) => (
                <ToolCard key={tool.id} tool={tool} />
              ))}
            </div>
          </section>
        )}

        {/* Software Tools */}
        {softwareTools.length > 0 && (
          <section className="mb-10">
            <h2 className="text-lg font-semibold text-[#E8E4DE] mb-4 pb-2 border-b border-[#252525]">
              {t('resources.toolbox.software.title')}
            </h2>
            <div className="space-y-3">
              {softwareTools.map((tool) => (
                <ToolCard key={tool.id} tool={tool} />
              ))}
            </div>
          </section>
        )}
      </ResourceLayout>
    </PublicLayout>
  );
}
