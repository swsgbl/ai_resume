import { useState } from 'react';
import { useQuery } from '@tanstack/react-query';
import { Link } from 'react-router-dom';
import { api } from '@ai-resume/shared/api';
import type { TemplateFilter } from '@ai-resume/shared/types';

export default function TemplatesPage() {
  const [filter, setFilter] = useState<TemplateFilter>({ page: 1, page_size: 20 });
  const [selectedCategory, setSelectedCategory] = useState<string>('全部');
  const [selectedLevel, setSelectedLevel] = useState<string>('');
  const [searchQuery, setSearchQuery] = useState('');

  const categories = ['全部', '互联网', '金融', '教育', '医疗', '设计', '销售', '行政'];
  const levels = ['全部', '应届生', '初级', '中级', '高级'];

  const { data, isLoading, refetch } = useQuery({
    queryKey: ['templates', filter],
    queryFn: () => api.template.getTemplates(filter),
  });

  const templates = data?.data ?? [];

  const handleSearch = () => {
    setFilter({
      ...filter,
      search: searchQuery || undefined,
      category: selectedCategory === '全部' ? undefined : selectedCategory,
      level: selectedLevel === '全部' ? undefined : selectedLevel,
    });
  };

  const handleFavorite = async (id: number, isFavorited: boolean) => {
    try {
      if (isFavorited) {
        await api.template.unfavoriteTemplate(id);
      } else {
        await api.template.favoriteTemplate(id);
      }
      refetch();
    } catch (error) {
      alert(error instanceof Error ? error.message : '操作失败');
    }
  };

  const handleUseTemplate = async (templateId: number, isPremium: boolean, templateName: string) => {
    if (isPremium) {
      alert('该模板需要高级会员');
      return;
    }

    try {
      const resume = await api.resume.createResume({
        title: `使用${templateName}创建的简历`,
        template_id: templateId,
      });
      window.location.href = `/resumes/${resume.id}`;
    } catch (error) {
      alert(error instanceof Error ? error.message : '创建失败');
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
              <Link to="/resumes" className="text-gray-700 hover:text-primary-600">
                我的简历
              </Link>
              <Link to="/profile" className="text-gray-700 hover:text-primary-600">
                个人中心
              </Link>
            </div>
          </div>
        </div>
      </header>

      <main className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        <h1 className="text-2xl font-bold mb-6">模板库</h1>

        {/* 搜索和筛选 */}
        <div className="card p-4 mb-6">
          <div className="flex flex-col md:flex-row gap-4">
            <input
              type="text"
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              onKeyDown={(e) => e.key === 'Enter' && handleSearch()}
              className="input flex-1"
              placeholder="搜索模板..."
            />
            <button onClick={handleSearch} className="btn btn-primary px-8">
              搜索
            </button>
          </div>

          {/* 分类筛选 */}
          <div className="mt-4">
            <h3 className="text-sm font-medium text-gray-700 mb-2">行业分类</h3>
            <div className="flex flex-wrap gap-2">
              {categories.map((category) => (
                <button
                  key={category}
                  onClick={() => {
                    setSelectedCategory(category);
                    handleSearch();
                  }}
                  className={`px-4 py-2 rounded-lg text-sm transition-colors ${
                    selectedCategory === category
                      ? 'bg-primary-600 text-white'
                      : 'bg-gray-100 text-gray-700 hover:bg-gray-200'
                  }`}
                >
                  {category}
                </button>
              ))}
            </div>
          </div>

          {/* 职级筛选 */}
          <div className="mt-4">
            <h3 className="text-sm font-medium text-gray-700 mb-2">经验水平</h3>
            <div className="flex flex-wrap gap-2">
              {levels.map((level) => (
                <button
                  key={level}
                  onClick={() => {
                    setSelectedLevel(level);
                    handleSearch();
                  }}
                  className={`px-4 py-2 rounded-lg text-sm transition-colors ${
                    selectedLevel === level
                      ? 'bg-primary-600 text-white'
                      : 'bg-gray-100 text-gray-700 hover:bg-gray-200'
                  }`}
                >
                  {level}
                </button>
              ))}
            </div>
          </div>
        </div>

        {/* 模板网格 */}
        {isLoading ? (
          <div className="text-center py-12">
            <div className="inline-block w-8 h-8 border-4 border-primary-200 border-t-primary-600 rounded-full animate-spin" />
          </div>
        ) : templates.length === 0 ? (
          <div className="card p-12 text-center">
            <p className="text-gray-500">暂无模板</p>
          </div>
        ) : (
          <div className="grid md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-6">
            {templates.map((template) => (
              <div key={template.id} className="card overflow-hidden group">
                {/* 缩略图 */}
                <div className="aspect-[3/4] bg-gray-100 relative">
                  {template.thumbnail_url ? (
                    <img
                      src={template.thumbnail_url}
                      alt={template.name}
                      className="w-full h-full object-cover"
                    />
                  ) : (
                    <div className="w-full h-full flex items-center justify-center">
                      <svg className="w-16 h-16 text-gray-300" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z" />
                      </svg>
                    </div>
                  )}
                  {template.is_premium && (
                    <div className="absolute top-2 right-2 bg-amber-500 text-white text-xs px-2 py-1 rounded">
                      PRO
                    </div>
                  )}
                </div>

                {/* 信息 */}
                <div className="p-4">
                  <h3 className="font-semibold mb-1 truncate">{template.name}</h3>
                  <p className="text-sm text-gray-500 mb-3">
                    {template.use_count} 人使用
                  </p>

                  <div className="flex items-center justify-between">
                    <button
                      onClick={() => handleFavorite(template.id, template.is_favorited ?? false)}
                      className="p-2 text-gray-400 hover:text-red-500 transition-colors"
                    >
                      <svg
                        className={`w-5 h-5 ${template.is_favorited ? 'fill-red-500 text-red-500' : ''}`}
                        fill="none"
                        stroke="currentColor"
                        viewBox="0 0 24 24"
                      >
                        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M4.318 6.318a4.5 4.5 0 000 6.364L12 20.364l7.682-7.682a4.5 4.5 0 00-6.364-6.364L12 7.636l-1.318-1.318a4.5 4.5 0 00-6.364 0z" />
                      </svg>
                    </button>
                    <button
                      onClick={() => handleUseTemplate(template.id, template.is_premium ?? false, template.name)}
                      className="btn btn-primary text-sm py-1 px-4"
                    >
                      使用
                    </button>
                  </div>
                </div>
              </div>
            ))}
          </div>
        )}
      </main>
    </div>
  );
}
