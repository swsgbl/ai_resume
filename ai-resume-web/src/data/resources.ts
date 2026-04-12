import toolsData from './tools.json';

export type ToolCategory = 'system' | 'network' | 'software';

export interface CloudStorage {
  type: string;
  url: string;
  extractCode?: string;
}

export interface Tool {
  id: string;
  name: string;
  nameEn: string;
  description: string;
  descriptionEn: string;
  category: string;
  version: string;
  size: string;
  cloudStorage?: CloudStorage;
}

export const tools: Tool[] = toolsData.tools;

export const getToolsByCategory = (category: ToolCategory): Tool[] =>
  tools.filter((t) => t.category === category);

export const systemTools = getToolsByCategory('system');
export const networkTools = getToolsByCategory('network');
export const softwareTools = getToolsByCategory('software');
