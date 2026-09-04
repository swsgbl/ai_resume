import { describe, it, expect, vi, beforeEach } from 'vitest';
import { render, screen, waitFor } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import QQLoginButton from './QQLoginButton';
import { initiateOAuth } from '../config/oauth.config';

vi.mock('../config/oauth.config', () => ({
  initiateOAuth: vi.fn(),
}));

const initiateOAuthMock = vi.mocked(initiateOAuth);

describe('QQLoginButton', () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  it('渲染腾讯官方长按钮素材', () => {
    render(<QQLoginButton />);
    const button = screen.getByRole('button', { name: '用QQ帐号登录' });
    const image = screen.getByAltText('用QQ帐号登录');
    expect(button).toBeInTheDocument();
    expect(image).toHaveAttribute('src', '/images/qq/qq-login-170x32.png');
    expect(image).toHaveAttribute('width', '170');
    expect(image).toHaveAttribute('height', '32');
  });

  it('点击后发起QQ授权', async () => {
    initiateOAuthMock.mockResolvedValue(undefined);
    render(<QQLoginButton size="lg" />);
    await userEvent.click(screen.getByRole('button', { name: '用QQ帐号登录' }));
    await waitFor(() => expect(initiateOAuthMock).toHaveBeenCalledWith('qq'));
  });
});
