import { useEffect, useRef, Suspense, lazy } from 'react';
import { Routes, Route, Navigate } from 'react-router-dom';
import { useAuthStore } from './store/auth';
import { ErrorBoundary } from './components/ErrorBoundary';
import { Spinner } from './components/UIComponents';
import PublicLayout from './components/PublicLayout';
import { Analytics } from './components/Analytics';

// 懒加载页面组件 - 代码分割优化
const LandingPage = lazy(() => import('./pages/LandingPage'));
const TraePage = lazy(() => import('./pages/TraePage'));
const CareerPage = lazy(() => import('./pages/CareerPage'));
const LoginPage = lazy(() => import('./pages/LoginPage'));
const RegisterPage = lazy(() => import('./pages/RegisterPage'));
const ForgotPasswordPage = lazy(() => import('./pages/ForgotPasswordPage'));
const UnifiedLoginPage = lazy(() => import('./pages/UnifiedLoginPage'));
const OAuthCallbackPage = lazy(() => import('./pages/OAuthCallbackPage'));
const AccountSettingsPage = lazy(() => import('./pages/AccountSettingsPage'));
const TermsPage = lazy(() => import('./pages/TermsPage'));
const PrivacyPage = lazy(() => import('./pages/PrivacyPage'));
const HelpPage = lazy(() => import('./pages/HelpPage'));
const AboutPage = lazy(() => import('./pages/AboutPage'));
const HomePage = lazy(() => import('./pages/HomePage'));
const ResumeListPage = lazy(() => import('./pages/ResumeListPage'));
const ResumeEditorPage = lazy(() => import('./pages/ResumeEditorPage'));
const TemplatesPage = lazy(() => import('./pages/TemplatesPage'));
const ProfilePage = lazy(() => import('./pages/ProfilePage'));
const SettingsPage = lazy(() => import('./pages/SettingsPage'));

// 资源工具页面
const ResourcesMainPage = lazy(() => import('./pages/resources/ResourcesMainPage'));
const ToolboxPage = lazy(() => import('./pages/resources/ToolboxPage'));
const ResourcesListPage = lazy(() => import('./pages/resources/ResourcesListPage'));
const FeedbackPage = lazy(() => import('./pages/resources/FeedbackPage'));
const StatusPage = lazy(() => import('./pages/resources/StatusPage'));
const SecurityPage = lazy(() => import('./pages/resources/SecurityPage'));

// 页面加载包装器
function PageLoader({ children }: { children: React.ReactNode }) {
  return (
    <Suspense
      fallback={
        <div className="min-h-screen flex items-center justify-center bg-[#0C0C0C]">
          <Spinner size="lg" />
        </div>
      }
    >
      {children}
    </Suspense>
  );
}

function App() {
  const isAuthenticated = useAuthStore((state) => state.isAuthenticated);
  const loadUser = useAuthStore((state) => state.loadUser);
  const isLoading = useAuthStore((state) => state.isLoading);
  const hasLoaded = useRef(false);

  // 修复：应用启动时验证token有效性（使用useRef确保单次执行）
  useEffect(() => {
    if (!hasLoaded.current) {
      hasLoaded.current = true;
      loadUser();
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  // 显示加载状态
  if (isLoading && isAuthenticated === false) {
    return (
      <div className="min-h-screen flex items-center justify-center bg-[#0C0C0C]">
        <Spinner size="lg" />
      </div>
    );
  }

  return (
    <ErrorBoundary>
      <Analytics />
      <Routes>
        {/* 公开首页 - Landing Page（独立导航） */}
        <Route
          path="/"
          element={
            <PageLoader>
              <LandingPage />
            </PageLoader>
          }
        />

        {/* 公开页面（统一全局导航） */}
        <Route
          path="/career"
          element={
            <PageLoader>
              <CareerPage />
            </PageLoader>
          }
        />
        <Route
          path="/trae"
          element={
            <PageLoader>
              <PublicLayout fullPage>
                <TraePage />
              </PublicLayout>
            </PageLoader>
          }
        />
        <Route
          path="/login"
          element={
            <PageLoader>
              {!isAuthenticated ? (
                <PublicLayout>
                  <LoginPage />
                </PublicLayout>
              ) : (
                <Navigate to="/dashboard" replace />
              )}
            </PageLoader>
          }
        />
        <Route
          path="/register"
          element={
            <PageLoader>
              {!isAuthenticated ? (
                <PublicLayout>
                  <RegisterPage />
                </PublicLayout>
              ) : (
                <Navigate to="/dashboard" replace />
              )}
            </PageLoader>
          }
        />
        <Route
          path="/forgot-password"
          element={
            <PageLoader>
              <PublicLayout>
                <ForgotPasswordPage />
              </PublicLayout>
            </PageLoader>
          }
        />
        <Route
          path="/unified-login"
          element={
            <PageLoader>
              {!isAuthenticated ? (
                <PublicLayout>
                  <UnifiedLoginPage />
                </PublicLayout>
              ) : (
                <Navigate to="/dashboard" replace />
              )}
            </PageLoader>
          }
        />
        <Route
          path="/oauth/callback"
          element={
            <PageLoader>
              <OAuthCallbackPage />
            </PageLoader>
          }
        />
        <Route
          path="/terms"
          element={
            <PageLoader>
              <TermsPage />
            </PageLoader>
          }
        />
        <Route
          path="/privacy"
          element={
            <PageLoader>
              <PrivacyPage />
            </PageLoader>
          }
        />
        <Route
          path="/help"
          element={
            <PageLoader>
              <HelpPage />
            </PageLoader>
          }
        />
        <Route
          path="/about"
          element={
            <PageLoader>
              <AboutPage />
            </PageLoader>
          }
        />

        {/* 资源工具页面 */}
        <Route path="/resources" element={<PageLoader><ResourcesMainPage /></PageLoader>} />
        <Route path="/resources/toolbox" element={<PageLoader><ToolboxPage /></PageLoader>} />
        <Route path="/resources/list" element={<PageLoader><ResourcesListPage /></PageLoader>} />
        <Route path="/resources/feedback" element={<PageLoader><FeedbackPage /></PageLoader>} />
        <Route path="/resources/status" element={<PageLoader><StatusPage /></PageLoader>} />
        <Route path="/resources/security" element={<PageLoader><SecurityPage /></PageLoader>} />

        {/* 受保护路由 */}
        <Route
          path="/dashboard"
          element={
            <PageLoader>
              {isAuthenticated ? <HomePage /> : <Navigate to="/login" replace />}
            </PageLoader>
          }
        />
        <Route
          path="/resumes"
          element={
            <PageLoader>
              {isAuthenticated ? <ResumeListPage /> : <Navigate to="/login" replace />}
            </PageLoader>
          }
        />
        <Route
          path="/resumes/new"
          element={
            <PageLoader>
              {isAuthenticated ? <ResumeEditorPage /> : <Navigate to="/login" replace />}
            </PageLoader>
          }
        />
        <Route
          path="/resumes/:id"
          element={
            <PageLoader>
              {isAuthenticated ? <ResumeEditorPage /> : <Navigate to="/login" replace />}
            </PageLoader>
          }
        />
        <Route
          path="/templates"
          element={
            <PageLoader>
              {isAuthenticated ? <TemplatesPage /> : <Navigate to="/login" replace />}
            </PageLoader>
          }
        />
        <Route
          path="/profile"
          element={
            <PageLoader>
              {isAuthenticated ? <ProfilePage /> : <Navigate to="/login" replace />}
            </PageLoader>
          }
        />
        <Route
          path="/settings"
          element={
            <PageLoader>
              {isAuthenticated ? <SettingsPage /> : <Navigate to="/login" replace />}
            </PageLoader>
          }
        />
        <Route
          path="/account-settings"
          element={
            <PageLoader>
              {isAuthenticated ? <AccountSettingsPage /> : <Navigate to="/login" replace />}
            </PageLoader>
          }
        />

        {/* 404 */}
        <Route path="*" element={<Navigate to="/" replace />} />
      </Routes>
    </ErrorBoundary>
  );
}

export default App;
