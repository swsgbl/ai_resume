import { useState } from 'react';
import { Link } from 'react-router-dom';
import { api } from '@ai-resume/shared';
import type { ResumeContent } from '@ai-resume/shared/types';
import { fromJsonResume } from '@ai-resume/shared/schema';
import { SEO } from '../components/SEO';
import { GradientText, Orb } from '../components/UIComponents';
import { ResumePreview } from '../components/ResumePreview';
import { loadModelConfig, runAgent, type AgentRunEvent } from '../agent/runner';
import { extractAgent } from '../agent/agents';
import { isRouteReady } from '../agent/providers';
import { jsonResumeSchema } from '@ai-resume/shared/schema';

/**
 * 智能简历生成 — /resumes/new 的一条龙体验(复杂留给后台,简单留给用户)
 * 输入端:一个框(粘贴旧简历/经历自述/口述碎片)
 * 生成端:AI 结构化(多厂商路由) → 完整简历实时预览
 * 输出端:保存到我的简历 → PDF/Word 一键下载 → 高级编辑/质检定制入口
 */

const EXAMPLE = `张伟,5年后端工程师(杭州),邮箱 zhangwei@mail.com,手机 13800001111。
阿里巴巴 2021.07-至今 高级后端工程师:主导订单系统微服务化,QPS 从 2k 提升到 15k,带领 4 人小组,年节省服务器成本 80 万。
蚂蚁集团 2019.07-2021.06 后端工程师:设计支付网关,日均处理 500 万笔交易,故障率下降 60%。
浙江大学 2015-2019 计算机科学与技术 本科 GPA 3.7。
技能:Java/Spring Cloud/MySQL/Redis/Kafka/K8s。有 PMP 认证。`;

type Phase = 'input' | 'generating' | 'preview';

export default function SmartResumeCreate() {
  const [experienceText, setExperienceText] = useState('');
  const [targetPosition, setTargetPosition] = useState('');
  const [resumeTitle, setResumeTitle] = useState('');
  const [content, setContent] = useState<ResumeContent | null>(null);
  const [template, setTemplate] = useState<'modern' | 'classic' | 'minimal'>('modern');
  const [phase, setPhase] = useState<Phase>('input');
  const [error, setError] = useState('');
  const [savedResumeId, setSavedResumeId] = useState<number | null>(null);
  const [saving, setSaving] = useState(false);
  const [savedMsg, setSavedMsg] = useState('');

  const routeReady = isRouteReady();
  const canGenerate = experienceText.trim().length >= 20 && routeReady && phase !== 'generating';

  const handleGenerate = async () => {
    const config = loadModelConfig();
    if (!config || !config.apiKey) {
      setError('还没有配置 AI 模型:点右上角去设置页,两分钟完成配置。');
      return;
    }
    if (experienceText.trim().length < 20) {
      setError('请至少粘贴 20 字的经历内容(旧简历、领英档案、或想到什么写什么都可以)。');
      return;
    }
    setPhase('generating');
    setError('');
    try {
      const input = targetPosition.trim()
        ? `${experienceText}\n\n【目标岗位】${targetPosition.trim()}(生成时向该岗位靠拢)`
        : experienceText;
      const events: AgentRunEvent[] = [];
      const jsonResume = await runAgent(extractAgent, config, input, {
        onEvent: (e) => {
          events.push(e);
          if (e.status === 'retry') setError(`AI 输出自检中:${e.detail?.slice(0, 60) ?? ''}`);
        },
      });
      const validated = jsonResumeSchema.passthrough().parse(jsonResume);
      const resumeContent = fromJsonResume(validated);
      if (!resumeContent.basic_info?.name && !resumeContent.work_experience?.length) {
        throw new Error('AI 未能从文本中提取到有效内容,请补充更多经历细节后重试。');
      }
      setContent(resumeContent);
      setResumeTitle(`${resumeContent.basic_info?.name ?? '我的'}的简历`);
      setPhase('preview');
      setError('');
    } catch (e) {
      setPhase('input');
      setError(e instanceof Error ? e.message : String(e));
    }
  };

  const handleSave = async () => {
    if (!content) return;
    setSaving(true);
    setSavedMsg('');
    try {
      const resume = await api.resume.createResume({
        title: resumeTitle.trim() || '我的简历',
        content,
      });
      setSavedResumeId(resume.id);
      setSavedMsg('已保存到「我的简历」');
    } catch (e) {
      setSavedMsg(e instanceof Error ? e.message : '保存失败,请重试');
    } finally {
      setSaving(false);
    }
  };

  return (
    <>
      <SEO title="智能简历生成" description="粘贴你的经历,AI 一键生成完整简历,在线预览并下载 PDF/Word。" noIndex />
      <div className="min-h-screen relative overflow-x-hidden bg-slate-950">
        <div className="fixed inset-0 pointer-events-none overflow-hidden">
          <Orb color="primary" size={200} className="top-0 left-0 -translate-x-1/2 -translate-y-1/2 opacity-20" />
          <Orb color="accent" size={150} className="bottom-0 right-0 translate-x-1/2 translate-y-1/2 opacity-10" />
        </div>
        <div className="fixed inset-0 bg-grid pointer-events-none opacity-5" />

        <main className="relative z-10 mx-auto w-full max-w-7xl px-4 pb-16 pt-10">
          {/* 页头 */}
          <header className="mb-6">
            <h1 className="text-3xl font-bold">
              <GradientText>AI 智能简历生成</GradientText>
            </h1>
            <p className="mt-2 text-sm text-slate-400">
              把你的经历粘贴进来,剩下的交给 AI:自动整理成完整简历,在线预览,一键下载
            </p>
          </header>

          <div className="grid gap-6 lg:grid-cols-[420px_1fr]">
            {/* 左:输入面板 */}
            <div className="space-y-4">
              <section className="card-glass rounded-2xl p-5" data-testid="input-panel">
                <div className="mb-3 flex items-center justify-between">
                  <h2 className="text-sm font-semibold text-white">① 你的经历</h2>
                  <button
                    className="text-[11px] text-primary-400 hover:text-primary-300"
                    onClick={() => setExperienceText(EXAMPLE)}
                  >
                    填入示例看看效果
                  </button>
                </div>
                <textarea
                  className="input min-h-[240px] text-xs leading-relaxed"
                  placeholder={'想到什么写什么,都行:\n· 直接粘贴你的旧简历 / 领英档案\n· 一段话口述工作经历\n· 零散列出做过的事\n\nAI 会自动整理成规范简历。'}
                  value={experienceText}
                  onChange={(e) => setExperienceText(e.target.value)}
                  data-testid="experience-input"
                />
                <label className="mb-1.5 mt-3 block text-xs font-medium text-slate-300" htmlFor="target-position-input">
                  ② 目标岗位 <span className="text-slate-500">(可选,填写后 AI 向该岗位靠拢)</span>
                </label>
                <input
                  id="target-position-input"
                  className="input text-xs"
                  placeholder="如:Java 高级后端工程师"
                  value={targetPosition}
                  onChange={(e) => setTargetPosition(e.target.value)}
                  data-testid="target-position-input"
                />
                <button
                  className="btn btn-primary mt-4 w-full py-3"
                  disabled={!canGenerate}
                  onClick={handleGenerate}
                  data-testid="generate-button"
                >
                  {phase === 'generating' ? '✨ AI 正在生成…(约 10-30 秒)' : '✨ 一键生成完整简历'}
                </button>
                {!routeReady && phase === 'input' && (
                  <div className="mt-3 rounded-lg border border-amber-500/30 bg-amber-500/10 p-3 text-xs leading-relaxed text-amber-300">
                    首次使用需要配置一个 AI 模型(约 2 分钟,选厂商 → 粘贴密钥 → 保存):
                    <Link to="/settings" className="ml-1 underline hover:no-underline" data-testid="goto-settings-link">
                      去设置页配置 →
                    </Link>
                  </div>
                )}
                {error && <p className="mt-3 text-xs leading-relaxed text-rose-400" data-testid="generate-error">{error}</p>}
              </section>

              {/* 输出面板:保存与下载(生成后出现) */}
              {content && (
                <section className="card-glass rounded-2xl p-5" data-testid="output-panel">
                  <h2 className="mb-3 text-sm font-semibold text-white">③ 保存与下载</h2>
                  <label className="mb-1.5 block text-xs font-medium text-slate-300" htmlFor="resume-title-input">
                    简历名称
                  </label>
                  <input
                    id="resume-title-input"
                    className="input mb-3 text-xs"
                    value={resumeTitle}
                    onChange={(e) => setResumeTitle(e.target.value)}
                    data-testid="resume-title-input"
                  />
                  <div className="space-y-2">
                    <button
                      className="btn btn-primary w-full text-sm"
                      disabled={saving || !!savedResumeId}
                      onClick={handleSave}
                      data-testid="save-resume-button"
                    >
                      {savedResumeId ? '✓ 已保存到我的简历' : saving ? '保存中…' : '保存到我的简历'}
                    </button>
                    {savedResumeId !== null && (
                      <>
                        <div className="grid grid-cols-2 gap-2">
                          <a
                            className="btn btn-secondary text-center text-sm"
                            href={api.resume.getPdfExportUrl(savedResumeId)}
                            target="_blank"
                            rel="noopener noreferrer"
                            data-testid="download-pdf-link"
                          >
                            📄 下载 PDF
                          </a>
                          <a
                            className="btn btn-secondary text-center text-sm"
                            href={api.resume.getWordExportUrl(savedResumeId)}
                            target="_blank"
                            rel="noopener noreferrer"
                            data-testid="download-word-link"
                          >
                            📝 下载 Word
                          </a>
                        </div>
                        <div className="grid grid-cols-2 gap-2 text-xs">
                          <Link className="btn btn-accent text-center text-sm" to={`/resumes/${savedResumeId}`}>
                            ✏️ 高级编辑
                          </Link>
                          <Link className="btn btn-accent text-center text-sm" to="/os">
                            🎯 质检与岗位定制
                          </Link>
                        </div>
                        <p className="text-[11px] leading-relaxed text-slate-500">
                          提示:PDF/Word 由服务器按已保存版本导出;修改内容后请回「我的简历」重新导出。
                        </p>
                      </>
                    )}
                    {savedMsg && savedResumeId === null && (
                      <p className="text-xs text-rose-400">{savedMsg}</p>
                    )}
                  </div>
                </section>
              )}
            </div>

            {/* 右:完整简历实时预览 */}
            <section className="card-glass rounded-2xl p-5" data-testid="preview-panel">
              <div className="mb-3 flex items-center justify-between">
                <h2 className="text-sm font-semibold text-white">完整简历预览</h2>
                {content && (
                  <div className="flex gap-1.5">
                    {(['modern', 'classic', 'minimal'] as const).map((t) => (
                      <button
                        key={t}
                        onClick={() => setTemplate(t)}
                        className={`rounded-md px-2.5 py-1 text-[11px] transition-colors ${
                          template === t
                            ? 'bg-primary-500/15 text-primary-300'
                            : 'text-slate-500 hover:text-slate-300'
                        }`}
                      >
                        {{ modern: '现代', classic: '经典', minimal: '简约' }[t]}
                      </button>
                    ))}
                  </div>
                )}
              </div>
              {content ? (
                <div className="max-h-[75vh] overflow-y-auto rounded-xl" data-testid="resume-preview">
                  <ResumePreview content={content} template={template} />
                </div>
              ) : (
                <div
                  className="flex min-h-[420px] flex-col items-center justify-center rounded-xl border border-dashed border-slate-700/60 px-6 text-center"
                  data-testid="preview-empty"
                >
                  <span className="text-3xl opacity-60">{phase === 'generating' ? '✨' : '📄'}</span>
                  <p className="mt-3 text-sm text-slate-300">
                    {phase === 'generating' ? 'AI 正在整理你的经历…' : '生成的完整简历会出现在这里'}
                  </p>
                  <p className="mt-2 max-w-xs text-[11px] leading-relaxed text-slate-600">
                    {phase === 'generating'
                      ? '正在提取基本信息、工作经历、教育背景、技能证书并生成规范排版'
                      : '左侧粘贴一段经历描述,点「一键生成」,无需逐项填表'}
                  </p>
                </div>
              )}
            </section>
          </div>
        </main>
      </div>
    </>
  );
}
