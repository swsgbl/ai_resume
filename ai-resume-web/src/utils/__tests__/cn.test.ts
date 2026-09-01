/**
 * cn 工具函数测试
 */
import { describe, it, expect } from 'vitest';
import { cn } from '../cn';

describe('cn 工具函数', () => {
  it('合并多个类名', () => {
    expect(cn('class1', 'class2', 'class3')).toBe('class1 class2 class3');
  });

  it('过滤 undefined 和 false', () => {
    expect(cn('class1', undefined, 'class2', false, 'class3')).toBe('class1 class2 class3');
  });

  it('处理空输入', () => {
    expect(cn()).toBe('');
  });

  it('处理只有无效值的输入', () => {
    expect(cn(undefined, false)).toBe('');
  });

  it('处理单个类名', () => {
    expect(cn('single-class')).toBe('single-class');
  });

  it('处理包含空格的类名', () => {
    expect(cn('class1 class2', 'class3')).toBe('class1 class2 class3');
  });
});
