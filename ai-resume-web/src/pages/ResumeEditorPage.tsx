/**
 * 增强版简历编辑器页面
 * 支持：撤销/重做、富文本编辑、拖拽排序
 */
import { useState, useEffect } from 'react';

// 模板类型定义
type ResumeTemplate = 'modern' | 'classic' | 'minimal';

// 初始简历内容（移到组件外部避免重新创建）
const INITIAL_RESUME_CONTENT: ResumeContent = {
  basic_info: {
    name: '',
    email: '',
    phone: '',
    location: '',
    title: '',
    summary: '',
    job_intention: '',
    self_introduction: '',
  },
  education: [],
  work_experience: [],
  projects: [],
  skills: [],
};

import { useParams, useNavigate, Link } from 'react-router-dom';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import useUndo from 'use-undo';
import { api } from '@ai-resume/shared/api';
import type { ResumeContent, Education, WorkExperience, Project } from '@ai-resume/shared/types';
import { ResumePreview } from '../components/ResumePreview';
import { RichTextEditor, UndoRedoControls, UndoHistoryIndicator } from '../components/editor';
import { DndContext, closestCenter, PointerSensor, useSensor, useSensors, type DragEndEvent } from '@dnd-kit/core';
import { SortableContext, verticalListSortingStrategy, useSortable } from '@dnd-kit/sortable';
import { CSS } from '@dnd-kit/utilities';
import { GripVertical, Trash2, Plus, Save, Eye, EyeOff, Wand2, X } from 'lucide-react';

// 创建可拖拽的工作经历项
function DraggableWorkItem({ work, index, onRemove, onUpdate }: {
  work: WorkExperience;
  index: number;
  onRemove: (index: number) => void;
  onUpdate: (index: number, field: keyof WorkExperience, value: string) => void;
}) {
  const { attributes, listeners, setNodeRef, transform, transition, isDragging } = useSortable({
    id: `work-${index}`,
  });

  const style = {
    transform: CSS.Transform.toString(transform),
    transition,
    zIndex: isDragging ? 1 : 0,
  };

  return (
    <div ref={setNodeRef} style={style} className="relative group">
      <div className="card p-6 border-l-4 border-amber-500">
        {/* 拖拽手柄 */}
        <div
          className="absolute left-3 top-4 cursor-grab active:cursor-grabbing text-slate-500 hover:text-slate-300"
          {...attributes}
          {...listeners}
        >
          <GripVertical className="w-5 h-5" />
        </div>

        {/* 移除按钮 */}
        <button
          onClick={() => onRemove(index)}
          className="absolute right-4 top-4 text-slate-500 hover:text-red-400 opacity-0 group-hover:opacity-100 transition-opacity"
        >
          <Trash2 className="w-5 h-5" />
        </button>

        {/* 内容 */}
        <div className="pl-10 space-y-4">
          <div className="flex items-center gap-2 mb-2">
            <span className="bg-amber-500/20 text-amber-400 text-xs font-medium px-2 py-1 rounded">
              {index + 1}
            </span>
          </div>

          <div className="grid md:grid-cols-2 gap-4">
            <div>
              <label className="block text-sm font-medium text-slate-300 mb-1">公司</label>
              <input
                type="text"
                value={work.company || ''}
                onChange={(e) => onUpdate(index, 'company', e.target.value)}
                className="w-full px-3 py-2 border border-white/10 rounded-md focus:outline-none focus:ring-2 focus:ring-amber-500"
              />
            </div>
            <div>
              <label className="block text-sm font-medium text-slate-300 mb-1">职位</label>
              <input
                type="text"
                value={work.position || ''}
                onChange={(e) => onUpdate(index, 'position', e.target.value)}
                className="w-full px-3 py-2 border border-white/10 rounded-md focus:outline-none focus:ring-2 focus:ring-amber-500"
              />
            </div>
          </div>

          <div>
            <label className="block text-sm font-medium text-slate-300 mb-1">工作描述</label>
            <RichTextEditor
              content={work.description || ''}
              onChange={(html) => onUpdate(index, 'description', html)}
              placeholder="描述您的工作职责和成就..."
              className="min-h-[120px]"
            />
          </div>
        </div>
      </div>
    </div>
  );
}

// 创建可拖拽的教育经历项
function DraggableEduItem({ edu, index, onRemove, onUpdate }: {
  edu: Education;
  index: number;
  onRemove: (index: number) => void;
  onUpdate: (index: number, field: keyof Education, value: string) => void;
}) {
  const { attributes, listeners, setNodeRef, transform, transition, isDragging } = useSortable({
    id: `edu-${index}`,
  });

  const style = {
    transform: CSS.Transform.toString(transform),
    transition,
    zIndex: isDragging ? 1 : 0,
  };

  return (
    <div ref={setNodeRef} style={style} className="relative group">
      <div className="card p-6 border-l-4 border-emerald-500">
        {/* 拖拽手柄 */}
        <div
          className="absolute left-3 top-4 cursor-grab active:cursor-grabbing text-slate-500 hover:text-slate-300"
          {...attributes}
          {...listeners}
        >
          <GripVertical className="w-5 h-5" />
        </div>

        {/* 移除按钮 */}
        <button
          onClick={() => onRemove(index)}
          className="absolute right-4 top-4 text-slate-500 hover:text-red-400 opacity-0 group-hover:opacity-100 transition-opacity"
        >
          <Trash2 className="w-5 h-5" />
        </button>

        {/* 内容 */}
        <div className="pl-10 space-y-4">
          <div className="flex items-center gap-2 mb-2">
            <span className="bg-emerald-500/20 text-emerald-400 text-xs font-medium px-2 py-1 rounded">
              {index + 1}
            </span>
          </div>

          <div className="grid md:grid-cols-3 gap-4">
            <div>
              <label className="block text-sm font-medium text-slate-300 mb-1">学校</label>
              <input
                type="text"
                value={edu.school || ''}
                onChange={(e) => onUpdate(index, 'school', e.target.value)}
                className="w-full px-3 py-2 border border-white/10 rounded-md focus:outline-none focus:ring-2 focus:ring-amber-500"
              />
            </div>
            <div>
              <label className="block text-sm font-medium text-slate-300 mb-1">学位</label>
              <input
                type="text"
                value={edu.degree || ''}
                onChange={(e) => onUpdate(index, 'degree', e.target.value)}
                className="w-full px-3 py-2 border border-white/10 rounded-md focus:outline-none focus:ring-2 focus:ring-amber-500"
              />
            </div>
            <div>
              <label className="block text-sm font-medium text-slate-300 mb-1">专业</label>
              <input
                type="text"
                value={edu.major || ''}
                onChange={(e) => onUpdate(index, 'major', e.target.value)}
                className="w-full px-3 py-2 border border-white/10 rounded-md focus:outline-none focus:ring-2 focus:ring-amber-500"
              />
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}

// 创建可拖拽的项目经历项
function DraggableProjectItem({ project, index, onRemove, onUpdate }: {
  project: Project;
  index: number;
  onRemove: (index: number) => void;
  onUpdate: (index: number, field: keyof Project, value: string | string[]) => void;
}) {
  const { attributes, listeners, setNodeRef, transform, transition, isDragging } = useSortable({
    id: `project-${index}`,
  });

  const style = {
    transform: CSS.Transform.toString(transform),
    transition,
    zIndex: isDragging ? 1 : 0,
  };

  return (
    <div ref={setNodeRef} style={style} className="relative group">
      <div className="card p-6 border-l-4 border-emerald-500">
        {/* 拖拽手柄 */}
        <div
          className="absolute left-3 top-4 cursor-grab active:cursor-grabbing text-slate-500 hover:text-slate-300"
          {...attributes}
          {...listeners}
        >
          <GripVertical className="w-5 h-5" />
        </div>

        {/* 移除按钮 */}
        <button
          onClick={() => onRemove(index)}
          className="absolute right-4 top-4 text-slate-500 hover:text-red-400 opacity-0 group-hover:opacity-100 transition-opacity"
        >
          <Trash2 className="w-5 h-5" />
        </button>

        {/* 内容 */}
        <div className="pl-10 space-y-4">
          <div className="flex items-center gap-2 mb-2">
            <span className="bg-emerald-500/20 text-emerald-400 text-xs font-medium px-2 py-1 rounded">
              {index + 1}
            </span>
          </div>

          <div className="grid md:grid-cols-2 gap-4">
            <div>
              <label className="block text-sm font-medium text-slate-300 mb-1">项目名称</label>
              <input
                type="text"
                value={project.name || ''}
                onChange={(e) => onUpdate(index, 'name', e.target.value)}
                className="w-full px-3 py-2 border border-white/10 rounded-md focus:outline-none focus:ring-2 focus:ring-amber-500"
              />
            </div>
            <div>
              <label className="block text-sm font-medium text-slate-300 mb-1">担任角色</label>
              <input
                type="text"
                value={project.role || ''}
                onChange={(e) => onUpdate(index, 'role', e.target.value)}
                className="w-full px-3 py-2 border border-white/10 rounded-md focus:outline-none focus:ring-2 focus:ring-amber-500"
              />
            </div>
          </div>

          <div>
            <label className="block text-sm font-medium text-slate-300 mb-1">项目描述</label>
            <RichTextEditor
              content={project.description || ''}
              onChange={(html) => onUpdate(index, 'description', html)}
              placeholder="描述项目的目标、您的贡献和成果..."
              className="min-h-[120px]"
            />
          </div>
        </div>
      </div>
    </div>
  );
}

// 主页面组件
export default function ResumeEditorPage() {
  const { id } = useParams<{ id: string }>();
  const navigate = useNavigate();
  const queryClient = useQueryClient();
  const isNew = id === 'new';

  const [activeTab, setActiveTab] = useState(0);
  const [title, setTitle] = useState('我的简历');
  const [isSaving, setIsSaving] = useState(false);
  const [isGenerating, setIsGenerating] = useState(false);

  // 实时预览相关状态
  const [showPreview, setShowPreview] = useState(false);
  const [previewTemplate, setPreviewTemplate] = useState<ResumeTemplate>('modern');

  const [content, setContent] = useState<ResumeContent>(INITIAL_RESUME_CONTENT);

  // 撤销/重做功能
  const [, { set: setUndoState, reset: resetUndo, undo: undoAction, redo: redoAction, canUndo, canRedo }] = useUndo(INITIAL_RESUME_CONTENT);

  // 同步 content 到 undo state
  useEffect(() => {
    setUndoState(content);
  }, [content, setUndoState]);

  // 获取简历详情
  const { data: resume, isLoading } = useQuery({
    queryKey: ['resume', id],
    queryFn: () => api.resume.getResume(Number(id)),
    enabled: !isNew,
  });

  useEffect(() => {
    if (resume) {
      setTitle(resume.title);
      const resumeContent = resume.content ?? INITIAL_RESUME_CONTENT;
      setContent(resumeContent);
      resetUndo(resumeContent);
    }
  }, [resume, resetUndo]);

  // 保存 mutation
  const saveMutation = useMutation({
    mutationFn: async (data: { title: string; content: ResumeContent }) => {
      if (isNew) {
        return api.resume.createResume(data);
      }
      return api.resume.updateResume(Number(id), data);
    },
    onSuccess: (data) => {
      setIsSaving(false);
      queryClient.invalidateQueries({ queryKey: ['resumes'] });
      if (isNew) {
        navigate(`/resumes/${data.id}`, { replace: true });
      }
    },
    onError: () => {
      setIsSaving(false);
    },
  });

  // AI 生成 mutation
  const generateMutation = useMutation({
    mutationFn: async () => {
      if (isNew) return;
      return api.resume.aiGenerateResume(Number(id), {
        target_position: content.basic_info?.job_intention || '软件工程师',
      });
    },
    onSuccess: (data) => {
      setIsGenerating(false);
      const newContent = (data?.content ?? {}) as ResumeContent;
      setContent(newContent);
      resetUndo(newContent);
    },
    onError: () => {
      setIsGenerating(false);
    },
  });

  // 拖拽传感器
  const sensors = useSensors(useSensor(PointerSensor));

  // 处理拖拽结束
  const handleDragEnd = (section: 'work_experience' | 'education' | 'projects') =>
    (event: DragEndEvent) => {
      const { active, over } = event;
      if (!over || active.id === over.id) return;

      const items = content[section] || [];
      const oldIndex = parseInt(String(active.id).split('-')[1]);
      const newIndex = parseInt(String(over.id).split('-')[1]);

      const newItems = [...items];
      const [removed] = newItems.splice(oldIndex, 1);
      newItems.splice(newIndex, 0, removed);

      setContent({
        ...content,
        [section]: newItems,
      });
    };

  const handleSave = async () => {
    setIsSaving(true);
    try {
      await saveMutation.mutateAsync({ title, content });
    } catch (error) {
      alert(error instanceof Error ? error.message : '保存失败');
    }
  };

  const handleAIGenerate = async () => {
    if (isNew) {
      alert('请先保存简历');
      return;
    }
    if (!content.basic_info?.job_intention) {
      alert('请先填写求职意向');
      setActiveTab(0);
      return;
    }
    setIsGenerating(true);
    try {
      await generateMutation.mutateAsync();
    } catch (error) {
      alert(error instanceof Error ? error.message : 'AI 生成失败');
    }
  };

  // 工作经历操作
  const addWork = () => {
    const newContent = {
      ...content,
      work_experience: [...(content.work_experience || []), { company: '', position: '', description: '' }],
    };
    setContent(newContent);
  };

  const updateWork = (index: number, field: keyof WorkExperience, value: string) => {
    const newWork = [...(content.work_experience || [])];
    newWork[index] = { ...newWork[index], [field]: value };
    setContent({ ...content, work_experience: newWork });
  };

  const removeWork = (index: number) => {
    setContent({
      ...content,
      work_experience: content.work_experience?.filter((_, i) => i !== index) || [],
    });
  };

  // 教育经历操作
  const addEducation = () => {
    setContent({
      ...content,
      education: [...(content.education || []), { school: '', degree: '', major: '' }],
    });
  };

  const updateEducation = (index: number, field: keyof Education, value: string) => {
    const newEducation = [...(content.education || [])];
    newEducation[index] = { ...newEducation[index], [field]: value };
    setContent({ ...content, education: newEducation });
  };

  const removeEducation = (index: number) => {
    setContent({
      ...content,
      education: content.education?.filter((_, i) => i !== index) || [],
    });
  };

  // 项目经历操作
  const addProject = () => {
    setContent({
      ...content,
      projects: [...(content.projects || []), { name: '', description: '', role: '' }],
    });
  };

  const updateProject = (index: number, field: keyof Project, value: string | string[]) => {
    const newProjects = [...(content.projects || [])];
    newProjects[index] = { ...newProjects[index], [field]: value };
    setContent({ ...content, projects: newProjects });
  };

  const removeProject = (index: number) => {
    setContent({
      ...content,
      projects: content.projects?.filter((_, i) => i !== index) || [],
    });
  };

  // 技能操作
  const addSkill = () => {
    const skill = prompt('请输入技能名称');
    if (skill) {
      setContent({
        ...content,
        skills: [...(content.skills || []), { name: skill }],
      });
    }
  };

  const removeSkill = (index: number) => {
    setContent({
      ...content,
      skills: content.skills?.filter((_, i) => i !== index) || [],
    });
  };

  // 快捷键支持
  useEffect(() => {
    const handleKeyDown = (e: KeyboardEvent) => {
      if ((e.ctrlKey || e.metaKey) && e.key === 'z') {
        e.preventDefault();
        if (e.shiftKey) {
          if (canRedo) redoAction();
        } else {
          if (canUndo) undoAction();
        }
      }
    };
    window.addEventListener('keydown', handleKeyDown);
    return () => window.removeEventListener('keydown', handleKeyDown);
  }, [canUndo, canRedo, undoAction, redoAction]);

  const tabs = [
    { label: '基本信息', icon: '👤' },
    { label: '教育经历', icon: '🎓' },
    { label: '工作经历', icon: '💼' },
    { label: '项目经历', icon: '🚀' },
    { label: '技能特长', icon: '⚡' },
  ];

  if (isLoading && !isNew) {
    return (
      <div className="min-h-screen flex items-center justify-center">
        <div className="w-8 h-8 border-4 border-amber-200 border-t-amber-500 rounded-full animate-spin" />
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-slate-950 flex flex-col">
      {/* 顶部栏 */}
      <header className="bg-slate-900/80 backdrop-blur-sm border-b border-white/10 sticky top-0 z-10">
        <div className="max-w-7xl mx-auto px-4 py-3">
          <div className="flex items-center justify-between">
            <Link to="/dashboard" className="text-xl font-bold text-amber-400">
              AI 简历
            </Link>

            <div className="flex items-center gap-2 flex-1 mx-8">
              <input
                type="text"
                value={title}
                onChange={(e) => setTitle(e.target.value)}
                className="text-center font-medium text-lg border-b-2 border-transparent hover:border-white/10 focus:border-amber-500 focus:outline-none px-2 py-1"
              />
            </div>

            <div className="flex items-center gap-2">
              {/* 撤销/重做 */}
              <UndoRedoControls
                canUndo={canUndo ?? false}
                canRedo={canRedo ?? false}
                onUndo={undoAction}
                onRedo={redoAction}
              />

              {/* 预览切换按钮 */}
              <button
                onClick={() => setShowPreview(!showPreview)}
                className={`btn flex items-center gap-2 ${
                  showPreview ? 'btn-primary' : 'btn-secondary'
                }`}
              >
                {showPreview ? <EyeOff className="w-4 h-4" /> : <Eye className="w-4 h-4" />}
                {showPreview ? '编辑' : '预览'}
              </button>

              {/* 模板选择 */}
              {showPreview && (
                <select
                  value={previewTemplate}
                  onChange={(e) => setPreviewTemplate(e.target.value as ResumeTemplate)}
                  className="btn btn-secondary px-3 py-2"
                >
                  <option value="modern">现代模板</option>
                  <option value="classic">经典模板</option>
                  <option value="minimal">简约模板</option>
                </select>
              )}

              <button
                onClick={handleAIGenerate}
                disabled={isGenerating || isNew}
                className="btn btn-secondary flex items-center gap-2"
              >
                <Wand2 className="w-4 h-4" />
                {isGenerating ? '生成中...' : 'AI 生成'}
              </button>

              <button
                onClick={handleSave}
                disabled={isSaving}
                className="btn btn-primary flex items-center gap-2"
              >
                {isSaving ? (
                  <>
                    <div className="w-4 h-4 border-2 border-white border-t-transparent rounded-full animate-spin" />
                    保存中
                  </>
                ) : (
                  <>
                    <Save className="w-4 h-4" />
                    保存
                  </>
                )}
              </button>
            </div>
          </div>

          {/* 历史记录指示器 */}
          <div className="mt-2 flex justify-center">
            <UndoHistoryIndicator pastLength={canUndo ? 1 : 0} futureLength={canRedo ? 1 : 0} />
          </div>
        </div>
      </header>

      {/* 预览模式 */}
      {showPreview ? (
        <main className="flex-1 overflow-auto bg-slate-900 p-8">
          <ResumePreview content={content} template={previewTemplate} />
        </main>
      ) : (
        <>
          {/* 标签页导航 */}
          <div className="bg-slate-900/80 border-b border-white/10">
            <div className="max-w-7xl mx-auto px-4">
              <div className="flex gap-1">
                {tabs.map((tab) => (
                  <button
                    key={tab.label}
                    onClick={() => setActiveTab(tabs.indexOf(tab))}
                    className={`px-6 py-3 font-medium transition-colors ${
                      activeTab === tabs.indexOf(tab)
                        ? 'text-amber-400 border-b-2 border-amber-500'
                        : 'text-slate-400 hover:text-slate-200'
                    }`}
                  >
                    <span className="mr-1">{tab.icon}</span>
                    {tab.label}
                  </button>
                ))}
              </div>
            </div>
          </div>

          {/* 内容区域 */}
          <main className="flex-1 overflow-auto">
            <div className="max-w-4xl mx-auto px-4 py-8">
              {activeTab === 0 && (
                <div className="space-y-6">
                  <h2 className="text-xl font-semibold text-slate-100 mb-4">基本信息</h2>
                  <div className="card p-6 space-y-4">
                    <div className="grid md:grid-cols-2 gap-4">
                      <div>
                        <label className="block text-sm font-medium text-slate-300 mb-1">姓名</label>
                        <input
                          type="text"
                          value={content.basic_info?.name || ''}
                          onChange={(e) => setContent({
                            ...content,
                            basic_info: { ...content.basic_info, name: e.target.value },
                          })}
                          className="w-full px-3 py-2 border border-white/10 rounded-md focus:outline-none focus:ring-2 focus:ring-amber-500"
                        />
                      </div>
                      <div>
                        <label className="block text-sm font-medium text-slate-300 mb-1">邮箱</label>
                        <input
                          type="email"
                          value={content.basic_info?.email || ''}
                          onChange={(e) => setContent({
                            ...content,
                            basic_info: { ...content.basic_info, email: e.target.value },
                          })}
                          className="w-full px-3 py-2 border border-white/10 rounded-md focus:outline-none focus:ring-2 focus:ring-amber-500"
                        />
                      </div>
                      <div>
                        <label className="block text-sm font-medium text-slate-300 mb-1">电话</label>
                        <input
                          type="tel"
                          value={content.basic_info?.phone || ''}
                          onChange={(e) => setContent({
                            ...content,
                            basic_info: { ...content.basic_info, phone: e.target.value },
                          })}
                          className="w-full px-3 py-2 border border-white/10 rounded-md focus:outline-none focus:ring-2 focus:ring-amber-500"
                        />
                      </div>
                      <div>
                        <label className="block text-sm font-medium text-slate-300 mb-1">地点</label>
                        <input
                          type="text"
                          value={content.basic_info?.location || ''}
                          onChange={(e) => setContent({
                            ...content,
                            basic_info: { ...content.basic_info, location: e.target.value },
                          })}
                          className="w-full px-3 py-2 border border-white/10 rounded-md focus:outline-none focus:ring-2 focus:ring-amber-500"
                        />
                      </div>
                      <div>
                        <label className="block text-sm font-medium text-slate-300 mb-1">职位</label>
                        <input
                          type="text"
                          value={content.basic_info?.title || ''}
                          onChange={(e) => setContent({
                            ...content,
                            basic_info: { ...content.basic_info, title: e.target.value },
                          })}
                          className="w-full px-3 py-2 border border-white/10 rounded-md focus:outline-none focus:ring-2 focus:ring-amber-500"
                        />
                      </div>
                      <div>
                        <label className="block text-sm font-medium text-slate-300 mb-1">求职意向</label>
                        <input
                          type="text"
                          value={content.basic_info?.job_intention || ''}
                          onChange={(e) => setContent({
                            ...content,
                            basic_info: { ...content.basic_info, job_intention: e.target.value },
                          })}
                          className="w-full px-3 py-2 border border-white/10 rounded-md focus:outline-none focus:ring-2 focus:ring-amber-500"
                        />
                      </div>
                    </div>
                    <div>
                      <label className="block text-sm font-medium text-slate-300 mb-1">个人简介</label>
                      <RichTextEditor
                        content={content.basic_info?.summary || ''}
                        onChange={(html) => setContent({
                          ...content,
                          basic_info: { ...content.basic_info, summary: html },
                        })}
                        placeholder="简要介绍您的专业背景和职业目标..."
                        className="min-h-[100px]"
                      />
                    </div>
                    <div>
                      <label className="block text-sm font-medium text-slate-300 mb-1">自我介绍</label>
                      <RichTextEditor
                        content={content.basic_info?.self_introduction || ''}
                        onChange={(html) => setContent({
                          ...content,
                          basic_info: { ...content.basic_info, self_introduction: html },
                        })}
                        placeholder="详细描述您的优势、经验和职业期望..."
                        className="min-h-[120px]"
                      />
                    </div>
                  </div>
                </div>
              )}

              {activeTab === 1 && (
                <div className="space-y-6">
                  <div className="flex justify-between items-center mb-4">
                    <h2 className="text-xl font-semibold text-slate-100">教育经历</h2>
                    <button onClick={addEducation} className="btn btn-primary flex items-center gap-2">
                      <Plus className="w-4 h-4" /> 添加
                    </button>
                  </div>

                  <DndContext
                    sensors={sensors}
                    collisionDetection={closestCenter}
                    onDragEnd={handleDragEnd('education')}
                  >
                    <SortableContext
                      items={(content.education || []).map((_, i) => `edu-${i}`)}
                      strategy={verticalListSortingStrategy}
                    >
                      <div className="space-y-4">
                        {(content.education || []).map((edu, index) => (
                          <DraggableEduItem
                            key={`edu-${index}-${edu.school || ''}`}
                            edu={edu}
                            index={index}
                            onUpdate={updateEducation}
                            onRemove={removeEducation}
                          />
                        ))}
                      </div>
                    </SortableContext>
                  </DndContext>
                </div>
              )}

              {activeTab === 2 && (
                <div className="space-y-6">
                  <div className="flex justify-between items-center mb-4">
                    <h2 className="text-xl font-semibold text-slate-100">工作经历</h2>
                    <button onClick={addWork} className="btn btn-primary flex items-center gap-2">
                      <Plus className="w-4 h-4" /> 添加
                    </button>
                  </div>

                  <DndContext
                    sensors={sensors}
                    collisionDetection={closestCenter}
                    onDragEnd={handleDragEnd('work_experience')}
                  >
                    <SortableContext
                      items={(content.work_experience || []).map((_, i) => `work-${i}`)}
                      strategy={verticalListSortingStrategy}
                    >
                      <div className="space-y-4">
                        {(content.work_experience || []).map((work, index) => (
                          <DraggableWorkItem
                            key={`work-${index}-${work.company || ''}`}
                            work={work}
                            index={index}
                            onUpdate={updateWork}
                            onRemove={removeWork}
                          />
                        ))}
                      </div>
                    </SortableContext>
                  </DndContext>
                </div>
              )}

              {activeTab === 3 && (
                <div className="space-y-6">
                  <div className="flex justify-between items-center mb-4">
                    <h2 className="text-xl font-semibold text-slate-100">项目经历</h2>
                    <button onClick={addProject} className="btn btn-primary flex items-center gap-2">
                      <Plus className="w-4 h-4" /> 添加
                    </button>
                  </div>

                  <DndContext
                    sensors={sensors}
                    collisionDetection={closestCenter}
                    onDragEnd={handleDragEnd('projects')}
                  >
                    <SortableContext
                      items={(content.projects || []).map((_, i) => `project-${i}`)}
                      strategy={verticalListSortingStrategy}
                    >
                      <div className="space-y-4">
                        {(content.projects || []).map((project, index) => (
                          <DraggableProjectItem
                            key={`project-${index}-${project.name || ''}`}
                            project={project}
                            index={index}
                            onUpdate={updateProject}
                            onRemove={removeProject}
                          />
                        ))}
                      </div>
                    </SortableContext>
                  </DndContext>
                </div>
              )}

              {activeTab === 4 && (
                <div className="space-y-6">
                  <div className="flex justify-between items-center mb-4">
                    <h2 className="text-xl font-semibold text-slate-100">技能特长</h2>
                    <button onClick={addSkill} className="btn btn-primary flex items-center gap-2">
                      <Plus className="w-4 h-4" /> 添加
                    </button>
                  </div>
                  <div className="card p-6">
                    <div className="flex flex-wrap gap-2">
                      {content.skills?.map((skill, index) => (
                        <span
                          key={`skill-${index}-${skill.name || ''}`}
                          className="bg-amber-500/20 text-amber-300 px-3 py-1 rounded-full text-sm font-medium flex items-center gap-2"
                        >
                          {skill.name}
                          <button
                            onClick={() => removeSkill(index)}
                            className="text-red-600 hover:text-red-800"
                          >
                            <X className="w-3 h-3" />
                          </button>
                        </span>
                      ))}
                      {(!content.skills || content.skills.length === 0) && (
                        <p className="text-slate-500">暂无技能，点击上方按钮添加</p>
                      )}
                    </div>
                  </div>
                </div>
              )}
            </div>
          </main>
        </>
      )}
    </div>
  );
}
