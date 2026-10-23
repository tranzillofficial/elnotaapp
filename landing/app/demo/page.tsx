import { redirect } from 'next/navigation';
export const metadata = { title: 'جرب حساب ديمو | النوتة' };
export default function Demo() {
  const demo = process.env.FLUTTER_DEMO_URL;
  if (demo?.startsWith('https://')) redirect(demo);
  return <main className="web-page wrap"><a className="text-link" href="/">العودة للرئيسية</a><div className="web-intro"><h1>جرب حساب ديمو</h1><p>جارٍ تجهيز نسخة التجربة المستقلة. الديمو لا يحتاج بريدًا أو كلمة مرور، ولا يتصل ببيانات العملاء.</p></div></main>;
}
