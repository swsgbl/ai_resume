/**
 * 面试故事库存储 — 演练场的数据底座(借鉴 interview-coach-skill 的 storybank)
 * STAR 故事 + 能力标签,从简历提炼或手动补充,模拟面试时作为作答素材。
 * 数据仅存本机 localStorage,符合产品隐私承诺。
 */

export interface InterviewStory {
  id: string;
  title: string;
  situation: string;
  task: string;
  action: string;
  result: string;
  tags: string[];
  createdAt: string;
}

const STORAGE_KEY = 'os_stories';

export function loadStories(): InterviewStory[] {
  try {
    const raw = localStorage.getItem(STORAGE_KEY);
    if (!raw) return [];
    const parsed = JSON.parse(raw) as InterviewStory[];
    return Array.isArray(parsed) ? parsed : [];
  } catch {
    return [];
  }
}

function persist(list: InterviewStory[]): void {
  localStorage.setItem(STORAGE_KEY, JSON.stringify(list));
}

export function saveStory(story: Omit<InterviewStory, 'id' | 'createdAt'>): InterviewStory {
  const record: InterviewStory = {
    ...story,
    id: `story-${Date.now()}-${Math.random().toString(36).slice(2, 8)}`,
    createdAt: new Date().toISOString().slice(0, 10),
  };
  const list = loadStories();
  // 同标题故事去重(提炼重复运行时不堆积)
  const next = [record, ...list.filter((s) => s.title !== story.title)];
  persist(next);
  return record;
}

export function removeStory(id: string): void {
  persist(loadStories().filter((s) => s.id !== id));
}
