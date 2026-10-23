export const metadata = { title: 'افتح النوتة Web | النوتة' };

export default function Web() {
  const webUrl = process.env.FLUTTER_WEB_URL;
  const configured = webUrl && /^https:\/\//.test(webUrl);
  return <main className="web-page wrap"><a className="text-link" href="/">→ العودة للنوتة</a><div className="web-intro"><span className="eyebrow">مساحة شغلك على المتصفح</span><h1>النوتة Web</h1><p>افتح شاشة QR، امسح الكود بالموبايل، وقارن كود التأكيد قبل الموافقة.</p></div>{configured ? <section className="web-status"><span className="status-dot"/><h2>نسخة الويب التجريبية جاهزة للفتح</h2><p>تفتح في صفحة مستقلة للحفاظ على جلسة التطبيق والربط الآمن.</p><a className="button" href={webUrl}>افتح شاشة QR ←</a></section> : <section className="web-status"><span className="status-dot pending-dot"/><h2>ربط بيئة الاختبار قيد الإعداد</h2><p>اللاندنج جاهزة للمعاينة. اختبار الدخول الفعلي يحتاج نسخة Flutter مرتبطة بمشروع Supabase تجريبي وتطبيق موبايل على نفس البيئة.</p><p>لا يتم استخدام حسابات العملاء أو بيانات الموقع القديم في هذه المعاينة.</p><a className="button secondary" href="/#how">شوف خطوات الربط</a></section>}<div className="web-checklist"><h2>قبل الربط</h2><p>١. سجّل الدخول في نسخة الموبايل التجريبية.</p><p>٢. افتح رابط الويب على الكمبيوتر.</p><p>٣. قارن كود التأكيد ووافق على الجهاز من موبايلك.</p></div></main>;
}
