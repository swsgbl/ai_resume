/**
 * 性能监控工具测试
 */
import { describe, it, expect, beforeEach, beforeAll, vi } from 'vitest';

// Mock web-vitals
vi.mock('web-vitals', () => ({
  onCLS: vi.fn(),
  onFID: vi.fn(),
  onLCP: vi.fn(),
  onFCP: vi.fn(),
  onTTFB: vi.fn(),
}));

describe('performance utils', () => {
  // Setup localStorage before all tests
  const store: Record<string, string> = {};

  beforeAll(() => {
    Object.defineProperty(window, 'localStorage', {
      value: {
        getItem: (key: string) => store[key] || null,
        setItem: (key: string, value: string) => {
          store[key] = value.toString();
        },
        removeItem: (key: string) => {
          delete store[key];
        },
        clear: () => {
          Object.keys(store).forEach((key) => delete store[key]);
        },
        get length() {
          return Object.keys(store).length;
        },
        key: (index: number) => Object.keys(store)[index] || null,
      },
    });
  });

  beforeEach(() => {
    // 清理 localStorage
    localStorage.clear();
    vi.clearAllMocks();
  });

  describe('getRating', () => {
    // 我们无法直接测试 getRating 因为它没有被导出
    // 但我们可以通过测试 initPerformanceMonitoring 来间接验证
    it('应该正确初始化性能监控', async () => {
      const { initPerformanceMonitoring } = await import('./performance');

      // 应该不抛出错误
      await expect(initPerformanceMonitoring()).resolves.not.toThrow();
    });
  });

  describe('getPerformanceReport', () => {
    it('应该返回 null 如果没有性能报告', async () => {
      const { getPerformanceReport } = await import('./performance');
      const report = getPerformanceReport();
      expect(report).toBeNull();
    });

    it('应该返回当前页面的性能报告', async () => {
      const { getPerformanceReport } = await import('./performance');

      // 手动添加一个测试报告
      const testReport = {
        metrics: [
          { name: 'LCP', value: 2000, rating: 'good', timestamp: Date.now() },
        ],
        url: window.location.href,
        userAgent: navigator.userAgent,
        timestamp: Date.now(),
      };
      localStorage.setItem('performance_reports', JSON.stringify([testReport]));

      const report = getPerformanceReport();
      expect(report).not.toBeNull();
      expect(report?.url).toBe(window.location.href);
      expect(report?.metrics).toHaveLength(1);
    });
  });

  describe('getAllPerformanceReports', () => {
    it('应该返回空数组如果没有报告', async () => {
      const { getAllPerformanceReports } = await import('./performance');
      const reports = getAllPerformanceReports();
      expect(reports).toEqual([]);
    });

    it('应该返回所有性能报告', async () => {
      const { getAllPerformanceReports } = await import('./performance');

      const testReports = [
        {
          metrics: [],
          url: 'https://example.com/page1',
          userAgent: 'test-agent',
          timestamp: Date.now(),
        },
        {
          metrics: [],
          url: 'https://example.com/page2',
          userAgent: 'test-agent',
          timestamp: Date.now(),
        },
      ];
      localStorage.setItem('performance_reports', JSON.stringify(testReports));

      const reports = getAllPerformanceReports();
      expect(reports).toHaveLength(2);
    });
  });

  describe('clearPerformanceReports', () => {
    it('应该清除所有性能报告', async () => {
      const { clearPerformanceReports, getAllPerformanceReports } = await import('./performance');

      // 添加测试数据
      localStorage.setItem('performance_reports', JSON.stringify([{}]));

      // 清除
      clearPerformanceReports();

      // 验证
      const reports = getAllPerformanceReports();
      expect(reports).toEqual([]);
    });
  });

  describe('calculatePerformanceScore', () => {
    it('应该返回 100 如果没有报告', async () => {
      const { calculatePerformanceScore } = await import('./performance');
      const score = calculatePerformanceScore(null);
      expect(score).toBe(100);
    });

    it('应该返回 100 如果没有指标', async () => {
      const { calculatePerformanceScore } = await import('./performance');
      const report = {
        metrics: [],
        url: 'https://example.com',
        userAgent: 'test',
        timestamp: Date.now(),
      };
      const score = calculatePerformanceScore(report);
      expect(score).toBe(100);
    });

    it('应该正确计算性能分数', async () => {
      const { calculatePerformanceScore } = await import('./performance');

      const report = {
        metrics: [
          { name: 'LCP', value: 2000, rating: 'good' as const, timestamp: Date.now() },
          { name: 'FID', value: 50, rating: 'good' as const, timestamp: Date.now() },
          { name: 'CLS', value: 0.05, rating: 'good' as const, timestamp: Date.now() },
        ],
        url: 'https://example.com',
        userAgent: 'test',
        timestamp: Date.now(),
      };

      const score = calculatePerformanceScore(report);
      expect(score).toBe(100);
    });

    it('应该正确计算混合评级的分数', async () => {
      const { calculatePerformanceScore } = await import('./performance');

      const report = {
        metrics: [
          { name: 'LCP', value: 2000, rating: 'good' as const, timestamp: Date.now() },
          { name: 'FID', value: 200, rating: 'needs-improvement' as const, timestamp: Date.now() },
          { name: 'CLS', value: 0.3, rating: 'poor' as const, timestamp: Date.now() },
        ],
        url: 'https://example.com',
        userAgent: 'test',
        timestamp: Date.now(),
      };

      const score = calculatePerformanceScore(report);
      // (100 + 50 + 0) / 3 = 50
      expect(score).toBe(50);
    });
  });

  describe('shouldShowPerformanceWarning', () => {
    it('如果没有报告应该返回 false', async () => {
      const { shouldShowPerformanceWarning } = await import('./performance');
      const shouldShow = shouldShowPerformanceWarning();
      expect(shouldShow).toBe(false);
    });

    it('如果所有指标良好应该返回 false', async () => {
      const { shouldShowPerformanceWarning } = await import('./performance');

      const report = {
        metrics: [
          { name: 'LCP', value: 2000, rating: 'good' as const, timestamp: Date.now() },
          { name: 'FID', value: 50, rating: 'good' as const, timestamp: Date.now() },
        ],
        url: window.location.href,
        userAgent: 'test',
        timestamp: Date.now(),
      };
      localStorage.setItem('performance_reports', JSON.stringify([report]));

      const shouldShow = shouldShowPerformanceWarning();
      expect(shouldShow).toBe(false);
    });

    it('如果有 poor 评级应该返回 true', async () => {
      const { shouldShowPerformanceWarning } = await import('./performance');

      const report = {
        metrics: [
          { name: 'LCP', value: 5000, rating: 'poor' as const, timestamp: Date.now() },
        ],
        url: window.location.href,
        userAgent: 'test',
        timestamp: Date.now(),
      };
      localStorage.setItem('performance_reports', JSON.stringify([report]));

      const shouldShow = shouldShowPerformanceWarning();
      expect(shouldShow).toBe(true);
    });

    it('如果 LCP 是 needs-improvement 应该返回 true', async () => {
      const { shouldShowPerformanceWarning } = await import('./performance');

      const report = {
        metrics: [
          { name: 'LCP', value: 3000, rating: 'needs-improvement' as const, timestamp: Date.now() },
        ],
        url: window.location.href,
        userAgent: 'test',
        timestamp: Date.now(),
      };
      localStorage.setItem('performance_reports', JSON.stringify([report]));

      const shouldShow = shouldShowPerformanceWarning();
      expect(shouldShow).toBe(true);
    });
  });
});
