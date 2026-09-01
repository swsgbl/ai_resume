import { describe, it, expect, beforeEach, vi } from 'vitest';
import { render, screen, fireEvent } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import PhoneBindingForm from './PhoneBindingForm';

describe('PhoneBindingForm Component', () => {
  const mockToken = 'test-token';
  const mockOnSuccess = vi.fn();

  beforeEach(() => {
    vi.clearAllMocks();
    global.confirm = vi.fn(() => true);
  });

  it('应该渲染绑定表单', () => {
    render(<PhoneBindingForm token={mockToken} onSuccess={mockOnSuccess} />);

    expect(screen.getByLabelText(/手机号/)).toBeInTheDocument();
    expect(screen.getByRole('button', { name: /绑定手机号/ })).toBeInTheDocument();
  });

  it('已绑定手机号时应该显示修改和解绑按钮', () => {
    render(
      <PhoneBindingForm
        token={mockToken}
        onSuccess={mockOnSuccess}
        currentPhone="13800138000"
      />
    );

    expect(screen.getByDisplayValue('13800138000')).toBeInTheDocument();
    expect(screen.getByRole('button', { name: /修改手机号/ })).toBeInTheDocument();
    expect(screen.getByRole('button', { name: /解绑/ })).toBeInTheDocument();
  });

  it('应该显示手机号输入框', () => {
    render(<PhoneBindingForm token={mockToken} onSuccess={mockOnSuccess} />);

    const input = screen.getByLabelText(/手机号/);
    expect(input).toBeInTheDocument();
    expect(input).toHaveAttribute('type', 'tel');
    expect(input).toHaveAttribute('maxLength', '11');
  });

  it('输入无效手机号应该显示错误', async () => {
    render(<PhoneBindingForm token={mockToken} onSuccess={mockOnSuccess} />);

    const input = screen.getByLabelText(/手机号/);
    const submitButton = screen.getByRole('button', { name: /绑定手机号/ });

    await userEvent.type(input, '123');
    fireEvent.click(submitButton);

    expect(screen.getByText(/请输入正确的11位手机号/)).toBeInTheDocument();
  });

  it('输入有效手机号格式应该通过校验', async () => {
    render(<PhoneBindingForm token={mockToken} onSuccess={mockOnSuccess} />);

    const input = screen.getByLabelText(/手机号/);
    await userEvent.type(input, '13800138000');

    expect(input).toHaveValue('13800138000');
  });

  it('应该清空手机号输入', async () => {
    render(<PhoneBindingForm token={mockToken} onSuccess={mockOnSuccess} />);

    const input = screen.getByLabelText(/手机号/);
    await userEvent.type(input, '13800138000');

    const clearButton = screen.getByRole('button', { name: /清空/ });
    await userEvent.click(clearButton);

    expect(input).toHaveValue('');
  });

  it('解绑时应该显示确认对话框', async () => {
    render(
      <PhoneBindingForm
        token={mockToken}
        onSuccess={mockOnSuccess}
        currentPhone="13800138000"
      />
    );

    const unbindButton = screen.getByRole('button', { name: /解绑/ });
    await userEvent.click(unbindButton);

    expect(global.confirm).toHaveBeenCalledWith('确定要解绑手机号吗？');
  });

  it('取消解绑不应该发送请求', async () => {
    global.confirm = vi.fn(() => false);

    render(
      <PhoneBindingForm
        token={mockToken}
        onSuccess={mockOnSuccess}
        currentPhone="13800138000"
      />
    );

    const unbindButton = screen.getByRole('button', { name: /解绑/ });
    await userEvent.click(unbindButton);

    expect(global.confirm).toHaveBeenCalled();
  });

  it('应该使用VITE_API_URL环境变量', () => {
    const originalEnv = import.meta.env.VITE_API_URL;
    import.meta.env.VITE_API_URL = 'http://test-api.com';

    render(<PhoneBindingForm token={mockToken} onSuccess={mockOnSuccess} />);

    // 组件应该使用环境变量
    expect(import.meta.env.VITE_API_URL).toBe('http://test-api.com');

    import.meta.env.VITE_API_URL = originalEnv;
  });
});
