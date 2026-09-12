import { useState, useEffect } from 'react';
import { Link } from 'react-router-dom';
import { storage } from '@ai-resume/shared';
import { getApiClient } from '@ai-resume/shared/api';
import { SEO } from '../components/SEO';
import { GradientText, Orb } from '../components/UIComponents';
import ModelConfigCard from '../agent/ModelConfigCard';

const DEFAULT_BASE_URL = '/api/v1';

/**
 * 设置页 — 全站 hm 设计系统
 * ① AI 模型(多厂商路由,唯一活跃的 AI 配置) ② 服务器地址(高级) ③ 数据与隐私
 * 旧版「AI 提供商配置」(openai/deepseek/xiaomi 三份 Key)无任何消费方,已移除。
 */
export default function SettingsPage() {
  const [baseUrl, setBaseUrl] = useState(DEFAULT_BASE_URL);
  const [savedUrl, setSavedUrl] = useState(DEFAULT_BASE_URL);
  const [saving, setSaving] = useState(false);
  const [urlMsg, setUrlMsg] = useState<{ ok: boolean; text: string } | null>(null);

  useEffect(() => {
    const current = storage.getBaseURL();
    setBaseUrl(current);
    setSavedUrl(current);
  }, []);

  const urlDirty = baseUrl.trim() !== savedUrl;

  const handleSaveUrl = async () => {
    setSaving(true);
    setUrlMsg(null);
    const next = baseUrl.trim();
    // 允许同域相对路径或完整 http(s) 地址
    const isRelative = next.startsWith('/') && !next.startsWith('//');
    let hostValid = false;
    try {
      new URL(next);
      hostValid = true;
    } catch {
      hostValid = false;
    }
    if (!next || (!isRelative && !hostValid)) {
      setUrlMsg({ ok: false, text: '地址格式不对:请以 / 开头(同域)或输入完整 http(s) 地址' });
      setSaving(false);
      return;
    }
    try {
      storage.setBaseURL(next);
      getApiClient().setBaseURL(next);
      setSavedUrl(next);
      setBaseUrl(next);
      setUrlMsg({ ok: true, text: '已保存,立即生效' });
    } catch {
      setUrlMsg({ ok: false, text: '保存失败,请重试' });
    } finally {
      setSaving(false);
    }
  };

  const handleResetUrl = () => {
    storage.setBaseURL(DEFAULT_BASE_URL);
    getApiClient().setBaseURL(DEFAULT_BASE_URL);
    setBaseUrl(DEFAULT_BASE_URL);
    setSavedUrl(DEFAULT_BASE_URL);
    setUrlMsg({ ok: true, text: '已恢复默认地址' });
  };

  const handleClearAll = () => {
    if (!confirm('确定清除本机保存的全部配置吗?模型密钥、服务器地址等将被删除,此操作不可撤销。')) return;
    storage.clearAll();
    window.location.reload();
  };

  return (
    <>
      <SEO title="设置" description="管理 AI 模型多厂商路由与服务器地址,数据仅存本机。" noIndex />
      <div className="min-h-screen relative overflow-x-hidden bg-slate-950">
        <div className="fixed inset-0 pointer-events-none overflow-hidden">
          <Orb color="primary" size={200} className="top-0 left-0 -translate-x-1/2 -translate-y-1/2 opacity-20" />
          <Orb color="accent" size={150} className="bottom-0 right-0 translate-x-1/2 translate-y-1/2 opacity-10" />
        </div>
        <div className="fixed inset-0 bg-grid pointer-events-none opacity-5" />

        <main className="relative z-10 mx-auto w-full max-w-3xl px-4 pb-20 pt-10">
          {/* 页头 */}
          <header className="mb-8">
            <h1 className="text-3xl font-bold">
              <GradientText>设置</GradientText>
            </h1>
            <p className="mt-2 text-sm text-slate-400">
              所有配置仅保存在这台设备的浏览器里,不会上传服务器
            </p>
          </header>

          {/* ① AI 模型 — 多厂商路由 */}
          <section className="card-glass mb-5 rounded-2xl p-6" data-testid="section-models">
            <div className="mb-4 flex flex-wrap items-center justify-between gap-3">
              <div>
                <h2 className="flex items-center gap-2 text-base font-semibold text-white">
                  <span className="flex h-8 w-8 items-center justify-center rounded-lg border border-primary-400/30 bg-primary-500/10 text-sm">
                    🤖
                  </span>
                  AI 模型 · 多厂商路由
                </h2>
                <p className="mt-1.5 text-xs leading-relaxed text-slate-500">
                  「简历生成车间」与演练场使用的 AI;可接入多家,⭐ 切换默认路由
                </p>
              </div>
              <Link
                to="/os"
                className="rounded-lg border border-slate-700 px-3 py-1.5 text-xs text-slate-400 transition-colors hover:border-primary-400/40 hover:text-primary-300"
              >
                去车间使用 →
              </Link>
            </div>
            <ModelConfigCard />
          </section>

          {/* ② 服务器地址 — 高级 */}
          <section className="card-glass mb-5 rounded-2xl p-6" data-testid="section-server">
            <div className="mb-4 flex items-center gap-2">
              <span className="flex h-8 w-8 items-center justify-center rounded-lg border border-slate-700 bg-slate-900/60 text-sm">
                🌐
              </span>
              <div>
                <h2 className="text-base font-semibold text-white">服务器地址</h2>
                <p className="mt-0.5 text-xs text-slate-500">高级选项 · 已有默认值,一般不用改</p>
              </div>
              {savedUrl === DEFAULT_BASE_URL ? (
                <span className="ml-auto rounded-full bg-slate-800 px-2.5 py-1 text-[11px] text-slate-400">默认</span>
              ) : (
                <span className="ml-auto rounded-full bg-amber-500/10 px-2.5 py-1 text-[11px] text-amber-400">自定义</span>
              )}
            </div>

            <label className="mb-1.5 block text-xs font-medium text-slate-300" htmlFor="server-url-input">
              后端 API 地址
            </label>
            <div className="flex flex-wrap gap-2">
              <input
                id="server-url-input"
                type="text"
                value={baseUrl}
                onChange={(e) => {
                  setBaseUrl(e.target.value);
                  setUrlMsg(null);
                }}
                placeholder="/api/v1 或 https://your-server.com/api/v1"
                className="input min-w-0 flex-1 font-mono text-xs"
                data-testid="server-url-input"
              />
              <button
                className="btn btn-primary text-sm"
                onClick={handleSaveUrl}
                disabled={saving || !urlDirty}
                data-testid="save-url-button"
              >
                {saving ? '保存中…' : '保存'}
              </button>
              {savedUrl !== DEFAULT_BASE_URL && (
                <button className="btn btn-secondary text-sm" onClick={handleResetUrl} data-testid="reset-url-button">
                  恢复默认
                </button>
              )}
            </div>
            {urlDirty && !urlMsg?.ok && <p className="mt-2 text-xs text-amber-400/90">有未保存的修改</p>}
            {urlMsg && (
              <p
                className={`mt-2 text-xs ${urlMsg.ok ? 'text-emerald-400' : 'text-rose-400'}`}
                data-testid="url-message"
              >
                {urlMsg.text}
              </p>
            )}
          </section>

          {/* ③ 数据与隐私 */}
          <section className="card-glass rounded-2xl p-6" data-testid="section-privacy">
            <div className="mb-4 flex items-center gap-2">
              <span className="flex h-8 w-8 items-center justify-center rounded-lg border border-slate-700 bg-slate-900/60 text-sm">
                🔒
              </span>
              <div>
                <h2 className="text-base font-semibold text-white">数据与隐私</h2>
                <p className="mt-0.5 text-xs text-slate-500">
                  你的简历原料、故事库、投递记录、模型密钥都只存在本机浏览器
                </p>
              </div>
            </div>
            <div className="mb-5 rounded-lg border border-slate-700/50 bg-slate-900/40 p-3 text-xs leading-relaxed text-slate-400">
              清除配置会删除本机保存的服务器地址与模型密钥;简历数据请在各功能页内单独管理。更多说明见
              <Link to="/about" className="mx-1 text-primary-400 hover:text-primary-300">
                关于页
              </Link>
              的隐私章节。
            </div>
            <button
              className="btn border border-rose-500/40 text-sm text-rose-400 transition-colors hover:bg-rose-500/10"
              onClick={handleClearAll}
              data-testid="clear-all-button"
            >
              清除本机全部配置
            </button>
          </section>
        </main>
      </div>
    </>
  );
}
