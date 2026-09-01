import { GradientText, Orb } from '../components/UIComponents';
import PublicLayout from '../components/PublicLayout';

export default function PrivacyPage() {
  const effectiveDate = '2024年1月1日';

  return (
    <PublicLayout>
      {/* Background Orbs */}
      <div className="fixed inset-0 pointer-events-none overflow-hidden">
        <Orb color="primary" size={200} className="top-0 left-0 -translate-x-1/2 -translate-y-1/2 opacity-20" />
        <Orb color="accent" size={150} className="bottom-0 right-0 translate-x-1/2 translate-y-1/2 opacity-10" />
      </div>

      {/* Background Grid */}
      <div className="fixed inset-0 bg-grid pointer-events-none opacity-5" />

      {/* Main Content */}
      <div className="relative z-10">
        <main className="max-w-4xl mx-auto px-4 py-12">
          <div className="card-glass">
            <h1 className="text-3xl font-bold mb-2">
              <GradientText>隐私政策</GradientText>
            </h1>
            <p className="text-slate-400 text-sm mb-8">
              最后更新日期：{effectiveDate}
            </p>

            <div className="space-y-6 text-slate-300 text-sm leading-relaxed">
              <section>
                <h2 className="text-lg font-semibold text-white mb-3">引言</h2>
                <p>
                  AI简历智能生成平台（以下简称"我们"或"本平台"）非常重视用户的隐私保护。
                  本隐私政策旨在向您说明我们如何收集、使用、存储和保护您的个人信息。
                  使用本平台即表示您同意本隐私政策的条款。
                </p>
              </section>

              <section>
                <h2 className="text-lg font-semibold text-white mb-3">1. 信息收集</h2>

                <h3 className="text-md font-medium text-white mb-2 mt-4">1.1 您主动提供的信息</h3>
                <ul className="list-disc list-inside space-y-1 text-slate-400">
                  <li>注册信息：邮箱、用户名、密码</li>
                  <li>简历内容：个人信息、教育经历、工作经验、技能等</li>
                  <li>反馈和沟通记录</li>
                </ul>

                <h3 className="text-md font-medium text-white mb-2 mt-4">1.2 自动收集的信息</h3>
                <ul className="list-disc list-inside space-y-1 text-slate-400">
                  <li>设备信息：设备类型、操作系统、浏览器类型</li>
                  <li>日志信息：IP地址、访问时间、访问页面</li>
                  <li>使用数据：功能使用情况、偏好设置</li>
                </ul>
              </section>

              <section>
                <h2 className="text-lg font-semibold text-white mb-3">2. 信息使用</h2>
                <p className="mb-2">我们使用收集的信息用于：</p>
                <ul className="list-disc list-inside space-y-1 text-slate-400">
                  <li>提供、维护和改进本平台服务</li>
                  <li>生成和优化您的简历内容</li>
                  <li>发送重要通知和服务更新</li>
                  <li>分析平台使用情况，优化用户体验</li>
                  <li>防范欺诈和确保平台安全</li>
                  <li>遵守法律义务</li>
                </ul>
              </section>

              <section>
                <h2 className="text-lg font-semibold text-white mb-3">3. 信息共享</h2>
                <p className="mb-2">除以下情况外，我们不会与第三方共享您的个人信息：</p>
                <ul className="list-disc list-inside space-y-1 text-slate-400">
                  <li>获得您的明确同意</li>
                  <li>履行法律义务或响应法律程序</li>
                  <li>保护我们或他人的权利、财产或安全</li>
                  <li>与可信服务提供商合作（需遵守保密义务）</li>
                </ul>

                <p className="mt-3">
                  <strong className="text-white">特别注意：</strong>您的简历内容不会被公开分享，
                  除非您主动选择分享或导出。
                </p>
              </section>

              <section>
                <h2 className="text-lg font-semibold text-white mb-3">4. AI服务说明</h2>
                <p className="mb-2">
                  本平台使用AI技术帮助您生成和优化简历内容：
                </p>
                <ul className="list-disc list-inside space-y-1 text-slate-400">
                  <li>您的简历数据会发送给AI服务提供商进行处理</li>
                  <li>AI提供商不会将您的数据用于训练其模型</li>
                  <li>传输过程采用加密保护</li>
                  <li>您可以选择不使用AI功能</li>
                </ul>
              </section>

              <section>
                <h2 className="text-lg font-semibold text-white mb-3">5. 信息存储与安全</h2>
                <p className="mb-2">
                  我们采取合理的技术和组织措施保护您的信息安全：
                </p>
                <ul className="list-disc list-inside space-y-1 text-slate-400">
                  <li>数据传输采用SSL/TLS加密</li>
                  <li>密码采用哈希算法存储</li>
                  <li>定期进行安全审计</li>
                  <li>访问控制和权限管理</li>
                </ul>

                <p className="mt-3 text-rose-400">
                  请注意：任何安全措施都无法做到绝对安全。请妥善保管您的账户信息。
                </p>
              </section>

              <section>
                <h2 className="text-lg font-semibold text-white mb-3">6. Cookie政策</h2>
                <p className="mb-2">
                  我们使用Cookie和类似技术来：
                </p>
                <ul className="list-disc list-inside space-y-1 text-slate-400">
                  <li>保持您的登录状态</li>
                  <li>记住您的偏好设置</li>
                  <li>分析平台使用情况</li>
                </ul>
                <p className="mt-2">
                  您可以通过浏览器设置管理Cookie，但这可能影响平台功能。
                </p>
              </section>

              <section>
                <h2 className="text-lg font-semibold text-white mb-3">7. 您的权利</h2>
                <p className="mb-2">您对个人信息享有以下权利：</p>
                <ul className="list-disc list-inside space-y-1 text-slate-400">
                  <li><strong>访问权：</strong>查看我们收集的您的信息</li>
                  <li><strong>更正权：</strong>更新或修改不准确的信息</li>
                  <li><strong>删除权：</strong>要求删除您的个人信息</li>
                  <li><strong>导出权：</strong>以结构化格式导出您的数据</li>
                  <li><strong>反对权：</strong>反对某些信息处理活动</li>
                </ul>
              </section>

              <section>
                <h2 className="text-lg font-semibold text-white mb-3">8. 数据保留</h2>
                <p className="mb-2">
                  我们仅在必要期限内保留您的个人信息：
                </p>
                <ul className="list-disc list-inside space-y-1 text-slate-400">
                  <li>账户信息：账户存续期间及注销后30天</li>
                  <li>简历数据：账户存续期间或您主动删除后</li>
                  <li>日志数据：最长保留90天</li>
                </ul>
                <p className="mt-2">
                  法律要求或必要情况下，保留期限可能延长。
                </p>
              </section>

              <section>
                <h2 className="text-lg font-semibold text-white mb-3">9. 儿童隐私</h2>
                <p>
                  本平台不面向16岁以下儿童。我们不会故意收集儿童的个人信息。
                  如发现我们收集了儿童信息，我们将立即删除。
                </p>
              </section>

              <section>
                <h2 className="text-lg font-semibold text-white mb-3">10. 政策更新</h2>
                <p>
                  我们可能不时更新本隐私政策。更新后的政策将在本页面发布，
                  并在政策顶部注明更新日期。继续使用即表示您接受更新后的政策。
                </p>
              </section>

              <section>
                <h2 className="text-lg font-semibold text-white mb-3">11. 联系我们</h2>
                <p>如您对本隐私政策有任何疑问、意见或请求，请通过以下方式联系我们：</p>
                <div className="mt-3 text-slate-400">
                  <p>邮箱：privacy@airesume.com</p>
                  <p>地址：中国上海市浦东新区</p>
                </div>
              </section>
            </div>
          </div>
        </main>
      </div>
    </PublicLayout>
  );
}
