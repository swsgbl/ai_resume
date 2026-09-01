import { useState } from 'react';
import { loadApplications, updateOutcome, calibrationStats } from './applications';
import type { JsonResumeApplication } from '@ai-resume/shared/schema';

/**
 * 投递回流面板 — 自进化飞轮的仪表盘
 * AI 匹配分 vs 真实结果对照,数据仅存本机。
 */

const OUTCOME_LABELS: Record<JsonResumeApplication['outcome'], string> = {
  submitted: '已投递',
  screening: '评估中',
  interview: '获面试',
  offer: 'Offer',
  rejected: '被拒',
  closed: '已关闭',
};

export default function ApplicationsPanel() {
  const [, refresh] = useState(0);
  const apps = loadApplications();
  const stats = calibrationStats();

  return (
    <div className="card-glass">
      <h2 className="text-lg font-semibold text-white mb-1">投递回流 · 自进化校准</h2>
      <p className="text-xs text-slate-500 mb-4">
        AI 匹配分与真实结果持续对照,校准评估引擎 · 数据仅存本机
      </p>
      {apps.length === 0 ? (
        <p className="text-sm text-slate-500">
          暂无投递记录。在②质检台完成评估后点击「记录投递」,等结果出来回来更新状态,系统就能校准预测准度。
        </p>
      ) : (
        <>
          <div className="grid grid-cols-2 md:grid-cols-4 gap-3 mb-5">
            <div className="p-3 bg-slate-900/40 rounded-lg text-center">
              <div className="text-xl font-bold text-white">{stats.total}</div>
              <div className="text-xs text-slate-500">累计投递</div>
            </div>
            <div className="p-3 bg-slate-900/40 rounded-lg text-center">
              <div className="text-xl font-bold text-emerald-400">{stats.interviewed}</div>
              <div className="text-xs text-slate-500">进入面试</div>
            </div>
            <div className="p-3 bg-slate-900/40 rounded-lg text-center">
              <div className="text-xl font-bold text-primary-400">
                {stats.hitRate !== null ? `${Math.round(stats.hitRate * 100)}%` : '—'}
              </div>
              <div className="text-xs text-slate-500">预测命中率(≥70分)</div>
            </div>
            <div className="p-3 bg-slate-900/40 rounded-lg text-center">
              <div className="text-xl font-bold text-slate-300">
                {stats.avgMatchOfInterviews !== null ? Math.round(stats.avgMatchOfInterviews) : '—'}
                <span className="text-sm text-slate-600"> / </span>
                {stats.avgMatchOfRejections !== null ? Math.round(stats.avgMatchOfRejections) : '—'}
              </div>
              <div className="text-xs text-slate-500">面试均分 / 被拒均分</div>
            </div>
          </div>
          <div className="space-y-2">
            {apps.map((a: JsonResumeApplication) => (
              <div
                key={a.id}
                className="flex items-center justify-between gap-3 p-3 bg-slate-900/40 border border-slate-700/40 rounded-lg"
              >
                <div className="min-w-0">
                  <div className="text-sm text-slate-200 truncate">
                    {a.company} · {a.position}
                    <span className="ml-2 text-xs text-primary-400">
                      {typeof a.matchScore === 'number' ? a.matchScore : '—'}分
                    </span>
                  </div>
                  <div className="text-xs text-slate-500">{a.appliedAt}</div>
                </div>
                <select
                  className="text-xs bg-slate-800 border border-slate-700 rounded px-2 py-1 text-slate-300"
                  value={a.outcome}
                  onChange={(e) => {
                    updateOutcome(a.id, e.target.value as JsonResumeApplication['outcome']);
                    refresh((n) => n + 1);
                  }}
                >
                  {Object.entries(OUTCOME_LABELS).map(([k, v]) => (
                    <option key={k} value={k}>{v}</option>
                  ))}
                </select>
              </div>
            ))}
          </div>
        </>
      )}
    </div>
  );
}
