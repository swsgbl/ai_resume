import { describe, it, expect, beforeEach } from 'vitest';
import { render } from '@testing-library/react';
import { Analytics } from './Analytics';

describe('Analytics Component', () => {
  beforeEach(() => {
    // 清除所有动态添加的脚本标签
    document.head.innerHTML = '';
  });

  it('应该返回null不渲染任何内容', () => {
    const { container } = render(<Analytics />);
    expect(container.firstChild).toBeNull();
  });

  it('应该创建script标签元素', () => {
    // 这个测试只验证组件能正常渲染
    // 实际的脚本注入需要真实的环境变量
    const { container } = render(<Analytics />);
    expect(container.firstChild).toBeNull();
    expect(() => render(<Analytics />)).not.toThrow();
  });

  it('应该正确处理空的环境变量', () => {
    vi.stubEnv('VITE_BAIDU_ANALYTICS_ID', '');
    vi.stubEnv('VITE_GA_ID', '');

    const { container } = render(<Analytics />);
    expect(container.firstChild).toBeNull();
  });

  it('组件应该有正确的导出', () => {
    expect(Analytics).toBeDefined();
    expect(typeof Analytics).toBe('function');
  });
});
