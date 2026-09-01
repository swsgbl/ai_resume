import { useState } from 'react';
import { loadModelConfig, saveModelConfig, type AgentModelConfig } from './runner';

/** 预置厂商:点卡片即自动填好接口地址与模型名,用户只需粘贴密钥 */
const PROVIDERS = [
  {
    id: 'deepseek',
    name: 'DeepSeek 深度求索',
    desc: '国内直连 · 性价比高 · 推荐',
    baseUrl: 'https://api.deepseek.com/v1',
    model: 'deepseek-chat',
    keyUrl: 'https://platform.deepseek.com/api_keys',
  },
  {
    id: 'openai',
    name: 'OpenAI ChatGPT',
    desc: '效果强 · 需海外网络与支付',
    baseUrl: 'https://api.openai.com/v1',
    model: 'gpt-4o-mini',
    keyUrl: 'https://platform.openai.com/api-keys',
  },
  {
    id: 'xiaomi',
    name: '小米 MiMo',
    desc: '新玩家 · 有免费额度',
    baseUrl: 'https://api.xiaomi.com/v1',
    model: 'mimo-pro',
    keyUrl: 'https://platform.xiaomimimo.com/',
  },
];

interface Props {
  /** 紧凑模式:折叠为一条状态,点击向下展开编辑器;默认展开主体(供设置页嵌入) */
  compact?: boolean;
}

/** 模型配置(本机):三步引导式配置,密钥仅存本机浏览器 */
export default function ModelConfigCard({ compact = false }: Props) {
  const [config, setConfig] = useState<AgentModelConfig>(
    () => loadModelConfig() ?? { baseUrl: PROVIDERS[0].baseUrl, apiKey: '', model: PROVIDERS[0].model }
  );
  const [saved, setSaved] = useState(() => (loadModelConfig()?.apiKey ?? '') !== '');
  const [open, setOpen] = useState(!compact);
  const [showAdvanced, setShowAdvanced] = useState(false);
  const [justSaved, setJustSaved] = useState(false);

  const active = PROVIDERS.find((p) => p.baseUrl === config.baseUrl);
  const keyUrl = active?.keyUrl ?? PROVIDERS[0].keyUrl;
  const advancedOpen = showAdvanced || active === undefined;

  const save = () => {
    saveModelConfig(config);
    setSaved(config.apiKey.trim() !== '');
    setJustSaved(true);
    setTimeout(() => {
      setJustSaved(false);
      if (compact) setOpen(false);
    }, 1600);
  };

  const editor = (
    <div className="space-y-4">
      {/* 引导语 */}
      <div className="rounded-lg bg-slate-800/50 px-3 py-2 text-[11px] leading-relaxed text-slate-400">
        三步搞定:<span className="text-slate-200">① 选模型 → ② 粘贴密钥 → ③ 保存</span>
        。密钥只保存在你自己设备的浏览器里,绝不上传服务器。
      </div>

      {/* 第①步:选厂商卡片 */}
      <div>
        <p className="mb-2 text-xs font-medium text-slate-300">第 ① 步 · 选一个 AI 模型(点击自动填好)</p>
        <div className="grid grid-cols-3 gap-2">
          {PROVIDERS.map((p) => (
            <button
              key={p.id}
              onClick={() => setConfig((c) => ({ ...c, baseUrl: p.baseUrl, model: p.model }))}
              className={`rounded-lg border p-2.5 text-left transition-colors ${
                config.baseUrl === p.baseUrl
                  ? 'border-primary-400/60 bg-primary-500/10'
                  : 'border-slate-700 hover:border-slate-500'
              }`}
            >
              <span
                className={`block truncate text-xs font-semibold ${
                  config.baseUrl === p.baseUrl ? 'text-primary-300' : 'text-slate-200'
                }`}
              >
                {p.name}
              </span>
              <span className="mt-1 block text-[10px] leading-snug text-slate-500">{p.desc}</span>
            </button>
          ))}
        </div>
      </div>

      {/* 第②步:密钥(唯一必填) */}
      <div>
        <div className="mb-2 flex items-center justify-between gap-2">
          <p className="text-xs font-medium text-slate-300">第 ② 步 · 粘贴 API Key 密钥</p>
          <a
            href={keyUrl}
            target="_blank"
            rel="noopener noreferrer"
            className="text-[11px] text-primary-400 hover:text-primary-300 hover:underline"
          >
            没有密钥?点这里去官网获取 ↗
          </a>
        </div>
        <input
          className="input text-sm"
          type="password"
          placeholder="在官网控制台创建,一般以 sk- 开头,粘贴到这里"
          value={config.apiKey}
          onChange={(e) => {
            setConfig({ ...config, apiKey: e.target.value });
            setSaved(false);
            setJustSaved(false);
          }}
        />
      </div>

      {/* 高级选项:预设已自动填好,默认收起 */}
      <div className="rounded-lg border border-slate-800">
        <button
          onClick={() => setShowAdvanced(!showAdvanced)}
          className="flex w-full items-center justify-between px-3 py-2 text-[11px] text-slate-500 hover:text-slate-300"
        >
          <span>高级选项{active ? '(已自动填好,一般不用改)' : '(当前为自定义接口,需检查)'}</span>
          <svg
            className={`h-3 w-3 transition-transform ${advancedOpen ? 'rotate-180' : ''}`}
            fill="none"
            stroke="currentColor"
            viewBox="0 0 24 24"
          >
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M19 9l-7 7-7-7" />
          </svg>
        </button>
        {advancedOpen && (
          <div className="grid gap-2 px-3 pb-3 sm:grid-cols-2">
            <div>
              <label className="mb-1 block text-[11px] text-slate-500">接口地址(Base URL)</label>
              <input
                className="input text-xs"
                value={config.baseUrl}
                onChange={(e) => {
                  setConfig({ ...config, baseUrl: e.target.value });
                  setSaved(false);
                }}
              />
            </div>
            <div>
              <label className="mb-1 block text-[11px] text-slate-500">模型名</label>
              <input
                className="input text-xs"
                value={config.model}
                onChange={(e) => {
                  setConfig({ ...config, model: e.target.value });
                  setSaved(false);
                }}
              />
            </div>
          </div>
        )}
      </div>

      {/* 第③步:保存 */}
      <div className="flex flex-wrap items-center gap-3">
        <button
          className="btn btn-primary text-sm"
          disabled={config.apiKey.trim() === ''}
          onClick={save}
        >
          {justSaved ? '✓ 已保存' : '第 ③ 步 · 保存模型配置'}
        </button>
        {justSaved && <span className="text-xs text-emerald-400">配置完成,可以去开工了</span>}
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
        <div className="absolute right-0 top-full z-30 mt-2 w-[min(92vw,480px)] rounded-xl border border-slate-700/60 bg-slate-900/95 p-4 shadow-2xl backdrop-blur">
          {editor}
          <p className="mt-3 text-[11px] text-slate-500">也可在「设置」页统一管理模型配置。</p>
        </div>
      )}
    </div>
  );
}
