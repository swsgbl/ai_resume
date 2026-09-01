import { useRef, useState } from 'react';
import { useQuery } from '@tanstack/react-query';
import { Link } from 'react-router-dom';
import { SEO } from '../components/SEO';
import { ResumeListSkeleton } from '../components/ui/Skeleton';
import { api } from '@ai-resume/shared/api';
import type { ResumeFilter } from '@ai-resume/shared/types';
import { ResumeStatus } from '@ai-resume/shared/types';
import { formatDate } from '@ai-resume/shared/utils';
import { toJsonResume, fromJsonResume, jsonResumeSchema } from '@ai-resume/shared/schema';

export default function ResumeListPage() {
  const [filter, setFilter] = useState<ResumeFilter>({ page: 1, page_size: 20 });
  const importInputRef = useRef<HTMLInputElement>(null);
  const [importing, setImporting] = useState(false);

  const { data, isLoading, refetch } = useQuery({
    queryKey: ['resumes', filter],
    queryFn: () => api.resume.getResumes(filter),
  });

  const resumes = data?.data ?? [];

  /** 导出 JSON Resume 开放标准格式(纯前端,数据不出本机) */
  const handleExportJson = async (id: number, title: string) => {
    try {
      const resume = await api.resume.getResume(id);
      const jsonResume = toJsonResume(resume.content ?? {});
      const blob = new Blob([JSON.stringify(jsonResume, null, 2)], { type: 'application/json' });
      const url = URL.createObjectURL(blob);
      const a = document.createElement('a');
      a.href = url;
      a.download = `${title.replace(/[\\/:*?"<>|]/g, '_')}.resume.json`;
      a.click();
      URL.revokeObjectURL(url);
    } catch (error) {
      alert(error instanceof Error ? error.message : '导出失败');
    }
  };

  /** 导入 JSON Resume 标准文件,转换为平台模型后创建简历 */
  const handleImportJson = (file: File) => {
    const reader = new FileReader();
    reader.onload = async () => {
      try {
        const parsed = jsonResumeSchema.parse(JSON.parse(String(reader.result)));
        const content = fromJsonResume(parsed);
        setImporting(true);
        const created = await api.resume.createResume({
          title: parsed.basics?.name ? `${parsed.basics.name}的简历` : '导入的简历',
          content,
        });
        await refetch();
        alert(`已创建「${created.title}」,可前往编辑器继续完善`);
      } catch (error) {
        alert(error instanceof Error ? `导入失败: ${error.message.slice(0, 160)}` : '导入失败');
      } finally {
        setImporting(false);
      }
    };
    reader.readAsText(file);
  };

  const handleDelete = async (id: number) => {
    if (!confirm('确定要删除这份简历吗？此操作无法撤销。')) return;

    try {
      await api.resume.deleteResume(id);
      refetch();
    } catch (error) {
      alert(error instanceof Error ? error.message : '删除失败');
    }
  };

  const handleExport = async (id: number, format: 'pdf' | 'word' | 'html' = 'pdf') => {
    try {
      let url: string;
      switch (format) {
        case 'pdf':
          url = api.resume.getPdfExportUrl(id);
          break;
        case 'word':
          url = api.resume.getWordExportUrl(id);
          break;
        case 'html':
          url = api.resume.getHtmlExportUrl(id);
          break;
        default:
          url = api.resume.getPdfExportUrl(id);
      }
      // 在新窗口中打开导出URL
      window.open(url, '_blank');
    } catch (error) {
      alert(error instanceof Error ? error.message : '导出失败');
    }
  };

  const getStatusBadge = (status: string) => {
    switch (status) {
      case 'published':
        return <span className="px-2 py-1 text-xs bg-emerald-500/20 text-emerald-400 rounded">已发布</span>;
      case 'archived':
        return <span className="px-2 py-1 text-xs bg-slate-700 text-slate-300 rounded">已归档</span>;
      default:
        return <span className="px-2 py-1 text-xs bg-amber-500/20 text-amber-400 rounded">草稿</span>;
    }
  };

  return (
    <>
      <SEO
        title="我的简历"
        description="查看和管理你的所有简历。使用 AI 技术快速编辑、优化和导出专业简历。"
        noIndex
      />
      <div className="min-h-screen bg-slate-950">
      {/* 顶部导航栏 */}
      <header className="bg-slate-900/80 backdrop-blur-sm border-b border-white/10 sticky top-0 z-10">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="flex justify-between items-center h-16">
            <Link to="/dashboard" className="text-xl font-bold text-amber-400">
              AI 简历
            </Link>
            <div className="flex items-center gap-4">
              <Link to="/templates" className="text-slate-300 hover:text-amber-400">
                模板库
              </Link>
              <Link to="/profile" className="text-slate-300 hover:text-amber-400">
                个人中心
              </Link>
            </div>
          </div>
        </div>
      </header>

      <main className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        <div className="flex items-center justify-between mb-6">
          <h1 className="text-2xl font-bold text-slate-100">我的简历</h1>
          <div className="flex items-center gap-3">
            <button
              onClick={() => importInputRef.current?.click()}
              disabled={importing}
              className="btn btn-secondary flex items-center gap-2"
              data-testid="import-json-button"
            >
              <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M4 16v1a3 3 0 003 3h10a3 3 0 003-3v-1m-4-8l-4-4m0 0L8 8m4-4v12" />
              </svg>
              {importing ? '导入中…' : '导入 JSON Resume'}
            </button>
            <input
              ref={importInputRef}
              type="file"
              accept="application/json,.json"
              className="hidden"
              onChange={(e) => {
                const f = e.target.files?.[0];
                if (f) handleImportJson(f);
                e.target.value = '';
              }}
            />
            <Link to="/resumes/new" className="btn btn-primary flex items-center gap-2">
              <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 4v16m8-8H4" />
              </svg>
              新建简历
            </Link>
          </div>
        </div>

        {/* 筛选器 */}
        <div className="flex gap-2 mb-6">
          <button
            onClick={() => setFilter({ ...filter, status: undefined })}
            className={`px-4 py-2 rounded-lg text-sm font-medium transition-colors ${
              !filter.status ? 'bg-amber-500 text-white' : 'bg-slate-800 text-slate-300 hover:bg-slate-700'
            }`}
          >
            全部
          </button>
          <button
            onClick={() => setFilter({ ...filter, status: ResumeStatus.DRAFT })}
            className={`px-4 py-2 rounded-lg text-sm font-medium transition-colors ${
              filter.status === 'draft' ? 'bg-amber-500 text-white' : 'bg-slate-800 text-slate-300 hover:bg-slate-700'
            }`}
          >
            草稿
          </button>
          <button
            onClick={() => setFilter({ ...filter, status: ResumeStatus.PUBLISHED })}
            className={`px-4 py-2 rounded-lg text-sm font-medium transition-colors ${
              filter.status === 'published' ? 'bg-amber-500 text-white' : 'bg-slate-800 text-slate-300 hover:bg-slate-700'
            }`}
          >
            已发布
          </button>
          <button
            onClick={() => setFilter({ ...filter, status: ResumeStatus.ARCHIVED })}
            className={`px-4 py-2 rounded-lg text-sm font-medium transition-colors ${
              filter.status === 'archived' ? 'bg-amber-500 text-white' : 'bg-slate-800 text-slate-300 hover:bg-slate-700'
            }`}
          >
            已归档
          </button>
        </div>

        {isLoading ? (
          <ResumeListSkeleton count={6} />
        ) : resumes.length === 0 ? (
          <div className="card p-12 text-center">
            <svg className="w-16 h-16 text-slate-600 mx-auto mb-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z" />
            </svg>
            <h3 className="text-lg font-medium text-slate-100 mb-2">还没有简历</h3>
            <p className="text-slate-400 mb-6">点击下方按钮创建你的第一份简历</p>
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
                  <p className="text-sm text-slate-400 mb-4">
                    更新于 {formatDate(resume.updated_at || resume.created_at)}
                  </p>
                  <div className="flex items-center justify-between">
                    <Link
                      to={`/resumes/${resume.id}`}
                      className="text-amber-400 hover:underline text-sm font-medium"
                    >
                      编辑简历
                    </Link>
                    <div className="flex gap-2 opacity-0 group-hover:opacity-100 transition-opacity">
                      <button
                        onClick={(e) => { e.preventDefault(); handleExportJson(resume.id, resume.title); }}
                        className="p-1 text-slate-400 hover:text-primary-400"
                        title="导出 JSON Resume 标准格式"
                      >
                        <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M10 20l4-16m4 4l4 4-4 4M6 16l-4-4 4-4" />
                        </svg>
                      </button>
                      <button
                        onClick={(e) => { e.preventDefault(); handleExport(resume.id, 'pdf'); }}
                        className="p-1 text-slate-400 hover:text-amber-400"
                        title="导出为PDF"
                      >
                        <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M4 16v1a3 3 0 003 3h10a3 3 0 003-3v-1m-4-4l-4 4m0 0l-4-4m4 4V4" />
                        </svg>
                      </button>
                      <button
                        onClick={(e) => { e.preventDefault(); handleDelete(resume.id); }}
                        className="p-1 text-slate-400 hover:text-red-500"
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
    </>
  );
}
