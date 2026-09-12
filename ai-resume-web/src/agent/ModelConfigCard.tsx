import { useState } from 'react';
import {
  PROVIDER_PRESETS,
  PROVIDER_CATEGORY_LABELS,
  presetToConfig,
  loadProviderStore,
  saveProviderConfig,
  removeProvider,
  setDefaultProvider,
  type ProviderConfig,
} from './providers';
import { saveModelConfig } from './runner';

/**
 * 多厂商模型配置管理(OpenCode 式 provider 路由):
 * - 厂商卡网格:预设目录一键接入,已配置的显示状态
 * - 每家独立配置(端点/模型/密钥),⭐ 设为默认 = 车间路由切换
 * - compact 模式:/os 顶栏折叠条,显示当前路由并支持快速切换
 * - 密钥按产品「仅存本机浏览器」承诺持久化存储(刷新不丢,绝不上传)
 */

interface Props {
  /** 紧凑模式:/os 顶栏折叠条;默认展开主体(供设置页嵌入) */
  compact?: boolean;
}

export default function ModelConfigCard({ compact = false }: Props) {
  const [store, setStore] = useState(loadProviderStore);
  const [editingId, setEditingId] = useState<string | null>(null);
  const [draft, setDraft] = useState<ProviderConfig | null>(null);
  const [justSaved, setJustSaved] = useState(false);
  const [open, setOpen] = useState(!compact);
  const [presetSearch, setPresetSearch] = useState('');

  const defaultProvider = store.providers.find((p) => p.id === store.defaultId) ?? null;
  const routeReady = !!defaultProvider && defaultProvider.apiKey.trim() !== '';

  const startEdit = (config: ProviderConfig) => {
    setEditingId(config.id);
    setDraft({ ...config });
  };

  const startAddPreset = (presetId: string) => {
    const preset = PROVIDER_PRESETS.find((p) => p.id === presetId);
    if (!preset) return;
    startEdit(presetToConfig(preset));
  };

  const handleSave = () => {
    if (!draft) return;
    const next = saveProviderConfig(draft);
    saveModelConfig({ baseUrl: draft.baseUrl, apiKey: draft.apiKey, model: draft.model });
    setStore(next);
    setEditingId(null);
    setDraft(null);
    setJustSaved(true);
    setTimeout(() => setJustSaved(false), 1600);
  };

  const handleRemove = (id: string) => {
    if (!confirm('删除该厂商配置?其 API Key 将一并从本机清除。')) return;
    setStore(removeProvider(id));
    if (editingId === id) {
      setEditingId(null);
      setDraft(null);
    }
  };

  const handleSetDefault = (id: string) => {
    const next = setDefaultProvider(id);
    setStore(next);
    const p = next.providers.find((x) => x.id === id);
    if (p) saveModelConfig({ baseUrl: p.baseUrl, apiKey: p.apiKey, model: p.model });
  };

  const editor = (
    <div className="space-y-4">
      {/* 引导语 */}
      <div className="rounded-lg bg-slate-800/50 px-3 py-2 text-[11px] leading-relaxed text-slate-400">
        可同时接入多家 AI,点 <span className="text-accent-500">⭐</span> 切换默认——车间所有工位立即改用它。
        密钥只保存在本机浏览器,绝不上传。
      </div>

      {/* 已接入的厂商 */}
      {store.providers.length > 0 && (
        <div>
          <p className="mb-2 text-xs font-medium text-slate-300">已接入(⭐ = 当前默认路由)</p>
          <div className="grid grid-cols-2 gap-2 sm:grid-cols-3">
            {store.providers.map((p) => {
              const isDefault = p.id === store.defaultId;
              const ready = p.apiKey.trim() !== '';
              return (
                <div
                  key={p.id}
                  className={`relative rounded-lg border p-2.5 ${
                    isDefault ? 'border-accent-500/50 bg-accent-500/5' : 'border-slate-700 bg-slate-900/40'
                  }`}
                >
                  <button
                    onClick={() => handleSetDefault(p.id)}
                    title={isDefault ? '当前默认路由' : '设为默认路由'}
                    className={`absolute right-2 top-2 text-sm transition-transform hover:scale-125 ${
                      isDefault ? 'text-accent-500' : 'text-slate-600 hover:text-accent-500/70'
                    }`}
                  >
                    ⭐
                  </button>
                  <button onClick={() => startEdit(p)} className="block w-full pr-6 text-left">
                    <span className="block truncate text-xs font-semibold text-slate-200">{p.name}</span>
                    <span className="mt-1 block truncate text-[10px] text-slate-500">{p.model || '未选模型'}</span>
                    <span
                      className={`mt-1 inline-block rounded px-1.5 py-0.5 text-[10px] ${
                        ready ? 'bg-emerald-500/10 text-emerald-400' : 'bg-amber-500/10 text-amber-400'
                      }`}
                    >
                      {ready ? '已配置' : '缺密钥'}
                    </span>
                  </button>
                </div>
              );
            })}
          </div>
        </div>
      )}

      {/* 编辑器(选中厂商或新增) */}
      {draft && (
        <div className="space-y-3 rounded-lg border border-primary-400/30 bg-primary-500/5 p-3">
          <div className="grid gap-2 sm:grid-cols-2">
            <div>
              <label className="mb-1 block text-[11px] text-slate-500">厂商名称</label>
              <input
                className="input text-xs"
                value={draft.name}
                onChange={(e) => setDraft({ ...draft, name: e.target.value })}
              />
            </div>
            <div>
              <label className="mb-1 block text-[11px] text-slate-500">模型名</label>
              {(() => {
                const preset = PROVIDER_PRESETS.find((p) => p.id === draft.id);
                if (preset?.models.length) {
                  return (
                    <select
                      className="input text-xs"
                      value={draft.model}
                      onChange={(e) => setDraft({ ...draft, model: e.target.value })}
                    >
                      {preset.models.map((m) => (
                        <option key={m} value={m}>
                          {m}
                        </option>
                      ))}
                      {!preset.models.includes(draft.model) && <option value={draft.model}>{draft.model}</option>}
                    </select>
                  );
                }
                return (
                  <input
                    className="input font-mono text-xs"
                    placeholder="如 deepseek-chat"
                    value={draft.model}
                    onChange={(e) => setDraft({ ...draft, model: e.target.value })}
                  />
                );
              })()}
            </div>
          </div>
          <div>
            <label className="mb-1 block text-[11px] text-slate-500">接口地址(Base URL,OpenAI 兼容)</label>
            <input
              className="input font-mono text-xs"
              value={draft.baseUrl}
              onChange={(e) => setDraft({ ...draft, baseUrl: e.target.value })}
            />
          </div>
          <div>
            <div className="mb-1 flex items-center justify-between">
              <label className="text-[11px] text-slate-500">API Key 密钥</label>
              {(() => {
                const preset = PROVIDER_PRESETS.find((p) => p.id === draft.id);
                return preset?.keyUrl ? (
                  <a
                    href={preset.keyUrl}
                    target="_blank"
                    rel="noopener noreferrer"
                    className="text-[11px] text-primary-400 hover:text-primary-300 hover:underline"
                  >
                    没有密钥?去官网获取 ↗
                  </a>
                ) : null;
              })()}
            </div>
            <input
              className="input text-sm"
              type="password"
              placeholder="一般以 sk- 开头,粘贴到这里"
              value={draft.apiKey}
              onChange={(e) => setDraft({ ...draft, apiKey: e.target.value })}
            />
          </div>
          <div className="flex flex-wrap items-center gap-2">
            <button
              className="btn btn-primary text-sm"
              disabled={!draft.name.trim() || !draft.baseUrl.trim() || !draft.model.trim()}
              onClick={handleSave}
            >
              {justSaved ? '✓ 已保存' : '保存配置'}
            </button>
            <button
              className="btn btn-secondary text-sm"
              onClick={() => {
                setEditingId(null);
                setDraft(null);
              }}
            >
              取消
            </button>
            {store.providers.some((p) => p.id === draft.id) && (
              <button
                className="ml-auto text-xs text-rose-400/80 hover:text-rose-400"
                onClick={() => handleRemove(draft.id)}
              >
                删除此厂商
              </button>
            )}
          </div>
        </div>
      )}

      {/* 预设目录:搜索 + 分组一键接入 */}
      <div>
        <p className="mb-2 text-xs font-medium text-slate-300">接入新厂商({PROVIDER_PRESETS.length} 家可选)</p>
        <input
          className="input mb-2 text-xs"
          placeholder="搜索厂商,如 DeepSeek / Kimi / Groq / Ollama…"
          value={presetSearch}
          onChange={(e) => setPresetSearch(e.target.value)}
        />
        <div className="max-h-64 space-y-3 overflow-y-auto pr-1">
          {(['cn', 'global', 'local'] as const).map((cat) => {
            const list = PROVIDER_PRESETS.filter(
              (preset) =>
                preset.category === cat &&
                !store.providers.some((p) => p.id === preset.id) &&
                (presetSearch.trim() === '' ||
                  `${preset.name}${preset.desc}`.toLowerCase().includes(presetSearch.trim().toLowerCase()))
            );
            if (list.length === 0) return null;
            return (
              <div key={cat}>
                <p className="mb-1.5 text-[10px] font-medium uppercase tracking-wider text-slate-600">
                  {PROVIDER_CATEGORY_LABELS[cat]}
                </p>
                <div className="grid grid-cols-2 gap-2 sm:grid-cols-3">
                  {list.map((preset) => (
                    <button
                      key={preset.id}
                      onClick={() => startAddPreset(preset.id)}
                      className="rounded-lg border border-slate-700 p-2.5 text-left transition-colors hover:border-primary-400/40"
                    >
                      <span className="block truncate text-xs font-semibold text-slate-200">{preset.name}</span>
                      <span className="mt-1 block truncate text-[10px] text-slate-500">{preset.desc}</span>
                    </button>
                  ))}
                </div>
              </div>
            );
          })}
        </div>
      </div>
    </div>
  );

  if (!compact) return editor;

  return (
    <div className="relative">
      <button
        onClick={() => setOpen(!open)}
        className="flex items-center gap-2 rounded-xl border border-slate-700/60 bg-slate-900/70 px-3.5 py-2 text-sm backdrop-blur transition-colors hover:border-primary-400/40"
      >
        <span className="text-base leading-none">⚙</span>
        <span className="text-slate-400">模型</span>
        <span className="max-w-[150px] truncate text-slate-200">
          {defaultProvider ? `${defaultProvider.name} · ${defaultProvider.model}` : '未设置'}
        </span>
        <span
          className={`rounded px-1.5 py-0.5 text-[11px] ${
            routeReady ? 'bg-emerald-500/10 text-emerald-400' : 'bg-amber-500/10 text-amber-400'
          }`}
        >
          {routeReady ? '已配置' : '未配置'}
        </span>
        <svg
          className={`h-3.5 w-3.5 text-slate-500 transition-transform ${open ? 'rotate-180' : ''}`}
          fill="none"
          stroke="currentColor"
          viewBox="0 0 24 24"
        >
          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M19 9l-7 7-7-7" />
        </svg>
      </button>
      {open && (
        <div className="absolute right-0 top-full z-30 mt-2 w-[min(92vw,520px)] rounded-xl border border-slate-700/60 bg-slate-900/95 p-4 shadow-2xl backdrop-blur">
          {editor}
          <p className="mt-3 text-[11px] text-slate-500">也可在「设置」页统一管理多厂商与默认路由。</p>
        </div>
      )}
    </div>
  );
}
