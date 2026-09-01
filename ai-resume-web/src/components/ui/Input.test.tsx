/**
 * Input 组件测试
 */
import { describe, it, expect, vi } from 'vitest';
import { render, screen } from '@testing-library/react';
import '@testing-library/jest-dom';
import userEvent from '@testing-library/user-event';
import { Input } from './Input';

describe('Input Component', () => {
  it('渲染基本输入框', () => {
    render(<Input id="test-input" />);

    expect(screen.getByRole('textbox')).toBeInTheDocument();
  });

  it('渲染带标签的输入框', () => {
    render(<Input id="test-input" label="用户名" />);

    expect(screen.getByLabelText('用户名')).toBeInTheDocument();
  });

  it('标签和输入框正确关联', () => {
    render(<Input id="email-input" label="邮箱" />);

    const input = screen.getByRole('textbox');
    expect(input.id).toBe('email-input');
  });

  it('显示错误信息', () => {
    render(<Input id="test-input" error="邮箱格式不正确" />);

    expect(screen.getByText('邮箱格式不正确')).toBeInTheDocument();
  });

  it('错误时添加边框样式', () => {
    render(<Input id="test-input" error="错误" />);

    expect(screen.getByRole('textbox')).toHaveClass('input-error');
  });

  it('显示图标', () => {
    render(
      <Input
        id="test-input"
        icon={<span data-testid="input-icon">🔍</span>}
      />
    );

    expect(screen.getByTestId('input-icon')).toBeInTheDocument();
  });

  it('有图标时调整输入框内边距', () => {
    render(
      <Input id="test-input" icon={<span>🔍</span>} />
    );

    expect(screen.getByRole('textbox')).toHaveClass('pl-12');
  });

  it('值变化触发 onChange', async () => {
    const handleChange = vi.fn();
    const user = userEvent.setup();

    render(<Input id="test-input" onChange={handleChange} />);

    const input = screen.getByRole('textbox');
    await user.type(input, 'hello');

    expect(handleChange).toHaveBeenCalled();
  });

  it('focus 和 blur 事件正确触发', async () => {
    const handleFocus = vi.fn();
    const handleBlur = vi.fn();
    const user = userEvent.setup();

    render(<Input id="test-input" onFocus={handleFocus} onBlur={handleBlur} />);

    const input = screen.getByRole('textbox');

    await user.click(input);
    expect(handleFocus).toHaveBeenCalledTimes(1);

    await user.tab();
    expect(handleBlur).toHaveBeenCalledTimes(1);
  });

  it('支持禁用状态', () => {
    render(<Input id="test-input" disabled />);

    expect(screen.getByRole('textbox')).toBeDisabled();
  });

  it('支持占位符', () => {
    render(<Input id="test-input" placeholder="请输入邮箱" />);

    expect(screen.getByPlaceholderText('请输入邮箱')).toBeInTheDocument();
  });

  it('支持不同输入类型', () => {
    const { rerender } = render(<Input id="test-input" type="text" />);
    expect(screen.getByRole('textbox')).toHaveAttribute('type', 'text');

    rerender(<Input id="test-input" type="email" />);
    expect(screen.getByDisplayValue('')).toHaveAttribute('type', 'email');

    rerender(<Input id="test-input" type="password" />);
    expect(screen.getByDisplayValue('')).toHaveAttribute('type', 'password');
  });

  it('应用自定义类名', () => {
    render(<Input id="test-input" className="custom-input" />);

    expect(screen.getByRole('textbox')).toHaveClass('custom-input');
  });

  it('传递 data-testid', () => {
    render(<Input id="test-input" data-testid="custom-testid" />);

    expect(screen.getByTestId('custom-testid')).toBeInTheDocument();
  });

  it('支持受控组件', async () => {
    const handleChange = vi.fn();
    const user = userEvent.setup();

    render(<Input id="test-input" value="初始值" onChange={handleChange} />);

    const input = screen.getByDisplayValue('初始值');
    expect(input).toBeInTheDocument();

    await user.clear(input);
    await user.type(input, '新值');

    expect(handleChange).toHaveBeenCalled();
  });

  it('支持最大长度限制', async () => {
    const user = userEvent.setup();

    render(<Input id="test-input" maxLength={5} />);

    const input = screen.getByRole('textbox');
    await user.type(input, '123456');

    expect(input).toHaveValue('12345');
  });

  it('支持自动完成', () => {
    render(<Input id="test-input" autoComplete="email" />);

    expect(screen.getByRole('textbox')).toHaveAttribute('autoComplete', 'email');
  });
});
