import { defineConfig, loadEnv } from 'vite';
import react from '@vitejs/plugin-react';
import { resolve } from 'path';

export default defineConfig(({ mode }) => {
  // 加载环境变量
  const env = loadEnv(mode, process.cwd(), '');

  return {
    // 基础路径，用于部署
    base: env.VITE_BASE_URL || '/',

    plugins: [react()],

    resolve: {
      preserveSymlinks: true,
      alias: {
        '@': resolve(__dirname, './src'),
      },
    },

    server: {
      port: 3000,
      strictPort: true,
      host: true,
      proxy: {
        '/api': {
          target: env.VITE_API_PROXY_TARGET || 'http://127.0.0.1:8000',
          changeOrigin: true,
        },
      },
      hmr: {
        overlay: false,
      },
    },

    preview: {
      port: 3000,
      host: true,
    },

    optimizeDeps: {
      esbuildOptions: {
        logLevel: 'error',
      },
    },

    build: {
      outDir: 'dist',
      sourcemap: mode === 'development',
      // 生产环境优化 - 使用 esbuild 避免额外依赖
      minify: 'esbuild',
      target: 'es2015',
      // 提高chunk大小警告阈值
      chunkSizeWarningLimit: 600,
      // 分包策略
      rollupOptions: {
        output: {
          // 简化的分包策略 - 避免循环依赖
          manualChunks: {
            // React 核心库（包括 react-dom）
            'vendor-react': ['react', 'react-dom', 'react-router-dom', 'react-router'],
            // 状态管理和请求
            'vendor-state': ['@tanstack/react-query', 'zustand'],
            // 富文本编辑器
            'vendor-editor': ['@tiptap/react', '@tiptap/starter-kit', '@tiptap/extension-underline', '@tiptap/extension-text-align', '@tiptap/extension-placeholder', '@tiptap/extension-link'],
            // 拖拽库
            'vendor-dnd': ['@dnd-kit/core', '@dnd-kit/sortable', '@dnd-kit/utilities'],
            // 图标库
            'vendor-icons': ['lucide-react'],
            // 撤销功能
            'vendor-undo': ['use-undo'],
          },
          // 为生成的 chunk 命名，便于调试
          chunkFileNames: 'assets/[name]-[hash].js',
          entryFileNames: 'assets/[name]-[hash].js',
          assetFileNames: 'assets/[name]-[hash].[ext]',
        },
      },
      // 资源内联限制
      assetsInlineLimit: 4096,
    },
  };
});
