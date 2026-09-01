import { z } from 'zod';
import type { AgentDefinition } from './runner';

/**
 * AI 简历 OS 的三条核心 Agent:
 *   extract  — 任意文本(旧简历/经历自述) → JSON Resume 结构化数据
 *   evaluate — 简历 × JD → 六维匹配评估(含匹配分,投递回流校准用)
 *   tailor   — 简历 × JD → 逐条定制建议
 * 全部结构化输出,消费方无需解析自然语言。
 */

export const extractAgent: AgentDefinition<unknown> = {
  name: '结构化抽取',
  system: `你是简历数据抽取引擎。把用户提供的任意文本(旧简历、经历自述、领英档案等)
转换为 JSON Resume 开放标准对象。字段映射规则:
- basics.name/label/email/phone/summary/location
- basics.profiles: [{network: "github"|"linkedin"|"website", url}]
- work[]: {name:公司, position, startDate:"YYYY-MM", endDate, summary, highlights:字符串数组(成就,量化优先)}
- education[]: {institution, area:专业, studyType:学位, startDate, endDate, score:GPA}
- projects[]: {name, description, keywords:技术栈数组, highlights, role, url}
- skills[]: {name, level:"入门"|"熟悉"|"熟练"|"精通", category, keywords}
- certificates[]: {name, issuer, date}
文本中没有的字段直接省略,禁止编造。日期统一 YYYY-MM 格式。`,
  schema: z.object({}).passthrough(),
};

export const evaluateSchema = z.object({
  matchScore: z.number().min(0).max(100),
  verdict: z.string(),
  dimensions: z.array(
    z.object({
      name: z.string(),
      score: z.number().min(0).max(100),
      comment: z.string(),
    })
  ),
  missingKeywords: z.array(z.string()),
  risks: z.array(z.string()),
});
export type EvaluateResult = z.infer<typeof evaluateSchema>;

export const evaluateAgent: AgentDefinition<EvaluateResult> = {
  name: 'JD 匹配评估',
  system: `你是资深猎头评估引擎。对照职位描述(JD)评估简历,输出 JSON:
- matchScore: 0-100 综合匹配分
- verdict: 一句话结论(是否建议投递)
- dimensions: 5-6 个维度评估 {name, score, comment},维度示例:经验匹配/技能覆盖/行业背景/学历要求/加分项
- missingKeywords: 简历缺失的 JD 关键词(中英文)
- risks: 投递风险点
评估基于事实,不鼓励编造。comment 不超过 40 字。`,
  schema: evaluateSchema,
};

export const tailorSchema = z.object({
  summarySuggestion: z.string(),
  bulletSuggestions: z.array(
    z.object({
      section: z.string(),
      original: z.string(),
      improved: z.string(),
      reason: z.string(),
    })
  ),
  keywordsToEmbed: z.array(z.string()),
});
export type TailorResult = z.infer<typeof tailorSchema>;

export const tailorAgent: AgentDefinition<TailorResult> = {
  name: '岗位定制',
  system: `你是简历定制引擎。针对目标 JD 优化简历,输出 JSON:
- summarySuggestion: 重写后的个人总结(80 字内)
- bulletSuggestions: 3-6 条经历改写 {section: "work"|"projects"|"skills", original: 原句, improved: 改写句(STAR+量化), reason: 修改理由}
- keywordsToEmbed: 建议自然嵌入的 JD 关键词
只基于简历已有事实改写,禁止虚构经历。`,
  schema: tailorSchema,
};

export type { AgentRunEvent } from './runner';
