import { Link } from 'react-router-dom';

export default function Footer() {
  const year = new Date().getFullYear();

  return (
    <footer className="lp-footer">
      <div className="lp-container">
        <div className="lp-footer-grid">
          <div>
            <div className="lp-footer-brand">ndtool</div>
            <p className="lp-footer-desc">
              AI 驱动的智能简历生成平台，帮助求职者快速创建专业简历，提升面试邀请率。
            </p>
          </div>

          <div>
            <div className="lp-footer-title">产品</div>
            <ul className="lp-footer-links">
              <li><Link to="/login">AI 简历</Link></li>
              <li><Link to="/templates">模板中心</Link></li>
              <li><Link to="/about">关于我们</Link></li>
              <li><Link to="/help">帮助中心</Link></li>
            </ul>
          </div>

          <div>
            <div className="lp-footer-title">资源</div>
            <ul className="lp-footer-links">
              <li><a href="/resources/">资源工具站</a></li>
              <li><a href="/blog/ai-resume-guide.html">简历攻略</a></li>
              <li><a href="/blog/fresh-graduate-resume.html">应届生指南</a></li>
              <li><Link to="/terms">服务条款</Link></li>
            </ul>
          </div>

          <div>
            <div className="lp-footer-title">联系</div>
            <ul className="lp-footer-links">
              <li><a href="mailto:641600780@qq.com">641600780@qq.com</a></li>
              <li><Link to="/privacy">隐私政策</Link></li>
              <li><a href="https://github.com/18606559294/AI-" target="_blank" rel="noopener">GitHub</a></li>
            </ul>
          </div>
        </div>

        <div className="lp-footer-bottom">
          <span>&copy; {year} ndtool.cn — AI 工具 + 简历平台</span>
          <span>仅供学习交流使用，如有侵权请联系删除</span>
        </div>
      </div>
    </footer>
  );
}
