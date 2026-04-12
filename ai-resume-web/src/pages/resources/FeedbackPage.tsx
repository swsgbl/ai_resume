import { useState } from 'react';
import { useTranslation } from 'react-i18next';
import PublicLayout from '../../components/PublicLayout';
import ResourceLayout from '../../components/resources/ResourceLayout';

interface FeedbackItem {
  id: string;
  name: string;
  question: string;
  date: string;
  status: 'pending' | 'processing' | 'resolved' | 'closed';
}

export default function FeedbackPage() {
  const { t } = useTranslation();
  const [name, setName] = useState('');
  const [contact, setContact] = useState('');
  const [question, setQuestion] = useState('');
  const [submitted, setSubmitted] = useState(false);
  const [history, setHistory] = useState<FeedbackItem[]>(() => {
    try {
      return JSON.parse(localStorage.getItem('feedback_history') || '[]');
    } catch { return []; }
  });

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (!name.trim() || !question.trim()) return;

    const item: FeedbackItem = {
      id: Date.now().toString(),
      name: name.trim(),
      question: question.trim(),
      date: new Date().toLocaleString('zh-CN'),
      status: 'pending',
    };

    const updated = [item, ...history];
    setHistory(updated);
    localStorage.setItem('feedback_history', JSON.stringify(updated));
    setName('');
    setContact('');
    setQuestion('');
    setSubmitted(true);
    setTimeout(() => setSubmitted(false), 3000);
  };

  const STATUS_COLORS: Record<string, string> = {
    pending: 'text-amber-400',
    processing: 'text-blue-400',
    resolved: 'text-[#8FAE8B]',
    closed: 'text-[#5A5652]',
  };

  return (
    <PublicLayout>
      <ResourceLayout>
        <h1 className="text-3xl font-bold text-[#E8E4DE] mb-8">{t('resources.feedback.title')}</h1>

        {/* Form */}
        <form onSubmit={handleSubmit} className="mb-10 space-y-4">
          <div>
            <label className="block text-sm text-[#8A8580] mb-1">{t('resources.feedback.name')}</label>
            <input
              type="text"
              value={name}
              onChange={(e) => setName(e.target.value)}
              placeholder={t('resources.feedback.namePlaceholder')}
              required
              className="w-full bg-[#161616] border-b border-[#252525] px-3 py-2 text-sm text-[#E8E4DE] placeholder-[#5A5652] focus:outline-none focus:border-[#C84B31] transition-colors"
            />
          </div>
          <div>
            <label className="block text-sm text-[#8A8580] mb-1">{t('resources.feedback.contact')}</label>
            <input
              type="text"
              value={contact}
              onChange={(e) => setContact(e.target.value)}
              placeholder={t('resources.feedback.contactPlaceholder')}
              className="w-full bg-[#161616] border-b border-[#252525] px-3 py-2 text-sm text-[#E8E4DE] placeholder-[#5A5652] focus:outline-none focus:border-[#C84B31] transition-colors"
            />
          </div>
          <div>
            <label className="block text-sm text-[#8A8580] mb-1">{t('resources.feedback.question')}</label>
            <textarea
              value={question}
              onChange={(e) => setQuestion(e.target.value)}
              placeholder={t('resources.feedback.questionPlaceholder')}
              required
              rows={4}
              className="w-full bg-[#161616] border-b border-[#252525] px-3 py-2 text-sm text-[#E8E4DE] placeholder-[#5A5652] focus:outline-none focus:border-[#C84B31] transition-colors resize-y"
            />
          </div>
          <button
            type="submit"
            className="px-6 py-2 bg-[#C84B31] text-white text-sm font-medium rounded hover:bg-[#A63D28] transition-colors"
          >
            {t('resources.feedback.submit')}
          </button>
          {submitted && (
            <p className="text-[#8FAE8B] text-sm">{t('resources.feedback.success')}</p>
          )}
        </form>

        {/* History */}
        <section>
          <h2 className="text-lg font-semibold text-[#E8E4DE] mb-4 pb-2 border-b border-[#252525]">
            {t('resources.feedback.history')}
          </h2>
          {history.length === 0 ? (
            <p className="text-[#5A5652] text-sm">{t('resources.feedback.noData')}</p>
          ) : (
            <div className="space-y-3">
              {history.map((item) => (
                <div key={item.id} className="p-4 bg-[#161616] border border-[#252525] rounded">
                  <div className="flex justify-between items-start mb-2">
                    <span className="text-[#E8E4DE] text-sm font-medium">{item.name}</span>
                    <span className={`text-xs ${STATUS_COLORS[item.status]}`}>
                      {t(`resources.feedback.status.${item.status}`)}
                    </span>
                  </div>
                  <p className="text-sm text-[#8A8580]">{item.question}</p>
                  <p className="text-xs text-[#5A5652] mt-2">{item.date}</p>
                </div>
              ))}
            </div>
          )}
        </section>
      </ResourceLayout>
    </PublicLayout>
  );
}
