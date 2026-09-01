import { Link, useLocation } from 'react-router-dom';
import { useTranslation } from 'react-i18next';
import { LanguageSwitcher } from './LanguageSwitcher';

const RESOURCE_NAV = [
  { path: '/resources', labelKey: 'resources.title', isExact: true },
  { path: '/resources/toolbox', labelKey: 'resources.toolbox.title', isExact: false },
  { path: '/resources/list', labelKey: 'resources.list.title', isExact: false },
  { path: '/resources/feedback', labelKey: 'resources.feedback.title', isExact: false },
  { path: '/resources/status', labelKey: 'resources.status.title', isExact: false },
  { path: '/resources/security', labelKey: 'resources.security.title', isExact: false },
];

export default function ResourceLayout({ children }: { children: React.ReactNode }) {
  const { t } = useTranslation();
  const location = useLocation();

  return (
    <div className="min-h-screen pt-20">
      {/* Sub-navigation */}
      <div className="border-b border-[#1E3A5C] bg-[#081426]/80 backdrop-blur-md sticky top-16 z-30">
        <div className="max-w-6xl mx-auto px-4 flex items-center justify-between h-12">
          <nav className="flex gap-1 overflow-x-auto no-scrollbar">
            {RESOURCE_NAV.map((item) => {
              const isActive = item.isExact
                ? location.pathname === item.path
                : location.pathname.startsWith(item.path) && item.path !== '/resources';
              return (
                <Link
                  key={item.path}
                  to={item.path}
                  className={`px-3 py-1.5 text-sm whitespace-nowrap transition-colors ${
                    isActive
                      ? 'text-[#4FD8EB] border-b-2 border-[#4FD8EB]'
                      : 'text-[#8FA8C0] hover:text-[#EAF4FA]'
                  }`}
                >
                  {t(item.labelKey)}
                </Link>
              );
            })}
          </nav>
          <LanguageSwitcher />
        </div>
      </div>

      {/* Content */}
      <main className="max-w-6xl mx-auto px-4 py-8">
        {children}
      </main>
    </div>
  );
}
