import { redirect } from 'next/navigation';
export default function Web() {
 const url = process.env.FLUTTER_WEB_URL;
 if (url && /^https:\/\//.test(url)) redirect(url);
 return <main className="web-page wrap"><h1>تسجيل الدخول</h1><p>نسخة الويب قيد الإعداد.</p></main>;
}
