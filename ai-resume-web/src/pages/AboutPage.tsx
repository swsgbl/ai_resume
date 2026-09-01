import { Link } from 'react-router-dom';
import { GradientText, Orb } from '../components/UIComponents';
import PublicLayout from '../components/PublicLayout';

const SUPPORT_LINKS = [
  {
    to: '/help',
    title: '帮助中心',
    desc: '使用教程、常见问题与故障排查',
    icon: (
      <svg className="w-6 h-6" fill="none" stroke="currentColor" strokeWidth={1.5} viewBox="0 0 24 24">
        <path strokeLinecap="round" strokeLinejoin="round" d="M9.879 7.519c1.171-1.025 3.071-1.025 4.242 0 1.172 1.025 1.172 2.687 0 3.712-.203.179-.43.326-.67.442-.745.361-1.45.999-1.45 1.827v.75M21 12a9 9 0 11-18 0 9 9 0 0118 0zm-9 5.25h.008v.008H12v-.008z" />
      </svg>
    ),
  },
  {
    to: '/terms',
    title: '服务条款',
    desc: '平台服务协议与使用规范',
    icon: (
      <svg className="w-6 h-6" fill="none" stroke="currentColor" strokeWidth={1.5} viewBox="0 0 24 24">
        <path strokeLinecap="round" strokeLinejoin="round" d="M19.5 14.25v-2.625a3.375 3.375 0 00-3.375-3.375h-1.5A1.125 1.125 0 0113.5 7.125v-1.5a3.375 3.375 0 00-3.375-3.375H8.25m0 12.75h7.5m-7.5 3H12M10.5 2.25H5.625c-.621 0-1.125.504-1.125 1.125v17.25c0 .621.504 1.125 1.125 1.125h12.75c.621 0 1.125-.504 1.125-1.125V11.25a9 9 0 00-9-9z" />
      </svg>
    ),
  },
  {
    to: '/privacy',
    title: '隐私政策',
    desc: '数据安全承诺与隐私保护说明',
    icon: (
      <svg className="w-6 h-6" fill="none" stroke="currentColor" strokeWidth={1.5} viewBox="0 0 24 24">
        <path strokeLinecap="round" strokeLinejoin="round" d="M9 12.75L11.25 15 15 9.75m-3-7.036A11.959 11.959 0 013.598 6 11.99 11.99 0 003 9.749c0 5.592 3.824 10.29 9 11.623 5.176-1.332 9-6.03 9-11.622 0-1.31-.21-2.571-.598-3.751h-.152c-3.196 0-6.1-1.248-8.25-3.285z" />
      </svg>
    ),
  },
];

export default function AboutPage() {
  return (
    <PublicLayout>
      {/* Background Orbs */}
      <div className="fixed inset-0 pointer-events-none overflow-hidden">
        <Orb color="primary" size={200} className="top-0 left-0 -translate-x-1/2 -translate-y-1/2 opacity-20" />
        <Orb color="accent" size={150} className="bottom-0 right-0 translate-x-1/2 translate-y-1/2 opacity-10" />
      </div>

      {/* Background Grid */}
      <div className="fixed inset-0 bg-grid pointer-events-none opacity-5" />

      {/* Main Content */}
      <div className="relative z-10">
        <main className="max-w-4xl mx-auto px-4 py-12">
          <div className="card-glass">
            <h1 className="text-3xl font-bold mb-2">
              <GradientText>关于我们</GradientText>
            </h1>
            <p className="text-slate-400 text-sm mb-8">
              AI 简历智能生成平台
            </p>

            {/* 产品介绍 */}
            <div className="mb-8">
              <p className="text-slate-300 mb-4">
                我们致力于利用前沿 AI 技术，帮助求职者创建专业、高质量的简历。
                支持多种 AI 模型，提供丰富的模板库，让求职更加轻松高效。
              </p>
              <div className="grid grid-cols-2 md:grid-cols-4 gap-4 mt-6">
                <div className="text-center p-4 bg-amber-500/10 border border-amber-500/20 rounded-lg">
                  <div className="text-2xl font-bold text-amber-400">50+</div>
                  <div className="text-sm text-slate-400">专业模板</div>
                </div>
                <div className="text-center p-4 bg-amber-500/10 border border-amber-500/20 rounded-lg">
                  <div className="text-2xl font-bold text-amber-400">3</div>
                  <div className="text-sm text-slate-400">AI 模型</div>
                </div>
                <div className="text-center p-4 bg-amber-500/10 border border-amber-500/20 rounded-lg">
                  <div className="text-2xl font-bold text-amber-400">100K+</div>
                  <div className="text-sm text-slate-400">服务用户</div>
                </div>
                <div className="text-center p-4 bg-amber-500/10 border border-amber-500/20 rounded-lg">
                  <div className="text-2xl font-bold text-amber-400">98%</div>
                  <div className="text-sm text-slate-400">满意度</div>
                </div>
              </div>
            </div>

            {/* 功能特点 */}
            <div className="mb-8">
              <h2 className="text-lg font-semibold text-white mb-4">核心功能</h2>
              <ul className="space-y-3">
                <li className="flex items-start gap-3">
                  <svg className="w-5 h-5 text-emerald-400 mt-0.5" fill="currentColor" viewBox="0 0 20 20">
                    <path fillRule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z" clipRule="evenodd" />
                  </svg>
                  <span className="text-slate-300"><strong className="text-white">AI 智能生成</strong> - 支持多种 AI 模型（OpenAI、DeepSeek、小米AI）</span>
                </li>
                <li className="flex items-start gap-3">
                  <svg className="w-5 h-5 text-emerald-400 mt-0.5" fill="currentColor" viewBox="0 0 20 20">
                    <path fillRule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z" clipRule="evenodd" />
                  </svg>
                  <span className="text-slate-300"><strong className="text-white">精美模板</strong> - 50+ 专业设计的简历模板，涵盖各行业</span>
                </li>
                <li className="flex items-start gap-3">
                  <svg className="w-5 h-5 text-emerald-400 mt-0.5" fill="currentColor" viewBox="0 0 20 20">
                    <path fillRule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z" clipRule="evenodd" />
                  </svg>
                  <span className="text-slate-300"><strong className="text-white">多格式导出</strong> - 支持 PDF、Word、HTML 格式导出</span>
                </li>
                <li className="flex items-start gap-3">
                  <svg className="w-5 h-5 text-emerald-400 mt-0.5" fill="currentColor" viewBox="0 0 20 20">
                    <path fillRule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z" clipRule="evenodd" />
                  </svg>
                  <span className="text-slate-300"><strong className="text-white">安全可靠</strong> - JWT 认证、数据加密、隐私保护</span>
                </li>
              </ul>
            </div>

            {/* 联系我们 */}
            <div className="mb-8">
              <h2 className="text-lg font-semibold text-white mb-4">联系我们</h2>
              <div className="space-y-3">
                <div className="flex items-center gap-3">
                  <svg className="w-5 h-5 text-slate-500" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M3 8l7.89 5.26a2 2 0 002.22 0L21 8M5 19h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v10a2 2 0 002 2z" />
                  </svg>
                  <span className="text-slate-400">support@airesume.com</span>
                </div>
                <div className="flex items-center gap-3">
                  <svg className="w-5 h-5 text-slate-500" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M3.055 11H5a2 2 0 012 2v1a2 2 0 002 2 2 2 0 012 2v2.945M8 3.935V5.5A2.5 2.5 0 0010.5 8h.5a2 2 0 012 2 2 2 0 104 0 2 2 0 012-2h1.064M15 20.488V18a2 2 0 012-2h3.064M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
                  </svg>
                  <span className="text-slate-400">https://github.com/airesume</span>
                </div>
              </div>
            </div>

            {/* 支持与法律:帮助/条款/隐私统一入口 */}
            <div className="mb-8">
              <h2 className="text-lg font-semibold text-white mb-4">支持与法律</h2>
              <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
                {SUPPORT_LINKS.map((item) => (
                  <Link
                    key={item.to}
                    to={item.to}
                    className="group p-5 bg-primary-500/5 border border-primary-500/15 rounded-lg transition-all duration-300 hover:border-primary-400/40 hover:shadow-[0_0_24px_rgba(79,216,235,0.12)]"
                  >
                    <div className="text-primary-400 mb-3 transition-transform duration-300 group-hover:scale-110">
                      {item.icon}
                    </div>
                    <div className="font-medium text-white mb-1">{item.title}</div>
                    <div className="text-sm text-slate-400">{item.desc}</div>
                  </Link>
                ))}
              </div>
            </div>

            {/* 版本信息 */}
            <div className="text-center text-sm text-slate-500 border-t border-white/5 pt-6">
              <p>版本 1.0.0</p>
              <p className="mt-2">&copy; 2026 AI Resume. All rights reserved.</p>
            </div>
          </div>
        </main>
      </div>
    </PublicLayout>
  );
}
