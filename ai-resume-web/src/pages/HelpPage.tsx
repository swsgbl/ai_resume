import { Link } from 'react-router-dom';
import { GradientText, Orb } from '../components/UIComponents';
import { SEO } from '../components/SEO';
import PublicLayout from '../components/PublicLayout';

export default function HelpPage() {
  const faqs = [
    {
      question: '如何创建一份新简历？',
      answer: '登录后点击"创建新简历"按钮，填写基本信息、教育经历、工作经历等内容，系统会自动保存您的进度。'
    },
    {
      question: '如何使用 AI 功能生成简历？',
      answer: '在简历编辑页面，点击"AI 生成"按钮，输入目标职位和您的背景信息，AI 会自动为您生成专业简历内容。'
    },
    {
      question: '支持哪些导出格式？',
      answer: '目前支持 PDF、Word (docx) 和 HTML 格式导出。您可以在简历编辑页面点击"导出"按钮选择格式。'
    },
    {
      question: '如何更换简历模板？',
      answer: '进入"模板库"页面，浏览50+专业模板，点击即可预览。选择心仪模板后，在简历编辑器中应用即可。'
    },
    {
      question: '忘记密码怎么办？',
      answer: '点击登录页面的"忘记密码"链接，输入注册邮箱，我们会发送重置验证码到您的邮箱。'
    },
    {
      question: '如何联系客服？',
      answer: '您可以通过邮箱 support@airesume.com 联系我们，我们会尽快回复您的问题。'
    }
  ];

  return (
    <PublicLayout>
      <SEO
        title="简历怎么写 - 帮助中心"
        description="AI简历使用指南：简历怎么写、应届生简历模板、自我评价怎么写、项目经验描述技巧。STAR法则、面试准备全攻略。"
        keywords="简历怎么写,应届生简历怎么写,简历自我评价怎么写,简历项目经验,简历star法则,求职攻略"
        canonicalUrl="https://ndtool.cn/help"
      />
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
              <GradientText>简历怎么写 - 帮助中心</GradientText>
            </h1>
            <p className="text-slate-400 text-sm mb-8">
              常见问题解答和使用指南
            </p>

            {/* 快速导航 */}
            <div className="grid grid-cols-1 md:grid-cols-3 gap-4 mb-8">
              <Link to="/register" className="p-4 rounded-lg bg-slate-800/50 border border-slate-700/50 hover:border-amber-500/50 transition-colors">
                <div className="w-10 h-10 rounded-lg bg-amber-500/20 flex items-center justify-center mb-3">
                  <svg className="w-5 h-5 text-amber-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M18 9v3m0 0v3m0-3h3m-3 0h-3m-2-5a4 4 0 11-8 0 4 4 0 018 0zM3 20a6 6 0 0112 0v1H3v-1z" />
                  </svg>
                </div>
                <h3 className="text-white font-medium mb-1">新用户注册</h3>
                <p className="text-slate-400 text-xs">创建账号开始使用</p>
              </Link>

              <Link to="/templates" className="p-4 rounded-lg bg-slate-800/50 border border-slate-700/50 hover:border-amber-500/50 transition-colors">
                <div className="w-10 h-10 rounded-lg bg-emerald-500/20 flex items-center justify-center mb-3">
                  <svg className="w-5 h-5 text-emerald-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M4 5a1 1 0 011-1h14a1 1 0 011 1v2a1 1 0 01-1 1H5a1 1 0 01-1-1V5zM4 13a1 1 0 011-1h6a1 1 0 011 1v6a1 1 0 01-1 1H5a1 1 0 01-1-1v-6zM16 13a1 1 0 011-1h2a1 1 0 011 1v6a1 1 0 01-1 1h-2a1 1 0 01-1-1v-6z" />
                  </svg>
                </div>
                <h3 className="text-white font-medium mb-1">模板库</h3>
                <p className="text-slate-400 text-xs">浏览50+专业模板</p>
              </Link>

              <a href="mailto:support@airesume.com" className="p-4 rounded-lg bg-slate-800/50 border border-slate-700/50 hover:border-amber-500/50 transition-colors">
                <div className="w-10 h-10 rounded-lg bg-pink-500/20 flex items-center justify-center mb-3">
                  <svg className="w-5 h-5 text-pink-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M3 8l7.89 5.26a2 2 0 002.22 0L21 8M5 19h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v10a2 2 0 002 2z" />
                  </svg>
                </div>
                <h3 className="text-white font-medium mb-1">联系客服</h3>
                <p className="text-slate-400 text-xs">support@airesume.com</p>
              </a>
            </div>

            {/* FAQ 列表 */}
            <h2 className="text-xl font-semibold text-white mb-4">常见问题</h2>
            <div className="space-y-4">
              {faqs.map((faq) => (
                <details key={faq.question} className="group">
                  <summary className="flex items-center justify-between p-4 rounded-lg bg-slate-800/50 border border-slate-700/50 cursor-pointer hover:border-amber-500/50 transition-colors">
                    <span className="text-white font-medium">{faq.question}</span>
                    <svg className="w-5 h-5 text-slate-400 group-open:rotate-180 transition-transform" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M19 9l-7 7-7-7" />
                    </svg>
                  </summary>
                  <div className="mt-3 px-4 text-slate-300 text-sm leading-relaxed">
                    {faq.answer}
                  </div>
                </details>
              ))}
            </div>

            {/* 使用指南 */}
            <h2 className="text-xl font-semibold text-white mb-4 mt-8">使用指南</h2>
            <div className="space-y-4 text-slate-300 text-sm leading-relaxed">
              <section>
                <h3 className="text-white font-medium mb-2">1. 创建账号</h3>
                <p>点击注册按钮，填写邮箱和密码，完成邮箱验证后即可开始使用。</p>
              </section>

              <section>
                <h3 className="text-white font-medium mb-2">2. 创建简历</h3>
                <p>点击"创建新简历"，选择合适的模板，填写您的个人信息、教育经历、工作经验等内容。</p>
              </section>

              <section>
                <h3 className="text-white font-medium mb-2">3. AI 优化</h3>
                <p>使用 AI 功能优化您的简历内容，使用 STAR 法则让经历更有说服力。</p>
              </section>

              <section>
                <h3 className="text-white font-medium mb-2">4. 导出简历</h3>
                <p>完成编辑后，选择合适的格式导出简历，支持 PDF、Word 和 HTML 格式。</p>
              </section>
            </div>
          </div>
        </main>
      </div>
    </PublicLayout>
  );
}
