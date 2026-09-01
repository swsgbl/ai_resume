import { useEffect } from 'react';
import PublicNavbar from './PublicNavbar';
import './PublicNavbar.css';

interface Props {
  children: React.ReactNode;
  fullPage?: boolean;
}

export default function PublicLayout({ children, fullPage = false }: Props) {
  useEffect(() => {
    window.scrollTo(0, 0);
  }, []);

  return (
    <div className="min-h-screen relative overflow-x-hidden bg-slate-950">
      <PublicNavbar />
      <main className={fullPage ? '' : 'pt-16'}>
        {children}
      </main>
    </div>
  );
}
