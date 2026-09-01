import { useRef, useState } from 'react';
import { SEO } from '../components/SEO';
import PublicLayout from '../components/PublicLayout';
import { GradientText, Orb } from '../components/UIComponents';
import { gsap, useGSAP, MOTION_OK } from '../animation/motion';
import { loadModelConfig, runAgent, type AgentRunEvent } from '../agent/runner';
import { extractAgent, evaluateAgent, tailorAgent, type EvaluateResult, type TailorResult } from '../agent/agents';
import { addApplication } from '../agent/applications';
import ApplicationsPanel from '../agent/ApplicationsPanel';
import ModelConfigCard from '../agent/ModelConfigCard';
import { jsonResumeSchema } from '@ai-resume/shared/schema';

type StationKind = 'extract' | 'evaluate' | 'tailor';
type Busy = StationKind | 'pipeline' | null;

type StationStatus = 'idle' | 'running' | 'done';

function StatusChip({ status }: { status: StationStatus }) {
  if (status === 'running')
    return (
      <span className="flex shrink-0 items-center gap-1.5 rounded-full bg-primary-500/10 px-2.5 py-1 text-[11px] text-primary-400">
        <span className="h-1.5 w-1.5 animate-pulse rounded-full bg-primary-400" />
        运行中
      </span>
    );
  if (status === 'done')
    return (
      <span className="flex shrink-0 items-center gap-1.5 rounded-full bg-emerald-500/10 px-2.5 py-1 text-[11px] text-emerald-400">
        <svg className="h-3 w-3" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={3} d="M5 13l4 4L19 7" />
        </svg>
        完成
      </span>
    );
  return (
    <span className="flex shrink-0 items-center gap-1.5 rounded-full bg-slate-800 px-2.5 py-1 text-[11px] text-slate-500">
      <span className="h-1.5 w-1.5 rounded-full bg-slate-600" />
      待命
    </span>
  );
}

function FlowArrow({ active }: { active: boolean }) {
  return (
    <div className="hidden w-8 shrink-0 items-center justify-center self-center lg:flex" aria-hidden>
      <svg
        className={`h-6 w-6 transition-colors duration-500 ${active ? 'text-accent-500' : 'text-slate-700'}`}
        fill="none"
        stroke="currentColor"
        viewBox="0 0 24 24"
      >
        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M13 6l6 6-6 6M5 6l6 6-6 6" />
      </svg>
    </div>
  );
}

function StationCard({
  no,
  title,
  sub,
  status,
  children,
}: {
  no: string;
  title: string;
  sub: string;
  status: StationStatus;
  children: React.ReactNode;
}) {
  return (
    <section className="os-station card-glass flex min-h-[460px] flex-col rounded-2xl p-5 lg:min-h-[calc(100vh-320px)]">
      <header className="mb-4 flex items-start justify-between gap-3">
        <div className="min-w-0">
          <div className="flex items-center gap-2.5">
            <span className="flex h-8 w-8 shrink-0 items-center justify-center rounded-lg border border-primary-400/30 bg-primary-500/10 text-sm font-bold text-primary-400">
              {no}
            </span>
            <h2 className="truncate text-base font-semibold text-white">{title}</h2>
          </div>
          <p className="mt-1.5 text-xs leading-relaxed text-slate-500">{sub}</p>
        </div>
        <StatusChip status={status} />
      </header>
      <div className="flex min-h-0 flex-1 flex-col gap-3">{children}</div>
    </section>
  );
}

export default function OSLabPage() {
  const [resumeText, setResumeText] = useState('');
  const [jdText, setJdText] = useState('');
  const [extracted, setExtracted] = useState<Record<string, unknown> | null>(null);
  const [evaluation, setEvaluation] = useState<EvaluateResult | null>(null);
  const [tailoring, setTailoring] = useState<TailorResult | null>(null);
  const [events, setEvents] = useState<AgentRunEvent[]>([]);
  const [busy, setBusy] = useState<Busy>(null);
  const [error, setError] = useState('');
  const [appsVersion, setAppsVersion] = useState(0);
  const [evalCtx, setEvalCtx] = useState(''); // 质检台产出 → 加工台上下文(闭环关键)
  const fileInputRef = useRef<HTMLInputElement>(null);
  const rootRef = useRef<HTMLDivElement>(null);

  /* 工位入场:鱼贯升起 */
  useGSAP(
    () => {
      const mm = gsap.matchMedia();
      mm.add(MOTION_OK, () => {
        gsap.from('.os-station', { y: 30, autoAlpha: 0, duration: 0.7, stagger: 0.12, ease: 'ink' });
      });
      return () => mm.revert();
    },
    { scope: rootRef }
  );

  const pushEvent = (e: AgentRunEvent) => setEvents((prev) => [...prev.slice(-7), e]);

  /** 质检报告浓缩为加工台的输入上下文 */
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

  /** 运行前取本机配置;未配置则给出人话指引 */
  const requireConfig = () => {
    const cfg = loadModelConfig();
    if (!cfg || !cfg.apiKey) {
      setError('请先点击右上角「⚙ 模型」填写 API Key(仅保存本机浏览器),也可在「设置」页管理。');
      return null;
    }
    return cfg;
  };

  const runExtract = async () => {
    const cfg = requireConfig();
    if (!cfg) return;
    if (resumeText.trim().length < 20) {
      setError('原料台需要至少 20 字的经历描述或旧简历文本。');
      return;
    }
    setBusy('extract');
    setError('');
    try {
      const result = await runAgent(extractAgent, cfg, resumeText, { onEvent: pushEvent });
      setExtracted(jsonResumeSchema.passthrough().parse(result) as Record<string, unknown>);
    } catch (e) {
      setError(e instanceof Error ? e.message : String(e));
    } finally {
      setBusy(null);
    }
  };

  const runEvaluate = async (): Promise<EvaluateResult | null> => {
    const input = `简历:\n${resumeText}\n\n职位描述:\n${jdText}`;
    const ev = await runAgent(evaluateAgent, loadModelConfig()!, input, { onEvent: pushEvent });
    setEvaluation(ev);
    setEvalCtx(buildEvalContext(ev));
    return ev;
  };

  const runEvaluateStation = async () => {
    const cfg = requireConfig();
    if (!cfg) return;
    if (!resumeText.trim() || !jdText.trim()) {
      setError('质检台需要 ① 的简历原料与本台的岗位 JD。');
      return;
    }
    setBusy('evaluate');
    setError('');
    try {
      await runEvaluate();
    } catch (e) {
      setError(e instanceof Error ? e.message : String(e));
    } finally {
      setBusy(null);
    }
  };

  const runTailor = async (extraCtx = '') => {
    const ctx = extraCtx || evalCtx;
    const input = [`简历:\n${resumeText}`, `目标职位描述:\n${jdText}`, ctx ? `\n${ctx}` : ''].join('\n');
    setTailoring(await runAgent(tailorAgent, loadModelConfig()!, input, { onEvent: pushEvent }));
  };

  const runTailorStation = async () => {
    const cfg = requireConfig();
    if (!cfg) return;
    if (!resumeText.trim() || !jdText.trim()) {
      setError('加工台需要 ① 的简历原料与 ② 的岗位 JD。');
      return;
    }
    setBusy('tailor');
    setError('');
    try {
      await runTailor();
    } catch (e) {
      setError(e instanceof Error ? e.message : String(e));
    } finally {
      setBusy(null);
    }
  };

  /** 总闸:质检 → (质检报告) → 加工,一键闭环 */
  const runFullPipeline = async () => {
    const cfg = requireConfig();
    if (!cfg) return;
    if (!resumeText.trim() || !jdText.trim()) {
      setError('一键闭环需要 ① 的简历原料与 ② 的岗位 JD。');
      return;
    }
    setBusy('pipeline');
    setError('');
    try {
      const ev = await runEvaluate();
      if (ev) await runTailor(buildEvalContext(ev));
    } catch (e) {
      setError(e instanceof Error ? e.message : String(e));
    } finally {
      setBusy(null);
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

  /** 把①的数据砖显式替换为下游原料(人控,不偷改) */
  const useExtractedAsMaterial = () => {
    if (!extracted) return;
    setResumeText(JSON.stringify(extracted, null, 2));
  };

  const st1: StationStatus = busy === 'extract' ? 'running' : extracted ? 'done' : 'idle';
  const st2: StationStatus =
    busy === 'evaluate' || busy === 'pipeline' ? 'running' : evaluation ? 'done' : 'idle';
  const st3: StationStatus = busy === 'tailor' || busy === 'pipeline' ? 'running' : tailoring ? 'done' : 'idle';
  const busyLabel =
    busy === 'pipeline'
      ? '闭环流水线运行中…'
      : busy === 'extract'
        ? '原料台抽取中…'
        : busy === 'evaluate'
          ? '质检台评估中…'
          : '加工台定制中…';

  return (
    <PublicLayout>
      <SEO
        title="简历生成车间 · AI 简历 OS"
        description="原料 → 质检 → 加工:三工位流水线完成结构化抽取、JD 匹配评估与岗位定制,投递回流持续校准。密钥与数据仅存本机。"
        noIndex
      />
      <div className="fixed inset-0 pointer-events-none overflow-hidden">
        <Orb color="primary" size={220} className="top-0 left-0 -translate-x-1/2 -translate-y-1/2 opacity-20" />
        <Orb color="accent" size={160} className="bottom-0 right-0 translate-x-1/2 translate-y-1/2 opacity-10" />
      </div>
      <div className="fixed inset-0 bg-grid pointer-events-none opacity-5" />

      <div className="relative z-10" ref={rootRef}>
        <div className="mx-auto w-full max-w-[1680px] px-4 pb-16 lg:px-8">
          {/* 车间顶栏 */}
          <header className="pt-8 pb-5 lg:pt-10">
            <div className="flex flex-wrap items-end justify-between gap-x-6 gap-y-4">
              <div className="min-w-0">
                <h1 className="text-3xl font-bold lg:text-4xl">
                  <GradientText>简历生成车间</GradientText>
                </h1>
                <p className="mt-2 max-w-2xl text-sm text-slate-400 lg:text-base">
                  原料 → 质检 → 加工,一条流水线产出定制简历 · JSON Resume 开放标准 · 密钥与数据仅存本机
                </p>
              </div>
              <div className="flex flex-wrap items-center gap-3">
                <ModelConfigCard compact />
                <button
                  className="btn btn-accent text-sm"
                  disabled={busy !== null}
                  onClick={runFullPipeline}
                  title="质检 Agent 的匹配分/缺失关键词/弱项自动作为加工 Agent 的输入"
                >
                  {busy === 'pipeline' ? '闭环运行中…' : '⚡ 一键闭环(质检→加工)'}
                </button>
              </div>
            </div>
            {(busy !== null || error !== '') && (
              <div className="mt-4 flex items-center gap-3 text-xs">
                {busy !== null && (
                  <span className="flex items-center gap-2 rounded-full bg-primary-500/10 px-3 py-1.5 text-primary-400">
                    <span className="h-1.5 w-1.5 animate-pulse rounded-full bg-primary-400" />
                    {busyLabel}
                  </span>
                )}
                {error !== '' && (
                  <span className="rounded-full bg-rose-500/10 px-3 py-1.5 text-rose-400">{error}</span>
                )}
              </div>
            )}
          </header>

          {/* 三工位:原料 → 质检 → 加工 */}
          <div className="grid items-stretch gap-4 lg:grid-cols-[1fr_auto_1fr_auto_1fr] lg:gap-2">
            {/* ① 原料台 */}
            <StationCard
              no="①"
              title="原料台 · 结构化抽取"
              sub="旧简历、领英档案或口述经历 → 压成 JSON Resume 标准数据砖,供全车间使用"
              status={st1}
            >
              <label className="text-xs font-medium text-slate-300">经历描述 / 旧简历文本</label>
              <textarea
                className="input min-h-[150px] flex-1 font-mono text-xs"
                placeholder="粘贴你的旧简历、领英档案或口述经历…这里是全车间共享的原料"
                value={resumeText}
                onChange={(e) => setResumeText(e.target.value)}
              />
              <div className="flex flex-wrap items-center gap-2">
                <button className="btn btn-primary text-sm" disabled={busy !== null} onClick={runExtract}>
                  {busy === 'extract' ? '抽取中…' : '▶ 开始抽取'}
                </button>
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
                  <>
                    <button className="btn btn-secondary text-sm" onClick={downloadJson}>
                      导出 resume.json
                    </button>
                    <button
                      className="btn btn-secondary text-sm"
                      onClick={useExtractedAsMaterial}
                      title="把抽取出的 JSON Resume 作为原料文本,供②③直接使用"
                    >
                      用数据砖替换原料 ↓
                    </button>
                  </>
                )}
              </div>
              {extracted !== null && (
                <div className="min-h-0">
                  <p className="mb-1.5 text-xs text-slate-500">JSON Resume 数据核心</p>
                  <pre className="max-h-52 overflow-auto rounded-lg border border-slate-700/50 bg-slate-900/60 p-3 text-[11px] leading-relaxed text-slate-300">
                    {JSON.stringify(extracted, null, 2)}
                  </pre>
                </div>
              )}
            </StationCard>

            <FlowArrow active={extracted !== null} />

            {/* ② 质检台 */}
            <StationCard
              no="②"
              title="质检台 · JD 匹配评估"
              sub="拿①的原料对照岗位 JD,量出匹配分、缺失关键词与弱项维度"
              status={st2}
            >
              <div className="flex items-center justify-between gap-2 text-xs">
                <label className="font-medium text-slate-300">目标岗位 JD</label>
                <span className={resumeText.trim() ? 'text-emerald-400/80' : 'text-slate-600'}>
                  原料来自① {resumeText.trim() ? `· ${resumeText.trim().length} 字就绪` : '· 待投放'}
                </span>
              </div>
              <textarea
                className="input min-h-[120px] text-xs"
                placeholder="粘贴职位描述全文…"
                value={jdText}
                onChange={(e) => setJdText(e.target.value)}
              />
              <div className="flex flex-wrap items-center gap-2">
                <button className="btn btn-primary text-sm" disabled={busy !== null} onClick={runEvaluateStation}>
                  {busy === 'evaluate' ? '评估中…' : '▶ 开始评估'}
                </button>
                {evaluation !== null && (
                  <button className="btn btn-secondary text-sm" onClick={recordApplication}>
                    记录投递(匹配分 {Math.round(evaluation.matchScore)})
                  </button>
                )}
              </div>
              {evaluation === null ? (
                <div className="flex flex-1 flex-col items-center justify-center rounded-lg border border-dashed border-slate-700/60 px-4 py-8 text-center">
                  <span className="text-2xl opacity-60">📋</span>
                  <p className="mt-2 text-xs text-slate-400">质检报告 · 待生成</p>
                  <p className="mt-1 text-[11px] leading-relaxed text-slate-600">
                    将产出:匹配分 / 维度评分 / 缺失关键词 / 风险点
                  </p>
                </div>
              ) : (
                <div className="min-h-0 flex-1 space-y-3 overflow-y-auto pr-1">
                  <div className="flex items-center gap-4">
                    <div className="text-4xl font-bold text-primary-400">{Math.round(evaluation.matchScore)}</div>
                    <div className="text-xs leading-relaxed text-slate-300">{evaluation.verdict}</div>
                  </div>
                  <div className="space-y-1.5">
                    {evaluation.dimensions.map((d) => (
                      <div key={d.name} className="flex items-center gap-2">
                        <span className="w-16 shrink-0 text-[11px] text-slate-400">{d.name}</span>
                        <div className="h-1.5 flex-1 overflow-hidden rounded-full bg-slate-800">
                          <div
                            className="h-full rounded-full bg-gradient-to-r from-primary-500 to-accent-500"
                            style={{ width: `${d.score}%` }}
                          />
                        </div>
                        <span className="w-7 text-right text-[11px] text-slate-300">{d.score}</span>
                        <span className="min-w-0 flex-1 truncate text-[11px] text-slate-500" title={d.comment}>
                          {d.comment}
                        </span>
                      </div>
                    ))}
                  </div>
                  {evaluation.missingKeywords.length > 0 && (
                    <div>
                      <span className="text-[11px] text-slate-400">缺失关键词:</span>{' '}
                      {evaluation.missingKeywords.map((k) => (
                        <span
                          key={k}
                          className="mb-1 mr-1.5 inline-block rounded bg-amber-500/10 px-2 py-0.5 text-[11px] text-amber-400"
                        >
                          {k}
                        </span>
                      ))}
                    </div>
                  )}
                  {evaluation.risks.length > 0 && (
                    <div>
                      <span className="text-[11px] text-slate-400">风险点:</span>
                      <ul className="mt-1 space-y-0.5 text-[11px] text-slate-400">
                        {evaluation.risks.map((r) => (
                          <li key={r}>· {r}</li>
                        ))}
                      </ul>
                    </div>
                  )}
                </div>
              )}
            </StationCard>

            <FlowArrow active={evalCtx !== ''} />

            {/* ③ 加工台 */}
            <StationCard
              no="③"
              title="加工台 · 岗位定制"
              sub="按②的质检报告精修简历:总结重写、bullet 改写、关键词嵌入,产出定制版"
              status={st3}
            >
              <div className="flex flex-wrap gap-2 text-[11px]">
                <span
                  className={`rounded-full px-2.5 py-1 ${
                    resumeText.trim() ? 'bg-emerald-500/10 text-emerald-400' : 'bg-slate-800 text-slate-500'
                  }`}
                >
                  ① 简历原料 {resumeText.trim() ? '✓' : '待投放'}
                </span>
                <span
                  className={`rounded-full px-2.5 py-1 ${
                    jdText.trim() ? 'bg-emerald-500/10 text-emerald-400' : 'bg-slate-800 text-slate-500'
                  }`}
                >
                  ② 岗位 JD {jdText.trim() ? '✓' : '待填写'}
                </span>
                <span
                  className={`rounded-full px-2.5 py-1 ${
                    evalCtx !== '' ? 'bg-emerald-500/10 text-emerald-400' : 'bg-slate-800 text-slate-500'
                  }`}
                >
                  ② 质检报告 {evalCtx !== '' ? '✓ 已注入' : '未生成(也可直接加工)'}
                </span>
              </div>
              <button className="btn btn-primary w-fit text-sm" disabled={busy !== null} onClick={runTailorStation}>
                {busy === 'tailor' ? '定制中…' : '▶ 开始定制'}
              </button>
              {tailoring === null ? (
                <div className="flex flex-1 flex-col items-center justify-center rounded-lg border border-dashed border-slate-700/60 px-4 py-8 text-center">
                  <span className="text-2xl opacity-60">🛠️</span>
                  <p className="mt-2 text-xs text-slate-400">定制产出 · 待生成</p>
                  <p className="mt-1 text-[11px] leading-relaxed text-slate-600">
                    将产出:总结重写 / 经历条目改写 / 建议嵌入关键词
                  </p>
                </div>
              ) : (
                <div className="min-h-0 flex-1 space-y-3 overflow-y-auto pr-1">
                  <div className="rounded-lg border border-primary-500/15 bg-primary-500/5 p-3 text-xs leading-relaxed text-slate-300">
                    <span className="font-medium text-primary-400">总结重写:</span> {tailoring.summarySuggestion}
                  </div>
                  <div className="space-y-2">
                    {tailoring.bulletSuggestions.map((b, i) => (
                      <div key={i} className="rounded-lg border border-slate-700/50 bg-slate-900/40 p-2.5">
                        <div className="mb-1 text-[11px] text-slate-500">
                          {b.section} · 修改理由:{b.reason}
                        </div>
                        <div className="text-[11px] text-slate-500 line-through">{b.original}</div>
                        <div className="mt-1 text-xs text-slate-200">{b.improved}</div>
                      </div>
                    ))}
                  </div>
                  {tailoring.keywordsToEmbed.length > 0 && (
                    <div>
                      <span className="text-[11px] text-slate-400">建议嵌入关键词:</span>{' '}
                      {tailoring.keywordsToEmbed.map((k) => (
                        <span
                          key={k}
                          className="mb-1 mr-1.5 inline-block rounded bg-emerald-500/10 px-2 py-0.5 text-[11px] text-emerald-400"
                        >
                          {k}
                        </span>
                      ))}
                    </div>
                  )}
                </div>
              )}
            </StationCard>
          </div>

          {/* Agent 运行时间线 */}
          {events.length > 0 && (
            <div className="card-glass mt-6 rounded-2xl p-5">
              <h2 className="mb-3 text-sm font-semibold text-white">Agent 运行时间线</h2>
              <div className="grid gap-x-6 gap-y-1.5 font-mono text-xs md:grid-cols-2">
                {events.map((e, i) => (
                  <div key={i} className="flex items-center gap-2">
                    <span
                      className={`h-1.5 w-1.5 shrink-0 rounded-full ${
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
                    <span className="truncate text-slate-500">
                      {e.status === 'running' ? '执行中' : e.status}
                      {e.detail ? ` · ${e.detail.slice(0, 80)}` : ''}
                    </span>
                  </div>
                ))}
              </div>
            </div>
          )}

          {/* 校准台:投递回流自进化飞轮 */}
          <div className="mt-6">
            <ApplicationsPanel key={appsVersion} />
          </div>
        </div>
      </div>
    </PublicLayout>
  );
}
