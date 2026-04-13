import { useScrollAnimation } from '../../hooks/useScrollAnimation';

interface Platform {
  name: string;
  ver: string;
  available: boolean;
  icon: React.ReactNode;
  url?: string;
}

const platforms: Platform[] = [
  {
    name: 'Windows',
    ver: 'Windows 10+',
    available: false,
    icon: <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="currentColor" width="28" height="28"><path d="M0 3.449L9.75 2.1v9.451H0m10.949-9.602L24 0v11.4H10.949M0 12.6h9.75v9.451L0 20.699M10.949 12.6H24V24l-12.9-1.801" /></svg>,
  },
  {
    name: 'macOS',
    ver: 'macOS 12+',
    available: false,
    icon: <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="currentColor" width="28" height="28"><path d="M18.71 19.5c-.83 1.24-1.71 2.45-3.05 2.47-1.34.03-1.77-.79-3.29-.79-1.53 0-2 .77-3.27.82-1.31.05-2.3-1.32-3.14-2.53C4.25 17 2.94 12.45 4.7 9.39c.87-1.52 2.43-2.48 4.12-2.51 1.28-.02 2.5.87 3.29.87.78 0 2.26-1.07 3.8-.91.65.03 2.47.26 3.64 1.98-.09.06-2.17 1.28-2.15 3.81.03 3.02 2.65 4.03 2.68 4.04-.03.07-.42 1.44-1.38 2.83M13 3.5c.73-.83 1.94-1.46 2.94-1.5.13 1.17-.34 2.35-1.04 3.19-.69.85-1.83 1.51-2.95 1.42-.15-1.15.41-2.35 1.05-3.11z" /></svg>,
  },
  {
    name: 'Linux .deb',
    ver: 'Ubuntu/Debian · v1.0.0',
    available: true,
    url: '/downloads/ai-resume-linux-amd64.deb',
    icon: <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="currentColor" width="28" height="28"><path d="M12.504 0c-.155 0-.311.015-.466.04C7.266.456 3.39 4.082 2.645 8.738c-.69 4.318 1.544 8.237 5.18 10.114v.862c0 .468.38.848.848.848h5.393c.468 0 .848-.38.848-.848v-.862c3.636-1.877 5.87-5.796 5.18-10.114C19.348 3.682 16.192.358 12.504 0zm2.07 19.28H9.426v-1.308h5.148v1.308zM12.504 2.08c3.023.315 5.542 2.834 5.857 5.857.526 4.946-3.733 8.543-7.752 8.263-2.834-.196-5.26-2.386-5.857-5.157-.72-3.34 1.24-6.358 4.15-7.732.35-.166.73-.253 1.117-.253.16 0 .323.014.485.04z" /></svg>,
  },
  {
    name: 'Linux .rpm',
    ver: 'Fedora/CentOS · v1.0.0',
    available: true,
    url: '/downloads/ai-resume-linux-amd64.rpm',
    icon: <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="currentColor" width="28" height="28"><path d="M12.504 0c-.155 0-.311.015-.466.04C7.266.456 3.39 4.082 2.645 8.738c-.69 4.318 1.544 8.237 5.18 10.114v.862c0 .468.38.848.848.848h5.393c.468 0 .848-.38.848-.848v-.862c3.636-1.877 5.87-5.796 5.18-10.114C19.348 3.682 16.192.358 12.504 0zm2.07 19.28H9.426v-1.308h5.148v1.308zM12.504 2.08c3.023.315 5.542 2.834 5.857 5.857.526 4.946-3.733 8.543-7.752 8.263-2.834-.196-5.26-2.386-5.857-5.157-.72-3.34 1.24-6.358 4.15-7.732.35-.166.73-.253 1.117-.253.16 0 .323.014.485.04z" /></svg>,
  },
  {
    name: 'Android',
    ver: 'Android 8+ · v1.0.0',
    available: true,
    url: '/downloads/ai-resume-android.apk',
    icon: <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="currentColor" width="28" height="28"><path d="M17.523 2.237l1.59-1.59a.5.5 0 0 0-.707-.707l-1.8 1.8A8.038 8.038 0 0 0 12 .727a8.038 8.038 0 0 0-4.606 1.413l-1.8-1.8a.5.5 0 0 0-.707.707l1.59 1.59A7.983 7.983 0 0 0 4 8.727h16a7.983 7.983 0 0 0-2.477-6.49zM9 6.727a.75.75 0 1 1 0-1.5.75.75 0 0 1 0 1.5zm6 0a.75.75 0 1 1 0-1.5.75.75 0 0 1 0 1.5zM4 9.727v8a2 2 0 0 0 2 2h1v3.5a1.5 1.5 0 0 0 3 0v-3.5h4v3.5a1.5 1.5 0 0 0 3 0v-3.5h1a2 2 0 0 0 2-2v-8H4zm-3 1.5a1.5 1.5 0 0 1 3 0v6a1.5 1.5 0 0 1-3 0v-6zm20 0a1.5 1.5 0 0 1 3 0v6a1.5 1.5 0 0 1-3 0v-6z" /></svg>,
  },
  {
    name: 'iOS',
    ver: '即将推出',
    available: false,
    icon: <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="currentColor" width="28" height="28"><path d="M18.71 19.5c-.83 1.24-1.71 2.45-3.05 2.47-1.34.03-1.77-.79-3.29-.79-1.53 0-2 .77-3.27.82-1.31.05-2.3-1.32-3.14-2.53C4.25 17 2.94 12.45 4.7 9.39c.87-1.52 2.43-2.48 4.12-2.51 1.28-.02 2.5.87 3.29.87.78 0 2.26-1.07 3.8-.91.65.03 2.47.26 3.64 1.98-.09.06-2.17 1.28-2.15 3.81.03 3.02 2.65 4.03 2.68 4.04-.03.07-.42 1.44-1.38 2.83M13 3.5c.73-.83 1.94-1.46 2.94-1.5.13 1.17-.34 2.35-1.04 3.19-.69.85-1.83 1.51-2.95 1.42-.15-1.15.41-2.35 1.05-3.11z" /></svg>,
  },
  {
    name: 'HarmonyOS',
    ver: '即将推出',
    available: false,
    icon: <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" strokeWidth={1.5} stroke="currentColor" width="28" height="28"><path strokeLinecap="round" strokeLinejoin="round" d="M10.5 1.5H8.25A2.25 2.25 0 0 0 6 3.75v16.5a2.25 2.25 0 0 0 2.25 2.25h7.5A2.25 2.25 0 0 0 18 20.25V3.75a2.25 2.25 0 0 0-2.25-2.25H13.5m-3 0V3h3V1.5m-3 0h3m-3 18.75h3" /></svg>,
  },
];

export default function DownloadSection() {
  const { ref, isVisible } = useScrollAnimation();

  return (
    <section className="lp-download">
      <div className="lp-container">
        <div className="lp-section-header">
          <div className="lp-section-badge">多端支持</div>
          <h2 className="lp-section-title">随时随地，制作简历</h2>
          <p className="lp-section-subtitle">支持 Web、桌面和移动端，数据云端同步</p>
        </div>
        <div
          ref={ref}
          className="lp-download-grid"
          style={{
            opacity: isVisible ? 1 : 0,
            transform: isVisible ? 'translateY(0)' : 'translateY(30px)',
            transition: 'opacity 0.6s ease, transform 0.6s ease',
          }}
        >
          {/* Web - always available */}
          <div className="lp-download-card">
            <div className="lp-download-icon">
              <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" strokeWidth={1.5} stroke="currentColor" width="28" height="28"><path strokeLinecap="round" strokeLinejoin="round" d="M12 21a9.004 9.004 0 0 0 8.716-6.747M12 21a9.004 9.004 0 0 1-8.716-6.747M12 21c2.485 0 4.5-4.03 4.5-9S14.485 3 12 3m0 18c-2.485 0-4.5-4.03-4.5-9S9.515 3 12 3m0 0a8.997 8.997 0 0 1 7.843 4.582M12 3a8.997 8.997 0 0 0-7.843 4.582m15.686 0A11.953 11.953 0 0 1 12 10.5c-2.998 0-5.74-1.1-7.843-2.918m15.686 0A8.959 8.959 0 0 1 21 12c0 .778-.099 1.533-.284 2.253m0 0A17.919 17.919 0 0 1 12 16.5c-3.162 0-6.133-.815-8.716-2.247m0 0A9.015 9.015 0 0 1 3 12c0-1.605.42-3.113 1.157-4.418" /></svg>
            </div>
            <div className="lp-download-name">Web 在线版</div>
            <div className="lp-download-ver">无需安装</div>
            <a href="/login" className="lp-download-btn active">立即使用</a>
          </div>

          {platforms.map((p) => (
            <div key={p.name} className={`lp-download-card${p.available ? '' : ' disabled'}`}>
              <div className="lp-download-icon">{p.icon}</div>
              <div className="lp-download-name">{p.name}</div>
              <div className="lp-download-ver">{p.ver}</div>
              {p.available ? (
                <a href={p.url || '#'} className="lp-download-btn active">下载安装</a>
              ) : (
                <span className="lp-download-btn soon">即将推出</span>
              )}
            </div>
          ))}
        </div>
      </div>
    </section>
  );
}
