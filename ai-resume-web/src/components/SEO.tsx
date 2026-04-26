import { Helmet } from 'react-helmet-async';

interface SEOProps {
  title?: string;
  description?: string;
  keywords?: string;
  ogImage?: string;
  ogType?: 'website' | 'article';
  noIndex?: boolean;
  canonicalUrl?: string;
}

const SITE_NAME = 'ndtool AI简历智能生成平台';
const DEFAULT_DESCRIPTION = '免费AI简历生成器，30秒生成专业简历。支持DeepSeek/OpenAI/小米MiMo多模型，智能优化+JD匹配，一键导出PDF/Word。应届生、跳槽者都在用的免费简历工具。';
const DEFAULT_KEYWORDS = 'AI简历,简历生成器,在线简历,简历模板,智能简历,PDF简历,AI简历生成,求职简历模板,应届生简历,简历怎么写,DeepSeek简历,免费简历工具,简历优化,AI简历修改,STAR法则简历,中英文简历,简历导出PDF,简历排版';
const DEFAULT_OG_IMAGE = '/og-image.png';

export function SEO({
  title,
  description = DEFAULT_DESCRIPTION,
  keywords = DEFAULT_KEYWORDS,
  ogImage = DEFAULT_OG_IMAGE,
  ogType = 'website',
  noIndex = false,
  canonicalUrl,
}: SEOProps) {
  const fullTitle = title ? `${title} | ${SITE_NAME}` : SITE_NAME;

  return (
    <Helmet>
      {/* Basic Meta Tags */}
      <title>{fullTitle}</title>
      <meta name="description" content={description} />
      <meta name="keywords" content={keywords} />
      {noIndex && <meta name="robots" content="noindex, nofollow" />}

      {/* Canonical URL */}
      {canonicalUrl && <link rel="canonical" href={canonicalUrl} />}

      {/* Open Graph / Facebook */}
      <meta property="og:type" content={ogType} />
      <meta property="og:title" content={fullTitle} />
      <meta property="og:description" content={description} />
      <meta property="og:image" content={ogImage} />
      {canonicalUrl && <meta property="og:url" content={canonicalUrl} />}
      <meta property="og:site_name" content={SITE_NAME} />

      {/* Twitter */}
      <meta name="twitter:card" content="summary_large_image" />
      <meta name="twitter:title" content={fullTitle} />
      <meta name="twitter:description" content={description} />
      <meta name="twitter:image" content={ogImage} />

      {/* Additional Meta Tags */}
      <meta name="viewport" content="width=device-width, initial-scale=1.0" />
      <meta charSet="UTF-8" />

      {/* Favicon */}
      <link rel="icon" type="image/svg+xml" href="/vite.svg" />

      {/* Structured Data (JSON-LD) */}
      <script type="application/ld+json">
        {JSON.stringify({
          '@context': 'https://schema.org',
          '@type': 'WebApplication',
          name: SITE_NAME,
          description: DEFAULT_DESCRIPTION,
          url: 'https://ndtool.cn',
          applicationCategory: 'BusinessApplication',
          operatingSystem: 'All',
          offers: {
            '@type': 'Offer',
            price: '0',
            priceCurrency: 'CNY',
          },
          author: {
            '@type': 'Organization',
            name: 'ndtool',
          },
        })}
      </script>
    </Helmet>
  );
}
