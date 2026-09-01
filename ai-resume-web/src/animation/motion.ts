/* ================================================================
   动效中枢 — 「墨 · 型 · 律」动效体系
   墨:内容如落笔,迅捷出场、沉稳收势(ink/silk/settle 三曲线)
   型:排版优先,标题逐字揭示(SplitText)
   律:滚动为指挥,各声部按 ScrollTrigger 节点进场
   ================================================================ */
import gsap from 'gsap';
import { ScrollTrigger } from 'gsap/ScrollTrigger';
import { ScrollToPlugin } from 'gsap/ScrollToPlugin';
import { SplitText } from 'gsap/SplitText';
import { DrawSVGPlugin } from 'gsap/DrawSVGPlugin';
import { CustomEase } from 'gsap/CustomEase';
import { useGSAP } from '@gsap/react';

gsap.registerPlugin(ScrollTrigger, ScrollToPlugin, SplitText, DrawSVGPlugin, CustomEase, useGSAP);

/* 统一缓动曲线 */
CustomEase.create('ink', '0.22, 1, 0.36, 1'); // 主出场:急落笔,缓缓洇开
CustomEase.create('silk', '0.65, 0.05, 0.36, 1'); // 对称过场:丝绸般顺滑
CustomEase.create('settle', '0.34, 1.56, 0.64, 1'); // 轻微过冲后落定(印章盖下)

/** 动效节奏令牌 — 全站时长/交错统一取值处 */
export const motion = {
  fast: 0.35,
  base: 0.7,
  slow: 1.1,
  ease: {
    out: 'ink',
    inOut: 'silk',
    pop: 'settle',
    linear: 'none',
  },
} as const;

/** 用户允许动效时才运行动画(测试环境 matchMedia 恒为 false,自动跳过) */
export const MOTION_OK = '(prefers-reduced-motion: no-preference)';
/** 精确指针设备(鼠标)才启用 hover 类交互 */
export const FINE_POINTER = '(hover: hover) and (pointer: fine)';

export { gsap, ScrollTrigger, SplitText, DrawSVGPlugin, useGSAP };
