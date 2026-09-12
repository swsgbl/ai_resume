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
- basics.location: {address: "城市名"}(必须对象,不要字符串)
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

/**
 * 演练场 Agent 组(借鉴 interview-coach-skill 方法论):
 *   storyExtract — 简历文本 → STAR 故事库(带能力标签)
 *   questionGen  — 简历 × JD × 故事库 → 定向面试题(建议用哪个故事作答)
 *   answerScore  — 问题 × 答案 → 五维评分 + 改写示范
 */

export const storyExtractSchema = z.object({
  stories: z
    .array(
      z.object({
        title: z.string(),
        situation: z.string(),
        task: z.string(),
        action: z.string(),
        result: z.string(),
        tags: z.array(z.string()),
      })
    )
    .min(1)
    .max(8),
});
export type StoryExtractResult = z.infer<typeof storyExtractSchema>;

export const storyExtractAgent: AgentDefinition<StoryExtractResult> = {
  name: '故事库提炼',
  system: `你是面试故事教练。从简历/经历文本中提炼 3-6 个可复用的 STAR 面试故事,输出 JSON:
- title: 故事短标题(15字内,如"零停机迁移数据库")
- situation: 背景(S)一句、task: 任务(T)一句、action: 行动(A)两三句、result: 结果(R)一句(量化优先)
- tags: 能力标签数组,从这些里选:技术攻坚/领导力/跨团队协作/冲突解决/创新/抗压/沟通/业务思维/项目管理/失败复盘
严格基于文本事实,禁止编造经历。文本太薄时可以少给,但每个故事必须四要素齐全。`,
  schema: storyExtractSchema,
};

export const questionGenSchema = z.object({
  questions: z
    .array(
      z.object({
        question: z.string(),
        type: z.string(),
        suggestedStory: z.string().nullable(),
      })
    )
    .min(3)
    .max(8),
});
export type QuestionGenResult = z.infer<typeof questionGenSchema>;

export const questionGenAgent: AgentDefinition<QuestionGenResult> = {
  name: '面试题生成',
  system: `你是目标公司的面试官。根据候选人简历、岗位 JD 和其故事库,出 5 道最可能被问到的面试题,输出 JSON:
- question: 问题原文(像真实面试官的口吻)
- type: "行为"|"情境"|"技术"|"动机"|"压力" 之一
- suggestedStory: 建议候选人用哪个故事作答(必须是故事库里的标题;没有合适的填 null)
组成:2-3 道行为题(优先考察 JD 强调的能力)、1-2 道与 JD 技术栈相关的情境/技术题、1 道动机题(为什么这个岗位)。`,
  schema: questionGenSchema,
};

export const answerScoreSchema = z.object({
  overall: z.number().min(0).max(100),
  dimensions: z
    .array(
      z.object({
        name: z.string(),
        score: z.number().min(0).max(100),
        comment: z.string(),
      })
    )
    .length(5),
  improved: z.string(),
});
export type AnswerScoreResult = z.infer<typeof answerScoreSchema>;

export const answerScoreAgent: AgentDefinition<AnswerScoreResult> = {
  name: '答案五维批改',
  system: `你是严格的面试教练。按五个维度给候选人的面试答案打分,输出 JSON:
五维固定为:具体性(有事实数字细节)、结构(STAR清晰)、相关性(紧扣问题)、可信度(细节可验证)、差异化(独特亮点)。
- dimensions: 恰好五项 {name, score, comment},comment 指出具体问题并给一句可操作的改进指令(40字内)
- overall: 0-100 总分(加权平均,相关性权重最高)
- improved: 不改变事实、仅优化表达后的示范答案(150-250字),保留原答案的所有数字与事实,禁止编造新事实`,
  schema: answerScoreSchema,
};
