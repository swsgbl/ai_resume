import { create } from 'zustand';
import { persist } from 'zustand/middleware';
import { api, storage } from '@ai-resume/shared';
import type { User } from '@ai-resume/shared/types';

interface AuthState {
  user: User | null;
  token: string | null;
  isAuthenticated: boolean;
  isLoading: boolean;
  error: string | null;

  // Actions
  login: (email: string, password: string) => Promise<void>;
  loginWithOAuth: (accessToken: string, refreshToken?: string) => void;
  register: (email: string, password: string, data?: {
    phone?: string;
    username?: string;
    verification_code?: string;
  }) => Promise<void>;
  logout: () => void;
  clearError: () => void;
  loadUser: () => Promise<void>;
}

export const useAuthStore = create<AuthState>()(
  persist(
    (set, _get) => ({
      user: null,
      token: null,
      isAuthenticated: false,
      isLoading: false,
      error: null,

      login: async (email: string, password: string) => {
        set({ isLoading: true, error: null });
        try {
          const response = await api.auth.login(email, password);
          const { access_token, user } = response;

          storage.setToken(access_token);
          if (response.refresh_token) {
            storage.setRefreshToken(response.refresh_token);
          }
          if (user) {
            storage.setUser(user);
          }

          set({
            user: user ?? null,
            token: access_token,
            isAuthenticated: true,
            isLoading: false,
          });
        } catch (error) {
          const message = error instanceof Error ? error.message : '登录失败';
          set({ error: message, isLoading: false });
          throw error;
        }
      },

      loginWithOAuth: (accessToken: string, refreshToken?: string) => {
        // OAuth登录成功后，保存token
        storage.setToken(accessToken);
        if (refreshToken) {
          storage.setRefreshToken(refreshToken);
        }

        // 设置认证状态
        set({
          token: accessToken,
          isAuthenticated: true,
          isLoading: false,
        });

        // 后台获取用户信息
        api.auth.getCurrentUser().then((userData) => {
          const user = userData as User;
          storage.setUser(user);
          set({ user });
        }).catch(() => {
          // 获取用户信息失败，但保持登录状态
          console.error('Failed to fetch user info after OAuth login');
        });
      },

      register: async (email: string, password: string, data) => {
        set({ isLoading: true, error: null });
        try {
          const response = await api.auth.register({
            email,
            password,
            ...data,
          });

          // 检查是否需要邮箱验证
          if ((response as unknown as Record<string, unknown>).require_verification) {
            set({
              user: null,
              token: null,
              isAuthenticated: false,
              isLoading: false,
            });
            // 不自动登录，返回提示需要验证
            throw new Error('注册成功，请查收邮件并验证邮箱后再登录');
          }

          // 不需要验证的情况才自动登录
          const { access_token, user } = response;

          storage.setToken(access_token);
          if (response.refresh_token) {
            storage.setRefreshToken(response.refresh_token);
          }
          if (user) {
            storage.setUser(user);
          }

          set({
            user: user ?? null,
            token: access_token,
            isAuthenticated: true,
            isLoading: false,
          });
        } catch (error) {
          const message = error instanceof Error ? error.message : '注册失败';
          set({ error: message, isLoading: false });
          throw error;
        }
      },

      logout: () => {
        storage.clearAuth();
        set({
          user: null,
          token: null,
          isAuthenticated: false,
        });
      },

      clearError: () => set({ error: null }),

      loadUser: async () => {
        const token = storage.getToken();
        if (!token) {
          set({ isAuthenticated: false, user: null, token: null, isLoading: false });
          return;
        }

        // 先尝试从 localStorage 读取用户数据（避免不必要的 API 调用）
        const storedUser = storage.getUser();
        if (storedUser) {
          set({
            user: storedUser,
            token,
            isAuthenticated: true,
            isLoading: false,
          });
          // 后台静默验证 token 有效性，不阻塞 UI
          api.auth.getCurrentUser().catch(() => {
            // token 失效，清除认证状态
            storage.clearAuth();
            set({
              user: null,
              token: null,
              isAuthenticated: false,
            });
          });
          return;
        }

        set({ isLoading: true });
        try {
            const response = await api.auth.getCurrentUser();
            const userData = response as User;
          set({
            user: userData,
            token,
            isAuthenticated: true,
            isLoading: false,
          });
        } catch {
          storage.clearAuth();
          set({
            user: null,
            token: null,
            isAuthenticated: false,
            isLoading: false,
          });
        }
      },
    }),
    {
      name: 'auth-storage',
      partialize: (state) => ({
        user: state.user,
        token: state.token,
        isAuthenticated: state.isAuthenticated,
      }),
    }
  )
);
