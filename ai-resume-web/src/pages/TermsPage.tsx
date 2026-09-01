import { GradientText, Orb } from '../components/UIComponents';
import PublicLayout from '../components/PublicLayout';

export default function TermsPage() {
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
              <GradientText>用户协议</GradientText>
            </h1>
            <p className="text-slate-400 text-sm mb-8">
              最后更新日期：{effectiveDate}
            </p>

            <div className="space-y-6 text-slate-300 text-sm leading-relaxed">
              <section>
                <h2 className="text-lg font-semibold text-white mb-3">1. 协议的接受</h2>
                <p>
                  欢迎使用AI简历智能生成平台（以下简称"本平台"）。当您注册、访问或使用本平台服务时，
                  您表示已阅读、理解并同意接受本用户协议的全部内容。如果您不同意本协议的任何条款，
                  请立即停止使用本平台。
                </p>
              </section>

              <section>
                <h2 className="text-lg font-semibold text-white mb-3">2. 服务说明</h2>
                <p className="mb-2">本平台提供以下服务：</p>
                <ul className="list-disc list-inside space-y-1 text-slate-400">
                  <li>AI智能简历生成与优化</li>
                  <li>简历模板选择与定制</li>
                  <li>简历多格式导出（PDF、Word等）</li>
                  <li>简历管理与版本控制</li>
                  <li>职位匹配与推荐</li>
                </ul>
              </section>

              <section>
                <h2 className="text-lg font-semibold text-white mb-3">3. 用户注册与账户</h2>
                <p className="mb-2">3.1 您在注册时必须提供真实、准确、完整的个人信息。</p>
                <p className="mb-2">3.2 您有责任维护账户安全，并对使用您账户的所有活动负责。</p>
                <p>3.3 如发现任何未经授权使用您账户的情况，请立即通知我们。</p>
              </section>

              <section>
                <h2 className="text-lg font-semibold text-white mb-3">4. 用户行为规范</h2>
                <p className="mb-2">使用本平台时，您同意不会：</p>
                <ul className="list-disc list-inside space-y-1 text-slate-400">
                  <li>上传含有虚假、误导性或非法信息的简历</li>
                  <li>侵犯他人的知识产权或其他合法权益</li>
                  <li>传播病毒、恶意代码或其他有害程序</li>
                  <li>干扰或破坏本平台的正常运行</li>
                  <li>利用本平台进行任何违法或不当活动</li>
                </ul>
              </section>

              <section>
                <h2 className="text-lg font-semibold text-white mb-3">5. 知识产权</h2>
                <p className="mb-2">
                  本平台的所有内容，包括但不限于文字、图片、软件、代码、商标等，均受知识产权法保护。
                  未经授权，您不得复制、修改、传播或用于商业目的。
                </p>
                <p>
                  您上传的简历内容仍归您所有，但您授予我们在提供服务所必需的范围内使用和存储的权利。
                </p>
              </section>

              <section>
                <h2 className="text-lg font-semibold text-white mb-3">6. 隐私保护</h2>
                <p>
                  我们重视您的隐私保护。关于我们如何收集、使用和保护您的个人信息，
                  请参阅我们的《隐私政策》。
                </p>
              </section>

              <section>
                <h2 className="text-lg font-semibold text-white mb-3">7. 服务变更与终止</h2>
                <p className="mb-2">
                  我们保留随时修改、暂停或终止本平台全部或部分服务的权利，
                  且无需对您或任何第三方承担责任。
                </p>
                <p>
                  您也可以随时停止使用本平台，并注销您的账户。
                </p>
              </section>

              <section>
                <h2 className="text-lg font-semibold text-white mb-3">8. 免责声明</h2>
                <p className="mb-2">
                  本平台按"现状"提供服务，不提供任何明示或暗示的保证。
                </p>
                <p className="mb-2">
                  对于以下情况，我们不承担任何责任：
                </p>
                <ul className="list-disc list-inside space-y-1 text-slate-400">
                  <li>因不可抗力导致的服务中断</li>
                  <li>因用户操作失误导致的数据丢失</li>
                  <li>第三方行为造成的损失或损害</li>
                  <li>AI生成内容的准确性或适用性</li>
                </ul>
              </section>

              <section>
                <h2 className="text-lg font-semibold text-white mb-3">9. 协议修改</h2>
                <p>
                  我们保留随时修改本协议的权利。修改后的协议一经发布即生效。
                  继续使用本平台即表示您接受修改后的协议。
                </p>
              </section>

              <section>
                <h2 className="text-lg font-semibold text-white mb-3">10. 法律适用</h2>
                <p>
                  本协议受中华人民共和国法律管辖。如有争议，双方应友好协商解决；
                  协商不成的，任何一方可向我们所在地人民法院提起诉讼。
                </p>
              </section>

              <section>
                <h2 className="text-lg font-semibold text-white mb-3">11. 联系我们</h2>
                <p>如您对本协议有任何疑问，请通过以下方式联系我们：</p>
                <p className="text-slate-400 mt-2">邮箱：support@airesume.com</p>
              </section>
            </div>
          </div>
        </main>
      </div>
    </PublicLayout>
  );
}
