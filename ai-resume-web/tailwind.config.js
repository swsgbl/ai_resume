/** @type {import('tailwindcss').Config} */
export default {
  content: [
    "./index.html",
    "./src/**/*.{js,ts,jsx,tsx}",
  ],
  darkMode: 'class',
  theme: {
    extend: {
      /* ============================================
         COLORS - 语义颜色扩展 (P0)
         ============================================ */
      colors: {
        primary: {
          400: '#D4593F',
          500: '#C84B31',
          600: '#A63D28',
          700: '#843220',
        },
        accent: {
          400: '#A3C49E',
          500: '#8FAE8B',
          600: '#7A9A76',
        },
        /* 语义颜色 - P0 新增 */
        success: {
          50: '#e8f5e9',
          100: '#c8e6c9',
          500: '#8FAE8B',
          700: '#4caf50',
        },
        warning: {
          50: '#fff8e1',
          500: '#D4A041',
          700: '#f57c00',
        },
        error: {
          50: '#ffebee',
          500: '#C84B31',
          700: '#d32f2f',
        },
        info: {
          50: '#e3f2fd',
          500: '#7A9A76',
          700: '#1976d2',
        },
        /* 表面层级 - P1 新增 */
        surface: {
          0: '#0C0C0C',
          1: '#161616',
          2: '#1E1E1E',
          3: '#252525',
          4: '#2A2A2A',
        },
      },

      /* ============================================
         FONTS - 字体系统
         ============================================ */
      fontFamily: {
        sans: ['DM Sans', 'Noto Sans SC', 'Inter', 'system-ui', 'sans-serif'],
        serif: ['Playfair Display', 'Noto Serif SC', 'Georgia', 'serif'],
        mono: ['JetBrains Mono', 'monospace'],
      },

      /* ============================================
         FONT SIZE - 完整排版层级 (P2)
         ============================================ */
      fontSize: {
        /* Display Tier - 负字距优化 */
        'display-xl': ['clamp(48px, 5vw, 80px)', {
          lineHeight: '1.05',
          letterSpacing: '-0.03em',
          fontWeight: '600'
        }],
        'display-lg': ['clamp(36px, 4vw, 56px)', {
          lineHeight: '1.10',
          letterSpacing: '-0.02em',
          fontWeight: '600'
        }],
        'display-md': ['clamp(28px, 3vw, 40px)', {
          lineHeight: '1.15',
          letterSpacing: '-0.01em',
          fontWeight: '600'
        }],

        /* Heading Tier */
        'heading-xl': ['28px', {
          lineHeight: '1.20',
          letterSpacing: '-0.006em',
          fontWeight: '600'
        }],
        'heading-lg': ['24px', {
          lineHeight: '1.25',
          letterSpacing: '-0.004em',
          fontWeight: '500'
        }],
        'heading-md': ['20px', {
          lineHeight: '1.40',
          letterSpacing: '-0.002em',
          fontWeight: '500'
        }],

        /* Body Tier */
        'body-lg': ['18px', {
          lineHeight: '1.50',
          letterSpacing: '-0.001em',
          fontWeight: '400'
        }],
        'body-md': ['16px', {
          lineHeight: '1.50',
          letterSpacing: '0',
          fontWeight: '400'
        }],
        'body-sm': ['14px', {
          lineHeight: '1.50',
          letterSpacing: '0',
          fontWeight: '400'
        }],

        /* Utility Tier */
        'caption': ['12px', {
          lineHeight: '1.40',
          letterSpacing: '0',
          fontWeight: '400'
        }],
        'button': ['14px', {
          lineHeight: '1.20',
          letterSpacing: '0',
          fontWeight: '500'
        }],

        /* 向后兼容 */
        'display': ['4rem', { lineHeight: '1.1', letterSpacing: '-0.02em' }],
        'title': ['2.5rem', { lineHeight: '1.2', letterSpacing: '-0.01em' }],
      },

      /* ============================================
         SPACING - 4px 基准网格 (P1)
         ============================================ */
      spacing: {
        '0.5': '2px',    /* 0.125rem */
        '1': '4px',      /* 0.25rem */
        '1.5': '6px',    /* 0.375rem */
        '2': '8px',      /* 0.5rem */
        '2.5': '10px',   /* 0.625rem */
        '3': '12px',     /* 0.75rem */
        '4': '16px',     /* 1rem */
        '5': '20px',     /* 1.25rem */
        '6': '24px',     /* 1.5rem */
        '8': '32px',     /* 2rem */
        '10': '40px',    /* 2.5rem */
        '12': '48px',    /* 3rem */
        '14': '56px',    /* 3.5rem */
        '16': '64px',    /* 4rem */
        '20': '80px',    /* 5rem */
        '24': '96px',    /* 6rem */

        /* Section 级别 */
        'section-sm': '48px',
        'section': '64px',
        'section-lg': '96px',
        'section-xl': '120px',
      },

      /* ============================================
         LETTER SPACING - 负字距 (P2)
         ============================================ */
      letterSpacing: {
        'tighter': '-0.05em',
        'tight': '-0.03em',
        'normal': '0',
        'wide': '0.025em',
      },

      /* ============================================
         ANIMATION
         ============================================ */
      animation: {
        'float': 'float 6s ease-in-out infinite',
        'shimmer': 'shimmer 3s infinite',
        'fade-in': 'fadeIn 0.5s ease-out',
        'slide-up': 'slideUp 0.5s ease-out',
      },
      keyframes: {
        float: {
          '0%, 100%': { transform: 'translateY(0px)' },
          '50%': { transform: 'translateY(-12px)' },
        },
        shimmer: {
          '0%': { backgroundPosition: '-200% 0' },
          '100%': { backgroundPosition: '200% 0' },
        },
        fadeIn: {
          '0%': { opacity: '0' },
          '100%': { opacity: '1' },
        },
        slideUp: {
          '0%': { transform: 'translateY(20px)', opacity: '0' },
          '100%': { transform: 'translateY(0)', opacity: '1' },
        },
      },
      transitionTimingFunction: {
        'bounce-out': 'cubic-bezier(0.34, 1.56, 0.64, 1)',
      },

      /* ============================================
         SHADOWS - 层级系统 (P1)
         ============================================ */
      boxShadow: {
        '0': 'none',
        '1': '0 0 0 1px var(--color-border, #252525)',
        '2': '0 0 0 1px var(--color-border, #252525), 0 4px 8px -4px rgba(0, 0, 0, 0.3)',
        '3': '0 0 0 1px var(--color-border, #252525), 0 8px 16px -8px rgba(0, 0, 0, 0.4)',
        '4': '0 0 0 1px var(--color-border, #252525), 0 16px 32px -16px rgba(0, 0, 0, 0.5)',
        '5': '0 0 0 1px var(--color-border, #252525), 0 24px 48px -24px rgba(0, 0, 0, 0.6)',
      },

      /* ============================================
         MIN HEIGHT - Touch Target (P0)
         ============================================ */
      minHeight: {
        'touch': '44px',
        'touch-lg': '48px',
      },

      /* ============================================
         MIN WIDTH - Touch Target (P0)
         ============================================ */
      minWidth: {
        'touch': '44px',
        'touch-lg': '48px',
      },
    },
  },

  /* ============================================
     SCREENS - 响应式断点优化 (P2)
     Mobile First 策略
     ============================================ */
  screens: {
    'xs': '375px',    /* 小屏手机 */
    'sm': '480px',    /* 大屏手机 */
    'md': '768px',    /* 平板竖屏 */
    'lg': '1024px',   /* 平板横屏 / 小笔记本 */
    'xl': '1280px',   /* 桌面 */
    '2xl': '1440px',  /* 大屏桌面 */
    '3xl': '1920px',  /* 超宽屏 */
  },

  plugins: [],
}
