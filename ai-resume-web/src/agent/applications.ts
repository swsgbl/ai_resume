import type { JsonResumeApplication, ApplicationOutcome } from '@ai-resume/shared/schema';

/**
 * 投递回流存储 — AI 简历 OS 自进化飞轮的数据底座
 * 每次投递记录 AI 匹配分,结果回流后与预测对照,用于校准评估引擎。
 * 数据仅存本机 localStorage,符合产品隐私承诺。
 */

const STORAGE_KEY = 'os_applications';

export function loadApplications(): JsonResumeApplication[] {
  try {
    const raw = localStorage.getItem(STORAGE_KEY);
    if (!raw) return [];
    const parsed = JSON.parse(raw) as JsonResumeApplication[];
    return Array.isArray(parsed) ? parsed : [];
  } catch {
    return [];
  }
}

function persist(list: JsonResumeApplication[]): void {
  localStorage.setItem(STORAGE_KEY, JSON.stringify(list));
}

export function addApplication(entry: Omit<JsonResumeApplication, 'id'>): JsonResumeApplication {
  const list = loadApplications();
  const record: JsonResumeApplication = {
    ...entry,
    id: `app-${Date.now()}-${Math.random().toString(36).slice(2, 8)}`,
  };
  list.unshift(record);
  persist(list);
  return record;
}

export function updateOutcome(id: string, outcome: ApplicationOutcome): void {
  const list = loadApplications();
  const item = list.find((a) => a.id === id);
  if (item) {
    item.outcome = outcome;
    persist(list);
  }
}

export function removeApplication(id: string): void {
  persist(loadApplications().filter((a) => a.id !== id));
}

export interface CalibrationStats {
  total: number;
  interviewed: number;
  /** 预测命中率:匹配分 ≥ 阈值的投递中,确实进入面试的比例 */
  hitRate: number | null;
  avgMatchOfInterviews: number | null;
  avgMatchOfRejections: number | null;
}

/** 校准统计:AI 预测 vs 真实结果的对照(自进化飞轮的仪表盘) */
export function calibrationStats(threshold = 70): CalibrationStats {
  const list = loadApplications();
  const scored = list.filter((a): a is JsonResumeApplication & { matchScore: number } => typeof a.matchScore === 'number');
  const interviews = scored.filter((a) => a.outcome === 'interview' || a.outcome === 'offer');
  const rejections = scored.filter((a) => a.outcome === 'rejected');
  const positives = scored.filter((a) => a.matchScore >= threshold && (interviews.includes(a) || rejections.includes(a)));

  const avg = (nums: number[]) => (nums.length ? nums.reduce((s, n) => s + n, 0) / nums.length : null);

  return {
    total: list.length,
    interviewed: interviews.length,
    hitRate: positives.length ? interviews.filter((a) => positives.includes(a)).length / positives.length : null,
    avgMatchOfInterviews: avg(interviews.map((a) => a.matchScore)),
    avgMatchOfRejections: avg(rejections.map((a) => a.matchScore)),
  };
}
