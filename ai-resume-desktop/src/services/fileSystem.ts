import { invoke } from '@tauri-apps/api/core';

/**
 * 将内容保存到本地文件
 * @param path 文件绝对路径
 * @param content 要保存的字符串内容
 */
export async function saveContent(path: string, content: string): Promise<void> {
  try {
    await invoke('save_content', { path, content });
  } catch (error) {
    console.error('Failed to save content:', error);
    throw error;
  }
}

/**
 * 从本地文件读取内容
 * @param path 文件绝对路径
 */
export async function readContent(path: string): Promise<string> {
  try {
    return await invoke('read_content', { path });
  } catch (error) {
    console.error('Failed to read content:', error);
    throw error;
  }
}
