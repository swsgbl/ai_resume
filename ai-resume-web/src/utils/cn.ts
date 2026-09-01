/**
 * 合并CSS类名的工具函数
 * 简化版本，避免外部依赖
 */
export function cn(...inputs: (string | undefined | false)[]) {
  return inputs.filter(Boolean).join(' ');
}

export default cn;
