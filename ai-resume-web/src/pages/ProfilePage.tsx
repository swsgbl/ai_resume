import { Link } from 'react-router-dom';
import { useAuthStore } from '../store/auth';

export default function ProfilePage() {
  const { user, logout } = useAuthStore();

  const handleLogout = () => {
    if (confirm('确定要退出登录吗？')) {
      logout();
      window.location.href = '/login';
    }
  };

  const getRoleBadge = () => {
    switch (user?.role) {
      case 'premium':
        return <span className="px-2 py-1 bg-amber-500/20 text-amber-400 text-xs rounded">专业版</span>;
      case 'enterprise':
        return <span className="px-2 py-1 bg-emerald-500/20 text-emerald-400 text-xs rounded">企业版</span>;
      case 'admin':
        return <span className="px-2 py-1 bg-red-500/20 text-red-400 text-xs rounded">管理员</span>;
      default:
        return <span className="px-2 py-1 bg-slate-700 text-slate-300 text-xs rounded">免费版</span>;
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

      <main className="max-w-4xl mx-auto px-4 py-8">
        <h1 className="text-2xl font-bold mb-6 text-slate-100">个人中心</h1>

        {/* 用户信息卡片 */}
        <div className="card p-6 mb-6">
          <div className="flex items-center gap-6">
            <div className="w-20 h-20 bg-amber-500/20 rounded-full flex items-center justify-center">
              <span className="text-3xl font-bold text-amber-400">
                {(user?.nickname ?? user?.email ?? 'U')[0].toUpperCase()}
              </span>
            </div>
            <div className="flex-1">
              <div className="flex items-center gap-2 mb-1">
                <h2 className="text-xl font-semibold text-slate-100">
                  {user?.nickname ?? user?.email?.split('@')[0] ?? '用户'}
                </h2>
                {getRoleBadge()}
              </div>
              <p className="text-slate-400">{user?.email}</p>
            </div>
          </div>
        </div>

        {/* 会员状态 */}
        <div className="card p-6 mb-6 bg-gradient-to-r from-amber-500/10 to-orange-500/10">
          <div className="flex items-center justify-between">
            <div>
              <h3 className="font-semibold text-lg mb-1 text-slate-100">升级专业版</h3>
              <p className="text-slate-400 text-sm">解锁 AI 深度优化、无限简历等高级功能</p>
            </div>
            <button className="btn btn-primary bg-amber-500 hover:bg-amber-600 border-0">
              立即升级
            </button>
          </div>
        </div>

        {/* 功能菜单 */}
        <div className="card divide-y">
          <Link to="/resumes" className="flex items-center justify-between p-4 hover:bg-white/5 transition-colors">
            <div className="flex items-center gap-3">
              <svg className="w-5 h-5 text-slate-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z" />
              </svg>
              <span>我的简历</span>
            </div>
            <svg className="w-5 h-5 text-slate-500" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 5l7 7-7 7" />
            </svg>
          </Link>

          <Link to="/templates" className="flex items-center justify-between p-4 hover:bg-white/5 transition-colors">
            <div className="flex items-center gap-3">
              <svg className="w-5 h-5 text-slate-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M4.318 6.318a4.5 4.5 0 000 6.364L12 20.364l7.682-7.682a4.5 4.5 0 00-6.364-6.364L12 7.636l-1.318-1.318a4.5 4.5 0 00-6.364 0z" />
              </svg>
              <span>我的收藏</span>
            </div>
            <svg className="w-5 h-5 text-slate-500" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 5l7 7-7 7" />
            </svg>
          </Link>

          <Link to="/settings" className="flex items-center justify-between p-4 hover:bg-white/5 transition-colors">
            <div className="flex items-center gap-3">
              <svg className="w-5 h-5 text-slate-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M10.325 4.317c.426-1.756 2.924-1.756 3.35 0a1.724 1.724 0 002.573 1.066c1.543-.94 3.31.826 2.37 2.37a1.724 1.724 0 001.065 2.572c1.756.426 1.756 2.924 0 3.35a1.724 1.724 0 00-1.066 2.573c.94 1.543-.826 3.31-2.37 2.37a1.724 1.724 0 00-2.572 1.065c-.426 1.756-2.924 1.756-3.35 0a1.724 1.724 0 00-2.573-1.066c-1.543.94-3.31-.826-2.37-2.37a1.724 1.724 0 00-1.065-2.572c-1.756-.426-1.756-2.924 0-3.35a1.724 1.724 0 001.066-2.573c-.94-1.543.826-3.31 2.37-2.37.996.608 2.296.07 2.572-1.065z" />
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M15 12a3 3 0 11-6 0 3 3 0 016 0z" />
              </svg>
              <span>设置</span>
            </div>
            <svg className="w-5 h-5 text-slate-500" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 5l7 7-7 7" />
            </svg>
          </Link>

          <Link to="/help" className="flex items-center justify-between p-4 hover:bg-white/5 transition-colors">
            <div className="flex items-center gap-3">
              <svg className="w-5 h-5 text-slate-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M8.228 9c.549-1.165 2.03-2 3.772-2 2.21 0 4 1.343 4 3 0 1.4-1.278 2.575-3.006 2.907-.542.104-.994.54-.994 1.093m0 3h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
              </svg>
              <span>帮助与反馈</span>
            </div>
            <svg className="w-5 h-5 text-slate-500" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 5l7 7-7 7" />
            </svg>
          </Link>

          <Link to="/about" className="flex items-center justify-between p-4 hover:bg-white/5 transition-colors">
            <div className="flex items-center gap-3">
              <svg className="w-5 h-5 text-slate-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
              </svg>
              <span>关于我们</span>
            </div>
            <span className="text-sm text-slate-500">版本 1.0.0</span>
          </Link>

          <button
            onClick={handleLogout}
            className="flex items-center justify-between p-4 hover:bg-red-500/10 transition-colors w-full text-left text-red-400"
          >
            <div className="flex items-center gap-3">
              <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M17 16l4-4m0 0l-4-4m4 4H7m6 4v1a3 3 0 01-3 3H6a3 3 0 01-3-3V7a3 3 0 013-3h4a3 3 0 013 3v1" />
              </svg>
              <span>退出登录</span>
            </div>
          </button>
        </div>
      </main>
    </div>
  );
}
