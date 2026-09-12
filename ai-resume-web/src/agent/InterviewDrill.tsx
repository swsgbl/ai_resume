import { useState } from 'react';
import { loadModelConfig, runAgent, type AgentRunEvent } from './runner';
import {
  storyExtractAgent,
  questionGenAgent,
  answerScoreAgent,
  type StoryExtractResult,
  type QuestionGenResult,
  type AnswerScoreResult,
} from './agents';
import { loadStories, saveStory, removeStory, type InterviewStory } from './stories';

/**
 * 演练场 · 面试备战 — 车间产出简历之后的第四站
 * 故事库(STAR) → 定向模拟面试题 → 五维答案批改,方法论源自 interview-coach-skill。
 * 与车间共享:简历原料(resumeText)、岗位 JD(jdText)、本机模型配置。
 */

interface Props {
  resumeText: string;
  jdText: string;
  onEvent?: (e: AgentRunEvent) => void;
}

const DIMENSION_HINTS: Record<string, string> = {
  具体性: '有事实、数字、细节',
  结构: 'STAR 叙事清晰',
  相关性: '紧扣问题意图',
  可信度: '细节可验证',
  差异化: '有独特亮点',
};

export default function InterviewDrill({ resumeText, jdText, onEvent }: Props) {
  const [storiesVersion, setStoriesVersion] = useState(0);
  const [expandedStory, setExpandedStory] = useState<string | null>(null);
  const [questions, setQuestions] = useState<QuestionGenResult['questions']>([]);
  const [currentQ, setCurrentQ] = useState(0);
  const [answers, setAnswers] = useState<Record<number, string>>({});
  const [scores, setScores] = useState<Record<number, AnswerScoreResult>>({});
  const [busy, setBusy] = useState<'story' | 'questions' | 'score' | null>(null);
  const [error, setError] = useState('');

  const stories: InterviewStory[] = loadStories();

  const requireConfig = () => {
    const cfg = loadModelConfig();
    if (!cfg || !cfg.apiKey) {
      setError('请先在右上角「⚙ 模型」配置 API Key(仅存本机)。');
      return null;
    }
    return cfg;
  };

  /** 从简历原料提炼 STAR 故事库 */
  const runStoryExtract = async () => {
    const cfg = requireConfig();
    if (!cfg) return;
    if (resumeText.trim().length < 20) {
      setError('故事库需要 ① 原料台的简历文本(至少 20 字)。');
      return;
    }
    setBusy('story');
    setError('');
    try {
      const result = await runAgent(storyExtractAgent, cfg, resumeText, { onEvent });
      const extracted: StoryExtractResult = result;
      extracted.stories.forEach((s) =>
        saveStory({
          title: s.title,
          situation: s.situation,
          task: s.task,
          action: s.action,
          result: s.result,
          tags: s.tags,
        })
      );
      setStoriesVersion((v) => v + 1);
    } catch (e) {
      setError(e instanceof Error ? e.message : String(e));
    } finally {
      setBusy(null);
    }
  };

  /** 生成定向面试题(带故事库上下文) */
  const runQuestionGen = async () => {
    const cfg = requireConfig();
    if (!cfg) return;
    if (!resumeText.trim() || !jdText.trim()) {
      setError('生成面试题需要 ① 的简历原料与 ② 的岗位 JD。');
      return;
    }
    setBusy('questions');
    setError('');
    try {
      const storyCtx = stories.length
        ? `\n\n候选人的故事库(作答素材,标题→标签):\n${stories
            .map((s) => `- ${s.title} → ${s.tags.join('/')}`)
            .join('\n')}`
        : '';
      const input = `候选人简历:\n${resumeText}\n\n目标岗位 JD:\n${jdText}${storyCtx}`;
      const result = await runAgent(questionGenAgent, cfg, input, { onEvent });
      setQuestions((result as QuestionGenResult).questions);
      setCurrentQ(0);
      setAnswers({});
      setScores({});
    } catch (e) {
      setError(e instanceof Error ? e.message : String(e));
    } finally {
      setBusy(null);
    }
  };

  /** 五维批改当前答案 */
  const runScore = async () => {
    const cfg = requireConfig();
    if (!cfg) return;
    const q = questions[currentQ];
    const answer = (answers[currentQ] || '').trim();
    if (!q || answer.length < 10) {
      setError('请先写下答案(至少 10 字)再批改。');
      return;
    }
    setBusy('score');
    setError('');
    try {
      const input = `面试问题(${q.type}):\n${q.question}\n\n候选人答案:\n${answer}\n\n候选人简历背景:\n${resumeText.slice(0, 1500)}`;
      const result = await runAgent(answerScoreAgent, cfg, input, { onEvent });
      setScores((prev) => ({ ...prev, [currentQ]: result as AnswerScoreResult }));
    } catch (e) {
      setError(e instanceof Error ? e.message : String(e));
    } finally {
      setBusy(null);
    }
  };

  const storyVersion = `story-v${storiesVersion}`;
  const q = questions[currentQ];
  const score = scores[currentQ];
  const answeredCount = Object.keys(answers).filter((k) => (answers[+k] || '').trim()).length;

  return (
    <section className="os-station card-glass rounded-2xl p-5" data-story-version={storyVersion}>
      <header className="mb-4 flex flex-wrap items-start justify-between gap-3">
        <div className="min-w-0">
          <div className="flex items-center gap-2.5">
            <span className="flex h-8 w-8 shrink-0 items-center justify-center rounded-lg border border-accent-500/30 bg-accent-500/10 text-sm font-bold text-accent-500">
              ④
            </span>
            <h2 className="text-base font-semibold text-white">演练场 · 面试备战</h2>
          </div>
          <p className="mt-1.5 text-xs leading-relaxed text-slate-500">
            简历只是入场券,面试才定胜负:提炼你的 STAR 故事库,按目标岗位出题,逐题五维批改
          </p>
        </div>
        <div className="flex flex-wrap items-center gap-2">
          <button
            className="btn btn-secondary text-sm"
            disabled={busy !== null}
            onClick={runStoryExtract}
            title="从 ① 原料台的简历文本提炼 STAR 故事,带能力标签"
          >
            {busy === 'story' ? '提炼中…' : '📖 提炼故事库'}
          </button>
          <button
            className="btn btn-primary text-sm"
            disabled={busy !== null}
            onClick={runQuestionGen}
            title="按目标 JD 生成 5 道最可能被问到的题,并建议用哪个故事作答"
          >
            {busy === 'questions' ? '出题中…' : '🎯 生成面试题'}
          </button>
        </div>
      </header>

      {(busy !== null || error !== '') && (
        <div className="mb-4 flex items-center gap-3 text-xs">
          {busy !== null && (
            <span className="flex items-center gap-2 rounded-full bg-primary-500/10 px-3 py-1.5 text-primary-400">
              <span className="h-1.5 w-1.5 animate-pulse rounded-full bg-primary-400" />
              {busy === 'story' ? '故事提炼中…' : busy === 'questions' ? '面试官出题中…' : '教练批改中…'}
            </span>
          )}
          {error !== '' && (
            <span className="rounded-full bg-rose-500/10 px-3 py-1.5 text-rose-400">{error}</span>
          )}
        </div>
      )}

      <div className="grid gap-4 xl:grid-cols-[340px_1fr]">
        {/* 左:故事库 */}
        <div className="min-w-0">
          <div className="mb-2 flex items-center justify-between text-xs">
            <span className="font-medium text-slate-300">我的故事库</span>
            <span className="text-slate-500">{stories.length} 个 · 仅存本机</span>
          </div>
          {stories.length === 0 ? (
            <div className="flex flex-col items-center justify-center rounded-lg border border-dashed border-slate-700/60 px-4 py-8 text-center">
              <span className="text-2xl opacity-60">📖</span>
              <p className="mt-2 text-xs text-slate-400">故事库还是空的</p>
              <p className="mt-1 text-[11px] leading-relaxed text-slate-600">
                点击「提炼故事库」,AI 从简历中找出你最强的 3-6 个 STAR 故事
              </p>
            </div>
          ) : (
            <div className="flex flex-row flex-wrap gap-2 xl:max-h-[420px] xl:flex-col xl:flex-nowrap xl:overflow-y-auto xl:pr-1">
              {stories.map((s) => (
                <div key={s.id} className="w-fit xl:w-full">
                  <button
                    onClick={() => setExpandedStory(expandedStory === s.id ? null : s.id)}
                    className={`w-full rounded-lg border px-3 py-2 text-left transition-colors ${
                      expandedStory === s.id
                        ? 'border-accent-500/40 bg-accent-500/5'
                        : 'border-slate-700/60 bg-slate-900/40 hover:border-slate-500'
                    }`}
                  >
                    <span className="block truncate text-xs font-medium text-slate-200">{s.title}</span>
                    <span className="mt-1 block truncate text-[11px] text-slate-500">{s.tags.join(' · ')}</span>
                  </button>
                  {expandedStory === s.id && (
                    <div className="mt-1 space-y-1.5 rounded-lg border border-slate-800 bg-slate-900/60 p-3 text-[11px] leading-relaxed">
                      <p className="text-slate-400">
                        <span className="text-slate-500">S:</span> {s.situation}
                      </p>
                      <p className="text-slate-400">
                        <span className="text-slate-500">T:</span> {s.task}
                      </p>
                      <p className="text-slate-300">
                        <span className="text-slate-500">A:</span> {s.action}
                      </p>
                      <p className="text-slate-300">
                        <span className="text-slate-500">R:</span> {s.result}
                      </p>
                      <button
                        className="mt-1 text-[11px] text-rose-400/80 hover:text-rose-400"
                        onClick={() => {
                          removeStory(s.id);
                          setStoriesVersion((v) => v + 1);
                        }}
                      >
                        删除这个故事
                      </button>
                    </div>
                  )}
                </div>
              ))}
            </div>
          )}
        </div>

        {/* 右:模拟面试问答 */}
        <div className="min-w-0">
          {questions.length === 0 ? (
            <div className="flex h-full min-h-[200px] flex-col items-center justify-center rounded-lg border border-dashed border-slate-700/60 px-4 py-8 text-center">
              <span className="text-2xl opacity-60">🎯</span>
              <p className="mt-2 text-xs text-slate-400">模拟面试 · 待开始</p>
              <p className="mt-1 text-[11px] leading-relaxed text-slate-600">
                需要 ① 简历原料 + ② 岗位 JD;有故事库时,每题会建议你用哪个故事作答
              </p>
            </div>
          ) : (
            <div className="space-y-3">
              {/* 题目导航 */}
              <div className="flex items-center justify-between gap-2">
                <div className="flex items-center gap-1.5">
                  {questions.map((_, i) => (
                    <button
                      key={i}
                      onClick={() => setCurrentQ(i)}
                      className={`h-1.5 rounded-full transition-all ${
                        i === currentQ
                          ? 'w-6 bg-primary-400'
                          : (answers[i] || '').trim()
                            ? 'w-1.5 bg-emerald-400/70'
                            : 'w-1.5 bg-slate-700 hover:bg-slate-500'
                      }`}
                      aria-label={`第 ${i + 1} 题`}
                    />
                  ))}
                  <span className="ml-2 text-[11px] text-slate-500">
                    已作答 {answeredCount}/{questions.length}
                  </span>
                </div>
                <span className="rounded-full bg-slate-800 px-2.5 py-1 text-[11px] text-slate-400">
                  {q.type}
                </span>
              </div>

              {/* 题目 */}
              <div className="rounded-lg border border-slate-700/50 bg-slate-900/50 p-4">
                <p className="text-sm font-medium leading-relaxed text-slate-100">{q.question}</p>
                {q.suggestedStory && (
                  <p className="mt-2 text-[11px] text-accent-500/90">
                    💡 教练建议:用「{q.suggestedStory}」这个故事作答
                  </p>
                )}
              </div>

              {/* 作答 */}
              <textarea
                className="input min-h-[130px] text-xs"
                placeholder="像真实面试一样口述你的答案,再粘贴进来…(建议用 STAR 结构:背景→任务→行动→结果)"
                value={answers[currentQ] || ''}
                onChange={(e) => setAnswers((prev) => ({ ...prev, [currentQ]: e.target.value }))}
              />

              <div className="flex flex-wrap items-center gap-2">
                <button className="btn btn-primary text-sm" disabled={busy !== null} onClick={runScore}>
                  {busy === 'score' ? '批改中…' : '✍️ 五维批改'}
                </button>
                <div className="flex gap-2">
                  <button
                    className="btn btn-secondary text-sm"
                    disabled={currentQ === 0}
                    onClick={() => setCurrentQ((i) => i - 1)}
                  >
                    上一题
                  </button>
                  <button
                    className="btn btn-secondary text-sm"
                    disabled={currentQ >= questions.length - 1}
                    onClick={() => setCurrentQ((i) => i + 1)}
                  >
                    下一题
                  </button>
                </div>
              </div>

              {/* 批改结果 */}
              {score && (
                <div className="space-y-3 rounded-lg border border-accent-500/20 bg-accent-500/5 p-4">
                  <div className="flex items-center gap-4">
                    <div className="text-3xl font-bold text-accent-500">{Math.round(score.overall)}</div>
                    <div className="text-[11px] leading-relaxed text-slate-400">
                      五维:具体性 / 结构 / 相关性 / 可信度 / 差异化
                      <br />
                      相关性权重最高——先答到点子上,再堆细节
                    </div>
                  </div>
                  <div className="space-y-1.5">
                    {score.dimensions.map((d) => (
                      <div key={d.name} className="flex items-center gap-2">
                        <span
                          className="w-14 shrink-0 text-[11px] text-slate-300"
                          title={DIMENSION_HINTS[d.name] || ''}
                        >
                          {d.name}
                        </span>
                        <div className="h-1.5 flex-1 overflow-hidden rounded-full bg-slate-800">
                          <div
                            className={`h-full rounded-full ${
                              d.score >= 70
                                ? 'bg-gradient-to-r from-primary-500 to-accent-500'
                                : 'bg-gradient-to-r from-amber-500 to-rose-400'
                            }`}
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
                  <div className="rounded-lg border border-slate-700/50 bg-slate-900/60 p-3">
                    <p className="mb-1 text-[11px] font-medium text-primary-400">✨ 教练改写示范(保留你的事实,仅优化表达):</p>
                    <p className="text-xs leading-relaxed text-slate-300">{score.improved}</p>
                  </div>
                </div>
              )}
            </div>
          )}
        </div>
      </div>
    </section>
  );
}
