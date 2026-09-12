import type { z } from 'zod';
import { loadProviderStore, saveProviderConfig } from './providers';

/**
 * 结构化输出 Agent 引擎 — AI 简历 OS 的执行层
 *
 * 原则:
 * - 模型端点可持久化,密钥只保留在当前页面内存中
 * - 每个 Agent 返回严格符合 Zod schema 的 JSON,下游代码直接消费
 * - 校验失败自动带错误信息重试一次(自愈),仍失败则抛出可读错误
 */

export interface AgentModelConfig {
  /** OpenAI 兼容 base URL,如 https://api.deepseek.com/v1 */
  baseUrl: string;
  apiKey: string;
  /** 模型名,如 deepseek-chat */
  model: string;
}

export const MODEL_CONFIG_STORAGE_KEY = 'os_model_config';

/**
 * 读取当前路由配置(多厂商方案的默认厂商)。
 * 迁移说明:旧版 apiKey 只存页面内存(刷新即丢,可用性缺陷),
 * 现按产品「仅存本机浏览器」承诺持久化到多厂商存储。
 */
export function loadModelConfig(): AgentModelConfig | null {
  const store = loadProviderStore();
  const current = store.providers.find((p) => p.id === store.defaultId);
  if (!current || !current.baseUrl || !current.model) return null;
  return { baseUrl: current.baseUrl, apiKey: current.apiKey, model: current.model };
}

/** 保存到默认路由对应的厂商(无则创建/更新该端点的厂商条目) */
export function saveModelConfig(config: AgentModelConfig): void {
  const store = loadProviderStore();
  const current = store.providers.find((p) => p.id === store.defaultId);
  if (current) {
    saveProviderConfig({ ...current, baseUrl: config.baseUrl, apiKey: config.apiKey, model: config.model });
  } else {
    saveProviderConfig({
      id: `provider-${Date.now()}`,
      name: '默认厂商',
      baseUrl: config.baseUrl,
      apiKey: config.apiKey,
      model: config.model,
    });
  }
}

interface ChatMessage {
  role: 'system' | 'user';
  content: string;
}

async function chatCompletion(
  config: AgentModelConfig,
  messages: ChatMessage[],
  signal?: AbortSignal
): Promise<string> {
  if (!config.apiKey.trim()) {
    throw new Error('API Key 未配置,请重新输入本次会话密钥');
  }
  const url = `${config.baseUrl.replace(/\/+$/, '')}/chat/completions`;
  const response = await fetch(url, {
    method: 'POST',
    signal,
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${config.apiKey}`,
    },
    body: JSON.stringify({
      model: config.model,
      messages,
      temperature: 0.3,
      response_format: { type: 'json_object' },
    }),
  });

  if (!response.ok) {
    const text = await response.text().catch(() => '');
    throw new Error(`模型接口 ${response.status}: ${text.slice(0, 200) || response.statusText}`);
  }

  const data = (await response.json()) as {
    choices?: Array<{ message?: { content?: string } }>;
  };
  const content = data.choices?.[0]?.message?.content;
  if (!content) throw new Error('模型返回为空');
  return content;
}

function extractJson(text: string): unknown {
  const trimmed = text.trim().replace(/^```(?:json)?\s*/i, '').replace(/\s*```$/, '');
  try {
    return JSON.parse(trimmed);
  } catch {
    // 兜底:截取首个 { 到末个 } 之间的内容
    const start = trimmed.indexOf('{');
    const end = trimmed.lastIndexOf('}');
    if (start >= 0 && end > start) return JSON.parse(trimmed.slice(start, end + 1));
    throw new Error('模型输出不是合法 JSON');
  }
}

export interface AgentDefinition<T> {
  name: string;
  system: string;
  /** 输出契约 */
  schema: z.ZodType<T>;
}

export interface AgentRunEvent {
  agent: string;
  status: 'running' | 'done' | 'retry' | 'failed';
  detail?: string;
}

/**
 * 运行一个 Agent:system 约束 + 用户输入 → 结构化 JSON → Zod 校验
 * 校验失败把错误回传模型自愈重试一次。
 */
export async function runAgent<T>(
  agent: AgentDefinition<T>,
  config: AgentModelConfig,
  input: string,
  options: { onEvent?: (event: AgentRunEvent) => void; signal?: AbortSignal } = {}
): Promise<T> {
  const { onEvent, signal } = options;
  const messages: ChatMessage[] = [
    { role: 'system', content: `${agent.system}\n\n只输出一个合法 JSON 对象,不要输出任何其他文字。` },
    { role: 'user', content: input },
  ];

  let lastError = '';
  for (let attempt = 1; attempt <= 2; attempt++) {
    onEvent?.({ agent: agent.name, status: 'running', detail: attempt === 1 ? undefined : '重试中' });
    try {
      const raw = await chatCompletion(config, messages, signal);
      const json = extractJson(raw);
      const result = agent.schema.safeParse(json);
      if (result.success) {
        onEvent?.({ agent: agent.name, status: 'done' });
        return result.data;
      }
      lastError = result.error.issues
        .slice(0, 5)
        .map((i) => `${i.path.join('.') || '(root)'}: ${i.message}`)
        .join('; ');
      // 自愈:把校验错误作为纠错反馈回传模型
      messages.push({ role: 'user', content: `你上次的输出未通过校验,错误如下:\n${lastError}\n请修正后重新输出完整 JSON。` });
      onEvent?.({ agent: agent.name, status: 'retry', detail: lastError });
    } catch (error) {
      // 网络/API 错误不值得重试格式问题,直接抛出
      throw error instanceof Error ? error : new Error(String(error));
    }
  }

  onEvent?.({ agent: agent.name, status: 'failed', detail: lastError });
  throw new Error(`Agent「${agent.name}」结构化输出校验失败: ${lastError}`);
}
