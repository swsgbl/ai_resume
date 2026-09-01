import { describe, it, expect } from 'vitest';
import { render } from '@testing-library/react';
import OAuthProviderIcon from './OAuthProviderIcon';

describe('OAuthProviderIcon Component', () => {
  it('应该渲染Google图标', () => {
    const { container } = render(<OAuthProviderIcon provider="google" />);
    const svg = container.querySelector('svg');
    expect(svg).toBeInTheDocument();
    expect(svg).toHaveClass('w-5', 'h-5');
  });

  it('应该渲染GitHub图标', () => {
    const { container } = render(<OAuthProviderIcon provider="github" />);
    const svg = container.querySelector('svg');
    expect(svg).toBeInTheDocument();
    expect(svg?.getAttribute('fill')).toBe('currentColor');
  });

  it('应该渲染Gitee图标', () => {
    const { container } = render(<OAuthProviderIcon provider="gitee" />);
    const svg = container.querySelector('svg');
    expect(svg).toBeInTheDocument();
    expect(svg?.getAttribute('fill')).toBe('currentColor');
  });

  it('应该渲染Discord图标', () => {
    const { container } = render(<OAuthProviderIcon provider="discord" />);
    const svg = container.querySelector('svg');
    expect(svg).toBeInTheDocument();
    expect(svg?.getAttribute('fill')).toBe('currentColor');
  });

  it('未知提供商应该返回null', () => {
    const { container } = render(<OAuthProviderIcon provider="unknown" />);
    expect(container.firstChild).toBeNull();
  });

  it('应该应用自定义className', () => {
    const { container } = render(
      <OAuthProviderIcon provider="google" className="w-10 h-10" />
    );
    const svg = container.querySelector('svg');
    expect(svg).toHaveClass('w-10', 'h-10');
    expect(svg).not.toHaveClass('w-5', 'h-5');
  });

  it('Google图标应该有正确的颜色路径', () => {
    const { container } = render(<OAuthProviderIcon provider="google" />);
    const paths = container.querySelectorAll('path');
    expect(paths.length).toBe(4);
    expect(paths[0].getAttribute('fill')).toBe('#4285F4');
    expect(paths[1].getAttribute('fill')).toBe('#34A853');
    expect(paths[2].getAttribute('fill')).toBe('#FBBC05');
    expect(paths[3].getAttribute('fill')).toBe('#EA4335');
  });

  it('GitHub图标应该有正确的viewBox', () => {
    const { container } = render(<OAuthProviderIcon provider="github" />);
    const svg = container.querySelector('svg');
    expect(svg?.getAttribute('viewBox')).toBe('0 0 24 24');
  });
});
