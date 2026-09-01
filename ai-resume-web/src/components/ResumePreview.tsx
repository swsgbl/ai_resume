/**
 * 简历实时预览组件
 */
import React, { useEffect, useState } from 'react';
import { Card } from '../components/ui/Card';
import { Spinner } from '../components/ui/Loading';
import type { ResumeContent } from '@ai-resume/shared/types';

interface ResumePreviewProps {
  content: ResumeContent;
  template?: 'modern' | 'classic' | 'minimal';
}

export const ResumePreview: React.FC<ResumePreviewProps> = ({
  content,
  template = 'modern'
}) => {
  const [mounted, setMounted] = useState(false);

  useEffect(() => {
    setMounted(true);
  }, []);

  if (!mounted) {
    return <Spinner />;
  }

  return (
    <Card className="w-full max-w-4xl mx-auto bg-white shadow-lg">
      {template === 'modern' ? (
        <ModernTemplate content={content} />
      ) : template === 'classic' ? (
        <ClassicTemplate content={content} />
      ) : (
        <MinimalTemplate content={content} />
      )}
    </Card>
  );
};

/**
 * 现代模板
 */
const ModernTemplate: React.FC<{ content: ResumePreviewProps['content'] }> = ({ content }) => {
  return (
    <div className="p-8">
      {/* 头部 */}
      <header className="mb-8 border-b-2 border-blue-600 pb-6">
        <h1 className="text-3xl font-bold text-gray-900 mb-2">
          {content.basic_info?.name || '姓名'}
        </h1>
        <div className="text-lg text-blue-600 font-semibold mb-3">
          {content.basic_info?.title || '职位'}
        </div>
        <div className="flex flex-wrap gap-4 text-sm text-gray-600">
          <span>📧 {content.basic_info?.email || 'email@example.com'}</span>
          <span>📱 {content.basic_info?.phone || '13800138000'}</span>
          <span>🎯 {content.basic_info?.job_intention || '求职意向'}</span>
        </div>
      </header>

      {/* 个人简介 */}
      {content.basic_info?.summary && (
        <section className="mb-6">
          <h2 className="text-xl font-bold text-gray-900 mb-3 flex items-center">
            <span className="bg-blue-600 text-white w-8 h-8 rounded-full flex items-center justify-center mr-3 text-sm">
              ★
            </span>
            个人简介
          </h2>
          <p className="text-gray-700 leading-relaxed">
            {content.basic_info.summary}
          </p>
        </section>
      )}

      {/* 自我介绍 */}
      {content.basic_info?.self_introduction && (
        <section className="mb-6">
          <h2 className="text-xl font-bold text-gray-900 mb-3 flex items-center">
            <span className="bg-blue-600 text-white w-8 h-8 rounded-full flex items-center justify-center mr-3 text-sm">
              👤
            </span>
            自我介绍
          </h2>
          <p className="text-gray-700 leading-relaxed">
            {content.basic_info.self_introduction}
          </p>
        </section>
      )}

      {/* 教育经历 */}
      {content.education && content.education.length > 0 && (
        <section className="mb-6">
          <h2 className="text-xl font-bold text-gray-900 mb-4 flex items-center">
            <span className="bg-blue-600 text-white w-8 h-8 rounded-full flex items-center justify-center mr-3 text-sm">
              🎓
            </span>
            教育经历
          </h2>
          <div className="space-y-4">
            {content.education.map((edu) => (
              <div key={`edu-${edu.school}-${edu.degree}-${edu.major}`} className="border-l-2 border-blue-400 pl-4">
                <div className="flex justify-between items-start mb-1">
                  <h3 className="font-semibold text-gray-900">
                    {edu.school}
                  </h3>
                  <span className="text-sm text-gray-500">
                    {edu.start_date} - {edu.end_date}
                  </span>
                </div>
                <div className="text-gray-700">
                  {edu.degree} · {edu.major}
                </div>
              </div>
            ))}
          </div>
        </section>
      )}

      {/* 工作经历 */}
      {content.work_experience && content.work_experience.length > 0 && (
        <section className="mb-6">
          <h2 className="text-xl font-bold text-gray-900 mb-4 flex items-center">
            <span className="bg-blue-600 text-white w-8 h-8 rounded-full flex items-center justify-center mr-3 text-sm">
              💼
            </span>
            工作经历
          </h2>
          <div className="space-y-4">
            {content.work_experience.map((work) => (
              <div key={`work-${work.company}-${work.position}`} className="border-l-2 border-blue-400 pl-4">
                <div className="flex justify-between items-start mb-1">
                  <h3 className="font-semibold text-gray-900">
                    {work.company}
                  </h3>
                  <span className="text-sm text-gray-500">
                    {work.start_date} - {work.end_date}
                  </span>
                </div>
                <div className="text-gray-700 mb-2">
                  {work.position}
                </div>
                {work.description && (
                  <p className="text-gray-600 text-sm leading-relaxed whitespace-pre-wrap">
                    {work.description}
                  </p>
                )}
              </div>
            ))}
          </div>
        </section>
      )}

      {/* 项目经验 */}
      {content.projects && content.projects.length > 0 && (
        <section className="mb-6">
          <h2 className="text-xl font-bold text-gray-900 mb-4 flex items-center">
            <span className="bg-blue-600 text-white w-8 h-8 rounded-full flex items-center justify-center mr-3 text-sm">
              🚀
            </span>
            项目经验
          </h2>
          <div className="space-y-4">
            {content.projects.map((project) => (
              <div key={`project-${project.name}`} className="border-l-2 border-blue-400 pl-4">
                <div className="flex justify-between items-start mb-1">
                  <h3 className="font-semibold text-gray-900">
                    {project.name}
                  </h3>
                  <span className="text-sm text-gray-600">
                    {project.role}
                  </span>
                </div>
                {project.description && (
                  <p className="text-gray-600 text-sm leading-relaxed whitespace-pre-wrap">
                    {project.description}
                  </p>
                )}
              </div>
            ))}
          </div>
        </section>
      )}

      {/* 技能列表 */}
      {content.skills && content.skills.length > 0 && (
        <section className="mb-6">
          <h2 className="text-xl font-bold text-gray-900 mb-4 flex items-center">
            <span className="bg-blue-600 text-white w-8 h-8 rounded-full flex items-center justify-center mr-3 text-sm">
              🛠️
            </span>
            技能
          </h2>
          <div className="flex flex-wrap gap-2">
            {content.skills.map((skill) => (
              <span
                key={`skill-${skill.id || skill.name}`}
                className="bg-blue-100 text-blue-800 px-3 py-1 rounded-full text-sm font-medium"
              >
                {skill.name}
              </span>
            ))}
          </div>
        </section>
      )}
    </div>
  );
};

/**
 * 经典模板
 */
const ClassicTemplate: React.FC<{ content: ResumePreviewProps['content'] }> = ({ content }) => {
  return (
    <div className="p-8 text-gray-900">
      <header className="mb-6">
        <h1 className="text-3xl font-bold mb-2">
          {content.basic_info?.name || '姓名'}
        </h1>
        <div className="text-lg mb-3">
          {content.basic_info?.title || '职位'}
        </div>
        <div className="text-sm text-gray-600 mb-1">
          {content.basic_info?.email} · {content.basic_info?.phone}
        </div>
        <div className="text-sm text-gray-600">
          求职意向: {content.basic_info?.job_intention}
        </div>
      </header>

      {content.basic_info?.summary && (
        <section className="mb-4">
          <h2 className="text-lg font-bold border-b border-gray-400 mb-2 pb-1">
            个人简介
          </h2>
          <p className="text-sm leading-relaxed">{content.basic_info.summary}</p>
        </section>
      )}

      {/* 其他部分... */}
    </div>
  );
};

/**
 * 简约模板
 */
const MinimalTemplate: React.FC<{ content: ResumePreviewProps['content'] }> = ({ content }) => {
  return (
    <div className="p-12">
      <header className="mb-8">
        <h1 className="text-2xl font-light text-gray-900 mb-2">
          {content.basic_info?.name || '姓名'}
        </h1>
        <div className="text-gray-600 text-sm">
          {content.basic_info?.email} · {content.basic_info?.phone}
        </div>
      </header>

      {content.basic_info?.summary && (
        <p className="text-sm text-gray-700 mb-6 leading-relaxed">
          {content.basic_info.summary}
        </p>
      )}

      {/* 其他部分... */}
    </div>
  );
};

export default ResumePreview;
