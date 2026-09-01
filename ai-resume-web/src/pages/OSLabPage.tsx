import { useRef, useState } from 'react';
import { SEO } from '../components/SEO';
import PublicLayout from '../components/PublicLayout';
import { GradientText, Orb } from '../components/UIComponents';
import { loadModelConfig, saveModelConfig, runAgent, type AgentModelConfig, type AgentRunEvent } from '../agent/runner';
import { extractAgent, evaluateAgent, tailorAgent, type EvaluateResult, type TailorResult } from '../agent/agents';
import { addApplication } from '../agent/applications';
import ApplicationsPanel from '../agent/ApplicationsPanel';
import TabsRow, { type OsTab } from '../agent/TabsRow';
import { jsonResumeSchema } from '@ai-resume/shared/schema';

const PRESETS = [
  { label: 'DeepSeek', baseUrl: 'https://api.deepseek.com/v1', model: 'deepseek-chat' },
  { label: 'OpenAI', baseUrl: 'https://api.openai.com/v1', model: 'gpt-4o-mini' },
  { label: '小米 MiMo', baseUrl: 'https://api.xiaomi.com/v1', model: 'mimo-pro' },
];

export default function OSLabPage() {
  const [tab, setTab] = useState<OsTab>('extract');
  const [config, setConfig] = useState<AgentModelConfig>(
    () => loadModelConfig() ?? { baseUrl: PRESETS[0].baseUrl, apiKey: '', model: PRESETS[0].model }
  );
  const [configSaved, setConfigSaved] = useState(() => !!loadModelConfig());

  const [resumeText, setResumeText] = useState('');
  const [jdText, setJdText] = useState('');
  const [extracted, setExtracted] = useState<Record<string, unknown> | null>(null);
  const [evaluation, setEvaluation] = useState<EvaluateResult | null>(null);
  const [tailoring, setTailoring] = useState<TailorResult | null>(null);
  const [events, setEvents] = useState<AgentRunEvent[]>([]);
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState('');
  const [appsVersion, setAppsVersion] = useState(0);
  const [evalCtx, setEvalCtx] = useState(''); // 评估→定制闭环:评估结果自动作为定制上下文
  const fileInputRef = useRef<HTMLInputElement>(null);

  const pushEvent = (e: AgentRunEvent) => setEvents((prev) => [...prev.slice(-7), e]);

  /** 把评估结果浓缩为定制 Agent 的上下文(闭环关键) */
  const buildEvalContext = (ev: EvaluateResult): string => {
    const weak = ev.dimensions
      .filter((d) => d.score < 70)
      .map((d) => `${d.name}(${d.score}分):${d.comment}`)
      .join('\n');
    return [
      `【评估引擎输出 — 供定制参考】`,
      `综合匹配分:${Math.round(ev.matchScore)} 结论:${ev.verdict}`,
      ev.missingKeywords.length ? `简历缺失关键词:${ev.missingKeywords.join('、')}` : '',
      weak ? `弱项维度:\n${weak}` : '',
    ]
      .filter(Boolean)
      .join('\n');
  };

  const runEvaluate = async (): Promise<EvaluateResult | null> => {
    const input = `简历:\n${resumeText}\n\n职位描述:\n${jdText}`;
    const ev = await runAgent(evaluateAgent, config, input, { onEvent: pushEvent });
    setEvaluation(ev);
    setEvalCtx(buildEvalContext(ev));
    return ev;
  };

  const runTailor = async (extraCtx = '') => {
    const ctx = extraCtx || evalCtx;
    const input = [`简历:\n${resumeText}`, `目标职位描述:\n${jdText}`, ctx ? `\n${ctx}` : ''].join('\n');
    setTailoring(await runAgent(tailorAgent, config, input, { onEvent: pushEvent }));
  };

  /** 一键流水线:评估 → (评估上下文) → 定制,闭环全自动化 */
  const runFullPipeline = async () => {
    if (busy) return;
    if (!config.apiKey) {
      setError('请先在上方填写模型 API Key(仅保存在本机浏览器)');
      return;
    }
    if (!resumeText.trim() || !jdText.trim()) {
      setError('简历与 JD 都需要填写');
      return;
    }
    setBusy(true);
    setError('');
    setTab('evaluate');
    try {
      const ev = await runEvaluate();
      if (ev) await runTailor(buildEvalContext(ev));
      setTab('tailor');
    } catch (e) {
      setError(e instanceof Error ? e.message : String(e));
    } finally {
      setBusy(false);
    }
  };

  const runPipeline = async (kind: OsTab) => {
    if (busy) return;
    if (!config.apiKey) {
      setError('请先在上方填写模型 API Key(仅保存在本机浏览器)');
      return;
    }
    if (kind === 'extract' && resumeText.trim().length < 20) {
      setError('请粘贴至少 20 字的经历描述或旧简历');
      return;
    }
    if (kind !== 'extract' && (!resumeText.trim() || !jdText.trim())) {
      setError('简历与 JD 都需要填写');
      return;
    }

    setBusy(true);
    setError('');
    try {
      if (kind === 'extract') {
        const result = await runAgent(extractAgent, config, resumeText, { onEvent: pushEvent });
        setExtracted(jsonResumeSchema.passthrough().parse(result) as Record<string, unknown>);
      } else if (kind === 'evaluate') {
        await runEvaluate();
      } else {
        await runTailor();
      }
    } catch (e) {
      setError(e instanceof Error ? e.message : String(e));
    } finally {
      setBusy(false);
    }
  };

  const recordApplication = () => {
    if (!evaluation) return;
    const company = prompt('投递公司名称:');
    if (!company) return;
    const position = prompt('投递岗位:', '') || '未填写';
    addApplication({
      company,
      position,
      appliedAt: new Date().toISOString().slice(0, 10),
      outcome: 'submitted',
      matchScore: Math.round(evaluation.matchScore),
      jdSummary: jdText.slice(0, 120),
    });
    setAppsVersion((v) => v + 1);
  };

  const downloadJson = () => {
    if (!extracted) return;
    const blob = new Blob([JSON.stringify(extracted, null, 2)], { type: 'application/json' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = 'resume.json';
    a.click();
    URL.revokeObjectURL(url);
  };

  const importJson = (file: File) => {
    const reader = new FileReader();
    reader.onload = () => {
      try {
        setExtracted(jsonResumeSchema.passthrough().parse(JSON.parse(String(reader.result))) as Record<string, unknown>);
        setError('');
      } catch (e) {
        setError(`JSON Resume 文件校验失败: ${e instanceof Error ? e.message.slice(0, 160) : e}`);
      }
    };
    reader.readAsText(file);
  };

  return (
    <PublicLayout>
      <SEO
        title="AI 简历 OS 实验室"
        description="结构化简历数据核心 + 本地 AI Agent 流水线:抽取、JD 匹配评估、岗位定制与投递回流校准。"
        noIndex
      />
      <div className="fixed inset-0 pointer-events-none overflow-hidden">
        <Orb color="primary" size={220} className="top-0 left-0 -translate-x-1/2 -translate-y-1/2 opacity-20" />
        <Orb color="accent" size={160} className="bottom-0 right-0 translate-x-1/2 translate-y-1/2 opacity-10" />
      </div>
      <div className="fixed inset-0 bg-grid pointer-events-none opacity-5" />

      <div className="relative z-10">
        <main className="max-w-5xl mx-auto px-4 py-12">
          {/* Header */}
          <div className="text-center mb-10">
            <h1 className="text-4xl font-bold mb-3">
              <GradientText>AI 简历 OS 实验室</GradientText>
            </h1>
            <p className="text-slate-400 text-lg">简历即数据 · Agent 即流水线 · 投递即校准</p>
            <p className="text-slate-500 text-sm mt-2">
              JSON Resume 开放标准数据核心,模型密钥与数据仅存本机浏览器
            </p>
          </div>

          {/* 模型配置 */}
          <div className="card-glass mb-6">
            <div className="flex items-center justify-between mb-4">
              <h2 className="text-lg font-semibold text-white">模型配置(本机)</h2>
              <span
                className={`text-xs px-2 py-1 rounded ${
                  configSaved ? 'bg-emerald-500/10 text-emerald-400' : 'bg-amber-500/10 text-amber-400'
                }`}
              >
                {configSaved ? '已配置' : '未配置'}
              </span>
            </div>
            <div className="flex flex-wrap gap-2 mb-4">
              {PRESETS.map((p) => (
                <button
                  key={p.label}
                  onClick={() => setConfig((c) => ({ ...c, baseUrl: p.baseUrl, model: p.model }))}
                  className={`px-3 py-1.5 text-xs rounded-md border transition-colors ${
                    config.baseUrl === p.baseUrl
                      ? 'border-primary-400/50 text-primary-400 bg-primary-500/10'
                      : 'border-slate-700 text-slate-400 hover:text-slate-200'
                  }`}
                >
                  {p.label}
                </button>
              ))}
            </div>
            <div className="grid md:grid-cols-3 gap-3">
              <input
                className="input flex-1"
                placeholder="Base URL (OpenAI 兼容)"
                value={config.baseUrl}
                onChange={(e) => {
                  setConfig({ ...config, baseUrl: e.target.value });
                  setConfigSaved(false);
                }}
              />
              <input
                className="input flex-1"
                placeholder="模型名,如 deepseek-chat"
                value={config.model}
                onChange={(e) => {
                  setConfig({ ...config, model: e.target.value });
                  setConfigSaved(false);
                }}
              />
              <input
                className="input flex-1"
                type="password"
                placeholder="API Key(仅存本机)"
                value={config.apiKey}
                onChange={(e) => {
                  setConfig({ ...config, apiKey: e.target.value });
                  setConfigSaved(false);
                }}
              />
            </div>
            <button
              className="btn btn-primary text-sm mt-3"
              onClick={() => {
                saveModelConfig(config);
                setConfigSaved(true);
              }}
            >
              保存配置
            </button>
          </div>

          {/* Tabs */}
          <TabsRow tab={tab} onChange={setTab} />

          {/* 输入区 */}
          <div className="card-glass mb-6">
            <div className={tab === 'extract' ? '' : 'grid md:grid-cols-2 gap-4'}>
              <div>
                <label className="block text-xs font-medium text-slate-300 mb-1">
                  {tab === 'extract' ? '经历描述 / 旧简历文本' : '简历(JSON Resume 或文本)'}
                </label>
                <textarea
                  className="input min-h-[180px] font-mono text-xs"
                  placeholder={tab === 'extract' ? '粘贴你的旧简历、领英档案或口述经历…' : '粘贴简历 JSON 或文本'}
                  value={resumeText}
                  onChange={(e) => setResumeText(e.target.value)}
                />
              </div>
              {tab !== 'extract' && (
                <div>
                  <label className="block text-xs font-medium text-slate-300 mb-1">目标岗位 JD</label>
                  <textarea
                    className="input min-h-[180px] text-xs"
                    placeholder="粘贴职位描述全文…"
                    value={jdText}
                    onChange={(e) => setJdText(e.target.value)}
                  />
                </div>
              )}
            </div>
            <div className="flex items-center gap-3 mt-4 flex-wrap">
              <button className="btn btn-primary text-sm" disabled={busy} onClick={() => runPipeline(tab)}>
                {busy ? '运行中…' : '运行 Agent'}
              </button>
              {tab !== 'extract' && (
                <button
                  className="btn btn-accent text-sm"
                  disabled={busy}
                  onClick={runFullPipeline}
                  title="评估 Agent 的输出(匹配分/缺失关键词/弱项)自动作为定制 Agent 的输入"
                >
                  ⚡ 一键闭环流水线(评估→定制)
                </button>
              )}
              {tab === 'extract' && (
                <>
                  <button className="btn btn-secondary text-sm" onClick={() => fileInputRef.current?.click()}>
                    导入 resume.json
                  </button>
                  <input
                    ref={fileInputRef}
                    type="file"
                    accept="application/json"
                    className="hidden"
                    onChange={(e) => {
                      const f = e.target.files?.[0];
                      if (f) importJson(f);
                    }}
                  />
                  {extracted !== null && (
                    <button className="btn btn-secondary text-sm" onClick={downloadJson}>
                      导出 resume.json
                    </button>
                  )}
                </>
              )}
              {error !== '' && <span className="text-xs text-rose-400">{error}</span>}
            </div>
          </div>

          {/* Agent 事件时间线 */}
          {events.length > 0 && (
            <div className="card-glass mb-6">
              <h2 className="text-sm font-semibold text-white mb-3">Agent 运行时间线</h2>
              <div className="space-y-1.5 font-mono text-xs">
                {events.map((e, i) => (
                  <div key={i} className="flex items-center gap-2">
                    <span
                      className={`w-1.5 h-1.5 rounded-full ${
                        e.status === 'done'
                          ? 'bg-emerald-400'
                          : e.status === 'failed'
                            ? 'bg-rose-400'
                            : e.status === 'retry'
                              ? 'bg-amber-400'
                              : 'bg-primary-400 animate-pulse'
                      }`}
                    />
                    <span className="text-slate-300">{e.agent}</span>
                    <span className="text-slate-500">
                      {e.status === 'running' ? '执行中' : e.status}
                      {e.detail ? ` · ${e.detail.slice(0, 80)}` : ''}
                    </span>
                  </div>
                ))}
              </div>
            </div>
          )}

          {/* 结果区:抽取 */}
          {tab === 'extract' && extracted !== null && (
            <div className="card-glass mb-6">
              <h2 className="text-lg font-semibold text-white mb-3">JSON Resume 数据核心</h2>
              <pre className="bg-slate-900/60 border border-slate-700/50 rounded-lg p-4 text-xs text-slate-300 overflow-x-auto max-h-96">
                {JSON.stringify(extracted, null, 2)}
              </pre>
            </div>
          )}

          {/* 结果区:评估 */}
          {tab === 'evaluate' && evaluation !== null && (
            <div className="card-glass mb-6">
              <div className="flex items-center justify-between mb-4 flex-wrap gap-3">
                <h2 className="text-lg font-semibold text-white">匹配评估</h2>
                <div className="flex items-center gap-3 flex-wrap">
                  {evalCtx !== '' && (
                    <button
                      className="btn btn-secondary text-sm"
                      disabled={busy}
                      onClick={() => {
                        setTab('tailor');
                        void runPipeline('tailor');
                      }}
                    >
                      带着评估结果去定制 →
                    </button>
                  )}
                  <button className="btn btn-primary text-sm" onClick={recordApplication}>
                    记录投递(带匹配分 {Math.round(evaluation.matchScore)})
                  </button>
                </div>
              </div>
              <div className="flex items-center gap-6 mb-4 flex-wrap">
                <div className="text-4xl font-bold text-primary-400">{Math.round(evaluation.matchScore)}</div>
                <div className="text-sm text-slate-300 max-w-md">{evaluation.verdict}</div>
              </div>
              <div className="space-y-2 mb-4">
                {evaluation.dimensions.map((d) => (
                  <div key={d.name} className="flex items-center gap-3">
                    <span className="text-xs text-slate-400 w-20 shrink-0">{d.name}</span>
                    <div className="flex-1 h-1.5 bg-slate-800 rounded-full overflow-hidden">
                      <div
                        className="h-full bg-gradient-to-r from-primary-500 to-accent-500 rounded-full"
                        style={{ width: `${d.score}%` }}
                      />
                    </div>
                    <span className="text-xs text-slate-300 w-8 text-right">{d.score}</span>
                    <span className="text-xs text-slate-500 flex-1 min-w-[140px]">{d.comment}</span>
                  </div>
                ))}
              </div>
              {evaluation.missingKeywords.length > 0 && (
                <div className="mb-3">
                  <span className="text-xs text-slate-400">缺失关键词:</span>{' '}
                  {evaluation.missingKeywords.map((k) => (
                    <span key={k} className="inline-block text-xs px-2 py-0.5 mr-1.5 mb-1 rounded bg-amber-500/10 text-amber-400">
                      {k}
                    </span>
                  ))}
                </div>
              )}
              {evaluation.risks.length > 0 && (
                <div>
                  <span className="text-xs text-slate-400">风险点:</span>
                  <ul className="text-xs text-slate-400 mt-1 space-y-0.5">
                    {evaluation.risks.map((r) => (
                      <li key={r}>· {r}</li>
                    ))}
                  </ul>
                </div>
              )}
            </div>
          )}

          {/* 结果区:定制 */}
          {tab === 'tailor' && tailoring !== null && (
            <div className="card-glass mb-6">
              <h2 className="text-lg font-semibold text-white mb-3">岗位定制建议</h2>
              <div className="p-4 bg-primary-500/5 border border-primary-500/15 rounded-lg text-sm text-slate-300 mb-4">
                <span className="text-primary-400 font-medium">总结重写:</span> {tailoring.summarySuggestion}
              </div>
              <div className="space-y-3 mb-4">
                {tailoring.bulletSuggestions.map((b, i) => (
                  <div key={i} className="p-3 bg-slate-900/40 border border-slate-700/50 rounded-lg">
                    <div className="text-xs text-slate-500 mb-1">
                      {b.section} · 修改理由:{b.reason}
                    </div>
                    <div className="text-xs text-slate-500 line-through">{b.original}</div>
                    <div className="text-sm text-slate-200 mt-1">{b.improved}</div>
                  </div>
                ))}
              </div>
              {tailoring.keywordsToEmbed.length > 0 && (
                <div>
                  <span className="text-xs text-slate-400">建议嵌入关键词:</span>{' '}
                  {tailoring.keywordsToEmbed.map((k) => (
                    <span key={k} className="inline-block text-xs px-2 py-0.5 mr-1.5 mb-1 rounded bg-emerald-500/10 text-emerald-400">
                      {k}
                    </span>
                  ))}
                </div>
              )}
            </div>
          )}

          {/* 投递回流:自进化飞轮 */}
          <ApplicationsPanel key={appsVersion} />
        </main>
      </div>
    </PublicLayout>
  );
}
