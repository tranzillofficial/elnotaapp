import type { Metadata } from 'next';
import './globals.css';

export const metadata: Metadata = {
  title: 'النوتة | حسابات أوضح، وشغل أريح',
  description: 'إدارة العملاء والفواتير والدفعات والأقساط في مكان واحد. اكتشف النوتة للموبايل والكمبيوتر والويب.',
  robots: { index: false, follow: false },
  openGraph: { title: 'النوتة — حسابات أوضح، وشغل أريح', description: 'عملاءك وفواتيرك وأقساطك، في نوتة واحدة.', locale: 'ar_EG', type: 'website' },
};

export default function Layout({ children }: Readonly<{ children: React.ReactNode }>) {
  return <html lang="ar" dir="rtl"><body>{children}</body></html>;
}
