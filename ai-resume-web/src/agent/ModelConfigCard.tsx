import { useState } from 'react';
import { loadModelConfig, saveModelConfig, type AgentModelConfig } from './runner';

const PRESETS = [
  { label: 'DeepSeek chat', baseUrl: 'https://api.deepseek.com/v1', model: 'deepseek-chat' },
  { label: 'OpenAI mini', baseUrl: 'https://api.openai.com/v1', model: 'gpt-4o-mini' },
  { label: '小米 MiMo', baseUrl: 'https://api.xiaomi.com/v1', model: 'mimo-pro' },
];

const FALLBACK: AgentModelConfig = { baseUrl: PRESETS[0].baseUrl, apiKey: '', model: PRESETS[0].model };

interface Props {
  /** 紧凑模式:折叠为一条状态,点击向下展开编辑器;默认展开主体(供设置页嵌入) */
  compact?: boolean;
}

/** 模型配置(本机):OpenAI 兼容端点 + 模型名 + API Key,仅存本机浏览器 */
export default function ModelConfigCard({ compact = false }: Props) {
  const [config, setConfig] = useState<AgentModelConfig>(() => loadModelConfig() ?? FALLBACK);
  const [saved, setSaved] = useState(() => (loadModelConfig()?.apiKey ?? '') !== '');
  const [open, setOpen] = useState(!compact);

  const save = () => {
    saveModelConfig(config);
    setSaved(config.apiKey !== '');
    if (compact) setOpen(false);
  };

  const editor = (
    <div className="space-y-3">
      <div className="flex flex-wrap gap-2">
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
      <div className="grid gap-2 sm:grid-cols-3">
        <input
          className="input text-xs"
          placeholder="Base URL (OpenAI 兼容)"
          value={config.baseUrl}
          onChange={(e) => {
            setConfig({ ...config, baseUrl: e.target.value });
            setSaved(false);
          }}
        />
        <input
          className="input text-xs"
          placeholder="模型名,如 deepseek-chat"
          value={config.model}
          onChange={(e) => {
            setConfig({ ...config, model: e.target.value });
            setSaved(false);
          }}
        />
        <input
          className="input text-xs"
          type="password"
          placeholder="API Key(仅存本机)"
          value={config.apiKey}
          onChange={(e) => {
            setConfig({ ...config, apiKey: e.target.value });
            setSaved(false);
          }}
        />
      </div>
      <button className="btn btn-primary text-sm w-fit" onClick={save}>
        保存模型配置
      </button>
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
        <span className="max-w-[130px] truncate text-slate-200">{config.model || '未设置'}</span>
        <span
          className={`rounded px-1.5 py-0.5 text-[11px] ${
            saved ? 'bg-emerald-500/10 text-emerald-400' : 'bg-amber-500/10 text-amber-400'
          }`}
        >
          {saved ? '已配置' : '未配置'}
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
        <div className="absolute right-0 top-full z-30 mt-2 w-[min(92vw,420px)] rounded-xl border border-slate-700/60 bg-slate-900/95 p-4 shadow-2xl backdrop-blur">
          {editor}
          <p className="mt-3 text-[11px] text-slate-500">密钥仅保存在本机浏览器,也可在「设置」页统一管理。</p>
        </div>
      )}
    </div>
  );
}
