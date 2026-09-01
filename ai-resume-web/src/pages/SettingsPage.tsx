import { useState, useEffect } from 'react';
import { Link } from 'react-router-dom';
import { storage, } from '@ai-resume/shared';
import { getApiClient } from '@ai-resume/shared/api';

type AIProvider = 'openai' | 'deepseek' | 'xiaomi';

export default function SettingsPage() {
  const [provider, setProvider] = useState<AIProvider>('openai' as AIProvider);
  const [baseUrl, setBaseUrl] = useState('http://127.0.0.1:8000/api/v1');

  // OpenAI 配置
  const [openaiKey, setOpenaiKey] = useState('');
  const [openaiModel, setOpenaiModel] = useState('gpt-4');

  // DeepSeek 配置
  const [deepseekKey, setDeepseekKey] = useState('');
  const [deepseekModel, setDeepseekModel] = useState('deepseek-chat');

  // 小米配置
  const [xiaomiKey, setXiaomiKey] = useState('');
  const [xiaomiModel, setXiaomiModel] = useState('MiMo-V2-Flash');

  const [isSaving, setIsSaving] = useState(false);
  const [message, setMessage] = useState('');
  const [switchingProvider, setSwitchingProvider] = useState<AIProvider | null>(null);

  useEffect(() => {
    // 加载配置
    setBaseUrl(storage.getBaseURL());
    setProvider(storage.getAIProvider() as AIProvider);
    setOpenaiKey(storage.getOpenAIApiKey() ?? '');
    setOpenaiModel(storage.getOpenAIModel() ?? 'gpt-4');
    setDeepseekKey(storage.getDeepSeekApiKey() ?? '');
    setDeepseekModel(storage.getDeepSeekModel() ?? 'deepseek-chat');
    setXiaomiKey(storage.getXiaomiApiKey() ?? '');
    setXiaomiModel(storage.getXiaomiModel() ?? 'MiMo-V2-Flash');
  }, []);

  const handleSave = async () => {
    setIsSaving(true);
    setMessage('');

    try {
      // 验证基础 URL
      try {
        new URL(baseUrl.replace('/api/v1', ''));
      } catch {
        setMessage('请输入有效的服务器地址');
        setIsSaving(false);
        return;
      }

      // 保存配置
      storage.setBaseURL(baseUrl);
      storage.setAIProvider(provider);
      storage.setOpenAIApiKey(openaiKey);
      storage.setOpenAIModel(openaiModel);
      storage.setDeepSeekApiKey(deepseekKey);
      storage.setDeepSeekModel(deepseekModel);
      storage.setXiaomiApiKey(xiaomiKey);
      storage.setXiaomiModel(xiaomiModel);

      // 更新 API 客户端
      const client = getApiClient();
      client.setBaseURL(baseUrl);

      setMessage('配置已保存');
    } catch (error) {
      setMessage('保存失败');
    } finally {
      setIsSaving(false);
    }
  };

  const handleClear = () => {
    if (confirm('确定要清除所有配置吗？将恢复默认设置。')) {
      storage.clearAll();
      window.location.reload();
    }
  };

  return (
    <div className="min-h-screen bg-slate-950">
      {/* 顶部导航栏 */}
      <header className="bg-slate-900/80 backdrop-blur-sm border-b border-white/10 sticky top-0 z-10">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="flex justify-between items-center h-16">
            <Link to="/dashboard" className="text-xl font-bold text-amber-400">
              AI 简历
            </Link>
            <div className="flex items-center gap-4">
              <Link to="/resumes" className="text-slate-300 hover:text-amber-400">
                我的简历
              </Link>
              <Link to="/templates" className="text-slate-300 hover:text-amber-400">
                模板库
              </Link>
            </div>
          </div>
        </div>
      </header>

      <main className="max-w-3xl mx-auto px-4 py-8">
        <h1 className="text-2xl font-bold mb-6 text-slate-100">设置</h1>

        {/* 配置说明 */}
        <div className="bg-amber-500/10 border border-amber-500/20 p-4 rounded-lg mb-6">
          <p className="text-sm text-slate-300">
            配置后端服务器地址和 AI 提供商。所有配置仅保存在本地设备，不会上传到任何服务器。
          </p>
        </div>

        {/* 服务器配置 */}
        <div className="card p-6 mb-6">
          <h2 className="text-lg font-semibold mb-4 flex items-center gap-2 text-slate-100">
            <span>🌐</span>
            服务器配置
          </h2>
          <div>
            <label className="block text-sm font-medium text-slate-300 mb-1">
              后端服务器地址
            </label>
            <input
              type="text"
              value={baseUrl}
              onChange={(e) => setBaseUrl(e.target.value)}
              className="input"
              placeholder="http://127.0.0.1:8000/api/v1"
            />
          </div>
        </div>

        {/* AI 提供商配置 */}
        <div className="card p-6 mb-6">
          <h2 className="text-lg font-semibold mb-4 flex items-center gap-2 text-slate-100">
            <span>🤖</span>
            AI 模型配置
          </h2>

          {/* 提供商选择 */}
          <div className="mb-6">
            <label className="block text-sm font-medium text-slate-300 mb-2">
              选择 AI 提供商
            </label>
            <div className="flex gap-2">
              {[
                { value: 'openai' as const, label: 'OpenAI', icon: '🌟' },
                { value: 'deepseek' as const, label: 'DeepSeek', icon: '🧠' },
                { value: 'xiaomi' as const, label: '小米AI', icon: '📱' },
              ].map((item) => (
                <button
                  key={item.value}
                  onClick={() => {
                    setSwitchingProvider(item.value);
                    setProvider(item.value);
                    setTimeout(() => setSwitchingProvider(null), 300);
                  }}
                  disabled={switchingProvider !== null}
                  className={`flex-1 p-3 rounded-lg border-2 transition-all duration-300 ${
                    provider === item.value
                      ? 'border-amber-500 bg-amber-500/10 scale-105 shadow-sm'
                      : 'border-white/10 hover:border-white/20'
                  } ${switchingProvider !== null ? 'opacity-50 cursor-not-allowed' : ''}`}
                >
                  <span className="mr-1">{item.icon}</span>
                  {item.label}
                </button>
              ))}
            </div>
            <p className="text-xs text-slate-500 mt-2">
              切换提供商后需要重新配置 API 密钥
            </p>
          </div>

          {/* OpenAI 配置 */}
          {provider === 'openai' && (
            <div className="space-y-4 p-4 bg-slate-800/50 rounded-lg">
              <h3 className="font-medium text-amber-400">OpenAI 配置</h3>
              <div>
                <label className="block text-sm font-medium text-slate-300 mb-1">
                  API 密钥
                </label>
                <input
                  type="password"
                  value={openaiKey}
                  onChange={(e) => setOpenaiKey(e.target.value)}
                  className="input"
                  placeholder="sk-..."
                />
              </div>
              <div>
                <label className="block text-sm font-medium text-slate-300 mb-1">
                  模型
                </label>
                <input
                  type="text"
                  value={openaiModel}
                  onChange={(e) => setOpenaiModel(e.target.value)}
                  className="input"
                  placeholder="gpt-4"
                />
              </div>
              <p className="text-xs text-slate-500">
                获取 API 密钥: platform.openai.com
              </p>
            </div>
          )}

          {/* DeepSeek 配置 */}
          {provider === 'deepseek' && (
            <div className="space-y-4 p-4 bg-slate-800/50 rounded-lg">
              <h3 className="font-medium text-amber-400">DeepSeek 配置</h3>
              <div>
                <label className="block text-sm font-medium text-slate-300 mb-1">
                  API 密钥
                </label>
                <input
                  type="password"
                  value={deepseekKey}
                  onChange={(e) => setDeepseekKey(e.target.value)}
                  className="input"
                  placeholder="sk-..."
                />
              </div>
              <div>
                <label className="block text-sm font-medium text-slate-300 mb-1">
                  模型
                </label>
                <input
                  type="text"
                  value={deepseekModel}
                  onChange={(e) => setDeepseekModel(e.target.value)}
                  className="input"
                  placeholder="deepseek-chat"
                />
              </div>
              <p className="text-xs text-slate-500">
                获取 API 密钥: platform.deepseek.com
              </p>
            </div>
          )}

          {/* 小米 AI 配置 */}
          {provider === 'xiaomi' && (
            <div className="space-y-4 p-4 bg-slate-800/50 rounded-lg">
              <h3 className="font-medium text-amber-400">小米 AI 配置</h3>
              <div>
                <label className="block text-sm font-medium text-slate-300 mb-1">
                  API 密钥
                </label>
                <input
                  type="password"
                  value={xiaomiKey}
                  onChange={(e) => setXiaomiKey(e.target.value)}
                  className="input"
                  placeholder="您的 API 密钥"
                />
              </div>
              <div>
                <label className="block text-sm font-medium text-slate-300 mb-1">
                  模型
                </label>
                <input
                  type="text"
                  value={xiaomiModel}
                  onChange={(e) => setXiaomiModel(e.target.value)}
                  className="input"
                  placeholder="MiMo-V2-Flash"
                />
              </div>
              <p className="text-xs text-slate-500">
                获取 API 密钥: platform.xiaomimimo.com
              </p>
            </div>
          )}
        </div>

        {/* 操作按钮 */}
        <div className="space-y-4">
          {message && (
            <div className={`p-3 rounded-lg text-center ${
              message.includes('保存') ? 'bg-emerald-500/10 text-emerald-400' : 'bg-red-500/10 text-red-400'
            }`}>
              {message}
            </div>
          )}

          <button
            onClick={handleSave}
            disabled={isSaving}
            className="btn btn-primary w-full py-3"
          >
            {isSaving ? '保存中...' : '保存配置'}
          </button>

          <button
            onClick={handleClear}
            className="btn btn-outline w-full py-3 border-red-500/30 text-red-400 hover:bg-red-500/10"
          >
            清除配置
          </button>
        </div>

        {/* 其他设置 */}
        <div className="card divide-y mt-6">
          <button className="flex items-center justify-between p-4 hover:bg-white/5 w-full text-left">
            <div className="flex items-center gap-3">
              <svg className="w-5 h-5 text-slate-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
              </svg>
              <span>关于</span>
            </div>
            <span className="text-sm text-slate-500">版本 1.0.0</span>
          </button>

          <Link to="/help" className="flex items-center justify-between p-4 hover:bg-white/5 w-full text-left">
            <div className="flex items-center gap-3">
              <svg className="w-5 h-5 text-slate-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M8.228 9c.549-1.165 2.03-2 3.772-2 2.21 0 4 1.343 4 3 0 1.4-1.278 2.575-3.006 2.907-.542.104-.994.54-.994 1.093m0 3h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
              </svg>
              <span>帮助</span>
            </div>
            <svg className="w-5 h-5 text-slate-500" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 5l7 7-7 7" />
            </svg>
          </Link>

          <Link to="/privacy" className="flex items-center justify-between p-4 hover:bg-white/5 w-full text-left">
            <div className="flex items-center gap-3">
              <svg className="w-5 h-5 text-slate-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 12l2 2 4-4m5.618-4.016A11.955 11.955 0 0112 2.944a11.955 11.955 0 01-8.618 3.04A12.02 12.02 0 003 9c0 5.591 3.824 10.29 9 11.622 5.176-1.332 9-6.03 9-11.622 0-1.042-.133-2.052-.382-3.016z" />
              </svg>
              <span>隐私政策</span>
            </div>
            <svg className="w-5 h-5 text-slate-500" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 5l7 7-7 7" />
            </svg>
          </Link>
        </div>
      </main>
    </div>
  );
}
