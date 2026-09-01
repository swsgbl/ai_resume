import { useState } from 'react';
import { Link } from 'react-router-dom';
import { GradientText, Orb } from '../components/UIComponents';
import PublicLayout from '../components/PublicLayout';

const API_URL = import.meta.env.VITE_API_URL || '';

interface CareerIntuition {
  first_impression: string;
  gut_score: number;
  archetype: string;
}

interface CareerEvaluationResult {
  intuition?: CareerIntuition;
  overall_score?: number;
  recommendation?: string;
  one_line_summary?: string;
  [key: string]: unknown;
}

export default function CareerPage() {
  const [activeTab, setActiveTab] = useState<'evaluate' | 'stories' | 'tailor'>('evaluate');
  const [jdText, setJdText] = useState('');
  const [loading, setLoading] = useState(false);
  const [result, setResult] = useState<CareerEvaluationResult | null>(null);
  const [error, setError] = useState('');

  const handleEvaluate = async () => {
    if (jdText.length < 50) {
      setError('请输入至少 50 个字符的职位描述');
      return;
    }
    setLoading(true);
    setError('');
    setResult(null);

    try {
      const token = localStorage.getItem('token');
      const response = await fetch(`${API_URL}/api/v1/career/evaluate`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          ...(token ? { Authorization: `Bearer ${token}` } : {}),
        },
        body: JSON.stringify({
          resume_id: 1,
          job_description: jdText,
          user_preferences: '',
        }),
      });

      const data = await response.json();
      if (data.code === 200 || data.data) {
        setResult(data.data || data);
      } else {
        setError(data.message || '评估失败，请稍后重试');
      }
    } catch {
      setError('网络错误，请检查后端服务是否运行');
    } finally {
      setLoading(false);
    }
  };

  return (
    <PublicLayout>
      {/* Background Orbs */}
      <div className="fixed inset-0 pointer-events-none overflow-hidden">
        <Orb color="primary" size={200} className="top-0 left-0 -translate-x-1/2 -translate-y-1/2 opacity-20" />
        <Orb color="accent" size={150} className="bottom-0 right-0 translate-x-1/2 translate-y-1/2 opacity-10" />
      </div>
      <div className="fixed inset-0 bg-grid pointer-events-none opacity-5" />

      <div className="relative z-10">
        <main className="max-w-5xl mx-auto px-4 py-12">
          {/* Header */}
          <div className="text-center mb-10">
            <h1 className="text-4xl font-bold mb-3">
              <GradientText>职业智能中心</GradientText>
            </h1>
            <p className="text-slate-400 text-lg">
              融合 career-ops 评估引擎 + Polanyi 默会知识理论
            </p>
            <p className="text-slate-500 text-sm mt-2">
              AI 模拟资深猎头阅人无数后形成的直觉判断 — 不只是关键词匹配，而是"一看就知道"的职业智慧
            </p>
          </div>

          {/* Tab Navigation */}
          <div className="flex gap-2 mb-8 border-b border-slate-700/50 pb-1">
            {[
              { key: 'evaluate' as const, label: 'JD 智能评估', icon: '🎯' },
              { key: 'stories' as const, label: '故事银行', icon: '📖' },
              { key: 'tailor' as const, label: '智能定制', icon: '✂️' },
            ].map((tab) => (
              <button
                key={tab.key}
                onClick={() => setActiveTab(tab.key)}
                className={`px-5 py-3 text-sm font-medium rounded-t-lg transition-all ${
                  activeTab === tab.key
                    ? 'bg-amber-500/10 text-amber-400 border-b-2 border-amber-400'
                    : 'text-slate-400 hover:text-slate-300 hover:bg-white/5'
                }`}
              >
                <span className="mr-2">{tab.icon}</span>
                {tab.label}
              </button>
            ))}
          </div>

          {/* Evaluate Tab */}
          {activeTab === 'evaluate' && (
            <div className="card-glass">
              <h2 className="text-xl font-semibold text-white mb-2">JD 全景评估</h2>
              <p className="text-slate-400 text-sm mb-6">
                粘贴目标职位的 JD，AI 将以资深猎头的直觉进行 6 维全景分析：职位摘要、简历匹配、等级策略、薪资研究、个性化方案、面试准备
              </p>

              <textarea
                value={jdText}
                onChange={(e) => setJdText(e.target.value)}
                placeholder="粘贴职位描述 (JD) 到这里...&#10;&#10;支持中文和英文 JD，AI 会自动识别语言并适配分析"
                className="w-full h-48 bg-slate-800/50 border border-slate-700/50 rounded-lg p-4 text-slate-300 text-sm placeholder-slate-600 focus:outline-none focus:border-amber-500/50 resize-y"
              />

              <div className="flex items-center justify-between mt-4">
                <span className="text-xs text-slate-500">{jdText.length} 字符</span>
                <div className="flex gap-3">
                  <Link
                    to="/login"
                    className="text-sm text-slate-400 hover:text-amber-400 transition-colors"
                  >
                    需要登录保存结果
                  </Link>
                  <button
                    onClick={handleEvaluate}
                    disabled={loading}
                    className="px-6 py-2.5 bg-gradient-to-r from-amber-500 to-amber-400 text-slate-900 font-semibold rounded-lg hover:shadow-lg hover:shadow-amber-500/20 transition-all disabled:opacity-50"
                  >
                    {loading ? (
                      <span className="flex items-center gap-2">
                        <svg className="animate-spin h-4 w-4" viewBox="0 0 24 24">
                          <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4" fill="none" />
                          <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4z" />
                        </svg>
                        AI 猎头分析中...
                      </span>
                    ) : '开始评估'}
                  </button>
                </div>
              </div>

              {/* Error */}
              {error && (
                <div className="mt-4 p-3 rounded-lg bg-rose-500/10 border border-rose-500/50 text-rose-400 text-sm">
                  {error}
                </div>
              )}

              {/* Result */}
              {result && (
                <div className="mt-6 space-y-4">
                  {/* Intuition */}
                  {result.intuition && (
                    <div className="p-4 rounded-lg bg-amber-500/5 border border-amber-500/20">
                      <h3 className="text-amber-400 font-semibold mb-2">直觉判断</h3>
                      <p className="text-slate-300 text-sm">{result.intuition.first_impression}</p>
                      <div className="mt-3 flex items-center gap-4">
                        <span className="text-2xl font-bold text-amber-400">{result.intuition.gut_score}/5</span>
                        <span className="text-slate-400 text-sm">原型: {result.intuition.archetype}</span>
                      </div>
                    </div>
                  )}

                  {/* Score */}
                  {result.overall_score && (
                    <div className="p-4 rounded-lg bg-emerald-500/5 border border-emerald-500/20">
                      <h3 className="text-emerald-400 font-semibold mb-1">综合评分: {result.overall_score as number}/5</h3>
                      <p className="text-slate-400 text-sm">{result.recommendation as string}</p>
                      <p className="text-slate-500 text-xs mt-1">{result.one_line_summary as string}</p>
                    </div>
                  )}

                  {/* Raw JSON (expandable) */}
                  <details className="group">
                    <summary className="cursor-pointer text-slate-500 text-xs hover:text-slate-400 transition-colors">
                      查看完整分析结果 (JSON)
                    </summary>
                    <pre className="mt-2 p-4 bg-slate-800/50 rounded-lg text-xs text-slate-400 overflow-x-auto">
                      {JSON.stringify(result, null, 2)}
                    </pre>
                  </details>
                </div>
              )}
            </div>
          )}

          {/* Stories Tab */}
          {activeTab === 'stories' && (
            <div className="card-glass">
              <h2 className="text-xl font-semibold text-white mb-2">STAR+R 故事银行</h2>
              <p className="text-slate-400 text-sm mb-4">
                基于 Polanyi 默会知识理论 — 帮你挖掘那些"知道但说不出"的经验智慧，转化为面试中的制胜故事
              </p>

              <div className="p-6 rounded-lg bg-slate-800/30 border border-slate-700/30 text-center">
                <div className="text-4xl mb-3 opacity-50">📖</div>
                <p className="text-slate-400 text-sm mb-3">
                  登录后上传简历，AI 将自动挖掘你的默会经验并生成 STAR+R 面试故事
                </p>
                <Link
                  to="/login"
                  className="inline-block px-5 py-2 bg-gradient-to-r from-amber-500 to-amber-400 text-slate-900 font-semibold rounded-lg text-sm"
                >
                  登录开始挖掘
                </Link>
              </div>

              {/* Explanation */}
              <div className="mt-6 space-y-3">
                <h3 className="text-white font-medium">什么是默会知识？</h3>
                <p className="text-slate-400 text-sm leading-relaxed">
                  Michael Polanyi 说："我们知道的多于我们能说的。" 你在职业生涯中积累了大量无法写在简历上的经验 —
                  处理危机的直觉反应、与人沟通的隐性技巧、技术选型的"第六感"。故事银行帮你把这些默会智慧转化为可复用的面试资产。
                </p>
                <div className="grid grid-cols-1 md:grid-cols-3 gap-3 mt-4">
                  <div className="p-3 rounded-lg bg-amber-500/5 border border-amber-500/10">
                    <div className="text-amber-400 font-medium text-sm mb-1">S - 情境</div>
                    <div className="text-slate-500 text-xs">当时的背景和画面</div>
                  </div>
                  <div className="p-3 rounded-lg bg-emerald-500/5 border border-emerald-500/10">
                    <div className="text-emerald-400 font-medium text-sm mb-1">T - 任务</div>
                    <div className="text-slate-500 text-xs">面对的挑战和目标</div>
                  </div>
                  <div className="p-3 rounded-lg bg-pink-500/5 border border-pink-500/10">
                    <div className="text-pink-400 font-medium text-sm mb-1">A - 行动</div>
                    <div className="text-slate-500 text-xs">你的直觉判断和决策</div>
                  </div>
                </div>
              </div>
            </div>
          )}

          {/* Tailor Tab */}
          {activeTab === 'tailor' && (
            <div className="card-glass">
              <h2 className="text-xl font-semibold text-white mb-2">智能简历定制</h2>
              <p className="text-slate-400 text-sm mb-4">
                不只是关键词替换 — AI 以猎头的直觉调整你的简历叙事角度，让你"看起来就是"目标岗位的理想人选
              </p>

              <div className="p-6 rounded-lg bg-slate-800/30 border border-slate-700/30 text-center">
                <div className="text-4xl mb-3 opacity-50">✂️</div>
                <p className="text-slate-400 text-sm mb-3">
                  登录后选择简历 + 粘贴目标 JD，AI 将生成针对特定职位的定制建议
                </p>
                <Link
                  to="/login"
                  className="inline-block px-5 py-2 bg-gradient-to-r from-amber-500 to-amber-400 text-slate-900 font-semibold rounded-lg text-sm"
                >
                  登录开始定制
                </Link>
              </div>
            </div>
          )}

          {/* Footer Info */}
          <div className="mt-8 text-center text-xs text-slate-600">
            <p>融合 career-ops 评估引擎 | 基于 Michael Polanyi 默会知识理论</p>
            <p className="mt-1">AI 判断仅供参考，最终决策权始终在你手中</p>
          </div>
        </main>
      </div>
    </PublicLayout>
  );
}
