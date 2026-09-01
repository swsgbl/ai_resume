/**
 * Auth Store 测试
 */
import { describe, it, expect, beforeEach, vi } from 'vitest';
import { renderHook, act } from '@testing-library/react';
import { useAuthStore } from './auth';
import { UserRole } from '@ai-resume/shared/types';

// Mock the shared module
vi.mock('@ai-resume/shared', () => ({
  api: {
    auth: {
      login: vi.fn(),
      register: vi.fn(),
      getCurrentUser: vi.fn(),
    },
  },
  storage: {
    setToken: vi.fn(),
    setRefreshToken: vi.fn(),
    setUser: vi.fn(),
    getToken: vi.fn(),
    getRefreshToken: vi.fn(),
    getUser: vi.fn(),
    clearAuth: vi.fn(),
  },
}));

describe('Auth Store', () => {
  const mockUser = {
    id: 1,
    email: 'test@example.com',
    username: 'testuser',
    is_verified: true,
    is_active: true,
    role: UserRole.USER,
    created_at: '2024-01-01T00:00:00Z',
  };

  beforeEach(() => {
    // Reset store state before each test
    const { result } = renderHook(() => useAuthStore());
    act(() => {
      result.current.logout();
    });
  });

  describe('初始状态', () => {
    it('应该有正确的初始状态', () => {
      const { result } = renderHook(() => useAuthStore());

      expect(result.current.user).toBeNull();
      expect(result.current.token).toBeNull();
      expect(result.current.isAuthenticated).toBe(false);
      expect(result.current.isLoading).toBe(false);
      expect(result.current.error).toBeNull();
    });
  });

  describe('login', () => {
    it('成功登录应该更新状态', async () => {
      const { api, storage } = await import('@ai-resume/shared');
      vi.mocked(api.auth.login).mockResolvedValue({
        access_token: 'test-access-token',
        refresh_token: 'test-refresh-token',
        token_type: 'bearer',
        user: mockUser,
      });

      const { result } = renderHook(() => useAuthStore());

      await act(async () => {
        await result.current.login('test@example.com', 'password123');
      });

      expect(result.current.user).toEqual(mockUser);
      expect(result.current.token).toBe('test-access-token');
      expect(result.current.isAuthenticated).toBe(true);
      expect(result.current.isLoading).toBe(false);
      expect(result.current.error).toBeNull();

      expect(storage.setToken).toHaveBeenCalledWith('test-access-token');
      expect(storage.setRefreshToken).toHaveBeenCalledWith('test-refresh-token');
      expect(storage.setUser).toHaveBeenCalledWith(mockUser);
    });

    it('登录失败应该设置错误信息', async () => {
      const { api } = await import('@ai-resume/shared');
      vi.mocked(api.auth.login).mockRejectedValue(new Error('邮箱或密码错误'));

      const { result } = renderHook(() => useAuthStore());

      await act(async () => {
        try {
          await result.current.login('test@example.com', 'wrong-password');
        } catch (e) {
          // Expected error
        }
      });

      expect(result.current.user).toBeNull();
      expect(result.current.token).toBeNull();
      expect(result.current.isAuthenticated).toBe(false);
      expect(result.current.isLoading).toBe(false);
      expect(result.current.error).toBe('邮箱或密码错误');
    });
  });

  describe('register', () => {
    it('成功注册应该更新状态', async () => {
      const { api } = await import('@ai-resume/shared');
      vi.mocked(api.auth.register).mockResolvedValue({
        access_token: 'new-access-token',
        refresh_token: 'new-refresh-token',
        token_type: 'bearer',
        user: mockUser,
      });

      const { result } = renderHook(() => useAuthStore());

      await act(async () => {
        await result.current.register('new@example.com', 'password123', {
          username: 'newuser',
          verification_code: '123456',
        });
      });

      expect(result.current.user).toEqual(mockUser);
      expect(result.current.token).toBe('new-access-token');
      expect(result.current.isAuthenticated).toBe(true);
    });
  });

  describe('logout', () => {
    it('登出应该清除状态', async () => {
      const { storage } = await import('@ai-resume/shared');
      const { result } = renderHook(() => useAuthStore());

      // 先设置登录状态
      act(() => {
        useAuthStore.setState({
          user: mockUser,
          token: 'test-token',
          isAuthenticated: true,
        });
      });

      expect(result.current.isAuthenticated).toBe(true);

      // 执行登出
      act(() => {
        result.current.logout();
      });

      expect(result.current.user).toBeNull();
      expect(result.current.token).toBeNull();
      expect(result.current.isAuthenticated).toBe(false);

      expect(storage.clearAuth).toHaveBeenCalled();
    });
  });

  describe('clearError', () => {
    it('应该清除错误信息', () => {
      const { result } = renderHook(() => useAuthStore());

      act(() => {
        useAuthStore.setState({ error: 'Some error' });
      });

      expect(result.current.error).toBe('Some error');

      act(() => {
        result.current.clearError();
      });

      expect(result.current.error).toBeNull();
    });
  });
});
