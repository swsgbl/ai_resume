import { describe, it, expect } from 'vitest';
import { toJsonResume, fromJsonResume, jsonResumeSchema } from '@ai-resume/shared/schema';
import type { ResumeContent } from '@ai-resume/shared/types';

const sample: ResumeContent = {
  basic_info: {
    name: '张三',
    email: 'zhang@example.com',
    phone: '13800000000',
    location: '上海',
    job_intention: '高级前端工程师',
    self_introduction: '五年前端经验',
    github: 'https://github.com/zhangsan',
  },
  work_experience: [
    {
      id: 'w-0',
      company: '字节跳动',
      position: '前端工程师',
      start_date: '2021-03',
      end_date: undefined,
      is_current: true,
      description: '负责抖音 Web 端',
      achievements: ['性能优化 LCP 降低 40%'],
    },
  ],
  education: [
    { id: 'e-0', school: '复旦大学', degree: '本科', major: '计算机科学', start_date: '2017-09', end_date: '2021-06', gpa: '3.6' },
  ],
  projects: [
    { id: 'p-0', name: '开源组件库', description: '企业级组件库', tech_stack: ['React', 'TypeScript'], highlights: ['100+ 组件'] },
  ],
  skills: [
    { id: 's-0', name: 'TypeScript', category: '前端', level: 3, keywords: ['TS'] },
  ],
  certifications: [
    { id: 'c-0', name: 'PMP', issuer: 'PMI', issue_date: '2023-05' },
  ],
};

describe('JSON Resume 双向转换', () => {
  it('平台模型 → JSON Resume 标准字段映射正确', () => {
    const jr = toJsonResume(sample);
    expect(jr.basics?.name).toBe('张三');
    expect(jr.basics?.label).toBe('高级前端工程师');
    expect(jr.basics?.profiles?.[0]).toEqual({ network: 'github', url: 'https://github.com/zhangsan' });
    expect(jr.work?.[0].name).toBe('字节跳动');
    expect(jr.work?.[0].endDate).toBeUndefined(); // 在职无结束日期
    expect(jr.education?.[0].institution).toBe('复旦大学');
    expect(jr.education?.[0].score).toBe('3.6');
    expect(jr.projects?.[0].keywords).toEqual(['React', 'TypeScript']);
    expect(jr.skills?.[0].level).toBe('精通');
    expect(jr.certificates?.[0].name).toBe('PMP');
  });

  it('导出结果通过 JSON Resume schema 校验', () => {
    const jr = toJsonResume(sample);
    expect(() => jsonResumeSchema.parse(jr)).not.toThrow();
  });

  it('JSON Resume → 平台模型 往返(round-trip)字段不丢失', () => {
    const jr = toJsonResume(sample);
    const back = fromJsonResume(jr);
    expect(back.basic_info?.name).toBe('张三');
    expect(back.basic_info?.github).toBe('https://github.com/zhangsan');
    expect(back.basic_info?.job_intention).toBe('高级前端工程师');
    expect(back.work_experience?.[0].company).toBe('字节跳动');
    expect(back.work_experience?.[0].is_current).toBe(true);
    expect(back.work_experience?.[0].achievements).toEqual(['性能优化 LCP 降低 40%']);
    expect(back.education?.[0].school).toBe('复旦大学');
    expect(back.education?.[0].gpa).toBe('3.6');
    expect(back.projects?.[0].tech_stack).toEqual(['React', 'TypeScript']);
    expect(back.skills?.[0].level).toBe(3);
    expect(back.certifications?.[0].issuer).toBe('PMI');
  });

  it('空内容安全转换', () => {
    const jr = toJsonResume({});
    expect(jr.work).toBeUndefined();
    const back = fromJsonResume({});
    expect(back.basic_info?.name).toBeUndefined();
    expect(back.work_experience).toBeUndefined();
  });

  it('投递回流扩展数据可解析', () => {
    const jr = jsonResumeSchema.parse({
      'x-applications': [
        { id: 'a1', company: '腾讯', position: '前端', appliedAt: '2026-08-01', outcome: 'interview', matchScore: 82 },
      ],
    });
    expect(jr['x-applications']?.[0].outcome).toBe('interview');
    expect(jr['x-applications']?.[0].matchScore).toBe(82);
  });

  it('非法投递状态被 schema 拒绝', () => {
    expect(() =>
      jsonResumeSchema.parse({
        'x-applications': [{ id: 'a1', company: 'x', position: 'y', appliedAt: '2026-08-01', outcome: 'unknown' }],
      })
    ).toThrow();
  });
});
