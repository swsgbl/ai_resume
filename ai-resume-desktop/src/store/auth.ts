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

      register: async (email: string, password: string, data) => {
        set({ isLoading: true, error: null });
        try {
          const response = await api.auth.register({
            email,
            password,
            ...data,
          });
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
