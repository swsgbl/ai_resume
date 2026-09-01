import { useState } from 'react';
import { useQuery } from '@tanstack/react-query';
import { Link } from 'react-router-dom';
import { api } from '@ai-resume/shared/api';
import type { ResumeFilter } from '@ai-resume/shared/types';
import { ResumeStatus } from '@ai-resume/shared/types';
import { formatDate } from '@ai-resume/shared/utils';

export default function ResumeListPage() {
  const [filter, setFilter] = useState<ResumeFilter>({ page: 1, page_size: 20 });

  const { data, isLoading, refetch } = useQuery({
    queryKey: ['resumes', filter],
    queryFn: () => api.resume.getResumes(filter),
  });

  const resumes = data?.data ?? [];

  const handleDelete = async (id: number) => {
    if (!confirm('确定要删除这份简历吗？此操作无法撤销。')) return;

    try {
      await api.resume.deleteResume(id);
      refetch();
    } catch (error) {
      alert(error instanceof Error ? error.message : '删除失败');
    }
  };

  const handleExport = async () => {
    // TODO: 实现导出功能
    alert('导出功能开发中...');
  };

  const getStatusBadge = (status: string) => {
    switch (status) {
      case 'published':
        return <span className="px-2 py-1 text-xs bg-green-100 text-green-700 rounded">已发布</span>;
      case 'archived':
        return <span className="px-2 py-1 text-xs bg-gray-100 text-gray-700 rounded">已归档</span>;
      default:
        return <span className="px-2 py-1 text-xs bg-orange-100 text-orange-700 rounded">草稿</span>;
    }
  };

  return (
    <div className="min-h-screen bg-gray-50">
      {/* 顶部导航栏 */}
      <header className="bg-white shadow-sm sticky top-0 z-10">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="flex justify-between items-center h-16">
            <Link to="/" className="text-xl font-bold text-primary-600">
              AI 简历
            </Link>
            <div className="flex items-center gap-4">
              <Link to="/templates" className="text-gray-700 hover:text-primary-600">
                模板库
              </Link>
              <Link to="/profile" className="text-gray-700 hover:text-primary-600">
                个人中心
              </Link>
            </div>
          </div>
        </div>
      </header>

      <main className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        <div className="flex items-center justify-between mb-6">
          <h1 className="text-2xl font-bold">我的简历</h1>
          <Link to="/resumes/new" className="btn btn-primary flex items-center gap-2">
            <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 4v16m8-8H4" />
            </svg>
            新建简历
          </Link>
        </div>

        {/* 筛选器 */}
        <div className="flex gap-2 mb-6">
          <button
            onClick={() => setFilter({ ...filter, status: undefined })}
            className={`px-4 py-2 rounded-lg text-sm font-medium transition-colors ${
              !filter.status ? 'bg-primary-600 text-white' : 'bg-white text-gray-700 hover:bg-gray-100'
            }`}
          >
            全部
          </button>
          <button
            onClick={() => setFilter({ ...filter, status: ResumeStatus.DRAFT })}
            className={`px-4 py-2 rounded-lg text-sm font-medium transition-colors ${
              filter.status === 'draft' ? 'bg-primary-600 text-white' : 'bg-white text-gray-700 hover:bg-gray-100'
            }`}
          >
            草稿
          </button>
          <button
            onClick={() => setFilter({ ...filter, status: ResumeStatus.PUBLISHED })}
            className={`px-4 py-2 rounded-lg text-sm font-medium transition-colors ${
              filter.status === 'published' ? 'bg-primary-600 text-white' : 'bg-white text-gray-700 hover:bg-gray-100'
            }`}
          >
            已发布
          </button>
          <button
            onClick={() => setFilter({ ...filter, status: ResumeStatus.ARCHIVED })}
            className={`px-4 py-2 rounded-lg text-sm font-medium transition-colors ${
              filter.status === 'archived' ? 'bg-primary-600 text-white' : 'bg-white text-gray-700 hover:bg-gray-100'
            }`}
          >
            已归档
          </button>
        </div>

        {isLoading ? (
          <div className="text-center py-12">
            <div className="inline-block w-8 h-8 border-4 border-primary-200 border-t-primary-600 rounded-full animate-spin" />
          </div>
        ) : resumes.length === 0 ? (
          <div className="card p-12 text-center">
            <svg className="w-16 h-16 text-gray-300 mx-auto mb-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z" />
            </svg>
            <h3 className="text-lg font-medium text-gray-900 mb-2">还没有简历</h3>
            <p className="text-gray-500 mb-6">点击下方按钮创建你的第一份简历</p>
            <Link to="/resumes/new" className="btn btn-primary">
              创建简历
            </Link>
          </div>
        ) : (
          <div className="grid md:grid-cols-2 lg:grid-cols-3 gap-4">
            {resumes.map((resume) => (
              <div
                key={resume.id}
                className="card hover:shadow-md transition-shadow group"
              >
                <Link to={`/resumes/${resume.id}`} className="block p-4">
                  <div className="flex items-start justify-between mb-3">
                    <h3 className="font-semibold text-lg truncate pr-2">{resume.title}</h3>
                    {getStatusBadge(resume.status)}
                  </div>
                  <p className="text-sm text-gray-500 mb-4">
                    更新于 {formatDate(resume.updated_at || resume.created_at)}
                  </p>
                  <div className="flex items-center justify-between">
                    <Link
                      to={`/resumes/${resume.id}`}
                      className="text-primary-600 hover:underline text-sm font-medium"
                    >
                      编辑简历
                    </Link>
                    <div className="flex gap-2 opacity-0 group-hover:opacity-100 transition-opacity">
                      <button
                        onClick={(e) => { e.preventDefault(); handleExport(); }}
                        className="p-1 text-gray-500 hover:text-primary-600"
                        title="导出"
                      >
                        <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M4 16v1a3 3 0 003 3h10a3 3 0 003-3v-1m-4-4l-4 4m0 0l-4-4m4 4V4" />
                        </svg>
                      </button>
                      <button
                        onClick={(e) => { e.preventDefault(); handleDelete(resume.id); }}
                        className="p-1 text-gray-500 hover:text-red-600"
                        title="删除"
                      >
                        <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16" />
                        </svg>
                      </button>
                    </div>
                  </div>
                </Link>
              </div>
            ))}
          </div>
        )}
      </main>
    </div>
  );
}
