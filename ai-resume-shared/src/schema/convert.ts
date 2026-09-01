import type { ResumeContent } from '../types/index.js';
import { jsonResumeSchema, type JsonResume } from './jsonresume.js';

/**
 * 平台数据模型 <-> JSON Resume 开放标准 双向转换器
 * 转换是纯函数,无副作用,可安全用于导入导出与 Agent 管线。
 */

/** 平台简历内容 → JSON Resume */
export function toJsonResume(content: ResumeContent): JsonResume {
  const basics = content.basic_info;
  const profiles: NonNullable<NonNullable<JsonResume['basics']>['profiles']> = [];
  if (basics?.github) profiles.push({ network: 'github', url: basics.github });
  if (basics?.linkedin) profiles.push({ network: 'linkedin', url: basics.linkedin });
  if (basics?.website) profiles.push({ network: 'website', url: basics.website });

  return jsonResumeSchema.parse({
    basics: {
      name: basics?.name,
      label: basics?.job_intention || basics?.title,
      email: basics?.email,
      phone: basics?.phone,
      summary: basics?.self_introduction || basics?.summary,
      image: basics?.avatar,
      location: basics?.location ? { address: basics.location } : undefined,
      profiles: profiles && profiles.length > 0 ? profiles : undefined,
    },
    work: content.work_experience?.map((w) => ({
      name: w.company,
      position: w.position,
      startDate: w.start_date,
      endDate: w.is_current ? undefined : w.end_date,
      summary: w.description,
      highlights: w.achievements,
      location: w.location,
    })),
    education: content.education?.map((e) => ({
      institution: e.school,
      area: e.major,
      studyType: e.degree,
      startDate: e.start_date,
      endDate: e.end_date,
      score: e.gpa,
      courses: e.description ? [e.description] : undefined,
    })),
    projects: content.projects?.map((p) => ({
      name: p.name,
      description: p.description,
      highlights: p.highlights,
      keywords: p.tech_stack,
      startDate: p.start_date,
      endDate: p.end_date,
      url: p.link,
      role: p.role,
    })),
    skills: content.skills?.map((s) => ({
      name: s.name,
      level: s.level !== undefined ? ['入门', '熟悉', '熟练', '精通'][Math.min(Math.max(s.level, 0), 3)] : undefined,
      keywords: s.keywords,
      category: s.category,
    })),
    certificates: content.certifications?.map((c) => ({
      name: c.name,
      date: c.issue_date,
      issuer: c.issuer,
      url: c.url,
    })),
  });
}

/** JSON Resume → 平台简历内容(导入) */
export function fromJsonResume(resume: unknown): ResumeContent {
  const parsed = jsonResumeSchema.parse(resume);
  const basics = parsed.basics;
  const profile = (network: string) =>
    basics?.profiles?.find((p) => p.network === network)?.url;

  return {
    basic_info: {
      name: basics?.name,
      email: basics?.email,
      phone: basics?.phone,
      location: basics?.location?.address || basics?.location?.city,
      title: basics?.label,
      summary: basics?.summary,
      avatar: basics?.image,
      github: profile('github'),
      linkedin: profile('linkedin'),
      website: profile('website'),
      job_intention: basics?.label,
      self_introduction: basics?.summary,
    },
    work_experience: parsed.work?.map((w, i) => ({
      id: `w-${i}`,
      company: w.name,
      position: w.position,
      start_date: w.startDate,
      end_date: w.endDate,
      is_current: !w.endDate,
      location: w.location,
      description: w.summary,
      achievements: w.highlights,
    })),
    education: parsed.education?.map((e, i) => ({
      id: `e-${i}`,
      school: e.institution,
      degree: e.studyType ?? '',
      major: e.area,
      start_date: e.startDate,
      end_date: e.endDate,
      gpa: e.score,
      description: e.courses?.join('；'),
    })),
    projects: parsed.projects?.map((p, i) => ({
      id: `p-${i}`,
      name: p.name,
      role: p.role,
      start_date: p.startDate,
      end_date: p.endDate,
      description: p.description,
      tech_stack: p.keywords,
      highlights: p.highlights,
      link: p.url,
    })),
    skills: parsed.skills?.map((s, i) => ({
      id: `s-${i}`,
      name: s.name,
      category: s.category,
      level: { 入门: 0, 熟悉: 1, 熟练: 2, 精通: 3 }[s.level ?? ''] ?? undefined,
      keywords: s.keywords,
    })),
    certifications: parsed.certificates?.map((c, i) => ({
      id: `c-${i}`,
      name: c.name,
      issuer: c.issuer,
      issue_date: c.date,
      url: c.url,
    })),
  };
}

/** 转换并附带投递回流记录(OS 飞轮数据) */
export function extractApplications(resume: unknown): JsonResume['x-applications'] {
  return jsonResumeSchema.parse(resume)['x-applications'];
}
