import { useEffect } from 'react';

/**
 * Analytics tracking component.
 * Activated by VITE_BAIDU_ANALYTICS_ID and/or VITE_GA_ID env vars.
 */
export function Analytics() {
  useEffect(() => {
    const baiduId = import.meta.env.VITE_BAIDU_ANALYTICS_ID as string | undefined;
    const gaId = import.meta.env.VITE_GA_ID as string | undefined;

    // Baidu Analytics (国内主流)
    if (baiduId) {
      const script = document.createElement('script');
      script.src = `https://hm.baidu.com/hm.js?${baiduId}`;
      script.async = true;
      document.head.appendChild(script);
    }

    // Google Analytics (海外辅助)
    if (gaId) {
      const gtagSrc = document.createElement('script');
      gtagSrc.src = `https://www.googletagmanager.com/gtag/js?id=${gaId}`;
      gtagSrc.async = true;
      document.head.appendChild(gtagSrc);

      const gtagInit = document.createElement('script');
      gtagInit.textContent = `
        window.dataLayer = window.dataLayer || [];
        function gtag(){dataLayer.push(arguments);}
        gtag('js', new Date());
        gtag('config', '${gaId}');
      `;
      document.head.appendChild(gtagInit);
    }
  }, []);

  return null;
}
