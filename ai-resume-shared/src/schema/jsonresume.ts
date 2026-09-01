import { z } from 'zod';

/**
 * JSON Resume 开放标准(schema.org 兼容)的 Zod 定义
 * https://jsonresume.org/schema — AI 简历 OS 的数据核心
 *
 * 原则:标准字段严格对齐 JSON Resume v1.0,便于接入 52+ 主题生态;
 * 平台特有数据(投递回流等)收敛在 x_applications 扩展命名空间。
 */

export const jsonResumeBasics = z.object({
  name: z.string().optional(),
  label: z.string().optional(), // 求职意向/头衔
  image: z.string().optional(),
  email: z.string().optional(),
  phone: z.string().optional(),
  url: z.string().optional(),
  summary: z.string().optional(),
  location: z
    .object({
      address: z.string().optional(),
      city: z.string().optional(),
      region: z.string().optional(),
    })
    .optional(),
  profiles: z
    .array(
      z.object({
        network: z.string(), // github / linkedin / website
        url: z.string(),
        username: z.string().optional(),
      })
    )
    .optional(),
});

export const jsonResumeWork = z.object({
  name: z.string(), // 公司
  position: z.string(),
  url: z.string().optional(),
  startDate: z.string().optional(), // YYYY-MM-DD
  endDate: z.string().optional(),
  summary: z.string().optional(),
  highlights: z.array(z.string()).optional(),
  location: z.string().optional(),
});

export const jsonResumeEducation = z.object({
  institution: z.string(),
  url: z.string().optional(),
  area: z.string().optional(), // 专业
  studyType: z.string().optional(), // 学位
  startDate: z.string().optional(),
  endDate: z.string().optional(),
  score: z.string().optional(), // GPA
  courses: z.array(z.string()).optional(),
});

export const jsonResumeProject = z.object({
  name: z.string(),
  description: z.string().optional(),
  highlights: z.array(z.string()).optional(),
  keywords: z.array(z.string()).optional(), // 技术栈
  startDate: z.string().optional(),
  endDate: z.string().optional(),
  url: z.string().optional(),
  role: z.string().optional(),
});

export const jsonResumeSkill = z.object({
  name: z.string(),
  level: z.string().optional(), // master / advanced / proficient
  keywords: z.array(z.string()).optional(),
  category: z.string().optional(),
});

export const jsonResumeCertificate = z.object({
  name: z.string(),
  date: z.string().optional(),
  issuer: z.string().optional(),
  url: z.string().optional(),
});

/**
 * 自进化扩展:投递回流记录
 * AI 简历 OS 的飞轮 —— 每次投递的结果沉淀回数据核心,
 * 支撑"匹配分 vs 真实结果"的校准迭代。
 */
export const applicationOutcome = z.enum([
  'submitted', // 已投递
  'screening', // 简历评估中
  'interview', // 获得面试
  'offer', // 收到 offer
  'rejected', // 被拒
  'closed', // 流程关闭
]);

export const jsonResumeApplication = z.object({
  id: z.string(),
  company: z.string(),
  position: z.string(),
  appliedAt: z.string(), // YYYY-MM-DD
  outcome: applicationOutcome,
  /** 投递时的 AI 匹配分(0-100),用于校准 */
  matchScore: z.number().min(0).max(100).optional(),
  jdSummary: z.string().optional(),
  notes: z.string().optional(),
});

export const jsonResumeSchema = z.object({
  $schema: z.string().optional(),
  basics: jsonResumeBasics.optional(),
  work: z.array(jsonResumeWork).optional(),
  education: z.array(jsonResumeEducation).optional(),
  projects: z.array(jsonResumeProject).optional(),
  skills: z.array(jsonResumeSkill).optional(),
  certificates: z.array(jsonResumeCertificate).optional(),
  /** 平台扩展命名空间(x- 前缀符合 JSON Resume 扩展惯例) */
  'x-applications': z.array(jsonResumeApplication).optional(),
});

export type JsonResume = z.infer<typeof jsonResumeSchema>;
export type JsonResumeApplication = z.infer<typeof jsonResumeApplication>;
export type ApplicationOutcome = z.infer<typeof applicationOutcome>;
