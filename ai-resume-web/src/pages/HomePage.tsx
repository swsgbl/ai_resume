import { useState } from 'react';
import { Link } from 'react-router-dom';
import { useAuthStore } from '../store/auth';
import { SEO } from '../components/SEO';
import {
  Button,
  Card,
  IconWrapper,
  GradientText,
  Orb,
  Badge,
} from '../components/UIComponents';

export default function HomePage() {
  const { user, logout } = useAuthStore();
  const [mobileMenuOpen, setMobileMenuOpen] = useState(false);
  const displayName = user?.nickname ?? user?.email?.split('@')[0] ?? '用户';

  return (
    <>
      <SEO
        title="AI 智能简历生成器 - 快速创建专业简历"
        description="使用 AI 技术快速创建专业简历。支持 50+ 精美模板，智能生成内容，实时预览，PDF/Word 导出。让求职更高效！"
        keywords="AI简历,简历生成器,在线简历,简历模板,智能简历,PDF简历,简历制作,免费简历"
      />
      <div className="min-h-screen relative overflow-hidden">
      {/* Background Orbs */}
      <div className="fixed inset-0 pointer-events-none overflow-hidden">
        <Orb color="primary" size={600} className="top-0 left-0 -translate-x-1/2 -translate-y-1/2" />
        <Orb color="accent" size={500} className="bottom-0 right-0 translate-x-1/2 translate-y-1/2" />
        <Orb color="primary" size={300} className="top-1/2 right-0 translate-x-1/2 -translate-y-1/2 opacity-50" />
      </div>

      {/* Background Grid */}
      <div className="fixed inset-0 bg-grid pointer-events-none opacity-30" />

      {/* Glassmorphism Navigation */}
      <nav className="nav-glass">
        <div className="flex items-center justify-between">
          <div className="flex items-center gap-8">
            <Link to="/dashboard" className="flex items-center gap-3">
              <div
                className="w-10 h-10 rounded-xl bg-gradient-to-br from-amber-400 to-emerald-500 flex items-center justify-center shadow-neon-blue"
                style={{ width: '40px', height: '40px' }}
              >
                <svg
                  className="w-6 h-6 text-white"
                  fill="none"
                  stroke="currentColor"
                  viewBox="0 0 24 24"
                  style={{ width: '24px', height: '24px' }}
                >
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z" />
                </svg>
              </div>
              <span className="text-xl font-bold text-gradient">AI Resume</span>
            </Link>

            <div className="hidden md:flex items-center gap-6">
              <Link to="/resumes" className="text-slate-300 hover:text-white transition-colors duration-200 flex items-center gap-2">
                <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z" />
                </svg>
                我的简历
              </Link>
              <Link to="/templates" className="text-slate-300 hover:text-white transition-colors duration-200 flex items-center gap-2">
                <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M4 5a1 1 0 011-1h14a1 1 0 011 1v2a1 1 0 01-1 1H5a1 1 0 01-1-1V5zM4 13a1 1 0 011-1h6a1 1 0 011 1v6a1 1 0 01-1 1H5a1 1 0 01-1-1v-6zM16 13a1 1 0 011-1h2a1 1 0 011 1v6a1 1 0 01-1 1h-2a1 1 0 01-1-1v-6z" />
                </svg>
                模板库
              </Link>
            </div>
          </div>

          <div className="flex items-center gap-4">
            <div className="hidden sm:flex items-center gap-3 px-4 py-2 rounded-xl glass-effect">
              <div className="w-8 h-8 rounded-full bg-gradient-to-br from-amber-400 to-emerald-500 flex items-center justify-center text-white text-sm font-bold">
                {displayName.charAt(0).toUpperCase()}
              </div>
              <span className="text-sm text-slate-300">{displayName}</span>
              <Badge variant="success">PRO</Badge>
            </div>

            <Link to="/settings" className="hidden sm:p-2 p-2 text-slate-400 hover:text-white transition-colors rounded-xl hover:bg-white/5">
              <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M10.325 4.317c.426-1.756 2.924-1.756 3.35 0a1.724 1.724 0 002.573 1.066c1.543-.94 3.31.826 2.37 2.37a1.724 1.724 0 001.065 2.572c1.756.426 1.756 2.924 0 3.35a1.724 1.724 0 00-1.066 2.573c.94 1.543-.826 3.31-2.37 2.37a1.724 1.724 0 00-2.572 1.065c-.426 1.756-2.924 1.756-3.35 0a1.724 1.724 0 00-2.573-1.066c-1.543.94-3.31-.826-2.37-2.37a1.724 1.724 0 00-1.065-2.572c-1.756-.426-1.756-2.924 0-3.35a1.724 1.724 0 001.066-2.573c-.94-1.543.826-3.31 2.37-2.37.996.608 2.296.07 2.572-1.065z" />
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M15 12a3 3 0 11-6 0 3 3 0 016 0z" />
              </svg>
            </Link>

            {/* 移动端汉堡菜单按钮 */}
            <button
              onClick={() => setMobileMenuOpen(!mobileMenuOpen)}
              className="md:hidden p-2 text-slate-400 hover:text-white transition-colors rounded-xl hover:bg-white/5"
              aria-label="Toggle menu"
            >
              <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                {mobileMenuOpen ? (
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
                ) : (
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M4 6h16M4 12h16M4 18h16" />
                )}
              </svg>
            </button>

            <Button variant="ghost" size="sm" onClick={logout} className="hidden sm:flex">
              <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M17 16l4-4m0 0l-4-4m4 4H7m6 4v1a3 3 0 01-3 3H6a3 3 0 01-3-3V7a3 3 0 013-3h4a3 3 0 013 3v1" />
              </svg>
            </Button>
          </div>
        </div>

        {/* 移动端下拉菜单 */}
        {mobileMenuOpen && (
          <div className="md:hidden mt-4 pt-4 border-t border-slate-700/50">
            <div className="flex flex-col gap-2">
              <Link
                to="/resumes"
                onClick={() => setMobileMenuOpen(false)}
                className="flex items-center gap-3 px-4 py-3 rounded-xl text-slate-300 hover:text-white hover:bg-white/5 transition-colors"
              >
                <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z" />
                </svg>
                我的简历
              </Link>
              <Link
                to="/templates"
                onClick={() => setMobileMenuOpen(false)}
                className="flex items-center gap-3 px-4 py-3 rounded-xl text-slate-300 hover:text-white hover:bg-white/5 transition-colors"
              >
                <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M4 5a1 1 0 011-1h14a1 1 0 011 1v2a1 1 0 01-1 1H5a1 1 0 01-1-1V5zM4 13a1 1 0 011-1h6a1 1 0 011 1v6a1 1 0 01-1 1H5a1 1 0 01-1-1v-6zM16 13a1 1 0 011-1h2a1 1 0 011 1v6a1 1 0 01-1 1h-2a1 1 0 01-1-1v-6z" />
                </svg>
                模板库
              </Link>
              <Link
                to="/settings"
                onClick={() => setMobileMenuOpen(false)}
                className="flex items-center gap-3 px-4 py-3 rounded-xl text-slate-300 hover:text-white hover:bg-white/5 transition-colors"
              >
                <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M10.325 4.317c.426-1.756 2.924-1.756 3.35 0a1.724 1.724 0 002.573 1.066c1.543-.94 3.31.826 2.37 2.37a1.724 1.724 0 001.065 2.572c1.756.426 1.756 2.924 0 3.35a1.724 1.724 0 00-1.066 2.573c.94 1.543-.826 3.31-2.37 2.37a1.724 1.724 0 00-2.572 1.065c-.426 1.756-2.924 1.756-3.35 0a1.724 1.724 0 00-2.573-1.066c-1.543.94-3.31-.826-2.37-2.37a1.724 1.724 0 00-1.065-2.572c-1.756-.426-1.756-2.924 0-3.35a1.724 1.724 0 001.066-2.573c-.94-1.543.826-3.31 2.37-2.37.996.608 2.296.07 2.572-1.065z" />
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M15 12a3 3 0 11-6 0 3 3 0 016 0z" />
                </svg>
                设置
              </Link>
              <button
                onClick={() => {
                  logout();
                  setMobileMenuOpen(false);
                }}
                className="flex items-center gap-3 px-4 py-3 rounded-xl text-slate-300 hover:text-white hover:bg-white/5 transition-colors w-full text-left"
              >
                <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M17 16l4-4m0 0l-4-4m4 4H7m6 4v1a3 3 0 01-3 3H6a3 3 0 01-3-3V7a3 3 0 013-3h4a3 3 0 013 3v1" />
                </svg>
                退出登录
              </button>
            </div>
          </div>
        )}
      </nav>

      {/* Hero Section */}
      <section className="relative pt-32 pb-20 px-4">
        <div className="max-w-7xl mx-auto">
          <div className="text-center mb-16 animate-fade-in">
            <div className="inline-flex items-center gap-2 px-4 py-2 rounded-full glass-effect text-amber-400 text-sm mb-6">
              <span className="w-2 h-2 rounded-full bg-amber-400 animate-pulse"></span>
              AI 驱动的智能简历平台
            </div>

            <h1 className="text-3xl font-bold mb-4">
              <span className="text-white">欢迎回来</span>
            </h1>

            <p className="text-xl text-slate-400 max-w-2xl mx-auto mb-6">
              使用 AI 技术快速创建专业简历
            </p>

            <div className="text-display font-bold mb-6">
              <GradientText>打造你的</GradientText>
              <br />
              <span className="text-white">专业简历</span>
            </div>

            <p className="text-xl text-slate-400 max-w-2xl mx-auto mb-10">
              利用前沿 AI 技术，快速创建令人印象深刻的简历。
              <br />
              让求职之路更加顺畅。
            </p>

            <div className="flex flex-wrap justify-center gap-4">
              <Link
                to="/resumes/new"
                className="inline-flex items-center justify-center gap-2 px-8 py-4 font-semibold rounded-xl transition-all duration-300 cursor-pointer bg-gradient-to-r from-amber-500 to-emerald-500 text-white hover:scale-105 shadow-lg shadow-amber-500/30 text-lg"
                data-testid="create-resume-link"
              >
                <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 4v16m8-8H4" />
                </svg>
                创建新简历
              </Link>
              <Link
                to="/templates"
                className="inline-flex items-center justify-center gap-2 px-8 py-4 font-semibold rounded-xl transition-all duration-300 cursor-pointer bg-white/10 backdrop-filter blur(10px) border border-white/20 text-white hover:bg-white/20 text-lg"
                data-testid="templates-link"
              >
                <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M15 12a3 3 0 11-6 0 3 3 0 016 0z" />
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z" />
                </svg>
                浏览模板
              </Link>
            </div>
          </div>

          {/* Quick Stats */}
          <div className="grid grid-cols-2 md:grid-cols-4 gap-4 mb-16">
            {[
              { label: '简历模板', value: '50+', icon: 'M4 5a1 1 0 011-1h14a1 1 0 011 1v2a1 1 0 01-1 1H5a1 1 0 01-1-1V5z' },
              { label: 'AI 优化', value: '智能', icon: 'M13 10V3L4 14h7v7l9-11h-7z' },
              { label: '导出格式', value: 'PDF+Word', icon: 'M12 10v6m0 0l-3-3m3 3l3-3m2 8H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z' },
              { label: '用户数量', value: '10K+', icon: 'M17 20h5v-2a3 3 0 00-5.356-1.857M17 20H7m10 0v-2c0-.656-.126-1.283-.356-1.857M7 20H2v-2a3 3 0 015.356-1.857M7 20v-2c0-.656.126-1.283.356-1.857m0 0a1 1 0 001-1.857V7a3 3 0 013-3h3a1 1 0 001 1v7a3 3 0 01-1 1.857' },
            ].map((stat) => (
              <Card key={stat.label} variant="glass" className="text-center group hover:scale-105 transition-transform">
                <svg className="w-8 h-8 mx-auto mb-3 text-amber-400 group-hover:text-amber-300 transition-colors" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d={stat.icon} />
                </svg>
                <div className="text-2xl font-bold text-gradient-primary">{stat.value}</div>
                <div className="text-sm text-slate-400">{stat.label}</div>
              </Card>
            ))}
          </div>
        </div>
      </section>

      {/* Features Section */}
      <section className="py-20 px-4 relative">
        <div className="max-w-7xl mx-auto">
          <div className="text-center mb-16">
            <h2 className="text-title font-bold text-white mb-4">
              强大的功能
            </h2>
            <p className="text-slate-400 max-w-xl mx-auto">
              一站式简历解决方案，从创建到优化，从设计到导出
            </p>
          </div>

          <div className="grid md:grid-cols-3 gap-6">
            {[
              {
                title: 'AI 智能生成',
                description: '输入你的基本信息，AI 自动生成专业简历内容',
                icon: 'M9.663 17h4.673M12 3v1m6.364 1.636l-.707.707M21 12h-1M4 12H3m3.343-5.657l-.707-.707m2.828 9.9a5 5 0 117.072 0l-.548.547A3.374 3.374 0 0014 18.469V19a2 2 0 11-4 0v-.531c0-.895-.356-1.754-.988-2.386l-.548-.547z',
                color: 'primary',
              },
              {
                title: '精美模板',
                description: '50+ 专业设计的简历模板，涵盖各行业风格',
                icon: 'M4 5a1 1 0 011-1h14a1 1 0 011 1v2a1 1 0 01-1 1H5a1 1 0 01-1-1V5zM4 13a1 1 0 011-1h6a1 1 0 011 1v6a1 1 0 01-1 1H5a1 1 0 01-1-1v-6zM16 13a1 1 0 011-1h2a1 1 0 011 1v6a1 1 0 01-1 1h-2a1 1 0 01-1-1v-6z',
                color: 'accent',
              },
              {
                title: '实时预览',
                description: '所见即所得的编辑体验，实时预览简历效果',
                icon: 'M15 12a3 3 0 11-6 0 3 3 0 016 0z M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z',
                color: 'primary',
              },
              {
                title: '智能优化',
                description: 'AI 分析简历内容，提供专业的优化建议',
                icon: 'M13 7h8m0 0v8m0-8l-8 8-4-4-4 4',
                color: 'accent',
              },
              {
                title: '多格式导出',
                description: '支持 PDF、Word、HTML 等多种格式导出',
                icon: 'M12 10v6m0 0l-3-3m3 3l3-3m2 8H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z',
                color: 'primary',
              },
              {
                title: '云端同步',
                description: '数据自动云端保存，随时随地访问你的简历',
                icon: 'M3 15a4 4 0 004 4h9a5 5 0 10-.1 0H7a3 3 0 01-3.9-3 3 3 0 01.9-5.1 5 5 0 117 9 9 5 0 011 9H15',
                color: 'accent',
              },
            ].map((feature) => (
              <Link
                key={feature.title}
                to="#"
                className="group"
              >
                <Card variant="hover" className="h-full">
                  <IconWrapper
                    variant={feature.color === 'primary' ? 'primary' : 'accent'}
                    size="lg"
                    className="mb-4"
                  >
                    <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d={feature.icon} />
                    </svg>
                  </IconWrapper>
                  <h3 className="text-xl font-semibold text-white mb-2 group-hover:text-amber-400 transition-colors">
                    {feature.title}
                  </h3>
                  <p className="text-slate-400">{feature.description}</p>
                </Card>
              </Link>
            ))}
          </div>
        </div>
      </section>

      {/* Recent Resumes Section */}
      <section className="py-20 px-4">
        <div className="max-w-7xl mx-auto">
          <div className="flex items-center justify-between mb-8">
            <div>
              <h2 className="text-title font-bold text-white mb-2">最近编辑</h2>
              <p className="text-slate-400">继续编辑你的简历</p>
            </div>
            <Link to="/resumes" className="text-amber-400 hover:text-amber-300 transition-colors flex items-center gap-2">
              查看全部
              <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 5l7 7-7 7" />
              </svg>
            </Link>
          </div>

          {/* Empty State */}
          <Card variant="glass" className="text-center py-16">
            <div className="w-20 h-20 mx-auto mb-6 rounded-2xl bg-slate-800/50 flex items-center justify-center">
              <svg className="w-10 h-10 text-slate-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z" />
              </svg>
            </div>
            <h3 className="text-xl font-semibold text-white mb-2">还没有简历</h3>
            <p className="text-slate-400 mb-6 max-w-md mx-auto">
              创建你的第一份 AI 简历，开启求职之旅
            </p>
            <Link
              to="/resumes/new"
              className="inline-flex items-center justify-center gap-2 px-6 py-3 font-semibold rounded-xl transition-all duration-300 cursor-pointer bg-gradient-to-r from-amber-500 to-emerald-500 text-white hover:scale-105 shadow-lg shadow-amber-500/30"
            >
              <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 4v16m8-8H4" />
              </svg>
              创建第一份简历
            </Link>
          </Card>
        </div>
      </section>

      {/* CTA Section */}
      <section className="py-20 px-4">
        <div className="max-w-4xl mx-auto">
          <div className="relative rounded-3xl p-12 text-center overflow-hidden">
            {/* Background Gradient */}
            <div className="absolute inset-0 bg-gradient-to-r from-amber-600 via-emerald-500 to-pink-500 opacity-90"></div>
            <div className="absolute inset-0 bg-grid opacity-20"></div>

            {/* Content */}
            <div className="relative z-10">
              <h2 className="text-3xl font-bold text-white mb-4">
                准备好创建你的专业简历了吗？
              </h2>
              <p className="text-white/80 text-lg mb-8 max-w-xl mx-auto">
                加入数万求职者的行列，使用 AI 技术快速创建令人印象深刻的简历
              </p>
              <div className="flex flex-wrap justify-center gap-4">
                <Link
                  to="/resumes/new"
                  className="inline-flex items-center justify-center gap-2 px-8 py-4 font-semibold rounded-xl transition-all duration-300 cursor-pointer bg-white/10 backdrop-filter blur(10px) border border-white/20 text-white hover:bg-white/20 text-lg"
                >
                  立即开始
                </Link>
                <Link
                  to="/templates"
                  className="inline-flex items-center justify-center gap-2 px-8 py-4 font-semibold rounded-xl transition-all duration-300 cursor-pointer text-slate-300 hover:text-white hover:bg-white/5 text-lg border border-transparent hover:border-white/10"
                >
                  查看模板
                </Link>
              </div>
            </div>

            {/* Floating Elements */}
            <div className="absolute top-8 left-8 w-4 h-4 rounded-full bg-white/20 animate-float" style={{ animationDelay: '0s' }}></div>
            <div className="absolute top-16 right-12 w-3 h-3 rounded-full bg-white/20 animate-float" style={{ animationDelay: '1s' }}></div>
            <div className="absolute bottom-12 left-16 w-2 h-2 rounded-full bg-white/20 animate-float" style={{ animationDelay: '2s' }}></div>
          </div>
        </div>
      </section>

      {/* Footer */}
      <footer className="py-12 px-4 border-t border-slate-800">
        <div className="max-w-7xl mx-auto text-center text-slate-500">
          <p>&copy; 2024 AI Resume. All rights reserved.</p>
        </div>
      </footer>
    </div>
    </>
  );
}
