export type OsTab = 'extract' | 'evaluate' | 'tailor';

const TABS: Array<{ key: OsTab; label: string }> = [
  { key: 'extract', label: '① 结构化抽取' },
  { key: 'evaluate', label: '② JD 匹配评估' },
  { key: 'tailor', label: '③ 岗位定制' },
];

export default function TabsRow({ tab, onChange }: { tab: OsTab; onChange: (t: OsTab) => void }) {
  return (
    <div className="flex gap-2 mb-6 border-b border-slate-700/50 pb-1">
      {TABS.map((t) => (
        <button
          key={t.key}
          onClick={() => onChange(t.key)}
          className={`px-4 py-2.5 text-sm font-medium rounded-t-lg transition-all ${
            tab === t.key
              ? 'bg-primary-500/10 text-primary-400 border-b-2 border-primary-400'
              : 'text-slate-400 hover:text-slate-200 hover:bg-white/5'
          }`}
        >
          {t.label}
        </button>
      ))}
    </div>
  );
}
