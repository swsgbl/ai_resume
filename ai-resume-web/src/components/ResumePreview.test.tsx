import { describe, it, expect } from 'vitest';
import { render, screen } from '@testing-library/react';
import '@testing-library/jest-dom';
import ResumePreview from './ResumePreview';
import type { ResumeContent } from '@ai-resume/shared/types';

const mockContent: ResumeContent = {
  basic_info: {
    name: '测试用户',
    email: 'test@example.com',
    phone: '13800138000',
    location: '北京市',
    title: '软件工程师',
    summary: '一名热爱编程的软件工程师',
    job_intention: '前端开发工程师',
    self_introduction: '我有丰富的开发经验',
  },
  education: [
    {
      school: '北京大学',
      degree: '学士',
      major: '计算机科学与技术',
      start_date: '2018-09',
      end_date: '2022-06',
    },
  ],
  work_experience: [
    {
      company: '某科技公司',
      position: '前端工程师',
      start_date: '2022-07',
      end_date: '至今',
      description: '负责前端开发工作',
    },
  ],
  projects: [
    {
      name: '简历项目',
      role: '核心开发者',
      description: '使用 React 开发的简历系统',
      tech_stack: ['React', 'TypeScript', 'Vite'],
      link: 'https://example.com',
    },
  ],
  skills: [
    { name: 'JavaScript', level: 5 },
    { name: 'TypeScript', level: 5 },
    { name: 'React', level: 5 },
  ],
};

describe('ResumePreview Component', () => {
  it('渲染简历预览（现代模板）', () => {
    render(<ResumePreview content={mockContent} template="modern" />);
    expect(screen.getByText('测试用户')).toBeInTheDocument();
    expect(screen.getByText('软件工程师')).toBeInTheDocument();
    // 邮箱前面有 emoji 前缀，使用模糊匹配
    expect(screen.getByText((content) => content.includes('test@example.com'))).toBeInTheDocument();
  });

  it('渲染简历预览（经典模板）', () => {
    render(<ResumePreview content={mockContent} template="classic" />);
    expect(screen.getByText('测试用户')).toBeInTheDocument();
  });

  it('渲染简历预览（极简模板）', () => {
    render(<ResumePreview content={mockContent} template="minimal" />);
    expect(screen.getByText('测试用户')).toBeInTheDocument();
  });

  it('显示教育经历', () => {
    render(<ResumePreview content={mockContent} template="modern" />);
    expect(screen.getByText('北京大学')).toBeInTheDocument();
    // major 和 degree 用 · 分隔，使用模糊匹配
    expect(screen.getByText((_content, element) => {
      return element?.textContent === '学士 · 计算机科学与技术';
    })).toBeInTheDocument();
  });

  it('显示工作经历', () => {
    render(<ResumePreview content={mockContent} template="modern" />);
    expect(screen.getByText('某科技公司')).toBeInTheDocument();
    expect(screen.getByText('前端工程师')).toBeInTheDocument();
  });

  it('显示项目经历', () => {
    render(<ResumePreview content={mockContent} template="modern" />);
    expect(screen.getByText('简历项目')).toBeInTheDocument();
    expect(screen.getByText('核心开发者')).toBeInTheDocument();
  });

  it('显示技能', () => {
    render(<ResumePreview content={mockContent} template="modern" />);
    expect(screen.getByText('JavaScript')).toBeInTheDocument();
    expect(screen.getByText('TypeScript')).toBeInTheDocument();
    expect(screen.getByText('React')).toBeInTheDocument();
  });
});
