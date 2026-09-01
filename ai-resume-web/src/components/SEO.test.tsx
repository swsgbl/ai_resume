/**
 * SEO 组件测试
 */
import { describe, it, expect, beforeEach, vi } from 'vitest';
import { render, screen } from '@testing-library/react';
import '@testing-library/jest-dom';
import { SEO } from './SEO';

// Mock Helmet
vi.mock('react-helmet-async', () => ({
  Helmet: ({ children }: { children: React.ReactNode }) => <div data-testid="helmet">{children}</div>,
}));

describe('SEO Component', () => {
  beforeEach(() => {
    // 清除 document head
    document.head.innerHTML = '';
  });

  it('渲染默认 SEO 标签', () => {
    render(<SEO />);

    // Helmet 组件应该被渲染
    expect(screen.getByTestId('helmet')).toBeInTheDocument();
  });

  it('设置页面标题', () => {
    render(<SEO title="首页" />);

    // 验证标题包含在 Helmet 中
    const helmet = screen.getByTestId('helmet');
    expect(helmet.innerHTML).toContain('首页');
    expect(helmet.innerHTML).toContain('ndtool AI简历智能生成平台');
  });

  it('使用默认站点名称', () => {
    render(<SEO />);

    const helmet = screen.getByTestId('helmet');
    expect(helmet.innerHTML).toContain('ndtool AI简历智能生成平台');
  });

  it('设置描述', () => {
    render(<SEO description="这是一个测试页面" />);

    const helmet = screen.getByTestId('helmet');
    expect(helmet.innerHTML).toContain('这是一个测试页面');
  });

  it('使用默认描述', () => {
    render(<SEO />);

    const helmet = screen.getByTestId('helmet');
    expect(helmet.innerHTML).toContain('免费AI简历生成器');
  });

  it('设置关键词', () => {
    render(<SEO keywords="测试,SEO,关键词" />);

    const helmet = screen.getByTestId('helmet');
    expect(helmet.innerHTML).toContain('测试,SEO,关键词');
  });

  it('使用默认关键词', () => {
    render(<SEO />);

    const helmet = screen.getByTestId('helmet');
    expect(helmet.innerHTML).toContain('AI简历');
  });

  it('设置 OG 图片', () => {
    render(<SEO ogImage="/custom-og-image.png" />);

    const helmet = screen.getByTestId('helmet');
    expect(helmet.innerHTML).toContain('/custom-og-image.png');
  });

  it('使用默认 OG 图片', () => {
    render(<SEO />);

    const helmet = screen.getByTestId('helmet');
    expect(helmet.innerHTML).toContain('/og-image.png');
  });

  it('设置 OG 类型', () => {
    render(<SEO ogType="article" />);

    const helmet = screen.getByTestId('helmet');
    expect(helmet.innerHTML).toContain('article');
  });

  it('默认 OG 类型为 website', () => {
    render(<SEO />);

    const helmet = screen.getByTestId('helmet');
    expect(helmet.innerHTML).toContain('website');
  });

  it('设置 canonical URL', () => {
    render(<SEO canonicalUrl="https://example.com/page" />);

    const helmet = screen.getByTestId('helmet');
    expect(helmet.innerHTML).toContain('https://example.com/page');
  });

  it('设置 noindex 标签', () => {
    render(<SEO noIndex />);

    const helmet = screen.getByTestId('helmet');
    expect(helmet.innerHTML).toContain('noindex');
    expect(helmet.innerHTML).toContain('nofollow');
  });

  it('不设置 noindex 时不包含 robots 标签', () => {
    render(<SEO noIndex={false} />);

    const helmet = screen.getByTestId('helmet');
    expect(helmet.innerHTML).not.toContain('noindex');
  });

  it('标题格式正确', () => {
    render(<SEO title="关于我们" />);

    const helmet = screen.getByTestId('helmet');
    // 标题应该是 "关于我们 | ndtool AI简历智能生成平台"
    const titleContent = helmet.innerHTML.match(/关于我们.*ndtool AI简历智能生成平台/);
    expect(titleContent).toBeTruthy();
  });

  it('包含 Twitter Card 标签', () => {
    render(<SEO />);

    const helmet = screen.getByTestId('helmet');
    expect(helmet.innerHTML).toContain('twitter:card');
    expect(helmet.innerHTML).toContain('summary_large_image');
  });

  it('包含 Open Graph 标签', () => {
    render(<SEO />);

    const helmet = screen.getByTestId('helmet');
    expect(helmet.innerHTML).toContain('og:');
    expect(helmet.innerHTML).toContain('og:type');
    expect(helmet.innerHTML).toContain('og:title');
    expect(helmet.innerHTML).toContain('og:description');
    expect(helmet.innerHTML).toContain('og:image');
  });

  it('包含 viewport meta 标签', () => {
    render(<SEO />);

    const helmet = screen.getByTestId('helmet');
    expect(helmet.innerHTML).toContain('viewport');
    expect(helmet.innerHTML).toContain('width=device-width');
  });

  it('包含 UTF-8 字符集', () => {
    render(<SEO />);

    const helmet = screen.getByTestId('helmet');
    expect(helmet.innerHTML).toContain('UTF-8');
  });

  it('包含 favicon 链接', () => {
    render(<SEO />);

    const helmet = screen.getByTestId('helmet');
    expect(helmet.innerHTML).toContain('/vite.svg');
    expect(helmet.innerHTML).toContain('icon');
  });

  it('完整的 SEO 标签组合', () => {
    render(
      <SEO
        title="测试页面"
        description="测试描述"
        keywords="测试,关键词"
        ogImage="/test.png"
        canonicalUrl="https://test.com"
        noIndex={false}
      />
    );

    const helmet = screen.getByTestId('helmet');
    expect(helmet.innerHTML).toContain('测试页面');
    expect(helmet.innerHTML).toContain('测试描述');
    expect(helmet.innerHTML).toContain('测试,关键词');
    expect(helmet.innerHTML).toContain('/test.png');
    expect(helmet.innerHTML).toContain('https://test.com');
  });
});
