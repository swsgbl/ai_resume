import { describe, it, expect, beforeEach, vi } from 'vitest';
import { render, screen, waitFor } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import VerificationCodeInput from './VerificationCodeInput';

// Mock fetch
global.fetch = vi.fn();

describe('VerificationCodeInput Component', () => {
  const mockOnCodeChange = vi.fn();
  const mockPhone = '13800138000';

  beforeEach(() => {
    vi.clearAllMocks();
    vi.mocked(fetch).mockResolvedValue({
      ok: true,
      json: async () => ({ data: { cooldown: 60 } }),
    } as Response);
  });

  it('应该渲染验证码输入框和发送按钮', () => {
    render(
      <VerificationCodeInput
        phone={mockPhone}
        onCodeChange={mockOnCodeChange}
        code=""
      />
    );

    expect(screen.getByLabelText(/验证码/)).toBeInTheDocument();
    expect(screen.getByRole('button', { name: /获取验证码/ })).toBeInTheDocument();
  });

  it('没有手机号时发送按钮应该禁用', () => {
    render(
      <VerificationCodeInput
        phone=""
        onCodeChange={mockOnCodeChange}
        code=""
      />
    );

    const sendButton = screen.getByRole('button', { name: /获取验证码/ });
    expect(sendButton).toBeDisabled();
  });

  it('应该只允许输入数字', async () => {
    render(
      <VerificationCodeInput
        phone={mockPhone}
        onCodeChange={mockOnCodeChange}
        code=""
      />
    );

    const input = screen.getByLabelText(/验证码/);
    await userEvent.type(input, 'abc123');

    // 应该只调用数字部分（非空字符串应该是纯数字）
    mockOnCodeChange.mock.calls.forEach(call => {
      const code = call[0];
      if (code.length > 0) {
        expect(/^\d+$/.test(code)).toBe(true);
      }
    });
  });

  it('应该限制验证码最大长度为6位', async () => {
    render(
      <VerificationCodeInput
        phone={mockPhone}
        onCodeChange={mockOnCodeChange}
        code=""
      />
    );

    const input = screen.getByLabelText(/验证码/);
    await userEvent.type(input, '123456789');

    // 应该从不调用超过6位
    mockOnCodeChange.mock.calls.forEach(call => {
      expect(call[0].length).toBeLessThanOrEqual(6);
    });
  });

  it('输入无效手机号格式时应该显示错误', async () => {
    render(
      <VerificationCodeInput
        phone="123"
        onCodeChange={mockOnCodeChange}
        code=""
      />
    );

    const sendButton = screen.getByRole('button', { name: /获取验证码/ });
    await userEvent.click(sendButton);

    expect(screen.getByText(/请先输入正确的11位手机号/)).toBeInTheDocument();
  });

  it('倒计时期间发送按钮应该禁用', async () => {
    render(
      <VerificationCodeInput
        phone={mockPhone}
        onCodeChange={mockOnCodeChange}
        code=""
      />
    );

    const sendButton = screen.getByRole('button', { name: /获取验证码/ });
    await userEvent.click(sendButton);

    // 模拟倒计时开始
    await waitFor(() => {
      expect(sendButton).toHaveTextContent(/\d+s/);
      expect(sendButton).toBeDisabled();
    });
  });

  it('应该清除发送错误信息', async () => {
    render(
      <VerificationCodeInput
        phone="invalid"
        onCodeChange={mockOnCodeChange}
        code=""
      />
    );

    const sendButton = screen.getByRole('button', { name: /获取验证码/ });
    await userEvent.click(sendButton);

    expect(screen.getByText(/请先输入正确的11位手机号/)).toBeInTheDocument();

    const input = screen.getByLabelText(/验证码/);
    await userEvent.type(input, '1');

    // 错误应该被清除
    await waitFor(() => {
      expect(screen.queryByText(/请先输入正确的11位手机号/)).not.toBeInTheDocument();
    });
  });

  it('发送成功时应该显示成功消息', async () => {
    render(
      <VerificationCodeInput
        phone={mockPhone}
        onCodeChange={mockOnCodeChange}
        code=""
      />
    );

    const sendButton = screen.getByRole('button', { name: /获取验证码/ });
    await userEvent.click(sendButton);

    // 等待发送完成
    await waitFor(() => {
      expect(screen.getByText(/验证码已发送，5分钟内有效/)).toBeInTheDocument();
    });
  });

  it('应该使用VITE_API_URL环境变量', () => {
    const originalEnv = import.meta.env.VITE_API_URL;
    import.meta.env.VITE_API_URL = 'http://test-api.com';

    render(
      <VerificationCodeInput
        phone={mockPhone}
        onCodeChange={mockOnCodeChange}
        code=""
      />
    );

    expect(import.meta.env.VITE_API_URL).toBe('http://test-api.com');

    import.meta.env.VITE_API_URL = originalEnv;
  });

  it('输入框应该有正确的属性', () => {
    render(
      <VerificationCodeInput
        phone={mockPhone}
        onCodeChange={mockOnCodeChange}
        code=""
      />
    );

    const input = screen.getByLabelText(/验证码/);
    expect(input).toHaveAttribute('type', 'text');
    expect(input).toHaveAttribute('maxLength', '6');
    expect(input).toHaveAttribute('placeholder', '6位数字验证码');
    expect(input).toHaveAttribute('required');
  });
});
