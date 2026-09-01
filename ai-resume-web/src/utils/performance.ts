/**
 * 性能监控系统
 * 监控 CLS, FID, LCP, FCP, TTFB 等关键性能指标
 */

export interface VitalMetric {
  name: string;
  value: number;
  rating: 'good' | 'needs-improvement' | 'poor';
  timestamp: number;
}

export interface PerformanceReport {
  metrics: VitalMetric[];
  url: string;
  userAgent: string;
  timestamp: number;
}

// Web Vitals 阈值 (基于 Google 的推荐标准)
const VITAL_THRESHOLDS = {
  // LCP (Largest Contentful Paint): 最大内容绘制
  LCP: { good: 2500, poor: 4000 },
  // FID (First Input Delay): 首次输入延迟
  FID: { good: 100, poor: 300 },
  // CLS (Cumulative Layout Shift): 累积布局偏移
  CLS: { good: 0.1, poor: 0.25 },
  // FCP (First Contentful Paint): 首次内容绘制
  FCP: { good: 1800, poor: 3000 },
  // TTFB (Time to First Byte): 首字节时间
  TTFB: { good: 800, poor: 1800 },
} as const;

type VitalName = keyof typeof VITAL_THRESHOLDS;

/**
 * 获取性能评级
 */
function getRating(name: VitalName, value: number): 'good' | 'needs-improvement' | 'poor' {
  const threshold = VITAL_THRESHOLDS[name];
  if (value <= threshold.good) return 'good';
  if (value <= threshold.poor) return 'needs-improvement';
  return 'poor';
}

/**
 * 存储性能指标到 localStorage
 */
function saveMetric(metric: VitalMetric): void {
  try {
    const reports: PerformanceReport[] = JSON.parse(
      localStorage.getItem('performance_reports') || '[]'
    );

    // 添加新指标到当前报告或创建新报告
    const currentUrl = window.location.href;
    let currentReport = reports.find(r => r.url === currentUrl);

    if (!currentReport) {
      currentReport = {
        metrics: [],
        url: currentUrl,
        userAgent: navigator.userAgent,
        timestamp: Date.now(),
      };
      reports.push(currentReport);
    }

    // 更新或添加指标
    const existingIndex = currentReport.metrics.findIndex(m => m.name === metric.name);
    if (existingIndex >= 0) {
      currentReport.metrics[existingIndex] = metric;
    } else {
      currentReport.metrics.push(metric);
    }

    // 只保留最近20条报告
    if (reports.length > 20) {
      reports.shift();
    }

    localStorage.setItem('performance_reports', JSON.stringify(reports));
  } catch (e) {
    console.warn('Failed to save performance metric:', e);
  }
}

/**
 * 导入 web-vitals 库并开始监控
 */
export async function initPerformanceMonitoring(): Promise<void> {
  try {
    // 动态导入 web-vitals
    const webvitals = await import(
      /* webpackChunkName: "web-vitals" */ 'web-vitals'
    );

    const { onCLS, onFID, onLCP, onFCP, onTTFB } = webvitals;

    // 监控 CLS
    onCLS((metric) => {
      const vitalMetric: VitalMetric = {
        name: 'CLS',
        value: Math.round(metric.value * 1000) / 1000,
        rating: getRating('CLS', metric.value),
        timestamp: Date.now(),
      };
      saveMetric(vitalMetric);

      if (vitalMetric.rating !== 'good') {
        console.warn('CLS warning:', vitalMetric);
      }
    });

    // 监控 FID
    onFID((metric) => {
      const vitalMetric: VitalMetric = {
        name: 'FID',
        value: Math.round(metric.value),
        rating: getRating('FID', metric.value),
        timestamp: Date.now(),
      };
      saveMetric(vitalMetric);

      if (vitalMetric.rating !== 'good') {
        console.warn('FID warning:', vitalMetric);
      }
    });

    // 监控 LCP
    onLCP((metric) => {
      const vitalMetric: VitalMetric = {
        name: 'LCP',
        value: Math.round(metric.value),
        rating: getRating('LCP', metric.value),
        timestamp: Date.now(),
      };
      saveMetric(vitalMetric);

      if (vitalMetric.rating !== 'good') {
        console.warn('LCP warning:', vitalMetric);
      }
    });

    // 监控 FCP
    onFCP((metric) => {
      const vitalMetric: VitalMetric = {
        name: 'FCP',
        value: Math.round(metric.value),
        rating: getRating('FCP', metric.value),
        timestamp: Date.now(),
      };
      saveMetric(vitalMetric);
    });

    // 监控 TTFB
    onTTFB((metric) => {
      const vitalMetric: VitalMetric = {
        name: 'TTFB',
        value: Math.round(metric.value),
        rating: getRating('TTFB', metric.value),
        timestamp: Date.now(),
      };
      saveMetric(vitalMetric);
    });

    console.log('Performance monitoring initialized');
  } catch (error) {
    console.warn('Failed to initialize performance monitoring:', error);
  }
}

/**
 * 获取当前页面的性能报告
 */
export function getPerformanceReport(): PerformanceReport | null {
  try {
    const reports: PerformanceReport[] = JSON.parse(
      localStorage.getItem('performance_reports') || '[]'
    );
    const currentUrl = window.location.href;
    return reports.find(r => r.url === currentUrl) || null;
  } catch (e) {
    return null;
  }
}

/**
 * 获取所有性能报告
 */
export function getAllPerformanceReports(): PerformanceReport[] {
  try {
    return JSON.parse(localStorage.getItem('performance_reports') || '[]');
  } catch (e) {
    return [];
  }
}

/**
 * 清除性能报告
 */
export function clearPerformanceReports(): void {
  localStorage.removeItem('performance_reports');
}

/**
 * 计算性能分数 (0-100)
 */
export function calculatePerformanceScore(report: PerformanceReport | null): number {
  if (!report || report.metrics.length === 0) return 100;

  let totalScore = 0;
  let count = 0;

  for (const metric of report.metrics) {
    let score = 100;
    if (metric.rating === 'needs-improvement') score = 50;
    if (metric.rating === 'poor') score = 0;
    totalScore += score;
    count++;
  }

  return Math.round(totalScore / count);
}

/**
 * 检查是否需要显示性能警告
 */
export function shouldShowPerformanceWarning(): boolean {
  const report = getPerformanceReport();
  if (!report) return false;

  return report.metrics.some(
    m => m.rating === 'poor' || (m.rating === 'needs-improvement' && m.name === 'LCP')
  );
}

export default {
  initPerformanceMonitoring,
  getPerformanceReport,
  getAllPerformanceReports,
  clearPerformanceReports,
  calculatePerformanceScore,
  shouldShowPerformanceWarning,
};
